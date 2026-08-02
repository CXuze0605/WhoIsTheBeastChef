extends SceneTree

const MENU_SCENE := "res://Scenes/menu/main_menu.tscn"
const GAME_SCENE := "res://Scenes/prototype_0_1/main.tscn"
const TEST_SETTINGS_PATH := "user://automated_tests/main_menu_settings.cfg"

var failures: PackedStringArray = []
var settings: GameSettingsManager
var session: AppSessionState
var original_settings: Dictionary


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	settings = root.get_node_or_null("SettingsManager") as GameSettingsManager
	session = root.get_node_or_null("AppSession") as AppSessionState
	_expect(settings != null and session != null, "bootstrap: settings and session autoloads must exist")
	if settings == null or session == null:
		_finish()
		return
	original_settings = settings.get_snapshot()
	settings.set_settings_path_override_for_test(TEST_SETTINGS_PATH)
	_remove_test_settings()

	await _test_main_menu_structure_and_modals()
	await _test_settings_audio_capture_conflicts_and_persistence()
	await _test_launch_modes_share_gameplay()
	await _test_pause_settings_and_return_to_menu()
	await _test_dynamic_input_prompts()

	settings._apply_snapshot(original_settings)
	settings.set_settings_path_override_for_test("")
	_remove_test_settings()
	session.clear_launch_mode()
	paused = false
	_finish()


func _test_main_menu_structure_and_modals() -> void:
	_expect(ProjectSettings.get_setting("application/run/main_scene") == MENU_SCENE, "menu: project startup scene must be the main menu")
	var menu := await _spawn_scene(MENU_SCENE) as MainMenu
	var expected := {
		"SinglePlayerButton": "单机游戏",
		"MultiplayerButton": "联机游戏",
		"TestHallButton": "测试大厅",
		"SettingsButton": "设置",
		"ExitButton": "退出游戏",
	}
	for node_name in expected:
		var button := menu.find_child(node_name, true, false) as Button
		_expect(button != null and button.text == expected[node_name], "menu: %s must exist with the expected label" % node_name)
	await process_frame
	_expect(menu.get_viewport().gui_get_focus_owner() == menu.single_player_button, "menu: single player must receive default focus")

	await _press_key(KEY_S)
	_expect(menu.get_viewport().gui_get_focus_owner() == menu.multiplayer_button, "menu: W/S must move keyboard focus")
	await _press_key(KEY_ENTER)
	_expect(menu.online_modal.visible, "menu: multiplayer must open a modal instead of starting networking")
	var online_text := _collect_label_text(menu.online_modal)
	_expect(online_text.contains("四人联机功能开发中") and online_text.contains("计划支持1—4名玩家"), "menu: multiplayer modal must promise 1-4 players, not two-player networking")
	await _press_key(KEY_ESCAPE)
	_expect(not menu.online_modal.visible and not menu.exit_modal.visible, "menu: ESC must close the multiplayer modal without opening exit confirmation")
	await _press_key(KEY_SPACE)
	_expect(menu.online_modal.visible, "menu: Space must confirm the focused button")
	await _press_key(KEY_ESCAPE)
	await _press_key(KEY_W)
	_expect(menu.get_viewport().gui_get_focus_owner() == menu.single_player_button, "menu: W must move focus back toward single player")

	await _press_key(KEY_ESCAPE)
	_expect(menu.exit_modal.visible, "menu: bare ESC must open exit confirmation")
	await _press_key(KEY_ESCAPE)
	_expect(not menu.exit_modal.visible, "menu: ESC must cancel exit confirmation and never quit directly")

	menu.settings_button.pressed.emit()
	_expect(menu.settings_panel.visible and not paused, "menu: shared settings panel must open without pausing the menu")
	await _press_key(KEY_ESCAPE)
	_expect(not menu.settings_panel.visible and menu.get_viewport().gui_get_focus_owner() == menu.settings_button, "menu: ESC must cancel settings and restore Settings button focus")
	await _dispose_scene(menu)


func _test_settings_audio_capture_conflicts_and_persistence() -> void:
	var panel_scene := load("res://Scenes/menu/settings_panel.tscn") as PackedScene
	var panel := panel_scene.instantiate() as SettingsPanel
	root.add_child(panel)
	await process_frame
	panel.open_panel("设置测试")
	var opening_snapshot := settings.get_snapshot()
	var defaults_button := panel.find_child("RestoreDefaultsButton", true, false) as Button
	defaults_button.pressed.emit()
	_expect(panel.defaults_dialog.visible and panel.defaults_dialog.dialog_text.contains("仍需点击“应用”"), "settings: Restore Defaults must require confirmation and remain unapplied")
	panel._on_defaults_confirmed()
	_expect(
		is_equal_approx(float(panel.get_working_snapshot_for_test().master_volume), 100.0)
			and _snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"move_up") == "W",
		"settings: confirmed Restore Defaults must load project.godot defaults into the working copy"
	)
	_expect(
		GameSettingsManager.EDITABLE_ACTIONS.has(&"sprint")
			and _snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"sprint").contains("Shift"),
		"settings: sprint must be remappable and default to Shift"
	)

	panel.master_slider.value = 0.0
	panel.music_slider.value = 37.0
	panel.sfx_slider.value = 42.0
	panel._on_volume_changed(0.0)
	var master_bus := AudioServer.get_bus_index(&"Master")
	var music_bus := AudioServer.get_bus_index(&"Music")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	var audio := root.get_node_or_null("AudioManager") as PrototypeAudioManager
	_expect(master_bus >= 0 and music_bus >= 0 and sfx_bus >= 0, "settings: Master, Music and SFX buses must exist")
	_expect(audio != null and audio._player_a.bus == &"Music" and audio._player_b.bus == &"Music", "settings: both existing BGM players must share the Music bus")
	_expect(AudioServer.is_bus_mute(master_bus), "settings: zero Master preview must actually mute the Master bus")
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), linear_to_db(0.37)), "settings: Music slider must control the Music bus in decibels")
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), linear_to_db(0.42)), "settings: SFX slider must control the SFX bus in decibels")
	panel.cancel_and_close()
	_expect(not AudioServer.is_bus_mute(master_bus), "settings: Cancel must roll back the live volume preview")
	_expect(is_equal_approx(settings.master_volume, float(opening_snapshot.master_volume)), "settings: Cancel must not alter applied values")

	panel.open_panel("设置测试")
	panel.begin_capture_for_test(&"move_up")
	await _press_key(KEY_ESCAPE)
	_expect(not panel.is_capturing_binding(), "settings: ESC must cancel key capture instead of becoming a binding")
	_expect(_snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"move_up") == _snapshot_first_event_text(opening_snapshot, &"move_up"), "settings: canceled capture must preserve the old key")

	panel.begin_capture_for_test(&"move_up")
	await _press_key(KEY_F8)
	_expect(panel.is_capturing_binding() and panel.status_label.text.contains("不能绑定"), "settings: F8 must be rejected with a visible reason")
	await _press_key(KEY_ESCAPE)

	panel.begin_capture_for_test(&"dish_attack")
	await _press_mouse_button(MOUSE_BUTTON_XBUTTON1)
	_expect(_snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"dish_attack") == "Mouse Button 4", "settings: common mouse buttons must be accepted and shown with readable text")

	var interact_before := _snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"interact_primary")
	panel.begin_capture_for_test(&"interact_primary")
	await _press_key(KEY_F)
	_expect(panel.conflict_dialog.visible and panel.conflict_dialog.dialog_text.contains("搬取 / 次级交互"), "settings: duplicate bindings must show the conflicting action")
	panel._cancel_conflict_binding()
	_expect(_snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"interact_primary") == interact_before, "settings: canceling a conflict must keep the original binding")
	panel.begin_capture_for_test(&"interact_primary")
	await _press_key(KEY_F)
	panel._confirm_conflict_binding()
	_expect(_snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"interact_primary") == "F", "settings: explicitly confirmed duplicate binding must be retained")
	_expect(_snapshot_first_event_text(panel.get_working_snapshot_for_test(), &"interact_carry") == "F", "settings: confirming a duplicate must not silently erase the other action")

	panel.master_slider.value = 64.0
	panel.music_slider.value = 53.0
	panel.sfx_slider.value = 42.0
	panel._on_volume_changed(0.0)
	var apply_button := panel.find_child("ApplyButton", true, false) as Button
	apply_button.pressed.emit()
	_expect(FileAccess.file_exists(TEST_SETTINGS_PATH) and panel.status_label.text.contains("设置已保存"), "settings: Apply button must save to the configured ConfigFile path")
	settings.master_volume = 100.0
	settings.music_volume = 100.0
	settings.sfx_volume = 100.0
	_expect(settings.load_settings() == OK, "settings: saved ConfigFile must load on restart path")
	_expect(is_equal_approx(settings.master_volume, 64.0) and is_equal_approx(settings.music_volume, 53.0) and is_equal_approx(settings.sfx_volume, 42.0), "settings: all three applied volumes must survive reload")
	_expect(InputPrompt.action_text(&"dish_attack") == "Mouse Button 4", "settings: applied mouse binding must survive reload")

	var broken := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	if broken != null:
		broken.store_string("[this is not a valid config")
		broken.close()
	var broken_error := settings.load_settings()
	_expect(broken_error != OK and is_equal_approx(settings.master_volume, 100.0), "settings: corrupted files must warn and safely restore defaults")

	var partial := ConfigFile.new()
	partial.set_value("meta", "version", 1)
	partial.set_value("audio", "master", 25.0)
	_expect(partial.save(TEST_SETTINGS_PATH) == OK, "settings: partial test configuration must be writable")
	_expect(settings.load_settings() == OK, "settings: incomplete but valid configuration must load")
	_expect(is_equal_approx(settings.master_volume, 25.0) and is_equal_approx(settings.music_volume, 100.0) and is_equal_approx(settings.sfx_volume, 100.0), "settings: missing fields must use project defaults")

	panel.queue_free()
	await process_frame
	settings._apply_snapshot(original_settings)


func _test_launch_modes_share_gameplay() -> void:
	session.set_launch_mode(AppSessionState.LaunchMode.SINGLE_PLAYER)
	var single_scene := await _spawn_scene(GAME_SCENE)
	await process_frame
	await process_frame
	var single_manager := single_scene.get_node("WaveManager") as PrototypeWaveManager
	var single_cabinet := single_scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var single_dummy := single_scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	_expect(single_manager.phase == PrototypeWaveManager.Phase.PREPARATION, "launch: single player must reuse the existing formal reset and enter PREPARATION")
	_expect(not single_cabinet.lobby_unlimited and single_cabinet.storage.width == 10 and single_cabinet.storage.height == 8, "launch: single player must use finite formal cabinet storage")
	_expect(not single_dummy.lobby_active and not single_dummy.visible, "launch: single player must hide and disable test dummies")
	_expect(single_manager.preparation_left <= single_manager.config.preparation_time and single_manager.preparation_left > single_manager.config.preparation_time - 1.0, "launch: single player must start the configured formal preparation countdown")
	await _dispose_scene(single_scene)

	session.set_launch_mode(AppSessionState.LaunchMode.TEST_HALL)
	var hall_scene := await _spawn_scene(GAME_SCENE)
	var hall_manager := hall_scene.get_node("WaveManager") as PrototypeWaveManager
	var hall_cabinet := hall_scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var hall_dummy := hall_scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	var hall_tools := hall_scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	_expect(hall_manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION, "launch: Test Hall must remain in FREE_PREPARATION")
	_expect(hall_cabinet.lobby_unlimited and hall_cabinet.storage.width == 20 and hall_cabinet.storage.height == 40, "launch: Test Hall must retain the 20x40 infinite catalog")
	_expect(hall_dummy.lobby_active and hall_dummy.visible and hall_tools.development_tools_enabled, "launch: Test Hall must retain dummies and F3/F9 developer tools")
	await _dispose_scene(hall_scene)

	session.clear_launch_mode()
	var direct_scene := await _spawn_scene(GAME_SCENE)
	var direct_manager := direct_scene.get_node("WaveManager") as PrototypeWaveManager
	_expect(direct_manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION, "launch: directly running main.tscn must preserve historical free-lobby test behavior")
	await _dispose_scene(direct_scene)


func _test_pause_settings_and_return_to_menu() -> void:
	session.clear_launch_mode()
	var scene := await _spawn_scene(GAME_SCENE)
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	var audio := root.get_node_or_null("AudioManager") as PrototypeAudioManager
	await _press_key(KEY_ESCAPE)
	_expect(paused and overlay.mode == PrototypeToolsOverlay.Mode.PAUSE_MENU, "pause: ESC must still open the single existing pause owner")
	overlay.settings_button.pressed.emit()
	_expect(paused and overlay.mode == PrototypeToolsOverlay.Mode.SETTINGS and overlay.settings_panel.visible, "pause: shared settings must remain operable while the world is paused")
	await _press_key(KEY_ESCAPE)
	_expect(paused and overlay.mode == PrototypeToolsOverlay.Mode.PAUSE_MENU and not overlay.settings_panel.visible, "pause: closing settings must return to pause menu without resuming")
	await _press_key(KEY_ESCAPE)
	_expect(not paused and overlay.mode == PrototypeToolsOverlay.Mode.NONE, "pause: only closing the pause menu may resume gameplay")

	await _press_key(KEY_ESCAPE)
	overlay.show_exit_confirmation()
	overlay.confirm_exit_to_lobby()
	await process_frame
	await process_frame
	_expect(not paused and current_scene is MainMenu, "pause: confirmed Exit Run must cleanly change to the new main menu")
	_expect(audio == null or not audio.is_music_paused(), "pause: returning to menu must never leave BGM paused")
	if current_scene != null:
		await _dispose_scene(current_scene)


func _test_dynamic_input_prompts() -> void:
	var restore := settings.get_snapshot()
	var remapped := settings.get_snapshot()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_P
	settings.replace_action_binding_in_snapshot(remapped, &"interact_primary", key)
	settings._apply_snapshot(remapped)
	var board := CuttingBoard.new()
	root.add_child(board)
	await process_frame
	var item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	root.add_child(item)
	item.set_stored(board, Vector2.ZERO)
	board.stored_item = item
	_expect(board.get_primary_prompt(null).contains("P"), "prompts: visible station prompts must read the current InputMap binding")
	board.queue_free()
	await process_frame
	settings._apply_snapshot(restore)


func _spawn_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	paused = false
	if current_scene == scene:
		current_scene = null
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	await process_frame
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


func _press_mouse_button(button_index: int) -> void:
	var pressed_event := InputEventMouseButton.new()
	pressed_event.button_index = button_index
	pressed_event.pressed = true
	root.push_input(pressed_event)
	await process_frame
	var released_event := pressed_event.duplicate() as InputEventMouseButton
	released_event.pressed = false
	root.push_input(released_event)
	await process_frame


func _snapshot_first_event_text(snapshot: Dictionary, action: StringName) -> String:
	var bindings: Dictionary = snapshot.get("bindings", {})
	var events: Array = bindings.get(action, [])
	return InputPrompt.event_text(events[0]) if not events.is_empty() else ""


func _collect_label_text(node: Node) -> String:
	var texts: PackedStringArray = []
	for child in node.find_children("*", "Label", true, false):
		texts.append((child as Label).text)
	return "\n".join(texts)


func _remove_test_settings() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PROTOTYPE_MAIN_MENU_SETTINGS_TEST: PASS (5/5 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_MAIN_MENU_SETTINGS_TEST: FAIL (%d)" % failures.size())
	quit(1)
