class_name PlayerHUD
extends CanvasLayer

@export var player_path: NodePath

var player: PrototypePlayer
var health_bar: ProgressBar
var health_label: Label
var panel: PanelContainer
var danger_panel: PanelContainer
var danger_label: Label
var flash_left: float = 0.0


func _ready() -> void:
	layer = 30
	player = get_node(player_path) as PrototypePlayer
	_build_ui()
	if player != null:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health, player.prototype_max_health)


func _process(delta: float) -> void:
	flash_left = maxf(0.0, flash_left - delta)
	panel.modulate = Color("ff9b9b") if flash_left > 0.0 and int(flash_left * 20.0) % 2 == 0 else Color.WHITE
	_update_raging_bull_warning()


func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar == null:
		return
	var previous := health_bar.value
	health_bar.max_value = maxf(maximum, 1.0)
	health_bar.value = current
	health_label.text = "%d / %d" % [roundi(current), roundi(maximum)]
	if current < previous:
		flash_left = 0.28


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "PlayerHealthPanel"
	panel.position = Vector2(20.0, 18.0)
	panel.size = Vector2(300.0, 76.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.92)
	style.border_color = Color("8ecae6")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	var title := Label.new()
	title.text = "玩家生命"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("d7e3fc"))
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(190.0, 25.0)
	health_bar.show_percentage = false
	row.add_child(health_bar)
	health_label = Label.new()
	health_label.name = "HealthValue"
	health_label.custom_minimum_size = Vector2(72.0, 25.0)
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(health_label)

	danger_panel = PanelContainer.new()
	danger_panel.name = "FriendlyFireDangerPanel"
	danger_panel.position = Vector2(20.0, 102.0)
	danger_panel.size = Vector2(340.0, 52.0)
	var danger_style := StyleBoxFlat.new()
	danger_style.bg_color = Color(0.42, 0.03, 0.05, 0.94)
	danger_style.border_color = Color("ff6b6b")
	danger_style.set_border_width_all(3)
	danger_style.set_corner_radius_all(7)
	danger_style.content_margin_left = 10.0
	danger_style.content_margin_right = 10.0
	danger_style.content_margin_top = 6.0
	danger_style.content_margin_bottom = 6.0
	danger_panel.add_theme_stylebox_override("panel", danger_style)
	add_child(danger_panel)
	danger_label = Label.new()
	danger_label.text = "⚠ 大型公牛接近，会造成友伤！"
	danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	danger_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	danger_label.add_theme_font_size_override("font_size", 16)
	danger_label.add_theme_color_override("font_color", Color.WHITE)
	danger_panel.add_child(danger_label)
	danger_panel.visible = false


func _update_raging_bull_warning() -> void:
	if danger_panel == null or player == null:
		return
	var danger_nearby := false
	for node in get_tree().get_nodes_in_group("raging_bull"):
		var bull := node as RagingBull
		if bull != null and bull.config != null and bull.global_position.distance_to(player.global_position) <= bull.config.raging_bull_warning_distance:
			danger_nearby = true
			break
	danger_panel.visible = danger_nearby
	if danger_nearby:
		danger_panel.modulate.a = 0.72 + sin(Time.get_ticks_msec() * 0.018) * 0.28
