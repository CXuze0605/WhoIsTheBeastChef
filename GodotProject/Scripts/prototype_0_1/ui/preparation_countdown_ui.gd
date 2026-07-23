class_name PreparationCountdownUI
extends CanvasLayer

var manager: PrototypeWaveManager
var root_control: Control
var countdown_label: Label


func _ready() -> void:
	layer = 35
	manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	_build_ui()


func _process(_delta: float) -> void:
	if manager == null:
		manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	root_control.visible = manager != null and manager.phase == PrototypeWaveManager.Phase.PREPARATION
	if root_control.visible:
		countdown_label.text = "营业准备  %02d:%02d" % [floori(manager.preparation_left / 60.0), ceili(manager.preparation_left) % 60]


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "PreparationCountdownRoot"
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	var panel := PanelContainer.new()
	panel.position = Vector2(440.0, 18.0)
	panel.size = Vector2(400.0, 72.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.94)
	style.border_color = Color("ffd166")
	style.set_border_width_all(3)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", style)
	root_control.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "营业准备  00:32"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 26)
	countdown_label.add_theme_color_override("font_color", Color("ffd166"))
	column.add_child(countdown_label)
	var hint := Label.new()
	hint.text = "倒计时结束后第一波味真族来袭"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("d7e3fc"))
	column.add_child(hint)
	root_control.visible = false
