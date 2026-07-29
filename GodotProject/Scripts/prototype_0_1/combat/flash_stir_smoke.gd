class_name FlashStirSmoke
extends Node2D

var radius: float = 185.0
var linger_left: float = -1.0
var source_id: String


func setup(origin: Vector2, smoke_radius: float = 185.0) -> void:
	global_position = origin
	radius = smoke_radius
	source_id = "flash_smoke_%d" % get_instance_id()


func _ready() -> void:
	add_to_group("flash_stir_smoke")
	z_index = 9
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.72, 0.34, 0.12, 0.13))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.95, 0.55, 0.20, 0.66), 3.0)


func _process(delta: float) -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		if not target is Node2D or not is_instance_valid(target):
			continue
		if global_position.distance_to((target as Node2D).global_position) > radius:
			continue
		CombatStatusController.ensure_on(target).apply_status(
			CombatStatusController.StatusType.AIM_DISRUPTION,
			source_id,
			1.0,
			0.25
		)
	if linger_left >= 0.0:
		linger_left -= delta
		if linger_left <= 0.0:
			_clear_and_free()


func begin_dissipating(duration: float) -> void:
	linger_left = maxf(0.0, duration)


func _clear_and_free() -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		var statuses := target.get_node_or_null("CombatStatusController") as CombatStatusController
		if statuses != null:
			statuses.remove_source(source_id)
	queue_free()
