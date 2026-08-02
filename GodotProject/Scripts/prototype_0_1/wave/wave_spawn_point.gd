class_name WaveSpawnPoint
extends Marker2D

@export var edge_label: String = "边缘"
@export var lane_id: StringName = &"unknown"


func _ready() -> void:
	add_to_group("enemy_spawn_point")
