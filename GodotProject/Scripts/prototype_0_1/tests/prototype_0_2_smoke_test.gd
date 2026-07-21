extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_scene_and_inputs()
	await _test_normal_quality_and_normal_bulls()
	await _test_perfect_finisher_and_raging_bull()
	await _test_flawed_and_bad_quality()
	await _test_plate_stacking_and_plating_consumption()
	await _test_dirty_plate_washing_and_wok_priority()
	await _test_item_state_and_existing_system_regression()
	if failures.is_empty():
		print("PROTOTYPE_0_2_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_2_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_scene_and_inputs() -> void:
	for action in ["plate_dish", "dish_attack"]:
		_expect(InputMap.has_action(action), "Prototype 0.2 应注册输入动作：%s" % action)
		_expect(not InputMap.action_get_events(action).is_empty(), "Prototype 0.2 输入动作应绑定临时按键：%s" % action)
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	_expect(scene.get_node_or_null("Kitchen/CleanPlatePile") is CleanPlatePile, "场景应包含干净盘子堆")
	_expect(scene.get_node_or_null("PlatingController") is PlatingController, "场景应包含独立摆盘控制器")
	_expect(scene.get_node_or_null("PlatingQTEUI") is PlatingQTEUI, "场景应包含摆盘 QTE UI")
	_expect(scene.get_node_or_null("CombatRuntime") is CombatManager, "场景应包含集中战斗运行节点")
	_expect(get_nodes_in_group("debug_combat_target").size() >= 4, "场景应包含敌方与友方测试目标")
	await _dispose_scene(scene)


func _test_normal_quality_and_normal_bulls() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	var qte_ui := scene.get_node("PlatingQTEUI") as PlatingQTEUI
	var attack := player.get_node("DishAttackController") as DishAttackController
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var enemy_a := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var enemy_b := scene.get_node("Kitchen/EnemyDummyB") as DebugCombatTarget
	var friendly := scene.get_node("Kitchen/FriendlyDummy") as DebugCombatTarget
	var dish := _give_unplated_dish(player, [])
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	_expect(plating.request_start(), "正常品质测试应能主动开始摆盘")
	_expect(player.modal_ui_open and not paused, "QTE 应锁定玩家但不暂停世界")
	qte_ui.set_pointer_ratio_for_test(0.1)
	_expect(plating.confirm_qte(), "QTE 普通区域应能完成摆盘")
	_expect(dish.data.item_type == ItemData.ItemType.PLATED_STIR_FRY_BEEF, "摆盘应原地生成已摆盘小炒黄牛肉")
	_expect(dish.data.quality == ItemData.Quality.NORMAL, "无标签且未命中完美区应为正常品质")
	_expect(dish.data.actual_damage == combat.config.standard_damage, "正常品质应使用标准伤害")
	_expect(dish.data.max_durability == combat.config.standard_durability, "正常品质应使用标准耐久")
	var original_instance := dish
	var first_bull_count := combat.normal_bulls_spawned
	_expect(attack.fire_once(Vector2.LEFT), "手持成品料理应能释放普通公牛")
	var bull := combat.get_children().back() as NormalBull
	_advance_normal_bull(bull, 70, 0.02)
	_expect(combat.normal_bulls_spawned == first_bull_count + 1, "一次攻击应只生成一头普通公牛")
	_expect(enemy_a.current_health == enemy_a.max_health - combat.config.standard_damage, "普通公牛应伤害第一个敌方目标一次")
	_expect(enemy_b.current_health == enemy_b.max_health - combat.config.standard_damage, "普通公牛应穿透并伤害第二个敌方目标")
	_expect(enemy_a.knockback_velocity.length() > 0.0, "普通公牛命中后应产生轻微击退反馈")
	_expect(friendly.current_health == friendly.max_health, "普通公牛不应伤害友方目标")
	var durability_after_first := dish.data.current_durability
	player.inventory.select(1)
	player.inventory.select(0)
	_expect(dish == original_instance and dish.data.current_durability == durability_after_first, "切格不得重置料理实例或耐久")
	while dish.data.item_type == ItemData.ItemType.PLATED_STIR_FRY_BEEF:
		attack.fire_once(Vector2.LEFT)
	_expect(dish == original_instance, "耐久耗尽应转换同一物品实例")
	_expect(dish.data.item_type == ItemData.ItemType.DIRTY_PLATE and dish.data.stack_count == 1, "正常料理耗尽后原格应变为一个脏盘子")
	await _dispose_scene(scene)


func _test_perfect_finisher_and_raging_bull() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	var qte_ui := scene.get_node("PlatingQTEUI") as PlatingQTEUI
	var attack := player.get_node("DishAttackController") as DishAttackController
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var enemy := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var friendly := scene.get_node("Kitchen/FriendlyDummy") as DebugCombatTarget
	var dish := _give_unplated_dish(player, [])
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	plating.request_start()
	qte_ui.set_pointer_ratio_for_test((combat.config.qte_perfect_min + combat.config.qte_perfect_max) * 0.5)
	plating.confirm_qte()
	_expect(dish.data.quality == ItemData.Quality.PERFECT and dish.data.has_perfect_finisher, "无标签命中完美区应获得完美终结")
	_expect(dish.data.actual_damage == combat.config.standard_damage and dish.data.max_durability == combat.config.standard_durability, "完美与正常应共享标准伤害和耐久")
	var perfect_max_durability := dish.data.max_durability
	var normal_before := combat.normal_bulls_spawned
	for shot in perfect_max_durability - 1:
		attack.fire_once(Vector2.RIGHT)
	_expect(combat.normal_bulls_spawned == normal_before + perfect_max_durability - 1, "完美料理最后一次前应释放普通公牛")
	var raging_before := combat.raging_bulls_spawned
	attack.fire_once(Vector2.RIGHT)
	_expect(combat.raging_bulls_spawned == raging_before + 1, "最后一份完美耐久应且只应释放一头大型公牛")
	_expect(combat.normal_bulls_spawned == normal_before + perfect_max_durability - 1, "完美最后一击不应额外释放普通公牛")
	_expect(dish.data.item_type == ItemData.ItemType.DIRTY_PLATE, "完美终结触发后料理格应立即变为脏盘")
	var raging := combat.get_children().back() as RagingBull
	var max_x := combat.config.combat_bounds.end.x - combat.config.raging_bull_radius
	raging.global_position = Vector2(max_x - 2.0, 400.0)
	raging.direction = Vector2.RIGHT
	raging._physics_process(0.1)
	_expect(raging.reflection_count >= 1 and raging.direction.x < 0.0, "大型公牛撞右墙应按法线反弹")
	var warned_direction := Vector2.UP
	raging.force_random_turn_warning_for_test(warned_direction)
	_expect(raging.warning_left > 0.0 and raging.random_turn_warning_count >= 1, "随机转向前应出现短暂预警")
	raging._physics_process(combat.config.random_turn_warning_time + 0.01)
	_expect(raging.direction.dot(warned_direction) > 0.9, "预警结束后大型公牛应改变方向")

	var player_health := player.current_health
	raging.global_position = player.global_position
	raging._hit_targets_with_cooldown()
	_expect(player.current_health < player_health, "大型公牛应能伤害释放者本人")
	var enemy_health := enemy.current_health
	raging.global_position = enemy.global_position
	raging._hit_targets_with_cooldown()
	_expect(enemy.current_health < enemy_health, "大型公牛应能伤害敌人")
	var same_hit_health := enemy.current_health
	raging._hit_targets_with_cooldown()
	_expect(enemy.current_health == same_hit_health, "大型公牛同一目标命中冷却应阻止连续物理帧重复伤害")
	var friendly_health := friendly.current_health
	raging.global_position = friendly.global_position
	raging._hit_targets_with_cooldown()
	_expect(friendly.current_health < friendly_health, "大型公牛应能伤害友方测试目标")
	_expect(not scene.get_node("Kitchen/WokStation").is_in_group("damageable"), "厨房工位不应进入伤害接收组")
	raging.lifetime_left = 0.01
	raging._physics_process(0.02)
	_expect(raging.is_queued_for_deletion(), "大型公牛持续时间结束后应自动消失")
	await _dispose_scene(scene)


func _test_flawed_and_bad_quality() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	var qte_ui := scene.get_node("PlatingQTEUI") as PlatingQTEUI
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var flawed := _give_unplated_dish(player, [ItemData.FailureTag.UNMARINATED])
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	plating.request_start()
	qte_ui.set_pointer_ratio_for_test((combat.config.qte_perfect_min + combat.config.qte_perfect_max) * 0.5)
	plating.confirm_qte()
	_expect(flawed.data.quality == ItemData.Quality.FLAWED, "一个失败标签即使命中完美区也应保持瑕疵")
	_expect(flawed.data.actual_damage == combat.config.standard_damage, "瑕疵伤害应保持标准")
	_expect(flawed.data.max_durability < combat.config.standard_durability and not flawed.data.has_perfect_finisher, "瑕疵应降低耐久且无大型公牛终结")
	player.drop_held_item()
	var bad := _give_unplated_dish(player, [ItemData.FailureTag.UNMARINATED, ItemData.FailureTag.CHILI_TOO_EARLY])
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	plating.request_start()
	qte_ui.set_pointer_ratio_for_test((combat.config.qte_perfect_min + combat.config.qte_perfect_max) * 0.5)
	plating.confirm_qte()
	_expect(bad.data.quality == ItemData.Quality.BAD, "两个失败标签应得到糟糕品质")
	_expect(bad.data.actual_damage < combat.config.standard_damage, "糟糕品质应降低伤害")
	_expect(bad.data.max_durability < combat.config.standard_durability and not bad.data.has_perfect_finisher, "糟糕品质应降低耐久且无终结")
	await _dispose_scene(scene)


func _test_plate_stacking_and_plating_consumption() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var pile := scene.get_node("Kitchen/CleanPlatePile") as CleanPlatePile
	var plating := scene.get_node("PlatingController") as PlatingController
	for count in 4:
		pile.carry_interact(player)
	var first_stack := player.inventory.get_item(0)
	_expect(first_stack.data.item_type == ItemData.ItemType.CLEAN_PLATE and first_stack.data.stack_count == 4, "四个干净盘子应堆叠在同一格")
	pile.carry_interact(player)
	_expect(player.inventory.get_item(1).data.item_type == ItemData.ItemType.CLEAN_PLATE and player.inventory.get_item(1).data.stack_count == 1, "第五个盘子应进入另一个空格")
	var dish := _give_unplated_dish(player, [])
	_expect(dish == player.inventory.get_item(2), "待摆盘料理应占用独立格子")
	plating.request_start()
	plating.complete_for_test(false)
	_expect(first_stack.data.stack_count == 3, "摆盘只应从盘子堆叠消耗一个单位")
	_expect(player.inventory.get_item(1).data.stack_count == 1, "其他盘子堆叠不应受摆盘影响")
	_expect(dish.data.item_type == ItemData.ItemType.PLATED_STIR_FRY_BEEF, "盘子与料理应合并到原料理格")
	await _dispose_scene(scene)


func _test_dirty_plate_washing_and_wok_priority() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	var pile := scene.get_node("Kitchen/CleanPlatePile") as CleanPlatePile
	var dirty_data := ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
	dirty_data.stack_count = 4
	player.receive_item_data(dirty_data)
	sink.carry_interact(player)
	_expect(sink.dirty_plate_count == 4 and player.held_item == null, "脏盘堆叠投入水池后应移出物品栏并进入独立脏盘池")
	sink.dirty_plate_count = 9
	_expect(sink.begin_primary_interaction(player), "有脏盘时应能开始连续清洗")
	var locked_duration := sink.locked_plate_wash_duration
	_expect(sink.locked_plate_speed_tier.contains("9+"), "九个脏盘应锁定最高速度档")
	sink.update_primary_interaction(player, locked_duration + 0.01)
	_expect(sink.dirty_plate_count == 8 and pile.washed_plate_count == 1, "洗完一个盘子应减少脏盘并增加干净盘堆")
	_expect(is_equal_approx(sink.hold_progress.duration, locked_duration), "同一连续清洗会话中速度档位必须保持锁定")
	sink.update_primary_interaction(player, locked_duration * 0.4)
	sink.cancel_primary_interaction(player)
	_expect(sink.get_progress_ratio() == 0.0 and sink.dirty_plate_count == 8 and pile.washed_plate_count == 1, "松开后当前盘进度归零，已完成盘子不得倒退")
	sink.begin_primary_interaction(player)
	var second_session_duration := sink.locked_plate_wash_duration
	_expect(sink.locked_plate_speed_tier.contains("5-8"), "新会话应按剩余八个脏盘重新计算档位")
	while sink.dirty_plate_count > 0:
		sink.update_primary_interaction(player, second_session_duration + 0.01)
	_expect(pile.washed_plate_count == 9, "持续按住应自动连续洗完所有脏盘")

	var wok := WokItem.new()
	wok.setup_wok(&"prototype_wok_01")
	scene.add_child(wok)
	wok.trigger_no_oil_accident()
	player.pickup_item(wok)
	sink.dirty_plate_count = 5
	sink.begin_primary_interaction(player)
	_expect(sink.active_wash_mode == SinkStation.WashMode.WOK, "手持粘锅时水池必须优先清洗炒锅")
	_expect(is_equal_approx(sink.hold_progress.duration, sink.prototype_stuck_wok_wash_time), "脏盘速度加成不得作用于炒锅")
	sink.update_primary_interaction(player, sink.prototype_stuck_wok_wash_time + 0.01)
	_expect(not wok.is_stuck() and sink.dirty_plate_count == 5, "洗净粘锅不能消耗脏盘池")
	await _dispose_scene(scene)


func _test_item_state_and_existing_system_regression() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var pile := scene.get_node("Kitchen/CleanPlatePile") as CleanPlatePile
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var plated_data := ItemCatalog.create(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	plated_data.add_failure_tag(ItemData.FailureTag.UNMARINATED)
	combat.config.apply_combat_dish_stats(plated_data)
	player.receive_item_data(plated_data)
	var dish := player.held_item
	dish.data.current_durability -= 1
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINADE))
	player.inventory.select(1)
	player.inventory.select(0)
	_expect(dish.data.quality == ItemData.Quality.FLAWED and dish.data.has_failure_tag(ItemData.FailureTag.UNMARINATED), "切格不得删除料理品质或失败标签")
	_expect(dish.data.current_durability == dish.data.max_durability - 1, "切格不得重置料理耐久")
	var full_plate := ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE)
	full_plate.stack_count = 4
	player.receive_item_data(full_plate)
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	_expect(player.inventory.is_full(), "满栏盘子测试前应占满五格")
	var claimed_before := pile.total_claimed
	pile.carry_interact(player)
	_expect(pile.total_claimed == claimed_before and player.get_visible_feedback() == "物品栏已满", "满栏且盘子堆已满时不能吞掉或生成额外盘子")
	var beef_stock := cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK)
	player.drop_held_item()
	_expect(cabinet.request_take(ItemData.ItemType.RAW_BEEF_CHUNK, player), "Prototype 0.2 后统一食材柜仍应正常取料")
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == beef_stock - 1, "统一食材柜库存仍应正确扣减")
	await _dispose_scene(scene)


func _give_unplated_dish(player: PrototypePlayer, tags: Array[int]) -> CarryableItem:
	var data := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	for tag in tags:
		data.add_failure_tag(tag)
	player.receive_item_data(data)
	return player.inventory.get_item(player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF))


func _advance_normal_bull(bull: NormalBull, steps: int, delta: float) -> void:
	for step in steps:
		if bull == null or bull.is_queued_for_deletion():
			break
		bull._physics_process(delta)


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "无法加载 Prototype 0.2 主场景")
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.start_game()
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
