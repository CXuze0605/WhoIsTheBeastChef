class_name MustardTargetMarker
extends Node2D

var source_id: String


func setup(id: String) -> void:
	source_id = id
	position = Vector2(0.0, -64.0)


func _ready() -> void:
	add_to_group("mustard_target_marker")
	z_index = 30
	queue_redraw()


func _draw() -> void:
	var leaf := PackedVector2Array([
		Vector2(-10.0, 3.0),
		Vector2(0.0, -10.0),
		Vector2(11.0, 2.0),
		Vector2(0.0, 10.0),
	])
	draw_colored_polygon(leaf, Color("a7c847"))
	draw_line(Vector2(-7.0, 5.0), Vector2(7.0, -5.0), Color("d8a928"), 3.0)
