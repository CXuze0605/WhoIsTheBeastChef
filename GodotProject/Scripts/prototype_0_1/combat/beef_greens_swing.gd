class_name BeefGreensSwing
extends Node2D

var direction := Vector2.RIGHT
var dish_data: ItemData
var source_entity: Node
var radial: bool = false
var life_left: float = 0.18
var hit_ids: Dictionary = {}


func setup(origin: Vector2, attack_direction: Vector2, data: ItemData, source: Node, is_radial: bool) -> void:
	global_position = origin
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	dish_data = data
	source_entity = source
	radial = is_radial


func _ready() -> void:
	add_to_group("beef_greens_swing")
	z_index = 17
	_apply_hits()
	queue_redraw()


func _process(delta: float) -> void:
	life_left -= delta
	modulate.a = clampf(life_left / 0.18, 0.0, 1.0)
	if life_left <= 0.0:
		queue_free()


func _draw() -> void:
	var radius := float(dish_data.effect_values.get("range", 148.0))
	if radial:
		draw_circle(Vector2.ZERO, radius, Color(0.45, 0.82, 0.30, 0.18))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color("b8dc75"), 7.0)
		return
	var half_arc := deg_to_rad(float(dish_data.effect_values.get("arc_degrees", 104.0)) * 0.5)
	draw_colored_polygon(PackedVector2Array([
		Vector2.ZERO,
		direction.rotated(-half_arc) * radius,
		direction * radius,
		direction.rotated(half_arc) * radius,
	]), Color(0.45, 0.82, 0.30, 0.24))


func _apply_hits() -> void:
	var radius := float(dish_data.effect_values.get("range", 148.0))
	var half_arc := deg_to_rad(float(dish_data.effect_values.get("arc_degrees", 104.0)) * 0.5)
	var center_half := deg_to_rad(float(dish_data.effect_values.get("center_degrees", 42.0)) * 0.5)
	for target in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(target):
			continue
		var offset: Vector2 = (target as Node2D).global_position - global_position
		if offset.length() > radius + _target_radius(target):
			continue
		var angle := absf(direction.angle_to(offset.normalized())) if not offset.is_zero_approx() else 0.0
		if not radial and angle > half_arc:
			continue
		var target_id := target.get_instance_id()
		if hit_ids.has(target_id):
			continue
		hit_ids[target_id] = true
		var damage := float(dish_data.effect_values.get("center_damage", dish_data.actual_damage))
		if not radial and angle > center_half:
			damage = float(dish_data.effect_values.get("side_damage", damage))
		elif radial:
			damage = (damage + float(dish_data.effect_values.get("side_damage", damage))) * 0.5
		var context := DamageContext.new()
		context.source_entity = source_entity
		context.source_dish = dish_data
		context.source_type = DamageContext.SourceType.PLAYER_DIRECT_MELEE
		context.attacker_faction = CombatRules.Faction.PLAYER
		context.target_faction = CombatRules.Faction.ENEMY
		context.base_damage = damage
		context.allow_direct_attack_bonus = true
		target.receive_damage_context(
			context,
			offset.normalized(),
			float(dish_data.effect_values.get("knockback", 42.0)) * (1.8 if radial else 1.0),
			0.0
		)


func _is_enemy(target: Node) -> bool:
	return (
		target != null
		and is_instance_valid(target)
		and target.has_method("get_combat_faction")
		and target.has_method("receive_damage_context")
		and int(target.get_combat_faction()) == CombatRules.Faction.ENEMY
	)


func _target_radius(target: Node) -> float:
	return (target as BasicTasteEnemy).enemy_collision_radius if target is BasicTasteEnemy else 18.0
