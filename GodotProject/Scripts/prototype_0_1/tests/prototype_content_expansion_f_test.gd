extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_real_combination_qte_and_recipe_inheritance()
	_test_real_soup_and_mustard_preparation()
	await _test_turret_random_bag_and_perfect_final()
	await _test_five_independent_soup_streams()
	await _test_mustard_zero_damage_marks_curse_and_cleanup()
	if failures.is_empty():
		print("PROTOTYPE_CONTENT_EXPANSION_F_TEST: PASS (5/5 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_CONTENT_EXPANSION_F_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_real_combination_qte_and_recipe_inheritance() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(rice)
	var beef := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.BEEF_GREENS,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), _leaves(5)],
		config
	)
	beef.add_failure_tag(ItemData.FailureTag.BURNT)
	_give(player, rice)
	_give(player, beef)
	_give(player, ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	_expect(plating.request_start(), "Milestone F combination: two unused components and a clean plate must start the real moving QTE")
	_expect(plating.action_mode == PlatingController.ActionMode.COMBINE_RICE_BOWL, "Milestone F combination: the controller must reserve a dedicated atomic combination mode")
	plating.complete_for_test(true)
	var result_item := _find_quick_type(player, ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL)
	_expect(
		result_item != null
		and result_item.data.failure_tags.has(ItemData.FailureTag.BURNT)
		and result_item.data.quality != ItemData.Quality.PERFECT
		and player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_BEEF_GREENS) < 0,
		"Milestone F combination: component failure tags must survive and both old attack forms must be replaced by one turret dish"
	)
	await _dispose_scene(scene)


func _test_real_soup_and_mustard_preparation() -> void:
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"f_soup")
	pot.fill_water()
	pot.fill_water()
	var beef := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)
	_expect(pot.insert_beef_soup_base(beef), "Milestone F soup: two water and a full beef-slice group must start the soup base")
	pot.complete_beef_soup_base()
	_expect(pot.add_beef_soup_greens(_leaves(5), config), "Milestone F soup: greens after the completed beef base must preserve perfect eligibility")
	pot.complete_beef_greens_soup(config)
	_expect(
		pot.content_data.recipe_id == ExpandedRecipeCatalog.BEEF_GREENS_SOUP
		and pot.content_data.current_durability == config.beef_greens_soup_durability
		and pot.content_data.quality_cap == ItemData.Quality.PERFECT,
		"Milestone F soup: recommended order must produce a full-duration independently toggleable auto dish"
	)
	var plain := ExpandedRecipeCatalog.create_advanced_dish(
		ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
		5,
		[ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES), _leaves(5)],
		config
	)
	plain.set_quality_with_cap(ItemData.Quality.PERFECT)
	_expect(plain.quality == ItemData.Quality.NORMAL, "Milestone F soup: un-marinated beef remains valid but can never become perfect")
	var mustard := ExpandedRecipeCatalog.create_advanced_dish(
		ExpandedRecipeCatalog.MUSTARD_GREENS,
		3,
		[_leaves(3), ItemCatalog.create(ItemData.ItemType.MUSTARD)],
		config
	)
	mustard.set_quality_with_cap(ItemData.Quality.PERFECT)
	_expect(
		mustard.is_weird_dish()
		and mustard.quality == ItemData.Quality.NORMAL
		and mustard.current_durability == 3,
		"Milestone F mustard greens: weird quality cap and actual leaf-count ammunition must both be enforced"
	)
	pot.free()


func _test_turret_random_bag_and_perfect_final() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var enemies: Array[DebugCombatTarget] = []
	for position in [Vector2(85.0, 0.0), Vector2(105.0, 25.0), Vector2(115.0, -20.0)]:
		var enemy := _target(scene, position)
		enemies.append(enemy)
	var data := ExpandedRecipeCatalog.create_advanced_dish(
		ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL,
		5,
		[],
		config
	)
	data.current_durability = 4
	var turret := RiceBowlTurret.new()
	turret.setup(data, config, 9127)
	scene.add_child(turret)
	turret.set_process(false)
	for _shot in 3:
		turret.cooldown_left = 0.0
		turret._process(0.0)
	_expect(
		turret.shot_history.slice(0, 3).duplicate().all(func(mode): return mode in [0, 1, 2])
		and _unique_count(turret.shot_history.slice(0, 3)) == 3,
		"Milestone F turret: each seeded three-shot bag must contain rice, greens and beef exactly once"
	)
	for _step in 8:
		for projectile in get_nodes_in_group("temporary_attack_entity"):
			if is_instance_valid(projectile):
				projectile._process(0.025)
		await process_frame
	_expect(
		enemies.any(func(enemy): return enemy.current_health < enemy.max_health),
		"Milestone F turret: observable projectiles must change actual enemy health, not only append shot history"
	)
	var perfect := ExpandedRecipeCatalog.create_advanced_dish(ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL, 5, [], config)
	perfect.set_quality_with_cap(ItemData.Quality.PERFECT)
	perfect.current_durability = 1
	var final_turret := RiceBowlTurret.new()
	final_turret.setup(perfect, config, 55)
	scene.add_child(final_turret)
	final_turret.set_process(false)
	final_turret._process(0.0)
	_expect(
		final_turret.shot_history == [0, 1, 2],
		"Milestone F turret: perfect final durability must fire all three ammunition modes together instead of drawing a random mode"
	)
	await _dispose_scene(scene)


func _test_five_independent_soup_streams() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var enemy := _target(scene, player.global_position + Vector2(80.0, 0.0))
	for index in 5:
		var soup := ExpandedRecipeCatalog.create_advanced_dish(
			ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
			5,
			[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), _leaves(5)],
			config
		)
		var item := _give(player, soup)
		_expect(player.auto_dish_controller.toggle_auto_equipment(item), "Milestone F auto soup: every carried instance must be independently toggleable")
	await process_frame
	await process_frame
	_expect(
		get_nodes_in_group("auto_dish_stream").size() == 5,
		"Milestone F auto soup: five carried enabled soups must create five independent visible stream runtimes without a hidden cap"
	)
	var health_before := enemy.current_health
	for stream in get_nodes_in_group("auto_dish_stream"):
		stream.target = enemy
		stream._fire_tick()
	_expect(
		enemy.current_health < health_before
		and get_nodes_in_group("auto_dish_stream").all(
			func(stream): return stream.ticks_fired >= 1 and stream.source_item.data.current_durability < stream.source_item.data.max_durability
		),
		"Milestone F auto soup: all five streams must independently damage, push and consume their own durability"
	)
	await _dispose_scene(scene)


func _test_mustard_zero_damage_marks_curse_and_cleanup() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var attack := player.get_node("DishAttackController") as DishAttackController
	var enemy := _target(scene, player.global_position + Vector2(74.0, 0.0))
	var nearby := _target(scene, player.global_position + Vector2(100.0, 30.0))
	var data := ExpandedRecipeCatalog.create_advanced_dish(
		ExpandedRecipeCatalog.MUSTARD_GREENS,
		1,
		[_leaves(1), ItemCatalog.create(ItemData.ItemType.MUSTARD)],
		config
	)
	var item := _give(player, data)
	var health_before := enemy.current_health
	_expect(attack.fire_once(Vector2.RIGHT), "Milestone F mustard greens: the real dish attack path must launch a leaf")
	var projectile := combat.get_children().filter(func(child): return child is MustardGreensProjectile).front() as MustardGreensProjectile
	for _step in 8:
		if is_instance_valid(projectile):
			projectile._process(0.02)
	player.auto_dish_controller._process(0.0)
	_expect(
		enemy.current_health == health_before
		and enemy.get_instance_id() in item.data.linked_target_ids
		and enemy.combat_statuses.has_status(CombatStatusController.StatusType.WEAKNESS)
		and enemy.combat_statuses.has_status(CombatStatusController.StatusType.ATTACK_SPEED_SLOW),
		"Milestone F mustard greens: a real hit must deal zero damage and maintain the primary four-part debuff by source instance"
	)
	_expect(
		nearby.combat_statuses.has_status(CombatStatusController.StatusType.MOVE_SLOW)
		and nearby.combat_statuses.has_status(CombatStatusController.StatusType.VULNERABILITY)
		and not nearby.combat_statuses.has_status(CombatStatusController.StatusType.WEAKNESS)
		and player.combat_statuses.has_status(CombatStatusController.StatusType.VULNERABILITY),
		"Milestone F mustard greens: moving aura gets only slow/vulnerability while the carrier curse remains active"
	)
	enemy.current_health = 0.0
	player.auto_dish_controller._process(0.0)
	_expect(
		item.data.item_type == ItemData.ItemType.DIRTY_PLATE,
		"Milestone F mustard greens: the zero-ammo residual must remain until its final linked target leaves, then become a dirty plate"
	)
	var second_data := ExpandedRecipeCatalog.create_advanced_dish(ExpandedRecipeCatalog.MUSTARD_GREENS, 2, [_leaves(2)], config)
	var second := _give(player, second_data)
	enemy.reset_target()
	player.auto_dish_controller.register_mustard_target(second, enemy)
	player.auto_dish_controller._process(0.0)
	player.inventory.select(player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_MUSTARD_GREENS))
	player.drop_held_item()
	player.auto_dish_controller._process(0.0)
	_expect(
		second.data.linked_target_ids.is_empty()
		and not enemy.combat_statuses.has_status(CombatStatusController.StatusType.WEAKNESS),
		"Milestone F mustard greens: moving the source outside quick/backpack must immediately clear every linked benefit and curse"
	)
	await _dispose_scene(scene)


func _give(player: PrototypePlayer, data: ItemData) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	current_scene.add_child(item)
	item.global_position = player.global_position
	if not player.pickup_item(item):
		failures.append("Test setup could not route %s into player inventory" % data.display_name)
	return item


func _find_quick_type(player: PrototypePlayer, item_type: int) -> CarryableItem:
	var slot := player.inventory.find_item_slot(item_type)
	return player.inventory.get_item(slot) if slot >= 0 else null


func _target(parent: Node, position: Vector2) -> DebugCombatTarget:
	var target := DebugCombatTarget.new()
	target.combat_faction = CombatRules.Faction.ENEMY
	target.global_position = position
	parent.add_child(target)
	return target


func _leaves(count: int) -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = count
	leaves.leaf_count = count
	return leaves


func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[value] = true
	return unique.size()


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
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
