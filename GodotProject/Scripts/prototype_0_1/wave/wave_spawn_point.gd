class_name WaveSpawnPoint
extends Marker2D

@export var edge_label: String = "边缘"


func _ready() -> void:
	add_to_group("enemy_spawn_point")

