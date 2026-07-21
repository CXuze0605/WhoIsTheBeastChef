class_name Interactable
extends Node2D

@export var display_title: String = "可交互对象"
@export var placeholder_size := Vector2(140.0, 76.0)
@export var placeholder_color := Color("52616b")
@export var prototype_art_key: StringName = &""

var interaction_enabled: bool = true
var placeholder: PlaceholderVisual


func _ready() -> void:
	add_to_group("interactable")
	placeholder = PlaceholderVisual.new()
	placeholder.name = "PlaceholderVisual"
	add_child(placeholder)
	placeholder.configure(placeholder_size, placeholder_color, display_title)
	if not prototype_art_key.is_empty():
		PrototypeArtCatalog.apply_to(placeholder, prototype_art_key)
		_sync_obstacle_to_art()


func _sync_obstacle_to_art() -> void:
	var obstacle := get_node_or_null("Obstacle") as KitchenObstacle
	if obstacle == null:
		return
	var art_size := placeholder.get_art_display_size()
	if art_size == Vector2.ZERO:
		return
	# Use the visible art footprint instead of the old wide graybox size.
	# A small inset keeps movement from feeling caught on transparent edge pixels.
	obstacle.set_obstacle_size(Vector2(
		maxf(24.0, art_size.x * 0.90),
		maxf(24.0, art_size.y * 0.86)
	))


func can_interact(_player: Node) -> bool:
	return interaction_enabled and is_visible_in_tree()


func get_carry_prompt(_player: Node) -> String:
	return ""


func carry_interact(player: Node) -> void:
	player.notify_feedback("这里没有可执行的拿取或放置操作")


func get_primary_prompt(_player: Node) -> String:
	return ""


func begin_primary_interaction(_player: Node) -> bool:
	return false


func update_primary_interaction(_player: Node, _delta: float) -> bool:
	return false


func cancel_primary_interaction(_player: Node) -> void:
	pass


func blocks_movement_during_primary() -> bool:
	return false


func get_secondary_prompt(_player: Node) -> String:
	return ""


func secondary_interact(player: Node) -> void:
	player.notify_feedback("这里没有锅具搬运操作")


func get_progress_ratio() -> float:
	return 0.0


func get_debug_state() -> String:
	return display_title


func set_placeholder_status(text: String) -> void:
	if placeholder != null:
		placeholder.set_status(text)
