class_name KitchenObstacle
extends StaticBody2D

@export var obstacle_size := Vector2(140.0, 76.0)

var collision_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("kitchen_obstacle")
	collision_layer = 1
	collision_mask = 0
	collision_shape = CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = obstacle_size
	collision_shape.shape = rectangle
	add_child(collision_shape)


func set_obstacle_size(value: Vector2) -> void:
	obstacle_size = value
	if collision_shape == null:
		return
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle != null:
		rectangle.size = obstacle_size


func get_navigation_rect(extra_margin: float = 0.0) -> Rect2:
	var expanded := obstacle_size + Vector2.ONE * extra_margin * 2.0
	return Rect2(global_position - expanded * 0.5, expanded)
