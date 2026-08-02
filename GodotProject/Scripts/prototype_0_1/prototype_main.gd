extends Node2D

var wave_manager: PrototypeWaveManager
var audio_manager: PrototypeAudioManager
var tools_overlay: PrototypeToolsOverlay


func _ready() -> void:
	var player := get_node_or_null("Kitchen/Player") as PrototypePlayer
	if player != null:
		player.notify_feedback("Prototype：%s 暂停；F3 切换开发 UI；F9 记录试玩问题。" % InputPrompt.action_text(&"toggle_pause", "ESC"))
	wave_manager = get_node_or_null("WaveManager") as PrototypeWaveManager
	audio_manager = get_node_or_null("/root/AudioManager") as PrototypeAudioManager
	tools_overlay = get_node_or_null("PrototypeToolsOverlay") as PrototypeToolsOverlay
	if tools_overlay != null:
		tools_overlay.exit_run_confirmed.connect(_on_exit_run_confirmed)
	if wave_manager != null:
		wave_manager.wave_stats_changed.connect(_sync_music_to_flow)
	_sync_music_to_flow()
	var session := get_node_or_null("/root/AppSession") as AppSessionState
	var launch_mode := session.consume_launch_mode() if session != null else AppSessionState.LaunchMode.UNSPECIFIED
	if launch_mode == AppSessionState.LaunchMode.TEST_HALL:
		if tools_overlay != null:
			tools_overlay.set_development_tools_enabled(true)
		CookbookCatalog.set_test_hall_mode(true)
	elif launch_mode == AppSessionState.LaunchMode.SINGLE_PLAYER:
		call_deferred("_start_single_player_from_menu")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		get_tree().reload_current_scene()


func _sync_music_to_flow() -> void:
	if audio_manager == null:
		return
	audio_manager.play_music(_get_desired_music_track())


func _on_exit_run_confirmed() -> void:
	if wave_manager != null:
		wave_manager.return_to_lobby()
	if tools_overlay != null:
		tools_overlay.complete_exit_to_lobby()
	get_tree().paused = false
	if audio_manager != null:
		audio_manager.set_music_paused(false)
		audio_manager.play_music(PrototypeAudioManager.Track.LOBBY)
	var session := get_node_or_null("/root/AppSession") as AppSessionState
	if session != null:
		session.clear_launch_mode()
	CookbookCatalog.set_test_hall_mode(false)
	call_deferred("_return_to_main_menu")


func _start_single_player_from_menu() -> void:
	if wave_manager != null and wave_manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION:
		wave_manager.start_service_early()


func _return_to_main_menu() -> void:
	var error := get_tree().change_scene_to_file(AppSessionState.MAIN_MENU_SCENE)
	if error != OK:
		push_error("Failed to return to main menu: %d" % error)


func _get_desired_music_track() -> int:
	if wave_manager == null:
		return PrototypeAudioManager.Track.LOBBY
	match wave_manager.phase:
		PrototypeWaveManager.Phase.FREE_PREPARATION:
			return PrototypeAudioManager.Track.LOBBY
		PrototypeWaveManager.Phase.PREPARATION, PrototypeWaveManager.Phase.GLOBAL_WARNING, PrototypeWaveManager.Phase.LOCAL_WARNING, PrototypeWaveManager.Phase.SPAWNING, PrototypeWaveManager.Phase.WAVE_ACTIVE, PrototypeWaveManager.Phase.INTERMISSION:
			return PrototypeAudioManager.Track.BATTLE
		PrototypeWaveManager.Phase.RUN_COMPLETE:
			return PrototypeAudioManager.Track.VICTORY
		PrototypeWaveManager.Phase.FAILED:
			return PrototypeAudioManager.Track.DEFEAT
	return PrototypeAudioManager.Track.LOBBY
