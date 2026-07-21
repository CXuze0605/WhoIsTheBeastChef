class_name BigBoneProjectile
extends Node2D

var direction := Vector2.RIGHT
var config: PrototypeCombatConfig
var traveled: float = 0.0
var completion_callback: Callable
var finished: bool = false


func setup(origin: Vector2, attack_direction: Vector2, combat_config: PrototypeCombatConfig, callback: Callable) -> void:
	global_position = origin
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	config = combat_config
	completion_callback = callback


func _ready() -> void:
	add_to_group("big_bone_projectile")
	var visual := PlaceholderVisual.new()
	add_child(visual)
	visual.configure(Vector2(62.0, 22.0), Color("e9dcc9"), "大骨头", "单体投掷")
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	var step := direction * config.big_bone_speed * delta
	global_position += step
	traveled += step.length()
	if _hit_first_target() or traveled >= config.big_bone_distance or not config.combat_bounds.has_point(global_position):
		_finish()


func _hit_first_target() -> bool:
	var closest: Node2D
	var closest_distance := INF
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_combat_hit"):
			continue
		if target.get_combat_faction() != CombatRules.Faction.ENEMY:
			continue
		var distance := global_position.distance_to(target.global_position)
		if distance <= config.big_bone_hit_radius and distance < closest_distance:
			closest = target
			closest_distance = distance
	if closest == null:
		return false
	closest.receive_combat_hit(config.big_bone_damage, CombatRules.Faction.PLAYER, direction, config.tomahawk_knockback, false, config.big_bone_stagger_power)
	return true


func _finish() -> void:
	if finished:
		return
	finished = true
	if completion_callback.is_valid():
		completion_callback.call()
	queue_free()
