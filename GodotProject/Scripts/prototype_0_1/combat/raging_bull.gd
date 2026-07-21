class_name RagingBull
extends Node2D

var direction := Vector2.RIGHT
var attacker_faction: int = CombatRules.Faction.PLAYER
var config: PrototypeCombatConfig
var lifetime_left: float = 0.0
var turn_check_left: float = 0.0
var warning_left: float = 0.0
var pending_direction := Vector2.ZERO
var target_cooldowns: Dictionary = {}
var reflection_count: int = 0
var random_turn_warning_count: int = 0
var random := RandomNumberGenerator.new()
var visual: PlaceholderVisual


func setup(
	spawn_position: Vector2,
	move_direction: Vector2,
	combat_config: PrototypeCombatConfig,
	spawn_faction: int = CombatRules.Faction.PLAYER
) -> void:
	global_position = spawn_position
	direction = move_direction.normalized() if not move_direction.is_zero_approx() else Vector2.RIGHT
	config = combat_config
	attacker_faction = spawn_faction
	lifetime_left = config.raging_bull_duration
	turn_check_left = config.random_turn_check_interval


func _ready() -> void:
	add_to_group("raging_bull")
	random.randomize()
	visual = PlaceholderVisual.new()
	add_child(visual)
	visual.configure(config.raging_bull_visual_size, Color("a51d2d"), "大型暴怒公牛", "横冲直撞 · 会友伤")
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()
		return
	_update_target_cooldowns(delta)
	_update_random_turn(delta)
	if warning_left <= 0.0:
		_move_and_reflect(delta)
		_hit_targets_with_cooldown()


func force_random_turn_warning_for_test(new_direction: Vector2) -> void:
	pending_direction = new_direction.normalized()
	warning_left = config.random_turn_warning_time
	random_turn_warning_count += 1
	if visual != null:
		visual.set_status("转向预警！")


func _move_and_reflect(delta: float) -> void:
	var min_x := config.combat_bounds.position.x + config.raging_bull_radius
	var max_x := config.combat_bounds.end.x - config.raging_bull_radius
	var min_y := config.combat_bounds.position.y + config.raging_bull_radius
	var max_y := config.combat_bounds.end.y - config.raging_bull_radius
	var travel_distance := config.raging_bull_speed * delta
	var substeps := maxi(1, ceili(travel_distance / maxf(config.raging_bull_radius * 0.45, 8.0)))
	var step_distance := travel_distance / float(substeps)
	for _step in substeps:
		var next_position := global_position + direction * step_distance
		var reflected := false
		if next_position.x < min_x or next_position.x > max_x:
			direction.x = -direction.x
			reflected = true
		if next_position.y < min_y or next_position.y > max_y:
			direction.y = -direction.y
			reflected = true
		if reflected:
			reflection_count += 1
			direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
			next_position = global_position + direction * step_distance
		global_position = Vector2(clampf(next_position.x, min_x, max_x), clampf(next_position.y, min_y, max_y))
	rotation = direction.angle()


func _update_random_turn(delta: float) -> void:
	if warning_left > 0.0:
		warning_left -= delta
		if warning_left <= 0.0:
			direction = pending_direction.normalized() if not pending_direction.is_zero_approx() else direction
			pending_direction = Vector2.ZERO
			if visual != null:
				visual.set_status("横冲直撞 · 会友伤")
		return
	turn_check_left -= delta
	if turn_check_left > 0.0:
		return
	turn_check_left = config.random_turn_check_interval
	if random.randf() <= config.random_turn_chance:
		force_random_turn_warning_for_test(Vector2.RIGHT.rotated(random.randf_range(-PI, PI)))


func _hit_targets_with_cooldown() -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_combat_hit"):
			continue
		var target_id := target.get_instance_id()
		if float(target_cooldowns.get(target_id, 0.0)) > 0.0:
			continue
		if global_position.distance_to(target.global_position) <= config.raging_bull_radius + 28.0:
			if target.receive_combat_hit(config.raging_bull_damage, attacker_faction, direction, config.raging_bull_knockback, true, config.raging_bull_stagger_power):
				target_cooldowns[target_id] = config.raging_bull_hit_cooldown


func _update_target_cooldowns(delta: float) -> void:
	for target_id in target_cooldowns.keys():
		target_cooldowns[target_id] = maxf(0.0, float(target_cooldowns[target_id]) - delta)
