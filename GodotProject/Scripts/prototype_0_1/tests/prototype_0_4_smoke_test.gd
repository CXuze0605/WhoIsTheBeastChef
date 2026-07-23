extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_a_free_preparation()
	await _test_b_generic_stoves()
	await _test_c_tomahawk_cooking()
	await _test_d_plating_bone_and_mustard()
	await _test_e_shabu_portions_and_soup()
	await _test_f_lure_trap()
	await _test_g_heavy_enemy_stagger()
	await _test_h_three_wave_flow()
	await _test_i_tags_and_regression()
	if failures.is_empty():
		print("PROTOTYPE_0_4_SMOKE_TEST: PASS (9/9 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_4_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_a_free_preparation() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var stove := scene.get_node("Kitchen/WokStation") as WokStation
	var start_ui := scene.get_node("StartGameUI") as StartGameUI
	_expect(manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION and manager.preparation_left == 0.0, "A: scene must initialize directly into untimed free preparation")
	_expect(not player.modal_ui_open and stove.session_active and start_ui.root_control.visible, "A: free preparation must allow world input and automatic cooking with an edge button")
	var stock_before := cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK)
	cabinet.request_take(ItemData.ItemType.RAW_BEEF_CHUNK, player)
	stove.wok_item.add_oil()
	stove.set_burner_on(true)
	_expect(manager.start_service_early(), "A: Start Service must be accepted from free preparation")
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and manager.preparation_left >= 30.0 and player.held_item == null and not stove.burner_on and not stove.wok_item.has_oil(), "A: starting service must clear isolated lobby practice state before formal preparation")
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == stock_before and not manager.early_started, "A: formal preparation must restore centralized initial stock and record no early reward")
	await _dispose_scene(scene)


func _test_b_generic_stoves() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var stove_a := scene.get_node("Kitchen/WokStation") as WokStation
	var stove_b := scene.get_node("Kitchen/StoveStation2") as WokStation
	var rack := scene.get_node("Kitchen/CookwareRack") as CookwareRack
	_expect(get_nodes_in_group("stove_station").size() == 2 and stove_a.wok_item != null and stove_b.cookware_item is PanItem and rack.soup_pot != null, "B: map must contain two generic stoves and one wok/pan/soup pot")
	stove_a.secondary_interact(player)
	var wok_slot := player.inventory.find_item_slot(ItemData.ItemType.WOK)
	player.inventory.select(wok_slot)
	stove_b.secondary_interact(player)
	var pan_slot := player.inventory.find_item_slot(ItemData.ItemType.PAN)
	player.inventory.select(pan_slot)
	stove_a.secondary_interact(player)
	_expect(stove_a.cookware_item is PanItem and stove_b.cookware_item == null, "B: pan must move to either generic stove while each slot holds at most one cookware")
	player.inventory.select(wok_slot)
	stove_b.secondary_interact(player)
	_expect(stove_b.cookware_item is WokItem, "B: existing wok must also move to either generic stove")
	await _dispose_scene(scene)


func _test_c_tomahawk_cooking() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var stove := scene.get_node("Kitchen/StoveStation2") as WokStation
	stove.set_process(false)
	var pan := stove.cookware_item as PanItem
	pan.add_oil()
	pan.insert_steak(ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
	stove.set_burner_on(true)
	stove.advance_automatic_cooking(stove.config.pan_first_side_time + 0.01)
	_expect(pan.cook_stage == PanItem.CookStage.FLIP_WINDOW and stove.circular_indicator.state_key == "flip", "C: first side must enter a local flip window")
	stove.begin_primary_interaction(player)
	_expect(pan.cook_stage == PanItem.CookStage.SECOND_SIDE and not pan.content_data.has_failure_tag(ItemData.FailureTag.FLIPPED_LATE), "C: interacting during window must flip without a failure tag")
	stove.advance_automatic_cooking(stove.config.pan_second_side_time + 0.01)
	_expect(pan.cook_stage == PanItem.CookStage.READY and pan.content_data.item_type == ItemData.ItemType.TOMAHAWK_STEAK and pan.content_data.is_eligible_for_plating(), "C: second side must produce a full, unused combat steak")
	var late_pan := PanItem.new()
	late_pan.setup_pan()
	late_pan.add_oil()
	late_pan.insert_steak(ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
	late_pan.open_flip_window()
	late_pan.flip(true)
	_expect(late_pan.content_data.has_failure_tag(ItemData.FailureTag.FLIPPED_LATE), "C: missed window must auto-flip and record the confirmed late-flip tag")
	late_pan.free()
	await _dispose_scene(scene)


func _test_d_plating_bone_and_mustard() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var plating := scene.get_node("PlatingController") as PlatingController
	var qte := scene.get_node("PlatingQTEUI") as PlatingQTEUI
	var attack := player.get_node("DishAttackController") as DishAttackController
	var steak_data := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	combat.config.apply_tomahawk_stats(steak_data)
	var steak := _give_data(player, steak_data)
	_give_data(player, ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	_expect(plating.request_start(), "D: full unused steak must be eligible for optional plating")
	qte.set_pointer_ratio_for_test(0.5)
	plating.confirm_qte()
	_expect(steak.data.item_type == ItemData.ItemType.PLATED_TOMAHAWK_STEAK and steak.data.quality == ItemData.Quality.PERFECT, "D: perfect QTE must create perfect plated tomahawk")
	for hit in steak.data.max_durability:
		attack.fire_once(Vector2.LEFT)
	_expect(steak.data.item_type == ItemData.ItemType.BIG_BONE, "D: perfect plated steak must become a persistent big bone in the same item instance")
	attack.fire_once(Vector2.LEFT)
	var bone: BigBoneProjectile
	for child in combat.get_children():
		if child is BigBoneProjectile:
			bone = child
	if bone != null:
		for step in 80:
			if not is_instance_valid(bone) or bone.is_queued_for_deletion():
				break
			bone._physics_process(0.02)
	await process_frame
	_expect(steak.data.item_type == ItemData.ItemType.DIRTY_PLATE, "D: big bone completion must convert the original plated instance to a dirty plate")
	var mustard_data := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	mustard_data.add_active_modifier(ItemData.ActiveModifier.MUSTARD)
	combat.config.apply_tomahawk_stats(mustard_data)
	var mustard_steak := _give_data(player, mustard_data)
	player.inventory.select(player.inventory.find_item_slot(ItemData.ItemType.TOMAHAWK_STEAK))
	mustard_steak.data.next_sneeze_attack = 2
	attack.fire_once(Vector2.RIGHT)
	attack.fire_once(Vector2.RIGHT)
	_expect(mustard_steak.data.attack_count == 0 and mustard_steak.data.next_sneeze_attack in [2, 3] and player.action_stun_left > 0.0, "D: mustard swing counter must persist per instance and sneeze after two or three swings")
	_expect(not mustard_steak.data.has_perfect_finisher and mustard_steak.data.actual_damage < combat.config.tomahawk_damage, "D: mustard steak must be weird, lower direct damage and have no perfect bone finisher")
	await _dispose_scene(scene)


func _test_e_shabu_portions_and_soup() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var stove := scene.get_node("Kitchen/StoveStation2") as WokStation
	stove.set_process(false)
	if stove.cookware_item != null:
		stove.cookware_item.queue_free()
	var pot := SoupPotItem.new()
	pot.setup_soup_pot()
	stove.add_child(pot)
	pot.set_stored(stove, Vector2(0.0, -10.0))
	stove.cookware_item = pot
	pot.fill_water()
	stove.set_burner_on(true)
	stove.advance_automatic_cooking(stove.config.soup_water_heat_time + 0.01)
	_expect(pot.cook_stage == SoupPotItem.CookStage.BOILING, "E: filled soup pot must heat to boiling on a generic stove")
	var slices := _give_data(player, ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	stove.carry_interact(player)
	_expect(slices.data.remaining_portions == 4 and pot.cook_stage == SoupPotItem.CookStage.SLICE_COOKING, "E: soup use must consume one of five stored beef-slice portions")
	stove.advance_automatic_cooking(stove.config.shabu_cook_time + 0.01)
	_expect(pot.content_data.item_type == ItemData.ItemType.SHABU_BEEF and pot.content_data.failure_tags.is_empty(), "E: boiling water must produce a normal shabu slice")
	var first_slice := pot.take_content()
	var second_slice := ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	_expect(first_slice.can_stack_with(second_slice) and first_slice.max_stack_count == 5, "E: matching shabu states must stack up to five")
	var cold_pot := SoupPotItem.new()
	cold_pot.setup_soup_pot(); cold_pot.fill_water(); cold_pot.insert_slice(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES)); cold_pot.complete_slice()
	_expect(cold_pot.content_data.has_failure_tag(ItemData.FailureTag.COLD_WATER_ENTRY), "E: cold-water entry must affect only the inserted slice")
	cold_pot.mark_overcooked(); cold_pot.turn_to_mushy()
	_expect(cold_pot.content_data.item_type == ItemData.ItemType.MUSHY_BOILED_BEEF, "E: late removal must progress through overboiled to mushy beef")
	cold_pot.free()
	await _dispose_scene(scene)


func _test_f_lure_trap() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var trap_controller := player.get_node("TrapController") as TrapController
	var shabu := ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	shabu.stack_count = 2
	_give_data(player, shabu)
	trap_controller._resolve_runtime()
	_expect(trap_controller.place_selected_shabu(), "F: selected shabu must place on a legal nearby navigation cell")
	var trap := get_first_node_in_group("shabu_trap") as ShabuTrap
	_expect(trap != null and shabu.stack_count == 1, "F: placement must consume exactly one slice and use a non-plate placeholder")
	var enemy := manager.spawn_enemy_for_test(trap.global_position + Vector2(90.0, 0.0))
	var health_before := enemy.current_health
	enemy._physics_process(0.02)
	_expect(enemy.state == BasicTasteEnemy.State.LURED and trap.locked_enemy == enemy, "F: one available trap must lock exactly one nearby enemy")
	enemy.global_position = trap.global_position + Vector2(5.0, 0.0)
	enemy._physics_process(0.02)
	_expect(enemy.state == BasicTasteEnemy.State.TASTING, "F: locked enemy must enter a short tasting state at the food")
	enemy._physics_process(trap.get_taste_duration() + 0.05)
	await process_frame
	_expect(enemy.current_health < health_before and (not is_instance_valid(trap) or trap.is_queued_for_deletion()), "F: tasting must deal reflavor damage and consume one trap")
	await _dispose_scene(scene)


func _test_g_heavy_enemy_stagger() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var heavy := manager.spawn_heavy_enemy_for_test(Vector2(1500.0, 900.0))
	_expect(heavy.current_health == manager.config.heavy_max_health and heavy.current_health >= manager.config.enemy_max_health * 2.5 and heavy.move_speed_value < manager.config.enemy_move_speed, "G: heavy enemy must be slower and roughly 2.5-3x tougher")
	heavy._enter_state(BasicTasteEnemy.State.WINDUP)
	heavy.receive_combat_hit(10.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 42.0, false, 22.0)
	_expect(heavy.state == BasicTasteEnemy.State.WINDUP and heavy.get_recipe_damage_multiplier(ItemData.AttackForm.PROJECTILE, ItemData.CookingMethod.STIR_FRY) == 1.0, "G: normal bull must deal full damage but not reliably interrupt heavy windup")
	heavy.receive_combat_hit(10.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 130.0, false, 100.0)
	_expect(heavy.state == BasicTasteEnemy.State.HIT_STUN and heavy.knockback_velocity.length() > 0.0, "G: tomahawk stagger power must interrupt heavy windup")
	await _dispose_scene(scene)


func _test_h_three_wave_flow() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var preserved := _give_data(player, ItemCatalog.create(ItemData.ItemType.SALT))
	player.current_health = 73.0
	manager.phase = PrototypeWaveManager.Phase.WAVE_ACTIVE
	manager.current_batch = manager.config.get_total_batches(1)
	manager.spawned_total = manager.config.get_planned_enemy_total(1)
	manager.reflavored_total = manager.spawned_total
	manager.active_enemy_count = 0
	manager._check_wave_complete()
	_expect(manager.phase == PrototypeWaveManager.Phase.INTERMISSION and manager.current_wave == 2 and player.current_health == 73.0 and preserved.is_inside_tree(), "H: wave one must enter timed intermission without resetting health or inventory")
	var early_before := manager.preparation_left
	manager.start_service_early()
	_expect(manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING and manager.early_started and manager.early_seconds == early_before, "H: intermission may start early and only records remaining seconds")
	_forcibly_complete_wave(manager, 2)
	_expect(manager.phase == PrototypeWaveManager.Phase.INTERMISSION and manager.current_wave == 3, "H: wave two must advance to a second intermission")
	_forcibly_complete_wave(manager, 3)
	_expect(manager.phase == PrototypeWaveManager.Phase.RUN_COMPLETE and manager.completed_waves == 3, "H: third mixed wave must end the Prototype run without a fourth wave")
	_expect(manager.config.get_heavy_per_batch(1) == 0 and manager.config.get_heavy_per_batch(2) > 0 and manager.config.get_heavy_per_batch(3) > 0, "H: wave one is basic-only while waves two and three mix heavy enemies")
	await _dispose_scene(scene)


func _test_i_tags_and_regression() -> void:
	var scene := await _spawn_main_scene()
	var wok_stove := scene.get_node("Kitchen/WokStation") as WokStation
	wok_stove.set_process(false)
	wok_stove.wok_item.add_oil()
	wok_stove.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok_stove.set_burner_on(true)
	wok_stove.advance_automatic_cooking(wok_stove.config.automatic_stage_one_time + 0.01)
	wok_stove.wok_item.add_chili()
	wok_stove.advance_automatic_cooking(wok_stove.config.automatic_stage_two_time + 0.01)
	var stir := wok_stove.wok_item.content_data
	var steak := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	var shabu := ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	_expect(stir.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF and stir.attack_form == ItemData.AttackForm.PROJECTILE and stir.cooking_method == ItemData.CookingMethod.STIR_FRY, "I: existing stir-fry route and projectile/stir-fry tags must remain intact")
	_expect(steak.attack_form == ItemData.AttackForm.MELEE and steak.cooking_method == ItemData.CookingMethod.PAN_FRY and shabu.attack_form == ItemData.AttackForm.TRAP and shabu.cooking_method == ItemData.CookingMethod.BOIL, "I: attack-form and cooking-method tags must be data-driven")
	_expect(scene.get_node_or_null("Kitchen/Sink") != null and scene.get_node_or_null("PlatingController") != null and QuickInventory.SLOT_COUNT == 5, "I: sink/plating/five-slot systems must remain connected")
	await _dispose_scene(scene)


func _forcibly_complete_wave(manager: PrototypeWaveManager, wave_index: int) -> void:
	manager.current_wave = wave_index
	manager.phase = PrototypeWaveManager.Phase.WAVE_ACTIVE
	manager.current_batch = manager.config.get_total_batches(wave_index)
	manager.spawned_total = manager.config.get_planned_enemy_total(wave_index)
	manager.reflavored_total = manager.spawned_total
	manager.active_enemy_count = 0
	manager._check_wave_complete()


func _give_data(player: PrototypePlayer, data: ItemData) -> CarryableItem:
	player.receive_item_data(data)
	var slot := player.inventory.find_item_slot(data.item_type)
	return player.inventory.get_item(slot)


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
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
