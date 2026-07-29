extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_group_6_factories_and_wok_priority()
	await _test_group_6_real_combat_and_auto_soups()
	await _test_group_7_pan_routes_and_failures()
	await _test_group_7_real_entities()
	await _test_lobby_catalog_and_perfect_samples()
	if failures.is_empty():
		print("PROTOTYPE_MISSING_RECIPES_GROUPS_6_7_TEST: PASS (5/5 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MISSING_RECIPES_GROUPS_6_7_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_group_6_factories_and_wok_priority() -> void:
	var chili := ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS)
	var rice := _ready_rice()
	var spicy_rice := ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.SPICY_FRIED_RICE, [rice, chili], config
	)
	_expect(
		spicy_rice.item_type == ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE
		and spicy_rice.max_durability == 16
		and int(spicy_rice.effect_values["grain_count"]) == 18,
		"Group 6 data: spicy fried rice must expose 18 grains and durability 16"
	)
	var raw_dice := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_DICE)
	var raw_spicy_beef := ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE, [rice, raw_dice, chili], config
	)
	_expect(
		raw_spicy_beef.has_failure_tag(ItemData.FailureTag.UNMARINATED)
		and raw_spicy_beef.quality_cap == ItemData.Quality.NORMAL
		and is_equal_approx(raw_spicy_beef.base_damage, 32.0),
		"Group 6 quality: un-marinated spicy beef routes must retain the failure tag, normal cap and reduced values"
	)
	var wok := WokItem.new()
	wok.setup_wok(&"group_6_test")
	wok.add_oil()
	_expect(wok.insert_cooked_rice_base(rice), "Group 6 recipe: unused white rice must enter the wok")
	_expect(wok.add_chili(), "Group 6 recipe: chili must be accepted before stir completion")
	var leaves := _leaves(5)
	var beef := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)
	_expect(wok.add_combination_greens(leaves), "Group 6 priority: greens may be staged before beef")
	_expect(wok.insert_dice(beef), "Group 6 priority: beef may upgrade the staged spicy rice")
	_expect(
		wok.pending_recipe == ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
		"Group 6 priority: complete spicy mixed fried rice must outrank base spicy fried rice"
	)
	wok.complete_groups_6_7_wok(config)
	_expect(
		wok.content_data.recipe_id == ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
		"Group 6 cooking: active completion must create the specific mixed spicy recipe"
	)


func _test_group_6_real_combat_and_auto_soups() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var manager := CombatManager.new()
	scene.add_child(manager)
	var player := Node2D.new()
	scene.add_child(player)
	player.global_position = Vector2.ZERO
	var spicy_rice := ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.SPICY_FRIED_RICE,
		[_ready_rice(), ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS)],
		config
	)
	spicy_rice = ItemCatalog.transform(spicy_rice, ItemData.ItemType.PLATED_SPICY_FRIED_RICE)
	spicy_rice.set_quality_with_cap(ItemData.Quality.PERFECT)
	ExpandedRecipeCatalog.refresh_after_plating(spicy_rice, config)
	manager.spawn_spicy_fried_rice_ring(Vector2.ZERO, spicy_rice, player, true)
	_expect(
		manager.spicy_grains_spawned == 18,
		"Group 6 combat: perfect final spicy fried rice must start with exactly 18 real grain projectiles"
	)
	await create_timer(config.spicy_fried_rice_second_ring_delay + 0.03).timeout
	_expect(
		manager.spicy_grains_spawned == 36,
		"Group 6 combat: perfect final must add a second delayed 18-grain ring"
	)
	var soup_data := ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS)],
		config
	)
	var soup_item := ItemFactory.create_carryable(soup_data)
	scene.add_child(soup_item)
	var stream := BeefGreensSoupStream.new()
	stream.setup(player, soup_item, config, 0, Callable())
	player.add_child(stream)
	var before := soup_data.current_durability
	stream._process(1.0)
	_expect(
		soup_data.current_durability == before,
		"Group 6 auto soup: without a valid target no durability may be consumed"
	)
	var target := _target(scene, Vector2(100.0, 0.0), 100.0)
	stream._process(0.26)
	stream._process(0.26)
	_expect(
		target.current_health < 100.0
		and target.combat_statuses.get_strongest(CombatStatusController.StatusType.VULNERABILITY) <= 0.1001,
		"Group 6 auto soup: a real target must take damage while shared vulnerability remains capped at five stacks"
	)
	await _dispose_scene(scene)


func _test_group_7_pan_routes_and_failures() -> void:
	var pan := PanItem.new()
	pan.setup_pan(&"group_7_test")
	pan.add_oil()
	_expect(pan.insert_rice_cake_base(_ready_rice()), "Group 7 pan: complete unused white rice must enter an oiled pan")
	_expect(pan.add_greens_crumbs(_crumbs(3)), "Group 7 pan: one to five greens crumbs must upgrade the route")
	_expect(pan.pending_recipe == ExpandedRecipeCatalog.GREENS_RICE_CAKE, "Group 7 branch: rice plus crumbs must become greens rice cake")
	_expect(pan.begin_pressing(), "Group 7 input: rice cake pressing must be an explicit hold stage")
	pan.finish_pressing()
	pan.flip_early()
	_expect(
		pan.content_data.has_failure_tag(ItemData.FailureTag.OUTSIDE_RAW)
		and pan.cook_stage == PanItem.CookStage.SECOND_SIDE,
		"Group 7 failure: early flip must preserve the route and add the outside-cooked/inside-raw failure"
	)
	pan.complete_rice_cake(config)
	_expect(
		pan.content_data.recipe_id == ExpandedRecipeCatalog.GREENS_RICE_CAKE
		and pan.content_data.leaf_count == 3
		and pan.content_data.has_failure_tag(ItemData.FailureTag.OUTSIDE_RAW),
		"Group 7 cooking: completed rice cake must retain ingredients and failure state"
	)
	var mixed_pan := PanItem.new()
	mixed_pan.setup_pan(&"group_7_mixed")
	mixed_pan.add_oil()
	mixed_pan.insert_rice_cake_base(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE))
	mixed_pan.add_greens_crumbs(_crumbs(5))
	mixed_pan.insert_rice_cake_base(_ready_rice())
	_expect(
		mixed_pan.pending_recipe == ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
		"Group 7 branch: pressing before fried-rice completion must irreversibly select the full mixed rice-cake route"
	)


func _test_group_7_real_entities() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var player := Node2D.new()
	scene.add_child(player)
	var target := _target(scene, Vector2(50.0, 0.0), 300.0)
	var beef_cake := ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.BEEF_RICE_CAKE,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), _ready_rice()],
		config
	)
	beef_cake = ItemCatalog.transform(beef_cake, ItemData.ItemType.PLATED_BEEF_RICE_CAKE)
	beef_cake.set_quality_with_cap(ItemData.Quality.PERFECT)
	ExpandedRecipeCatalog.refresh_after_plating(beef_cake, config)
	var bounce := RiceCakeCombatEntity.new()
	bounce.setup(RiceCakeCombatEntity.Mode.BEEF_BOUNCE, player, beef_cake, Vector2.RIGHT)
	scene.add_child(bounce)
	for index in 16:
		if is_instance_valid(bounce):
			bounce._physics_process(0.2)
	_expect(
		target.current_health < 200.0,
		"Group 7 bounce: the real perfect beef cake entity must perform multiple escalating hits and a terminal slam"
	)
	var mixed := ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), _ready_rice(), _crumbs(5)],
		config,
		5
	)
	mixed.add_active_modifier(ItemData.ActiveModifier.SALTED)
	mixed = ExpandedRecipeCatalog.create_groups_6_7_dish(
		ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), _ready_rice(), _crumbs(5), ItemCatalog.create(ItemData.ItemType.SALT)],
		config,
		5
	)
	_expect(
		int(mixed.effect_values["split_hits"]) == 4,
		"Group 7 salt rule: each mixed rice-cake splitter must gain exactly one extra strike"
	)
	await _dispose_scene(scene)


func _test_lobby_catalog_and_perfect_samples() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	cabinet.configure_lobby_unlimited_catalog()
	var new_types: Array[int] = []
	for item_type in range(ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE + 1):
		new_types.append(item_type)
	for item_type in new_types:
		_expect(cabinet.get_stock(item_type) == 1, "Groups 6/7 cabinet: every unplated and plated type must be directly available (%d)" % item_type)
	for item_type in new_types:
		if not String(ItemData.ItemType.keys()[item_type]).begins_with("PLATED_"):
			continue
		var sample := cabinet._find_item(item_type)
		_expect(
			sample != null and sample.data.quality == ItemData.Quality.PERFECT and sample.data.has_perfect_finisher,
			"Groups 6/7 cabinet: legal plated sample must carry real perfect state (%d)" % item_type
		)
	cabinet.queue_free()
	await process_frame


func _ready_rice() -> ItemData:
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(rice)
	return rice


func _leaves(count: int) -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = count
	leaves.leaf_count = count
	return leaves


func _crumbs(count: int) -> ItemData:
	var crumbs := ItemCatalog.create(ItemData.ItemType.GREENS_CRUMBS)
	crumbs.stack_count = count
	crumbs.leaf_count = count
	return crumbs


func _target(parent: Node, position: Vector2, health: float) -> DebugCombatTarget:
	var target := DebugCombatTarget.new()
	target.combat_faction = CombatRules.Faction.ENEMY
	target.max_health = health
	parent.add_child(target)
	target.global_position = position
	return target


func _dispose_scene(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
