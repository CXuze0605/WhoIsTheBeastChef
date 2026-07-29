class_name SpicyBeefAttack
extends Node2D

var direction := Vector2.RIGHT
var dish_data: ItemData
var source_entity: Node
var radial: bool = false
var perfect_finisher: bool = false
var resolved: bool = false


func setup(origin: Vector2, attack_direction: Vector2, data: ItemData, source: Node, finisher: bool) -> void:
	global_position = origin
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	dish_data = data
	source_entity = source
	perfect_finisher = finisher
	radial = finisher


func _ready() -> void:
	add_to_group("temporary_attack_entity")
	z_index = 20
	_resolve()
	queue_redraw()
	var timer := get_tree().create_timer(0.16)
	timer.timeout.connect(queue_free)


func _draw() -> void:
	var radius := float(dish_data.effect_values.get("perfect_radius", 175.0)) if radial else float(dish_data.effect_values.get("range", 148.0))
	if radial:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.28, 0.12, 0.75), 7.0)
	else:
		var half := deg_to_rad(float(dish_data.effect_values.get("arc", 104.0)) * 0.5)
		draw_arc(Vector2.ZERO, radius, direction.angle() - half, direction.angle() + half, 28, Color(1.0, 0.28, 0.12, 0.78), 9.0)


func _resolve() -> void:
	if resolved or dish_data == null:
		return
	resolved = true
	var max_range := float(dish_data.effect_values.get("perfect_radius", 175.0)) if radial else float(dish_data.effect_values.get("range", 148.0))
	var half_arc := deg_to_rad(float(dish_data.effect_values.get("arc", 104.0)) * 0.5)
	var center_half := deg_to_rad(float(dish_data.effect_values.get("center_arc", 42.0)) * 0.5)
	for target in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(target):
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() > max_range + _target_radius(target):
			continue
		var angle := absf(direction.angle_to(offset.normalized())) if not offset.is_zero_approx() else 0.0
		if not radial and angle > half_arc:
			continue
		var amount := float(dish_data.effect_values.get("perfect_damage", 27.0)) if radial else (
			float(dish_data.effect_values.get("center_damage", 30.0))
			if angle <= center_half
			else float(dish_data.effect_values.get("side_damage", 15.0))
		)
		var context := DamageContext.new()
		context.source_entity = source_entity
		context.source_dish = dish_data
		context.source_type = DamageContext.SourceType.PLAYER_DIRECT_MELEE
		context.attacker_faction = CombatRules.Faction.PLAYER
		context.target_faction = CombatRules.Faction.ENEMY
		context.base_damage = amount
		context.allow_direct_attack_bonus = true
		target.receive_damage_context(
			context,
			offset.normalized(),
			float(dish_data.effect_values.get("knockback", 18.0)),
			0.0
		)
		var statuses := CombatStatusController.ensure_on(target)
		statuses.apply_status(
			CombatStatusController.StatusType.VULNERABILITY,
			dish_data.source_recipe_instance_id,
			float(dish_data.effect_values.get("perfect_vulnerability", 0.15)) if radial else float(dish_data.effect_values.get("vulnerability", 0.08)),
			float(dish_data.effect_values.get("perfect_duration", 4.0)) if radial else float(dish_data.effect_values.get("vulnerability_duration", 3.0))
		)


func _is_enemy(target: Node) -> bool:
	return target != null and is_instance_valid(target) and target.has_method("get_combat_faction") and target.has_method("receive_damage_context") and int(target.get_combat_faction()) == CombatRules.Faction.ENEMY


func _target_radius(target: Node) -> float:
	return (target as BasicTasteEnemy).enemy_collision_radius if target is BasicTasteEnemy else 18.0
