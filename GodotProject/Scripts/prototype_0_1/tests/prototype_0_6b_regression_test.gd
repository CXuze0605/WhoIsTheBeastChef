extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_shield_pipeline_and_hud()
	await _test_fast_and_ranged_enemy_behaviors()
	await _test_ranged_leftover_volley()
	await _test_wave_mix_and_loot_configuration()
	await _test_rice_bag_instance_and_atomic_extraction()
	await _test_water_and_rice_cooking_nodes()
	await _test_white_rice_real_projectile_path()
	await _test_porridge_and_emergency_consumption()
	await _test_crispy_rice_armor_and_trap()
	await _test_debug_dummy_auto_attack_switch()
	if failures.is_empty():
		print("PROTOTYPE_0_6B_REGRESSION_TEST: PASS (10/10 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_6B_REGRESSION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_shield_pipeline_and_hud() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	player.reset_for_new_game(100.0, 0.0, 30.0, 4.0, 10.0)
	_expect(
		player.receive_combat_hit(20.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
		and is_equal_approx(player.current_shield, 10.0)
		and is_equal_approx(player.current_health, 100.0),
		"Shield: a real combat hit must consume shield before health"
	)
	player.hit_protection_left = 0.0
	_expect(
		player.receive_combat_hit(15.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
		and is_zero_approx(player.current_shield)
		and is_equal_approx(player.current_health, 95.0),
		"Shield: damage beyond the remaining shield must overflow to health"
	)
	player._update_shield_regeneration(3.9)
	_expect(is_zero_approx(player.current_shield), "Shield: regeneration must not begin before four seconds")
	player._update_shield_regeneration(0.2)
	_expect(player.current_shield > 0.0, "Shield: regeneration must begin based on time since the last hit")
	player.hit_protection_left = 0.0
	player.receive_combat_hit(1.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
	_expect(is_zero_approx(player.time_since_last_damage), "Shield: another accepted hit must reset the regeneration delay")
	var health_before_wave := player.current_health
	player.restore_shield_for_wave()
	_expect(
		is_equal_approx(player.current_shield, 30.0) and is_equal_approx(player.current_health, health_before_wave),
		"Shield: a wave refresh must refill only shield, never health"
	)
	hud._process(0.0)
	_expect(
		is_equal_approx(hud.shield_bar.value, player.current_shield)
		and hud.shield_label.text.contains("30"),
		"Shield: the real HUD must mirror the player's shield value and numeric label"
	)
	player.current_shield = 5.0
	player.time_since_last_damage = 1.25
	paused = true
	await process_frame
	await process_frame
	_expect(
		is_equal_approx(player.current_shield, 5.0) and is_equal_approx(player.time_since_last_damage, 1.25),
		"Shield: true SceneTree pause must freeze delay and regeneration"
	)
	paused = false
	await _dispose_scene(scene)


func _test_fast_and_ranged_enemy_behaviors() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var fast := manager.spawn_fast_enemy_for_test(player.global_position + Vector2(170.0, 0.0))
	fast.spawn_grace_left = 0.0
	fast.dash_cooldown_left = 0.0
	fast._update_fast_chase(0.01)
	_expect(
		fast.state == FastTasteEnemy.STATE_CHARGING
		and fast.charge_line.visible
		and fast.charge_audio != null
		and fast.charge_audio.playing,
		"Fast enemy: entering mid range must start visible and audible technical charge telegraphs"
	)
	var trap := ShabuTrap.new()
	trap.setup(ItemCatalog.create(ItemData.ItemType.SHABU_BEEF), scene.get_node("CombatRuntime").config)
	scene.add_child(trap)
	trap.global_position = fast.global_position + Vector2(40.0, 0.0)
	fast._update_charge(0.1)
	_expect(fast.dash_target == trap, "Fast enemy: an available shabu lure must take priority before direction lock")
	fast._update_charge(manager.config.fast_charge_windup_time * 0.5)
	var locked_direction := fast.dash_direction
	trap.global_position += Vector2(0.0, 140.0)
	fast._update_charge(0.05)
	_expect(
		fast.direction_locked and fast.dash_direction.is_equal_approx(locked_direction),
		"Fast enemy: a locked dash direction must not keep tracking a moving target"
	)
	_expect(
		fast.lock_cue_played and fast.charge_audio.pitch_scale > 1.0,
		"Fast enemy: direction lock must emit a distinct final-moment cue"
	)
	fast.dash_target = player
	fast.global_position = player.global_position + Vector2(10.0, 0.0)
	fast.dash_direction = Vector2.LEFT
	fast.dash_hit_ids.clear()
	player.hit_protection_left = 0.0
	var first_dash_hit := fast._try_dash_hit_target()
	player.hit_protection_left = 0.0
	var duplicate_dash_hit := fast._try_dash_hit_target()
	_expect(first_dash_hit and not duplicate_dash_hit, "Fast enemy: one dash must damage the same target at most once")
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	var wall_shape := CollisionShape2D.new()
	var wall_rectangle := RectangleShape2D.new()
	wall_rectangle.size = Vector2(24.0, 120.0)
	wall_shape.shape = wall_rectangle
	wall.add_child(wall_shape)
	scene.add_child(wall)
	wall.global_position = Vector2(900.0, 800.0)
	fast.global_position = wall.global_position - Vector2(24.0, 0.0)
	fast.state = FastTasteEnemy.STATE_DASHING
	fast.dash_target = null
	fast.dash_direction = Vector2.RIGHT
	fast._update_dash(0.08)
	_expect(fast.state == FastTasteEnemy.STATE_DASH_RECOVERY, "Fast enemy: colliding with a facility/wall must stop the dash and enter recovery")

	trap.free()
	for enemy_node in get_nodes_in_group("basic_taste_enemy"):
		(enemy_node as BasicTasteEnemy).set_physics_process(false)
	_expect(
		manager.config.fast_concurrent_limit == 4 and manager.config.ranged_concurrent_limit == 2,
		"Enemy caps: speed and ranged concurrent limits must remain centralized"
	)
	await _dispose_scene(scene)


func _test_ranged_leftover_volley() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var config := manager.config
	var ranged := manager.spawn_ranged_enemy_for_test(Vector2(1320.0, 1040.0))
	ranged.set_physics_process(false)
	player.global_position = Vector2(1620.0, 1040.0)
	_expect(
		ranged != null
		and ranged.is_in_group("ranged_taste_enemy")
		and is_equal_approx(config.ranged_eating_time, 0.75)
		and is_equal_approx(config.ranged_retch_windup_time, 0.65)
		and config.ranged_volley_count == 3
		and is_equal_approx(config.ranged_projectile_damage, 8.0)
		and is_equal_approx(config.ranged_projectile_splash_damage, 4.0),
		"Ranged volley: the existing ranged test spawn must use centralized three-shot leftover-food values"
	)

	ranged.combat_target = player
	ranged._begin_ranged_attack(player.global_position)
	_expect(ranged.state == RangedTasteEnemy.STATE_EATING, "Ranged volley: an attack must begin with the readable eating state")
	ranged._update_eating(config.ranged_eating_time)
	ranged._update_retch_windup(config.ranged_retch_windup_time * 0.30)
	_expect(
		ranged.state == RangedTasteEnemy.STATE_RETCH_WINDUP
		and not ranged.aim_locked
		and ranged.center_target_marker.visible
		and ranged.center_target_marker.global_position.is_equal_approx(player.global_position),
		"Ranged volley: the unlocked retch warning must visibly track the real target"
	)
	ranged._update_retch_windup(config.ranged_retch_windup_time * 0.30)
	var locked_positions := ranged.locked_landing_positions.duplicate()
	_expect(
		ranged.aim_locked
		and locked_positions.size() == 3
		and ranged.landing_markers.all(func(marker): return marker.visible),
		"Ranged volley: lock must create exactly three visible real landing warnings"
	)
	for index in locked_positions.size():
		_expect(
			ranged.landing_markers[index].global_position.is_equal_approx(locked_positions[index]),
			"Ranged volley: warning %d must match its real locked landing point" % (index + 1)
		)
	player.global_position += Vector2(0.0, 120.0)
	ranged._update_retch_windup(config.ranged_retch_windup_time)
	_expect(
		ranged.state == RangedTasteEnemy.STATE_VOLLEY
		and ranged.locked_landing_positions == locked_positions,
		"Ranged volley: movement after lock must not retarget the three actual landing points"
	)

	var fired_indices: Array[int] = []
	var fired_positions: Array[Vector2] = []
	var fired_projectiles: Array[RangedFlavorProjectile] = []
	ranged.volley_projectile_fired.connect(func(index: int, position: Vector2, projectile: RangedFlavorProjectile):
		fired_indices.append(index)
		fired_positions.append(position)
		fired_projectiles.append(projectile)
	)
	ranged._update_volley(0.0)
	ranged._update_volley(config.ranged_volley_interval * 0.50)
	_expect(fired_indices.size() == 1, "Ranged volley: the three projectiles must not spawn in the same frame")
	ranged._update_volley(config.ranged_volley_interval * 0.55)
	ranged._update_volley(config.ranged_volley_interval * 0.50)
	_expect(fired_indices.size() == 2, "Ranged volley: the second projectile must respect the configured interval")
	ranged._update_volley(config.ranged_volley_interval * 0.55)
	_expect(
		fired_indices == [0, 1, 2]
		and fired_positions == locked_positions
		and ranged.state == RangedTasteEnemy.STATE_SHOOT_RECOVERY
		and ranged.landing_markers.all(func(marker): return not marker.visible),
		"Ranged volley: one attack must emit exactly three ordered projectiles, then enter visible recovery"
	)
	for projectile in fired_projectiles:
		if projectile != null and is_instance_valid(projectile):
			projectile.queue_free()
	await process_frame

	var base_center := Vector2(1580.0, 980.0)
	var base_positions := ranged._build_spread_positions(base_center)
	ranged.combat_statuses.apply_status(
		CombatStatusController.StatusType.AIM_DISRUPTION,
		"ranged_volley_test_choke",
		1.0,
		4.0
	)
	seed(24680)
	ranged._lock_volley_positions(base_center)
	var disrupted_positions := ranged.locked_landing_positions.duplicate()
	_expect(
		disrupted_positions.size() == 3
		and disrupted_positions != base_positions
		and ranged.landing_markers[0].global_position.is_equal_approx(disrupted_positions[0])
		and ranged.landing_markers[1].global_position.is_equal_approx(disrupted_positions[1])
		and ranged.landing_markers[2].global_position.is_equal_approx(disrupted_positions[2]),
		"Ranged volley: choking must alter actual locked trajectories and show those same displaced warnings"
	)
	ranged.combat_statuses.remove_source("ranged_volley_test_choke")

	var emitted_before_interrupt := fired_indices.size()
	ranged.state = RangedTasteEnemy.STATE_VOLLEY
	ranged.volley_shot_index = 0
	ranged.volley_interval_left = 0.0
	ranged._update_volley(0.0)
	var emitted_after_first := fired_indices.size()
	ranged.current_health = ranged.max_health_value
	ranged.receive_combat_hit(1.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 0.0, false, 100.0)
	_expect(
		emitted_after_first == emitted_before_interrupt + 1
		and ranged.state == BasicTasteEnemy.State.HIT_STUN
		and ranged.locked_landing_positions.is_empty()
		and ranged.landing_markers.all(func(marker): return not marker.visible),
		"Ranged volley: a valid stagger must cancel every not-yet-fired projectile and all warnings"
	)
	ranged.set_physics_process(true)
	for _frame in 15:
		await physics_frame
	_expect(
		fired_indices.size() == emitted_after_first and ranged.state == RangedTasteEnemy.STATE_SEEK,
		"Ranged volley: hit-stun recovery must return to ranged SEEK without resuming a cancelled volley"
	)
	ranged.set_physics_process(false)
	for node in get_nodes_in_group("ranged_leftover_projectile"):
		(node as RangedFlavorProjectile).queue_free()
	await process_frame

	var lure := ShabuTrap.new()
	lure.setup(ItemCatalog.create(ItemData.ItemType.SHABU_BEEF), scene.get_node("CombatRuntime").config)
	scene.add_child(lure)
	lure.global_position = ranged.global_position + Vector2(80.0, 0.0)
	_expect(
		EnemyTargetProvider.choose_target(ranged, player) == lure,
		"Ranged volley: the existing extensible target provider must keep shabu lure priority"
	)
	lure.queue_free()
	await process_frame

	player.configure_wave_health(100.0, 0.0, 30.0, 4.0, 10.0)
	ranged.global_position = player.global_position + Vector2(60.0, 0.0)
	ranged.state = RangedTasteEnemy.STATE_SEEK
	ranged.fire_cooldown_left = 0.0
	ranged._update_seek(0.01)
	var shield_before_shove := player.current_shield
	ranged._update_shove_windup(config.ranged_shove_windup)
	_expect(
		ranged.state == RangedTasteEnemy.STATE_SHOVE_RECOVERY
		and is_equal_approx(player.current_shield, shield_before_shove - config.ranged_shove_damage),
		"Ranged volley: close pressure must retain the weak telegraphed shove and unified shield pipeline"
	)

	player.global_position = Vector2(1640.0, 1140.0)
	player.configure_wave_health(100.0, 0.0, 30.0, 4.0, 10.0)
	ranged.global_position = player.global_position - Vector2(90.0, 0.0)
	ranged.combat_target = player
	ranged._lock_volley_positions(player.global_position)
	for shot_index in config.ranged_volley_count:
		ranged._fire_volley_projectile(shot_index)
		for _frame in 14:
			await physics_frame
	for _frame in 55:
		await physics_frame
	_expect(
		is_equal_approx(player.current_shield, 6.0),
		"Ranged volley: three unobstructed direct hits must total 24 damage without same-projectile splash duplication"
	)

	player.global_position = Vector2(1540.0, 900.0)
	player.configure_wave_health(100.0, 0.0, 30.0, 4.0, 10.0)
	var splash_projectile := RangedFlavorProjectile.new()
	scene.add_child(splash_projectile)
	splash_projectile.setup(
		player.global_position - Vector2(100.0, 0.0),
		player.global_position + Vector2(20.0, 0.0),
		config,
		null,
		ranged
	)
	for _frame in 30:
		await physics_frame
	_expect(
		not is_instance_valid(splash_projectile) and is_equal_approx(player.current_shield, 26.0),
		"Ranged volley: a missed direct hit must still deal the configured four-point landing splash"
	)

	player.global_position = Vector2(1540.0, 820.0)
	player.configure_wave_health(100.0, 0.0, 30.0, 4.0, 10.0)
	var dodge_target := player.global_position
	var dodge_projectile := RangedFlavorProjectile.new()
	scene.add_child(dodge_projectile)
	dodge_projectile.setup(dodge_target - Vector2(100.0, 0.0), dodge_target, config, player, ranged)
	player.global_position += Vector2(0.0, 100.0)
	for _frame in 30:
		await physics_frame
	_expect(
		not is_instance_valid(dodge_projectile) and is_equal_approx(player.current_shield, 30.0),
		"Ranged volley: leaving a locked warning before impact must dodge both direct and splash damage"
	)

	var projectile_wall := StaticBody2D.new()
	projectile_wall.collision_layer = 1
	projectile_wall.collision_mask = 0
	var projectile_wall_shape := CollisionShape2D.new()
	var projectile_wall_rectangle := RectangleShape2D.new()
	projectile_wall_rectangle.size = Vector2(30.0, 180.0)
	projectile_wall_shape.shape = projectile_wall_rectangle
	projectile_wall.add_child(projectile_wall_shape)
	scene.add_child(projectile_wall)
	projectile_wall.global_position = Vector2(1460.0, 760.0)
	player.global_position = projectile_wall.global_position + Vector2(100.0, 0.0)
	player.configure_wave_health(100.0, 0.0, 30.0, 4.0, 10.0)
	var blocked_projectile := RangedFlavorProjectile.new()
	scene.add_child(blocked_projectile)
	blocked_projectile.setup(projectile_wall.global_position - Vector2(80.0, 0.0), player.global_position, config, player, ranged)
	for _frame in 35:
		await physics_frame
	_expect(
		not is_instance_valid(blocked_projectile) and is_equal_approx(player.current_shield, 30.0),
		"Ranged volley: a facility must stop the ground-projected arc without taking damage or splashing through it"
	)
	_expect(
		config.ranged_concurrent_limit == 2
		and config.get_ranged_per_batch(1, 3) == 0
		and config.get_ranged_per_batch(2, 1) == 1
		and config.get_ranged_per_batch(3, 1) == 1,
		"Ranged volley: the existing wave debut, mixed wave, and concurrent cap must remain unchanged"
	)
	ranged.state = RangedTasteEnemy.STATE_VOLLEY
	ranged._lock_volley_positions(player.global_position)
	ranged.disable_for_failed_wave()
	_expect(
		ranged.state == BasicTasteEnemy.State.DISABLED
		and ranged.locked_landing_positions.is_empty()
		and ranged.landing_markers.all(func(marker): return not marker.visible),
		"Ranged volley: wave disable must cancel every remaining shot and telegraph"
	)
	await _dispose_scene(scene)


func _test_wave_mix_and_loot_configuration() -> void:
	var config := PrototypeWaveConfig.new()
	_expect(
		config.get_fast_per_batch(1, 1) == 0
		and config.get_fast_per_batch(1, 2) == 1
		and config.get_ranged_per_batch(1, 3) == 0,
		"Wave mix: wave one must introduce only the speed behavior in its latter half"
	)
	_expect(
		config.get_ranged_per_batch(2, 1) == 1
		and config.get_fast_per_batch(2, 2) == 1
		and config.get_ranged_per_batch(3, 1) == 1,
		"Wave mix: ranged must debut in wave two and all four types must mix in wave three"
	)
	_expect(
		config.wave_three_normal_per_batch < config.wave_two_normal_per_batch + 1,
		"Wave mix: mixed wave three must not restore excessive basic-enemy density"
	)
	_expect(
		config.fast_loot_whole_greens_weight == 35.0
		and config.fast_loot_oil_weight == 20.0
		and config.ranged_loot_salt_weight == 35.0
		and config.ranged_loot_small_rice_bag_weight == 10.0,
		"Loot: fast/ranged drop tendencies must live in centralized configuration"
	)
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var heavy_a := manager.spawn_heavy_enemy_for_test(Vector2(1200.0, 900.0))
	var beef := manager.settle_enemy_loot_for_test(heavy_a)
	var heavy_b := manager.spawn_heavy_enemy_for_test(Vector2(1260.0, 900.0))
	var second_beef := manager.settle_enemy_loot_for_test(heavy_b)
	var rice_bag_count := get_nodes_in_group("loot_drop").filter(
		func(node): return node is CarryableItem and node.data.item_type in [ItemData.ItemType.RICE_BAG, ItemData.ItemType.SMALL_RICE_BAG]
	).size()
	_expect(
		beef != null
		and second_beef != null
		and beef.data.item_type == ItemData.ItemType.RAW_STEAK
		and second_beef.data.item_type == ItemData.ItemType.RAW_STEAK
		and rice_bag_count == 0,
		"Loot: heavy must guarantee one 3x1 steak and must no longer roll any temporary rice bag"
	)
	await _dispose_scene(scene)


func _test_rice_bag_instance_and_atomic_extraction() -> void:
	var bag_data := ItemCatalog.create(ItemData.ItemType.RICE_BAG)
	_expect(
		ItemStorageCatalog.get_default_size(ItemData.ItemType.RICE_BAG) == Vector2i(3, 4)
		and ItemStorageCatalog.get_shape_bounds(ItemStorageCatalog.get_shape_cells(ItemData.ItemType.RICE_BAG, true)) == Vector2i(4, 3)
		and bag_data.remaining_portions == 20
		and bag_data.max_remaining_portions == 20,
		"Rice bag: each item instance must carry 20 portions and a rotatable 3x4 footprint"
	)
	var small_bag_data := ItemCatalog.create(ItemData.ItemType.SMALL_RICE_BAG)
	_expect(
		ItemStorageCatalog.get_default_size(ItemData.ItemType.SMALL_RICE_BAG) == Vector2i(2, 2)
		and small_bag_data.remaining_portions == 2
		and ItemCatalog.get_art_key_for_data(small_bag_data) == &"rice_bag_small",
		"Rice bag: enemy-drop bag must be a distinct 2-portion instance with its own 2x2 art mapping"
	)
	var duplicate := ItemCatalog.duplicate_data(bag_data)
	duplicate.remaining_portions = 7
	_expect(bag_data.remaining_portions == 20, "Rice bag: remaining portions must not be shared by item type")
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.reset_for_new_game(100.0, 0.0)
	var bag := _put_quick_item(scene, player, bag_data, 0)
	_expect(player._take_one_rice_from_bag(bag), "Rice bag: a successful atomic extraction must create one real raw-rice item")
	_expect(
		bag.data.remaining_portions == 19
		and _count_player_item_type(player, ItemData.ItemType.RAW_RICE) == 1,
		"Rice bag: only a successfully stored rice portion may decrement the bag"
	)
	for slot_index in range(1, QuickInventory.SLOT_COUNT):
		if player.inventory.get_item(slot_index) == null:
			_put_quick_item(scene, player, ItemCatalog.create(ItemData.ItemType.MUSHY_BOILED_BEEF), slot_index)
	for y in player.backpack.height:
		for x in player.backpack.width:
			if player.backpack.get_item_at(Vector2i(x, y)) == null:
				var filler := _new_item(scene, ItemData.ItemType.MUSHY_BOILED_BEEF)
				player.backpack.add_item_at(filler, Vector2i(x, y))
	var before_blocked := bag.data.remaining_portions
	_expect(
		not player._take_one_rice_from_bag(bag) and bag.data.remaining_portions == before_blocked,
		"Rice bag: full quick bar and backpack must leave both the portion and bag intact"
	)
	player.reset_for_new_game(100.0, 0.0)
	await process_frame
	_expect(
		player.inventory.slots.all(func(item): return item == null) and player.backpack.get_items().is_empty(),
		"Rice bag: formal run reset must clear quick inventory and backpack rice resources"
	)
	await _dispose_scene(scene)


func _test_water_and_rice_cooking_nodes() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var config := PrototypeCombatConfig.new()
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"test")
	holder.add_child(pot)
	_expect(pot.fill_water() and pot.water_units == 1, "Water: filling an empty clean pot must add exactly one discrete unit")
	_expect(pot.fill_water() and pot.water_units == 2 and not pot.fill_water(), "Water: a pot must cap at two discrete units")
	_expect(pot.drain_water() and pot.water_units == 0, "Water: an empty pot must support explicit draining without becoming an inventory water item")
	pot.fill_water()
	_expect(pot.insert_rice(ItemCatalog.create(ItemData.ItemType.RAW_RICE)), "Rice cooking: one water plus one rice must begin white-rice cooking")
	pot.complete_rice(config)
	_expect(
		pot.content_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE
		and pot.content_data.current_durability == config.white_rice_durability,
		"Rice cooking: completed white rice must receive its full weapon stats immediately"
	)
	pot.complete_crispy_rice(config)
	_expect(
		pot.content_data.item_type == ItemData.ItemType.UNPLATED_CRISPY_RICE
		and pot.content_data.current_durability == config.crispy_rice_durability,
		"Rice cooking: continued heating must transform cooked rice into active crispy-rice armor"
	)
	pot.burn_crispy_rice(config)
	_expect(pot.content_data.has_failure_tag(ItemData.FailureTag.BURNT), "Rice cooking: only further overheating may add the burnt failure tag")
	var porridge_pot := SoupPotItem.new()
	porridge_pot.setup_soup_pot(&"test_porridge")
	holder.add_child(porridge_pot)
	porridge_pot.fill_water()
	porridge_pot.fill_water()
	porridge_pot.insert_rice(ItemCatalog.create(ItemData.ItemType.RAW_RICE))
	porridge_pot.complete_rice(config)
	_expect(
		porridge_pot.content_data.item_type == ItemData.ItemType.UNPLATED_RICE_PORRIDGE
		and is_equal_approx(porridge_pot.content_data.hot_time_left, config.rice_porridge_hot_time),
		"Rice cooking: two water plus one rice must produce hot porridge with instance-owned cooling time"
	)
	holder.queue_free()
	await process_frame


func _test_white_rice_real_projectile_path() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var combat := scene.get_node("CombatRuntime") as CombatManager
	player.reset_for_new_game(100.0, 0.0)
	var rice_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	combat.config.apply_white_rice_stats(rice_data)
	var rice := _put_quick_item(scene, player, rice_data, 0)
	var front := DebugCombatTarget.new()
	front.combat_faction = CombatRules.Faction.ENEMY
	front.max_health = 80.0
	scene.add_child(front)
	var controller := player.get_node("DishAttackController") as DishAttackController
	var shot_direction := controller.get_current_aim_direction()
	front.global_position = player.global_position + shot_direction * 120.0
	var behind := DebugCombatTarget.new()
	behind.combat_faction = CombatRules.Faction.ENEMY
	behind.max_health = 80.0
	scene.add_child(behind)
	behind.global_position = player.global_position + shot_direction * 190.0
	var friendly := DebugCombatTarget.new()
	friendly.combat_faction = CombatRules.Faction.FRIENDLY
	friendly.max_health = 80.0
	scene.add_child(friendly)
	friendly.global_position = player.global_position + shot_direction * 90.0 + shot_direction.orthogonal() * 18.0
	Input.action_press("dish_attack")
	controller._process(0.016)
	Input.action_release("dish_attack")
	for _frame in 30:
		await process_frame
	_expect(
		combat.rice_balls_spawned == 1
		and front.current_health < front.max_health
		and is_equal_approx(behind.current_health, behind.max_health)
		and is_equal_approx(friendly.current_health, friendly.max_health),
		"White rice: real attack input must spawn one visible, single-target, non-piercing projectile that ignores friendly units"
	)
	_expect(
		rice.data.current_durability == combat.config.white_rice_durability - 1
		and rice.data.has_been_used
		and not rice.data.is_eligible_for_plating(),
		"White rice: an actual throw must consume durability and permanently remove plating eligibility"
	)
	controller.cooldown_left = 0.0
	await _dispose_scene(scene)


func _test_porridge_and_emergency_consumption() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var config := (scene.get_node("CombatRuntime") as CombatManager).config
	player.reset_for_new_game(100.0, 0.0)
	player.current_health = 50.0
	var porridge_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE)
	config.apply_rice_porridge_stats(porridge_data)
	porridge_data.hot_time_left = 0.0
	var porridge := _put_quick_item(scene, player, porridge_data, 0)
	var attack := player.get_node("DishAttackController") as DishAttackController
	var normal_bulls_before := (scene.get_node("CombatRuntime") as CombatManager).normal_bulls_spawned
	_expect(
		not attack.fire_once(Vector2.RIGHT)
		and (scene.get_node("CombatRuntime") as CombatManager).normal_bulls_spawned == normal_bulls_before,
		"Porridge: a healing-only dish must never fall through to the ordinary bull attack"
	)
	Input.action_press("secondary_use")
	player._start_secondary_use()
	player._update_consumption(0.5)
	Input.action_release("secondary_use")
	player._update_consumption(0.0)
	_expect(
		player.current_health > 50.0
		and player.current_health < 60.1
		and porridge.data.current_durability == 1
		and not player.is_consuming,
		"Porridge: real held input must heal continuously, prepay one durability, and preserve partial healing after release"
	)
	player.inventory.clear_all()
	await process_frame
	player.current_health = 50.0
	var interrupted_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE)
	config.apply_rice_porridge_stats(interrupted_data)
	var interrupted := _put_quick_item(scene, player, interrupted_data, 0)
	Input.action_press("secondary_use")
	player._start_secondary_use()
	player._update_consumption(0.25)
	var healed_before_hit := player.current_health
	player.hit_protection_left = 0.0
	player.receive_combat_hit(1.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
	Input.action_release("secondary_use")
	_expect(
		not player.is_consuming
		and interrupted.data.current_durability == 1
		and player.current_health >= healed_before_hit,
		"Porridge: an accepted hit must interrupt drinking without refunding durability or rolling back healing"
	)
	player.inventory.clear_all()
	await process_frame
	player.current_health = 2.0
	var hot_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE)
	config.apply_rice_porridge_stats(hot_data)
	hot_data.hot_time_left = 10.0
	_put_quick_item(scene, player, hot_data, 0)
	Input.action_press("secondary_use")
	player._start_secondary_use()
	player._update_hot_burn(config.rice_porridge_burn_duration)
	Input.action_release("secondary_use")
	_expect(player.current_health >= 1.0, "Porridge: Prototype hot burn must bypass shield but never reduce health below one")
	player.inventory.clear_all()
	await process_frame
	player.current_health = 50.0
	var emergency_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	config.apply_combat_dish_stats(emergency_data)
	var emergency := _put_quick_item(scene, player, emergency_data, 0)
	Input.action_press("secondary_use")
	player._start_secondary_use()
	player._update_consumption(0.25)
	Input.action_release("secondary_use")
	player._update_consumption(0.0)
	_expect(
		emergency.data.current_durability == config.standard_durability - ceili(float(config.standard_durability) * config.emergency_durability_ratio)
		and player.current_health > 50.0,
		"Emergency eating: standard dishes must use the shared secondary action, prepaid durability, and continuous partial healing"
	)
	await _dispose_scene(scene)


func _test_crispy_rice_armor_and_trap() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var combat := scene.get_node("CombatRuntime") as CombatManager
	player.reset_for_new_game(100.0, 0.0, 30.0, 4.0, 10.0)
	var first_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE)
	combat.config.apply_crispy_rice_stats(first_data)
	var first := _put_quick_item(scene, player, first_data, 0)
	var backup_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE)
	combat.config.apply_crispy_rice_stats(backup_data)
	var backup := _new_item(scene, ItemData.ItemType.UNPLATED_CRISPY_RICE)
	backup.data = backup_data
	backup.refresh_visual()
	player.backpack.add_item_at(backup, Vector2i.ZERO)
	_expect(player.get_active_crispy_rice() == first, "Crispy rice: quick slots left-to-right must activate before backpack placements")
	var backup_before := backup.data.current_durability
	player.hit_protection_left = 0.0
	player.receive_combat_hit(20.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
	_expect(
		is_equal_approx(player.current_shield, 15.0)
		and first.data.current_durability == combat.config.crispy_rice_durability - 1
		and backup.data.current_durability == backup_before,
		"Crispy rice: one armor must reduce damage before shield and must not consume a backup on the same hit"
	)
	first.data.current_durability = 1
	player.hit_protection_left = 0.0
	player.receive_combat_hit(4.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
	await process_frame
	_expect(
		combat.crispy_traps_spawned == 1 and player.get_active_crispy_rice() == backup,
		"Crispy rice: depletion must spawn exactly one trap and then hand off to the next armor"
	)
	var trap := get_first_node_in_group("crispy_rice_trap") as CrispyRiceTrap
	player.global_position = trap.global_position + Vector2(160.0, 0.0)
	var enemy := DebugCombatTarget.new()
	enemy.combat_faction = CombatRules.Faction.ENEMY
	enemy.max_health = 60.0
	scene.add_child(enemy)
	enemy.global_position = trap.global_position
	trap.arm_left = 0.0
	trap.owner_has_left = true
	trap._physics_process(0.0)
	_expect(
		enemy.current_health == 60.0 - combat.config.crispy_trap_damage and trap.triggered,
		"Crispy-rice trap: after arming it must damage the first valid unit once and then disappear"
	)
	var player_trap := combat.spawn_crispy_rice_trap(player.global_position, player)
	player_trap.arm_left = 0.0
	player_trap.owner_has_left = true
	player.hit_protection_left = 0.0
	var shield_before_trap := player.current_shield
	player_trap._physics_process(0.0)
	_expect(
		player.current_shield < shield_before_trap and player_trap.triggered,
		"Crispy-rice trap: after the owner has left, re-entry must allow real friendly-fire damage through the current armor/shield pipeline"
	)
	player.inventory.clear_all()
	player.backpack.clear_all()
	await process_frame
	var plated_data := ItemCatalog.create(ItemData.ItemType.PLATED_CRISPY_RICE)
	combat.config.apply_crispy_rice_stats(plated_data)
	plated_data.current_durability = 1
	_put_quick_item(scene, player, plated_data, 0)
	player.hit_protection_left = 0.0
	player.receive_combat_hit(2.0, CombatRules.Faction.ENEMY, Vector2.ZERO, 0.0, false)
	_expect(
		player.inventory.get_item(0) != null
		and player.inventory.get_item(0).data.item_type == ItemData.ItemType.DIRTY_PLATE,
		"Crispy rice: a plated armor that breaks must leave a dirty plate in the same actual inventory slot"
	)
	combat.clear_active_attacks()
	await process_frame
	_expect(get_nodes_in_group("crispy_rice_trap").is_empty(), "Crispy-rice trap: run cleanup must remove all retained traps")
	await _dispose_scene(scene)


func _test_debug_dummy_auto_attack_switch() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var enemy_a := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var enemy_b := scene.get_node("Kitchen/EnemyDummyB") as DebugCombatTarget
	var friendly := scene.get_node("Kitchen/FriendlyDummy") as DebugCombatTarget
	var debug_ui := scene.get_node("DebugUI") as PrototypeDebugUI
	var toggle := debug_ui.get_node("EnemyDummyAAutoAttackToggle") as CheckButton
	var combat := scene.get_node("CombatRuntime") as CombatManager
	player.reset_for_new_game(100.0, 0.0, 30.0, 4.0, 10.0)
	var armor_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE)
	combat.config.apply_crispy_rice_stats(armor_data)
	var armor := _put_quick_item(scene, player, armor_data, 0)
	enemy_a.global_position = Vector2(600.0, 600.0)
	player.global_position = enemy_a.global_position + Vector2(55.0, 0.0)
	friendly.global_position = enemy_a.global_position + Vector2(90.0, 0.0)
	enemy_b.global_position = enemy_a.global_position + Vector2(70.0, 0.0)
	enemy_a.reset_target()
	enemy_b.reset_target()
	friendly.reset_target()
	toggle.button_pressed = true
	await process_frame
	_expect(
		enemy_a.auto_attack_enabled and toggle.button_pressed,
		"Debug dummy: the real development switch must enable EnemyDummyA auto attack"
	)
	player.hit_protection_left = 0.0
	var armor_before := armor.data.current_durability
	var player_shield_before := player.current_shield
	var friendly_health_before := friendly.current_health
	var enemy_health_before := enemy_b.current_health
	var hits := enemy_a.perform_auto_attack_pulse()
	_expect(
		hits == 2
		and player.current_shield < player_shield_before
		and armor.data.current_durability == armor_before - 1,
		"Debug dummy: an attack pulse must hit the player through the real armor and shield pipeline"
	)
	_expect(
		friendly.current_health < friendly_health_before and is_equal_approx(enemy_b.current_health, enemy_health_before),
		"Debug dummy: a pulse must hit friendly targets but never enemy-faction targets"
	)
	player.global_position = enemy_a.global_position + Vector2(enemy_a.auto_attack_range + 40.0, 0.0)
	friendly.global_position = enemy_a.global_position + Vector2(enemy_a.auto_attack_range + 40.0, 20.0)
	var shield_outside := player.current_shield
	var friendly_outside := friendly.current_health
	enemy_a.perform_auto_attack_pulse()
	_expect(
		is_equal_approx(player.current_shield, shield_outside) and is_equal_approx(friendly.current_health, friendly_outside),
		"Debug dummy: targets outside the configured range must not be damaged"
	)
	enemy_a.set_lobby_active(false)
	debug_ui._process(0.0)
	_expect(
		not enemy_a.auto_attack_enabled and toggle.disabled and not toggle.button_pressed,
		"Debug dummy: formal-run dummy shutdown must also turn off and lock the development switch"
	)
	await _dispose_scene(scene)


func _put_quick_item(scene: Node, player: PrototypePlayer, data: ItemData, slot_index: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_inventory_stored(player)
	_expect(player.inventory.put_item(slot_index, item), "Test setup: requested quick slot must be empty")
	return item


func _new_item(parent: Node, item_type: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(ItemCatalog.create(item_type))
	parent.add_child(item)
	return item


func _count_player_item_type(player: PrototypePlayer, item_type: int) -> int:
	var count := 0
	for item in player.inventory.slots:
		if item != null and item.data.item_type == item_type:
			count += 1
	for item in player.backpack.get_items():
		if item.data.item_type == item_type:
			count += 1
	return count


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	Input.action_release("dish_attack")
	Input.action_release("secondary_use")
	if paused:
		paused = false
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
