class_name InventoryGridView
extends Control

signal item_pressed(item: CarryableItem, cell: Vector2i)
signal item_double_clicked(item: CarryableItem, cell: Vector2i)
signal item_hovered(item: CarryableItem, details: String)
signal item_hover_ended

var inventory: GridInventory
var cell_size: float = 42.0
var grid_label: String = ""
var hidden_drag_item: CarryableItem
var drop_preview_cells: Array[Vector2i] = []
var hovered_item: CarryableItem


func setup(target_inventory: GridInventory, target_cell_size: float, label_text: String) -> void:
	inventory = target_inventory
	cell_size = target_cell_size
	grid_label = label_text
	custom_minimum_size = Vector2(inventory.width, inventory.height) * cell_size
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not inventory.changed.is_connected(queue_redraw):
		inventory.changed.connect(queue_redraw)
	queue_redraw()


func get_cell_at_global(global_mouse: Vector2) -> Vector2i:
	var local := global_mouse - global_position
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))


func contains_global(global_mouse: Vector2) -> bool:
	return get_global_rect().has_point(global_mouse)


func get_item_at_global(global_mouse: Vector2) -> CarryableItem:
	if inventory == null or not contains_global(global_mouse):
		return null
	return inventory.get_item_at(get_cell_at_global(global_mouse))


func set_hidden_drag_item(item: CarryableItem) -> void:
	hidden_drag_item = item
	queue_redraw()


func set_drop_preview(item: CarryableItem, origin: Vector2i, rotated: bool) -> void:
	drop_preview_cells.clear()
	if item != null and item.data != null:
		for shape_cell in ItemStorageCatalog.get_shape_cells_for_data(item.data, rotated):
			drop_preview_cells.append(origin + shape_cell)
	queue_redraw()


func clear_drop_preview() -> void:
	if drop_preview_cells.is_empty():
		return
	drop_preview_cells.clear()
	queue_redraw()


func get_item_art_rotation_degrees(item: CarryableItem) -> float:
	if inventory == null:
		return 0.0
	var placement := inventory.get_placement(item)
	return 90.0 if placement != null and placement.rotated else 0.0


func get_item_art_source_rect(item: CarryableItem) -> Rect2:
	if item == null or item.data == null:
		return Rect2()
	var art_key := ItemCatalog.get_art_key_for_data(item.data)
	var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
	return PrototypeArtCatalog.get_ui_source_rect(art_key, texture)


func _gui_input(event: InputEvent) -> void:
	if inventory == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := Vector2i(floori(event.position.x / cell_size), floori(event.position.y / cell_size))
		var item := inventory.get_item_at(cell)
		if item != null:
			if event.double_click:
				item_double_clicked.emit(item, cell)
			else:
				item_pressed.emit(item, cell)
			accept_event()
	elif event is InputEventMouseMotion:
		_update_hovered_item(inventory.get_item_at(Vector2i(
			floori(event.position.x / cell_size),
			floori(event.position.y / cell_size)
		)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_update_hovered_item(null)


func _get_tooltip(at_position: Vector2) -> String:
	if inventory == null:
		return ""
	var item := inventory.get_item_at(Vector2i(
		floori(at_position.x / cell_size),
		floori(at_position.y / cell_size)
	))
	return get_item_detail_text(item)


func get_item_detail_text(item: CarryableItem) -> String:
	if item == null or item.data == null or inventory == null:
		return ""
	var placement := inventory.get_placement(item)
	var rotated := placement != null and placement.rotated
	var bounds := ItemStorageCatalog.get_shape_bounds(
		ItemStorageCatalog.get_shape_cells_for_data(item.data, rotated)
	)
	var summary := item.data.display_name
	if item.data.is_stackable:
		summary += " ×%d" % item.data.stack_count
	if item.data.is_reusable_resource_container():
		summary += " · %s" % item.data.get_portion_label()
	summary += "  ·  占格 %d×%d" % [bounds.x, bounds.y]
	var states: PackedStringArray = []
	if item.data.is_combat_dish:
		states.append("品质：%s" % item.data.get_quality_text())
	if not item.data.failure_tags.is_empty():
		states.append("失败：%s" % item.data.get_failure_tags_text())
	if not item.data.active_modifiers.is_empty():
		states.append("调味：%s" % item.data.get_active_modifiers_text())
	if item.data.recipe_id in [
		ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
		ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
	]:
		states.append("自动喷流：%s（双击切换）" % ("开启" if item.data.auto_equipment_enabled else "关闭"))
	if item.data.recipe_id == ExpandedRecipeCatalog.MUSTARD_GREENS:
		states.append("关联标记：%d（携带者持续易伤）" % item.data.linked_target_ids.size())
	if item.data.is_perishable():
		states.append("新鲜度：%s" % item.data.get_freshness_text())
	if item.data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		states.append("腐败来源：%s" % item.data.rotten_source_name)
		states.append("浪费份量：%d%s" % [item.data.waste_units_snapshot, "（已结算）" if item.data.waste_penalty_settled else ""])
	return summary if states.is_empty() else "%s\n%s" % [summary, "  ·  ".join(states)]


func _draw() -> void:
	if inventory == null:
		return
	var background := Color(0.055, 0.067, 0.086, 0.96)
	var line := Color(0.28, 0.34, 0.42, 0.95)
	draw_rect(Rect2(Vector2.ZERO, size), background, true)
	for x in inventory.width + 1:
		draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, inventory.height * cell_size), line, 1.0)
	for y in inventory.height + 1:
		draw_line(Vector2(0, y * cell_size), Vector2(inventory.width * cell_size, y * cell_size), line, 1.0)
	for placement in inventory.placements:
		var item := placement.item
		if item == null or item.data == null or item == hidden_drag_item:
			continue
		var occupied := inventory.get_cells_for_placement(placement)
		var color := ItemCatalog.get_item_color(item.data.item_type)
		for cell in occupied:
			var rect := Rect2(Vector2(cell) * cell_size + Vector2.ONE * 2.0, Vector2.ONE * (cell_size - 4.0))
			draw_rect(rect, color.darkened(0.18), true)
			draw_rect(rect, color.lightened(0.22), false, 2.0)
		var bounds := ItemStorageCatalog.get_shape_bounds(ItemStorageCatalog.get_shape_cells_for_data(item.data, placement.rotated))
		var item_rect := Rect2(Vector2(placement.origin) * cell_size + Vector2.ONE * 4.0, Vector2(bounds) * cell_size - Vector2.ONE * 8.0)
		var art_key := ItemCatalog.get_art_key_for_data(item.data)
		var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
		if texture != null:
			_draw_item_texture(
				texture,
				item_rect,
				placement.rotated,
				PrototypeArtCatalog.get_ui_source_rect(art_key, texture)
			)
		var freshness_overlay := _get_freshness_overlay(item.data)
		if freshness_overlay.a > 0.0:
			draw_rect(item_rect, freshness_overlay, true)
			draw_rect(item_rect.grow(-1.0), _get_freshness_border(item.data), false, 3.0)
		if item_rect.size.x >= cell_size * 2.7:
			var name_rect := Rect2(item_rect.position + Vector2(2.0, 2.0), Vector2(item_rect.size.x - 4.0, 19.0))
			draw_rect(name_rect, Color(0.04, 0.05, 0.07, 0.78), true)
			draw_string(
				ThemeDB.fallback_font,
				name_rect.position + Vector2(4.0, 14.0),
				_fit_text_with_ellipsis(item.data.display_name, name_rect.size.x - 8.0, 11),
				HORIZONTAL_ALIGNMENT_LEFT,
				name_rect.size.x - 8.0,
				11,
				Color.WHITE
			)
		if item.data.is_stackable and item.data.stack_count > 1:
			var count_text := "×%d" % item.data.stack_count
			var count_size := ThemeDB.fallback_font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12)
			var count_rect := Rect2(
				item_rect.end - count_size - Vector2(10.0, 19.0),
				count_size + Vector2(8.0, 5.0)
			)
			draw_rect(count_rect, Color(0.04, 0.05, 0.07, 0.88), true)
			draw_string(ThemeDB.fallback_font, count_rect.position + Vector2(4.0, 14.0), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
		elif item.data.is_reusable_resource_container():
			var portion_text := "%d/%d" % [item.data.remaining_portions, item.data.max_remaining_portions]
			var portion_size := ThemeDB.fallback_font.get_string_size(portion_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12)
			var portion_rect := Rect2(
				item_rect.end - portion_size - Vector2(10.0, 19.0),
				portion_size + Vector2(8.0, 5.0)
			)
			draw_rect(portion_rect, Color(0.04, 0.05, 0.07, 0.88), true)
			draw_string(ThemeDB.fallback_font, portion_rect.position + Vector2(4.0, 14.0), portion_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("ffe082"))
		var state_text := ""
		if item.data.is_combat_dish:
			state_text = item.data.get_quality_text()
		elif not item.data.failure_tags.is_empty():
			state_text = item.data.get_failure_tags_text()
		elif not item.data.active_modifiers.is_empty():
			state_text = item.data.get_active_modifiers_text()
		if not state_text.is_empty() and item_rect.size.x >= cell_size * 1.7:
			var state_size := ThemeDB.fallback_font.get_string_size(state_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10)
			var state_rect := Rect2(
				Vector2(item_rect.position.x + 2.0, item_rect.end.y - 19.0),
				Vector2(minf(item_rect.size.x - 4.0, state_size.x + 8.0), 17.0)
			)
			draw_rect(state_rect, Color(0.14, 0.09, 0.03, 0.84), true)
			draw_string(ThemeDB.fallback_font, state_rect.position + Vector2(4.0, 12.0), state_text, HORIZONTAL_ALIGNMENT_LEFT, state_rect.size.x - 8.0, 10, Color("ffe08a"))
		if item == hovered_item:
			draw_rect(item_rect.grow(1.0), Color("ffd166"), false, 3.0)
		if _is_active_crispy_rice(item):
			draw_rect(item_rect.grow(2.0), Color("5eead4"), false, 4.0)
		if item.data.auto_equipment_enabled:
			draw_rect(item_rect.grow(2.0), Color("4cc9f0"), false, 4.0)
	var drop_fill := Color(0.95, 0.08, 0.08, 0.20)
	var drop_border := Color(1.0, 0.12, 0.12, 1.0)
	for cell in drop_preview_cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= inventory.width or cell.y >= inventory.height:
			continue
		var rect := Rect2(Vector2(cell) * cell_size + Vector2.ONE * 1.5, Vector2.ONE * (cell_size - 3.0))
		draw_rect(rect, drop_fill, true)
		draw_rect(rect, drop_border, false, 3.0)


func _draw_item_texture(texture: Texture2D, target_rect: Rect2, rotated: bool, source_rect: Rect2) -> void:
	if texture == null or target_rect.size.x <= 0.0 or target_rect.size.y <= 0.0:
		return
	if source_rect.size.x <= 0.0 or source_rect.size.y <= 0.0:
		source_rect = Rect2(Vector2.ZERO, texture.get_size())
	if not rotated:
		var fitted_size := _fit_source_size(source_rect.size, target_rect.size)
		var fitted_rect := Rect2(target_rect.get_center() - fitted_size * 0.5, fitted_size)
		draw_texture_rect_region(texture, fitted_rect, source_rect, Color.WHITE)
		return
	var unrotated_bounds := Vector2(target_rect.size.y, target_rect.size.x)
	var unrotated_size := _fit_source_size(source_rect.size, unrotated_bounds)
	draw_set_transform(target_rect.get_center(), PI * 0.5, Vector2.ONE)
	draw_texture_rect_region(texture, Rect2(-unrotated_size * 0.5, unrotated_size), source_rect, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _fit_source_size(source_size: Vector2, bounds: Vector2) -> Vector2:
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return bounds
	var fit_scale := minf(bounds.x / source_size.x, bounds.y / source_size.y)
	return source_size * fit_scale


func _is_active_crispy_rice(item: CarryableItem) -> bool:
	if item == null or get_tree() == null:
		return false
	var player := get_tree().get_first_node_in_group("player") as PrototypePlayer
	return player != null and player.get_active_crispy_rice() == item


func _get_freshness_overlay(data: ItemData) -> Color:
	if data == null:
		return Color.TRANSPARENT
	match data.get_freshness_state():
		ItemData.FreshnessState.STILL_FRESH:
			return Color(1.0, 0.86, 0.26, 0.08)
		ItemData.FreshnessState.NEAR_EXPIRY:
			return Color(1.0, 0.43, 0.06, 0.18)
		ItemData.FreshnessState.ROTTEN:
			return Color(0.24, 0.38, 0.20, 0.38)
	return Color.TRANSPARENT


func _get_freshness_border(data: ItemData) -> Color:
	match data.get_freshness_state():
		ItemData.FreshnessState.STILL_FRESH:
			return Color("e9c46a")
		ItemData.FreshnessState.NEAR_EXPIRY:
			return Color("f77f00")
		ItemData.FreshnessState.ROTTEN:
			return Color("6b7d4f")
	return Color("55c271")


func _update_hovered_item(item: CarryableItem) -> void:
	if item == hovered_item:
		return
	hovered_item = item
	queue_redraw()
	if hovered_item == null:
		item_hover_ended.emit()
	else:
		item_hovered.emit(hovered_item, get_item_detail_text(hovered_item))


func _fit_text_with_ellipsis(text: String, max_width: float, font_size: int) -> String:
	if ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= max_width:
		return text
	var result := text
	while result.length() > 1:
		result = result.left(result.length() - 1)
		var candidate := result + "…"
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x <= max_width:
			return candidate
	return "…"
