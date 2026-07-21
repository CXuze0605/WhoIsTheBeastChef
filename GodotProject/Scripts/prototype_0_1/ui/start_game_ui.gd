class_name StartGameUI
extends CanvasLayer

var manager: PrototypeWaveManager
var root_control: Control
var start_button: Button


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
		PrototypeWaveManager.Phase.RUN_COMPLETE,
		PrototypeWaveManager.Phase.FAILED,
	]
	if manager != null:
		start_button.text = "开始营业" if manager.phase in [PrototypeWaveManager.Phase.FREE_PREPARATION, PrototypeWaveManager.Phase.INTERMISSION] else "重新开始"


func _on_start_pressed() -> void:
	if manager == null:
		return
	if manager.phase in [PrototypeWaveManager.Phase.FREE_PREPARATION, PrototypeWaveManager.Phase.INTERMISSION]:
		manager.start_service_early()
	else:
		manager.start_game()


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "StartGameRoot"
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var panel := PanelContainer.new()
	panel.position = Vector2(754.0, 104.0)
	panel.size = Vector2(182.0, 88.0)
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
	var hint := Label.new()
	hint.text = "自由准备中 · 世界继续运行"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)
	start_button = Button.new()
	start_button.name = "StartGameButton"
	start_button.text = "开始营业"
	start_button.custom_minimum_size = Vector2(0.0, 40.0)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.pressed.connect(_on_start_pressed)
	column.add_child(start_button)
