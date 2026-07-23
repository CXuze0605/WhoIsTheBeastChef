class_name MeleeSwing
extends Node2D

var direction := Vector2.RIGHT
var damage: float = 0.0
var range: float = 0.0
var half_angle_radians: float = 0.0
var knockback: float = 0.0
var stagger_power: float = 0.0
var on_hit_effect: StatusEffectData
var hit_target_ids: Dictionary = {}
var active_time_left: float = 0.13


func setup(origin: Vector2, attack_direction: Vector2, item_data: ItemData, config: PrototypeCombatConfig) -> void:
	global_position = origin
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	damage = item_data.actual_damage
	range = config.tomahawk_range
	half_angle_radians = deg_to_rad(config.tomahawk_arc_degrees * 0.5)
	knockback = config.tomahawk_knockback
	stagger_power = item_data.stagger_power
	on_hit_effect = config.create_on_hit_effect(item_data)


func _ready() -> void:
	add_to_group("melee_swing")
	var arc := Line2D.new()
	arc.width = 8.0
	arc.default_color = Color("ffb703")
	var points := PackedVector2Array([Vector2.ZERO])
	for index in 9:
		var angle := lerpf(-half_angle_radians, half_angle_radians, float(index) / 8.0)
		points.append(direction.rotated(angle) * range)
	points.append(Vector2.ZERO)
	arc.points = points
	add_child(arc)
	_hit_available_targets()


func _physics_process(delta: float) -> void:
	# Recheck briefly while the visible arc exists so a moving target cannot pass
	# through the effect between its single spawn-frame sample and the next frame.
	_hit_available_targets()
	active_time_left -= delta
	if active_time_left <= 0.0:
		queue_free()


func _hit_available_targets() -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_combat_hit"):
			continue
		var target_node := target as Node2D
		if target_node == null:
			continue
		var id := target.get_instance_id()
		if hit_target_ids.has(id):
			continue
		var offset: Vector2 = target_node.global_position - global_position
		if not _target_intersects_arc(target_node, offset):
			continue
		if target.receive_combat_hit(damage, CombatRules.Faction.PLAYER, direction, knockback, false, stagger_power):
			hit_target_ids[id] = true
			if on_hit_effect != null and target.has_method("apply_status_effect"):
				target.apply_status_effect(on_hit_effect.copy_effect())


func _target_intersects_arc(target: Node2D, offset: Vector2) -> bool:
	var target_radius := _get_target_collision_radius(target)
	var distance := offset.length()
	if distance - target_radius > range:
		return false
	# A target whose collision body overlaps the attack origin is a valid
	# point-blank hit. Otherwise reject bodies wholly behind the swing.
	if distance <= target_radius:
		return true
	if direction.dot(offset) + target_radius < 0.0:
		return false
	var angular_radius := asin(clampf(target_radius / maxf(distance, 0.001), 0.0, 1.0))
	return absf(direction.angle_to(offset / distance)) <= half_angle_radians + angular_radius


func _get_target_collision_radius(target: Node2D) -> float:
	if target is BasicTasteEnemy:
		return maxf(0.0, (target as BasicTasteEnemy).enemy_collision_radius)
	for child in target.get_children():
		if child is not CollisionShape2D:
			continue
		var shape := (child as CollisionShape2D).shape
		if shape is CircleShape2D:
			return maxf(0.0, (shape as CircleShape2D).radius)
		if shape is RectangleShape2D:
			return (shape as RectangleShape2D).size.length() * 0.5
	return 0.0
