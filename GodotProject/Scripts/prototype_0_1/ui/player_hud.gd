class_name PlayerHUD
extends CanvasLayer

@export var player_path: NodePath

var player: PrototypePlayer
var health_bar: ProgressBar
var health_label: Label
var shield_bar: ProgressBar
var shield_label: Label
var shield_status: Label
var stamina_row: HBoxContainer
var stamina_bar: ProgressBar
var stamina_label: Label
var stamina_status: Label
var armor_status: Label
var ghost_health_bar: ProgressBar
var ghost_health_value: float = 0.0
var ghost_health_target: float = 0.0
const GHOST_HEALTH_FOLLOW_SPEED := 25.0
var panel: PanelContainer
var danger_panel: PanelContainer
var danger_label: Label
var interaction_panel: PanelContainer
var interaction_label: Label
var flash_left: float = 0.0
var shield_flash_left: float = 0.0


func _ready() -> void:
	layer = 30
	player = get_node(player_path) as PrototypePlayer
	_build_ui()
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.shield_changed.connect(_on_shield_changed)
		player.stamina_changed.connect(_on_stamina_changed)
		player.shield_feedback.connect(_on_shield_feedback)
		_on_health_changed(player.current_health, player.prototype_max_health)
		_on_shield_changed(player.current_shield, player.prototype_max_shield)
		_on_stamina_changed(player.current_stamina, player.prototype_max_stamina)


func _process(delta: float) -> void:
	flash_left = maxf(0.0, flash_left - delta)
	shield_flash_left = maxf(0.0, shield_flash_left - delta)
	panel.modulate = Color("ff9b9b") if flash_left > 0.0 and int(flash_left * 20.0) % 2 == 0 else Color.WHITE
	if shield_bar != null:
		shield_bar.modulate = Color("ffffff") if shield_flash_left <= 0.0 or int(shield_flash_left * 24.0) % 2 == 0 else Color("66d9ff")
	if ghost_health_bar != null and ghost_health_value > ghost_health_target:
		ghost_health_value = maxf(ghost_health_target, ghost_health_value - GHOST_HEALTH_FOLLOW_SPEED * delta)
		ghost_health_bar.value = ghost_health_value
	_update_raging_bull_warning()
	_update_armor_status()
	_update_interaction_prompt()


func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar == null:
		return
	var previous := health_bar.value
	health_bar.max_value = maxf(maximum, 1.0)
	health_bar.value = current
	if ghost_health_bar != null:
		ghost_health_bar.max_value = maxf(maximum, 1.0)
		if current < previous:
			ghost_health_target = current
			ghost_health_value = maxf(ghost_health_value, previous)
		else:
			ghost_health_value = current
			ghost_health_target = current
		ghost_health_bar.value = ghost_health_value
	health_label.text = "%d / %d" % [roundi(current), roundi(maximum)]
	if current < previous:
		flash_left = 0.28


func _on_shield_changed(current: float, maximum: float) -> void:
	if shield_bar == null:
		return
	var previous := shield_bar.value
	shield_bar.max_value = maxf(maximum, 1.0)
	shield_bar.value = current
	shield_label.text = "%d / %d" % [roundi(current), roundi(maximum)]
	if current < previous:
		shield_flash_left = 0.32


func _on_shield_feedback(event_name: StringName) -> void:
	if shield_status == null:
		return
	match event_name:
		&"broken":
			shield_status.text = "◇ 护盾破碎"
			shield_status.add_theme_color_override("font_color", Color("ffb4a2"))
			shield_flash_left = 0.8
		&"regen_started":
			shield_status.text = "↻ 护盾恢复中"
			shield_status.add_theme_color_override("font_color", Color("90e0ef"))
		&"full":
			shield_status.text = "◆ 护盾充满"
			shield_status.add_theme_color_override("font_color", Color("caf0f8"))
		_:
			shield_status.text = "◇ 护盾受击"
			shield_status.add_theme_color_override("font_color", Color("ffd166"))


func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar == null:
		return
	stamina_bar.max_value = maxf(maximum, 1.0)
	stamina_bar.value = current
	stamina_label.text = "%d / %d" % [roundi(current), roundi(maximum)]
	var should_show := current < maximum - 0.01 or (player != null and player.is_sprinting)
	stamina_row.visible = should_show
	stamina_status.visible = should_show
	if player != null and player.sprint_exhausted:
		stamina_status.text = "体力耗尽 · 松开疾跑键后可再次起跑"
		stamina_status.add_theme_color_override("font_color", Color("ffb86b"))
	elif player != null and player.is_sprinting:
		stamina_status.text = "疾跑中"
		stamina_status.add_theme_color_override("font_color", Color("ffe08a"))
	else:
		stamina_status.text = "体力恢复中"
		stamina_status.add_theme_color_override("font_color", Color("b8e986"))


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "PlayerHealthPanel"
	panel.position = Vector2(20.0, 18.0)
	panel.size = Vector2(300.0, 194.0)
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
	var health_stack := Control.new()
	health_stack.name = "HealthBarStack"
	health_stack.custom_minimum_size = Vector2(190.0, 25.0)
	row.add_child(health_stack)
	ghost_health_bar = ProgressBar.new()
	ghost_health_bar.name = "HealthGhostBar"
	ghost_health_bar.custom_minimum_size = Vector2(190.0, 25.0)
	ghost_health_bar.show_percentage = false
	var ghost_fill := StyleBoxFlat.new()
	ghost_fill.bg_color = Color("e53935")
	ghost_fill.border_color = Color("b71c1c")
	ghost_fill.set_border_width_all(1)
	ghost_fill.set_corner_radius_all(3)
	ghost_health_bar.add_theme_stylebox_override("fill", ghost_fill)
	var ghost_background := StyleBoxFlat.new()
	ghost_background.bg_color = Color(0.0, 0.0, 0.0, 0.35)
	ghost_background.border_color = Color(0.0, 0.0, 0.0, 1.0)
	ghost_background.set_border_width_all(1)
	ghost_background.set_corner_radius_all(3)
	ghost_health_bar.add_theme_stylebox_override("background", ghost_background)
	ghost_health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_stack.add_child(ghost_health_bar)
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(190.0, 25.0)
	health_bar.show_percentage = false
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("4caf50")
	health_fill.border_color = Color("2e7d32")
	health_fill.set_border_width_all(1)
	health_fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	var health_background := StyleBoxFlat.new()
	health_background.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_stack.add_child(health_bar)
	health_label = Label.new()
	health_label.name = "HealthValue"
	health_label.custom_minimum_size = Vector2(72.0, 25.0)
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	health_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(health_label)
	var shield_row := HBoxContainer.new()
	shield_row.add_theme_constant_override("separation", 8)
	column.add_child(shield_row)
	shield_bar = ProgressBar.new()
	shield_bar.name = "ShieldBar"
	shield_bar.custom_minimum_size = Vector2(190.0, 20.0)
	shield_bar.show_percentage = false
	var shield_fill := StyleBoxFlat.new()
	shield_fill.bg_color = Color("219ebc")
	shield_fill.border_color = Color("caf0f8")
	shield_fill.set_border_width_all(2)
	shield_fill.set_corner_radius_all(3)
	shield_bar.add_theme_stylebox_override("fill", shield_fill)
	shield_row.add_child(shield_bar)
	shield_label = Label.new()
	shield_label.name = "ShieldValue"
	shield_label.custom_minimum_size = Vector2(72.0, 20.0)
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shield_label.add_theme_color_override("font_color", Color("caf0f8"))
	shield_row.add_child(shield_label)
	shield_status = Label.new()
	shield_status.name = "ShieldStatus"
	shield_status.text = "◆ 护盾充满"
	shield_status.add_theme_font_size_override("font_size", 12)
	shield_status.add_theme_color_override("font_color", Color("caf0f8"))
	column.add_child(shield_status)
	stamina_row = HBoxContainer.new()
	stamina_row.name = "StaminaRow"
	stamina_row.add_theme_constant_override("separation", 8)
	column.add_child(stamina_row)
	stamina_bar = ProgressBar.new()
	stamina_bar.name = "StaminaBar"
	stamina_bar.custom_minimum_size = Vector2(190.0, 18.0)
	stamina_bar.show_percentage = false
	var stamina_fill := StyleBoxFlat.new()
	stamina_fill.bg_color = Color("e9b949")
	stamina_fill.border_color = Color("ffe8a3")
	stamina_fill.set_border_width_all(2)
	stamina_fill.set_corner_radius_all(3)
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill)
	stamina_row.add_child(stamina_bar)
	stamina_label = Label.new()
	stamina_label.name = "StaminaValue"
	stamina_label.custom_minimum_size = Vector2(72.0, 18.0)
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamina_label.add_theme_color_override("font_color", Color("ffe8a3"))
	stamina_row.add_child(stamina_label)
	stamina_status = Label.new()
	stamina_status.name = "StaminaStatus"
	stamina_status.text = "体力恢复中"
	stamina_status.add_theme_font_size_override("font_size", 12)
	stamina_status.add_theme_color_override("font_color", Color("b8e986"))
	column.add_child(stamina_status)
	armor_status = Label.new()
	armor_status.name = "CrispyRiceArmorStatus"
	armor_status.text = "锅巴防具：无"
	armor_status.add_theme_font_size_override("font_size", 12)
	armor_status.add_theme_color_override("font_color", Color("dda15e"))
	column.add_child(armor_status)

	danger_panel = PanelContainer.new()
	danger_panel.name = "FriendlyFireDangerPanel"
	danger_panel.position = Vector2(20.0, 222.0)
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

	interaction_panel = PanelContainer.new()
	interaction_panel.name = "InteractionPromptPanel"
	interaction_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_panel.position = Vector2(-300.0, -178.0)
	interaction_panel.size = Vector2(600.0, 58.0)
	var interaction_style := StyleBoxFlat.new()
	interaction_style.bg_color = Color(0.035, 0.055, 0.085, 0.94)
	interaction_style.border_color = Color("ffd166")
	interaction_style.set_border_width_all(3)
	interaction_style.set_corner_radius_all(8)
	interaction_style.content_margin_left = 16.0
	interaction_style.content_margin_right = 16.0
	interaction_style.content_margin_top = 8.0
	interaction_style.content_margin_bottom = 8.0
	interaction_panel.add_theme_stylebox_override("panel", interaction_style)
	add_child(interaction_panel)
	interaction_label = Label.new()
	interaction_label.name = "InteractionPrompt"
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 18)
	interaction_label.add_theme_color_override("font_color", Color("fff3bf"))
	interaction_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	interaction_label.add_theme_constant_override("shadow_offset_x", 2)
	interaction_label.add_theme_constant_override("shadow_offset_y", 2)
	interaction_panel.add_child(interaction_label)
	interaction_panel.visible = false


func _update_interaction_prompt() -> void:
	if interaction_panel == null or interaction_label == null or player == null:
		return
	var target := player.current_target
	var visible_target := is_instance_valid(target) and target.can_interact(player)
	interaction_panel.visible = visible_target
	if visible_target:
		interaction_label.text = player.get_interaction_prompt()


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


func _update_armor_status() -> void:
	if armor_status == null or player == null:
		return
	var armor := player.get_active_crispy_rice()
	if armor == null:
		armor_status.text = "锅巴防具：无"
		return
	armor_status.text = "▣ 锅巴生效：减伤 %d%% · %d/%d" % [
		roundi(armor.data.armor_reduction * 100.0),
		armor.data.current_durability,
		armor.data.max_durability,
	]
