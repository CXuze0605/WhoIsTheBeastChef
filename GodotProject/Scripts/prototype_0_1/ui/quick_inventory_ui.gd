class_name QuickInventoryUI
extends CanvasLayer

@export var player_path: NodePath

var player: PrototypePlayer
var slot_panels: Array[PanelContainer] = []
var slot_labels: Array[Label] = []
var selected_style: StyleBoxFlat
var normal_style: StyleBoxFlat


func _ready() -> void:
	player = get_node(player_path) as PrototypePlayer
	selected_style = _make_slot_style(true)
	normal_style = _make_slot_style(false)
	_build_ui()


func _process(_delta: float) -> void:
	if player == null:
		return
	for slot_index in QuickInventory.SLOT_COUNT:
		var item := player.inventory.get_item(slot_index)
		var item_name := "空"
		if item != null:
			item_name = item.data.display_name + (" ×%d" % item.data.stack_count if item.data.is_stackable else "")
		slot_labels[slot_index].text = "格子 %d\n%s" % [slot_index + 1, item_name]
		var selected := slot_index == player.inventory.selected_index
		slot_panels[slot_index].add_theme_stylebox_override("panel", selected_style if selected else normal_style)


func _build_ui() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(100.0, 566.0)
	column.size = Vector2(752.0, 92.0)
	column.add_theme_constant_override("separation", 4)
	add_child(column)

	var hint := Label.new()
	hint.text = "Prototype 五格快捷栏 · 鼠标滚轮 / 数字键 1—5 切换"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("d7e3fc"))
	hint.add_theme_color_override("font_outline_color", Color("202027"))
	hint.add_theme_constant_override("outline_size", 3)
	column.add_child(hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for slot_index in QuickInventory.SLOT_COUNT:
		var panel := PanelContainer.new()
		panel.name = "Slot%d" % (slot_index + 1)
		panel.custom_minimum_size = Vector2(144.0, 58.0)
		row.add_child(panel)
		slot_panels.append(panel)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 15)
		panel.add_child(label)
		slot_labels.append(label)


func _make_slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("576574") if selected else Color("252a33")
	style.border_color = Color("ffd166") if selected else Color("6c757d")
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(6)
	return style
