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
var friendly_targets_hit: Dictionary = {}
var reflection_count: int = 0
var random_turn_warning_count: int = 0
var random := RandomNumberGenerator.new()
var visual: PlaceholderVisual
var visual_animator: RagingBullVisualAnimator


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
	PrototypeArtCatalog.apply_to(visual, &"raging_bull")
	visual.configure(config.raging_bull_visual_size, Color("d00000"), "⚠ 大型暴怒公牛", "友伤危险 · 注意躲避")
	var frames := load(
		"res://Assets/Combat/DishAttacks/StirFryRagingBull01/stir_fry_raging_bull_01_sprite_frames.tres"
	) as SpriteFrames
	visual_animator = RagingBullVisualAnimator.new()
	visual_animator.name = "RagingBullVisualAnimator"
	add_child(visual_animator)
	visual_animator.configure(visual, frames)
	visual_animator.set_direction(direction)


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
	if visual_animator != null:
		visual_animator.set_direction(direction)


func _update_random_turn(delta: float) -> void:
	if warning_left > 0.0:
		warning_left -= delta
		if warning_left <= 0.0:
			direction = pending_direction.normalized() if not pending_direction.is_zero_approx() else direction
			pending_direction = Vector2.ZERO
			if visual_animator != null:
				visual_animator.set_direction(direction)
			if visual != null:
				visual.set_status("友伤危险 · 注意躲避")
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
		var target_faction: int = target.get_combat_faction()
		var is_friendly_target := target_faction in [CombatRules.Faction.PLAYER, CombatRules.Faction.FRIENDLY]
		if is_friendly_target and friendly_targets_hit.has(target_id):
			continue
		if float(target_cooldowns.get(target_id, 0.0)) > 0.0:
			continue
		if global_position.distance_to(target.global_position) <= config.raging_bull_radius + 28.0:
			var hit_damage := config.raging_bull_friendly_fire_damage if is_friendly_target else config.raging_bull_damage
			var hit_knockback := config.raging_bull_friendly_knockback if is_friendly_target else config.raging_bull_knockback
			if target.receive_combat_hit(hit_damage, attacker_faction, direction, hit_knockback, true, config.raging_bull_stagger_power):
				if is_friendly_target:
					friendly_targets_hit[target_id] = true
				else:
					target_cooldowns[target_id] = config.raging_bull_hit_cooldown


func _update_target_cooldowns(delta: float) -> void:
	for target_id in target_cooldowns.keys():
		target_cooldowns[target_id] = maxf(0.0, float(target_cooldowns[target_id]) - delta)
