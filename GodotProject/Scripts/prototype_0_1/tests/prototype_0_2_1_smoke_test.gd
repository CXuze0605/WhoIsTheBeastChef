extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_automatic_cooking()
	await _test_overheating()
	await _test_burner_interruption()
	await _test_wok_removal_interruption()
	await _test_burner_persistence()
	await _test_salt_modifier()
	await _test_mustard_modifier_and_poison()
	await _test_mustard_aim_side_effects()
	await _test_salt_and_mustard_coexist()
	await _test_regression_contracts()
	if failures.is_empty():
		print("PROTOTYPE_0_2_1_SMOKE_TEST: PASS (10/10 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_2_1_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_automatic_cooking() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	player.global_position = Vector2(800.0, 680.0)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "Auto cooking must continue after the player leaves the stove")
	_expect(not player.modal_ui_open, "Auto cooking must not lock player movement or other actions")
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time + 0.01)
	_expect(station.wok_item.content_data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, "Automatic two-stage route must produce the unplated dish")
	await _dispose_scene(scene)


func _test_overheating() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	_make_completed_unplated_in_wok(station)
	station.advance_automatic_cooking(station.config.automatic_burn_time + 0.01)
	_expect(station.wok_item.content_data.has_failure_tag(ItemData.FailureTag.BURNT), "Completed dish left on fire must gain the confirmed burnt tag")
	_expect(station.wok_item.cook_stage == WokItem.CookStage.BURNT_TAGGED, "Burning must advance to a discrete completed state")
	station.advance_automatic_cooking(station.config.automatic_charcoal_time + 0.01)
	_expect(station.wok_item.content_data.item_type == ItemData.ItemType.CHARCOAL, "Continued overheating must turn the dish into charcoal")
	await _dispose_scene(scene)


func _test_burner_interruption() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time * 0.5)
	_expect(station.get_progress_ratio() > 0.0, "Stage one should visibly advance before interruption")
	station.set_burner_on(false)
	_expect(station.get_progress_ratio() == 0.0, "Turning the burner off must reset the unfinished stage")
	_expect(station.wok_item.cook_stage == WokItem.CookStage.RAW_LOADED, "Turning fire off must retain the previous discrete food state")
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time * 0.6)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.RAW_LOADED, "Restarted stage must begin from zero, not retain partial heat progress")
	station.advance_automatic_cooking(station.config.automatic_stage_one_time * 0.5)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "Restarted full stage should complete normally")
	await _dispose_scene(scene)


func _test_wok_removal_interruption() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time * 0.5)
	station.secondary_interact(player)
	var carried := player.held_item as WokItem
	_expect(carried != null and station.wok_item == null, "Wok must remain an independent carryable instance")
	_expect(station.get_progress_ratio() == 0.0, "Taking the wok off-station must reset the unfinished heat stage")
	_expect(carried.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "Completed first stage must survive wok transport")
	_expect(carried.content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS), "Inserted chili must survive heat interruption and wok transport")
	station.secondary_interact(player)
	station.advance_automatic_cooking(station.config.automatic_stage_two_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_TWO_DONE, "Returned wok must restart and complete stage two from zero")
	await _dispose_scene(scene)


func _test_burner_persistence() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	_make_completed_unplated_in_wok(station)
	station.carry_interact(player)
	_expect(station.burner_on, "Taking a completed dish out must not automatically turn the burner off")
	station.advance_automatic_cooking(10.0)
	_expect(not station.wok_item.is_stuck(), "An empty lit wok is safe in this Prototype and must not become stuck")
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_ONE_DONE, "New valid ingredients must start automatically while the burner remains on")
	station.set_burner_on(false)
	_expect(not station.burner_on, "Player must be able to turn the burner off explicitly")
	await _dispose_scene(scene)


func _test_salt_modifier() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var config := scene.get_node("CombatRuntime").config as PrototypeCombatConfig
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time * 0.4)
	var progress_before := station.get_progress_ratio()
	_expect(station.wok_item.add_salt(), "Salt must be accepted during the cooking window")
	_expect(is_equal_approx(station.get_progress_ratio(), progress_before), "Adding salt must not reset current cooking progress")
	station.set_burner_on(false)
	_expect(station.wok_item.content_data.has_active_modifier(ItemData.ActiveModifier.SALTED), "Salt modifier must survive turning the burner off")
	var salted := ItemCatalog.create(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	salted.add_active_modifier(ItemData.ActiveModifier.SALTED)
	config.apply_combat_dish_stats(salted)
	var normal := ItemCatalog.create(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	config.apply_combat_dish_stats(normal)
	_expect(salted.max_durability == normal.max_durability + config.salt_durability_bonus, "Salt must increase maximum durability by the centralized Prototype value")
	_expect(is_equal_approx(salted.actual_damage, normal.actual_damage), "Salt must not alter direct damage")
	station.wok_item.complete_stage_one()
	station.wok_item.add_chili()
	station.wok_item.complete_stage_two()
	_expect(not station.wok_item.can_add_salt(), "Salt must be rejected after the unplated dish has formed")
	await _dispose_scene(scene)


func _test_mustard_modifier_and_poison() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var plating := scene.get_node("PlatingController") as PlatingController
	var config := scene.get_node("CombatRuntime").config as PrototypeCombatConfig
	var dish := _give_unplated_dish(player)
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MUSTARD))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	_expect(plating.request_apply_mustard(), "Mustard must be consumable only on an unplated dish")
	_expect(dish.data.has_active_modifier(ItemData.ActiveModifier.MUSTARD), "Mustard must be saved as an active modifier")
	_expect(dish.data.failure_tags.is_empty(), "Mustard must not be stored as a failure tag")
	_expect(plating.request_start() and plating.complete_for_test(true), "Mustard dish must still complete the plating QTE")
	_expect(dish.data.quality == ItemData.Quality.NORMAL and not dish.data.has_perfect_finisher, "Weird mustard dish must cap at normal quality and lose the perfect finisher")
	_expect(dish.data.actual_damage < config.standard_damage, "Mustard must reduce direct damage")
	var target := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var health_before := target.current_health
	target.receive_combat_hit(dish.data.actual_damage, CombatRules.Faction.PLAYER, Vector2.RIGHT, 0.0, false)
	var effect := config.create_on_hit_effect(dish.data)
	_expect(effect != null and target.apply_status_effect(effect), "Mustard hit must apply reusable poison status data")
	target.status_effects.advance_effects(config.mustard_poison_duration + config.mustard_poison_interval)
	var total_damage := health_before - target.current_health
	_expect(total_damage > config.standard_damage, "Reduced direct hit plus full poison must exceed the normal direct-hit total")
	await _dispose_scene(scene)


func _test_mustard_aim_side_effects() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var attack := player.get_node("DishAttackController") as DishAttackController
	var friendly := scene.get_node("Kitchen/FriendlyDummy") as DebugCombatTarget
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var dish_data := ItemCatalog.create(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	dish_data.add_active_modifier(ItemData.ActiveModifier.MUSTARD)
	combat.config.apply_combat_dish_stats(dish_data)
	player.receive_item_data(dish_data)
	attack.update_mustard_aim_for_test(0.10, true)
	var first_sway := attack.current_sway_angle
	attack.update_mustard_aim_for_test(0.10, true)
	_expect(not is_equal_approx(first_sway, attack.current_sway_angle), "Mustard aim sway must move smoothly over time instead of per-frame random jitter")
	_expect(not is_zero_approx(friendly.external_aim_sway_angle), "Nearby ranged-friendly test receiver must receive the shared aim influence")
	attack.force_sneeze_warning_for_test(28.0)
	_expect(attack.sneeze_phase == DishAttackController.SneezePhase.WARNING, "Sneeze must provide a warning phase")
	attack.update_mustard_aim_for_test(combat.config.mustard_sneeze_warning_time + 0.01, true)
	_expect(attack.sneeze_phase == DishAttackController.SneezePhase.OFFSET and absf(attack.current_sneeze_offset) > 0.0, "Sneeze warning must transition to one large temporary offset")
	var bull := combat.spawn_normal_bull(player.global_position, Vector2.RIGHT, 1.0)
	var released_direction := bull.direction
	attack.update_mustard_aim_for_test(0.2, true)
	_expect(bull.direction == released_direction, "Already released bulls must not follow later aim movement")
	attack.update_mustard_aim_for_test(0.01, false)
	_expect(is_zero_approx(attack.current_sway_angle) and is_zero_approx(attack.current_sneeze_offset), "Stopping mustard attacks must immediately restore normal aim")
	_expect(is_zero_approx(friendly.external_aim_sway_angle) and is_zero_approx(friendly.external_sneeze_offset), "Stopping must also clear nearby friendly aim influence")
	await _dispose_scene(scene)


func _test_salt_and_mustard_coexist() -> void:
	var config := PrototypeCombatConfig.new()
	var dish := ItemCatalog.create(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	dish.add_active_modifier(ItemData.ActiveModifier.SALTED)
	dish.add_active_modifier(ItemData.ActiveModifier.MUSTARD)
	dish.quality = ItemData.Quality.NORMAL
	config.apply_combat_dish_stats(dish)
	_expect(dish.active_modifiers.size() == 2 and dish.failure_tags.is_empty(), "Salt and mustard must coexist in a collection separate from failure tags")
	_expect(dish.max_durability == config.standard_durability + config.salt_durability_bonus, "Salt durability bonus must coexist with mustard")
	_expect(dish.actual_damage < config.standard_damage and dish.poison_damage > 0.0, "Mustard direct-damage and poison changes must coexist with salt")
	_expect(not dish.has_perfect_finisher and dish.is_weird_dish(), "Salt must not restore perfect eligibility to a mustard weird dish")


func _test_regression_contracts() -> void:
	_expect(InputMap.has_action("season_dish") and not InputMap.action_get_events("season_dish").is_empty(), "Prototype 0.2.1 must register a dedicated mustard input")
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.start_service_early()
	await process_frame
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and not cabinet.lobby_unlimited, "Formal preparation must use the finite cabinet")
	_expect(cabinet.get_supported_item_types().size() == 6, "Unified cabinet must contain exactly the four old ingredients plus salt and mustard")
	_expect(cabinet.get_stock(ItemData.ItemType.SALT) > 0 and cabinet.get_stock(ItemData.ItemType.MUSTARD) > 0, "Salt and mustard stocks must be finite editable Debug values")
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	station.carry_interact(player)
	station.set_burner_on(true)
	_expect(station.wok_item.is_stuck(), "Automatic heat must preserve the no-oil charcoal and stuck-wok accident")
	station.secondary_interact(player)
	_expect(player.held_item is WokItem, "Stuck wok must remain carryable")
	sink.begin_primary_interaction(player)
	sink.update_primary_interaction(player, sink.prototype_stuck_wok_wash_time + 0.01)
	_expect(not (player.held_item as WokItem).is_stuck(), "Sink hold interaction must still clean a stuck wok")
	station.secondary_interact(player)
	_expect(station.wok_item != null and not station.wok_item.is_stuck(), "Cleaned wok must return to its origin station and work again")
	await _dispose_scene(scene)


func _make_completed_unplated_in_wok(station: WokStation) -> void:
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time + 0.01)


func _give_unplated_dish(player: PrototypePlayer) -> CarryableItem:
	var data := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	var combat := player.get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat != null:
		combat.config.apply_combat_dish_stats(data)
	player.receive_item_data(data)
	return player.inventory.get_item(player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF))


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "Unable to load the Prototype main scene")
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.start_game()
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
