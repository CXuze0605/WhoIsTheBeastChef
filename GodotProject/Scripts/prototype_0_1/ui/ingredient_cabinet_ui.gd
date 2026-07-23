class_name IngredientCabinetUI
extends CanvasLayer

class DragPreviewArtwork:
	extends Control

	var texture: Texture2D
	var is_rotated: bool = false

	func configure(new_texture: Texture2D, rotated: bool) -> void:
		texture = new_texture
		is_rotated = rotated
		queue_redraw()

	func _draw() -> void:
		if texture == null or size.x <= 0.0 or size.y <= 0.0:
			return
		if not is_rotated:
			var fitted_size := _fit_texture_size(size)
			draw_texture_rect(texture, Rect2((size - fitted_size) * 0.5, fitted_size), false, Color.WHITE)
			return
		var unrotated_bounds := Vector2(size.y, size.x)
		var unrotated_size := _fit_texture_size(unrotated_bounds)
		draw_set_transform(size * 0.5, PI * 0.5, Vector2.ONE)
		draw_texture_rect(texture, Rect2(-unrotated_size * 0.5, unrotated_size), false, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _fit_texture_size(bounds: Vector2) -> Vector2:
		var texture_size := texture.get_size()
		if texture_size.x <= 0.0 or texture_size.y <= 0.0:
			return bounds
		var fit_scale := minf(bounds.x / texture_size.x, bounds.y / texture_size.y)
		return texture_size * fit_scale

@export var player_path: NodePath

enum SourceKind {
	NONE,
	QUICK,
	BACKPACK,
	CABINET,
}

var player: PrototypePlayer
var cabinet: IngredientCabinet
var root_control: Control
var title_label: Label
var cabinet_title_label: Label
var feedback_label: Label
var item_detail_label: Label
var backpack_view: InventoryGridView
var cabinet_view: InventoryGridView
var cabinet_scroll: ScrollContainer
var drag_preview: Panel
var drag_preview_icon: DragPreviewArtwork
var drag_preview_label: Label
var drag_preview_style: StyleBoxFlat
var quick_buttons: Array[Button] = []
var stock_icons: Dictionary = {}
var inventory_icons: Array[TextureRect] = []
var take_buttons: Dictionary = {}
var opened_frame: int = -1
var previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var cabinet_mode: bool = false

var dragged_item: CarryableItem
var drag_source_kind: int = SourceKind.NONE
var drag_quick_slot: int = -1
var drag_rotated: bool = false


func _ready() -> void:
	player = get_node(player_path) as PrototypePlayer
	add_to_group("ingredient_cabinet_ui")
	add_to_group("prototype_local_modal")
	_ensure_backpack_input()
	_build_ui()
	root_control.visible = false


func _process(_delta: float) -> void:
	if not is_open():
		return
	_refresh_content()
	if dragged_item != null:
		var mouse_position := get_viewport().get_mouse_position()
		_position_drag_preview(mouse_position)
		_update_drop_target_preview(mouse_position)
	if cabinet_mode and (not is_instance_valid(cabinet) or player.global_position.distance_to(cabinet.global_position) > player.prototype_interaction_distance):
		close_cabinet()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragged_item != null:
		_finish_drag(event.position)
		get_viewport().set_input_as_handled()
		return
	if is_open() and event.is_action_pressed("rotate_inventory_item") and dragged_item != null:
		drag_rotated = not drag_rotated
		feedback_label.text = "拖拽方向：%s" % ("已旋转 90°" if drag_rotated else "默认方向")
		_refresh_drag_preview()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_backpack"):
		if is_open():
			close_cabinet()
		else:
			open_backpack(player)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_backpack"):
		close_cabinet()
		get_viewport().set_input_as_handled()


func open_backpack(target_player: PrototypePlayer) -> void:
	if is_open():
		return
	player = target_player
	cabinet = null
	cabinet_mode = false
	_open_common()


func open_cabinet(target_cabinet: IngredientCabinet, target_player: PrototypePlayer) -> void:
	if is_open():
		return
	cabinet = target_cabinet
	player = target_player
	cabinet_mode = true
	_open_common()


func _open_common() -> void:
	opened_frame = Engine.get_process_frames()
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	root_control.visible = true
	player.set_modal_ui_open(true)
	title_label.text = (
		"测试大厅全物品柜 · 无限取用"
		if cabinet_mode and cabinet.lobby_unlimited
		else "异形食材柜 · 实时整理"
	) if cabinet_mode else "玩家异形背包"
	cabinet_view.visible = cabinet_mode
	cabinet_scroll.visible = cabinet_mode
	cabinet_title_label.visible = cabinet_mode
	if cabinet_mode:
		cabinet_title_label.text = "20×20 测试目录（滚动查看 · 取走后自动补充）" if cabinet.lobby_unlimited else "10×8 异形食材柜"
	feedback_label.text = (
		"测试物品取走后自动补充 · 鼠标拖放 · R 旋转 · Tab / Esc 关闭"
		if cabinet_mode and cabinet.lobby_unlimited
		else "鼠标拖放 · 拖拽时按 R 旋转 · Tab / Esc 关闭"
	)
	item_detail_label.text = "将鼠标移到物品上，查看完整名称、占格和状态"
	_bind_inventories()
	_refresh_content()


func close_cabinet() -> void:
	if not is_open():
		return
	_cancel_drag()
	root_control.visible = false
	if player != null:
		player.set_modal_ui_open(false)
	Input.mouse_mode = previous_mouse_mode
	cabinet = null
	cabinet_mode = false


func is_open() -> bool:
	return root_control != null and root_control.visible


func is_local_modal_open() -> bool:
	return is_open()


func close_local_modal() -> void:
	close_cabinet()


func _bind_inventories() -> void:
	backpack_view.setup(player.backpack, 54.0, "6×6 随身背包")
	if cabinet_mode:
		var cabinet_cell_size := 32.0 if cabinet.lobby_unlimited else 42.0
		var cabinet_label := "20×20 测试目录" if cabinet.lobby_unlimited else "10×8 食材柜"
		cabinet_view.setup(cabinet.storage, cabinet_cell_size, cabinet_label)
		cabinet_scroll.scroll_horizontal = 0
		cabinet_scroll.scroll_vertical = 0


func _begin_grid_drag(item: CarryableItem, source_kind: int) -> void:
	dragged_item = item
	drag_source_kind = source_kind
	drag_quick_slot = -1
	var placement := _get_source_grid().get_placement(item)
	drag_rotated = placement.rotated if placement != null else item.storage_rotated
	_get_view_for_kind(source_kind).set_hidden_drag_item(item)
	_refresh_drag_preview()
	feedback_label.text = "拖拽：%s · R 旋转" % item.data.display_name


func _begin_quick_drag(slot_index: int) -> void:
	var item := player.inventory.get_item(slot_index)
	if item == null:
		return
	dragged_item = item
	drag_source_kind = SourceKind.QUICK
	drag_quick_slot = slot_index
	drag_rotated = item.storage_rotated
	_refresh_drag_preview()
	feedback_label.text = "拖拽快捷栏 %d：%s" % [slot_index + 1, item.data.display_name]


func _finish_drag(mouse_position: Vector2) -> void:
	var success := false
	if backpack_view.visible and backpack_view.contains_global(mouse_position):
		success = _drop_to_grid(player.backpack, backpack_view.get_cell_at_global(mouse_position), SourceKind.BACKPACK)
	elif _is_cabinet_grid_point(mouse_position):
		success = _drop_to_grid(cabinet.storage, cabinet_view.get_cell_at_global(mouse_position), SourceKind.CABINET)
	else:
		var quick_slot := _quick_slot_at(mouse_position)
		if quick_slot >= 0:
			success = _drop_to_quick(quick_slot)
	feedback_label.text = "移动完成" if success else "放置失败：物品已安全保留在原位置"
	_cancel_drag()
	_refresh_content()


func _drop_to_grid(target: GridInventory, origin: Vector2i, target_kind: int) -> bool:
	if dragged_item == null or target == null:
		return false
	var target_item := target.get_item_at(origin)
	if target_item != null and target_item != dragged_item and target_item.data.can_stack_with(dragged_item.data):
		return _merge_dragged_into(target_item)
	if target_item != null and target_item != dragged_item and drag_source_kind == target_kind:
		return target.swap_items(dragged_item, target_item)
	if drag_source_kind == target_kind:
		return target.move_item(dragged_item, origin, drag_rotated)
	if not target.can_place_item(dragged_item, origin, drag_rotated):
		return false
	if drag_source_kind == SourceKind.QUICK:
		var removed := player.inventory.take_item(drag_quick_slot)
		if target.add_item_at(removed, origin, drag_rotated):
			return true
		player.inventory.put_item(drag_quick_slot, removed)
		return false
	var source_grid := _get_source_grid()
	var old := source_grid.remove_item(dragged_item)
	if target.add_item_at(dragged_item, origin, drag_rotated):
		return true
	source_grid.add_item_at(dragged_item, old.origin, old.rotated)
	return false


func _drop_to_quick(slot_index: int) -> bool:
	if dragged_item == null:
		return false
	if drag_source_kind == SourceKind.QUICK:
		return player.inventory.swap_items(drag_quick_slot, slot_index)
	var target_item := player.inventory.get_item(slot_index)
	if target_item != null and target_item.data.can_stack_with(dragged_item.data):
		return _merge_dragged_into(target_item)
	if target_item != null:
		return false
	var source_grid := _get_source_grid()
	var old := source_grid.remove_item(dragged_item)
	if player.inventory.put_item(slot_index, dragged_item):
		return true
	source_grid.add_item_at(dragged_item, old.origin, old.rotated)
	return false


func _merge_dragged_into(target_item: CarryableItem) -> bool:
	var accepted := target_item.data.add_to_stack(dragged_item.data.stack_count)
	if accepted <= 0:
		return false
	dragged_item.data.stack_count -= accepted
	target_item.refresh_visual()
	if dragged_item.data.stack_count <= 0:
		if drag_source_kind == SourceKind.QUICK:
			player.inventory.take_item(drag_quick_slot)
		else:
			_get_source_grid().remove_item(dragged_item)
		dragged_item.queue_free()
	else:
		dragged_item.refresh_visual()
		if drag_source_kind != SourceKind.QUICK:
			_get_source_grid().changed.emit()
	player.inventory.notify_item_changed()
	return true


func _get_source_grid() -> GridInventory:
	match drag_source_kind:
		SourceKind.BACKPACK:
			return player.backpack
		SourceKind.CABINET:
			return cabinet.storage if cabinet != null else null
	return null


func _get_view_for_kind(kind: int) -> InventoryGridView:
	match kind:
		SourceKind.BACKPACK:
			return backpack_view
		SourceKind.CABINET:
			return cabinet_view
	return null


func _quick_slot_at(mouse_position: Vector2) -> int:
	for index in quick_buttons.size():
		if quick_buttons[index].get_global_rect().has_point(mouse_position):
			return index
	return -1


func _cancel_drag() -> void:
	if backpack_view != null:
		backpack_view.set_hidden_drag_item(null)
		backpack_view.clear_drop_preview()
	if cabinet_view != null:
		cabinet_view.set_hidden_drag_item(null)
		cabinet_view.clear_drop_preview()
	dragged_item = null
	drag_source_kind = SourceKind.NONE
	drag_quick_slot = -1
	if drag_preview != null:
		drag_preview.visible = false


func _refresh_drag_preview() -> void:
	if drag_preview == null or dragged_item == null or dragged_item.data == null:
		return
	var bounds := ItemStorageCatalog.get_shape_bounds(
		ItemStorageCatalog.get_shape_cells(dragged_item.data.item_type, drag_rotated)
	)
	var preview_cell_size := 38.0
	drag_preview.size = Vector2(bounds) * preview_cell_size
	drag_preview.custom_minimum_size = drag_preview.size
	drag_preview_style.bg_color = ItemCatalog.get_item_color(dragged_item.data.item_type).darkened(0.18)
	drag_preview_icon.position = Vector2(4.0, 4.0)
	drag_preview_icon.size = drag_preview.size - Vector2(8.0, 8.0)
	drag_preview_icon.configure(
		PrototypeArtCatalog.TEXTURES.get(ItemCatalog.get_art_key_for_data(dragged_item.data)) as Texture2D,
		drag_rotated
	)
	drag_preview_label.position = Vector2(3.0, drag_preview.size.y - 20.0)
	drag_preview_label.size = Vector2(drag_preview.size.x - 6.0, 18.0)
	drag_preview_label.text = dragged_item.data.display_name
	drag_preview.visible = true
	var mouse_position := get_viewport().get_mouse_position()
	_position_drag_preview(mouse_position)
	_update_drop_target_preview(mouse_position)


func _position_drag_preview(mouse_position: Vector2) -> void:
	if drag_preview == null or not drag_preview.visible:
		return
	drag_preview.position = mouse_position - drag_preview.size * 0.5


func _update_drop_target_preview(mouse_position: Vector2) -> void:
	if backpack_view != null:
		backpack_view.clear_drop_preview()
	if cabinet_view != null:
		cabinet_view.clear_drop_preview()
	if dragged_item == null:
		return
	if backpack_view.visible and backpack_view.contains_global(mouse_position):
		backpack_view.set_drop_preview(dragged_item, backpack_view.get_cell_at_global(mouse_position), drag_rotated)
	elif _is_cabinet_grid_point(mouse_position):
		cabinet_view.set_drop_preview(dragged_item, cabinet_view.get_cell_at_global(mouse_position), drag_rotated)


func _is_cabinet_grid_point(mouse_position: Vector2) -> bool:
	return (
		cabinet_mode
		and cabinet_view != null
		and cabinet_view.visible
		and cabinet_scroll != null
		and cabinet_scroll.visible
		and cabinet_scroll.get_global_rect().has_point(mouse_position)
		and cabinet_view.contains_global(mouse_position)
	)


func _refresh_content() -> void:
	if player == null:
		return
	for index in QuickInventory.SLOT_COUNT:
		var item := player.inventory.get_item(index)
		var prefix := "▶ " if index == player.inventory.selected_index else ""
		quick_buttons[index].text = "%s%d\n%s" % [
			prefix,
			index + 1,
			"空" if item == null else _item_short_text(item.data),
		]
		var icon := inventory_icons[index]
		icon.texture = null if item == null else PrototypeArtCatalog.TEXTURES.get(ItemCatalog.get_art_key_for_data(item.data)) as Texture2D
	if cabinet_mode and cabinet != null:
		for item_type in cabinet.get_supported_item_types():
			var stock_icon := stock_icons[item_type] as TextureRect
			stock_icon.texture = PrototypeArtCatalog.TEXTURES.get(ItemCatalog.get_art_key(item_type)) as Texture2D
	backpack_view.queue_redraw()
	if cabinet_mode:
		cabinet_view.queue_redraw()


func _item_short_text(data: ItemData) -> String:
	var text := data.display_name
	if data.is_stackable:
		text += " ×%d" % data.stack_count
	return text


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "InventoryRoot"
	root_control.position = Vector2.ZERO
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.58)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(50.0, 28.0)
	panel.size = Vector2(1180.0, 664.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20252e")
	style.border_color = Color("8ecae6")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	root_control.add_child(panel)
	title_label = Label.new()
	title_label.position = Vector2(80.0, 46.0)
	title_label.size = Vector2(1120.0, 38.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 27)
	title_label.add_theme_color_override("font_color", Color("ffd166"))
	root_control.add_child(title_label)
	var quick_title := Label.new()
	quick_title.text = "五格快捷栏（可直接使用）"
	quick_title.position = Vector2(82.0, 92.0)
	quick_title.size = Vector2(320.0, 24.0)
	root_control.add_child(quick_title)
	for index in QuickInventory.SLOT_COUNT:
		var button := Button.new()
		button.position = Vector2(82.0 + index * 150.0, 120.0)
		button.size = Vector2(140.0, 70.0)
		button.gui_input.connect(_on_quick_gui_input.bind(index))
		root_control.add_child(button)
		quick_buttons.append(button)
		var compatibility_icon := TextureRect.new()
		compatibility_icon.visible = false
		root_control.add_child(compatibility_icon)
		inventory_icons.append(compatibility_icon)
	var backpack_title := Label.new()
	backpack_title.text = "6×6 玩家背包"
	backpack_title.position = Vector2(82.0, 205.0)
	backpack_title.size = Vector2(260.0, 24.0)
	root_control.add_child(backpack_title)
	backpack_view = InventoryGridView.new()
	backpack_view.position = Vector2(82.0, 232.0)
	backpack_view.item_pressed.connect(func(item: CarryableItem, _cell: Vector2i): _begin_grid_drag(item, SourceKind.BACKPACK))
	backpack_view.item_hovered.connect(_on_grid_item_hovered)
	backpack_view.item_hover_ended.connect(_on_grid_item_hover_ended)
	root_control.add_child(backpack_view)
	cabinet_title_label = Label.new()
	cabinet_title_label.text = "10×8 异形食材柜"
	cabinet_title_label.position = Vector2(490.0, 205.0)
	cabinet_title_label.size = Vector2(680.0, 24.0)
	root_control.add_child(cabinet_title_label)
	cabinet_scroll = ScrollContainer.new()
	cabinet_scroll.name = "CabinetScroll"
	cabinet_scroll.position = Vector2(490.0, 232.0)
	cabinet_scroll.size = Vector2(680.0, 336.0)
	cabinet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cabinet_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cabinet_scroll.clip_contents = true
	root_control.add_child(cabinet_scroll)
	cabinet_view = InventoryGridView.new()
	cabinet_view.position = Vector2.ZERO
	cabinet_view.item_pressed.connect(func(item: CarryableItem, _cell: Vector2i): _begin_grid_drag(item, SourceKind.CABINET))
	cabinet_view.item_hovered.connect(_on_grid_item_hovered)
	cabinet_view.item_hover_ended.connect(_on_grid_item_hover_ended)
	cabinet_scroll.add_child(cabinet_view)
	item_detail_label = Label.new()
	item_detail_label.name = "ItemDetailLabel"
	item_detail_label.position = Vector2(82.0, 574.0)
	item_detail_label.size = Vector2(820.0, 42.0)
	item_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_detail_label.add_theme_font_size_override("font_size", 14)
	item_detail_label.add_theme_color_override("font_color", Color("d9f0ff"))
	item_detail_label.add_theme_color_override("font_outline_color", Color("10141a"))
	item_detail_label.add_theme_constant_override("outline_size", 3)
	item_detail_label.text = "将鼠标移到物品上，查看完整名称、占格和状态"
	root_control.add_child(item_detail_label)
	feedback_label = Label.new()
	feedback_label.position = Vector2(82.0, 624.0)
	feedback_label.size = Vector2(820.0, 38.0)
	feedback_label.add_theme_color_override("font_color", Color("ffcf70"))
	root_control.add_child(feedback_label)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "关闭（Tab / Esc）"
	close_button.position = Vector2(950.0, 620.0)
	close_button.size = Vector2(220.0, 48.0)
	close_button.pressed.connect(close_cabinet)
	root_control.add_child(close_button)
	drag_preview = Panel.new()
	drag_preview.name = "DragPreview"
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 500
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.88)
	drag_preview_style = StyleBoxFlat.new()
	drag_preview_style.bg_color = Color("49515f")
	drag_preview_style.border_color = Color("ffd166")
	drag_preview_style.set_border_width_all(2)
	drag_preview_style.set_corner_radius_all(5)
	drag_preview.add_theme_stylebox_override("panel", drag_preview_style)
	root_control.add_child(drag_preview)
	drag_preview_icon = DragPreviewArtwork.new()
	drag_preview_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	drag_preview_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.add_child(drag_preview_icon)
	drag_preview_label = Label.new()
	drag_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drag_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drag_preview_label.add_theme_font_size_override("font_size", 10)
	drag_preview_label.add_theme_color_override("font_color", Color.WHITE)
	drag_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.add_child(drag_preview_label)
	drag_preview.visible = false
	for item_type in IngredientCabinet.get_all_item_types():
		var compatibility_stock_icon := TextureRect.new()
		compatibility_stock_icon.visible = false
		compatibility_stock_icon.texture = PrototypeArtCatalog.TEXTURES.get(ItemCatalog.get_art_key(item_type)) as Texture2D
		root_control.add_child(compatibility_stock_icon)
		stock_icons[item_type] = compatibility_stock_icon
		var take_button := Button.new()
		take_button.name = "TakeItem%d" % item_type
		take_button.visible = false
		take_button.pressed.connect(_on_legacy_take_pressed.bind(item_type))
		root_control.add_child(take_button)
		take_buttons[item_type] = take_button


func _on_quick_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_quick_drag(slot_index)


func _on_legacy_take_pressed(item_type: int) -> void:
	if cabinet != null and player != null:
		cabinet.request_take(item_type, player)
		_refresh_content()


func _on_grid_item_hovered(_item: CarryableItem, details: String) -> void:
	item_detail_label.text = details


func _on_grid_item_hover_ended() -> void:
	item_detail_label.text = "将鼠标移到物品上，查看完整名称、占格和状态"


func _ensure_backpack_input() -> void:
	if not InputMap.has_action("toggle_backpack"):
		InputMap.add_action("toggle_backpack")
	InputMap.action_erase_events("toggle_backpack")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	InputMap.action_add_event("toggle_backpack", tab)
	if not InputMap.has_action("rotate_inventory_item"):
		InputMap.add_action("rotate_inventory_item")
	InputMap.action_erase_events("rotate_inventory_item")
	var rotate := InputEventKey.new()
	rotate.physical_keycode = KEY_R
	InputMap.action_add_event("rotate_inventory_item", rotate)
