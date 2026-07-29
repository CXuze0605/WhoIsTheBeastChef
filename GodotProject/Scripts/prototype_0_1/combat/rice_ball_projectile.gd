class_name RiceBallProjectile
extends Node2D

var direction := Vector2.RIGHT
var damage: float = 0.0
var speed: float = 720.0
var max_distance: float = 560.0
var traveled: float = 0.0
var hit_radius: float = 13.0
var source_entity: Node
var source_dish: ItemData
var grain_visual: bool = false
var move_slow: float = 0.0
var slow_duration: float = 0.0
var slow_source_id: int = 0
var vulnerability: float = 0.0
var vulnerability_duration: float = 0.0


func setup(origin: Vector2, move_direction: Vector2, attack_damage: float, combat_config: PrototypeCombatConfig, attack_source: Node = null, dish_data: ItemData = null) -> void:
	global_position = origin
	direction = move_direction.normalized() if not move_direction.is_zero_approx() else Vector2.RIGHT
	damage = attack_damage
	speed = combat_config.white_rice_projectile_speed
	max_distance = combat_config.white_rice_projectile_range
	source_entity = attack_source
	source_dish = dish_data


func configure_grain(
	projectile_speed: float,
	projectile_range: float,
	slow_strength: float,
	slow_time: float,
	status_source_id: int
) -> void:
	grain_visual = true
	speed = projectile_speed
	max_distance = projectile_range
	hit_radius = 5.0
	move_slow = slow_strength
	slow_duration = slow_time
	slow_source_id = status_source_id


func configure_vulnerability(strength: float, duration: float, status_source_id: int) -> void:
	vulnerability = maxf(0.0, strength)
	vulnerability_duration = maxf(0.0, duration)
	slow_source_id = status_source_id


func _ready() -> void:
	add_to_group("rice_ball_projectile")
	z_index = 15
	queue_redraw()


func _draw() -> void:
	if grain_visual:
		var texture := CombatArtCatalog.get_texture(&"rice_grain")
		draw_texture_rect(texture, Rect2(Vector2(-9.0, -9.0), Vector2(18.0, 18.0)), false)
		draw_circle(Vector2(-12.0, 0.0), 1.4, Color(0.96, 0.82, 0.42, 0.45))
	else:
		draw_circle(Vector2.ZERO, hit_radius, Color("fff8e7"))
		draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 20, Color("d6ccc2"), 2.0)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position += step
	rotation = direction.angle()
	traveled += step.length()
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_combat_hit"):
			continue
		if int(target.get_combat_faction()) != CombatRules.Faction.ENEMY:
			continue
		if global_position.distance_to(target.global_position) > hit_radius + 18.0:
			continue
		if target.has_method("receive_damage_context"):
			var context := DamageContext.new()
			context.source_entity = source_entity
			context.source_dish = source_dish
			context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
			context.attacker_faction = CombatRules.Faction.PLAYER
			context.target_faction = CombatRules.Faction.ENEMY
			context.base_damage = damage
			context.friendly_fire = false
			context.allow_direct_attack_bonus = true
			target.receive_damage_context(context, direction, 0.0, -1.0 if grain_visual else 0.0)
		else:
			target.receive_combat_hit(damage, CombatRules.Faction.PLAYER, direction, 0.0, false, -1.0 if grain_visual else 0.0)
		if move_slow > 0.0 and slow_duration > 0.0:
			var statuses := CombatStatusController.ensure_on(target)
			statuses.apply_status(
				CombatStatusController.StatusType.MOVE_SLOW,
				slow_source_id if slow_source_id != 0 else get_instance_id(),
				move_slow,
				slow_duration
			)
		if vulnerability > 0.0 and vulnerability_duration > 0.0:
			var vulnerability_statuses := CombatStatusController.ensure_on(target)
			vulnerability_statuses.apply_status(
				CombatStatusController.StatusType.VULNERABILITY,
				slow_source_id if slow_source_id != 0 else get_instance_id(),
				vulnerability,
				vulnerability_duration
			)
		queue_free()
		return
	if traveled >= max_distance:
		queue_free()
