class_name BasicTasteEnemy
extends CharacterBody2D

signal reflavor_completed(enemy: BasicTasteEnemy)

enum State { CHASE, WINDUP, ATTACK, RECOVERY, HIT_STUN, REFLAVORING, DISABLED, LURED, TASTING }

var config: PrototypeWaveConfig
var target: PrototypePlayer
var navigation: KitchenNavigationGrid
var state: int = State.CHASE
var current_health: float = 0.0
var state_time_left: float = 0.0
var chase_refresh_left: float = 0.0
var attack_cooldown_left: float = 0.0
var locked_attack_direction := Vector2.DOWN
var knockback_velocity := Vector2.ZERO
var current_path := PackedVector2Array()
var path_index: int = 0
var hit_flash_left: float = 0.0
var counted_reflavor: bool = false
var placeholder: PlaceholderVisual
var status_effects: DamageOverTimeController
var lure_target: ShabuTrap
var lure_path_fail_left: float = 0.0
var enemy_title: String = "基础味真族"
var enemy_color := Color("a94f64")
var enemy_visual_size := Vector2(50.0, 58.0)
var enemy_collision_radius: float = 14.0
var max_health_value: float = 60.0
var move_speed_value: float = 82.0
var attack_distance_value: float = 58.0
var attack_range_value: float = 78.0
var attack_width_value: float = 68.0
var windup_time_value: float = 0.36
var attack_active_time_value: float = 0.12
var recovery_time_value: float = 0.28
var attack_damage_value: float = 12.0
var player_knockback_value: float = 58.0
var attack_cooldown_value: float = 0.7
var hit_stun_time_value: float = 0.14
var stagger_threshold: float = 0.0
var knockback_multiplier: float = 1.0


func setup(enemy_config: PrototypeWaveConfig, player_target: PrototypePlayer, nav: KitchenNavigationGrid) -> void:
	config = enemy_config
	target = player_target
	navigation = nav
	_configure_basic_values()
	current_health = max_health_value


func _configure_basic_values() -> void:
	max_health_value = config.enemy_max_health
	move_speed_value = config.enemy_move_speed
	attack_distance_value = config.attack_distance
	attack_range_value = config.attack_range
	attack_width_value = config.attack_width
	windup_time_value = config.windup_time
	attack_active_time_value = config.attack_active_time
	recovery_time_value = config.recovery_time
	attack_damage_value = config.attack_damage
	player_knockback_value = config.player_knockback
	attack_cooldown_value = config.attack_cooldown
	hit_stun_time_value = config.hit_stun_time


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("basic_taste_enemy")
	collision_layer = 4
	collision_mask = 7
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = enemy_collision_radius
	collision.shape = circle
	add_child(collision)
	placeholder = PlaceholderVisual.new()
	add_child(placeholder)
	placeholder.configure(enemy_visual_size, enemy_color, enemy_title, _status_text())
	if not (self is HeavyTasteEnemy):
		PrototypeArtCatalog.apply_to(placeholder, &"basic_taste_enemy")
	status_effects = DamageOverTimeController.new()
	status_effects.name = "DamageOverTimeController"
	add_child(status_effects)


func _physics_process(delta: float) -> void:
	if config == null or state == State.DISABLED:
		velocity = Vector2.ZERO
		return
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	if state == State.REFLAVORING:
		_update_reflavor(delta)
		_refresh_visual()
		return
	if state == State.HIT_STUN:
		state_time_left -= delta
		_move_with_knockback(delta)
		if state_time_left <= 0.0:
			_enter_state(State.LURED if lure_target != null and is_instance_valid(lure_target) else State.CHASE)
		_refresh_visual()
		return
	match state:
		State.CHASE:
			_update_chase(delta)
		State.WINDUP:
			_update_timed_state(delta, State.ATTACK)
		State.ATTACK:
			_update_timed_state(delta, State.RECOVERY)
		State.RECOVERY:
			_update_timed_state(delta, State.CHASE)
		State.LURED:
			_update_lured(delta)
		State.TASTING:
			_update_tasting(delta)
	_refresh_visual()


func _update_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.is_defeated:
		velocity = Vector2.ZERO
		return
	if _try_acquire_lure():
		return
	if global_position.distance_to(target.global_position) <= attack_distance_value and attack_cooldown_left <= 0.0:
		locked_attack_direction = global_position.direction_to(target.global_position)
		_enter_state(State.WINDUP)
		return
	chase_refresh_left -= delta
	if chase_refresh_left <= 0.0:
		chase_refresh_left = config.chase_refresh_interval
		current_path = navigation.find_path(global_position, target.global_position) if navigation != null else PackedVector2Array([target.global_position])
		path_index = 0
	while path_index < current_path.size() and global_position.distance_to(current_path[path_index]) < 18.0:
		path_index += 1
	var desired := global_position.direction_to(target.global_position)
	if path_index < current_path.size():
		desired = global_position.direction_to(current_path[path_index])
	var separation := _get_separation_velocity()
	velocity = desired * move_speed_value + separation + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, config.knockback_decay * delta)


func _update_timed_state(delta: float, next_state: int) -> void:
	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, config.knockback_decay * delta)
	state_time_left -= delta
	if state_time_left <= 0.0:
		_enter_state(next_state)


func _enter_state(next_state: int) -> void:
	state = next_state
	match state:
		State.CHASE:
			state_time_left = 0.0
			chase_refresh_left = 0.0
		State.WINDUP:
			state_time_left = windup_time_value
			velocity = Vector2.ZERO
		State.ATTACK:
			state_time_left = attack_active_time_value
			_perform_locked_swing()
		State.RECOVERY:
			state_time_left = recovery_time_value
			attack_cooldown_left = attack_cooldown_value
		State.HIT_STUN:
			state_time_left = hit_stun_time_value
		State.REFLAVORING:
			state_time_left = config.reflavor_exit_time
			velocity = Vector2.ZERO
		State.LURED:
			state_time_left = 0.0
			chase_refresh_left = 0.0
			lure_path_fail_left = lure_target.config.shabu_lock_timeout if lure_target != null and is_instance_valid(lure_target) else 7.0
		State.TASTING:
			velocity = Vector2.ZERO
			state_time_left = lure_target.get_taste_duration() * get_trap_taste_time_multiplier() if lure_target != null and is_instance_valid(lure_target) else 0.0


func _perform_locked_swing() -> void:
	if target == null or not is_instance_valid(target) or target.is_defeated:
		return
	var offset := target.global_position - global_position
	var forward := offset.dot(locked_attack_direction)
	var side := absf(offset.dot(locked_attack_direction.orthogonal()))
	if forward >= 0.0 and forward <= attack_range_value and side <= attack_width_value * 0.5:
		target.receive_combat_hit(attack_damage_value, CombatRules.Faction.ENEMY, locked_attack_direction, player_knockback_value, false)


func _get_separation_velocity() -> Vector2:
	var separation := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("basic_taste_enemy"):
		var other := node as BasicTasteEnemy
		if other == null or other == self or other.state == State.REFLAVORING:
			continue
		var distance := global_position.distance_to(other.global_position)
		if distance > 0.01 and distance < config.separation_radius:
			separation += other.global_position.direction_to(global_position) * (1.0 - distance / config.separation_radius)
	return separation.limit_length(1.0) * config.separation_force


func _try_acquire_lure() -> bool:
	var nearest: ShabuTrap
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("shabu_trap"):
		var trap := node as ShabuTrap
		if trap == null or not trap.is_available_for(self):
			continue
		var distance := global_position.distance_to(trap.global_position)
		if distance < nearest_distance:
			nearest = trap
			nearest_distance = distance
	if nearest == null or not nearest.try_claim(self):
		return false
	lure_target = nearest
	_enter_state(State.LURED)
	return true


func _update_lured(delta: float) -> void:
	if lure_target == null or not is_instance_valid(lure_target) or lure_target.locked_enemy != self:
		lure_target = null
		_enter_state(State.CHASE)
		return
	if global_position.distance_to(lure_target.global_position) <= 30.0:
		_enter_state(State.TASTING)
		return
	chase_refresh_left -= delta
	if chase_refresh_left <= 0.0:
		chase_refresh_left = config.chase_refresh_interval
		current_path = navigation.find_path(global_position, lure_target.global_position) if navigation != null else PackedVector2Array([lure_target.global_position])
		path_index = 0
		if current_path.is_empty():
			lure_path_fail_left -= config.chase_refresh_interval
	while path_index < current_path.size() and global_position.distance_to(current_path[path_index]) < 18.0:
		path_index += 1
	if current_path.is_empty() or lure_path_fail_left <= 0.0:
		_release_lure()
		_enter_state(State.CHASE)
		return
	var desired := global_position.direction_to(lure_target.global_position)
	if path_index < current_path.size():
		desired = global_position.direction_to(current_path[path_index])
	velocity = desired * move_speed_value + _get_separation_velocity() + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, config.knockback_decay * delta)


func _update_tasting(delta: float) -> void:
	velocity = Vector2.ZERO
	state_time_left -= delta
	if state_time_left > 0.0:
		return
	var consumed_trap := lure_target
	lure_target = null
	if consumed_trap != null and is_instance_valid(consumed_trap):
		consumed_trap.consume_by(self)
	if state not in [State.REFLAVORING, State.DISABLED]:
		_enter_state(State.CHASE)


func _release_lure() -> void:
	if lure_target != null and is_instance_valid(lure_target):
		lure_target.release_claim(self)
	lure_target = null


func get_trap_taste_time_multiplier() -> float:
	return 1.0


func get_combat_faction() -> int:
	return CombatRules.Faction.ENEMY


func get_recipe_damage_multiplier(_attack_form: int, _cooking_method: int) -> float:
	# Prototype 0.4 reserves data tags only. Every current enemy multiplier is 1.0.
	return 1.0


func receive_combat_hit(damage: float, attacker_faction: int, knockback_direction: Vector2, knockback_force: float, friendly_fire: bool, stagger_power_value: float = 0.0) -> bool:
	if state in [State.REFLAVORING, State.DISABLED] or not CombatRules.can_damage(attacker_faction, get_combat_faction(), friendly_fire):
		return false
	current_health = maxf(0.0, current_health - damage)
	knockback_velocity += knockback_direction.normalized() * knockback_force * knockback_multiplier
	hit_flash_left = 0.12
	if current_health <= 0.0:
		_begin_reflavor()
	elif stagger_power_value >= stagger_threshold:
		_enter_state(State.HIT_STUN)
	return true


func apply_status_effect(effect: StatusEffectData) -> bool:
	return status_effects.apply_effect(effect) if status_effects != null and state != State.REFLAVORING else false


func receive_status_damage(damage: float, attacker_faction: int, _effect_type: int) -> bool:
	if state in [State.REFLAVORING, State.DISABLED] or not CombatRules.can_damage(attacker_faction, get_combat_faction(), false):
		return false
	current_health = maxf(0.0, current_health - damage)
	hit_flash_left = 0.16
	if current_health <= 0.0:
		_begin_reflavor()
	return true


func receive_trap_reflavor_damage(damage: float) -> bool:
	if state in [State.REFLAVORING, State.DISABLED]:
		return false
	current_health = maxf(0.0, current_health - damage)
	hit_flash_left = 0.16
	if current_health <= 0.0:
		_begin_reflavor()
	return true


func disable_for_failed_wave() -> void:
	_release_lure()
	state = State.DISABLED
	velocity = Vector2.ZERO


func _begin_reflavor() -> void:
	if state == State.REFLAVORING:
		return
	_release_lure()
	_enter_state(State.REFLAVORING)
	collision_layer = 0
	collision_mask = 0


func _update_reflavor(delta: float) -> void:
	state_time_left -= delta
	var ratio := clampf(state_time_left / maxf(config.reflavor_exit_time, 0.01), 0.0, 1.0)
	modulate.a = ratio
	scale = Vector2.ONE * lerpf(0.35, 1.0, ratio)
	if state_time_left <= 0.0 and not counted_reflavor:
		counted_reflavor = true
		reflavor_completed.emit(self)
		queue_free()


func _move_with_knockback(delta: float) -> void:
	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, config.knockback_decay * delta)


func _refresh_visual() -> void:
	if placeholder == null:
		return
	placeholder.set_color(Color.WHITE if hit_flash_left > 0.0 else _state_color())
	placeholder.set_status(_status_text())


func _status_text() -> String:
	var state_text: String = {
		State.CHASE: "追击",
		State.WINDUP: "挥击前摇！",
		State.ATTACK: "挥击",
		State.RECOVERY: "后摇",
		State.HIT_STUN: "受击僵直",
		State.REFLAVORING: "完成复味",
		State.DISABLED: "波次失败：停用",
		State.LURED: "被涮牛肉吸引",
		State.TASTING: "品尝涮牛肉",
	}.get(state, "未知")
	return "%s · HP %.0f/%.0f" % [state_text, current_health, max_health_value]


func _state_color() -> Color:
	match state:
		State.WINDUP:
			return Color("f4a261")
		State.ATTACK:
			return Color("ef233c")
		State.HIT_STUN:
			return Color("f8f9fa")
		State.REFLAVORING:
			return Color("8ecae6")
	return enemy_color
