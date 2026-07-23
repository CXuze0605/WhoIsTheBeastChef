class_name QuickInventoryUI
extends CanvasLayer

@export var player_path: NodePath

var player: PrototypePlayer
var slot_panels: Array[PanelContainer] = []
var slot_labels: Array[Label] = []
var slot_icons: Array[TextureRect] = []
var slot_icon_styles: Array[StyleBoxFlat] = []
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
		_refresh_slot_content(slot_index, item)
		var selected := slot_index == player.inventory.selected_index
		slot_panels[slot_index].add_theme_stylebox_override("panel", selected_style if selected else normal_style)


func _build_ui() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(100.0, 540.0)
	column.size = Vector2(752.0, 116.0)
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
		panel.custom_minimum_size = Vector2(144.0, 80.0)
		row.add_child(panel)
		slot_panels.append(panel)
		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 1)
		panel.add_child(stack)
		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(112.0, 52.0)
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color("151820")
		icon_style.set_corner_radius_all(4)
		icon_style.content_margin_left = 4.0
		icon_style.content_margin_right = 4.0
		icon_style.content_margin_top = 2.0
		icon_style.content_margin_bottom = 2.0
		icon_panel.add_theme_stylebox_override("panel", icon_style)
		stack.add_child(icon_panel)
		slot_icon_styles.append(icon_style)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_panel.add_child(icon)
		slot_icons.append(icon)
		var label := Label.new()
		label.custom_minimum_size = Vector2(0.0, 20.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		stack.add_child(label)
		slot_labels.append(label)


func _refresh_slot_content(slot_index: int, item: CarryableItem) -> void:
	var label := slot_labels[slot_index]
	var icon := slot_icons[slot_index]
	var icon_style := slot_icon_styles[slot_index]
	if item == null or not is_instance_valid(item) or item.data == null:
		icon.texture = null
		icon_style.bg_color = Color("151820")
		label.text = "%d · 空" % (slot_index + 1)
		label.tooltip_text = "空格"
		return
	var art_key := ItemCatalog.get_art_key_for_data(item.data)
	var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
	icon.texture = texture
	icon_style.bg_color = Color("151820") if texture != null else ItemCatalog.get_item_color(item.data.item_type).darkened(0.42)
	var count_text := " ×%d" % item.data.stack_count if item.data.is_stackable else ""
	label.text = "%d%s" % [slot_index + 1, count_text] if texture != null else "%d · %s%s" % [slot_index + 1, item.data.display_name, count_text]
	label.tooltip_text = item.data.display_name


func _make_slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("576574") if selected else Color("252a33")
	style.border_color = Color("ffd166") if selected else Color("6c757d")
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(6)
	return style
