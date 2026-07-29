class_name TurretDishProjectile
extends Node2D

enum Mode { RICE_AOE, GREENS_PIERCE, BEEF_SINGLE }

var mode: int
var dish_data: ItemData
var source_turret: Node
var target: Node2D
var direction := Vector2.RIGHT
var speed: float = 620.0
var travelled: float = 0.0
var max_range: float = 470.0
var hit_ids: Dictionary = {}
var damage_override: float = -1.0


func setup(origin: Vector2, target_node: Node2D, shot_mode: int, data: ItemData, turret: Node, override_damage: float = -1.0) -> void:
	global_position = origin
	target = target_node
	mode = shot_mode
	dish_data = ItemCatalog.duplicate_data(data)
	source_turret = turret
	damage_override = override_damage
	if target != null:
		direction = origin.direction_to(target.global_position)
	max_range = float(data.effect_values.get("greens_range", 470.0))


func setup_direction(origin: Vector2, shot_direction: Vector2, data: ItemData, turret: Node) -> void:
	global_position = origin
	target = null
	mode = Mode.GREENS_PIERCE
	dish_data = ItemCatalog.duplicate_data(data)
	source_turret = turret
	direction = shot_direction.normalized()
	max_range = float(data.effect_values.get("greens_range", 470.0))


func _ready() -> void:
	add_to_group("temporary_attack_entity")
	z_index = 12
	queue_redraw()


func _draw() -> void:
	var key := &"rice_grain"
	if mode == Mode.GREENS_PIERCE:
		key = &"greens_leaf"
	elif mode == Mode.BEEF_SINGLE:
		key = &"beef_projectile"
	var texture := CombatArtCatalog.get_texture(key)
	draw_texture_rect(texture, Rect2(Vector2(-13.0, -13.0), Vector2(26.0, 26.0)), false)


func _process(delta: float) -> void:
	if mode != Mode.GREENS_PIERCE and (target == null or not is_instance_valid(target)):
		queue_free()
		return
	if mode != Mode.GREENS_PIERCE:
		direction = global_position.direction_to(target.global_position)
	var step := direction * speed * delta
	if _blocked_by_facility(global_position, global_position + step):
		queue_free()
		return
	global_position += step
	rotation = direction.angle()
	travelled += step.length()
	if mode == Mode.GREENS_PIERCE:
		_damage_greens_path()
		if travelled >= max_range:
			queue_free()
		return
	if global_position.distance_to(target.global_position) <= 14.0 or travelled >= max_range:
		_impact()


func _impact() -> void:
	if mode == Mode.RICE_AOE:
		var radius := float(dish_data.effect_values.get("rice_radius", 82.0))
		for candidate in get_tree().get_nodes_in_group("damageable"):
			if _is_enemy(candidate) and global_position.distance_to(candidate.global_position) <= radius:
				_damage(candidate, float(dish_data.effect_values.get("rice_damage", 12.0)))
	elif mode == Mode.BEEF_SINGLE and _is_enemy(target):
		_damage(target, damage_override if damage_override >= 0.0 else float(dish_data.effect_values.get("beef_damage", 38.0)))
	queue_free()


func _damage_greens_path() -> void:
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(candidate) or hit_ids.has(candidate.get_instance_id()):
			continue
		if global_position.distance_to(candidate.global_position) > 28.0:
			continue
		hit_ids[candidate.get_instance_id()] = true
		_damage(candidate, float(dish_data.effect_values.get("greens_damage", 18.0)))
		if hit_ids.size() >= int(dish_data.effect_values.get("greens_pierce", 999)):
			queue_free()
			return


func _damage(candidate: Node, amount: float) -> void:
	var context := DamageContext.new()
	context.source_entity = source_turret
	context.source_dish = dish_data
	context.source_type = DamageContext.SourceType.TURRET
	context.attacker_faction = CombatRules.Faction.PLAYER
	context.target_faction = CombatRules.Faction.ENEMY
	context.base_damage = amount
	context.allow_direct_attack_bonus = false
	candidate.receive_damage_context(context, direction, 0.0, 0.0)


func _is_enemy(candidate: Node) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.has_method("get_combat_faction")
		and candidate.has_method("receive_damage_context")
		and int(candidate.get_combat_faction()) == CombatRules.Faction.ENEMY
	)


func _blocked_by_facility(from: Vector2, to: Vector2) -> bool:
	if get_world_2d() == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
