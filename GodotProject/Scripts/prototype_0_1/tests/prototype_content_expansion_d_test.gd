extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_combination_recipe_values_and_caps()
	_test_real_wok_combination_routes()
	await _test_beef_greens_real_fan_damage()
	await _test_three_fried_rice_damage_profiles()
	if failures.is_empty():
		print("PROTOTYPE_CONTENT_EXPANSION_D_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_CONTENT_EXPANSION_D_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_combination_recipe_values_and_caps() -> void:
	var marinated := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)
	var raw := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_DICE)
	var leaves := _leaf_stack()
	var rice := _ready_rice()
	var beef := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.BEEF_FRIED_RICE, [marinated, rice], config
	)
	var plain := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.BEEF_FRIED_RICE, [raw, rice], config
	)
	plain.set_quality_with_cap(ItemData.Quality.PERFECT)
	var mixed := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.MIXED_FRIED_RICE, [marinated, leaves, rice], config
	)
	_expect(
		beef.is_marinated
		and beef.current_durability == config.beef_fried_rice_durability
		and plain.quality == ItemData.Quality.NORMAL
		and plain.actual_damage < beef.actual_damage,
		"Milestone D recipes: un-marinated beef fried rice must remain valid but weaker and capped at normal"
	)
	_expect(
		mixed.leaf_count == 5
		and mixed.beef_portion_count == 5
		and mixed.current_durability == config.mixed_fried_rice_durability,
		"Milestone D recipes: mixed fried rice must consume one full greens and beef group without multiplication"
	)


func _test_real_wok_combination_routes() -> void:
	var wok := WokItem.new()
	wok.setup_wok(&"test")
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.complete_stage_one()
	_expect(wok.add_combination_greens(_leaf_stack()), "Milestone D wok: full greens group must join stage-one marinated slices")
	wok.complete_wok_combination(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.BEEF_GREENS, "Milestone D wok: two-stage beef-greens route must complete")
	wok.take_content()
	wok.add_oil()
	wok.insert_dice(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE))
	wok.complete_stage_one()
	wok.add_cooked_rice(_ready_rice())
	wok.complete_wok_combination(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.BEEF_FRIED_RICE, "Milestone D wok: beef dice then cooked rice must form strict-single-target fried rice")
	wok.take_content()
	wok.add_oil()
	wok.insert_dice(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE))
	wok.complete_stage_one()
	wok.add_combination_greens(_leaf_stack())
	wok.add_cooked_rice(_ready_rice())
	wok.complete_wok_combination(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.MIXED_FRIED_RICE, "Milestone D wok: beef, greens and rice must form the mixed route")
	wok.take_content()
	wok.add_oil()
	wok.insert_greens(_leaf_stack())
	wok.complete_greens(config)
	wok.add_cooked_rice(_ready_rice())
	wok.complete_wok_combination(config)
	_expect(wok.content_data.recipe_id == ExpandedRecipeCatalog.GREENS_FRIED_RICE, "Milestone D wok: recommended greens-first order must form greens fried rice")
	wok.free()


func _test_beef_greens_real_fan_damage() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var source := Node2D.new()
	scene.add_child(source)
	var center := _target(scene, Vector2(90.0, 0.0))
	var side := _target(scene, Vector2(80.0, 60.0))
	var behind := _target(scene, Vector2(-60.0, 0.0))
	await process_frame
	var dish := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.BEEF_GREENS,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), _leaf_stack()],
		config
	)
	var swing := BeefGreensSwing.new()
	swing.setup(Vector2.ZERO, Vector2.RIGHT, dish, source, false)
	scene.add_child(swing)
	await process_frame
	_expect(center.current_health < center.max_health, "Milestone D beef-greens: central target must take real health damage")
	_expect(
		(center.max_health - center.current_health) > (side.max_health - side.current_health),
		"Milestone D beef-greens: central beef-and-greens zone must exceed side greens damage"
	)
	_expect(behind.current_health == behind.max_health, "Milestone D beef-greens: a true rear target must not be hit")
	await _dispose(scene)


func _test_three_fried_rice_damage_profiles() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var source := Node2D.new()
	scene.add_child(source)
	var first := _target(scene, Vector2(0.0, 0.0))
	var second := _target(scene, Vector2(55.0, 0.0))
	await process_frame
	var greens := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.GREENS_FRIED_RICE, [_leaf_stack(), _ready_rice()], config
	)
	var greens_projectile := FriedRiceProjectile.new()
	greens_projectile.setup(Vector2(-200.0, 0.0), Vector2.ZERO, greens, source, FriedRiceProjectile.Mode.GREENS_AOE, false, config)
	scene.add_child(greens_projectile)
	greens_projectile._impact(Vector2.ZERO)
	_expect(
		first.current_health < first.max_health and second.current_health < second.max_health,
		"Milestone D greens fried rice: low-damage landing AOE must affect multiple real targets"
	)
	first.reset_target()
	second.reset_target()
	var beef := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.BEEF_FRIED_RICE, [ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), _ready_rice()], config
	)
	var beef_projectile := FriedRiceProjectile.new()
	beef_projectile.setup(Vector2(-200.0, 0.0), Vector2.ZERO, beef, source, FriedRiceProjectile.Mode.BEEF_SINGLE, false, config)
	scene.add_child(beef_projectile)
	beef_projectile._impact(Vector2.ZERO)
	_expect(
		(first.current_health < first.max_health) != (second.current_health < second.max_health),
		"Milestone D beef fried rice: strict single-target landing must damage exactly one target"
	)
	first.reset_target()
	second.reset_target()
	var mixed := ExpandedRecipeCatalog.create_wok_combination(
		ExpandedRecipeCatalog.MIXED_FRIED_RICE,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), _leaf_stack(), _ready_rice()],
		config
	)
	var mixed_projectile := FriedRiceProjectile.new()
	mixed_projectile.setup(Vector2(-200.0, 0.0), Vector2.ZERO, mixed, source, FriedRiceProjectile.Mode.MIXED, false, config)
	scene.add_child(mixed_projectile)
	mixed_projectile._impact(Vector2.ZERO)
	var main_damage := first.max_health - first.current_health
	var outer_damage := second.max_health - second.current_health
	_expect(
		main_damage > outer_damage and is_equal_approx(main_damage, config.mixed_fried_rice_primary_damage),
		"Milestone D mixed fried rice: main target must be resolved once and must not also receive peripheral damage"
	)
	await _dispose(scene)


func _ready_rice() -> ItemData:
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(rice)
	return rice


func _leaf_stack() -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	leaves.leaf_count = 5
	return leaves


func _target(parent: Node, position: Vector2) -> DebugCombatTarget:
	var target := DebugCombatTarget.new()
	target.combat_faction = CombatRules.Faction.ENEMY
	target.global_position = position
	parent.add_child(target)
	return target


func _dispose(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
