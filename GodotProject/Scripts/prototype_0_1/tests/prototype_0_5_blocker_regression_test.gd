extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_a_modal_pause_notes_and_real_persistence()
	await _test_b_cabinet_escape_priority()
	await _test_c_formal_run_reset_boundary()
	await _test_d_player_hold_progress_indicator()
	await _test_e_unplated_stir_fry_combat_rules()
	await _test_f_tomahawk_trigger_and_hit_reliability()
	if failures.is_empty():
		print("PROTOTYPE_0_5_BLOCKER_REGRESSION_TEST: PASS (6/6 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_5_BLOCKER_REGRESSION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_a_modal_pause_notes_and_real_persistence() -> void:
	var scene := await _spawn_main_scene()
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	var audio := root.get_node_or_null("AudioManager") as PrototypeAudioManager
	overlay.set_development_tools_enabled(true)

	await _press_key(KEY_F9)
	_expect(overlay.is_playtest_notes_open() and paused, "A: F9 from gameplay must open notes and pause the world")
	_expect(audio != null and audio.is_music_paused(), "A: notes must pause BGM without changing the current playback state")
	await _press_key(KEY_ESCAPE)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.NONE and not paused, "A: ESC from gameplay notes must close and restore gameplay")
	_expect(audio != null and not audio.is_music_paused(), "A: closing gameplay notes must restore BGM pause state")

	await _press_key(KEY_ESCAPE)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.PAUSE_MENU and paused, "A: ESC must open the pause menu")
	await _press_key(KEY_F9)
	_expect(overlay.is_playtest_notes_open() and paused, "A: F9 from pause must transition into notes while remaining paused")
	await _press_key(KEY_ESCAPE)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.PAUSE_MENU and paused, "A: closing notes opened from pause must return to the pause menu")
	await _press_key(KEY_F9)
	_expect(overlay.is_playtest_notes_open() and paused, "A: pause menu must be able to enter notes repeatedly without duplicate pause ownership")
	await _press_key(KEY_F9)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.PAUSE_MENU and paused, "A: F9 inside notes must close back to the originating pause menu")
	await _press_key(KEY_ESCAPE)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.NONE and not paused, "A: leaving the returned pause menu must not leave the SceneTree permanently paused")

	var real_notes_path := overlay._get_notes_path()
	var original_exists := FileAccess.file_exists(real_notes_path)
	var original_text := ""
	if original_exists:
		var original_file := FileAccess.open(real_notes_path, FileAccess.READ)
		original_text = original_file.get_as_text() if original_file != null else ""
		if original_file != null:
			original_file.close()
	await _press_key(KEY_F9)
	await _type_unicode_text(overlay.note_inputs[0], "中文输入路径测试")
	_expect(overlay.note_inputs[0].text.contains("中文输入路径测试"), "A: focused TextEdit must receive real Unicode key input without global interception")
	overlay.save_notes_button.pressed.emit()
	var saved_file := FileAccess.open(real_notes_path, FileAccess.READ)
	var saved_text := saved_file.get_as_text() if saved_file != null else ""
	if saved_file != null:
		saved_file.close()
	_expect(saved_text.contains("中文输入路径测试") and real_notes_path.ends_with("AI_Context/Playtest_Notes.md"), "A: Save button must append real text to the repository-root AI_Context path")
	_expect(overlay.notes_status_label.text.contains("记录已保存"), "A: successful save must show clear feedback")
	_restore_file(real_notes_path, original_exists, original_text)

	overlay.notes_path_override = ProjectSettings.globalize_path("res://")
	await _type_unicode_text(overlay.note_inputs[0], "失败路径仍可关闭")
	overlay.save_notes_button.pressed.emit()
	_expect(overlay.notes_status_label.text.contains("保存失败") and overlay.is_playtest_notes_open(), "A: a real write failure must report the path while keeping notes open")
	await _press_key(KEY_F9)
	_expect(not paused and overlay.mode == PrototypeToolsOverlay.Mode.NONE, "A: save failure must never trap the player in a hidden permanent pause")

	overlay.set_development_tools_enabled(false)
	await _press_key(KEY_F9)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.NONE and not paused, "A: exported/player mode must ignore the developer notes shortcut")
	await _dispose_scene(scene)


func _test_b_cabinet_escape_priority() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var cabinet_ui := scene.get_node("IngredientCabinetUI") as IngredientCabinetUI
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	cabinet_ui.open_cabinet(cabinet, player)
	await _press_key(KEY_ESCAPE)
	_expect(not cabinet_ui.is_open() and not paused and overlay.mode == PrototypeToolsOverlay.Mode.NONE, "B: first ESC must only close the open cabinet without pausing")
	_expect(not player.modal_ui_open, "B: closing the cabinet must restore player input and mouse ownership")
	await _press_key(KEY_ESCAPE)
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.PAUSE_MENU and paused, "B: second ESC after the cabinet closes must open global pause")
	await _press_key(KEY_ESCAPE)
	await _dispose_scene(scene)


func _test_c_formal_run_reset_boundary() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	var marinating := scene.get_node("Kitchen/MarinatingStation") as MarinatingStation
	var wok_stove := scene.get_node("Kitchen/WokStation") as WokStation
	var pan_stove := scene.get_node("Kitchen/StoveStation2") as WokStation
	var rack := scene.get_node("Kitchen/CookwareRack") as CookwareRack
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	var pile := scene.get_node("Kitchen/CleanPlatePile") as CleanPlatePile
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var stats := scene.get_node("RunStats") as RunStats
	var dummy := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget

	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.SALT))
	player.current_health = 9.0
	player.hit_protection_left = 2.0
	player.action_stun_left = 2.0
	player.global_position += Vector2(300.0, 140.0)
	board.stored_item = _store_item(scene, board, ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK), Vector2.ZERO)
	board.hold_progress.begin(1.0)
	board.hold_progress.elapsed = 0.4
	marinating.meat_item = _store_item(scene, marinating, ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES), Vector2(-20.0, 0.0))
	marinating.marinade_item = _store_item(scene, marinating, ItemCatalog.create(ItemData.ItemType.MARINADE), Vector2(20.0, 0.0))
	marinating.hold_progress.begin(1.0)
	marinating.hold_progress.elapsed = 0.5
	wok_stove.wok_item.add_oil()
	wok_stove.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok_stove.set_burner_on(true)
	(pan_stove.cookware_item as PanItem).add_oil()
	(pan_stove.cookware_item as PanItem).insert_steak(ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
	pan_stove.set_burner_on(true)
	var moved_pot := rack.soup_pot
	rack.soup_pot = null
	moved_pot.release_to_world(scene, Vector2(600.0, 600.0))
	sink.dirty_plate_count = 5
	sink.active_wash_mode = SinkStation.WashMode.PLATES
	sink.hold_progress.begin(1.0)
	sink.hold_progress.elapsed = 0.5
	pile.available_plate_count = 1
	cabinet.request_take(ItemData.ItemType.RAW_BEEF_CHUNK, player)
	var ground_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.MUSTARD))
	scene.add_child(ground_item)
	ground_item.release_to_world(scene, Vector2(720.0, 640.0))
	var trap := ShabuTrap.new()
	trap.setup(ItemCatalog.create(ItemData.ItemType.SHABU_BEEF), combat.config)
	scene.add_child(trap)
	combat.spawn_normal_bull(Vector2(400.0, 400.0), Vector2.RIGHT, 1.0)
	combat.spawn_raging_bull(Vector2(450.0, 400.0), Vector2.RIGHT)
	var tomahawk := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	combat.config.apply_tomahawk_stats(tomahawk)
	combat.spawn_melee_swing(Vector2(500.0, 400.0), Vector2.RIGHT, tomahawk)
	combat.spawn_big_bone(Vector2(550.0, 400.0), Vector2.RIGHT, Callable())
	stats.begin_run()
	stats.record_dish_created()

	_expect(manager.start_service_early(), "C: Start Service must accept the transition from the practice lobby")
	await process_frame
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and is_equal_approx(manager.preparation_left, manager.config.preparation_time), "C: reset must finish directly in the configured formal preparation phase")
	_expect(player.held_item == null and is_equal_approx(player.current_health, manager.config.player_max_health) and player.global_position == player.spawn_position, "C: player health, position, hit state and all five inventory slots must reset")
	_expect(is_zero_approx(player.hit_protection_left) and is_zero_approx(player.action_stun_left) and player.active_interactable == null, "C: hit protection, stun and sustained interaction state must reset")
	_expect(board.stored_item == null and not board.hold_progress.active and marinating.meat_item == null and marinating.marinade_item == null and not marinating.hold_progress.active, "C: cutting and marinating contents/progress must reset")
	_expect(not wok_stove.burner_on and wok_stove.wok_item.content_data == null and not pan_stove.burner_on and (pan_stove.cookware_item as PanItem).content_data == null, "C: both fires, cookware contents and cookware placement must restore to defaults")
	_expect(rack.soup_pot != null and rack.soup_pot.get_parent() == rack, "C: soup pot must return to its initial rack position")
	_expect(sink.dirty_plate_count == 0 and not sink.hold_progress.active and pile.available_plate_count == manager.config.clean_plate_stock, "C: dirty plates, washing progress and clean plate stock must reset")
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == manager.config.raw_beef_stock, "C: cabinet stock must reset to the formal initial values")
	_expect(not is_instance_valid(ground_item) and not is_instance_valid(moved_pot) and not is_instance_valid(trap), "C: lobby ground items, moved cookware instance and shabu traps must be removed")
	_expect(combat.get_children().all(func(child: Node) -> bool: return child is not NormalBull and child is not RagingBull and child is not MeleeSwing and child is not BigBoneProjectile), "C: every temporary attack entity must be cleared")
	var snapshot := stats.get_snapshot()
	_expect(stats.tracking_active and snapshot["dishes_created"] == 0 and is_zero_approx(snapshot["total_damage_dealt"]), "C: formal run statistics must begin from zero")
	_expect(not dummy.lobby_active and not dummy.visible and not dummy.is_in_group("damageable"), "C: test dummies must be disabled for the formal run")

	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.SALT))
	var prepared_item := player.held_item
	manager.force_advance_phase_for_test(manager.preparation_left + 0.01)
	_expect(manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING and player.held_item == prepared_item, "C: formal preparation output must not be reset again when the countdown ends")
	await _dispose_scene(scene)


func _test_d_player_hold_progress_indicator() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	board.stored_item = _store_item(scene, board, ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK), Vector2.ZERO)
	player.global_position = board.global_position
	Input.action_press("interact_primary")
	_expect(board.begin_primary_interaction(player), "D: a valid first cut must begin through the existing HoldProgress")
	player.active_interactable = board
	board.update_primary_interaction(player, board.prototype_first_cut_time * 0.35)
	player._update_hold_progress_indicator()
	_expect(player.hold_progress_bar.visible and is_equal_approx(player.hold_progress_bar.value / 100.0, board.get_progress_ratio()), "D: head progress bar must read the existing station HoldProgress ratio directly")
	var paused_ratio := board.get_progress_ratio()
	await _press_key(KEY_ESCAPE)
	_expect(paused and overlay.is_pause_menu_open() and not player.hold_progress_bar.visible and is_equal_approx(board.get_progress_ratio(), paused_ratio), "D: opening a modal pause must hide the bar without advancing or duplicating progress")
	await process_frame
	_expect(is_equal_approx(board.get_progress_ratio(), paused_ratio), "D: paused world frames must preserve the current hold progress")
	await _press_key(KEY_ESCAPE)
	_expect(not paused and player.hold_progress_bar.visible and board.get_progress_ratio() >= paused_ratio and player.hold_progress_bar.value > 0.0, "D: resuming while E remains held must reveal and continue the existing progress instead of resetting it")
	player._cancel_active_interaction()
	Input.action_release("interact_primary")
	_expect(not player.hold_progress_bar.visible and is_zero_approx(board.get_progress_ratio()), "D: releasing/canceling must immediately hide and reset the discrete hold stage")

	sink.dirty_plate_count = 2
	player.global_position = sink.global_position
	Input.action_press("interact_primary")
	_expect(sink.begin_primary_interaction(player), "D: continuous plate washing must begin through the existing HoldProgress")
	player.active_interactable = sink
	sink.hold_progress.elapsed = sink.locked_plate_wash_duration - 0.01
	player._update_active_interaction(0.02)
	player._update_hold_progress_indicator()
	_expect(sink.dirty_plate_count == 1 and sink.hold_progress.active and player.hold_progress_bar.visible and player.hold_progress_bar.value < 5.0, "D: after one plate, the next plate must start a fresh visible progress round without a second timer")
	player._cancel_active_interaction()
	Input.action_release("interact_primary")
	player.reset_for_new_game(100.0, 0.22)
	_expect(not player.hold_progress_bar.visible and player.active_interactable == null, "D: formal reset must clear the indicator and its active interaction source")
	await _dispose_scene(scene)


func _test_e_unplated_stir_fry_combat_rules() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	manager.start_service_early()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var stove := scene.get_node("Kitchen/WokStation") as WokStation
	stove.set_process(false)
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var attack := player.get_node("DishAttackController") as DishAttackController
	var plating := scene.get_node("PlatingController") as PlatingController
	var stats := scene.get_node("RunStats") as RunStats

	stove.wok_item.add_oil()
	stove.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	stove.set_burner_on(true)
	stove.advance_automatic_cooking(stove.config.automatic_stage_one_time + 0.01)
	stove.wok_item.add_chili()
	stove.advance_automatic_cooking(stove.config.automatic_stage_two_time + 0.01)
	var cooked := stove.wok_item.content_data
	_expect(cooked.is_combat_dish and cooked.current_durability == combat.config.standard_durability and cooked.current_durability == cooked.max_durability, "E: completed unplated stir-fry must immediately receive full combat durability")
	_expect(cooked.quality == ItemData.Quality.NORMAL and not cooked.has_perfect_finisher, "E: an unplated stir-fry may be normal but never perfect or a raging-bull finisher")
	stove.carry_interact(player)
	var unplated := player.held_item
	var normal_before := combat.normal_bulls_spawned
	var raging_before := combat.raging_bulls_spawned
	_expect(attack.fire_once(Vector2.RIGHT), "E: unplated completed stir-fry must directly fire a normal bull")
	_expect(combat.normal_bulls_spawned == normal_before + 1 and combat.raging_bulls_spawned == raging_before, "E: direct unplated use must never spawn the perfect raging bull")
	_expect(unplated.data.has_been_used and not unplated.data.is_eligible_for_plating(), "E: the first durability-consuming attack must permanently remove plating eligibility even on a miss")
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	_expect(not plating.request_start(), "E: a used unplated dish must be rejected by the plating flow")

	player.inventory.clear_all()
	var unused_data := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	combat.config.apply_combat_dish_stats(unused_data)
	player.receive_item_data(unused_data)
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE))
	var dishes_before_plating := stats.dishes_created
	_expect(plating.request_start() and plating.complete_for_test(true), "E: an unused full-durability stir-fry must still be eligible for a clean-plate QTE")
	_expect(player.held_item.data.item_type == ItemData.ItemType.PLATED_STIR_FRY_BEEF and player.held_item.data.quality == ItemData.Quality.PERFECT, "E: clean no-failure QTE perfect may upgrade the plated dish")
	_expect(stats.dishes_created == dishes_before_plating, "E: plating must not record a second dish output")

	player.inventory.clear_all()
	var exhaust_unplated := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	combat.config.apply_combat_dish_stats(exhaust_unplated)
	exhaust_unplated.current_durability = 1
	player.receive_item_data(exhaust_unplated)
	attack.cooldown_left = 0.0
	attack.fire_once(Vector2.RIGHT)
	_expect(player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF) == -1 and player.inventory.find_item_slot(ItemData.ItemType.DIRTY_PLATE) == -1, "E: exhausted unplated stir-fry must disappear without creating a dirty plate")

	var plated_data := ItemCatalog.create(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	combat.config.apply_combat_dish_stats(plated_data)
	plated_data.current_durability = 1
	player.receive_item_data(plated_data)
	attack.cooldown_left = 0.0
	attack.fire_once(Vector2.RIGHT)
	_expect(player.inventory.find_item_slot(ItemData.ItemType.DIRTY_PLATE) != -1, "E: exhausted plated stir-fry must continue to create a dirty plate")

	var flawed := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	flawed.add_failure_tag(ItemData.FailureTag.UNMARINATED)
	combat.config.apply_combat_dish_stats(flawed)
	var mustard := ItemCatalog.create(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	mustard.add_active_modifier(ItemData.ActiveModifier.MUSTARD)
	combat.config.apply_combat_dish_stats(mustard)
	_expect(flawed.quality == ItemData.Quality.FLAWED and not flawed.has_perfect_finisher and mustard.quality == ItemData.Quality.NORMAL and not mustard.has_perfect_finisher, "E: failure tags and mustard must retain their quality branches without granting unplated perfect")
	await _dispose_scene(scene)


func _test_f_tomahawk_trigger_and_hit_reliability() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	manager.start_service_early()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.global_position = Vector2(1400.0, 900.0)
	player.facing_direction = Vector2.RIGHT
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var attack := player.get_node("DishAttackController") as DishAttackController
	var steak_data := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	combat.config.apply_tomahawk_stats(steak_data)
	player.receive_item_data(steak_data)

	var normal_front := manager.spawn_enemy_for_test(player.global_position + Vector2.RIGHT * 90.0)
	var heavy_close := manager.spawn_heavy_enemy_for_test(player.global_position + Vector2.RIGHT * 36.0)
	var swing_origin := player.global_position + Vector2.RIGHT * 26.0
	var normal_edge := manager.spawn_enemy_for_test(swing_origin + Vector2.RIGHT.rotated(deg_to_rad(50.0)) * 90.0)
	var normal_back := manager.spawn_enemy_for_test(player.global_position + Vector2.LEFT * 70.0)
	var normal_far := manager.spawn_enemy_for_test(player.global_position + Vector2.RIGHT * 170.0)
	for enemy in [normal_front, heavy_close, normal_edge, normal_back, normal_far]:
		enemy.set_physics_process(false)
	var front_health := normal_front.current_health
	var close_health := heavy_close.current_health
	var edge_health := normal_edge.current_health
	var back_health := normal_back.current_health
	var far_health := normal_far.current_health
	var swing := combat.spawn_melee_swing(player.global_position + Vector2.RIGHT * 26.0, Vector2.RIGHT, steak_data)
	_expect(swing != null and combat.melee_swings_spawned > 0, "F: every legal tomahawk swing must create an observable attack effect")
	_expect(normal_front.current_health < front_health, "F: a normal enemy centered in front must lose real health")
	_expect(heavy_close.current_health < close_health and heavy_close.knockback_velocity.length() > 0.0 and heavy_close.state == BasicTasteEnemy.State.HIT_STUN, "F: a point-blank heavy enemy must take damage, knockback and sufficient stagger")
	_expect(normal_edge.current_health < edge_health, "F: a collision body visibly covered at the arc edge must be hit")
	_expect(is_equal_approx(normal_back.current_health, back_health), "F: a target truly behind the player must not be hit")
	_expect(is_equal_approx(normal_far.current_health, far_health), "F: a target truly outside range must not be hit")
	swing.queue_free()
	await process_frame

	var moving_target := manager.spawn_enemy_for_test(player.global_position + Vector2.UP * 140.0)
	moving_target.set_physics_process(false)
	var moving_health := moving_target.current_health
	var moving_swing := combat.spawn_melee_swing(player.global_position + Vector2.RIGHT * 26.0, Vector2.RIGHT, steak_data)
	moving_target.global_position = player.global_position + Vector2.RIGHT * 80.0
	await physics_frame
	await physics_frame
	_expect(moving_swing.hit_target_ids.has(moving_target.get_instance_id()) and moving_target.current_health < moving_health, "F: the short active window must catch a target moving into the visible swing after spawn")
	moving_swing.queue_free()
	await process_frame

	var buffered_target := manager.spawn_heavy_enemy_for_test(player.global_position + attack.get_current_aim_direction() * 82.0)
	buffered_target.set_physics_process(false)
	var buffered_health := buffered_target.current_health
	var swing_count_before := combat.melee_swings_spawned
	attack.cooldown_left = 0.08
	await _press_mouse_left()
	for frame in 10:
		await process_frame
	_expect(combat.melee_swings_spawned == swing_count_before + 1 and buffered_target.current_health < buffered_health, "F: a real click near cooldown end must be buffered into one successful damaging swing")
	_expect(attack.attack_buffer_left <= 0.0, "F: a consumed melee buffer must clear instead of turning into held-button auto attack")
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
	Input.action_release("interact_primary")
	Input.action_release("dish_attack")
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _press_key(keycode: int) -> void:
	var pressed_event := InputEventKey.new()
	pressed_event.keycode = keycode
	pressed_event.physical_keycode = keycode
	pressed_event.pressed = true
	root.push_input(pressed_event)
	await process_frame
	var released_event := pressed_event.duplicate() as InputEventKey
	released_event.pressed = false
	root.push_input(released_event)
	await process_frame


func _press_mouse_left() -> void:
	var pressed_event := InputEventMouseButton.new()
	pressed_event.button_index = MOUSE_BUTTON_LEFT
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)
	await process_frame
	var released_event := pressed_event.duplicate() as InputEventMouseButton
	released_event.pressed = false
	Input.parse_input_event(released_event)
	await process_frame


func _type_unicode_text(target: TextEdit, text: String) -> void:
	target.grab_focus()
	await process_frame
	for index in text.length():
		var event := InputEventKey.new()
		event.pressed = true
		event.unicode = text.unicode_at(index)
		root.push_input(event)
		await process_frame


func _store_item(scene: Node, container: Node, data: ItemData, local_position: Vector2) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_stored(container, local_position)
	return item


func _restore_file(path: String, existed: bool, contents: String) -> void:
	if existed:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(contents)
			file.close()
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
