extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_recipe_data()
	await _test_real_component_and_plating_qte()
	await _test_turret_profiles()
	await _test_lobby_catalog_samples()
	if failures.is_empty():
		print("PROTOTYPE_MISSING_RECIPES_GROUP_2_TEST: PASS (4/4 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MISSING_RECIPES_GROUP_2_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_recipe_data() -> void:
	var greens := ExpandedRecipeCatalog.create_group_2_rice_bowl(
		ExpandedRecipeCatalog.GREENS_RICE_BOWL,
		[_ready_rice(), ExpandedRecipeCatalog.create_boiled_greens(5, [_leaves(5)], config)],
		config
	)
	_expect(
		greens.item_type == ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL
		and greens.current_durability == config.greens_rice_bowl_base_durability + 5
		and int(greens.effect_values["greens_pierce"]) == 3,
		"Group 2 data: greens rice bowl must retain leaf-count durability and three-target piercing"
	)
	var beef_component := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	)
	var beef := ExpandedRecipeCatalog.create_group_2_rice_bowl(
		ExpandedRecipeCatalog.BEEF_RICE_BOWL,
		[_ready_rice(), beef_component],
		config
	)
	_expect(
		beef.item_type == ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL
		and beef.current_durability == config.beef_rice_bowl_base_durability + 5
		and float(beef.effect_values["beef_damage"]) == 42.0,
		"Group 2 data: beef rice bowl must retain standard beef portions and centralized 42 damage"
	)


func _test_real_component_and_plating_qte() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	_give(player, _ready_rice())
	_give(player, ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	))
	_expect(plating.request_start(), "Group 2 QTE: full unused rice and clear beef must enter the real combination QTE")
	plating.complete_for_test(true)
	var unplated := _find_quick_type(player, ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL)
	_expect(
		unplated != null and unplated.data.quality == ItemData.Quality.NORMAL,
		"Group 2 QTE: component QTE must form an unplated normal dish instead of bypassing plating"
	)
	_give(player, ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	_expect(plating.request_start(), "Group 2 QTE: the newly formed unplated rice bowl must enter the shared plating QTE")
	plating.complete_for_test(true)
	var plated := _find_quick_type(player, ItemData.ItemType.PLATED_BEEF_RICE_BOWL)
	_expect(
		plated != null
		and plated.data.quality == ItemData.Quality.PERFECT
		and plated.data.has_perfect_finisher,
		"Group 2 QTE: clean perfect plating must create a real perfect turret instance"
	)
	await _dispose_scene(scene)


func _test_turret_profiles() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var near_enemy := _target(scene, Vector2(90.0, 0.0), 100.0)
	var far_healthy := _target(scene, Vector2(180.0, 0.0), 240.0)
	var beef_data := ExpandedRecipeCatalog.create_group_2_rice_bowl(
		ExpandedRecipeCatalog.BEEF_RICE_BOWL,
		[_ready_rice(), _standard_beef_component()],
		config
	)
	beef_data.current_durability = 2
	var beef_turret := RiceBowlTurret.new()
	beef_turret.setup(beef_data, config, 12)
	scene.add_child(beef_turret)
	beef_turret.set_process(false)
	beef_turret._process(0.0)
	var normal_projectile := _latest_projectile(scene)
	_expect(
		normal_projectile != null and normal_projectile.target == near_enemy,
		"Group 2 turret: ordinary beef rice bowl must target the nearest enemy"
	)
	if normal_projectile != null:
		normal_projectile.queue_free()
	beef_data.quality = ItemData.Quality.PERFECT
	beef_data.has_perfect_finisher = true
	beef_data.current_durability = 1
	beef_turret.cooldown_left = 0.0
	beef_turret._process(0.0)
	var final_projectile := _latest_projectile(scene)
	_expect(
		final_projectile != null
		and final_projectile.target == far_healthy
		and final_projectile.damage_override == config.beef_rice_bowl_finisher_damage,
		"Group 2 turret: perfect final beef shot must choose the highest-health enemy and snapshot 90 damage"
	)
	if final_projectile != null:
		final_projectile.queue_free()

	var greens_data := ExpandedRecipeCatalog.create_group_2_rice_bowl(
		ExpandedRecipeCatalog.GREENS_RICE_BOWL,
		[_ready_rice(), ExpandedRecipeCatalog.create_boiled_greens(5, [_leaves(5)], config)],
		config
	)
	greens_data.quality = ItemData.Quality.PERFECT
	greens_data.has_perfect_finisher = true
	greens_data.current_durability = 1
	var greens_turret := RiceBowlTurret.new()
	greens_turret.setup(greens_data, config, 33)
	scene.add_child(greens_turret)
	greens_turret.set_process(false)
	greens_turret._process(0.0)
	_expect(
		greens_turret.projectiles_fired == config.greens_rice_bowl_finisher_count
		and greens_turret.shot_history.all(func(mode): return mode == TurretDishProjectile.Mode.GREENS_PIERCE),
		"Group 2 turret: perfect final greens shot must emit the configured five-leaf fan"
	)
	await _dispose_scene(scene)


func _test_lobby_catalog_samples() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	cabinet.configure_lobby_unlimited_catalog()
	for item_type in [
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL,
		ItemData.ItemType.PLATED_GREENS_RICE_BOWL,
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL,
		ItemData.ItemType.PLATED_BEEF_RICE_BOWL,
	]:
		_expect(cabinet.get_stock(item_type) == 1, "Group 2 cabinet: every new state must have one auto-replenished catalog sample")
	for item_type in [ItemData.ItemType.PLATED_GREENS_RICE_BOWL, ItemData.ItemType.PLATED_BEEF_RICE_BOWL]:
		var sample := cabinet._find_item(item_type)
		_expect(
			sample != null
			and sample.data.quality == ItemData.Quality.PERFECT
			and sample.data.has_perfect_finisher,
			"Group 2 cabinet: legally perfect plated rice bowls must be real perfect instances"
		)
	cabinet.queue_free()
	await process_frame


func _standard_beef_component() -> ItemData:
	return ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	)


func _ready_rice() -> ItemData:
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	config.apply_white_rice_stats(rice)
	return rice


func _leaves(count: int) -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = count
	leaves.leaf_count = count
	return leaves


func _give(player: PrototypePlayer, data: ItemData) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	current_scene.add_child(item)
	item.global_position = player.global_position
	if not player.pickup_item(item):
		failures.append("Group 2 setup could not route %s into inventory" % data.display_name)
	return item


func _find_quick_type(player: PrototypePlayer, item_type: int) -> CarryableItem:
	var slot := player.inventory.find_item_slot(item_type)
	return player.inventory.get_item(slot) if slot >= 0 else null


func _target(parent: Node, position: Vector2, health: float) -> DebugCombatTarget:
	var target := DebugCombatTarget.new()
	target.combat_faction = CombatRules.Faction.ENEMY
	target.max_health = health
	target.current_health = health
	target.global_position = position
	parent.add_child(target)
	return target


func _latest_projectile(scene: Node) -> TurretDishProjectile:
	var projectiles := scene.get_children().filter(func(child): return child is TurretDishProjectile)
	return projectiles.back() as TurretDishProjectile if not projectiles.is_empty() else null


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
