extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_classification_and_thresholds()
	await _test_formal_clock_and_locations()
	await _test_active_heat_pause_and_station_recovery()
	await _test_processing_inheritance()
	await _test_weighted_partial_stacking()
	await _test_rotten_identity_shape_and_no_stack()
	await _test_waste_once_and_unbounded_linear_scaling()
	await _test_shortage_effective_supply()
	if failures.is_empty():
		print("PROTOTYPE_FRESHNESS_SPOILAGE_REGRESSION_TEST: PASS (8/8 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_FRESHNESS_SPOILAGE_REGRESSION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_classification_and_thresholds() -> void:
	var steak := ItemCatalog.create(ItemData.ItemType.RAW_STEAK)
	_expect(steak.freshness_lifetime == 600.0 and steak.get_freshness_state() == ItemData.FreshnessState.FRESH, "Classification: raw steak must start fully fresh with the centralized 600s lifetime")
	steak.set_spoilage_ratio(0.40)
	_expect(steak.get_freshness_state() == ItemData.FreshnessState.STILL_FRESH and not steak.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY), "Threshold: 40% must enter still-fresh without a failure tag")
	steak.set_spoilage_ratio(0.75)
	_expect(steak.get_freshness_state() == ItemData.FreshnessState.NEAR_EXPIRY and steak.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY) and steak.quality == ItemData.Quality.FLAWED, "Threshold: 75% must add the permanent near-expiry tag and cap ordinary quality at flawed")
	steak.set_spoilage_ratio(0.80)
	_expect(steak.failure_tags.count(ItemData.FailureTag.NEAR_EXPIRY) == 1, "Threshold: repeated near-expiry updates must not duplicate the tag")
	steak.add_failure_tag(ItemData.FailureTag.BURNT)
	_expect(steak.quality == ItemData.Quality.BAD, "Quality: near-expiry plus another failure must be bad")
	var oil := ItemCatalog.create(ItemData.ItemType.COOKING_OIL)
	var rice := ItemCatalog.create(ItemData.ItemType.RAW_RICE)
	var plate := ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE)
	_expect(not oil.is_perishable() and not rice.is_perishable() and not plate.is_perishable(), "Classification: oil, raw rice and plates must remain nonperishable")


func _test_formal_clock_and_locations() -> void:
	var scene := await _spawn_main_scene()
	var wave := scene.get_node("WaveManager") as PrototypeWaveManager
	var freshness := scene.get_node("FreshnessManager") as FreshnessManager
	wave.set_process(false)
	freshness.set_process(false)
	var lobby_item := _new_world_item(scene, ItemData.ItemType.RAW_STEAK)
	freshness.advance_for_test(120.0)
	_expect(lobby_item.data.spoilage_ratio == 0.0, "Clock: free test lobby must not age food")
	wave.start_service_early()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.inventory.clear_all()
	var carried := _new_world_item(scene, ItemData.ItemType.RAW_STEAK)
	_expect(player.pickup_item(carried), "Clock: test steak must enter the real quick inventory")
	freshness.process_all_items_now()
	freshness.advance_for_test(60.0)
	_expect(is_equal_approx(carried.data.spoilage_ratio, 0.10), "Clock: hidden quick-inventory instances must age exactly once")
	var before := carried.data.spoilage_ratio
	carried.storage_rotated = true
	freshness.process_all_items_now()
	_expect(is_equal_approx(carried.data.spoilage_ratio, before), "Clock: moving or rotating without elapsed formal time must not refresh or double-age")
	paused = true
	var paused_before := carried.data.spoilage_ratio
	# SceneTree pause prevents the runtime process; direct test calls model no elapsed authority.
	freshness.process_all_items_now()
	paused = false
	_expect(is_equal_approx(carried.data.spoilage_ratio, paused_before), "Clock: a true global pause must not advance freshness")
	await _dispose_scene(scene)


func _test_active_heat_pause_and_station_recovery() -> void:
	var scene := await _spawn_main_scene()
	var wave := scene.get_node("WaveManager") as PrototypeWaveManager
	var freshness := scene.get_node("FreshnessManager") as FreshnessManager
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	wave.set_process(false)
	freshness.set_process(false)
	station.set_process(false)
	wave.start_service_early()
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.stirring_active = true
	station.hold_progress.begin(30.0)
	freshness.process_all_items_now()
	freshness.advance_for_test(60.0)
	var content := station.wok_item.content_data
	_expect(is_zero_approx(content.spoilage_ratio), "Cooking: valid heat plus actively progressing stir must pause ingredient ageing")
	station.hold_progress.cancel()
	station.stirring_active = false
	freshness.advance_for_test(66.0)
	_expect(is_equal_approx(content.spoilage_ratio, 0.10), "Cooking: leaving food in a lit but non-progressing wok must resume ageing")
	content.set_spoilage_ratio(0.999)
	freshness.process_all_items_now()
	freshness.advance_for_test(1.0)
	_expect(
		station.wok_item.content_data != null
		and station.wok_item.content_data.item_type == ItemData.ItemType.ROTTEN_WASTE
		and not station.hold_progress.active,
		"Cooking: food rotting in a station must cancel processing while leaving removable waste instead of soft-locking the station"
	)
	await _dispose_scene(scene)


func _test_processing_inheritance() -> void:
	var chunk := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK)
	chunk.set_spoilage_ratio(0.50)
	var steak := ItemCatalog.transform(chunk, ItemData.ItemType.RAW_STEAK)
	_expect(is_equal_approx(steak.spoilage_ratio, 0.50) and is_equal_approx(steak.get_remaining_freshness_seconds(), 300.0), "Processing: shape-only cutting must preserve exact spoilage ratio across the new lifetime")
	steak.set_spoilage_ratio(0.80)
	var slices := ItemCatalog.transform(steak, ItemData.ItemType.RAW_BEEF_SLICES)
	var marinated := ItemCatalog.transform(slices, ItemData.ItemType.MARINATED_BEEF_SLICES)
	_expect(is_zero_approx(marinated.spoilage_ratio) and marinated.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY), "Processing: marination must refresh the current cycle but retain the permanent near-expiry failure")
	var dish := ItemCatalog.transform(marinated, ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	_expect(is_zero_approx(dish.spoilage_ratio) and dish.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY), "Processing: forming a completed dish must start its dish cycle without clearing inherited failures")
	dish.set_quality_with_cap(ItemData.Quality.PERFECT)
	dish.has_perfect_finisher = true
	dish.set_spoilage_ratio(0.76)
	_expect(dish.quality == ItemData.Quality.FLAWED and not dish.has_perfect_finisher, "Completed dish: later near-expiry must remove perfect quality and perfect-only finishers")


func _test_weighted_partial_stacking() -> void:
	var existing := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	existing.stack_count = 4
	existing.leaf_count = 1
	existing.set_spoilage_ratio(0.20)
	var incoming := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	incoming.stack_count = 3
	incoming.leaf_count = 1
	incoming.set_spoilage_ratio(0.60)
	var accepted := existing.add_from_stack(incoming)
	incoming.stack_count -= accepted
	_expect(accepted == 1 and existing.stack_count == 5 and incoming.stack_count == 2, "Stacking: only available capacity may be accepted")
	_expect(is_equal_approx(existing.spoilage_ratio, 0.28) and is_equal_approx(incoming.spoilage_ratio, 0.60), "Stacking: weighted average must include only the accepted portion and preserve the remainder")
	var near_a := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	var near_b := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	near_a.set_spoilage_ratio(0.78)
	near_b.set_spoilage_ratio(0.92)
	var fresh := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	_expect(near_a.can_stack_with(near_b) and not near_a.can_stack_with(fresh), "Stacking: near-expiry may merge only with near-expiry")
	var refreshed := ItemCatalog.transform(near_a, ItemData.ItemType.GREENS_LEAF)
	refreshed.reset_freshness_cycle()
	_expect(refreshed.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY) and not refreshed.can_stack_with(fresh), "Stacking: a refreshed cycle with permanent near-expiry history must not merge into an untagged batch")


func _test_rotten_identity_shape_and_no_stack() -> void:
	var manager := FreshnessManager.new()
	root.add_child(manager)
	manager.begin_formal_run()
	var holder := Node2D.new()
	root.add_child(holder)
	var chunk_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	holder.add_child(chunk_item)
	manager._convert_to_rotten(chunk_item.data, chunk_item)
	_expect(chunk_item.data.item_type == ItemData.ItemType.ROTTEN_WASTE and not chunk_item.data.is_stackable and chunk_item.data.max_stack_count == 1, "Rotten: conversion must erase the food identity and make every waste instance non-stackable")
	_expect(ItemStorageCatalog.get_shape_bounds(ItemStorageCatalog.get_shape_cells_for_data(chunk_item.data, false)) == Vector2i(3, 3) and chunk_item.data.waste_units_snapshot == 15, "Rotten: a whole beef chunk must retain 3x3 storage and snapshot 15 waste units")
	var steak_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
	holder.add_child(steak_item)
	steak_item.storage_rotated = true
	manager._convert_to_rotten(steak_item.data, steak_item)
	var rotated_bounds := ItemStorageCatalog.get_shape_bounds(ItemStorageCatalog.get_shape_cells_for_data(steak_item.data, steak_item.storage_rotated))
	_expect(rotated_bounds == Vector2i(1, 3), "Rotten: a rotated horizontal steak must remain vertically oriented after conversion")
	_expect(not chunk_item.data.can_stack_with(steak_item.data), "Rotten: even two rotten items can never stack")
	holder.queue_free()
	manager.queue_free()
	await process_frame


func _test_waste_once_and_unbounded_linear_scaling() -> void:
	var manager := FreshnessManager.new()
	root.add_child(manager)
	manager.begin_formal_run()
	for amount in [40, 60, 100]:
		var waste := ItemCatalog.create(ItemData.ItemType.ROTTEN_WASTE)
		waste.waste_units_snapshot = amount
		manager.settle_waste(waste, &"drop")
		_expect(manager.settle_waste(waste, &"trash") == 0, "Waste: one physical rotten instance must settle at most once")
		if amount == 40:
			_expect(is_equal_approx(manager.get_enemy_health_multiplier(), 1.20) and is_equal_approx(manager.get_enemy_damage_multiplier(), 1.10), "Waste scaling: 40 units must produce 1.20 health and 1.10 damage")
		elif amount == 60:
			_expect(is_equal_approx(manager.get_enemy_health_multiplier(), 1.50) and is_equal_approx(manager.get_enemy_damage_multiplier(), 1.25), "Waste scaling: 100 cumulative units must continue to 1.50 health and 1.25 damage")
		else:
			_expect(is_equal_approx(manager.get_enemy_health_multiplier(), 2.00) and is_equal_approx(manager.get_enemy_damage_multiplier(), 1.50), "Waste scaling: 200 units must remain uncapped and linear at 2.00 health and 1.50 damage")
	var enemy := BasicTasteEnemy.new()
	enemy.setup(PrototypeWaveConfig.new(), null, null)
	var base_health := enemy.max_health_value
	var base_damage := enemy.attack_damage_value
	enemy.apply_spawn_waste_multipliers(manager.get_enemy_health_multiplier(), manager.get_enemy_damage_multiplier())
	_expect(is_equal_approx(enemy.max_health_value, base_health * 2.0) and is_equal_approx(enemy.attack_damage_value, base_damage * 1.5), "Waste scaling: a newly spawned enemy must apply multipliers once from base values without compounding")
	manager.begin_formal_run()
	_expect(manager.waste_units == 0 and manager.get_enemy_health_multiplier() == 1.0 and manager.get_enemy_damage_multiplier() == 1.0, "Waste scaling: a formal new run must reset arbitrarily high waste")
	enemy.free()
	manager.queue_free()
	await process_frame


func _test_shortage_effective_supply() -> void:
	var manager := PrototypeWaveManager.new()
	var supply := {
		manager.RESOURCE_GREENS: 0.0,
		manager.RESOURCE_BEEF: 0.0,
		manager.RESOURCE_RICE: 0.0,
		manager.RESOURCE_OIL: 0.0,
		manager.RESOURCE_SALT: 0.0,
		manager.RESOURCE_MARINADE: 0.0,
		manager.RESOURCE_CHILI: 0.0,
		manager.RESOURCE_MUSTARD: 0.0,
	}
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	leaves.set_spoilage_ratio(0.80)
	manager._add_item_supply(supply, leaves)
	_expect(is_equal_approx(float(supply[manager.RESOURCE_GREENS]), 2.5), "Shortage: five near-expiry leaves must count as 2.5 effective leaves")
	leaves.item_type = ItemData.ItemType.ROTTEN_WASTE
	manager._add_item_supply(supply, leaves)
	_expect(is_equal_approx(float(supply[manager.RESOURCE_GREENS]), 2.5), "Shortage: rotten waste must contribute zero effective supply")
	manager.free()


func _new_world_item(scene: Node, item_type: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(ItemCatalog.create(item_type))
	scene.add_child(item)
	item.release_to_world(scene, Vector2(900.0, 800.0))
	return item


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	paused = false
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	await process_frame
	current_scene = null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
