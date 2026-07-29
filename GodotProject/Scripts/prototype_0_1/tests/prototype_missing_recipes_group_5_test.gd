extends SceneTree

var failures: PackedStringArray = []
var config := PrototypeCombatConfig.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_real_component_combination_and_plating()
	await _test_main_bomb_damage_and_fragments()
	await _test_perfect_snapshot_and_fragment_no_chain()
	await _test_lobby_catalog_and_reset_cleanup()
	if failures.is_empty():
		print("PROTOTYPE_MISSING_RECIPES_GROUP_5_TEST: PASS (4/4 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MISSING_RECIPES_GROUP_5_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_real_component_combination_and_plating() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	var crispy := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE)
	config.apply_crispy_rice_stats(crispy)
	var clear_beef := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	)
	_put_quick_item(scene, player, crispy, 0)
	_put_quick_item(scene, player, clear_beef, 1)
	_expect(
		plating.request_start()
		and plating.locked_combination_recipe == ExpandedRecipeCatalog.CRISPY_RICE_BEEF,
		"Group 5 recipe: the shared real QTE must prioritize full unused crispy rice plus clear beef"
	)
	_expect(plating.complete_for_test(false), "Group 5 recipe: component combination QTE must complete atomically")
	var unplated := player.inventory.get_item(0)
	_expect(
		unplated != null
		and unplated.data.item_type == ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF
		and unplated.data.recipe_id == ExpandedRecipeCatalog.CRISPY_RICE_BEEF
		and player.inventory.get_item(1) == null
		and unplated.data.current_durability == 1,
		"Group 5 recipe: combination must consume exactly two components and create one unplated bomb dish"
	)
	_put_quick_item(scene, player, ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE), 1)
	_expect(plating.request_start(), "Group 5 plating: unplated crispy beef must enter the shared movable plating QTE")
	_expect(plating.complete_for_test(true), "Group 5 plating: perfect QTE must finish")
	var plated := player.inventory.get_item(0)
	_expect(
		plated != null
		and plated.data.item_type == ItemData.ItemType.PLATED_CRISPY_RICE_BEEF
		and plated.data.quality == ItemData.Quality.PERFECT
		and plated.data.has_perfect_finisher
		and plated.data.carried_plate_state == ItemData.PlateState.CLEAN,
		"Group 5 plating: a legal perfect result must carry real perfect state, finisher and plate ownership"
	)
	var trap_controller := player.get_node("TrapController") as TrapController
	_expect(
		trap_controller.deploy_selected_crispy_beef_bomb(),
		"Group 5 deployment: the selected plated dish must use the existing TrapController input route"
	)
	var dirty_plate_found := false
	for node in scene.find_children("*", "CarryableItem", true, false):
		var carryable := node as CarryableItem
		if carryable != null and carryable.data != null and carryable.data.item_type == ItemData.ItemType.DIRTY_PLATE:
			dirty_plate_found = true
			break
	_expect(
		player.inventory.get_item(0) == null
		and get_nodes_in_group("crispy_beef_bomb").any(
			func(node: Node) -> bool: return is_instance_valid(node) and node is CrispyBeefBomb and node.kind == CrispyBeefBomb.BombKind.MAIN
		)
		and dirty_plate_found,
		"Group 5 deployment: use must atomically consume the dish, spawn one main bomb and leave the plated dish's dirty plate"
	)
	await _dispose_scene(scene)


func _test_main_bomb_damage_and_fragments() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var enemy := _target(scene, CombatRules.Faction.ENEMY, Vector2(20.0, 0.0), 400.0)
	var friendly := _target(scene, CombatRules.Faction.FRIENDLY, Vector2(-20.0, 0.0), 400.0)
	var data := _crispy_beef_data(false)
	var bomb := CrispyBeefBomb.new()
	bomb.setup_main(data, null, config, false, 1234)
	scene.add_child(bomb)
	bomb.global_position = Vector2.ZERO
	bomb._process(config.crispy_beef_main_arm_time + 0.01)
	_expect(
		is_equal_approx(enemy.current_health, 280.0)
		and is_equal_approx(friendly.current_health, 352.0),
		"Group 5 main bomb: a real armed trigger must deal 120 enemy damage and exactly 40% friendly damage"
	)
	_expect(
		get_nodes_in_group("crispy_beef_bomb").filter(
			func(node: Node) -> bool: return is_instance_valid(node) and node is CrispyBeefBomb and node.kind == CrispyBeefBomb.BombKind.FRAGMENT
		).size() == config.crispy_beef_fragment_count,
		"Group 5 main bomb: normal explosion must scatter exactly eight independently armed fragments"
	)
	await _dispose_scene(scene)


func _test_perfect_snapshot_and_fragment_no_chain() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var far_enemy := _target(scene, CombatRules.Faction.ENEMY, Vector2(200.0, 0.0), 400.0)
	var perfect_data := _crispy_beef_data(true)
	var main := CrispyBeefBomb.new()
	main.setup_main(perfect_data, null, config, true, 4321)
	scene.add_child(main)
	main.global_position = Vector2.ZERO
	main.force_explode_for_test()
	_expect(
		is_equal_approx(far_enemy.current_health, 250.0),
		"Group 5 perfect bomb: the release-time snapshot must use radius 220 and 150 damage"
	)
	_expect(
		get_nodes_in_group("crispy_beef_bomb").filter(
			func(node: Node) -> bool: return is_instance_valid(node) and node is CrispyBeefBomb and node.kind == CrispyBeefBomb.BombKind.FRAGMENT
		).size() == config.crispy_beef_perfect_fragment_count,
		"Group 5 perfect bomb: perfect main explosion must scatter exactly twelve fragments"
	)
	for node in get_nodes_in_group("crispy_beef_bomb"):
		if is_instance_valid(node):
			node.queue_free()
	await process_frame
	var near_enemy := _target(scene, CombatRules.Faction.ENEMY, Vector2(10.0, 0.0), 200.0)
	var near_friend := _target(scene, CombatRules.Faction.FRIENDLY, Vector2(-10.0, 0.0), 200.0)
	var fragment_a := CrispyBeefBomb.new()
	var fragment_b := CrispyBeefBomb.new()
	fragment_a.setup_fragment(perfect_data, null, config, 11)
	fragment_b.setup_fragment(perfect_data, null, config, 22)
	scene.add_child(fragment_a)
	scene.add_child(fragment_b)
	fragment_a.global_position = Vector2.ZERO
	fragment_b.global_position = Vector2.ZERO
	fragment_a.force_explode_for_test()
	_expect(
		is_equal_approx(near_enemy.current_health, 165.0)
		and is_equal_approx(near_friend.current_health, 182.5),
		"Group 5 fragment: each fragment must deal 35 enemy damage and exactly 50% friendly damage"
	)
	_expect(
		not fragment_b.triggered and is_instance_valid(fragment_b),
		"Group 5 anti-chain: bombs are not damageable targets and one explosion must not trigger another bomb"
	)
	await _dispose_scene(scene)


func _test_lobby_catalog_and_reset_cleanup() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	cabinet.configure_lobby_unlimited_catalog()
	for item_type in [
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF,
		ItemData.ItemType.PLATED_CRISPY_RICE_BEEF,
	]:
		_expect(cabinet.get_stock(item_type) == 1, "Group 5 cabinet: unplated and plated crispy beef must be directly available")
	var sample := cabinet._find_item(ItemData.ItemType.PLATED_CRISPY_RICE_BEEF)
	_expect(
		sample != null
		and sample.data.quality == ItemData.Quality.PERFECT
		and sample.data.current_durability == 1,
		"Group 5 cabinet: the legal plated sample must be a real perfect one-use bomb"
	)
	var cleanup_scene := Node2D.new()
	root.add_child(cleanup_scene)
	current_scene = cleanup_scene
	var bomb := CrispyBeefBomb.new()
	bomb.setup_main(_crispy_beef_data(false), null, config, false, 77)
	cleanup_scene.add_child(bomb)
	var manager := CombatManager.new()
	manager.config = config
	cleanup_scene.add_child(manager)
	manager.clear_active_attacks()
	await process_frame
	_expect(
		not is_instance_valid(bomb),
		"Group 5 cleanup: formal run reset must remove armed bombs through the existing run_deployable lifecycle"
	)
	cabinet.queue_free()
	await _dispose_scene(cleanup_scene)


func _crispy_beef_data(perfect: bool) -> ItemData:
	var crispy := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE)
	config.apply_crispy_rice_stats(crispy)
	var clear_beef := ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
		[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
		config
	)
	var data := ExpandedRecipeCatalog.create_group_5_crispy_beef([crispy, clear_beef], config)
	if perfect:
		data = ItemCatalog.transform(data, ItemData.ItemType.PLATED_CRISPY_RICE_BEEF)
		data.set_quality_with_cap(ItemData.Quality.PERFECT)
		ExpandedRecipeCatalog.refresh_after_plating(data, config)
	return data


func _target(parent: Node, faction: int, position: Vector2, health: float) -> DebugCombatTarget:
	var target := DebugCombatTarget.new()
	target.combat_faction = faction
	target.max_health = health
	parent.add_child(target)
	target.global_position = position
	return target


func _put_quick_item(scene: Node, player: PrototypePlayer, data: ItemData, slot_index: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_inventory_stored(player)
	_expect(player.inventory.put_item(slot_index, item), "Group 5 setup: requested quick slot must be empty")
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
