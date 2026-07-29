extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_porridge_recipe_orders_and_limits()
	_test_soaked_rice_recipe_priority()
	await _test_real_porridge_drinking_and_zone_statuses()
	await _test_lobby_catalog_and_plating_quality()
	if failures.is_empty():
		print("PROTOTYPE_MISSING_RECIPES_GROUP_4_TEST: PASS (4/4 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MISSING_RECIPES_GROUP_4_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_porridge_recipe_orders_and_limits() -> void:
	var beef_first := _completed_white_porridge_pot()
	_expect(
		beef_first.insert_porridge_beef(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)),
		"Group 4 porridge: completed white porridge must accept a full marinated slice group"
	)
	_expect(
		beef_first.add_porridge_greens(_leaves(5), config),
		"Group 4 porridge: greens must upgrade unfinished beef porridge before completion"
	)
	beef_first.complete_expanded_recipe(config)
	_expect(
		beef_first.content_data.item_type == ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE
		and beef_first.content_data.recipe_id == ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE
		and beef_first.content_data.current_durability == config.greens_beef_porridge_durability
		and is_equal_approx(beef_first.content_data.healing_per_use, 13.0),
		"Group 4 porridge: specific combined recipe must preserve five greens and use centralized heal/durability"
	)

	var greens_first := _completed_white_porridge_pot()
	_expect(greens_first.insert_greens(_leaves(3)), "Group 4 porridge: greens may enter completed white porridge first")
	_expect(
		greens_first.insert_porridge_beef(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)),
		"Group 4 porridge: marinated beef may upgrade unfinished greens porridge"
	)
	_expect(
		greens_first.pending_recipe == ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE
		and greens_first.content_data.leaf_count == 3,
		"Group 4 porridge: both legal material orders must converge on the combined stable recipe ID"
	)

	var raw_branch := _completed_white_porridge_pot()
	raw_branch.insert_porridge_beef(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	raw_branch.add_porridge_greens(_leaves(2), config)
	raw_branch.complete_expanded_recipe(config)
	_expect(
		raw_branch.content_data.has_failure_tag(ItemData.FailureTag.UNMARINATED)
		and raw_branch.content_data.quality_cap == ItemData.Quality.NORMAL
		and is_equal_approx(
			float(raw_branch.content_data.effect_values["direct_bonus"]),
			config.greens_beef_porridge_unmarinated_bonus
		),
		"Group 4 porridge: unseasoned beef remains edible but must gain the failure tag and lose perfect eligibility"
	)


func _test_soaked_rice_recipe_priority() -> void:
	var beef_first := _one_water_cooked_rice_pot()
	_expect(
		beef_first.add_soaked_beef(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), config),
		"Group 4 soaked rice: marinated beef must enter only after complete white rice starts cooking in one water"
	)
	_expect(
		beef_first.add_soaked_greens(_leaves(5), config),
		"Group 4 soaked rice: greens must upgrade unfinished beef soaked rice"
	)
	beef_first.complete_function_rice(config)
	_expect(
		beef_first.content_data.item_type == ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE
		and beef_first.content_data.leaf_count == 5
		and beef_first.content_data.beef_portion_count == 5,
		"Group 4 soaked rice: mixed ingredients must resolve to the more specific recipe without losing counts"
	)

	var greens_first := _one_water_cooked_rice_pot()
	greens_first.add_soaked_greens(_leaves(3), config)
	_expect(
		greens_first.add_soaked_beef(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), config)
		and greens_first.pending_recipe == ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
		"Group 4 soaked rice: greens-first order must also converge on the specific mixed recipe"
	)

	var raw_rejected := _one_water_cooked_rice_pot()
	_expect(
		not raw_rejected.can_add_soaked_beef(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES)),
		"Group 4 soaked rice: the confirmed recipe must reject unseasoned beef rather than invent an unapproved branch"
	)


func _test_real_porridge_drinking_and_zone_statuses() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.current_health = 50.0
	var porridge := ExpandedRecipeCatalog.create_porridge(
		ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE,
		5,
		[
			ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE),
			ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES),
			_leaves(5),
		],
		config
	)
	porridge.set_quality_with_cap(ItemData.Quality.PERFECT)
	porridge.current_durability = 1
	porridge.hot_time_left = 0.0
	_put_quick_item(scene, player, porridge, 0)
	Input.action_press("secondary_use")
	player._start_secondary_use()
	player._update_consumption(config.greens_beef_porridge_use_time + 0.01)
	Input.action_release("secondary_use")
	_expect(
		is_equal_approx(player.current_health, 63.0)
		and is_equal_approx(
			player.combat_statuses.get_strongest(CombatStatusController.StatusType.DIRECT_MELEE_BONUS),
			config.greens_beef_porridge_perfect_bonus
		)
		and is_equal_approx(player.healing_over_time_rate, config.greens_beef_porridge_perfect_hot_heal_per_second),
		"Group 4 porridge: a real completed final drink must heal in real time and grant the perfect direct bonus/HoT"
	)

	var enemy := DebugCombatTarget.new()
	enemy.combat_faction = CombatRules.Faction.ENEMY
	scene.add_child(enemy)
	enemy.global_position = player.global_position + Vector2(20.0, 0.0)
	var mixed := ExpandedRecipeCatalog.create_rice_function_dish(
		ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
		5,
		[
			ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE),
			ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES),
			_leaves(5),
		],
		config
	)
	var zone := RiceEffectZone.new()
	zone.setup(player.global_position, mixed, config, false)
	scene.add_child(zone)
	zone._process(0.05)
	_expect(
		is_equal_approx(player.combat_statuses.get_strongest(CombatStatusController.StatusType.WEAKNESS), 0.15)
		and is_equal_approx(enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.VULNERABILITY), 0.15)
		and is_equal_approx(enemy.current_health, enemy.max_health),
		"Group 4 mixed soaked rice: the real faction-neutral zone must apply capped weakness/vulnerability without damage"
	)
	var perfect_zone := RiceEffectZone.new()
	perfect_zone.setup(player.global_position, mixed, config, true)
	scene.add_child(perfect_zone)
	perfect_zone._process(0.05)
	_expect(
		is_equal_approx(enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.MOVE_SLOW), 0.35)
		and is_equal_approx(enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.ATTACK_SPEED_SLOW), 0.30)
		and is_equal_approx(enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.WEAKNESS), 0.20)
		and is_equal_approx(enemy.combat_statuses.get_strongest(CombatStatusController.StatusType.VULNERABILITY), 0.20),
		"Group 4 perfect final zone: exact final snapshot must use the larger slow and capped 20% dual statuses"
	)
	await _dispose_scene(scene)


func _test_lobby_catalog_and_plating_quality() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	cabinet.configure_lobby_unlimited_catalog()
	var all_types := [
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE,
		ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE,
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE,
		ItemData.ItemType.PLATED_BEEF_SOAKED_RICE,
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE,
		ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE,
	]
	for item_type in all_types:
		_expect(cabinet.get_stock(item_type) == 1, "Group 4 cabinet: every unplated/plated state must be present and replenishable")
	for item_type in [
		ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE,
		ItemData.ItemType.PLATED_BEEF_SOAKED_RICE,
		ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE,
	]:
		var sample := cabinet._find_item(item_type)
		_expect(
			sample != null
			and sample.data.quality == ItemData.Quality.PERFECT
			and sample.data.current_durability == sample.data.max_durability,
			"Group 4 cabinet: legally perfect plated samples must carry real perfect stats after movement"
		)
	var plating := PlatingController.new()
	_expect(
		plating._get_plated_type(ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE) == ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE
		and plating._get_plated_type(ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE) == ItemData.ItemType.PLATED_BEEF_SOAKED_RICE
		and plating._get_plated_type(ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE) == ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE,
		"Group 4 plating: all three recipes must use the shared movable plating route"
	)
	cabinet.queue_free()
	await process_frame


func _completed_white_porridge_pot() -> SoupPotItem:
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"group4_porridge")
	pot.content_data = ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE)
	config.apply_rice_porridge_stats(pot.content_data)
	pot.cook_stage = SoupPotItem.CookStage.PORRIDGE_READY
	return pot


func _one_water_cooked_rice_pot() -> SoupPotItem:
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"group4_soaked")
	pot.fill_water()
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(rice)
	pot.insert_cooked_rice(rice, config)
	return pot


func _leaves(count: int) -> ItemData:
	var data := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	data.stack_count = count
	data.leaf_count = count
	return data


func _put_quick_item(scene: Node, player: PrototypePlayer, data: ItemData, slot_index: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_inventory_stored(player)
	_expect(player.inventory.put_item(slot_index, item), "Group 4 setup: requested quick slot must be empty")
	return item


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
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
