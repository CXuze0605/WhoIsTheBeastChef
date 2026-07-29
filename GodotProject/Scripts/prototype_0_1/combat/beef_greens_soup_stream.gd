class_name BeefGreensSoupStream
extends Node2D

var owner_player: Node2D
var source_item: CarryableItem
var config: PrototypeCombatConfig
var target: Node2D
var current_direction := Vector2.RIGHT
var tick_left: float = 0.0
var display_index: int = 0
var depleted_callback: Callable
var ticks_fired: int = 0
var durability_elapsed: float = 0.0
var finisher_running: bool = false


func setup(
	player: Node2D,
	item: CarryableItem,
	combat_config: PrototypeCombatConfig,
	index: int,
	callback: Callable
) -> void:
	owner_player = player
	source_item = item
	config = combat_config
	display_index = index
	depleted_callback = callback
	position = Vector2.from_angle(float(index) * 0.9) * (25.0 + float(index % 3) * 7.0)


func _ready() -> void:
	add_to_group("auto_dish_stream")
	z_index = 11
	queue_redraw()


func _draw() -> void:
	var spicy := source_item != null and source_item.data.recipe_id in [ExpandedRecipeCatalog.SPICY_BEEF_SOUP, ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP]
	draw_circle(Vector2.ZERO, 9.0, Color("c95436") if spicy else Color("77a7a0"))
	if target != null and is_instance_valid(target):
		var endpoint := to_local(target.global_position)
		var stream_length := endpoint.length()
		if stream_length <= 0.01:
			return
		var is_beef_only := source_item.data.recipe_id == ExpandedRecipeCatalog.SPICY_BEEF_SOUP
		var base_key := &"soup_stream_beef" if is_beef_only else &"soup_stream_greens_beef"
		var width := maxf(18.0, float(source_item.data.effect_values.get("width", 12.0)))
		var pulse := 0.88 + sin(Time.get_ticks_msec() * 0.014 + float(display_index)) * 0.08
		draw_set_transform(Vector2.ZERO, endpoint.angle(), Vector2.ONE)
		draw_texture_rect(
			CombatArtCatalog.get_texture(base_key),
			Rect2(Vector2(0.0, -width * 0.5), Vector2(stream_length, width)),
			false,
			Color(1.0, 1.0, 1.0, pulse)
		)
		if spicy:
			draw_texture_rect(
				CombatArtCatalog.get_texture(&"soup_stream_spicy"),
				Rect2(Vector2(0.0, -width * 0.5), Vector2(stream_length, width)),
				false,
				Color(1.0, 0.82, 0.64, 0.78)
			)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(delta: float) -> void:
	if source_item == null or not is_instance_valid(source_item) or source_item.data.current_durability <= 0:
		queue_free()
		return
	_update_target()
	if target == null:
		queue_redraw()
		return
	var desired := global_position.direction_to(target.global_position)
	current_direction = current_direction.rotated(
		clampf(current_direction.angle_to(desired), -config.beef_greens_soup_turn_speed * delta, config.beef_greens_soup_turn_speed * delta)
	).normalized()
	tick_left = maxf(0.0, tick_left - delta)
	durability_elapsed += delta
	if tick_left <= 0.0:
		_fire_tick()
	queue_redraw()


func _update_target() -> void:
	var attack_range := float(source_item.data.effect_values.get("range", config.beef_greens_soup_range))
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(candidate):
			continue
		var distance := owner_player.global_position.distance_to(candidate.global_position)
		if distance <= attack_range and distance < nearest_distance and _has_line(candidate):
			nearest = candidate
			nearest_distance = distance
	if target != null and is_instance_valid(target) and _is_enemy(target):
		var current_distance := owner_player.global_position.distance_to(target.global_position)
		if current_distance <= attack_range and _has_line(target) and (nearest == null or current_distance <= nearest_distance * 1.15):
			return
	target = nearest


func _has_line(candidate: Node2D) -> bool:
	if not is_inside_tree() or get_world_2d() == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(global_position, candidate.global_position)
	var exclusions: Array[RID] = []
	if owner_player is CollisionObject2D:
		exclusions.append((owner_player as CollisionObject2D).get_rid())
	if candidate is CollisionObject2D:
		exclusions.append((candidate as CollisionObject2D).get_rid())
	query.exclude = exclusions
	query.collision_mask = 1
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _fire_tick() -> void:
	if target == null or not is_instance_valid(target):
		return
	if source_item.data.recipe_id == ExpandedRecipeCatalog.SPICY_BEEF_SOUP:
		_fire_spicy_beef_tick()
		return
	if source_item.data.recipe_id == ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP:
		_fire_spicy_support_tick()
		return
	var tick_direction := owner_player.global_position.direction_to(target.global_position)
	_damage_target(target, float(source_item.data.effect_values.get("center_damage", config.beef_greens_soup_center_damage)), tick_direction)
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(candidate) or candidate == target:
			continue
		var candidate_2d := candidate as Node2D
		var offset: Vector2 = candidate_2d.global_position - owner_player.global_position
		var along: float = offset.dot(tick_direction)
		var lateral: float = absf(offset.cross(tick_direction))
		if along > 0.0 and along <= float(source_item.data.effect_values.get("range", config.beef_greens_soup_range)) and lateral <= 36.0:
			_damage_target(candidate, float(source_item.data.effect_values.get("outer_damage", config.beef_greens_soup_outer_damage)), tick_direction)
	source_item.data.current_durability -= 1
	source_item.data.mark_used()
	ticks_fired += 1
	tick_left = float(source_item.data.effect_values.get("tick_interval", config.beef_greens_soup_tick_interval))
	if source_item.data.current_durability <= 0:
		if source_item.data.quality == ItemData.Quality.PERFECT:
			_release_finisher(target.global_position)
		if not depleted_callback.is_null():
			depleted_callback.call(source_item)


func _fire_spicy_beef_tick() -> void:
	if finisher_running:
		return
	if source_item.data.current_durability == 1 and source_item.data.has_perfect_finisher:
		_start_spicy_beef_finisher(target)
		return
	var tick_direction := owner_player.global_position.direction_to(target.global_position)
	_damage_target(target, float(source_item.data.effect_values.get("damage", 4.0)), tick_direction)
	_apply_shared_spicy_vulnerability(target)
	ticks_fired += 1
	tick_left = float(source_item.data.effect_values.get("tick_interval", 0.25))
	var spend_interval := float(source_item.data.effect_values.get("durability_interval", 0.5))
	if durability_elapsed >= spend_interval:
		durability_elapsed = fmod(durability_elapsed, spend_interval)
		_spend_one_durability()


func _start_spicy_beef_finisher(locked_target: Node2D) -> void:
	if locked_target == null or not is_instance_valid(locked_target):
		return
	finisher_running = true
	for index in 2:
		if not is_instance_valid(locked_target):
			break
		_damage_line(
			owner_player.global_position.direction_to(locked_target.global_position),
			float(source_item.data.effect_values.get("finisher_range", 420.0)),
			float(source_item.data.effect_values.get("finisher_width", 70.0)),
			float(source_item.data.effect_values.get("finisher_damage", 5.0)),
			true
		)
		if index == 0:
			await get_tree().create_timer(0.25).timeout
	_spend_one_durability()
	finisher_running = false


func _fire_spicy_support_tick() -> void:
	if source_item.data.current_durability == 1 and source_item.data.has_perfect_finisher:
		_apply_support_finisher(target.global_position)
		_spend_one_durability()
		return
	var tick_direction := owner_player.global_position.direction_to(target.global_position)
	var attack_range := float(source_item.data.effect_values.get("range", 360.0))
	var width := float(source_item.data.effect_values.get("width", 30.0))
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(candidate):
			continue
		var offset: Vector2 = candidate.global_position - owner_player.global_position
		var along := offset.dot(tick_direction)
		var lateral := absf(offset.cross(tick_direction))
		if candidate == target:
			_apply_support_status(candidate, true)
		elif along > 0.0 and along <= attack_range and lateral <= width * 0.5:
			_apply_support_status(candidate, false)
	ticks_fired += 1
	tick_left = float(source_item.data.effect_values.get("interval", 0.48))
	_spend_one_durability()


func _apply_shared_spicy_vulnerability(candidate: Node) -> void:
	var statuses := CombatStatusController.ensure_on(candidate)
	var source_id := "spicy_beef_soup_shared"
	var per_stack := float(source_item.data.effect_values.get("vulnerability_per_stack", 0.02))
	var cap := per_stack * float(source_item.data.effect_values.get("max_stacks", 5))
	var current := 0.0
	if statuses.sources.has(CombatStatusController.StatusType.VULNERABILITY):
		var by_source: Dictionary = statuses.sources[CombatStatusController.StatusType.VULNERABILITY]
		if by_source.has(source_id):
			current = float((by_source[source_id] as Dictionary).get("magnitude", 0.0))
	statuses.apply_status(
		CombatStatusController.StatusType.VULNERABILITY,
		source_id,
		minf(cap, current + per_stack),
		float(source_item.data.effect_values.get("stack_timeout", 3.0))
	)


func _apply_support_status(candidate: Node, primary: bool) -> void:
	var statuses := CombatStatusController.ensure_on(candidate)
	var source_id := "spicy_support_%d" % source_item.data.source_recipe_instance_id
	statuses.apply_status(
		CombatStatusController.StatusType.VULNERABILITY,
		source_id,
		float(source_item.data.effect_values.get("primary_vulnerability" if primary else "line_vulnerability", 0.0)),
		float(source_item.data.effect_values.get("status_duration", 3.0))
	)
	statuses.apply_status(
		CombatStatusController.StatusType.WEAKNESS,
		source_id,
		float(source_item.data.effect_values.get("primary_weakness" if primary else "line_weakness", 0.0)),
		float(source_item.data.effect_values.get("status_duration", 3.0))
	)


func _apply_support_finisher(origin: Vector2) -> void:
	var radius := float(source_item.data.effect_values.get("finisher_radius", 150.0))
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(candidate) or origin.distance_to(candidate.global_position) > radius:
			continue
		var statuses := CombatStatusController.ensure_on(candidate)
		var source_id := "spicy_support_finisher_%d" % source_item.data.source_recipe_instance_id
		statuses.apply_status(CombatStatusController.StatusType.VULNERABILITY, source_id, float(source_item.data.effect_values.get("finisher_vulnerability", 0.12)), float(source_item.data.effect_values.get("finisher_duration", 4.0)))
		statuses.apply_status(CombatStatusController.StatusType.WEAKNESS, source_id, float(source_item.data.effect_values.get("finisher_weakness", 0.15)), float(source_item.data.effect_values.get("finisher_duration", 4.0)))


func _damage_line(tick_direction: Vector2, attack_range: float, width: float, amount: float, finisher: bool) -> void:
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if not _is_enemy(candidate):
			continue
		var offset: Vector2 = candidate.global_position - owner_player.global_position
		if offset.dot(tick_direction) <= 0.0 or offset.dot(tick_direction) > attack_range or absf(offset.cross(tick_direction)) > width * 0.5:
			continue
		_damage_target(candidate, amount, tick_direction)
		if finisher:
			CombatStatusController.ensure_on(candidate).apply_status(
				CombatStatusController.StatusType.VULNERABILITY,
				"spicy_beef_soup_finisher",
				float(source_item.data.effect_values.get("finisher_vulnerability", 0.15)),
				float(source_item.data.effect_values.get("finisher_status_duration", 4.0))
			)


func _spend_one_durability() -> void:
	source_item.data.current_durability -= 1
	source_item.data.mark_used()
	if source_item.data.current_durability <= 0 and not depleted_callback.is_null():
		depleted_callback.call(source_item)


func _release_finisher(origin: Vector2) -> void:
	var radius := float(source_item.data.effect_values.get("finisher_radius", config.beef_greens_soup_finisher_radius))
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if _is_enemy(candidate) and origin.distance_to(candidate.global_position) <= radius:
			_damage_target(
				candidate,
				float(source_item.data.effect_values.get("finisher_damage", config.beef_greens_soup_finisher_damage)),
				origin.direction_to(candidate.global_position)
			)


func _damage_target(candidate: Node, amount: float, knockback_direction: Vector2) -> void:
	var context := DamageContext.new()
	context.source_entity = owner_player
	context.source_dish = source_item.data
	context.source_type = DamageContext.SourceType.AUTO_DISH_EQUIPMENT
	context.attacker_faction = CombatRules.Faction.PLAYER
	context.target_faction = CombatRules.Faction.ENEMY
	context.base_damage = amount
	context.allow_direct_attack_bonus = false
	candidate.receive_damage_context(
		context,
		knockback_direction,
		float(source_item.data.effect_values.get("knockback", config.beef_greens_soup_knockback)),
		0.0
	)


func _is_enemy(candidate: Node) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.has_method("get_combat_faction")
		and candidate.has_method("receive_damage_context")
		and int(candidate.get_combat_faction()) == CombatRules.Faction.ENEMY
	)
