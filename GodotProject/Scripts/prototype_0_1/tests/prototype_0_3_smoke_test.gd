extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_01_finite_preparation_stock()
	await _test_02_countdown_starts_warning()
	await _test_03_early_service()
	await _test_04_edge_spawn_validation()
	await _test_05_staggered_batches()
	await _test_06_chase_and_locked_swing()
	await _test_07_player_damage_and_failure()
	await _test_08_bull_hit_stun_and_poison()
	await _test_09_enemy_separation()
	await _test_10_kitchen_collision_and_pathing()
	await _test_11_reflavor_exit_once()
	await _test_12_cooking_continues_during_combat()
	await _test_13_wave_completion_preserves_state()
	await _test_14_regression_contracts()
	if failures.is_empty():
		print("PROTOTYPE_0_3_SMOKE_TEST: PASS (14/14 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_3_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_01_finite_preparation_stock() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	_expect(manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION, "01: scene must begin in unrestricted free preparation")
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == manager.config.raw_beef_stock, "01: cabinet must use centralized finite beef stock")
	var before := cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK)
	_expect(cabinet.request_take(ItemData.ItemType.RAW_BEEF_CHUNK, player), "01: preparation must allow normal finite withdrawal")
	manager.start_service_early()
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == before - 1, "01: starting combat must not refill or refund stock")
	await _dispose_scene(scene)


func _test_02_countdown_starts_warning() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	_expect(manager.start_service_early(), "02: free preparation must wait for Start Service")
	_expect(manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING, "02: Start Service must enter global warning")
	manager.force_advance_phase_for_test(manager.config.global_warning_time + 0.01)
	_expect(manager.phase == PrototypeWaveManager.Phase.LOCAL_WARNING, "02: global warning must lead to local warning before spawning")
	await _dispose_scene(scene)


func _test_03_early_service() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	_expect(manager.start_service_early(), "03: B action handler must begin service during free preparation")
	_expect(not manager.early_started and is_zero_approx(manager.early_seconds), "03: initial free preparation must not record an early-service reward")
	_expect(manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING, "03: early service must enter the same warning, not spawn instantly")
	await _dispose_scene(scene)


func _test_04_edge_spawn_validation() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	var legal := manager.get_legal_spawn_points()
	_expect(legal.size() >= 4, "04: several legal edge spawn points must be available")
	var edges: Dictionary = {}
	for point in legal:
		edges[point.edge_label] = true
		_expect(manager.navigation.is_position_walkable(point.global_position), "04: spawn point must be on walkable navigation")
		_expect(point.global_position.distance_to(manager.player.global_position) >= manager.config.minimum_spawn_distance, "04: spawn point must respect player safety distance")
	_expect(edges.size() >= 3, "04: candidates must cover multiple map edges")
	await _dispose_scene(scene)


func _test_05_staggered_batches() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	manager.start_service_early()
	manager.force_advance_phase_for_test(manager.config.global_warning_time + 0.01)
	manager.force_advance_phase_for_test(manager.config.local_warning_time + 0.01)
	_expect(manager.phase == PrototypeWaveManager.Phase.SPAWNING and manager.spawned_total == 0, "05: local warning must precede first spawn")
	manager.force_advance_phase_for_test(0.01)
	_expect(manager.spawned_total == 1, "05: first enemy must spawn alone")
	manager.force_advance_phase_for_test(manager.config.same_batch_spawn_interval + 0.01)
	_expect(manager.spawned_total == manager.config.enemies_per_batch, "05: first batch must complete over a short interval")
	_expect(manager.phase == PrototypeWaveManager.Phase.WAVE_ACTIVE, "05: manager must wait between batches while old enemies remain")
	manager.force_advance_phase_for_test(manager.config.batch_interval + 0.01)
	_expect(manager.phase == PrototypeWaveManager.Phase.LOCAL_WARNING and manager.active_enemy_count > 0, "05: next batch warning may begin before previous enemies are reflavored")
	await _dispose_scene(scene)


func _test_06_chase_and_locked_swing() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	var player := manager.player
	player.global_position = Vector2(470, 525)
	var enemy := manager.spawn_enemy_for_test(Vector2(80, 580))
	var before_distance := enemy.global_position.distance_to(player.global_position)
	for i in 25:
		enemy._physics_process(0.05)
	_expect(enemy.global_position.distance_to(player.global_position) < before_distance, "06: enemy must chase along a path")
	enemy.global_position = player.global_position - Vector2(50, 0)
	enemy.state = BasicTasteEnemy.State.CHASE
	enemy.attack_cooldown_left = 0.0
	enemy._physics_process(0.01)
	_expect(enemy.state == BasicTasteEnemy.State.WINDUP, "06: enemy must stop and enter a clear windup in range")
	var locked := enemy.locked_attack_direction
	var hp_before := player.current_health
	player.global_position += Vector2(0, 130)
	enemy._physics_process(manager.config.windup_time + 0.01)
	_expect(enemy.locked_attack_direction == locked and player.current_health == hp_before, "06: swing direction must stay locked so movement can dodge it")
	enemy._physics_process(manager.config.attack_active_time + 0.01)
	_expect(enemy.state == BasicTasteEnemy.State.RECOVERY, "06: attack must have a recovery state before chasing again")
	await _dispose_scene(scene)


func _test_07_player_damage_and_failure() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	var player := manager.player
	var before := player.current_health
	_expect(player.receive_combat_hit(12.0, CombatRules.Faction.ENEMY, Vector2.RIGHT, 30.0, false), "07: enemy swing must damage player")
	_expect(not player.receive_combat_hit(12.0, CombatRules.Faction.ENEMY, Vector2.RIGHT, 30.0, false), "07: short Prototype protection must block duplicate same-swing damage")
	_expect(player.current_health == before - 12.0 and player.knockback_velocity.x > 0.0, "07: player must lose HP and receive light knockback")
	player.hit_protection_left = 0.0
	player.current_health = 1.0
	player.receive_combat_hit(12.0, CombatRules.Faction.ENEMY, Vector2.RIGHT, 30.0, false)
	_expect(player.is_defeated and manager.phase == PrototypeWaveManager.Phase.FAILED, "07: zero HP must fail the current wave instead of silently resetting")
	await _dispose_scene(scene)


func _test_08_bull_hit_stun_and_poison() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var enemy_a := manager.spawn_enemy_for_test(Vector2(510, 520))
	var enemy_b := manager.spawn_enemy_for_test(Vector2(510, 535))
	var bull := combat.spawn_normal_bull(Vector2(460, 527), Vector2.RIGHT, 20.0)
	bull._physics_process(0.01)
	_expect(enemy_a.current_health < manager.config.enemy_max_health and enemy_b.current_health < manager.config.enemy_max_health, "08: one normal bull must penetrate and damage multiple enemies")
	_expect(enemy_a.state == BasicTasteEnemy.State.HIT_STUN and enemy_a.knockback_velocity.x > 0.0, "08: normal bull must apply light knockback and short hit stun")
	var poison := StatusEffectData.new()
	poison.effect_type = StatusEffectData.EffectType.POISON
	poison.damage_per_tick = 3.0
	poison.tick_interval = 0.1
	poison.duration = 0.2
	poison.source_faction = CombatRules.Faction.PLAYER
	_expect(enemy_a.apply_status_effect(poison), "08: basic enemy must accept reusable mustard poison data")
	var after_direct := enemy_a.current_health
	enemy_a.status_effects.advance_effects(0.21)
	_expect(enemy_a.current_health < after_direct, "08: poison ticks must reduce enemy health")
	await _dispose_scene(scene)


func _test_09_enemy_separation() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	manager.player.global_position = Vector2(800, 600)
	var enemy_a := manager.spawn_enemy_for_test(Vector2(120, 560))
	var enemy_b := manager.spawn_enemy_for_test(Vector2(124, 560))
	var initial := enemy_a.global_position.distance_to(enemy_b.global_position)
	for i in 20:
		enemy_a._physics_process(0.04)
		enemy_b._physics_process(0.04)
	_expect(enemy_a.global_position.distance_to(enemy_b.global_position) > initial, "09: close enemies must use light separation instead of complete overlap")
	await _dispose_scene(scene)


func _test_10_kitchen_collision_and_pathing() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	var obstacles := get_nodes_in_group("kitchen_obstacle")
	_expect(obstacles.size() >= 8, "10: expanded two-stove kitchen and cookware rack must retain close-fitting collisions")
	var path := manager.navigation.find_path(Vector2(80, 320), Vector2(880, 320))
	_expect(path.size() > 2, "10: navigation must route around the row of kitchen facilities")
	for point in path:
		for obstacle_node in obstacles:
			var obstacle := obstacle_node as KitchenObstacle
			_expect(not obstacle.get_navigation_rect(manager.navigation.agent_radius * 0.5).has_point(point), "10: route waypoints must not cross facility collision")
	await _dispose_scene(scene)


func _test_11_reflavor_exit_once() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	var enemy := manager.spawn_enemy_for_test(Vector2(300, 560))
	var before := manager.reflavored_total
	enemy.receive_combat_hit(999.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 10.0, false)
	_expect(enemy.state == BasicTasteEnemy.State.REFLAVORING and enemy.collision_layer == 0, "11: zero HP must stop danger and enter Prototype reflavor exit")
	enemy._physics_process(manager.config.reflavor_exit_time + 0.01)
	_expect(manager.reflavored_total == before + 1 and manager.active_enemy_count == 0, "11: reflavor completion must notify the wave exactly once")
	await _dispose_scene(scene)


func _test_12_cooking_continues_during_combat() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	manager.start_service_early()
	manager.force_advance_phase_for_test(manager.config.global_warning_time + 0.01)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "12: warnings and combat phase must not pause automatic cooking")
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time + 0.01)
	station.advance_automatic_cooking(station.config.automatic_burn_time + 0.01)
	_expect(station.wok_item.content_data.has_failure_tag(ItemData.FailureTag.BURNT), "12: unattended combat cooking must continue into burnt state")
	await _dispose_scene(scene)


func _test_13_wave_completion_preserves_state() -> void:
	var scene := await _spawn_main_scene()
	var manager := _manager(scene)
	manager.set_process(false)
	manager.config.total_batches = 1
	manager.config.enemies_per_batch = 1
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var beef_before := cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK)
	station.set_burner_on(true)
	manager.start_service_early()
	manager.force_advance_phase_for_test(manager.config.global_warning_time + 0.01)
	manager.force_advance_phase_for_test(manager.config.local_warning_time + 0.01)
	manager.force_advance_phase_for_test(0.01)
	var enemy := manager.live_enemies[0]
	enemy.receive_combat_hit(999.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 0.0, false)
	enemy._physics_process(manager.config.reflavor_exit_time + 0.01)
	_expect(manager.phase == PrototypeWaveManager.Phase.INTERMISSION, "13: first wave enters intermission only after all planned spawns finish and leave")
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == beef_before and station.burner_on, "13: completion must preserve stock and burner state")
	await _dispose_scene(scene)


func _test_14_regression_contracts() -> void:
	_expect(InputMap.has_action("start_service") and not InputMap.action_get_events("start_service").is_empty(), "14: Prototype 0.3 must register an early-service input")
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var wok := scene.get_node("Kitchen/WokStation") as WokStation
	_expect(player.inventory.slots.size() == 5, "14: five-slot quick inventory must remain intact")
	_expect(cabinet.get_supported_item_types().size() == 6, "14: unified cabinet with salt and mustard must remain intact")
	wok.wok_item.add_oil()
	wok.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.set_burner_on(true)
	wok.advance_automatic_cooking(wok.config.automatic_stage_one_time + 0.01)
	_expect(wok.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "14: existing automatic cooking route must still work")
	_expect(scene.get_node_or_null("PlatingController") != null and scene.get_node_or_null("CombatRuntime") != null, "14: plating and combat dish systems must remain connected")
	await _dispose_scene(scene)


func _manager(scene: Node) -> PrototypeWaveManager:
	return scene.get_node("WaveManager") as PrototypeWaveManager


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "Unable to load Prototype 0.3 main scene")
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
