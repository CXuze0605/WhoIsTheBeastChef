extends Node2D

var wave_manager: PrototypeWaveManager
var audio_manager: PrototypeAudioManager
var tools_overlay: PrototypeToolsOverlay


func _ready() -> void:
	var player := get_node_or_null("Kitchen/Player") as PrototypePlayer
	if player != null:
		player.notify_feedback("Prototype 0.5：ESC 暂停；F3 切换开发 UI；F9 记录试玩问题。")
	wave_manager = get_node_or_null("WaveManager") as PrototypeWaveManager
	audio_manager = get_node_or_null("/root/AudioManager") as PrototypeAudioManager
	tools_overlay = get_node_or_null("PrototypeToolsOverlay") as PrototypeToolsOverlay
	if tools_overlay != null:
		tools_overlay.exit_run_confirmed.connect(_on_exit_run_confirmed)
	if wave_manager != null:
		wave_manager.wave_stats_changed.connect(_sync_music_to_flow)
	_sync_music_to_flow()


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
