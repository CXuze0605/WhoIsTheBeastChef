extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_recipe_data_and_quality()
	_test_real_wok_branches_and_specificity()
	_test_real_soup_branches()
	await _test_fried_white_rice_ring()
	await _test_clear_beef_combo()
	await _test_held_soup_streams()
	await _test_lobby_catalog_and_perfect_samples()
	_test_freshness_and_waste_integration()
	if failures.is_empty():
		print("PROTOTYPE_MISSING_RECIPES_GROUP_1_TEST: PASS (8/8 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MISSING_RECIPES_GROUP_1_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_recipe_data_and_quality() -> void:
	var rice := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.FRIED_WHITE_RICE,
		[_ready_rice(), _single_oil_source()],
		config
	)
	_expect(
		rice.item_type == ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE
		and rice.current_durability == config.fried_white_rice_durability
		and int(rice.effect_values["grain_count"]) == 20,
		"Group 1 data: fried white rice must have its independent type, durability and 20-grain profile"
	)
	var raw_beef := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES), _single_oil_source()],
		config
	)
	raw_beef.set_quality_with_cap(ItemData.Quality.PERFECT)
	_expect(
		raw_beef.has_failure_tag(ItemData.FailureTag.UNMARINATED)
		and raw_beef.quality == ItemData.Quality.NORMAL
		and raw_beef.current_durability == config.clear_beef_unmarinated_durability,
		"Group 1 data: un-marinated clear beef must remain valid, tagged, weaker and capped at normal"
	)
	var salted_greens := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.GREENS_SOUP,
		[_leaf_stack(), _single_salt_source()],
		config,
		5
	)
	_expect(
		salted_greens.current_durability == config.greens_soup_base_durability + 5 + config.salt_durability_bonus
		and salted_greens.has_active_modifier(ItemData.ActiveModifier.SALTED),
		"Group 1 data: one salt portion must add only the centralized durability bonus"
	)


func _test_real_wok_branches_and_specificity() -> void:
	var wok := WokItem.new()
	wok.setup_wok(&"group1")
	wok.add_oil()
	_expect(wok.insert_cooked_rice_base(_ready_rice()), "Group 1 wok: unused complete white rice must enter the fried-white-rice route")
	wok.complete_missing_group_1(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.FRIED_WHITE_RICE, "Group 1 wok: base rice route must form fried white rice")
	wok.take_content()

	wok.add_oil()
	wok.insert_cooked_rice_base(_ready_rice())
	wok.insert_dice(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE))
	wok.add_combination_greens(_leaf_stack())
	_expect(wok.pending_recipe == ExpandedRecipeCatalog.MIXED_FRIED_RICE, "Group 1 specificity: rice base must yield to the more complete mixed fried-rice recipe")
	wok.complete_wok_combination(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.MIXED_FRIED_RICE, "Group 1 specificity: the complete mixed recipe must not be swallowed by fried white rice")
	wok.take_content()

	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.complete_stage_one()
	_expect(wok.pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF, "Group 1 wok: first beef stage must expose the clear/chili branch window")
	wok.complete_missing_group_1(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF, "Group 1 wok: continuing without chili must form clear stir-fry beef")
	wok.take_content()

	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.complete_stage_one()
	wok.add_chili()
	_expect(wok.pending_recipe == &"", "Group 1 wok: adding chili during the branch window must return to the existing stir-fry beef route")
	wok.complete_stage_two()
	_expect(wok.content_data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, "Group 1 wok: chili branch must still form existing stir-fry beef")
	wok.free()


func _test_real_soup_branches() -> void:
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"group1")
	pot.fill_water()
	pot.fill_water()
	pot.mark_boiling()
	_expect(pot.insert_greens(_leaf_stack()), "Group 1 soup: two boiling water units must accept greens")
	pot.complete_greens_soup_blanching(config)
	_expect(
		pot.content_data.item_type == ItemData.ItemType.UNPLATED_BOILED_GREENS
		and pot.cook_stage == SoupPotItem.CookStage.GREENS_SOUP_FINISHING,
		"Group 1 soup: the first discrete node must remain an early-take boiled/salt-water greens result"
	)
	pot.complete_greens_soup(config)
	_expect(pot.content_data.recipe_id == ExpandedRecipeCatalog.GREENS_SOUP, "Group 1 soup: continuing after blanching must form greens soup")
	pot.take_content()

	pot.fill_water()
	pot.fill_water()
	pot.mark_boiling()
	_expect(pot.insert_beef_soup_base(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)), "Group 1 soup: a full marinated dice group must enter the beef-soup route")
	pot.complete_beef_soup_base()
	_expect(pot.cook_stage == SoupPotItem.CookStage.BEEF_SOUP_FINISHING, "Group 1 soup: dice base must retain a greens branch window before formation")
	pot.complete_beef_soup(config)
	_expect(
		pot.content_data.recipe_id == ExpandedRecipeCatalog.BEEF_SOUP
		and float(pot.content_data.effect_values["damage"]) == config.beef_soup_damage,
		"Group 1 soup: no-greens second stage must form concentrated beef soup"
	)
	pot.free()


func _test_fried_white_rice_ring() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var manager := CombatManager.new()
	scene.add_child(manager)
	var source := _test_player(scene)
	var target := _target(scene, Vector2(78.0, 0.0))
	var dish := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.FRIED_WHITE_RICE, [_ready_rice()], config
	)
	dish.set_quality_with_cap(ItemData.Quality.PERFECT)
	manager.ring_random.seed = 7
	var grains := manager.spawn_fried_white_rice_ring(Vector2.ZERO, dish, source)
	_expect(grains.size() == config.fried_white_rice_grain_count, "Group 1 combat: fried white rice must create exactly 20 independently moving grains")
	for frame in 20:
		await physics_frame
	_expect(target.current_health < target.max_health, "Group 1 combat: a real enemy in the ring path must take actual grain damage")
	_expect(
		target.combat_statuses != null
		and is_equal_approx(target.combat_statuses.get_strongest(CombatStatusController.StatusType.MOVE_SLOW), config.fried_white_rice_perfect_move_slow),
		"Group 1 combat: perfect grains must apply one refreshable 8% movement slow"
	)
	await _dispose(scene)


func _test_clear_beef_combo() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var source := _test_player(scene)
	var target := _target(scene, Vector2(74.0, 0.0))
	var behind := _target(scene, Vector2(-60.0, 0.0))
	var dish := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	)
	var combo := ClearBeefComboAttack.new()
	combo.setup(Vector2.ZERO, Vector2.RIGHT, dish, source, false, config)
	scene.add_child(combo)
	await process_frame
	combo._process(config.clear_beef_combo_duration * 0.55)
	combo._process(config.clear_beef_combo_duration * 0.55)
	_expect(
		is_equal_approx(target.max_health - target.current_health, config.clear_beef_hit_damage * 3.0),
		"Group 1 combat: normal clear beef must resolve all three independently deduplicated hits"
	)
	_expect(behind.current_health == behind.max_health, "Group 1 combat: clear beef must not damage a true rear target")
	var perfect_target := _target(scene, Vector2(72.0, 0.0))
	source.facing_direction = Vector2.RIGHT
	var perfect_combo := ClearBeefComboAttack.new()
	perfect_combo.setup(Vector2.ZERO, Vector2.RIGHT, dish, source, true, config)
	scene.add_child(perfect_combo)
	await process_frame
	perfect_combo._process(config.clear_beef_perfect_duration + 0.01)
	_expect(
		is_equal_approx(perfect_target.max_health - perfect_target.current_health, config.clear_beef_hit_damage * 6.0)
		and perfect_combo.hit_count == config.clear_beef_perfect_hits
		and is_equal_approx(perfect_combo.final_arc_degrees, config.clear_beef_perfect_final_arc),
		"Group 1 combat: the perfect final durability attack must replace the normal combo with six cuts and the wider last arc (damage %.2f, hits %d, arc %.2f)" % [
			perfect_target.max_health - perfect_target.current_health,
			perfect_combo.hit_count,
			perfect_combo.final_arc_degrees,
		]
	)
	await _dispose(scene)


func _test_held_soup_streams() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := _test_player(scene)
	var greens_item := ItemFactory.create_carryable(
		ExpandedRecipeCatalog.create_missing_group_1_dish(
			ExpandedRecipeCatalog.GREENS_SOUP, [_leaf_stack()], config, 5
		)
	)
	greens_item.data.set_quality_with_cap(ItemData.Quality.PERFECT)
	scene.add_child(greens_item)
	var near := _target(scene, Vector2(90.0, 0.0))
	var stream := HeldSoupStream.new()
	stream.setup(player, greens_item, HeldSoupStream.Mode.GREENS)
	scene.add_child(stream)
	stream.tick_left = 999.0
	stream.update_direction(Vector2.RIGHT)
	await process_frame
	stream._resolve_tick()
	_expect(
		is_equal_approx(near.max_health - near.current_health, config.greens_soup_damage)
		and not near.knockback_velocity.is_zero_approx(),
		"Group 1 combat: perfect greens soup must push, while its three streams deduplicate the same enemy in one tick"
	)
	stream.stop_stream()

	near.reset_target()
	near.position = Vector2(90.0, 0.0)
	near.knockback_velocity = Vector2.ZERO
	var far := _target(scene, Vector2(150.0, 0.0))
	var beef_data := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.BEEF_SOUP,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)],
		config
	)
	beef_data.set_quality_with_cap(ItemData.Quality.PERFECT)
	var beef_item := ItemFactory.create_carryable(beef_data)
	scene.add_child(beef_item)
	var beef_stream := HeldSoupStream.new()
	beef_stream.setup(player, beef_item, HeldSoupStream.Mode.BEEF)
	scene.add_child(beef_stream)
	beef_stream.tick_left = 999.0
	beef_stream.update_direction(Vector2.RIGHT)
	for hit in 7:
		beef_stream._resolve_tick()
	var expected_damage := config.beef_soup_damage * (1.06 + 1.12 + 1.18 + 1.24 + 1.30 + 1.30 + 1.30)
	_expect(
		is_equal_approx(near.max_health - near.current_health, expected_damage)
		and far.current_health == far.max_health
		and near.knockback_velocity.is_zero_approx(),
		"Group 1 combat: beef soup must hit only the first target, never pierce or knock back, and cap focus at +30%% (near %.2f expected %.2f far %.2f)" % [near.max_health - near.current_health, expected_damage, far.max_health - far.current_health]
	)
	_expect(beef_stream.focus_stacks == 5 and beef_stream.visual_level == 5, "Group 1 combat: focus visual level must match the five-stack gameplay cap")
	beef_stream.stop_stream()
	await _dispose(scene)


func _test_lobby_catalog_and_perfect_samples() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	await process_frame
	cabinet.configure_lobby_unlimited_catalog()
	_expect(
		cabinet.storage.width == 20
		and cabinet.storage.height == 40
		and cabinet.storage.get_items().size() == ItemData.ItemType.size(),
		"Group 1 cabinet: 20x40 test catalog must contain one instance of every current ItemType"
	)
	for plated_type in [
		ItemData.ItemType.PLATED_FRIED_WHITE_RICE,
		ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF,
		ItemData.ItemType.PLATED_GREENS_SOUP,
		ItemData.ItemType.PLATED_BEEF_SOUP,
		ItemData.ItemType.PLATED_STIR_FRY_BEEF,
	]:
		var sample := cabinet._find_item(plated_type)
		_expect(
			sample != null
			and sample.data.quality == ItemData.Quality.PERFECT
			and sample.data.current_durability == sample.data.max_durability,
			"Group 1 cabinet: legally perfect plated sample %d must be a real fully initialized PERFECT instance" % plated_type
		)
	for item in cabinet.storage.get_items():
		var enum_name := String(ItemData.ItemType.keys()[item.data.item_type])
		var should_be_perfect := (
			enum_name.begins_with("PLATED_")
			and item.data.is_combat_dish
			and not item.data.is_weird_dish()
			and item.data.quality_cap == ItemData.Quality.PERFECT
			and item.data.failure_tags.is_empty()
		)
		if should_be_perfect:
			_expect(
				item.data.quality == ItemData.Quality.PERFECT
				and item.data.current_durability == item.data.max_durability,
				"Group 1 cabinet: every legally perfect plated catalog item must be a fully initialized perfect sample (%s)" % enum_name
			)
	var weird := cabinet._find_item(ItemData.ItemType.PLATED_MUSTARD_GREENS)
	var capped := cabinet._find_item(ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE)
	_expect(
		weird != null and weird.data.quality != ItemData.Quality.PERFECT
		and capped != null and capped.data.quality != ItemData.Quality.PERFECT,
		"Group 1 cabinet: weird and formally capped dishes must not bypass their quality limits"
	)
	cabinet.queue_free()
	await process_frame


func _test_freshness_and_waste_integration() -> void:
	for item_type in [
		ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE,
		ItemData.ItemType.PLATED_FRIED_WHITE_RICE,
		ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF,
		ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF,
		ItemData.ItemType.UNPLATED_GREENS_SOUP,
		ItemData.ItemType.PLATED_GREENS_SOUP,
		ItemData.ItemType.UNPLATED_BEEF_SOUP,
		ItemData.ItemType.PLATED_BEEF_SOUP,
	]:
		var dish := ItemCatalog.create(item_type)
		_expect(dish.is_perishable() and FreshnessCatalog.get_waste_units(dish) >= 1, "Group 1 freshness: new dish type %d must use completed-dish spoilage and waste rules" % item_type)
	var near := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	)
	near.set_spoilage_ratio(FreshnessCatalog.STILL_FRESH_LIMIT)
	var plated := ItemCatalog.transform(near, ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF)
	plated.recalculate_quality()
	_expect(
		plated.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY)
		and plated.quality == ItemData.Quality.FLAWED
		and not plated.has_perfect_finisher,
		"Group 1 freshness: near-expiry failure must survive plating and remove perfect effects"
	)


func _ready_rice() -> ItemData:
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(rice)
	return rice


func _leaf_stack() -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	leaves.leaf_count = 5
	return leaves


func _single_oil_source() -> ItemData:
	var oil := ItemCatalog.create(ItemData.ItemType.COOKING_OIL)
	oil.remaining_portions = 1
	oil.max_remaining_portions = 1
	return oil


func _single_salt_source() -> ItemData:
	var salt := ItemCatalog.create(ItemData.ItemType.SALT)
	salt.remaining_portions = 1
	salt.max_remaining_portions = 1
	return salt


func _target(parent: Node, position: Vector2) -> DebugCombatTarget:
	var target := DebugCombatTarget.new()
	target.combat_faction = CombatRules.Faction.ENEMY
	target.position = position
	parent.add_child(target)
	return target


func _test_player(parent: Node) -> PrototypePlayer:
	var player := PrototypePlayer.new()
	var art := AnimatedSprite2D.new()
	art.name = "PlayerArt"
	player.add_child(art)
	var held_anchor := Node2D.new()
	held_anchor.name = "HeldAnchor"
	player.add_child(held_anchor)
	var inventory_storage := Node2D.new()
	inventory_storage.name = "InventoryStorage"
	player.add_child(inventory_storage)
	parent.add_child(player)
	return player


func _dispose(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
