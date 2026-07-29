class_name MainMenu
extends Control

const GAMEPLAY_SCENE := "res://Scenes/prototype_0_1/main.tscn"

@onready var single_player_button: Button = %SinglePlayerButton
@onready var multiplayer_button: Button = %MultiplayerButton
@onready var test_hall_button: Button = %TestHallButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var online_modal: Control = %OnlineModal
@onready var online_back_button: Button = %OnlineBackButton
@onready var exit_modal: Control = %ExitModal
@onready var exit_cancel_button: Button = %ExitCancelButton
@onready var exit_confirm_button: Button = %ExitConfirmButton
@onready var settings_panel: SettingsPanel = %SettingsPanel

var _main_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_main_buttons = [
		single_player_button,
		multiplayer_button,
		test_hall_button,
		settings_button,
		exit_button,
	]
	single_player_button.pressed.connect(_start_single_player)
	multiplayer_button.pressed.connect(_show_online_modal)
	test_hall_button.pressed.connect(_start_test_hall)
	settings_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(_show_exit_confirmation)
	online_back_button.pressed.connect(_close_online_modal)
	exit_cancel_button.pressed.connect(_close_exit_confirmation)
	exit_confirm_button.pressed.connect(_confirm_exit)
	settings_panel.closed.connect(_on_settings_closed)
	online_modal.visible = false
	exit_modal.visible = false
	var session := get_node_or_null("/root/AppSession") as AppSessionState
	if session != null:
		session.clear_launch_mode()
	var audio := get_node_or_null("/root/AudioManager") as PrototypeAudioManager
	if audio != null:
		audio.set_music_paused(false)
		audio.play_music(PrototypeAudioManager.Track.LOBBY)
	call_deferred("_focus_default_button")


func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible:
		return
	if _is_escape_pressed(event):
		if online_modal.visible:
			_close_online_modal()
		elif exit_modal.visible:
			_close_exit_confirmation()
		else:
			_show_exit_confirmation()
		get_viewport().set_input_as_handled()
		return
	if online_modal.visible or exit_modal.visible:
		return
	if _is_focus_previous(event):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif _is_focus_next(event):
		_move_focus(1)
		get_viewport().set_input_as_handled()


func _start_single_player() -> void:
	_launch_gameplay(AppSessionState.LaunchMode.SINGLE_PLAYER)


func _start_test_hall() -> void:
	_launch_gameplay(AppSessionState.LaunchMode.TEST_HALL)


func _launch_gameplay(mode: int) -> void:
	var session := get_node_or_null("/root/AppSession") as AppSessionState
	if session == null:
		push_error("Main menu cannot find AppSession")
		return
	session.set_launch_mode(mode)
	var error := get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	if error != OK:
		session.clear_launch_mode()
		push_error("Failed to open gameplay scene: %d" % error)


func _show_online_modal() -> void:
	online_modal.visible = true
	online_back_button.grab_focus()


func _close_online_modal() -> void:
	online_modal.visible = false
	multiplayer_button.grab_focus()


func _open_settings() -> void:
	settings_panel.open_panel("设置")


func _on_settings_closed() -> void:
	settings_button.grab_focus()


func _show_exit_confirmation() -> void:
	exit_modal.visible = true
	exit_cancel_button.grab_focus()


func _close_exit_confirmation() -> void:
	exit_modal.visible = false
	exit_button.grab_focus()


func _confirm_exit() -> void:
	get_tree().quit()


func _focus_default_button() -> void:
	single_player_button.grab_focus()


func _move_focus(direction: int) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var index := _main_buttons.find(focused)
	if index < 0:
		index = 0
	else:
		index = wrapi(index + direction, 0, _main_buttons.size())
	_main_buttons[index].grab_focus()


func _is_escape_pressed(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var key := event as InputEventKey
	return key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE)


func _is_focus_previous(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return false
	return key.keycode in [KEY_UP, KEY_W] or key.physical_keycode in [KEY_UP, KEY_W]


func _is_focus_next(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return false
	return key.keycode in [KEY_DOWN, KEY_S] or key.physical_keycode in [KEY_DOWN, KEY_S]
