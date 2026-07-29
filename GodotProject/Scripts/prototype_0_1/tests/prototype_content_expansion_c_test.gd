extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_recipe_catalog_and_quality_caps()
	_test_wok_greens_routes_and_flash_qte()
	_test_soup_greens_and_porridge_routes()
	await _test_real_leaf_projectiles_and_statuses()
	await _test_porridge_completion_effects()
	if failures.is_empty():
		print("PROTOTYPE_CONTENT_EXPANSION_C_TEST: PASS (5/5 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_CONTENT_EXPANSION_C_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_recipe_catalog_and_quality_caps() -> void:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	var boiled := ExpandedRecipeCatalog.create_boiled_greens(5, [leaves], config)
	var spicy := ExpandedRecipeCatalog.create_stir_fry_greens(
		5, ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS, [leaves], config
	)
	var plain_beef := ExpandedRecipeCatalog.create_porridge(
		ExpandedRecipeCatalog.PLAIN_BEEF_PORRIDGE,
		0,
		[ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE), ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES)],
		config
	)
	plain_beef.set_quality_with_cap(ItemData.Quality.PERFECT)
	_expect(
		boiled.current_durability == 5
		and spicy.current_durability == config.stir_fry_greens_durability
		and is_equal_approx(float(spicy.effect_values["vulnerability"]), config.spicy_vulnerability),
		"Milestone C catalog: leaf counts, durability and spicy vulnerability must come from centralized config"
	)
	_expect(
		plain_beef.quality == ItemData.Quality.NORMAL,
		"Milestone C quality: un-marinated beef porridge must remain a formal recipe capped at normal"
	)


func _test_wok_greens_routes_and_flash_qte() -> void:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	var wok := WokItem.new()
	wok.setup_wok(&"test")
	_expect(wok.add_oil() and wok.insert_greens(leaves), "Milestone C wok: oil plus leaves must enter the active stir route")
	wok.add_chili()
	wok.complete_greens(config)
	_expect(
		wok.content_data.recipe_id == ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS,
		"Milestone C wok: chili added after greens must produce spicy stir-fried greens"
	)
	wok.take_content()
	wok.add_oil()
	_expect(wok.preheat_chili(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS)), "Milestone C wok: chili must be accepted into hot oil before greens")
	wok.insert_greens(leaves)
	var station := WokStation.new()
	station.cookware_item = wok
	station.config = config
	station.flash_qte_active = true
	_expect(
		not station.confirm_flash_stir_qte(false)
		and wok.content_data.item_type == ItemData.ItemType.GREENS_LEAF
		and wok.pending_recipe == ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
		"Milestone C flash stir: failed QTE must preserve ingredients and reset only the current stir segment"
	)
	station.flash_qte_active = true
	_expect(
		station.confirm_flash_stir_qte(true)
		and wok.content_data.recipe_id == ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
		"Milestone C flash stir: successful retry must finish the flash-stir recipe"
	)
	station.free()
	wok.free()


func _test_soup_greens_and_porridge_routes() -> void:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 3
	var pot := SoupPotItem.new()
	pot.setup_soup_pot(&"test")
	pot.fill_water()
	_expect(
		pot.add_salt(ItemCatalog.create(ItemData.ItemType.SALT))
		and pot.insert_greens(leaves),
		"Milestone C soup: one water plus salt plus leaves must be accepted atomically"
	)
	pot.complete_expanded_recipe(config)
	_expect(
		pot.content_data.recipe_id == ExpandedRecipeCatalog.BOILED_GREENS
		and pot.content_data.leaf_count == 3,
		"Milestone C soup: boiled greens must preserve actual leaf count"
	)
	pot.take_content()
	pot.fill_water()
	pot.fill_water()
	pot.insert_rice(ItemCatalog.create(ItemData.ItemType.RAW_RICE))
	pot.complete_rice(config)
	var marinated := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)
	_expect(pot.insert_porridge_beef(marinated), "Milestone C porridge: completed white porridge must accept a whole marinated slice group")
	pot.complete_expanded_recipe(config)
	_expect(
		pot.content_data.recipe_id == ExpandedRecipeCatalog.BEEF_PORRIDGE
		and is_equal_approx(pot.content_data.healing_per_use, config.beef_porridge_heal),
		"Milestone C porridge: marinated slices must produce the buff-capable beef porridge"
	)
	pot.free()


func _test_real_leaf_projectiles_and_statuses() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var source := Node2D.new()
	scene.add_child(source)
	source.global_position = Vector2.ZERO
	var target := DebugCombatTarget.new()
	target.combat_faction = CombatRules.Faction.ENEMY
	target.global_position = Vector2(90.0, 0.0)
	scene.add_child(target)
	await process_frame
	var spicy := ExpandedRecipeCatalog.create_stir_fry_greens(
		5, ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS, [], config
	)
	var projectile := GreensLeafProjectile.new()
	scene.add_child(projectile)
	projectile.setup(Vector2.ZERO, Vector2.RIGHT, spicy, source, GreensLeafProjectile.Mode.SPICY_BOOMERANG)
	var health_before := target.current_health
	for frame in 20:
		await physics_frame
		if target.current_health < health_before:
			break
	_expect(target.current_health < health_before, "Milestone C projectile: a real target in front must lose actual health")
	_expect(
		target.combat_statuses.has_status(CombatStatusController.StatusType.VULNERABILITY),
		"Milestone C spicy leaf: vulnerability must be applied after the first hit"
	)
	target.reset_target()
	var flash := ExpandedRecipeCatalog.create_stir_fry_greens(
		5, ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS, [], config
	)
	var flash_projectile := GreensLeafProjectile.new()
	scene.add_child(flash_projectile)
	flash_projectile.setup(Vector2.ZERO, Vector2.RIGHT, flash, source, GreensLeafProjectile.Mode.FLASH)
	for frame in 20:
		await physics_frame
		if target.combat_statuses.has_status(CombatStatusController.StatusType.AIM_DISRUPTION):
			break
	_expect(
		target.combat_statuses.has_status(CombatStatusController.StatusType.AIM_DISRUPTION),
		"Milestone C flash leaf: the burst must apply the shared aim-disruption status"
	)
	current_scene = null
	scene.queue_free()
	await process_frame
	await process_frame


func _test_porridge_completion_effects() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var beef := ExpandedRecipeCatalog.create_porridge(ExpandedRecipeCatalog.BEEF_PORRIDGE, 0, [], config)
	beef.source_recipe_instance_id = 42
	var carried := ItemFactory.create_carryable(beef)
	player._apply_completed_porridge_effect(carried)
	carried.free()
	_expect(
		player.combat_statuses.get_strongest(CombatStatusController.StatusType.DIRECT_MELEE_BONUS) == config.beef_porridge_direct_bonus
		and player.combat_statuses.get_strongest(CombatStatusController.StatusType.DIRECT_RANGED_BONUS) == config.beef_porridge_direct_bonus,
		"Milestone C beef porridge: completion must buff only the shared direct melee/ranged channels"
	)
	await _dispose_scene(scene)


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
