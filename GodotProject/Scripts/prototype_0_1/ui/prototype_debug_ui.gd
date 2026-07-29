class_name PrototypeDebugUI
extends CanvasLayer

@export var player_path: NodePath

var player: PrototypePlayer
var held_label: Label
var target_label: Label
var prompt_label: Label
var item_label: Label
var station_label: Label
var stock_label: Label
var feedback_label: Label
var combat_label: Label
var plate_label: Label
var wave_label: Label
var controls_label: Label
var progress_bar: ProgressBar
var enemy_dummy_a: DebugCombatTarget
var auto_attack_toggle: CheckButton


func _ready() -> void:
	player = get_node(player_path) as PrototypePlayer
	enemy_dummy_a = get_node_or_null("../Kitchen/EnemyDummyA") as DebugCombatTarget
	_build_ui()
	if enemy_dummy_a != null:
		enemy_dummy_a.auto_attack_changed.connect(_on_dummy_auto_attack_changed)
	set_developer_ui_visible(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_ui"):
		set_developer_ui_visible(not visible)
		get_viewport().set_input_as_handled()


func set_developer_ui_visible(active: bool) -> void:
	visible = active


func is_developer_ui_visible() -> bool:
	return visible


func _process(_delta: float) -> void:
	if player == null:
		return
	_refresh_auto_attack_toggle()
	controls_label.text = _get_controls_text()
	held_label.text = "手持：\n%s" % (player.held_item.get_debug_description() if player.held_item != null else "空")
	var target := player.current_target
	target_label.text = "当前目标：%s" % (target.display_title if target != null else "无")
	prompt_label.text = "可用操作：\n%s" % player.get_interaction_prompt()
	station_label.text = "工位状态：\n%s" % (target.get_debug_state() if target != null else "靠近设施查看")
	var inspected := player.get_inspected_item_data()
	if inspected != null:
		var combat_text := ""
		if inspected.is_combat_dish:
			combat_text = "\n耐久：%d/%d  伤害：%.1f\n完美终结：%s" % [inspected.current_durability, inspected.max_durability, inspected.actual_damage, "是" if inspected.has_perfect_finisher else "否"]
		item_label.text = "当前物品数据：\n名称：%s\n失败标签：%s\n主动调味：%s\n怪异料理：%s\n品质：%s%s" % [inspected.display_name, inspected.get_failure_tags_text(), inspected.get_active_modifiers_text(), "是" if inspected.is_weird_dish() else "否", inspected.get_quality_text(), combat_text]
	else:
		item_label.text = "当前物品数据：无"
	stock_label.text = _get_stock_text()
	feedback_label.text = "操作反馈：\n%s" % player.get_visible_feedback()
	combat_label.text = _get_combat_text()
	plate_label.text = _get_plate_text()
	wave_label.text = _get_wave_text()
	var progress := 0.0
	if player.active_interactable != null:
		progress = player.active_interactable.get_progress_ratio()
	elif target != null:
		progress = target.get_progress_ratio()
	progress_bar.value = progress * 100.0
	progress_bar.visible = progress > 0.0


func _build_ui() -> void:
	var background := ColorRect.new()
	background.name = "DebugPanel"
	background.position = Vector2(952.0, 0.0)
	background.size = Vector2(328.0, 720.0)
	background.color = Color(0.06, 0.07, 0.09, 0.94)
	add_child(background)

	var margin := MarginContainer.new()
	margin.position = Vector2(964.0, 10.0)
	margin.size = Vector2(304.0, 700.0)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var title := _make_label("Prototype 0.5 / 开发辅助 UI\nF3 可切换玩家模式 · 非最终数值", 17, Color("ffd166"))
	column.add_child(title)
	controls_label = _make_label(_get_controls_text(), 12, Color("d7e3fc"))
	column.add_child(controls_label)
	wave_label = _make_label("波次：等待初始化", 12, Color("ffd166"))
	column.add_child(wave_label)
	held_label = _make_label("手持：空", 14, Color.WHITE)
	column.add_child(held_label)
	target_label = _make_label("当前目标：无", 14, Color("8ecae6"))
	column.add_child(target_label)
	prompt_label = _make_label("可用操作：", 14, Color("90be6d"))
	column.add_child(prompt_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0.0, 22.0)
	progress_bar.show_percentage = true
	progress_bar.visible = false
	column.add_child(progress_bar)
	station_label = _make_label("工位状态：", 13, Color("cdb4db"))
	column.add_child(station_label)
	item_label = _make_label("当前物品数据：无", 13, Color("f4a261"))
	column.add_child(item_label)
	combat_label = _make_label("战斗状态：", 12, Color("ff8fa3"))
	column.add_child(combat_label)
	plate_label = _make_label("盘子循环：", 12, Color("90e0ef"))
	column.add_child(plate_label)
	stock_label = _make_label("Debug 库存：", 13, Color("b7e4c7"))
	column.add_child(stock_label)
	feedback_label = _make_label("操作反馈：", 14, Color("ffadad"))
	column.add_child(feedback_label)

	auto_attack_toggle = CheckButton.new()
	auto_attack_toggle.name = "EnemyDummyAAutoAttackToggle"
	auto_attack_toggle.position = Vector2(966.0, 675.0)
	auto_attack_toggle.size = Vector2(296.0, 36.0)
	auto_attack_toggle.text = "假人 A 自动攻击：关"
	auto_attack_toggle.tooltip_text = "周期攻击范围内的玩家与友方角色；用于测试护盾、防具和召唤物。"
	auto_attack_toggle.add_theme_font_size_override("font_size", 14)
	auto_attack_toggle.add_theme_color_override("font_color", Color("ffb4a2"))
	auto_attack_toggle.toggled.connect(_on_auto_attack_toggled)
	add_child(auto_attack_toggle)


func _get_controls_text() -> String:
	var movement := "%s%s%s%s" % [
		InputPrompt.action_text(&"move_up", "W"),
		InputPrompt.action_text(&"move_left", "A"),
		InputPrompt.action_text(&"move_down", "S"),
		InputPrompt.action_text(&"move_right", "D"),
	]
	var hotbar := "%s—%s" % [
		InputPrompt.action_text(&"select_hotbar_1", "1"),
		InputPrompt.action_text(&"select_hotbar_5", "5"),
	]
	return "%s 移动  %s 交互/切洗  %s 投料/拿取\n%s 锅具  滚轮/%s 切格  %s 开始营业\n%s 调味  %s 陷阱  %s 摆盘  %s 攻击\nESC/%s 暂停  F3 隐藏开发 UI  F9 试玩记录  T 重置" % [
		movement,
		InputPrompt.action_text(&"interact_primary", "E"),
		InputPrompt.action_text(&"interact_carry", "F"),
		InputPrompt.action_text(&"interact_cookware", "R"),
		hotbar,
		InputPrompt.action_text(&"start_service", "B"),
		InputPrompt.action_text(&"season_dish", "M"),
		InputPrompt.action_text(&"place_trap", "G"),
		InputPrompt.action_text(&"plate_dish", "Space"),
		InputPrompt.action_text(&"dish_attack", "Mouse Left"),
		InputPrompt.action_text(&"toggle_pause", "ESC"),
	]


func _on_auto_attack_toggled(enabled: bool) -> void:
	if enemy_dummy_a != null:
		enemy_dummy_a.set_auto_attack_enabled(enabled)
	_refresh_auto_attack_toggle()


func _on_dummy_auto_attack_changed(_enabled: bool) -> void:
	_refresh_auto_attack_toggle()


func _refresh_auto_attack_toggle() -> void:
	if auto_attack_toggle == null:
		return
	var available := enemy_dummy_a != null and enemy_dummy_a.auto_attack_available and enemy_dummy_a.lobby_active
	auto_attack_toggle.disabled = not available
	var enabled := available and enemy_dummy_a.auto_attack_enabled
	if auto_attack_toggle.button_pressed != enabled:
		auto_attack_toggle.set_pressed_no_signal(enabled)
	auto_attack_toggle.text = "假人 A 自动攻击：%s" % ("开" if enabled else "关")
	if enabled:
		auto_attack_toggle.text += "  |  命中 %d" % enemy_dummy_a.last_auto_attack_hit_count


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _get_stock_text() -> String:
	var cabinet := get_tree().get_first_node_in_group("ingredient_cabinet") as IngredientCabinet
	if cabinet == null:
		return "食材柜 Debug 库存：未找到统一食材柜"
	return "食材柜 Debug 库存（非正式数值）：\n%s" % cabinet.get_stock_summary()


func _get_combat_text() -> String:
	var lines: PackedStringArray = ["战斗状态：玩家 HP %.0f / %.0f" % [player.current_health, player.prototype_max_health]]
	var attack := player.get_node_or_null("DishAttackController") as DishAttackController
	if attack != null:
		lines.append(attack.get_aim_debug_text())
	for node in get_tree().get_nodes_in_group("debug_combat_target"):
		var target := node as DebugCombatTarget
		if target != null and target.lobby_active:
			var effect_text := target.status_effects.get_effects_text() if target.status_effects != null else "无"
			lines.append("%s：%.0f / %.0f · 状态 %s" % [target.debug_title, target.current_health, target.max_health, effect_text])
	return "\n".join(lines)


func _get_wave_text() -> String:
	var manager := get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	if manager == null:
		return "波次：未找到 PrototypeWaveManager"
	var freshness := get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
	return "波次状态（Prototype）：\n%s%s" % [
		manager.get_debug_summary(),
		"\n%s" % freshness.get_debug_summary() if freshness != null else "",
	]


func _get_plate_text() -> String:
	var sink := get_tree().get_first_node_in_group("interactable")
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is SinkStation:
			sink = node
			break
	var actual_sink := sink as SinkStation
	var pile := get_tree().get_first_node_in_group("clean_plate_pile") as CleanPlatePile
	var plating := get_tree().get_first_node_in_group("plating_controller") as PlatingController
	if actual_sink == null or pile == null:
		return "盘子循环：节点未就绪"
	return "盘子循环：脏盘池 %d / 洗净累计 %d\n清洗档位：%s\n摆盘 QTE：%s" % [
		actual_sink.dirty_plate_count,
		pile.washed_plate_count,
		actual_sink.locked_plate_speed_tier,
		"进行中（%s 确认）" % InputPrompt.action_text(&"plate_dish", "Space") if plating != null and plating.active else "未开始",
	]
