class_name RangedTasteEnemy
extends BasicTasteEnemy

signal volley_projectile_fired(shot_index: int, landing_position: Vector2, projectile: RangedFlavorProjectile)
signal volley_finished

const STATE_SEEK := 30
const STATE_EATING := 31
const STATE_RETCH_WINDUP := 32
const STATE_VOLLEY := 33
const STATE_SHOOT_RECOVERY := 34
const STATE_SHOVE_WINDUP := 35
const STATE_SHOVE_RECOVERY := 36
# Compatibility alias for the previous 0.6B single-shot test/debug entry.
const STATE_AIM := STATE_RETCH_WINDUP

var ranged_state: int = STATE_SEEK
var aim_elapsed: float = 0.0
var locked_target_position := Vector2.ZERO
var aim_locked: bool = false
var combat_target: Node2D
var shots_from_position: int = 0
var fire_cooldown_left: float = 0.0
var volley_shot_index: int = 0
var volley_interval_left: float = 0.0
var locked_landing_positions: Array[Vector2] = []
var center_target_marker: TargetMarker
var landing_markers: Array[TargetMarker] = []
var ranged_character_animator: Node


class TargetMarker:
	extends Node2D
	var radius := 24.0
	var locked := false

	func configure(marker_radius: float, is_locked: bool) -> void:
		radius = marker_radius
		locked = is_locked
		queue_redraw()

	func _draw() -> void:
		var primary := Color(0.96, 0.62, 0.20, 0.94) if locked else Color(0.96, 0.82, 0.38, 0.78)
		var fill := Color(primary.r, primary.g, primary.b, 0.13 if locked else 0.08)
		draw_circle(Vector2.ZERO, radius, fill)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, primary, 3.0 if locked else 2.0)
		draw_line(Vector2(-radius, 0), Vector2(radius, 0), Color(primary.r, primary.g, primary.b, 0.68), 2.0)
		draw_line(Vector2(0, -radius), Vector2(0, radius), Color(primary.r, primary.g, primary.b, 0.68), 2.0)


func setup(enemy_config: PrototypeWaveConfig, player_target: PrototypePlayer, nav: KitchenNavigationGrid) -> void:
	super.setup(enemy_config, player_target, nav)
	enemy_title = "远程型味真族（暂名）"
	enemy_color = Color("6d597a")
	enemy_visual_size = Vector2(54.0, 62.0)
	enemy_collision_radius = 14.0
	max_health_value = config.enemy_max_health * config.ranged_max_health_multiplier
	move_speed_value = config.enemy_move_speed * config.ranged_move_speed_multiplier
	current_health = max_health_value
	state = STATE_SEEK


func _ready() -> void:
	super._ready()
	add_to_group("ranged_taste_enemy")
	center_target_marker = _create_target_marker("AimCenterMarker", 24.0, false)
	for index in config.ranged_volley_count:
		landing_markers.append(_create_target_marker("LandingMarker_%d" % (index + 1), 18.0, true))
	ranged_character_animator = RangedEnemyCharacterAnimator.new()
	ranged_character_animator.name = "RangedEnemyCharacterAnimator"
	add_child(ranged_character_animator)
	ranged_character_animator.configure(placeholder)
	if walk_animator != null:
		walk_animator.set_process(false)


func _physics_process(delta: float) -> void:
	if config == null or state == State.DISABLED:
		velocity = Vector2.ZERO
		_hide_all_markers()
		return
	if state in [State.REFLAVORING, State.HIT_STUN, State.LURED, State.TASTING]:
		_cancel_pending_volley()
		super._physics_process(delta)
		return
	fire_cooldown_left = maxf(0.0, fire_cooldown_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	match state:
		STATE_SEEK:
			_update_seek(delta)
		STATE_EATING:
			_update_eating(delta)
		STATE_RETCH_WINDUP:
			_update_retch_windup(delta)
		STATE_VOLLEY:
			_update_volley(delta)
		STATE_SHOOT_RECOVERY:
			_update_shoot_recovery(delta)
		STATE_SHOVE_WINDUP:
			_update_shove_windup(delta)
		STATE_SHOVE_RECOVERY:
			_update_shove_recovery(delta)
	_refresh_visual()
	if walk_animator != null:
		walk_animator.update_animation(delta, velocity)


func _update_seek(delta: float) -> void:
	combat_target = EnemyTargetProvider.choose_target(self, target)
	var claimed := EnemyTargetProvider.try_claim_if_lure(self, combat_target)
	if claimed != null:
		lure_target = claimed
		combat_target = claimed
	var destination := combat_target.global_position if combat_target != null and is_instance_valid(combat_target) else target.global_position
	var distance := global_position.distance_to(destination)
	if combat_target is PrototypePlayer and distance <= config.ranged_close_distance:
		state = STATE_SHOVE_WINDUP
		state_time_left = config.ranged_shove_windup
		velocity = Vector2.ZERO
		return
	if (
		fire_cooldown_left <= 0.0
		and distance >= config.ranged_preferred_min_distance
		and distance <= config.ranged_preferred_max_distance
		and _has_line_of_sight(destination)
	):
		_begin_ranged_attack(destination)
		return
	var desired_goal := _get_reachable_firing_goal(destination)
	chase_refresh_left -= delta
	if chase_refresh_left <= 0.0:
		chase_refresh_left = config.chase_refresh_interval
		current_path = navigation.find_path(global_position, desired_goal) if navigation != null else PackedVector2Array([desired_goal])
		path_index = 0
	while path_index < current_path.size() and global_position.distance_to(current_path[path_index]) < 18.0:
		path_index += 1
	var desired := global_position.direction_to(current_path[path_index]) if path_index < current_path.size() else global_position.direction_to(desired_goal)
	_move_chasing(desired, delta, true)


func _begin_ranged_attack(initial_target_position: Vector2) -> void:
	state = STATE_EATING
	state_time_left = config.ranged_eating_time / _get_attack_speed_multiplier()
	fire_cooldown_left = config.ranged_attack_cycle_interval / _get_attack_speed_multiplier()
	aim_elapsed = 0.0
	aim_locked = false
	locked_target_position = initial_target_position
	locked_landing_positions.clear()
	velocity = Vector2.ZERO
	_hide_all_markers()


func _update_eating(delta: float) -> void:
	velocity = Vector2.ZERO
	state_time_left -= delta
	if state_time_left > 0.0:
		return
	state = STATE_RETCH_WINDUP
	aim_elapsed = 0.0
	aim_locked = false
	locked_landing_positions.clear()


# Kept as a small compatibility wrapper for old debug/test callers.
func _update_aim(delta: float) -> void:
	_update_retch_windup(delta)


func _update_retch_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	if combat_target == null or not is_instance_valid(combat_target):
		_cancel_pending_volley()
		state = STATE_SEEK
		return
	aim_elapsed += delta
	if not aim_locked:
		locked_target_position = combat_target.global_position
		_show_tracking_marker(locked_target_position)
		if aim_elapsed >= config.ranged_retch_windup_time * config.ranged_lock_ratio:
			_lock_volley_positions(locked_target_position)
	if aim_elapsed < config.ranged_retch_windup_time:
		return
	if not aim_locked:
		_lock_volley_positions(locked_target_position)
	state = STATE_VOLLEY
	volley_shot_index = 0
	volley_interval_left = 0.0


func _update_volley(delta: float) -> void:
	velocity = Vector2.ZERO
	if locked_landing_positions.size() != config.ranged_volley_count:
		_cancel_pending_volley()
		state = STATE_SEEK
		return
	volley_interval_left = maxf(0.0, volley_interval_left - delta)
	if volley_interval_left > 0.0:
		return
	_fire_volley_projectile(volley_shot_index)
	volley_shot_index += 1
	if volley_shot_index >= config.ranged_volley_count:
		_hide_all_markers()
		state = STATE_SHOOT_RECOVERY
		state_time_left = config.ranged_shoot_recovery / _get_attack_speed_multiplier()
		shots_from_position += 1
		volley_finished.emit()
		return
	volley_interval_left = config.ranged_volley_interval / _get_attack_speed_multiplier()


func _fire_volley_projectile(shot_index: int) -> RangedFlavorProjectile:
	if shot_index < 0 or shot_index >= locked_landing_positions.size():
		return null
	var landing_position := locked_landing_positions[shot_index]
	var projectile := RangedFlavorProjectile.new()
	get_tree().current_scene.add_child(projectile)
	projectile.setup(
		global_position,
		landing_position,
		config,
		combat_target if is_instance_valid(combat_target) else null,
		self
	)
	if shot_index < landing_markers.size():
		landing_markers[shot_index].visible = false
	volley_projectile_fired.emit(shot_index, landing_position, projectile)
	return projectile


func _update_shoot_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	state_time_left -= delta
	if state_time_left > 0.0:
		return
	if shots_from_position >= config.ranged_shots_before_reposition:
		shots_from_position = 0
		chase_slot_index += 2
	state = STATE_SEEK
	chase_refresh_left = 0.0


func _update_shove_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	state_time_left -= delta
	if state_time_left > 0.0:
		return
	if target != null and global_position.distance_to(target.global_position) <= config.ranged_close_distance + 20.0:
		target.receive_combat_hit(scale_direct_attack_damage(config.ranged_shove_damage), CombatRules.Faction.ENEMY, global_position.direction_to(target.global_position), config.ranged_shove_knockback, false)
	state = STATE_SHOVE_RECOVERY
	state_time_left = config.ranged_shove_recovery


func _update_shove_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	state_time_left -= delta
	if state_time_left <= 0.0:
		state = STATE_SEEK
		chase_refresh_left = 0.0


func _get_reachable_firing_goal(target_position: Vector2) -> Vector2:
	var away := target_position.direction_to(global_position)
	if away.is_zero_approx():
		away = Vector2.RIGHT
	var desired_distance := (config.ranged_preferred_min_distance + config.ranged_preferred_max_distance) * 0.5
	var base := target_position + away * desired_distance
	for index in 8:
		var candidate := target_position + away.rotated(float(index - 3) * PI / 8.0) * desired_distance
		if navigation == null or navigation.is_position_walkable(candidate):
			if _has_line_of_sight_from(candidate, target_position):
				return candidate
	return base


func _has_line_of_sight(target_position: Vector2) -> bool:
	return _has_line_of_sight_from(global_position, target_position)


func _has_line_of_sight_from(origin: Vector2, target_position: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var query := PhysicsRayQueryParameters2D.create(origin, target_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _lock_volley_positions(center: Vector2) -> void:
	aim_locked = true
	locked_target_position = center
	locked_landing_positions = _build_spread_positions(center)
	if combat_statuses != null and combat_statuses.has_status(CombatStatusController.StatusType.AIM_DISRUPTION):
		for index in locked_landing_positions.size():
			locked_landing_positions[index] = _apply_aim_disruption(locked_landing_positions[index])
	_hide_tracking_marker()
	for index in landing_markers.size():
		var marker := landing_markers[index]
		marker.visible = index < locked_landing_positions.size()
		if marker.visible:
			marker.global_position = locked_landing_positions[index]


func _build_spread_positions(center: Vector2) -> Array[Vector2]:
	var forward := global_position.direction_to(center)
	if forward.is_zero_approx():
		forward = Vector2.DOWN
	var side := forward.orthogonal()
	var spread := config.ranged_volley_spread
	return [
		center - side * spread - forward * spread * 0.25,
		center,
		center + side * spread + forward * spread * 0.25,
	]


func _apply_aim_disruption(position: Vector2) -> Vector2:
	var runtime := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	var degrees := runtime.config.choking_aim_degrees if runtime != null else 18.0
	var shot_direction := global_position.direction_to(position)
	var shot_distance := global_position.distance_to(position)
	if shot_direction.is_zero_approx():
		shot_direction = Vector2.DOWN
	return global_position + shot_direction.rotated(
		deg_to_rad(randf_range(-degrees, degrees))
	) * shot_distance


func _create_target_marker(marker_name: String, marker_radius: float, locked: bool) -> TargetMarker:
	var marker := TargetMarker.new()
	marker.name = marker_name
	marker.top_level = true
	marker.visible = false
	marker.z_index = 40
	marker.configure(marker_radius, locked)
	add_child(marker)
	return marker


func _show_tracking_marker(position: Vector2) -> void:
	if center_target_marker == null:
		return
	center_target_marker.global_position = position
	center_target_marker.visible = true


func _hide_tracking_marker() -> void:
	if center_target_marker != null:
		center_target_marker.visible = false


func _hide_all_markers() -> void:
	_hide_tracking_marker()
	for marker in landing_markers:
		if marker != null and is_instance_valid(marker):
			marker.visible = false


func _cancel_pending_volley() -> void:
	_hide_all_markers()
	aim_elapsed = 0.0
	aim_locked = false
	locked_landing_positions.clear()
	volley_shot_index = 0
	volley_interval_left = 0.0


func _enter_state(next_state: int) -> void:
	if next_state == State.CHASE:
		_cancel_pending_volley()
		state = STATE_SEEK
		state_time_left = 0.0
		chase_refresh_left = 0.0
		_reset_stuck_tracking()
		return
	if next_state in [State.HIT_STUN, State.REFLAVORING, State.DISABLED, State.LURED, State.TASTING]:
		_cancel_pending_volley()
	super._enter_state(next_state)


func disable_for_failed_wave() -> void:
	_cancel_pending_volley()
	super.disable_for_failed_wave()


func is_special_enemy() -> bool:
	return true


func get_enemy_archetype_key() -> StringName:
	return &"ranged"


func _status_text() -> String:
	var label := "寻找射击位置"
	match state:
		STATE_EATING:
			label = "吞食蓄能"
		STATE_RETCH_WINDUP:
			label = "催吐预警%s" % (" · 三点已锁定" if aim_locked else " · 跟踪中")
		STATE_VOLLEY:
			label = "连续喷吐 %d/%d" % [mini(volley_shot_index + 1, config.ranged_volley_count), config.ranged_volley_count]
		STATE_SHOOT_RECOVERY:
			label = "喷吐后摇"
		STATE_SHOVE_WINDUP:
			label = "近身推击前摇"
		STATE_SHOVE_RECOVERY:
			label = "推击硬直"
		State.HIT_STUN:
			label = "瞄准被打断"
		State.REFLAVORING:
			label = "完成复味"
		State.LURED:
			label = "寻找诱饵射线"
		State.TASTING:
			label = "攻击诱饵"
	return "%s · HP %.0f/%.0f" % [label, current_health, max_health_value]


func _state_color() -> Color:
	match state:
		STATE_EATING:
			return Color("d8b26e")
		STATE_RETCH_WINDUP:
			return Color("e9c46a") if not aim_locked else Color("f4a261")
		STATE_VOLLEY:
			return Color("e76f51")
		STATE_SHOOT_RECOVERY:
			return Color("8d6e63")
		STATE_SHOVE_WINDUP:
			return Color("f4a261")
		STATE_SHOVE_RECOVERY:
			return Color("7b6d8d")
	return super._state_color()


func _refresh_visual() -> void:
	super._refresh_visual()
	if placeholder != null:
		var pulse := 1.0
		if state == STATE_EATING:
			pulse = 1.0 + 0.035 * sin(Time.get_ticks_msec() * 0.014)
		elif state == STATE_RETCH_WINDUP:
			pulse = 1.0 + 0.055 * clampf(
				aim_elapsed / maxf(config.ranged_retch_windup_time, 0.01),
				0.0,
				1.0
			)
		elif state == STATE_VOLLEY:
			pulse = 0.94
		placeholder.scale = Vector2(pulse, 2.0 - pulse)
	if ranged_character_animator != null and ranged_character_animator.has_method("update_state"):
		ranged_character_animator.call(
			"update_state",
			state,
			velocity,
			locked_target_position,
			hit_flash_left > 0.0
		)
