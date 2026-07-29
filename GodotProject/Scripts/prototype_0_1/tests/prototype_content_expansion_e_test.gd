extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_recipe_values_and_real_pot_routes()
	await _test_vegetable_rice_shared_station()
	await _test_soaked_rice_enemy_and_friendly_zone()
	await _test_real_deployment_and_cleanup()
	if failures.is_empty():
		print("PROTOTYPE_CONTENT_EXPANSION_E_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_CONTENT_EXPANSION_E_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_recipe_values_and_real_pot_routes() -> void:
	var leaves_two := _leaves(2)
	var leaves_four := _leaves(4)
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"e_test")
	pot.fill_water()
	pot.insert_rice(ItemCatalog.create(ItemData.ItemType.RAW_RICE))
	_expect(
		pot.add_vegetable_rice_greens(_leaves(5), true, config),
		"Milestone E cooking: five leaves must join partially cooked rice without losing the rice"
	)
	pot.complete_function_rice(config)
	_expect(
		pot.content_data.recipe_id == ExpandedRecipeCatalog.VEGETABLE_RICE
		and pot.content_data.current_durability == config.vegetable_rice_durability,
		"Milestone E cooking: rice plus one full greens group must form durable vegetable rice"
	)
	pot.take_content()
	pot.fill_water()
	var cooked_rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(cooked_rice)
	_expect(pot.insert_cooked_rice(cooked_rice, config), "Milestone E cooking: one water plus a complete unused cooked rice must start soaked rice")
	pot.complete_function_rice(config)
	_expect(pot.add_soaked_greens(leaves_two, config), "Milestone E cooking: soaked rice must accept an initial leaf addition")
	_expect(pot.add_soaked_greens(leaves_four, config), "Milestone E cooking: greens soaked rice must accept another leaf addition and restart the short stage")
	pot.complete_function_rice(config)
	_expect(
		pot.content_data.recipe_id == ExpandedRecipeCatalog.GREENS_SOAKED_RICE
		and pot.content_data.leaf_count == 5
		and is_equal_approx(float(pot.content_data.effect_values["weakness"]), config.greens_soaked_rice_weakness_cap),
		"Milestone E cooking: repeated leaves must cap effective weakness at five without discarding the recipe"
	)
	var used_rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(used_rice)
	used_rice.mark_used()
	var rejection_pot := SoupPotItem.new()
	rejection_pot.setup_soup_pot(&"reject")
	rejection_pot.fill_water()
	_expect(
		not rejection_pot.can_insert_cooked_rice(used_rice),
		"Milestone E atomic recipe: previously used cooked rice must never be accepted as complete soaked-rice material"
	)
	pot.free()
	rejection_pot.free()


func _test_vegetable_rice_shared_station() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.current_shield = 0.0
	player.time_since_last_damage = 0.0
	var dish := ExpandedRecipeCatalog.create_rice_function_dish(
		ExpandedRecipeCatalog.VEGETABLE_RICE, 5, [_leaves(5)], config
	)
	dish.set_quality_with_cap(ItemData.Quality.PERFECT)
	var station := VegetableRiceStation.new()
	station.setup(dish)
	scene.add_child(station)
	station.global_position = player.global_position
	await process_frame
	var before := dish.current_durability
	station.begin_primary_interaction(player)
	station.update_primary_interaction(player, float(dish.effect_values["bite_time"]) * 0.4)
	station.cancel_primary_interaction(player)
	_expect(
		dish.current_durability == before and is_zero_approx(player.current_shield),
		"Milestone E vegetable rice: cancelling an incomplete bite must not consume shared durability or grant shield"
	)
	station.begin_primary_interaction(player)
	station.update_primary_interaction(player, float(dish.effect_values["bite_time"]) + 0.01)
	_expect(
		dish.current_durability == before - 1 and player.current_shield > 0.0,
		"Milestone E vegetable rice: a completed real hold must consume one shared bite and restore actual player shield"
	)
	dish.current_durability = 1
	player.current_shield = 0.0
	station.begin_primary_interaction(player)
	station.update_primary_interaction(player, float(dish.effect_values["bite_time"]) + 0.01)
	_expect(
		player.combat_statuses.has_status(CombatStatusController.StatusType.DAMAGE_REDUCTION),
		"Milestone E vegetable rice: the completed perfect final bite must grant the configured temporary reduction"
	)
	await _dispose_scene(scene)


func _test_soaked_rice_enemy_and_friendly_zone() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var enemy := DebugCombatTarget.new()
	enemy.combat_faction = CombatRules.Faction.ENEMY
	scene.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(20.0, 0.0)
	var data := ExpandedRecipeCatalog.create_rice_function_dish(
		ExpandedRecipeCatalog.GREENS_SOAKED_RICE, 5, [_leaves(5)], config
	)
	var zone := RiceEffectZone.new()
	zone.setup(player.global_position, data, config, false)
	scene.add_child(zone)
	await process_frame
	zone._process(0.05)
	_expect(
		player.combat_statuses.get_strongest(CombatStatusController.StatusType.MOVE_SLOW) == config.soaked_rice_move_slow
		and enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.ATTACK_SPEED_SLOW) == config.soaked_rice_attack_slow,
		"Milestone E soaked rice: the real zone must affect friendly player and enemy alike with movement/attack slowdown"
	)
	_expect(
		enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.WEAKNESS) == config.greens_soaked_rice_weakness_cap
		and enemy.current_health == enemy.max_health,
		"Milestone E greens soaked rice: five leaves must apply capped weakness without dealing direct damage"
	)
	await _dispose_scene(scene)


func _test_real_deployment_and_cleanup() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var trap_controller := player.get_node("TrapController") as TrapController
	var dish := ExpandedRecipeCatalog.create_rice_function_dish(
		ExpandedRecipeCatalog.SOAKED_RICE, 0, [], config
	)
	var carried := ItemFactory.create_carryable(dish)
	scene.add_child(carried)
	carried.global_position = player.global_position
	_expect(player.pickup_item(carried), "Milestone E deploy: soaked rice must enter the real quick inventory")
	_expect(trap_controller.place_selected_deployable(), "Milestone E deploy: the shared G action must route soaked rice into a real effect zone")
	_expect(
		not get_nodes_in_group("rice_effect_zone").is_empty() and dish.current_durability == config.soaked_rice_durability - 1,
		"Milestone E deploy: an actual pour must create an observable zone and consume exactly one durability"
	)
	scene.get_node("CombatRuntime").clear_active_attacks()
	await process_frame
	_expect(get_nodes_in_group("run_deployable").is_empty(), "Milestone E reset: formal attack cleanup must remove retained food deployments")
	await _dispose_scene(scene)


func _leaves(count: int) -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = count
	leaves.leaf_count = count
	return leaves


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
