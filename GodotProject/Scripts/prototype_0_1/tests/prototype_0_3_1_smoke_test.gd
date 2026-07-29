extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_01_preparation_timing()
	await _test_02_spawn_pacing()
	await _test_03_enemy_attack_timing()
	await _test_04_expanded_map_and_kitchen_layout()
	await _test_05_camera_boundaries_and_raging_bull()
	await _test_06_navigation_and_real_edge_spawns()
	await _test_07_manual_processing_times()
	await _test_08_extended_automatic_cooking_times()
	await _test_09_interruption_preserves_completed_inputs()
	await _test_10_burn_and_charcoal_windows()
	await _test_11_parallel_cooking_feedback()
	await _test_12_full_regression_contract()
	if failures.is_empty():
		print("PROTOTYPE_0_3_1_SMOKE_TEST: PASS (12/12 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_3_1_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_01_preparation_timing() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	_expect(is_equal_approx(manager.config.preparation_time, 32.0), "01: preparation must use the centralized 32 second Prototype value")
	_expect(manager.config.preparation_time >= 18.0 * 1.5, "01: preparation must be clearly longer than Prototype 0.3")
	var stock_before := cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK)
	manager.start_service_early()
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and manager.preparation_left >= 30.0, "01: Start Service must use the centralized formal preparation time")
	_expect(not manager.early_started and is_zero_approx(manager.early_seconds), "01: initial free preparation must not create an early-service reward")
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == stock_before, "01: timing changes must not refill or consume finite stock")
	await _dispose_scene(scene)


func _test_02_spawn_pacing() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	_expect(is_equal_approx(manager.config.batch_interval, 4.2), "02: batch interval must increase from 3.0 to 4.2 seconds")
	_expect(is_equal_approx(manager.config.same_batch_spawn_interval, 0.55), "02: same-batch interval must increase from 0.3 to 0.55 seconds")
	_expect(manager.config.total_batches == 3 and manager.config.enemies_per_batch == 2, "02: pacing pass must not change the six-enemy total")
	manager.start_service_early()
	manager.force_advance_phase_for_test(manager.preparation_left + 0.01)
	manager.force_advance_phase_for_test(manager.config.global_warning_time + 0.01)
	manager.force_advance_phase_for_test(manager.config.local_warning_time + 0.01)
	manager.force_advance_phase_for_test(0.01)
	_expect(manager.spawned_total == 1, "02: first spawn remains staggered")
	manager.force_advance_phase_for_test(0.3)
	_expect(manager.spawned_total == 1, "02: old 0.3 second gap must no longer spawn the second enemy")
	manager.force_advance_phase_for_test(0.26)
	_expect(manager.spawned_total == 2, "02: second enemy must enter after the new interval")
	await _dispose_scene(scene)


func _test_03_enemy_attack_timing() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	_expect(is_equal_approx(manager.config.windup_time, 0.36), "03: windup must change from 0.62 to 0.36 seconds")
	_expect(is_equal_approx(manager.config.recovery_time, 0.28), "03: recovery must change from 0.48 to 0.28 seconds")
	_expect(manager.config.windup_time > 0.0 and manager.config.attack_active_time > 0.0, "03: the swing must remain observable rather than instant")
	var player := manager.player
	var enemy := manager.spawn_enemy_for_test(player.global_position - Vector2(50.0, 0.0))
	enemy.state = BasicTasteEnemy.State.CHASE
	enemy.attack_cooldown_left = 0.0
	enemy._physics_process(0.01)
	var locked_direction := enemy.locked_attack_direction
	_expect(enemy.state == BasicTasteEnemy.State.WINDUP, "03: close enemy must still use windup")
	player.global_position += Vector2(0.0, 120.0)
	enemy._physics_process(manager.config.windup_time + 0.01)
	_expect(enemy.locked_attack_direction == locked_direction, "03: timing adjustment must not add tracking during the locked swing")
	enemy._physics_process(manager.config.attack_active_time + 0.01)
	_expect(enemy.state == BasicTasteEnemy.State.RECOVERY, "03: attack must still enter recovery")
	enemy._physics_process(manager.config.recovery_time + 0.01)
	_expect(enemy.state == BasicTasteEnemy.State.CHASE, "03: shortened recovery must return to chase promptly")
	await _dispose_scene(scene)


func _test_04_expanded_map_and_kitchen_layout() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var controller = scene.get_node("MapController")
	var floor := scene.get_node("Floor") as Polygon2D
	var kitchen := scene.get_node("Kitchen") as Node2D
	var bounds: Rect2 = controller.get_map_bounds()
	_expect(bounds.size == Vector2(1820.0, 1328.0), "04: active map size must double in both dimensions")
	_expect(is_equal_approx(bounds.size.x * bounds.size.y, 4.0 * 910.0 * 664.0), "04: active area must be four times the old map")
	_expect(kitchen.position == manager.config.kitchen_offset and kitchen.position == Vector2(240.0, 220.0), "04: temporary kitchen cluster must be offset into the expanded map")
	_expect(floor.polygon[2] == bounds.end, "04: graybox floor must cover the expanded bounds")
	_expect(bounds.end.x - (kitchen.position.x + 920.0) > 600.0, "04: expanded map must leave a broad combat area beyond the kitchen")
	await _dispose_scene(scene)


func _test_05_camera_boundaries_and_raging_bull() -> void:
	var scene := await _spawn_main_scene()
	var controller = scene.get_node("MapController")
	var camera := scene.get_node("Kitchen/Player/Camera2D") as Camera2D
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var bounds: Rect2 = controller.get_map_bounds()
	_expect(camera.enabled, "05: expanded map needs an enabled player camera")
	_expect(camera.limit_left == roundi(bounds.position.x) and camera.limit_right == roundi(bounds.end.x), "05: horizontal camera limits must follow centralized map bounds")
	_expect(camera.limit_top == roundi(bounds.position.y) and camera.limit_bottom == roundi(bounds.end.y), "05: vertical camera limits must follow centralized map bounds")
	var right_wall := scene.get_node("Bounds/Right") as StaticBody2D
	_expect(is_equal_approx(right_wall.position.x, bounds.end.x + 8.0), "05: physical right boundary must move to the expanded edge")
	var raging := combat.spawn_raging_bull(Vector2(bounds.end.x - combat.config.raging_bull_radius - 2.0, bounds.get_center().y), Vector2.RIGHT)
	raging._physics_process(0.1)
	_expect(raging.reflection_count >= 1 and raging.direction.x < 0.0, "05: raging bull must reflect at the new map edge")
	await _dispose_scene(scene)


func _test_06_navigation_and_real_edge_spawns() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var bounds := manager.config.map_bounds
	var points := get_nodes_in_group("enemy_spawn_point")
	_expect(points.size() == 8, "06: all eight Prototype spawn candidates must remain available")
	for node in points:
		var point := node as WaveSpawnPoint
		var p := point.global_position
		var edge_distance := minf(minf(absf(p.x - bounds.position.x), absf(p.x - bounds.end.x)), minf(absf(p.y - bounds.position.y), absf(p.y - bounds.end.y)))
		_expect(edge_distance <= 32.0, "06: spawn points must be at the new real map edge")
		_expect(manager.navigation.is_position_walkable(p), "06: expanded-edge spawn must be navigable")
	var kitchen := scene.get_node("Kitchen") as Node2D
	var from_point := kitchen.position + Vector2(30.0, 320.0)
	var to_point := kitchen.position + Vector2(980.0, 320.0)
	var path := manager.navigation.find_path(from_point, to_point)
	_expect(path.size() > 2, "06: navigation must cross expanded walkable space and route around the kitchen row")
	for obstacle_node in get_nodes_in_group("kitchen_obstacle"):
		var obstacle := obstacle_node as KitchenObstacle
		for waypoint in path:
			_expect(not obstacle.get_navigation_rect(manager.navigation.agent_radius * 0.5).has_point(waypoint), "06: expanded navigation path must not enter facility collision")
	await _dispose_scene(scene)


func _test_07_manual_processing_times() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	var marinating := scene.get_node("Kitchen/MarinatingStation") as MarinatingStation
	_expect(is_equal_approx(board.prototype_first_cut_time, 1.4) and is_equal_approx(board.prototype_second_cut_time, 1.4), "07: both cuts must increase from 1.2 to 1.4 seconds")
	_expect(is_equal_approx(marinating.prototype_marinating_time, 1.8), "07: marinating must increase from 1.6 to 1.8 seconds")
	_expect(is_equal_approx(board.prototype_first_cut_time, manager.config.first_cut_time) and is_equal_approx(marinating.prototype_marinating_time, manager.config.marinating_time), "07: manual processing times must come from centralized Prototype config")
	await _dispose_scene(scene)


func _test_08_extended_automatic_cooking_times() -> void:
	var scene := await _spawn_main_scene()
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.set_process(false)
	_expect(is_equal_approx(station.config.automatic_stage_one_time, 3.6), "08: stage one must increase from 1.3 to 3.6 seconds")
	_expect(is_equal_approx(station.config.automatic_stage_two_time, 3.9), "08: stage two must increase from 1.4 to 3.9 seconds")
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(1.4)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.RAW_LOADED, "08: stage one must no longer finish near the old timing")
	station.advance_automatic_cooking(2.3)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "08: stage one must finish only after the new full interval")
	station.wok_item.add_chili()
	station.advance_automatic_cooking(1.5)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "08: stage two must no longer complete immediately")
	station.advance_automatic_cooking(2.5)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_TWO_DONE, "08: stage two must still produce the intended dish")
	await _dispose_scene(scene)


func _test_09_interruption_preserves_completed_inputs() -> void:
	var scene := await _spawn_main_scene()
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.set_process(false)
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.wok_item.add_salt()
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time * 0.5)
	station.set_burner_on(false)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.RAW_LOADED and is_zero_approx(station.get_progress_ratio()), "09: interrupting stage one must reset only current progress")
	_expect(station.wok_item.content_data.has_active_modifier(ItemData.ActiveModifier.SALTED), "09: salt must survive stage interruption")
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time * 0.5)
	station.set_burner_on(false)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE and is_zero_approx(station.get_progress_ratio()), "09: interrupting stage two must return to its completed discrete start")
	_expect(station.wok_item.content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS), "09: chili already added must not disappear on interruption")
	_expect(station.wok_item.content_data.has_active_modifier(ItemData.ActiveModifier.SALTED), "09: salt must remain independent from interruption")
	await _dispose_scene(scene)


func _test_10_burn_and_charcoal_windows() -> void:
	var scene := await _spawn_main_scene()
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.set_process(false)
	_expect(is_equal_approx(station.config.automatic_burn_time, 2.7), "10: finished-to-burnt window must increase from 1.5 to 2.7 seconds")
	_expect(is_equal_approx(station.config.automatic_charcoal_time, 2.0), "10: burnt-to-charcoal window must use the distinct 2.0 second value")
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time + 0.01)
	station.advance_automatic_cooking(1.6)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_TWO_DONE, "10: dish must not burn at the old 1.5 second window")
	station.advance_automatic_cooking(1.2)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.BURNT_TAGGED, "10: dish must gain burnt after the new tolerance window")
	station.advance_automatic_cooking(station.config.automatic_charcoal_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.CHARCOAL, "10: continued heat must still produce charcoal")
	await _dispose_scene(scene)


func _test_11_parallel_cooking_feedback() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.set_process(false)
	manager.set_process(false)
	manager.start_service_early()
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	manager.force_advance_phase_for_test(manager.preparation_left + 0.01)
	manager.force_advance_phase_for_test(manager.config.global_warning_time + 0.01)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "11: warning and combat phases must not pause automatic cooking")
	station._refresh_status()
	_expect(station.circular_indicator != null and station.circular_indicator.state_key == "waiting_chili", "11: stage milestone must use the local wok indicator")
	_expect(scene.get_node_or_null("CookingStatusUI") == null, "11: ordinary cooking must not use a screen-fixed remote status panel")
	await _dispose_scene(scene)


func _test_12_full_regression_contract() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	manager.start_service_early()
	await process_frame
	_expect(player.inventory.slots.size() == 5, "12: five-slot inventory must remain intact")
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and not cabinet.lobby_unlimited, "12: formal preparation must use the finite cabinet")
	_expect(cabinet.get_supported_item_types().size() == 8 and cabinet.get_stock(ItemData.ItemType.RICE_BAG) == 1 and cabinet.get_stock(ItemData.ItemType.WHOLE_GREENS) == 1, "12: unified finite cabinet must include the rice bag and current Prototype whole greens")
	_expect(scene.get_node_or_null("PlatingController") != null and scene.get_node_or_null("CombatRuntime") != null, "12: plating and combat-dish runtime must remain connected")
	_expect(scene.get_node_or_null("Kitchen/Sink") != null and scene.get_node_or_null("Kitchen/CleanPlatePile") != null, "12: plate and stuck-wok cleaning loop must remain connected")
	_expect(InputMap.has_action("start_service") and manager.config.global_warning_time == 2.0 and manager.config.local_warning_time == 0.8, "12: service input and existing warning rules must remain unchanged")
	_expect(manager.config.raw_beef_stock == 1 and manager.config.clean_plate_stock == 6 and cabinet.storage.get_items().size() > 0, "12: 0.6A must use constrained actual cabinet stock while preserving plate startup")
	await _dispose_scene(scene)


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "Unable to load Prototype 0.3.1 main scene")
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
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
