class_name PlatingQTEUI
extends CanvasLayer

var root_control: Control
var track: ColorRect
var perfect_zone: ColorRect
var pointer: ColorRect
var pointer_ratio: float = 0.0
var pointer_direction: float = 1.0
var config: PrototypeCombatConfig


func _ready() -> void:
	_build_ui()
	root_control.visible = false


func _process(delta: float) -> void:
	if not is_open() or config == null:
		return
	pointer_ratio += pointer_direction * config.qte_pointer_speed * delta
	if pointer_ratio >= 1.0:
		pointer_ratio = 1.0
		pointer_direction = -1.0
	elif pointer_ratio <= 0.0:
		pointer_ratio = 0.0
		pointer_direction = 1.0
	_refresh_pointer()


func open_qte(combat_config: PrototypeCombatConfig) -> void:
	config = combat_config
	pointer_ratio = 0.0
	pointer_direction = 1.0
	root_control.visible = true
	_refresh_pointer()


func close_qte() -> void:
	root_control.visible = false


func is_open() -> bool:
	return root_control != null and root_control.visible


func is_pointer_perfect() -> bool:
	return config != null and pointer_ratio >= config.qte_perfect_min and pointer_ratio <= config.qte_perfect_max


func set_pointer_ratio_for_test(value: float) -> void:
	pointer_ratio = clampf(value, 0.0, 1.0)
	_refresh_pointer()


func _refresh_pointer() -> void:
	if pointer == null or config == null:
		return
	pointer.position.x = track.position.x + pointer_ratio * (track.size.x - pointer.size.x)
	perfect_zone.position.x = track.position.x + config.qte_perfect_min * track.size.x
	perfect_zone.size.x = (config.qte_perfect_max - config.qte_perfect_min) * track.size.x


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "PlatingQTERoot"
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.46)
	shade.size = Vector2(952.0, 720.0)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(shade)
	var panel := ColorRect.new()
	panel.position = Vector2(180.0, 235.0)
	panel.size = Vector2(590.0, 210.0)
	panel.color = Color("20252e")
	root_control.add_child(panel)
	var title := Label.new()
	title.position = Vector2(0.0, 18.0)
	title.size = Vector2(590.0, 48.0)
	title.text = "摆盘 QTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("ffd166"))
	panel.add_child(title)
	var hint := Label.new()
	hint.position = Vector2(0.0, 158.0)
	hint.size = Vector2(590.0, 34.0)
	hint.text = "再次按 Space 确认 · 黄色区域为完美"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)
	track = ColorRect.new()
	track.position = Vector2(55.0, 94.0)
	track.size = Vector2(480.0, 34.0)
	track.color = Color("4a5568")
	panel.add_child(track)
	perfect_zone = ColorRect.new()
	perfect_zone.position = track.position
	perfect_zone.size = Vector2(70.0, 34.0)
	perfect_zone.color = Color("f4d35e")
	panel.add_child(perfect_zone)
	pointer = ColorRect.new()
	pointer.position = Vector2(track.position.x, 84.0)
	pointer.size = Vector2(8.0, 54.0)
	pointer.color = Color("f8f9fa")
	panel.add_child(pointer)
