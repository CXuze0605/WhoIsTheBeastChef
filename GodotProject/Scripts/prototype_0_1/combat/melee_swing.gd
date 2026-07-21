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
	_hit_once()
	var timer := get_tree().create_timer(0.13)
	timer.timeout.connect(queue_free)


func _hit_once() -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_combat_hit"):
			continue
		var id := target.get_instance_id()
		if hit_target_ids.has(id):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() > range or offset.is_zero_approx() or absf(direction.angle_to(offset.normalized())) > half_angle_radians:
			continue
		if target.receive_combat_hit(damage, CombatRules.Faction.PLAYER, direction, knockback, false, stagger_power):
			hit_target_ids[id] = true
			if on_hit_effect != null and target.has_method("apply_status_effect"):
				target.apply_status_effect(on_hit_effect.copy_effect())
