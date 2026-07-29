class_name FriedRiceProjectile
extends Node2D

enum Mode { GREENS_AOE, BEEF_SINGLE, MIXED, SPICY_BEEF_SINGLE, SPICY_MIXED }

var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var elapsed: float = 0.0
var flight_time: float = 0.48
var mode: int = Mode.GREENS_AOE
var dish_data: ItemData
var source_entity: Node
var perfect_finisher: bool = false
var resolved: bool = false


func setup(origin: Vector2, destination: Vector2, data: ItemData, source: Node, attack_mode: int, is_finisher: bool, config: PrototypeCombatConfig) -> void:
	start_position = origin
	global_position = origin
	target_position = destination
	dish_data = data
	source_entity = source
	mode = attack_mode
	perfect_finisher = is_finisher
	flight_time = config.fried_rice_flight_time


func _ready() -> void:
	add_to_group("fried_rice_projectile")
	z_index = 18
	queue_redraw()


func _draw() -> void:
	var key := &"spicy_rice" if mode in [Mode.SPICY_BEEF_SINGLE, Mode.SPICY_MIXED] else (
		&"beef_projectile" if mode == Mode.BEEF_SINGLE else &"rice_grain"
	)
	var texture := CombatArtCatalog.get_texture(key)
	var size := Vector2.ONE * (34.0 if perfect_finisher else 28.0)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
	draw_circle(Vector2(-18.0, 0.0), 2.2, Color(0.95, 0.78, 0.26, 0.55))
	draw_circle(Vector2(-27.0, 0.0), 1.4, Color(0.95, 0.78, 0.26, 0.30))


func _physics_process(delta: float) -> void:
	if resolved:
		return
	elapsed = minf(flight_time, elapsed + delta)
	var ratio := clampf(elapsed / maxf(flight_time, 0.01), 0.0, 1.0)
	var next_position := start_position.lerp(target_position, ratio)
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_impact(global_position)
		return
	global_position = next_position
	rotation = start_position.direction_to(target_position).angle()
	scale = Vector2.ONE * (1.0 + sin(ratio * PI) * 0.35)
	if ratio >= 1.0:
		_impact(target_position)


func _impact(origin: Vector2) -> void:
	if resolved:
		return
	resolved = true
	var main_target := _find_nearest_enemy(origin, float(dish_data.effect_values.get("snap_radius", 0.0)))
	if mode == Mode.GREENS_AOE:
		_apply_aoe(origin, null)
	elif mode == Mode.BEEF_SINGLE:
		if main_target != null:
			_apply_damage(main_target, float(dish_data.effect_values.get("single_damage", dish_data.actual_damage)) * (float(dish_data.effect_values.get("perfect_multiplier", 1.0)) if perfect_finisher else 1.0))
	elif mode == Mode.SPICY_BEEF_SINGLE:
		if main_target != null:
			_apply_damage(
				main_target,
				float(dish_data.effect_values.get("perfect_damage", dish_data.actual_damage)) if perfect_finisher else float(dish_data.effect_values.get("single_damage", dish_data.actual_damage)),
				float(dish_data.effect_values.get("perfect_stun", 0.0)) if perfect_finisher else float(dish_data.effect_values.get("stun", 0.0))
			)
			_apply_vulnerability(main_target)
	elif mode == Mode.MIXED:
		if main_target != null:
			_apply_damage(main_target, float(dish_data.effect_values.get("single_damage", dish_data.actual_damage)) * (float(dish_data.effect_values.get("perfect_multiplier", 1.0)) if perfect_finisher else 1.0))
		_apply_aoe(origin, main_target)
	elif mode == Mode.SPICY_MIXED:
		if main_target != null:
			_apply_damage(
				main_target,
				float(dish_data.effect_values.get("perfect_damage", dish_data.actual_damage)) if perfect_finisher else float(dish_data.effect_values.get("single_damage", dish_data.actual_damage)),
				0.0,
				float(dish_data.effect_values.get("perfect_knockback", 0.0)) if perfect_finisher else 0.0
			)
			_apply_vulnerability(main_target)
		_apply_aoe(origin, main_target)
	queue_free()


func _apply_aoe(origin: Vector2, excluded: Node) -> void:
	var radius := float(dish_data.effect_values.get("perfect_radius", 0.0)) if perfect_finisher else float(dish_data.effect_values.get("radius", 0.0))
	var damage := (
		float(dish_data.effect_values.get("perfect_aoe_damage", dish_data.effect_values.get("aoe_damage", dish_data.actual_damage)))
		if perfect_finisher
		else float(dish_data.effect_values.get("aoe_damage", dish_data.actual_damage))
	)
	for target in get_tree().get_nodes_in_group("damageable"):
		if target == excluded or not _is_enemy(target):
			continue
		if origin.distance_to(target.global_position) <= radius + _target_radius(target):
			_apply_damage(target, damage)
			if mode == Mode.SPICY_MIXED:
				_apply_vulnerability(target)


func _apply_damage(target: Node, amount: float, stagger: float = -1.0, knockback: float = 0.0) -> void:
	var context := DamageContext.new()
	context.source_entity = source_entity
	context.source_dish = dish_data
	context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
	context.attacker_faction = CombatRules.Faction.PLAYER
	context.target_faction = CombatRules.Faction.ENEMY
	context.base_damage = amount
	context.allow_direct_attack_bonus = true
	target.receive_damage_context(
		context,
		global_position.direction_to(target.global_position),
		knockback,
		float(dish_data.effect_values.get("stagger", 0.0)) if stagger < 0.0 else stagger
	)


func _apply_vulnerability(target: Node) -> void:
	var strength := (
		float(dish_data.effect_values.get("perfect_vulnerability", 0.0))
		if perfect_finisher
		else float(dish_data.effect_values.get("vulnerability", 0.0))
	)
	var duration := (
		float(dish_data.effect_values.get("perfect_duration", 0.0))
		if perfect_finisher
		else float(dish_data.effect_values.get("vulnerability_duration", 0.0))
	)
	if strength <= 0.0 or duration <= 0.0:
		return
	CombatStatusController.ensure_on(target).apply_status(
		CombatStatusController.StatusType.VULNERABILITY,
		dish_data.source_recipe_instance_id,
		strength,
		duration
	)


func _find_nearest_enemy(origin: Vector2, snap_radius: float) -> Node:
	var nearest: Node
	var nearest_distance := INF
	for target in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(target):
			continue
		var distance := origin.distance_to(target.global_position)
		if distance <= snap_radius + _target_radius(target) and distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	return nearest


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
