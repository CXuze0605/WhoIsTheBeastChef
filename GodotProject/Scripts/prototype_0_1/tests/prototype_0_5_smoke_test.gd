extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_a_preparation_and_lobby_dummies()
	await _test_b_developer_ui_toggle()
	await _test_c_raging_bull_friendly_fire_risk()
	await _test_d_run_stats_and_summary()
	await _test_e_bgm_flow()
	await _test_f_pause_and_exit_flow()
	await _test_g_playtest_notes()
	await _test_h_enemy_navigation_congestion()
	await _test_i_static_art_batch()
	if failures.is_empty():
		print("PROTOTYPE_0_5_SMOKE_TEST: PASS (9/9 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_5_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_a_preparation_and_lobby_dummies() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var stove := scene.get_node("Kitchen/WokStation") as WokStation
	var dummy := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var countdown := scene.get_node("PreparationCountdownUI") as PreparationCountdownUI
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	stove.set_burner_on(true)
	_expect(manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION and dummy.lobby_active and dummy.visible, "A: initial scene must be a free lobby with test dummies")
	_expect(manager.start_service_early(), "A: Start Service must be accepted from the free lobby")
	countdown._process(0.0)
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and manager.preparation_left >= 30.0, "A: Start Service must enter a visible preparation countdown of at least 30 seconds")
	_expect(countdown.root_control.visible and countdown.countdown_label.text.contains("营业准备"), "A: dedicated preparation countdown must be visible without a blocking modal")
	_expect(player.held_item == null and not stove.burner_on, "A: entering formal preparation must clear isolated lobby inventory and kitchen state")
	_expect(not dummy.lobby_active and not dummy.visible and not dummy.is_in_group("damageable"), "A: lobby test dummies must leave the formal run")
	manager.force_advance_phase_for_test(manager.preparation_left + 0.01)
	_expect(manager.phase == PrototypeWaveManager.Phase.GLOBAL_WARNING and manager.spawned_total == 0, "A: countdown completion must lead to warning before the first enemy spawns")
	await _dispose_scene(scene)


func _test_b_developer_ui_toggle() -> void:
	var scene := await _spawn_main_scene()
	var debug_ui := scene.get_node("DebugUI") as PrototypeDebugUI
	_expect(InputMap.has_action("toggle_debug_ui") and not InputMap.action_get_events("toggle_debug_ui").is_empty(), "B: developer UI toggle must have a configured shortcut")
	var shortcut_text := InputMap.action_get_events("toggle_debug_ui")[0].as_text()
	_expect(shortcut_text.contains("F3"), "B: the configured developer UI shortcut must be F3")
	_expect(debug_ui.is_developer_ui_visible(), "B: developer UI may remain visible by default")
	debug_ui.set_developer_ui_visible(false)
	_expect(not debug_ui.is_developer_ui_visible(), "B: player mode must hide the developer text panel")
	debug_ui.set_developer_ui_visible(true)
	_expect(debug_ui.is_developer_ui_visible(), "B: developer information must remain available after toggling back")
	await _dispose_scene(scene)


func _test_c_raging_bull_friendly_fire_risk() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	var bull := combat.spawn_raging_bull(player.global_position, Vector2.RIGHT)
	bull.global_position = player.global_position
	var health_before := player.current_health
	bull._hit_targets_with_cooldown()
	var expected_health := health_before - combat.config.raging_bull_friendly_fire_damage
	_expect(is_equal_approx(player.current_health, expected_health), "C: friendly targets must use the lower dedicated raging-bull damage")
	player.hit_protection_left = 0.0
	bull.target_cooldowns.clear()
	bull._hit_targets_with_cooldown()
	_expect(is_equal_approx(player.current_health, expected_health), "C: one raging bull must not repeatedly damage the same friendly target")
	hud._process(0.0)
	_expect(hud.danger_panel.visible, "C: nearby raging bull must show an obvious player-facing friendly-fire warning")
	var enemy := manager.spawn_enemy_for_test(player.global_position + Vector2(10.0, 0.0))
	bull.global_position = enemy.global_position
	bull.target_cooldowns.clear()
	var enemy_health_before := enemy.current_health
	bull._hit_targets_with_cooldown()
	_expect(is_equal_approx(enemy.current_health, enemy_health_before - combat.config.raging_bull_damage), "C: enemy damage must retain the full raging-bull value")
	await _dispose_scene(scene)


func _test_d_run_stats_and_summary() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var stats := scene.get_node("RunStats") as RunStats
	var summary := scene.get_node("RunSummaryUI") as RunSummaryUI
	manager.start_service_early()

	var wok := scene.get_node("Kitchen/WokStation").wok_item as WokItem
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.complete_stage_one()
	wok.add_chili()
	wok.complete_stage_two()
	var pan := scene.get_node("Kitchen/StoveStation2").cookware_item as PanItem
	pan.add_oil()
	pan.insert_steak(ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
	pan.complete_steak()
	var pot := scene.get_node("Kitchen/CookwareRack").soup_pot as SoupPotItem
	pot.fill_water()
	pot.mark_boiling()
	pot.insert_slice(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	pot.complete_slice()

	var normal := manager.spawn_enemy_for_test(Vector2(1500.0, 900.0))
	normal.receive_combat_hit(999.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 0.0, false)
	var heavy := manager.spawn_heavy_enemy_for_test(Vector2(1600.0, 900.0))
	heavy.receive_combat_hit(999.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 0.0, false)
	var friendly := scene.get_node("Kitchen/FriendlyDummy") as DebugCombatTarget
	friendly.set_lobby_active(true)
	friendly.current_health = 10.0
	friendly.receive_combat_hit(30.0, CombatRules.Faction.PLAYER, Vector2.RIGHT, 0.0, true)
	var snapshot := stats.get_snapshot()
	_expect(snapshot["dishes_created"] == 3, "D: completed wok, pan and soup dishes must feed the shared run statistic")
	_expect(is_equal_approx(snapshot["total_damage_dealt"], manager.config.enemy_max_health + manager.config.heavy_max_health), "D: total damage must use actual enemy health removed rather than requested overkill")
	_expect(snapshot["basic_enemies_defeated"] == 1 and snapshot["special_enemies_defeated"] == 1, "D: normal and heavy defeat counts must be separated")
	_expect(is_equal_approx(snapshot["friendly_fire_damage"], 10.0) and snapshot["teammates_knocked_down"] == 1, "D: actual friendly damage and friendly knockdowns must be tracked")

	manager._finish_run(true)
	summary._process(0.0)
	_expect(summary.root_control.visible and summary.title_label.text == "成功防守" and summary.stats_label.text.contains("制作料理数量：3"), "D: successful defense must open the statistics summary")
	summary._on_end_run_pressed()
	summary._process(0.0)
	_expect(manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION and not summary.root_control.visible and not stats.tracking_active, "D: End Run must return to a reset free lobby")
	_expect(friendly.lobby_active and friendly.visible, "D: returning to the lobby must restore test dummies")
	manager.start_service_early()
	manager._finish_run(false)
	summary._process(0.0)
	_expect(summary.root_control.visible and summary.title_label.text == "厨房失守", "D: failed defense must use the same summary flow with the failure title")
	await _dispose_scene(scene)


func _test_e_bgm_flow() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var audio := root.get_node_or_null("AudioManager") as PrototypeAudioManager
	_expect(audio != null, "E: one autoload AudioManager must own the BGM players")
	if audio == null:
		await _dispose_scene(scene)
		return

	_expect(audio.get_current_track() == PrototypeAudioManager.Track.LOBBY, "E: the free lobby must select the lobby theme")
	var track_events: Array[int] = []
	var track_listener := func(track: int): track_events.append(track)
	audio.track_changed.connect(track_listener)
	manager.start_service_early()
	_expect(audio.get_current_track() == PrototypeAudioManager.Track.BATTLE, "E: formal cooking preparation must switch to the battle theme immediately")
	for uninterrupted_phase in [
		PrototypeWaveManager.Phase.GLOBAL_WARNING,
		PrototypeWaveManager.Phase.LOCAL_WARNING,
		PrototypeWaveManager.Phase.SPAWNING,
		PrototypeWaveManager.Phase.WAVE_ACTIVE,
		PrototypeWaveManager.Phase.LOCAL_WARNING,
		PrototypeWaveManager.Phase.SPAWNING,
		PrototypeWaveManager.Phase.INTERMISSION,
		PrototypeWaveManager.Phase.GLOBAL_WARNING,
	]:
		manager.phase = uninterrupted_phase
		manager.wave_stats_changed.emit()
		_expect(audio.get_current_track() == PrototypeAudioManager.Track.BATTLE, "E: warnings, small batches and intermission must keep one continuous battle theme")
	_expect(track_events.count(PrototypeAudioManager.Track.BATTLE) == 1, "E: repeated small-batch flow updates must not restart or re-request the battle track")

	manager._finish_run(true)
	_expect(audio.get_current_track() == PrototypeAudioManager.Track.VICTORY, "E: successful defense must switch from battle to the victory theme")
	manager.return_to_lobby()
	_expect(audio.get_current_track() == PrototypeAudioManager.Track.LOBBY, "E: ending a run must restore the lobby theme")
	manager.start_service_early()
	manager._finish_run(false)
	_expect(audio.get_current_track() == PrototypeAudioManager.Track.DEFEAT, "E: failed defense must switch to the defeat theme")
	_expect(audio.default_fade_seconds > 0.0, "E: music changes must keep a non-zero fade interface")
	for track in [PrototypeAudioManager.Track.LOBBY, PrototypeAudioManager.Track.BATTLE, PrototypeAudioManager.Track.VICTORY, PrototypeAudioManager.Track.DEFEAT]:
		var stream := audio.get_track_stream(track)
		_expect(stream is AudioStreamMP3 and (stream as AudioStreamMP3).loop, "E: every Prototype BGM stream must loop by default")
	audio.track_changed.disconnect(track_listener)
	audio.stop_music(0.0)
	await _dispose_scene(scene)


func _test_f_pause_and_exit_flow() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	var audio := root.get_node_or_null("AudioManager") as PrototypeAudioManager
	_expect(InputMap.has_action("toggle_pause") and not InputMap.action_get_events("toggle_pause").is_empty(), "F: ESC pause must have a configured semantic input action")
	_expect(InputMap.action_get_events("toggle_pause")[0].as_text().contains("Escape"), "F: the pause shortcut must be ESC")
	manager.start_service_early()
	var preparation_before := manager.preparation_left
	overlay.open_pause_menu()
	_expect(paused and overlay.is_pause_menu_open() and overlay.is_world_paused_by_overlay(), "F: opening the pause menu must pause the SceneTree while keeping the overlay active")
	_expect(audio != null and audio.is_music_paused(), "F: BGM playback must pause without changing tracks")
	await process_frame
	await process_frame
	_expect(is_equal_approx(manager.preparation_left, preparation_before), "F: preparation and wave clocks must not advance while paused")
	overlay.close_overlay()
	_expect(not paused and not overlay.is_pause_menu_open(), "F: continue must restore gameplay processing")
	_expect(audio != null and not audio.is_music_paused(), "F: continuing must resume the existing BGM state")

	var enemy := manager.spawn_enemy_for_test(Vector2(1500.0, 900.0))
	overlay.open_pause_menu()
	overlay.show_exit_confirmation()
	_expect(overlay.mode == PrototypeToolsOverlay.Mode.EXIT_CONFIRMATION and paused, "F: Exit Run must require a confirmation while the game remains paused")
	overlay.confirm_exit_to_lobby()
	_expect(manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION and not paused, "F: confirming Exit Run must reuse the lobby reset path and unpause the tree")
	await process_frame
	_expect(not is_instance_valid(enemy), "F: confirming Exit Run must clean enemies from the abandoned run")
	await _dispose_scene(scene)


func _test_g_playtest_notes() -> void:
	var scene := await _spawn_main_scene()
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	var test_path := "user://prototype_0_5_playtest_notes_test.md"
	var absolute_test_path := ProjectSettings.globalize_path(test_path)
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(absolute_test_path)
	overlay.set_development_tools_enabled(true)
	overlay.notes_path_override = test_path
	_expect(InputMap.has_action("toggle_playtest_notes") and not InputMap.action_get_events("toggle_playtest_notes").is_empty(), "G: playtest notes must have a configured developer shortcut")
	_expect(InputMap.action_get_events("toggle_playtest_notes")[0].as_text().contains("F9"), "G: the playtest notes shortcut must be F9")
	_expect(overlay.open_playtest_notes() and paused and overlay.is_playtest_notes_open(), "G: the developer notes panel must pause gameplay while typing")
	overlay.note_inputs[0].text = "第一项自动化试玩问题"
	overlay.note_inputs[1].text = "第二项自动化试玩问题"
	_expect(overlay.save_playtest_notes(), "G: at least one entered issue must be persisted")
	var file := FileAccess.open(test_path, FileAccess.READ)
	var saved_text := file.get_as_text() if file != null else ""
	if file != null:
		file.close()
	_expect(saved_text.contains("Prototype 0.5") and saved_text.contains("第一项自动化试玩问题") and saved_text.contains("第二项自动化试玩问题"), "G: saved Markdown must include version and entered issues")
	overlay.close_overlay()
	_expect(not paused and not overlay.is_playtest_notes_open(), "G: closing the developer notes panel must resume the previous gameplay state")
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(absolute_test_path)
	await _dispose_scene(scene)


func _test_h_enemy_navigation_congestion() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var navigation := scene.get_node("KitchenNavigation") as KitchenNavigationGrid
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	player.global_position = Vector2(1400.0, 900.0)

	var heavy := manager.spawn_heavy_enemy_for_test(Vector2(180.0, 600.0))
	var collision := heavy.get_child(0) as CollisionShape2D
	var heavy_shape := collision.shape as CircleShape2D
	_expect(heavy_shape != null and is_equal_approx(heavy_shape.radius, heavy.enemy_collision_radius), "H: heavy runtime collision must use its configured larger body radius")
	_expect(navigation.agent_radius >= heavy.enemy_collision_radius, "H: static navigation clearance must fit the heavy enemy body")
	_expect((heavy.collision_mask & 1) != 0 and (heavy.collision_mask & 2) != 0 and (heavy.collision_mask & 4) == 0, "H: enemies must still collide with world/player without hard-blocking each other")

	var normal_a := manager.spawn_enemy_for_test(Vector2(184.0, 604.0))
	var normal_b := manager.spawn_enemy_for_test(Vector2(188.0, 608.0))
	_expect(normal_a.get_chase_goal_position().distance_to(normal_b.get_chase_goal_position()) > 1.0, "H: enemies pursuing one player must receive distinct local chase goals")
	var heavy_path := navigation.find_path(heavy.global_position, heavy.get_chase_goal_position())
	_expect(not heavy_path.is_empty(), "H: heavy enemies must retain a legal route through the kitchen layout")
	for waypoint in heavy_path:
		for obstacle_node in get_nodes_in_group("kitchen_obstacle"):
			var obstacle := obstacle_node as KitchenObstacle
			_expect(not obstacle.get_navigation_rect(heavy.enemy_collision_radius).has_point(waypoint), "H: heavy path waypoints must respect heavy-body facility clearance")

	var start_position := heavy.global_position
	for step in 100:
		await physics_frame
	var heavy_progress := heavy.global_position.distance_to(start_position)
	_expect(heavy_progress > 30.0, "H: a heavy enemy in a close crowd must continue progressing toward the player (progress %.1f, recoveries %d)" % [heavy_progress, heavy.stuck_recovery_count])

	var recovery_before := heavy.stuck_recovery_count
	heavy._update_stuck_tracking(heavy.global_position, Vector2.RIGHT, manager.config.stuck_repath_time + 0.01, true)
	_expect(heavy.stuck_recovery_count == recovery_before + 1 and heavy.chase_refresh_left == 0.0 and heavy.unstuck_steer_left > 0.0, "H: prolonged no-motion must force a repath and temporary lateral recovery steer")
	await _dispose_scene(scene)


func _test_i_static_art_batch() -> void:
	var expected_keys: Array[StringName] = [
		&"normal_bull", &"raging_bull", &"enemy_dummy", &"friendly_dummy",
		&"raw_beef_chunk", &"raw_steak", &"raw_beef_slice_single", &"raw_beef_slices",
		&"shabu_beef_single", &"shabu_beef_slices", &"clean_plate_stack",
	]
	for art_key in expected_keys:
		var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
		_expect(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "I: art catalog must load %s" % art_key)

	var raw_chunk := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK)
	var raw_slices := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES)
	var shabu := ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	_expect(ItemCatalog.get_art_key_for_data(raw_chunk) == &"raw_beef_chunk", "I: raw beef chunk must use its dedicated art")
	_expect(ItemCatalog.get_art_key_for_data(raw_slices) == &"raw_beef_slices", "I: a full raw-slice portion must use grouped art")
	raw_slices.remaining_portions = 1
	_expect(ItemCatalog.get_art_key_for_data(raw_slices) == &"raw_beef_slice_single", "I: the last raw slice must switch to single-slice art")
	shabu.stack_count = 4
	_expect(ItemCatalog.get_art_key_for_data(shabu) == &"shabu_beef_slices", "I: stacked shabu beef must use grouped art")
	shabu.stack_count = 1
	_expect(ItemCatalog.get_art_key_for_data(shabu) == &"shabu_beef_single", "I: one shabu serving must use single-slice art")

	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var player_art := scene.get_node("Kitchen/Player/PlayerArt") as Sprite2D
	var plate_pile := scene.get_node("Kitchen/CleanPlatePile") as CleanPlatePile
	var enemy_dummy := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var friendly_dummy := scene.get_node("Kitchen/FriendlyDummy") as DebugCombatTarget
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var hotbar := scene.get_node("QuickInventoryUI") as QuickInventoryUI
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var cabinet_ui := scene.get_node("IngredientCabinetUI") as IngredientCabinetUI
	var normal_bull := combat.spawn_normal_bull(Vector2(300.0, 300.0), Vector2.RIGHT, 10.0)
	var raging_bull := combat.spawn_raging_bull(Vector2(500.0, 300.0), Vector2.RIGHT)
	var raw_slice_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	scene.add_child(raw_slice_item)
	var shabu_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.SHABU_BEEF))
	shabu_item.data.stack_count = 4
	scene.add_child(shabu_item)
	_expect(
		player.walk_animator != null
		and player_art.texture != null
		and player_art.texture.resource_path.ends_with("player_walk_sheet.png")
		and player_art.hframes == 4
		and player_art.vframes == 3,
		"I: the actual player node must use the new 4x3 chef walk animation sheet"
	)
	_expect(plate_pile.placeholder.has_art, "I: the clean plate pile must display the replacement stack art")
	_expect(enemy_dummy.placeholder.has_art and friendly_dummy.placeholder.has_art, "I: both lobby dummy factions must display dedicated art")
	_expect(enemy_dummy.placeholder.art_sprite.texture != friendly_dummy.placeholder.art_sprite.texture, "I: enemy and friendly dummies must remain visually distinct")
	_expect(normal_bull.visual.has_art and raging_bull.visual.has_art, "I: both stir-fry bull attack forms must display their new art")
	_expect(raw_slice_item.placeholder.art_sprite.texture.resource_path.ends_with("raw_beef_slices.png"), "I: carried multi-portion raw slices must display grouped art")
	raw_slice_item.data.remaining_portions = 1
	raw_slice_item.refresh_visual()
	_expect(raw_slice_item.placeholder.art_sprite.texture.resource_path.ends_with("raw_beef_slice_single.png"), "I: carried final raw slice must refresh to single art")
	shabu_item.refresh_visual()
	_expect(shabu_item.placeholder.art_sprite.texture.resource_path.ends_with("shabu_beef_slices.png"), "I: carried stacked shabu must display grouped art")
	shabu_item.data.stack_count = 1
	shabu_item.refresh_visual()
	_expect(shabu_item.placeholder.art_sprite.texture.resource_path.ends_with("shabu_beef_single.png"), "I: carried final shabu serving must refresh to single art")
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	hotbar._process(0.0)
	_expect(hotbar.slot_icons.size() == QuickInventory.SLOT_COUNT and hotbar.slot_icons[0].texture != null, "I: the five-slot hotbar must render available item art")
	_expect(not hotbar.slot_labels[0].text.contains("整块生牛肉"), "I: an illustrated hotbar item must not fall back to a text-only name")
	cabinet_ui.open_cabinet(cabinet, player)
	_expect(cabinet_ui.stock_icons.size() == cabinet.get_supported_item_types().size(), "I: every cabinet stock row must include an image area")
	_expect((cabinet_ui.stock_icons[ItemData.ItemType.RAW_BEEF_CHUNK] as TextureRect).texture != null, "I: cabinet stock must display available ingredient art")
	_expect(cabinet_ui.inventory_icons[0].texture != null, "I: the cabinet panel must render the player's inventory with item art")
	cabinet_ui.close_cabinet()

	var trap := ShabuTrap.new()
	trap.setup(ItemCatalog.create(ItemData.ItemType.SHABU_BEEF), combat.config)
	scene.add_child(trap)
	_expect(trap.placeholder.has_art and trap.placeholder.art_sprite.texture.resource_path.ends_with("shabu_beef_single.png"), "I: placed shabu trap must display single-slice art")
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
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
