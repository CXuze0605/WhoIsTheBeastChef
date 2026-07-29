class_name GreensLeafProjectile
extends Node2D

enum Mode { BOOMERANG, SPICY_BOOMERANG, FLASH }

var mode: int = Mode.BOOMERANG
var direction := Vector2.RIGHT
var damage: float = 0.0
var speed: float = 560.0
var max_distance: float = 460.0
var traveled: float = 0.0
var hit_radius: float = 16.0
var pierce_left: int = 3
var returning: bool = false
var source_entity: Node2D
var source_dish: ItemData
var outbound_hits: Dictionary = {}
var return_hits: Dictionary = {}
var resolved_callback: Callable


func setup(
	origin: Vector2,
	move_direction: Vector2,
	dish_data: ItemData,
	attack_source: Node2D,
	projectile_mode: int,
	on_resolved: Callable = Callable()
) -> void:
	global_position = origin
	direction = move_direction.normalized() if not move_direction.is_zero_approx() else Vector2.RIGHT
	source_entity = attack_source
	source_dish = dish_data
	mode = projectile_mode
	damage = dish_data.actual_damage
	speed = float(dish_data.effect_values.get("projectile_speed", 560.0))
	max_distance = float(dish_data.effect_values.get("range", 460.0))
	pierce_left = int(dish_data.effect_values.get("pierce", 3))
	resolved_callback = on_resolved


func _ready() -> void:
	add_to_group("greens_leaf_projectile")
	z_index = 16
	queue_redraw()


func _draw() -> void:
	var texture := CombatArtCatalog.get_texture(&"greens_leaf")
	var tint := Color("ffad62") if mode == Mode.FLASH else Color.WHITE
	draw_texture_rect(texture, Rect2(Vector2(-16.0, -16.0), Vector2(32.0, 32.0)), false, tint)
	draw_circle(Vector2(-18.0, 0.0), 2.0, Color(0.42, 0.78, 0.35, 0.45))


func _physics_process(delta: float) -> void:
	if mode != Mode.FLASH and returning:
		if source_entity == null or not is_instance_valid(source_entity):
			_resolve()
			return
		direction = global_position.direction_to(source_entity.global_position)
	var step := direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		if mode == Mode.FLASH:
			_explode(null)
		else:
			returning = true
		return
	global_position += step
	rotation = direction.angle()
	traveled += step.length()
	_hit_targets()
	if mode == Mode.FLASH and traveled >= max_distance:
		_explode(null)
	elif mode != Mode.FLASH and not returning and traveled >= max_distance:
		returning = true
	elif mode != Mode.FLASH and returning and source_entity != null and global_position.distance_to(source_entity.global_position) <= 24.0:
		_resolve()


func _hit_targets() -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy_target(target) or global_position.distance_to(target.global_position) > hit_radius + _target_radius(target):
			continue
		if mode == Mode.FLASH:
			_explode(target)
			return
		var hits := return_hits if returning else outbound_hits
		var target_id := target.get_instance_id()
		if hits.has(target_id):
			continue
		hits[target_id] = true
		_apply_direct_damage(target)
		if mode == Mode.SPICY_BOOMERANG:
			var statuses := CombatStatusController.ensure_on(target)
			statuses.apply_status(
				CombatStatusController.StatusType.VULNERABILITY,
				"spicy_leaf_%d" % source_dish.source_recipe_instance_id,
				float(source_dish.effect_values.get("vulnerability", 0.0)),
				float(source_dish.effect_values.get("vulnerability_duration", 0.0))
			)
		pierce_left -= 1
		if pierce_left <= 0:
			returning = true


func _explode(direct_target: Node) -> void:
	if direct_target != null:
		_apply_direct_damage(direct_target)
	var radius := float(source_dish.effect_values.get("burst_radius", 105.0))
	for target in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy_target(target) or global_position.distance_to(target.global_position) > radius + _target_radius(target):
			continue
		var statuses := CombatStatusController.ensure_on(target)
		statuses.apply_status(
			CombatStatusController.StatusType.AIM_DISRUPTION,
			"flash_leaf_%d" % source_dish.source_recipe_instance_id,
			1.0,
			float(source_dish.effect_values.get("choking_duration", 0.0))
		)
	_resolve()


func _apply_direct_damage(target: Node) -> void:
	var context := DamageContext.new()
	context.source_entity = source_entity
	context.source_dish = source_dish
	context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
	context.attacker_faction = CombatRules.Faction.PLAYER
	context.target_faction = CombatRules.Faction.ENEMY
	context.base_damage = damage
	context.allow_direct_attack_bonus = true
	target.receive_damage_context(context, direction, 0.0, 0.0)


func _is_enemy_target(target: Node) -> bool:
	return (
		target != null
		and is_instance_valid(target)
		and target.has_method("get_combat_faction")
		and target.has_method("receive_damage_context")
		and int(target.get_combat_faction()) == CombatRules.Faction.ENEMY
	)


func _target_radius(target: Node) -> float:
	if target is BasicTasteEnemy:
		return (target as BasicTasteEnemy).enemy_collision_radius
	return 18.0


func _resolve() -> void:
	if resolved_callback.is_valid():
		resolved_callback.call(global_position)
	queue_free()
