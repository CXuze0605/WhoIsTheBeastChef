class_name StartGameUI
extends CanvasLayer

const ACTION_PANEL_POSITION := Vector2(20.0, 238.0)
const ACTION_PANEL_SIZE := Vector2(218.0, 88.0)

var manager: PrototypeWaveManager
var root_control: Control
var start_button: Button
var hint_label: Label


func _ready() -> void:
	layer = 40
	manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	_build_ui()


func _process(_delta: float) -> void:
	if manager == null:
		manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	root_control.visible = manager != null and manager.phase in [
		PrototypeWaveManager.Phase.FREE_PREPARATION,
		PrototypeWaveManager.Phase.INTERMISSION,
	]
	if manager != null:
		var start_key := InputPrompt.action_text(&"start_service", "B")
		start_button.text = (
			"开始营业 [%s]" % start_key
			if manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION
			else "提前开始下一波 [%s]" % start_key
		)
		hint_label.text = "自由大厅 · 可测试与准备" if manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION else "波间准备 %.0f 秒" % manager.preparation_left


func _on_start_pressed() -> void:
	if manager == null:
		return
	manager.start_service_early()


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "StartGameRoot"
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var panel := PanelContainer.new()
	panel.position = ACTION_PANEL_POSITION
	panel.size = ACTION_PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20252e")
	style.border_color = Color("ffd166")
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	root_control.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	hint_label = Label.new()
	hint_label.text = "自由大厅 · 可测试与准备"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	column.add_child(hint_label)
	start_button = Button.new()
	start_button.name = "StartGameButton"
	start_button.text = "开始营业"
	start_button.custom_minimum_size = Vector2(0.0, 40.0)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(_on_start_pressed)
	column.add_child(start_button)
