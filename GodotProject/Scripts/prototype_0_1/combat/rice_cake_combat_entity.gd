class_name RiceCakeCombatEntity
extends Node2D

enum Mode { BOOMERANG, GREENS_ORBIT, BEEF_BOUNCE, MIXED_ORBIT, SPLITTER, CORE_SPLITTER }

var mode: int = Mode.BOOMERANG
var owner_player: Node2D
var dish_data: ItemData
var direction := Vector2.RIGHT
var start_position := Vector2.ZERO
var traveled: float = 0.0
var returning: bool = false
var phase_hits: Dictionary = {}
var elapsed: float = 0.0
var angle: float = 0.0
var hit_cooldowns: Dictionary = {}
var remaining_hits: int = 0
var split_count: int = 0
var split_left: float = 0.0
var attack_left: float = 0.0
var resolved: bool = false


func setup(entity_mode: int, player: Node2D, source_data: ItemData, attack_direction: Vector2) -> void:
	mode = entity_mode
	owner_player = player
	dish_data = ItemCatalog.duplicate_data(source_data)
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	start_position = player.global_position
	global_position = start_position + direction * 28.0
	remaining_hits = maxi(1, dish_data.max_durability)
	split_left = float(dish_data.effect_values.get("split_interval", 1.25))


func setup_splitter(player: Node2D, source_data: ItemData, core: bool) -> void:
	setup(Mode.CORE_SPLITTER if core else Mode.SPLITTER, player, source_data, Vector2.RIGHT)
	remaining_hits = int(dish_data.effect_values.get("core_hits", 5)) if core else int(dish_data.effect_values.get("split_hits", 3))
	attack_left = 0.05


func _ready() -> void:
	add_to_group("temporary_attack_entity")
	add_to_group("run_deployable")
	z_index = 19
	queue_redraw()


func _draw() -> void:
	var key := &"rice_cake_plain"
	if mode == Mode.GREENS_ORBIT:
		key = &"rice_cake_greens"
	elif mode in [Mode.BEEF_BOUNCE, Mode.SPLITTER]:
		key = &"rice_cake_beef"
	elif mode in [Mode.MIXED_ORBIT, Mode.CORE_SPLITTER]:
		key = &"rice_cake_greens_beef"
	var texture := CombatArtCatalog.get_texture(key)
	var size := Vector2.ONE * (50.0 if mode == Mode.CORE_SPLITTER else 40.0)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
	draw_arc(Vector2.ZERO, size.x * 0.43, 0.0, TAU, 24, Color(1.0, 0.76, 0.28, 0.32), 2.0)


func _physics_process(delta: float) -> void:
	if resolved or owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return
	elapsed += delta
	rotation += delta * (5.5 if returning else 3.4)
	_advance_cooldowns(delta)
	match mode:
		Mode.BOOMERANG:
			_process_boomerang(delta)
		Mode.GREENS_ORBIT:
			_process_greens_orbit(delta)
		Mode.BEEF_BOUNCE:
			_process_bounce(delta)
		Mode.MIXED_ORBIT:
			_process_mixed_orbit(delta)
		Mode.SPLITTER, Mode.CORE_SPLITTER:
			_process_splitter(delta)


func _process_boomerang(delta: float) -> void:
	var speed := float(dish_data.effect_values.get("speed", 430.0))
	var max_range := float(dish_data.effect_values.get("range", 360.0))
	var target_direction := global_position.direction_to(owner_player.global_position) if returning else direction
	var step := target_direction * speed * delta
	if not returning:
		traveled += step.length()
		if traveled >= max_range or _blocked(global_position, global_position + step):
			returning = true
			phase_hits.clear()
	else:
		if global_position.distance_to(owner_player.global_position) <= step.length() + 18.0:
			if dish_data.quality == ItemData.Quality.PERFECT and dish_data.has_perfect_finisher:
				_resolve_return_orbit()
			else:
				queue_free()
			return
	global_position += step
	var max_hits := 999 if dish_data.quality == ItemData.Quality.PERFECT and dish_data.has_perfect_finisher else int(dish_data.effect_values.get("pierce", 3))
	for target in _enemies_in_radius(global_position, 19.0):
		var id := target.get_instance_id()
		if phase_hits.has(id) or phase_hits.size() >= max_hits:
			continue
		phase_hits[id] = true
		var amount := (
			float(dish_data.effect_values.get("perfect_return_damage", 18.0)) if returning else float(dish_data.effect_values.get("perfect_out_damage", 22.0))
		) if dish_data.quality == ItemData.Quality.PERFECT and dish_data.has_perfect_finisher else (
			float(dish_data.effect_values.get("return_damage", 12.0)) if returning else float(dish_data.effect_values.get("out_damage", 16.0))
		)
		_damage(target, amount, 0.0, 0.0)


func _resolve_return_orbit() -> void:
	var radius := float(dish_data.effect_values.get("perfect_orbit_radius", 95.0))
	for target in _enemies_in_radius(owner_player.global_position, radius):
		_damage(target, float(dish_data.effect_values.get("perfect_orbit_damage", 12.0)), 0.0, 0.0)
	resolved = true
	queue_free()


func _process_greens_orbit(delta: float) -> void:
	if elapsed >= float(dish_data.effect_values.get("max_lifetime", 8.0)):
		queue_free()
		return
	angle += TAU * delta / maxf(0.1, float(dish_data.effect_values.get("lap_time", 1.1)))
	global_position = owner_player.global_position + Vector2.from_angle(angle) * float(dish_data.effect_values.get("orbit_radius", 115.0))
	for target in _enemies_in_radius(global_position, 22.0):
		if not _can_hit(target):
			continue
		_damage(target, float(dish_data.effect_values.get("damage", 11.0)), 0.0, 0.0)
		_apply_slow(target, float(dish_data.effect_values.get("slow", 0.12)), float(dish_data.effect_values.get("slow_duration", 2.0)))
		_set_cooldown(target, float(dish_data.effect_values.get("hit_cooldown", 0.6)))
		remaining_hits -= 1
		if remaining_hits <= 0:
			_finish_greens_orbit()
			return


func _finish_greens_orbit() -> void:
	if dish_data.quality == ItemData.Quality.PERFECT and dish_data.has_perfect_finisher:
		for target in _enemies_in_radius(owner_player.global_position, float(dish_data.effect_values.get("orbit_radius", 115.0)) + 35.0):
			_damage(target, float(dish_data.effect_values.get("perfect_damage", 16.0)), 0.0, 0.0)
			_apply_slow(target, float(dish_data.effect_values.get("perfect_slow", 0.20)), float(dish_data.effect_values.get("perfect_slow_duration", 2.5)))
		var targets := _sorted_enemies(owner_player.global_position, 300.0)
		for index in mini(dish_data.leaf_count, targets.size()):
			_damage(targets[index], float(dish_data.effect_values.get("leaf_damage", 7.0)), 0.0, 0.0)
			_apply_slow(targets[index], float(dish_data.effect_values.get("perfect_slow", 0.20)), float(dish_data.effect_values.get("perfect_slow_duration", 2.5)))
	resolved = true
	queue_free()


func _process_bounce(delta: float) -> void:
	if elapsed >= float(dish_data.effect_values.get("max_lifetime", 4.0)) or remaining_hits <= 0:
		_finish_beef_bounce()
		return
	attack_left = maxf(0.0, attack_left - delta)
	if attack_left > 0.0:
		return
	var target := _pick_target(global_position, float(dish_data.effect_values.get("target_radius", 190.0)))
	if target == null:
		return
	global_position = target.global_position
	var hit_index := dish_data.max_durability - remaining_hits
	var amount := float(dish_data.effect_values.get("damage", 26.0))
	if dish_data.quality == ItemData.Quality.PERFECT:
		var sequence: Array = dish_data.effect_values.get("perfect_hits", [])
		if hit_index < sequence.size():
			amount = float(sequence[hit_index])
	_damage(target, amount, float(dish_data.effect_values.get("knockback", 62.0)), float(dish_data.effect_values.get("stun", 0.18)))
	_set_cooldown(target, float(dish_data.effect_values.get("same_target_cooldown", 0.45)))
	remaining_hits -= 1
	attack_left = 0.18
	if remaining_hits <= 0:
		_finish_beef_bounce(target)


func _finish_beef_bounce(direct_target: Node = null) -> void:
	if resolved:
		return
	if dish_data.quality == ItemData.Quality.PERFECT and dish_data.has_perfect_finisher and direct_target != null:
		_damage(direct_target, float(dish_data.effect_values.get("slam_damage", 45.0)), 0.0, float(dish_data.effect_values.get("perfect_stun", 0.35)))
		for other in _enemies_in_radius(global_position, float(dish_data.effect_values.get("slam_radius", 105.0))):
			if other != direct_target:
				_damage(other, float(dish_data.effect_values.get("splash_damage", 18.0)), 55.0, 0.0)
	resolved = true
	queue_free()


func _process_mixed_orbit(delta: float) -> void:
	if elapsed >= float(dish_data.effect_values.get("max_lifetime", 10.0)) or split_count >= 5:
		queue_free()
		return
	angle += TAU * delta / maxf(0.1, float(dish_data.effect_values.get("lap_time", 1.15)))
	global_position = owner_player.global_position + Vector2.from_angle(angle) * float(dish_data.effect_values.get("orbit_radius", 120.0))
	var damages: Array = dish_data.effect_values.get("body_damages", [16.0, 14.0, 12.0, 10.0, 8.0])
	var body_damage := float(damages[mini(split_count, damages.size() - 1)])
	for target in _enemies_in_radius(global_position, 24.0):
		if not _can_hit(target):
			continue
		_damage(target, body_damage, 0.0, 0.0)
		_apply_slow(target, float(dish_data.effect_values.get("body_slow", 0.10)), float(dish_data.effect_values.get("body_slow_duration", 2.0)))
		_set_cooldown(target, float(dish_data.effect_values.get("body_hit_cooldown", 0.65)))
	split_left = maxf(0.0, split_left - delta)
	if split_left <= 0.0 and _pick_target(owner_player.global_position, float(dish_data.effect_values.get("split_target_radius", 280.0))) != null:
		split_count += 1
		var splitter := RiceCakeCombatEntity.new()
		var core := split_count == 5 and dish_data.quality == ItemData.Quality.PERFECT and dish_data.has_perfect_finisher
		splitter.setup_splitter(owner_player, dish_data, core)
		get_parent().add_child(splitter)
		splitter.global_position = global_position
		split_left = float(dish_data.effect_values.get("split_interval", 1.25))
		if split_count >= 5:
			queue_free()


func _process_splitter(delta: float) -> void:
	if elapsed >= 5.0 or remaining_hits <= 0:
		_finish_splitter()
		return
	attack_left = maxf(0.0, attack_left - delta)
	if attack_left > 0.0:
		return
	var target := _pick_target(global_position, float(dish_data.effect_values.get("split_target_radius", 280.0)))
	if target == null:
		return
	global_position = target.global_position
	var amount := float(dish_data.effect_values.get("core_damage", 20.0)) if mode == Mode.CORE_SPLITTER else float(dish_data.effect_values.get("split_damage", 14.0))
	var stun := float(dish_data.effect_values.get("core_stun", 0.18)) if mode == Mode.CORE_SPLITTER else float(dish_data.effect_values.get("split_stun", 0.10))
	_damage(target, amount, float(dish_data.effect_values.get("split_knockback", 28.0)), stun)
	_apply_slow(target, float(dish_data.effect_values.get("split_slow", 0.12)), float(dish_data.effect_values.get("split_slow_duration", 2.0)))
	_set_cooldown(target, float(dish_data.effect_values.get("split_same_target_cooldown", 0.35)))
	remaining_hits -= 1
	attack_left = 0.16
	if remaining_hits <= 0:
		_finish_splitter(target)


func _finish_splitter(direct_target: Node = null) -> void:
	if resolved:
		return
	if mode == Mode.CORE_SPLITTER and direct_target != null:
		_damage(direct_target, float(dish_data.effect_values.get("core_final_damage", 25.0)), 0.0, float(dish_data.effect_values.get("core_stun", 0.18)))
		for other in _enemies_in_radius(global_position, float(dish_data.effect_values.get("core_radius", 110.0))):
			if other == direct_target:
				continue
			_damage(other, float(dish_data.effect_values.get("core_splash_damage", 15.0)), 70.0, 0.0)
			_apply_slow(other, float(dish_data.effect_values.get("core_slow", 0.20)), float(dish_data.effect_values.get("core_slow_duration", 2.5)))
	resolved = true
	queue_free()


func _damage(target: Node, amount: float, knockback: float, stagger: float) -> void:
	var context := DamageContext.new()
	context.source_entity = owner_player
	context.source_dish = dish_data
	context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
	context.attacker_faction = CombatRules.Faction.PLAYER
	context.target_faction = CombatRules.Faction.ENEMY
	context.base_damage = amount
	context.allow_direct_attack_bonus = true
	target.receive_damage_context(context, global_position.direction_to(target.global_position), knockback, stagger)


func _apply_slow(target: Node, strength: float, duration: float) -> void:
	CombatStatusController.ensure_on(target).apply_status(
		CombatStatusController.StatusType.MOVE_SLOW,
		dish_data.source_recipe_instance_id,
		strength,
		duration
	)


func _pick_target(origin: Vector2, radius: float) -> Node2D:
	for candidate in _sorted_enemies(origin, radius):
		if _can_hit(candidate):
			return candidate
	return null


func _sorted_enemies(origin: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if _is_enemy(candidate) and origin.distance_to(candidate.global_position) <= radius:
			result.append(candidate)
	result.sort_custom(func(a: Node2D, b: Node2D) -> bool: return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	return result


func _enemies_in_radius(origin: Vector2, radius: float) -> Array[Node2D]:
	return _sorted_enemies(origin, radius)


func _can_hit(target: Node) -> bool:
	return target != null and not hit_cooldowns.has(target.get_instance_id())


func _set_cooldown(target: Node, duration: float) -> void:
	hit_cooldowns[target.get_instance_id()] = duration


func _advance_cooldowns(delta: float) -> void:
	for id in hit_cooldowns.keys():
		var left := float(hit_cooldowns[id]) - delta
		if left <= 0.0:
			hit_cooldowns.erase(id)
		else:
			hit_cooldowns[id] = left


func _blocked(from: Vector2, to: Vector2) -> bool:
	if get_world_2d() == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	if owner_player is CollisionObject2D:
		query.exclude = [(owner_player as CollisionObject2D).get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _is_enemy(target: Node) -> bool:
	return target != null and is_instance_valid(target) and target.has_method("get_combat_faction") and target.has_method("receive_damage_context") and int(target.get_combat_faction()) == CombatRules.Faction.ENEMY
