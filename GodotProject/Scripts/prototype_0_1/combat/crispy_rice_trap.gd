class_name CrispyRiceTrap
extends Node2D

var config: PrototypeCombatConfig
var owner_player: PrototypePlayer
var arm_left: float = 0.5
var owner_has_left: bool = false
var triggered: bool = false


func setup(origin: Vector2, source_player: PrototypePlayer, combat_config: PrototypeCombatConfig) -> void:
	global_position = origin
	owner_player = source_player
	config = combat_config
	arm_left = combat_config.crispy_trap_arm_time


func _ready() -> void:
	add_to_group("crispy_rice_trap")
	z_index = 4
	queue_redraw()


func _draw() -> void:
	var radius := config.crispy_trap_radius if config != null else 34.0
	draw_circle(Vector2.ZERO, radius, Color(0.64, 0.39, 0.18, 0.18))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var p := Vector2.RIGHT.rotated(angle) * radius * 0.72
		draw_line(p - Vector2(5, 3), p + Vector2(5, 3), Color("bc6c25"), 3.0)


func _physics_process(delta: float) -> void:
	if triggered or config == null:
		return
	arm_left = maxf(0.0, arm_left - delta)
	if owner_player != null and is_instance_valid(owner_player):
		if global_position.distance_to(owner_player.global_position) > config.crispy_trap_radius + 12.0:
			owner_has_left = true
	if arm_left > 0.0:
		return
	for node in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(node) or not node.has_method("receive_combat_hit") or not node.has_method("get_combat_faction"):
			continue
		if node == owner_player and not owner_has_left:
			continue
		if global_position.distance_to(node.global_position) > config.crispy_trap_radius:
			continue
		var direction := global_position.direction_to(node.global_position)
		if direction.is_zero_approx():
			direction = Vector2.UP
		if node.receive_combat_hit(config.crispy_trap_damage, CombatRules.Faction.PLAYER, direction, 44.0, true, 48.0):
			triggered = true
			queue_free()
			return
