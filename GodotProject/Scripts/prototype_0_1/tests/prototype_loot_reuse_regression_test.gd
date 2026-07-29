extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_container_instances_and_formal_stock()
	await _test_real_station_consumes_one_portion()
	await _test_enemy_tables_and_physical_loot()
	await _test_shortage_compensation_and_statistics()
	if failures.is_empty():
		print("PROTOTYPE_LOOT_REUSE_REGRESSION_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_LOOT_REUSE_REGRESSION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_container_instances_and_formal_stock() -> void:
	var oil := ItemCatalog.create(ItemData.ItemType.COOKING_OIL)
	var salt := ItemCatalog.create(ItemData.ItemType.SALT)
	var large_bag := ItemCatalog.create(ItemData.ItemType.RICE_BAG)
	var small_bag := ItemCatalog.create(ItemData.ItemType.SMALL_RICE_BAG)
	_expect(
		oil.remaining_portions == 6
		and oil.max_remaining_portions == 6
		and not oil.is_stackable
		and ItemStorageCatalog.get_default_size(oil.item_type) == Vector2i(1, 2),
		"Container: a full oil bottle must be one non-stackable 1x2 instance with six portions"
	)
	_expect(
		salt.remaining_portions == 10
		and salt.max_remaining_portions == 10
		and not salt.is_stackable
		and ItemStorageCatalog.get_default_size(salt.item_type) == Vector2i.ONE,
		"Container: a full salt bottle must be one non-stackable 1x1 instance with ten portions"
	)
	_expect(
		large_bag.remaining_portions == 20
		and ItemStorageCatalog.get_default_size(large_bag.item_type) == Vector2i(3, 4)
		and small_bag.remaining_portions == 2
		and ItemStorageCatalog.get_default_size(small_bag.item_type) == Vector2i(2, 2)
		and ItemCatalog.get_art_key_for_data(small_bag) == &"rice_bag_small",
		"Rice packages: starting 20-portion 3x4 bag and enemy 2-portion 2x2 bag must remain distinct"
	)
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	_expect(manager.start_service_early(), "Formal stock: starting service must enter the existing formal reset path")
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	_expect(
		cabinet.get_stock(ItemData.ItemType.COOKING_OIL) == 1
		and cabinet.get_resource_portions(ItemData.ItemType.COOKING_OIL) == 6
		and cabinet.get_stock(ItemData.ItemType.SALT) == 1
		and cabinet.get_resource_portions(ItemData.ItemType.SALT) == 10
		and cabinet.get_resource_portions(ItemData.ItemType.RICE_BAG) == 20,
		"Formal stock: reset must create one six-use oil bottle, one ten-use salt bottle and one 20-rice starting bag"
	)
	await _dispose_scene(scene)


func _test_real_station_consumes_one_portion() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	manager.start_service_early()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.inventory.clear_all()
	var stove: WokStation
	for node in get_nodes_in_group("stove_station"):
		if node is WokStation and (node as WokStation).cookware_item is WokItem:
			stove = node as WokStation
			break
	_expect(stove != null, "Portion use: the real scene must expose a wok stove")
	if stove == null:
		await _dispose_scene(scene)
		return
	var oil_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	scene.add_child(oil_item)
	_expect(player.pickup_item(oil_item), "Portion use: full oil bottle must enter the real quick inventory")
	stove._insert_into_wok(player, stove.cookware_item as WokItem, oil_item.data)
	_expect(
		(stove.cookware_item as WokItem).has_oil()
		and is_instance_valid(oil_item)
		and oil_item.data.remaining_portions == 5
		and player.inventory.get_selected_item() == oil_item,
		"Portion use: oiling a clean wok must consume one portion and retain the same bottle instance"
	)
	stove._insert_into_wok(player, stove.cookware_item as WokItem, oil_item.data)
	_expect(oil_item.data.remaining_portions == 5, "Portion use: repeated oil input on the same oiled wok must not consume again")
	var meat := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)
	(stove.cookware_item as WokItem).insert_meat(meat)
	var salt_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.SALT))
	scene.add_child(salt_item)
	_expect(player.pickup_item(salt_item), "Portion use: salt bottle must enter the real quick inventory")
	player.inventory.select(1)
	stove._insert_into_wok(player, stove.cookware_item as WokItem, salt_item.data)
	_expect(
		salt_item.data.remaining_portions == 9
		and (stove.cookware_item as WokItem).content_data.has_active_modifier(ItemData.ActiveModifier.SALTED),
		"Portion use: adding salt must consume exactly one portion and mark this dish once"
	)
	stove._insert_into_wok(player, stove.cookware_item as WokItem, salt_item.data)
	_expect(salt_item.data.remaining_portions == 9, "Portion use: one dish cannot consume salt repeatedly")
	var consumed: Dictionary = (scene.get_node("RunStats") as RunStats).get_snapshot()["consumed_resource_portions"]
	_expect(
		int(consumed.get(&"cooking_oil", 0)) == 1 and int(consumed.get(&"salt", 0)) == 1,
		"Statistics: actual oil and salt cooking uses must be recorded as portions"
	)
	await _dispose_scene(scene)


func _test_enemy_tables_and_physical_loot() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	manager.start_service_early()
	var basic_entries := manager._get_enemy_loot_entries(&"basic")
	var fast_entries := manager._get_enemy_loot_entries(&"fast")
	var ranged_entries := manager._get_enemy_loot_entries(&"ranged")
	_expect(
		manager.config.basic_loot_chance == 0.30
		and manager.config.fast_loot_chance == 0.40
		and manager.config.ranged_loot_chance == 0.50,
		"Loot table: four enemy-type base chances must remain centralized"
	)
	_expect(
		_entry_weight(basic_entries, ItemData.ItemType.COOKING_OIL) == 35.0
		and _entry_weight(basic_entries, ItemData.ItemType.WHOLE_GREENS) == 20.0
		and _entry_weight(fast_entries, ItemData.ItemType.WHOLE_GREENS) == 35.0
		and _entry_weight(ranged_entries, ItemData.ItemType.SMALL_RICE_BAG) == 10.0,
		"Loot table: basic, fast and ranged pools must match the approved resource identities"
	)
	_expect(
		_entry_weight(basic_entries, ItemData.ItemType.MUSTARD) == 0.0
		and _entry_weight(ranged_entries, ItemData.ItemType.COOKING_OIL) == 0.0
		and _entry_weight(ranged_entries, ItemData.ItemType.RICE_BAG) == 0.0,
		"Loot table: forbidden cross-type resources and the 20-rice starting bag must not enter these pools"
	)
	var oil_drop := manager._create_loot_item_data(ItemData.ItemType.COOKING_OIL)
	var salt_drop := manager._create_loot_item_data(ItemData.ItemType.SALT)
	_expect(
		oil_drop.remaining_portions == 2
		and salt_drop.remaining_portions == 3
		and not oil_drop.is_stackable
		and not salt_drop.is_stackable,
		"Loot instances: enemy oil and salt containers must carry two and three portions without bottle stacking"
	)
	var heavy := manager.spawn_heavy_enemy_for_test(Vector2(1100.0, 850.0))
	heavy.set_physics_process(false)
	var heavy_drop := manager.settle_enemy_loot_for_test(heavy)
	_expect(
		heavy_drop != null
		and heavy_drop.data.item_type == ItemData.ItemType.RAW_STEAK
		and ItemStorageCatalog.get_default_size(heavy_drop.data.item_type) == Vector2i(3, 1),
		"Heavy loot: every heavy enemy must generate exactly one horizontal 3x1 raw steak"
	)
	_expect(
		get_nodes_in_group("loot_drop").filter(
			func(node): return node is CarryableItem and node.data.item_type in [ItemData.ItemType.RICE_BAG, ItemData.ItemType.SMALL_RICE_BAG]
		).is_empty(),
		"Heavy loot: the removed temporary bonus-rice-bag rule must not survive"
	)
	manager._on_enemy_reflavored(heavy)
	var enemy_stats := (scene.get_node("RunStats") as RunStats).get_snapshot()
	_expect(
		int(enemy_stats["enemy_spawned_by_type"].get(&"heavy", 0)) == 1
		and int(enemy_stats["enemy_spawned_by_rank"].get(&"ordinary", 0)) == 1
		and int(enemy_stats["enemy_reflavored_by_type"].get(&"heavy", 0)) == 1
		and int(enemy_stats["enemy_reflavored_by_rank"].get(&"ordinary", 0)) == 1,
		"Statistics: enemy combat type and ordinary rank must be counted independently at spawn and completed reflavor"
	)
	await _dispose_scene(scene)


func _test_shortage_compensation_and_statistics() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	manager.start_service_early()
	var zero_supply := {
		manager.RESOURCE_OIL: 0.0,
		manager.RESOURCE_GREENS: 0.0,
		manager.RESOURCE_SALT: 0.0,
		manager.RESOURCE_MARINADE: 0.0,
		manager.RESOURCE_RICE: 0.0,
		manager.RESOURCE_CHILI: 0.0,
		manager.RESOURCE_MUSTARD: 0.0,
		manager.RESOURCE_BEEF: 0.0,
	}
	manager.set_shortage_supply_override_for_test(zero_supply)
	manager.force_shortage_update_for_test(42.0)
	_expect(
		manager.get_shortage_multiplier_for_test(manager.RESOURCE_OIL) > 1.0
		and manager.get_shortage_multiplier_for_test(manager.RESOURCE_RICE) > 1.0
		and manager.get_shortage_multiplier_for_test(manager.RESOURCE_MUSTARD) == 1.0,
		"Shortage: oil/rice may gain Prototype compensation while mustard has no hard pity"
	)
	var urgent := manager._get_most_urgent_eligible_shortage(manager._get_enemy_loot_entries(&"basic"))
	_expect(urgent == manager.RESOURCE_OIL, "Shortage: one drop opportunity must choose only the most urgent eligible resource")
	var spawned := manager._spawn_loot_item(ItemData.ItemType.COOKING_OIL, Vector2(1000.0, 800.0), manager.RESOURCE_OIL)
	_expect(
		spawned != null
		and spawned.is_loot_drop
		and manager.shortage_elapsed[manager.RESOURCE_OIL] == 0.0,
		"Shortage: only successful physical world generation resets the matching shortage timer"
	)
	var stats := scene.get_node("RunStats") as RunStats
	var snapshot := stats.get_snapshot()
	_expect(
		snapshot["compensation_trigger_count"] == 1
		and int(snapshot["loot_spawned_portions_by_item"].get(&"cooking_oil", 0)) == 2,
		"Statistics: compensation event and generated container portions must be recorded"
	)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.global_position = spawned.global_position
	_expect(player.pickup_item(spawned), "Statistics: compensated physical loot must still require personal pickup")
	snapshot = stats.get_snapshot()
	_expect(
		snapshot["loot_picked_up"] == 1
		and int(snapshot["loot_picked_up_portions_by_item"].get(&"cooking_oil", 0)) == 2,
		"Statistics: personal pickup must preserve and record the real remaining resource portions"
	)
	var small_bag := manager._spawn_loot_item(ItemData.ItemType.SMALL_RICE_BAG, Vector2(1040.0, 800.0), manager.RESOURCE_RICE)
	snapshot = stats.get_snapshot()
	_expect(
		small_bag.data.remaining_portions == 2
		and snapshot["small_rice_bag_potential_healing"] == 40.0
		and manager.rice_drop_cooldown_left > 0.0,
		"Rice shortage: successful small-bag generation must record 2-rice healing potential and start supply cooldown"
	)
	await _dispose_scene(scene)


func _entry_weight(entries: Array, item_type: int) -> float:
	for entry in entries:
		if int(entry[0]) == item_type:
			return float(entry[1])
	return 0.0


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
