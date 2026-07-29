class_name AppSessionState
extends Node

enum LaunchMode {
	UNSPECIFIED,
	SINGLE_PLAYER,
	TEST_HALL,
	MULTIPLAYER,
}

const MAIN_MENU_SCENE := "res://Scenes/menu/main_menu.tscn"
const GAMEPLAY_SCENE := "res://Scenes/prototype_0_1/main.tscn"

var launch_mode: int = LaunchMode.UNSPECIFIED


func set_launch_mode(mode: int) -> void:
	launch_mode = mode if mode in LaunchMode.values() else LaunchMode.UNSPECIFIED


func consume_launch_mode() -> int:
	var requested_mode := launch_mode
	launch_mode = LaunchMode.UNSPECIFIED
	return requested_mode


func clear_launch_mode() -> void:
	launch_mode = LaunchMode.UNSPECIFIED
