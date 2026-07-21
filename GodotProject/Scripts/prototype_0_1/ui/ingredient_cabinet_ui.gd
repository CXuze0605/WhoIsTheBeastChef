class_name IngredientCabinetUI
extends CanvasLayer

@export var player_path: NodePath

var player: PrototypePlayer
var cabinet: IngredientCabinet
var root_control: Control
var inventory_label: Label
var feedback_label: Label
var stock_labels: Dictionary = {}
var take_buttons: Dictionary = {}
var opened_frame: int = -1
var previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	player = get_node(player_path) as PrototypePlayer
	add_to_group("ingredient_cabinet_ui")
	_build_ui()
	root_control.visible = false


func _process(_delta: float) -> void:
	if not is_open():
		return
	_refresh_content()
	if not is_instance_valid(cabinet) or player.global_position.distance_to(cabinet.global_position) > player.prototype_interaction_distance:
		close_cabinet()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") or (event.is_action_pressed("interact_primary") and Engine.get_process_frames() > opened_frame):
		close_cabinet()
		get_viewport().set_input_as_handled()


func open_cabinet(target_cabinet: IngredientCabinet, target_player: PrototypePlayer) -> void:
	if is_open():
		return
	cabinet = target_cabinet
	player = target_player
	opened_frame = Engine.get_process_frames()
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	root_control.visible = true
	player.set_modal_ui_open(true)
	feedback_label.text = "选择要取出的物品"
	_refresh_content()


func close_cabinet() -> void:
	if not is_open():
		return
	root_control.visible = false
	if player != null:
		player.set_modal_ui_open(false)
	Input.mouse_mode = previous_mouse_mode
	cabinet = null


func is_open() -> bool:
	return root_control != null and root_control.visible


func _on_take_pressed(item_type: int) -> void:
	if cabinet == null or player == null:
		return
	if cabinet.request_take(item_type, player):
		feedback_label.text = "已取出：%s" % ItemCatalog.create(item_type).display_name
	elif cabinet.get_stock(item_type) <= 0:
		feedback_label.text = "库存不足"
	else:
		feedback_label.text = "物品栏已满"
	_refresh_content()


func _refresh_content() -> void:
	if cabinet == null or player == null:
		return
	for item_type in cabinet.get_supported_item_types():
		var count := cabinet.get_stock(item_type)
		stock_labels[item_type].text = "%s    剩余：%d" % [ItemCatalog.create(item_type).display_name, count]
		take_buttons[item_type].disabled = count <= 0
	var slots: PackedStringArray = []
	for slot_index in QuickInventory.SLOT_COUNT:
		var item := player.inventory.get_item(slot_index)
		var marker := "▶" if slot_index == player.inventory.selected_index else " "
		var item_text := "空"
		if item != null:
			item_text = item.data.display_name + (" ×%d" % item.data.stack_count if item.data.is_stackable else "")
		slots.append("%s[%d] %s" % [marker, slot_index + 1, item_text])
	inventory_label.text = "玩家物品栏：\n%s" % "    ".join(slots)


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "CabinetRoot"
	root_control.position = Vector2.ZERO
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.52)
	shade.size = Vector2(952.0, 720.0)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(218.0, 42.0)
	panel.size = Vector2(520.0, 640.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20252e")
	style.border_color = Color("8ecae6")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", style)
	root_control.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 15)
	panel.add_child(column)
	var title := Label.new()
	title.text = "食材柜"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("ffd166"))
	column.add_child(title)

	for item_type in [ItemData.ItemType.RAW_BEEF_CHUNK, ItemData.ItemType.MARINADE, ItemData.ItemType.CHILI_SEGMENTS, ItemData.ItemType.COOKING_OIL, ItemData.ItemType.SALT, ItemData.ItemType.MUSTARD]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		column.add_child(row)
		var label := Label.new()
		label.custom_minimum_size = Vector2(340.0, 42.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		row.add_child(label)
		stock_labels[item_type] = label
		var button := Button.new()
		button.name = "TakeItem%d" % item_type
		button.text = "取出"
		button.custom_minimum_size = Vector2(100.0, 42.0)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(_on_take_pressed.bind(item_type))
		row.add_child(button)
		take_buttons[item_type] = button

	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.add_theme_font_size_override("font_size", 16)
	inventory_label.add_theme_color_override("font_color", Color("d7e3fc"))
	column.add_child(inventory_label)
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_color_override("font_color", Color("ffadad"))
	column.add_child(feedback_label)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "关闭（E / Esc）"
	close_button.custom_minimum_size = Vector2(0.0, 46.0)
	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(close_cabinet)
	column.add_child(close_button)
