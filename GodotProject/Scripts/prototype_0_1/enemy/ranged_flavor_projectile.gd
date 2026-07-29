class_name RangedFlavorProjectile
extends Node2D

var direction := Vector2.RIGHT
var speed: float = 360.0
var damage: float = 8.0
var splash_damage: float = 4.0
var splash_radius: float = 32.0
var max_distance: float = 720.0
var hit_radius: float = 11.0
var arc_height: float = 48.0
var knockback: float = 28.0
var traveled: float = 0.0
var travel_distance: float = 0.0
var landing_position := Vector2.ZERO
var intended_target: Node2D
var source_enemy: RangedTasteEnemy
var resolved: bool = false
var blocked_by_facility: bool = false
var direct_hit_ids: Dictionary = {}


func setup(
	origin: Vector2,
	target_position: Vector2,
	enemy_config: PrototypeWaveConfig,
	target_node: Node2D = null,
	enemy_source: RangedTasteEnemy = null
) -> void:
	global_position = origin
	var raw_distance := origin.distance_to(target_position)
	travel_distance = minf(raw_distance, enemy_config.ranged_projectile_range)
	direction = origin.direction_to(target_position)
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	landing_position = origin + direction * travel_distance
	speed = enemy_config.ranged_projectile_speed
	damage = enemy_config.ranged_projectile_damage
	splash_damage = enemy_config.ranged_projectile_splash_damage
	splash_radius = enemy_config.ranged_projectile_splash_radius
	max_distance = enemy_config.ranged_projectile_range
	hit_radius = enemy_config.ranged_projectile_radius
	arc_height = enemy_config.ranged_projectile_arc_height
	knockback = enemy_config.ranged_projectile_knockback
	intended_target = target_node
	source_enemy = enemy_source
	if source_enemy != null:
		damage = source_enemy.scale_direct_attack_damage(damage)
		splash_damage = source_enemy.scale_direct_attack_damage(splash_damage)


func _ready() -> void:
	add_to_group("enemy_projectile")
	add_to_group("ranged_leftover_projectile")
	z_index = 32
	queue_redraw()


func _draw() -> void:
	var progress := clampf(traveled / maxf(travel_distance, 0.001), 0.0, 1.0)
	var height := sin(progress * PI) * arc_height
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, hit_radius * 0.92, Color(0.12, 0.09, 0.06, 0.34))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var food_position := Vector2(0.0, -height)
	var texture := CombatArtCatalog.get_texture(&"ranged_leftovers")
	var projectile_size := Vector2.ONE * maxf(24.0, hit_radius * 2.25)
	draw_texture_rect(texture, Rect2(food_position - projectile_size * 0.5, projectile_size), false)
	draw_circle(food_position - direction * 12.0 + Vector2(0.0, 3.0), 2.4, Color("8c5f43"))
	draw_circle(food_position - direction * 20.0 + Vector2(0.0, 6.0), 1.8, Color("e8d6a3"))


func _physics_process(delta: float) -> void:
	if resolved:
		return
	var remaining := maxf(0.0, travel_distance - traveled)
	var step_length := minf(speed * delta, remaining)
	var step := direction * step_length
	var next_position := global_position + step
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 1)
	var collision := get_world_2d().direct_space_state.intersect_ray(query)
	if not collision.is_empty():
		blocked_by_facility = true
		_resolve_without_splash()
		return
	var direct_target := _find_direct_target_on_segment(global_position, next_position)
	global_position = next_position
	traveled += step.length()
	queue_redraw()
	if direct_target != null:
		_apply_direct_hit(direct_target)
		_resolve_impact()
		return
	if traveled >= travel_distance - 0.01 or traveled >= max_distance:
		_resolve_impact()


func _find_direct_target_on_segment(from: Vector2, to: Vector2) -> Node2D:
	if intended_target == null or not is_instance_valid(intended_target):
		return null
	var target_radius := 18.0 if intended_target is PrototypePlayer else 16.0
	var closest := Geometry2D.get_closest_point_to_segment(intended_target.global_position, from, to)
	return intended_target if closest.distance_to(intended_target.global_position) <= hit_radius + target_radius else null


func _apply_direct_hit(hit_target: Node2D) -> void:
	var target_id := hit_target.get_instance_id()
	if direct_hit_ids.has(target_id):
		return
	direct_hit_ids[target_id] = true
	if hit_target is PrototypePlayer:
		var context := DamageContext.from_legacy(
			damage,
			CombatRules.Faction.ENEMY,
			CombatRules.Faction.PLAYER,
			false,
			source_enemy
		)
		(hit_target as PrototypePlayer).receive_damage_context(context, direction, knockback)
	elif hit_target is ShabuTrap:
		(hit_target as ShabuTrap).receive_enemy_attack(source_enemy)


func _resolve_impact() -> void:
	if resolved:
		return
	resolved = true
	_apply_splash()
	_spawn_impact()
	queue_free()


func _apply_splash() -> void:
	if splash_damage <= 0.0 or splash_radius <= 0.0:
		return
	for node in get_tree().get_nodes_in_group("player_target"):
		var player := node as PrototypePlayer
		if player == null or not is_instance_valid(player) or direct_hit_ids.has(player.get_instance_id()):
			continue
		if global_position.distance_to(player.global_position) > splash_radius:
			continue
		var context := DamageContext.from_legacy(
			splash_damage,
			CombatRules.Faction.ENEMY,
			CombatRules.Faction.PLAYER,
			false,
			source_enemy
		)
		player.receive_damage_context(context, direction, knockback * 0.55)
	for node in get_tree().get_nodes_in_group("shabu_trap"):
		var trap := node as ShabuTrap
		if trap == null or not is_instance_valid(trap) or direct_hit_ids.has(trap.get_instance_id()):
			continue
		if global_position.distance_to(trap.global_position) <= splash_radius:
			trap.receive_enemy_attack(source_enemy)


func _resolve_without_splash() -> void:
	if resolved:
		return
	resolved = true
	_spawn_impact()
	queue_free()


func _spawn_impact() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var burst := CombatVfxBurst.new()
	burst.setup(CombatVfxBurst.Kind.LEFTOVERS_IMPACT, global_position, splash_radius, Color("d8b77a"))
	parent.add_child(burst)
