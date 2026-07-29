extends SceneTree

class FeedbackStub:
	extends Node
	var messages: PackedStringArray = []

	func notify_feedback(message: String) -> void:
		messages.append(message)


var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_damage_sources_and_status_order()
	await _test_source_scoped_status_removal()
	_test_quality_caps()
	await _test_active_stir_fry()
	await _test_mobile_atomic_plating_qte()
	if failures.is_empty():
		print("PROTOTYPE_CONTENT_EXPANSION_A_TEST: PASS (5/5 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_CONTENT_EXPANSION_A_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_damage_sources_and_status_order() -> void:
	var source := Node.new()
	var target := Node.new()
	root.add_child(source)
	root.add_child(target)
	var source_status := CombatStatusController.ensure_on(source)
	var target_status := CombatStatusController.ensure_on(target)
	source_status.apply_status(CombatStatusController.StatusType.DIRECT_RANGED_BONUS, &"porridge", 0.20, 8.0)
	source_status.apply_status(CombatStatusController.StatusType.WEAKNESS, &"weak_zone", 0.10, 8.0)
	target_status.apply_status(CombatStatusController.StatusType.VULNERABILITY, &"spicy", 0.08, 8.0)
	target_status.apply_status(CombatStatusController.StatusType.DAMAGE_REDUCTION, &"meal", 0.15, 8.0)
	var direct := DamageContext.new()
	direct.source_entity = source
	direct.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
	direct.base_damage = 100.0
	direct.allow_direct_attack_bonus = true
	var direct_damage := CombatRules.resolve_damage(direct, target)
	_expect(
		is_equal_approx(direct_damage, 100.0 * 1.20 * 0.90 * 1.08 * 0.85),
		"Milestone A damage order: direct bonus, weakness, vulnerability and reduction must multiply in order"
	)
	var turret := DamageContext.new()
	turret.source_entity = source
	turret.source_type = DamageContext.SourceType.TURRET
	turret.base_damage = 100.0
	turret.allow_direct_attack_bonus = false
	var turret_damage := CombatRules.resolve_damage(turret, target)
	_expect(
		is_equal_approx(turret_damage, 100.0 * 0.90 * 1.08 * 0.85),
		"Milestone A damage sources: turret damage must not receive the player's direct-ranged bonus"
	)
	source.queue_free()
	target.queue_free()
	await process_frame


func _test_source_scoped_status_removal() -> void:
	var holder := Node.new()
	root.add_child(holder)
	var statuses := CombatStatusController.ensure_on(holder)
	statuses.apply_status(CombatStatusController.StatusType.VULNERABILITY, &"source_a", 0.08, 3.0)
	statuses.apply_status(CombatStatusController.StatusType.VULNERABILITY, &"source_b", 0.15, 3.0)
	statuses.remove_source(&"source_b")
	_expect(
		is_equal_approx(statuses.get_strongest(CombatStatusController.StatusType.VULNERABILITY), 0.08),
		"Milestone A statuses: removing one source must preserve the same status from another source"
	)
	statuses.advance(3.1)
	_expect(
		not statuses.has_status(CombatStatusController.StatusType.VULNERABILITY),
		"Milestone A statuses: non-persistent source durations must expire deterministically"
	)
	holder.queue_free()
	await process_frame


func _test_quality_caps() -> void:
	var weird := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	weird.weird_recipe = true
	weird.set_quality_with_cap(ItemData.Quality.PERFECT)
	_expect(
		weird.quality == ItemData.Quality.NORMAL,
		"Milestone A quality: weird dishes must cap at normal even after a perfect request"
	)
	var failed := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	failed.add_failure_tag(ItemData.FailureTag.BURNT)
	failed.set_quality_with_cap(ItemData.Quality.PERFECT)
	_expect(
		failed.quality == ItemData.Quality.PERFECT,
		"Milestone A test setup: an explicit quality request alone does not erase failure tags"
	)
	failed.recalculate_quality()
	_expect(
		failed.quality == ItemData.Quality.FLAWED and failed.has_failure_tag(ItemData.FailureTag.BURNT),
		"Milestone A quality: recalculation must retain inherited failure tags"
	)


func _test_active_stir_fry() -> void:
	var station := WokStation.new()
	root.add_child(station)
	await process_frame
	var feedback := FeedbackStub.new()
	root.add_child(feedback)
	var wok := station.wok_item
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.session_active = true
	station.burner_on = true
	station._process(station.config.active_stir_stage_one_time + 0.2)
	_expect(
		wok.cook_stage == WokItem.CookStage.RAW_LOADED,
		"Milestone A active stir: an active gameplay session must not auto-complete a stir-fry stage"
	)
	_expect(station.begin_primary_interaction(feedback), "Milestone A active stir: hold-E must start a valid stir interaction")
	_expect(
		not station.update_primary_interaction(feedback, station.config.active_stir_stage_one_time + 0.01)
		and wok.cook_stage == WokItem.CookStage.STAGE_ONE_DONE,
		"Milestone A active stir: the stage must complete only after the existing hold progress reaches its end"
	)
	wok.add_chili()
	station.begin_primary_interaction(feedback)
	station.update_primary_interaction(feedback, station.config.active_stir_stage_two_time + 0.01)
	_expect(
		wok.cook_stage == WokItem.CookStage.STAGE_TWO_DONE
		and wok.content_data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF,
		"Milestone A active stir: both held stages must still produce the existing combat dish"
	)
	station.queue_free()
	feedback.queue_free()
	await process_frame


func _test_mobile_atomic_plating_qte() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	player.inventory.clear_all()
	var config := (scene.get_node("CombatRuntime") as CombatManager).config
	var dish_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	config.apply_combat_dish_stats(dish_data)
	_put_quick_item(scene, player, dish_data, 0)
	_put_quick_item(scene, player, ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE), 1)
	_expect(plating.request_start(), "Milestone A mobile QTE: a valid dish and clean plate must start plating")
	_expect(
		player.action_qte_locked and not player.modal_ui_open and player.inventory.find_item_slot(ItemData.ItemType.CLEAN_PLATE) != -1,
		"Milestone A mobile QTE: actions are locked, movement remains available, and the plate is only reserved"
	)
	plating.cancel_active_plating()
	_expect(
		not player.action_qte_locked and player.inventory.find_item_slot(ItemData.ItemType.CLEAN_PLATE) != -1,
		"Milestone A mobile QTE: cancel must leave both reserved resources untouched"
	)
	_expect(plating.request_start() and plating.complete_for_test(true), "Milestone A mobile QTE: deterministic completion must succeed")
	_expect(
		player.inventory.find_item_slot(ItemData.ItemType.CLEAN_PLATE) == -1
		and player.inventory.get_item(0).data.item_type == ItemData.ItemType.PLATED_STIR_FRY_BEEF,
		"Milestone A mobile QTE: only successful completion consumes the plate and transforms the same dish instance"
	)
	await _dispose_scene(scene)


func _put_quick_item(scene: Node, player: PrototypePlayer, data: ItemData, slot_index: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_inventory_stored(player)
	_expect(player.inventory.put_item(slot_index, item), "Milestone A test setup: requested quick slot must be empty")
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
