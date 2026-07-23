class_name WaveWarningUI
extends CanvasLayer

var manager: PrototypeWaveManager
var center_label: Label
var edge_label: Label


func _ready() -> void:
	layer = 15
	manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	_build_ui()


func _process(_delta: float) -> void:
	if manager == null:
		manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
		return
	center_label.visible = manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING
	if manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING:
		center_label.text = "味真族正在逼近！"
		center_label.modulate.a = 0.65 + sin(Time.get_ticks_msec() * 0.015) * 0.35
	edge_label.visible = manager.phase == PrototypeWaveManager.Phase.LOCAL_WARNING
	edge_label.text = "⚠ 下一批将从%s进入" % manager.current_edge_label
	edge_label.modulate.a = 0.55 + sin(Time.get_ticks_msec() * 0.022) * 0.45


func _build_ui() -> void:
	center_label = Label.new()
	center_label.position = Vector2(210.0, 210.0)
	center_label.size = Vector2(560.0, 140.0)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.add_theme_font_size_override("font_size", 34)
	center_label.add_theme_color_override("font_color", Color("ff6b6b"))
	center_label.add_theme_color_override("font_outline_color", Color("271f30"))
	center_label.add_theme_constant_override("outline_size", 8)
	center_label.visible = false
	add_child(center_label)
	edge_label = Label.new()
	# Keep the local-spawn warning clear of the top-left health HUD.
	edge_label.position = Vector2(340.0, 48.0)
	edge_label.size = Vector2(560.0, 54.0)
	edge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edge_label.add_theme_font_size_override("font_size", 24)
	edge_label.add_theme_color_override("font_color", Color("ffd166"))
	edge_label.add_theme_color_override("font_outline_color", Color("3d2b1f"))
	edge_label.add_theme_constant_override("outline_size", 6)
	edge_label.visible = false
	add_child(edge_label)
