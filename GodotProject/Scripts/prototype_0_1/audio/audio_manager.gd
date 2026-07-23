class_name PrototypeAudioManager
extends Node

signal track_changed(track: int)
signal transition_finished(track: int)

enum Track {
	NONE,
	LOBBY,
	BATTLE,
	VICTORY,
	DEFEAT,
}

const SILENCE_DB: float = -60.0
const TRACK_PATHS := {
	Track.LOBBY: "res://Audio/bgm/lobby_theme.mp3",
	Track.BATTLE: "res://Audio/bgm/battle_theme.mp3",
	Track.VICTORY: "res://Audio/bgm/victory_theme.mp3",
	Track.DEFEAT: "res://Audio/bgm/defeat_theme.mp3",
}

var default_fade_seconds: float = 0.8
var music_volume_db: float = 0.0
var current_track: int = Track.NONE
var playback_enabled: bool = true
var music_paused: bool = false

var _streams: Dictionary = {}
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _inactive_player: AudioStreamPlayer
var _transition_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	playback_enabled = DisplayServer.get_name() != "headless"
	_load_streams()
	_configure_stream_loops()
	_player_a = _create_music_player("MusicPlayerA")
	_player_b = _create_music_player("MusicPlayerB")
	_active_player = _player_a
	_inactive_player = _player_b


func _exit_tree() -> void:
	_cancel_transition()
	if _player_a != null:
		_player_a.stop()
		_player_a.stream = null
	if _player_b != null:
		_player_b.stop()
		_player_b.stream = null
	_streams.clear()


func play_music(track: int, fade_seconds: float = -1.0) -> void:
	var stream := get_track_stream(track)
	if stream == null:
		push_warning("AudioManager received an unknown music track: %d" % track)
		return
	if current_track == track and _active_player != null and _active_player.playing:
		return
	if current_track == track and not playback_enabled:
		return

	_cancel_transition()
	if not playback_enabled:
		current_track = track
		track_changed.emit(current_track)
		transition_finished.emit(current_track)
		return
	var duration := default_fade_seconds if fade_seconds < 0.0 else maxf(0.0, fade_seconds)
	var outgoing := _active_player if _active_player != null and _active_player.playing else null
	var incoming := _inactive_player if outgoing != null else _active_player
	if incoming == null:
		return

	incoming.stop()
	incoming.stream = null
	incoming.stream = stream
	incoming.volume_db = SILENCE_DB if duration > 0.0 else music_volume_db
	incoming.play()
	incoming.stream_paused = music_paused
	current_track = track
	track_changed.emit(current_track)

	if outgoing != null and outgoing != incoming:
		_active_player = incoming
		_inactive_player = outgoing
		if duration > 0.0:
			_transition_tween = create_tween().set_parallel(true)
			_transition_tween.tween_property(outgoing, "volume_db", SILENCE_DB, duration)
			_transition_tween.tween_property(incoming, "volume_db", music_volume_db, duration)
			_transition_tween.finished.connect(_on_crossfade_finished.bind(outgoing, incoming, track))
		else:
			outgoing.stop()
			outgoing.stream = null
			outgoing.volume_db = SILENCE_DB
			incoming.volume_db = music_volume_db
			transition_finished.emit(current_track)
		return

	_active_player = incoming
	_inactive_player = _player_b if incoming == _player_a else _player_a
	if duration > 0.0:
		_transition_tween = create_tween()
		_transition_tween.tween_property(incoming, "volume_db", music_volume_db, duration)
		_transition_tween.finished.connect(_on_fade_in_finished.bind(incoming, track))
	else:
		incoming.volume_db = music_volume_db
		transition_finished.emit(current_track)


func stop_music(fade_seconds: float = -1.0) -> void:
	_cancel_transition()
	var duration := default_fade_seconds if fade_seconds < 0.0 else maxf(0.0, fade_seconds)
	current_track = Track.NONE
	track_changed.emit(current_track)
	if not playback_enabled:
		transition_finished.emit(current_track)
		return
	if _active_player == null or not _active_player.playing:
		transition_finished.emit(current_track)
		return
	if duration <= 0.0:
		_active_player.stop()
		_active_player.stream = null
		_active_player.volume_db = SILENCE_DB
		transition_finished.emit(current_track)
		return
	_transition_tween = create_tween()
	_transition_tween.tween_property(_active_player, "volume_db", SILENCE_DB, duration)
	_transition_tween.finished.connect(_on_stop_fade_finished.bind(_active_player))


func set_music_volume_db(value: float) -> void:
	music_volume_db = clampf(value, SILENCE_DB, 6.0)
	_cancel_transition()
	if _active_player != null and _active_player.playing:
		_active_player.volume_db = music_volume_db


func set_music_volume_linear(value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	set_music_volume_db(SILENCE_DB if clamped <= 0.0 else linear_to_db(clamped))


func set_music_paused(paused: bool) -> void:
	music_paused = paused
	if _player_a != null:
		_player_a.stream_paused = paused
	if _player_b != null:
		_player_b.stream_paused = paused


func is_music_paused() -> bool:
	return music_paused


func get_current_track() -> int:
	return current_track


func get_track_stream(track: int) -> AudioStream:
	return _streams.get(track) as AudioStream


func is_track_playing(track: int) -> bool:
	return current_track == track and _active_player != null and _active_player.playing


func _create_music_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = SILENCE_DB
	add_child(player)
	return player


func _load_streams() -> void:
	_streams.clear()
	for track in TRACK_PATHS:
		var stream := load(TRACK_PATHS[track]) as AudioStream
		if stream == null:
			push_error("AudioManager could not load music track: %s" % TRACK_PATHS[track])
			continue
		_streams[track] = stream


func _configure_stream_loops() -> void:
	for value in _streams.values():
		var stream := value as AudioStream
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
			(stream as AudioStreamMP3).loop_offset = 0.0


func _cancel_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
	if _inactive_player != null and _inactive_player.playing:
		_inactive_player.stop()
		_inactive_player.stream = null
		_inactive_player.volume_db = SILENCE_DB


func _on_crossfade_finished(outgoing: AudioStreamPlayer, incoming: AudioStreamPlayer, track: int) -> void:
	if incoming != _active_player or track != current_track:
		return
	outgoing.stop()
	outgoing.stream = null
	outgoing.volume_db = SILENCE_DB
	incoming.volume_db = music_volume_db
	_transition_tween = null
	transition_finished.emit(current_track)


func _on_fade_in_finished(player: AudioStreamPlayer, track: int) -> void:
	if player != _active_player or track != current_track:
		return
	player.volume_db = music_volume_db
	_transition_tween = null
	transition_finished.emit(current_track)


func _on_stop_fade_finished(player: AudioStreamPlayer) -> void:
	if current_track != Track.NONE:
		return
	player.stop()
	player.stream = null
	player.volume_db = SILENCE_DB
	_transition_tween = null
	transition_finished.emit(current_track)
