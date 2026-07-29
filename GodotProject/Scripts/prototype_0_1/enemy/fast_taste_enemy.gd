class_name FastTasteEnemy
extends BasicTasteEnemy

const STATE_CHARGING := 20
const STATE_DASHING := 21
const STATE_DASH_RECOVERY := 22

var dash_cooldown_left: float = 0.0
var dash_elapsed: float = 0.0
var dash_direction := Vector2.DOWN
var dash_target: Node2D
var direction_locked: bool = false
var dash_hit_ids: Dictionary = {}
var spawn_grace_left: float = 0.0
var charge_line: Line2D
var charge_audio: AudioStreamPlayer2D
var lock_cue_played: bool = false
var fast_character_animator: FastEnemyCharacterAnimator


func setup(enemy_config: PrototypeWaveConfig, player_target: PrototypePlayer, nav: KitchenNavigationGrid) -> void:
	super.setup(enemy_config, player_target, nav)
	enemy_title = "速度型味真族（暂名）"
	enemy_color = Color("5b8e7d")
	enemy_visual_size = Vector2(50.0, 58.0)
	enemy_collision_radius = 13.0
	max_health_value = config.enemy_max_health * config.fast_max_health_multiplier
	move_speed_value = config.enemy_move_speed * config.fast_move_speed_multiplier
	current_health = max_health_value
	spawn_grace_left = config.fast_spawn_grace_time


func _ready() -> void:
	super._ready()
	add_to_group("fast_taste_enemy")
	# Keep the previous sheet as an immediate rollback fallback, then let the
	# dedicated animator hide it while the candidate PixelLab set is active.
	PrototypeArtCatalog.apply_to(placeholder, &"fast_taste_enemy_walk_sheet")
	if walk_animator != null:
		walk_animator.queue_free()
		walk_animator = null
	var frames := load(
		"res://Assets/Characters/Enemies/FastTasteEnemy01/fast_taste_enemy_01_sprite_frames.tres"
	) as SpriteFrames
	fast_character_animator = FastEnemyCharacterAnimator.new()
	fast_character_animator.name = "FastEnemyCharacterAnimator"
	add_child(fast_character_animator)
	fast_character_animator.configure(placeholder, frames)
	charge_line = Line2D.new()
	charge_line.name = "DashDirectionTelegraph"
	charge_line.width = 7.0
	charge_line.default_color = Color(1.0, 0.35, 0.18, 0.82)
	charge_line.points = PackedVector2Array([Vector2.ZERO, Vector2.DOWN * 210.0])
	charge_line.visible = false
	charge_line.z_index = -1
	add_child(charge_line)
	charge_audio = AudioStreamPlayer2D.new()
	charge_audio.name = "PrototypeDashCue"
	charge_audio.bus = &"SFX"
	charge_audio.stream = _make_dash_cue_stream()
	charge_audio.max_distance = 760.0
	charge_audio.volume_db = -8.0
	add_child(charge_audio)


func _physics_process(delta: float) -> void:
	if config == null or state == State.DISABLED:
		velocity = Vector2.ZERO
		return
	if state in [State.REFLAVORING, State.HIT_STUN, State.LURED, State.TASTING]:
		if state == State.HIT_STUN and charge_line != null:
			charge_line.visible = false
		super._physics_process(delta)
		return
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	spawn_grace_left = maxf(0.0, spawn_grace_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	match state:
		State.CHASE:
			_update_fast_chase(delta)
		STATE_CHARGING:
			_update_charge(delta)
		STATE_DASHING:
			_update_dash(delta)
		STATE_DASH_RECOVERY:
			_update_dash_recovery(delta)
	_update_dash_pose()
	_refresh_visual()


func _update_fast_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.is_defeated:
		velocity = Vector2.ZERO
		return
	var candidate := EnemyTargetProvider.choose_target(self, target)
	var claimed := EnemyTargetProvider.try_claim_if_lure(self, candidate)
	if claimed != null:
		lure_target = claimed
		_enter_state(State.LURED)
		return
	var distance := global_position.distance_to(target.global_position)
	if spawn_grace_left <= 0.0 and dash_cooldown_left <= 0.0 and distance <= config.fast_charge_trigger_distance and distance >= 72.0:
		dash_target = target
		dash_direction = global_position.direction_to(target.global_position)
		direction_locked = false
		lock_cue_played = false
		dash_elapsed = 0.0
		state = STATE_CHARGING
		velocity = Vector2.ZERO
		charge_line.visible = true
		charge_audio.pitch_scale = 0.82
		charge_audio.play()
		return
	chase_refresh_left -= delta
	var goal := get_chase_goal_position()
	if chase_refresh_left <= 0.0:
		chase_refresh_left = config.chase_refresh_interval
		current_path = navigation.find_path(global_position, goal) if navigation != null else PackedVector2Array([goal])
		path_index = 0
	while path_index < current_path.size() and global_position.distance_to(current_path[path_index]) < 18.0:
		path_index += 1
	var desired := global_position.direction_to(current_path[path_index]) if path_index < current_path.size() else global_position.direction_to(goal)
	_move_chasing(desired, delta, true)


func _update_charge(delta: float) -> void:
	velocity = Vector2.ZERO
	dash_elapsed += delta
	var lock_time := config.fast_charge_windup_time * config.fast_direction_lock_ratio
	if not direction_locked:
		var candidate := EnemyTargetProvider.choose_target(self, target)
		if candidate is ShabuTrap:
			var claimed := EnemyTargetProvider.try_claim_if_lure(self, candidate)
			if claimed != null:
				lure_target = claimed
				dash_target = claimed
		elif candidate != null:
			dash_target = candidate
		if dash_target != null and is_instance_valid(dash_target):
			dash_direction = global_position.direction_to(dash_target.global_position)
		if dash_elapsed >= lock_time:
			if combat_statuses != null and combat_statuses.has_status(CombatStatusController.StatusType.AIM_DISRUPTION):
				var runtime := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
				var degrees := runtime.config.choking_aim_degrees if runtime != null else 0.0
				dash_direction = dash_direction.rotated(
					deg_to_rad(degrees) * (-1.0 if get_instance_id() % 2 == 0 else 1.0)
				)
			direction_locked = true
			if not lock_cue_played:
				lock_cue_played = true
				charge_audio.pitch_scale = 1.35
				charge_audio.play()
	if charge_line != null:
		charge_line.points = PackedVector2Array([Vector2.ZERO, dash_direction * 230.0])
		charge_line.default_color = Color("ff2d55") if direction_locked else Color("ff9f1c")
	if dash_elapsed >= config.fast_charge_windup_time:
		state = STATE_DASHING
		dash_elapsed = 0.0
		dash_hit_ids.clear()
		charge_line.visible = false


func _update_dash(delta: float) -> void:
	dash_elapsed += delta
	velocity = dash_direction * config.fast_dash_speed
	var collision := move_and_collide(velocity * delta)
	if _try_dash_hit_target():
		_begin_dash_recovery(config.fast_hit_recovery)
		return
	if collision != null:
		_begin_dash_recovery(config.fast_wall_recovery)
		notify_stunned_visual()
		return
	if navigation != null and not navigation.is_position_walkable(global_position):
		global_position -= velocity * delta
		_begin_dash_recovery(config.fast_wall_recovery)
		notify_stunned_visual()
		return
	if dash_elapsed >= config.fast_dash_time:
		_begin_dash_recovery(config.fast_miss_recovery)


func _try_dash_hit_target() -> bool:
	if dash_target == null or not is_instance_valid(dash_target):
		return false
	if global_position.distance_to(dash_target.global_position) > enemy_collision_radius + 28.0:
		return false
	var target_id := dash_target.get_instance_id()
	if dash_hit_ids.has(target_id):
		return false
	dash_hit_ids[target_id] = true
	if dash_target is PrototypePlayer:
		return (dash_target as PrototypePlayer).receive_combat_hit(
			scale_direct_attack_damage(config.fast_dash_damage),
			CombatRules.Faction.ENEMY,
			dash_direction,
			config.fast_dash_knockback,
			false
		)
	if dash_target is ShabuTrap:
		(dash_target as ShabuTrap).receive_enemy_attack(self)
		return true
	return false


func _begin_dash_recovery(duration: float) -> void:
	state = STATE_DASH_RECOVERY
	state_time_left = duration
	dash_cooldown_left = config.fast_dash_cooldown
	velocity = Vector2.ZERO
	if lure_target != null and is_instance_valid(lure_target):
		lure_target.release_claim(self)
	lure_target = null
	dash_target = null


func _update_dash_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	state_time_left -= delta
	if state_time_left <= 0.0:
		state = State.CHASE
		chase_refresh_left = 0.0


func notify_stunned_visual() -> void:
	hit_flash_left = maxf(hit_flash_left, config.fast_wall_recovery)


func _update_dash_pose() -> void:
	if placeholder == null:
		return
	# The native crouch sequence now communicates the charge. Do not squash the
	# whole visual node, which would distort the supplied pixel frames.
	placeholder.scale = Vector2.ONE


func _refresh_visual() -> void:
	super._refresh_visual()
	if fast_character_animator == null:
		return
	var visual_motion := velocity if state in [State.CHASE, State.LURED] else Vector2.ZERO
	var is_slowed := combat_statuses != null and combat_statuses.get_move_speed_multiplier() < 0.999
	var action_phase := FastEnemyCharacterAnimator.ActionPhase.NONE
	if state == STATE_CHARGING:
		action_phase = FastEnemyCharacterAnimator.ActionPhase.CHARGING
	elif state == STATE_DASHING:
		action_phase = FastEnemyCharacterAnimator.ActionPhase.POUNCING
	elif state == STATE_DASH_RECOVERY:
		action_phase = FastEnemyCharacterAnimator.ActionPhase.RECOVERY
	fast_character_animator.update_animation(
		action_phase,
		visual_motion,
		dash_direction,
		is_slowed,
		state == State.REFLAVORING,
		hit_flash_left > 0.0
	)


func _make_dash_cue_stream() -> AudioStreamWAV:
	# Generated technical cue only; this is not a final sound asset.
	var sample_rate := 22050
	var duration := 0.13
	var sample_count := roundi(sample_rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in sample_count:
		var envelope := 1.0 - float(index) / float(sample_count)
		var sample := roundi(sin(TAU * 520.0 * float(index) / float(sample_rate)) * envelope * 9000.0)
		pcm[index * 2] = sample & 0xff
		pcm[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream


func is_special_enemy() -> bool:
	return true


func get_enemy_archetype_key() -> StringName:
	return &"fast"


func _status_text() -> String:
	var label := "追赶"
	match state:
		STATE_CHARGING:
			label = "冲刺蓄力%s" % (" · 已锁定" if direction_locked else "")
		STATE_DASHING:
			label = "直线冲刺"
		STATE_DASH_RECOVERY:
			label = "冲刺后摇 / 眩晕"
		State.HIT_STUN:
			label = "冲刺被打断"
		State.REFLAVORING:
			label = "完成复味"
		State.LURED:
			label = "被涮牛肉吸引"
		State.TASTING:
			label = "品尝涮牛肉"
	return "%s · HP %.0f/%.0f" % [label, current_health, max_health_value]
