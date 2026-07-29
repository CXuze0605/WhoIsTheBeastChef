extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_real_greens_cutting()
	_test_exact_water_and_recipe_priority()
	await _test_shared_meal_effects()
	await _test_lobby_catalog_and_plating_quality()
	if failures.is_empty():
		print("PROTOTYPE_MISSING_RECIPES_GROUP_3_TEST: PASS (4/4 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MISSING_RECIPES_GROUP_3_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_real_greens_cutting() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var board := scene.get_tree().get_first_node_in_group("cutting_board") as CuttingBoard
	var leaves := ItemFactory.create_carryable(_leaves(3))
	scene.add_child(leaves)
	board.stored_item = leaves
	leaves.set_stored(board, Vector2.ZERO)
	_expect(board.begin_primary_interaction(player), "Group 3 cutting: a real leaf stack must start the cutting-board hold interaction")
	board.update_primary_interaction(player, board.prototype_dice_cut_time + 0.01)
	_expect(
		board.stored_item != null
		and board.stored_item.data.item_type == ItemData.ItemType.GREENS_CRUMBS
		and board.stored_item.data.stack_count == 3
		and board.stored_item.data.leaf_count == 3,
		"Group 3 cutting: each leaf must atomically become one stackable greens crumb"
	)
	await _dispose_scene(scene)


func _test_exact_water_and_recipe_priority() -> void:
	var beef_first := _one_water_rice_pot()
	var marinated := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)
	_expect(beef_first.add_braised_rice_beef(marinated, config), "Group 3 recipe: one-water raw rice must accept a full beef-dice group")
	_expect(
		beef_first.pending_recipe == ExpandedRecipeCatalog.BEEF_BRAISED_RICE
		and beef_first.cook_stage == SoupPotItem.CookStage.BEEF_BRAISED_RICE_COOKING,
		"Group 3 recipe: beef-only ingredients must select beef braised rice"
	)
	_expect(beef_first.add_braised_rice_greens(_crumbs(5), config), "Group 3 priority: unfinished beef braised rice must accept a five-unit greens upgrade")
	_expect(
		beef_first.pending_recipe == ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE,
		"Group 3 priority: the more specific mixed braised recipe must replace the unfinished beef recipe"
	)
	beef_first.complete_braised_rice(config)
	_expect(
		beef_first.content_data.item_type == ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE
		and beef_first.content_data.current_durability == 12,
		"Group 3 recipe: mixed braised rice must finish with centralized durability"
	)

	var greens_first := _one_water_rice_pot()
	_expect(greens_first.add_vegetable_rice_greens(_leaves(5), true, config), "Group 3 order: greens may enter before beef while rice is unfinished")
	_expect(greens_first.add_braised_rice_beef(marinated, config), "Group 3 order: beef may upgrade unfinished vegetable rice to mixed braised rice")
	_expect(
		greens_first.pending_recipe == ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE,
		"Group 3 order: material order before completion must not change the specific mixed result"
	)

	var raw_beef := _one_water_rice_pot()
	_expect(raw_beef.add_braised_rice_beef(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_DICE), config), "Group 3 raw branch: unseasoned beef remains a legal Prototype route")
	raw_beef.complete_braised_rice(config)
	_expect(
		raw_beef.content_data.has_failure_tag(ItemData.FailureTag.UNMARINATED)
		and raw_beef.content_data.quality_cap == ItemData.Quality.NORMAL
		and raw_beef.content_data.max_durability == 9,
		"Group 3 raw branch: unseasoned beef must lose perfect eligibility and use reduced durability"
	)

	var two_water := SoupPotItem.new()
	two_water.setup_soup_pot(&"group3_two_water")
	two_water.fill_water()
	two_water.fill_water()
	two_water.insert_rice(ItemCatalog.create(ItemData.ItemType.RAW_RICE))
	_expect(
		two_water.cook_stage == SoupPotItem.CookStage.PORRIDGE_COOKING
		and not two_water.can_add_braised_rice_beef(marinated),
		"Group 3 water split: two-water porridge must never be intercepted by the one-water braised recipe"
	)


func _test_shared_meal_effects() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.current_shield = 0.0
	var mixed := ExpandedRecipeCatalog.create_group_3_braised_rice(
		ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE,
		[
			ItemCatalog.create(ItemData.ItemType.RAW_RICE),
			ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE),
			_leaves(5),
		],
		config
	)
	mixed.set_quality_with_cap(ItemData.Quality.PERFECT)
	mixed.has_perfect_finisher = true
	mixed.current_durability = 1
	var station := VegetableRiceStation.new()
	station.setup(mixed)
	scene.add_child(station)
	_expect(station.begin_primary_interaction(player), "Group 3 station: real hold interaction must start at the deployed shared meal")
	station.update_primary_interaction(player, config.greens_beef_braised_rice_bite_time + 0.01)
	_expect(
		is_equal_approx(player.current_shield, config.greens_beef_braised_rice_perfect_shield)
		and is_equal_approx(player.combat_statuses.get_strongest(CombatStatusController.StatusType.DIRECT_MELEE_BONUS), 0.15)
		and is_equal_approx(player.combat_statuses.get_strongest(CombatStatusController.StatusType.DIRECT_RANGED_BONUS), 0.15)
		and is_equal_approx(player.combat_statuses.get_strongest(CombatStatusController.StatusType.DAMAGE_REDUCTION), 0.10),
		"Group 3 station: perfect last bite must restore 8 shield and apply only the configured direct bonuses/reduction"
	)
	_expect(
		is_equal_approx(
			player.combat_statuses.get_outgoing_damage_multiplier(DamageContext.SourceType.TURRET, false),
			1.0
		),
		"Group 3 station: turret/automatic sources must not inherit player-direct meal bonuses"
	)
	await _dispose_scene(scene)


func _test_lobby_catalog_and_plating_quality() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	cabinet.configure_lobby_unlimited_catalog()
	for item_type in [
		ItemData.ItemType.GREENS_CRUMBS,
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE,
		ItemData.ItemType.PLATED_BEEF_BRAISED_RICE,
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE,
		ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE,
	]:
		_expect(cabinet.get_stock(item_type) == 1, "Group 3 cabinet: every intermediate and dish state must be present and replenishable")
	for item_type in [
		ItemData.ItemType.PLATED_BEEF_BRAISED_RICE,
		ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE,
	]:
		var sample := cabinet._find_item(item_type)
		_expect(
			sample != null
			and sample.data.quality == ItemData.Quality.PERFECT
			and sample.data.current_durability == sample.data.max_durability,
			"Group 3 cabinet: legally perfect plated braised-rice samples must be real perfect full-durability instances"
		)
	cabinet.queue_free()
	await process_frame


func _one_water_rice_pot() -> SoupPotItem:
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"group3")
	pot.fill_water()
	pot.insert_rice(ItemCatalog.create(ItemData.ItemType.RAW_RICE))
	return pot


func _leaves(count: int) -> ItemData:
	var data := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	data.stack_count = count
	data.leaf_count = count
	return data


func _crumbs(count: int) -> ItemData:
	var data := ItemCatalog.create(ItemData.ItemType.GREENS_CRUMBS)
	data.stack_count = count
	data.leaf_count = count
	return data


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
