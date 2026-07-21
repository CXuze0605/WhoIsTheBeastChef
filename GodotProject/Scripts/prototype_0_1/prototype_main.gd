extends Node2D


func _ready() -> void:
	var player := get_node_or_null("Kitchen/Player") as PrototypePlayer
	if player != null:
		player.notify_feedback("Prototype 0.3：准备期可正常做饭；B 提前营业；味真族来袭后战斗与自动烹饪同时进行。")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		get_tree().reload_current_scene()
