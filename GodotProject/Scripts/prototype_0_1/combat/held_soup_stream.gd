class_name HeldSoupStream
extends Node2D

enum Mode {
	GREENS,
	BEEF,
}

signal durability_spent

var source_player: PrototypePlayer
var dish_item: CarryableItem
var dish_data: ItemData
var mode: int = Mode.GREENS
var direction := Vector2.RIGHT
var tick_left: float = 0.0
var durability_elapsed: float = 0.0
var focus_target_id: int = 0
var focus_stacks: int = 0
var focus_time_left: float = 0.0
var visual_level: int = 0
var visual_intensity: float = 0.0
var active: bool = true


func setup(player: PrototypePlayer, item: CarryableItem, stream_mode: int) -> void:
	source_player = player
	dish_item = item
	dish_data = item.data
	mode = stream_mode
	direction = player.facing_direction.normalized() if not player.facing_direction.is_zero_approx() else Vector2.RIGHT
	durability_elapsed = float(dish_data.effect_values.get("stream_durability_elapsed", 0.0))


func _ready() -> void:
	add_to_group("temporary_attack_entity")
	add_to_group("held_soup_stream")
	z_index = 17
	queue_redraw()


func update_direction(value: Vector2) -> void:
	if not value.is_zero_approx():
		direction = value.normalized()
	queue_redraw()


func advance_for_test(delta: float) -> void:
	_advance(delta)


func _process(delta: float) -> void:
	_advance(delta)


func _advance(delta: float) -> void:
	if not active or source_player == null or dish_item == null or not is_instance_valid(source_player) or not is_instance_valid(dish_item):
		stop_stream()
		return
	global_position = source_player.global_position
	if dish_item.data != dish_data or dish_data.current_durability <= 0:
		stop_stream()
		return
	tick_left -= delta
	focus_time_left = maxf(0.0, focus_time_left - delta)
	if mode == Mode.BEEF and focus_time_left <= 0.0:
		_clear_focus()
	if mode == Mode.BEEF:
		visual_intensity = move_toward(
			visual_intensity,
			float(visual_level),
			float(dish_data.effect_values.get("visual_fade_speed", 7.5)) * delta
		)
	if tick_left <= 0.0:
		tick_left += maxf(0.01, float(dish_data.effect_values.get("tick_interval", 0.25)))
		_resolve_tick()
	durability_elapsed += delta
	var spend_interval := maxf(0.05, float(dish_data.effect_values.get("durability_interval", 0.5)))
	if durability_elapsed >= spend_interval:
		durability_elapsed -= spend_interval
		dish_data.effect_values["stream_durability_elapsed"] = durability_elapsed
		durability_spent.emit()
	queue_redraw()


func stop_stream() -> void:
	if not active:
		return
	active = false
	if dish_data != null:
		dish_data.effect_values["stream_durability_elapsed"] = durability_elapsed
	_clear_focus()
	queue_free()


func _resolve_tick() -> void:
	if mode == Mode.BEEF:
		var target := _find_first_target(direction, _stream_range(), _stream_width())
		if target != null:
			_apply_beef_hit(target)
		else:
			_clear_focus()
		return
	var directions: Array[Vector2] = [direction]
	if dish_data.quality == ItemData.Quality.PERFECT:
		var side_angle := deg_to_rad(float(dish_data.effect_values.get("side_angle_degrees", 20.0)))
		directions.append(direction.rotated(-side_angle))
		directions.append(direction.rotated(side_angle))
	var hit_ids: Dictionary = {}
	for stream_index in directions.size():
		var stream_direction := directions[stream_index]
		var range_scale := 1.0 if stream_index == 0 else float(dish_data.effect_values.get("side_range_multiplier", 0.85))
		var effect_scale := 1.0 if stream_index == 0 else float(dish_data.effect_values.get("side_multiplier", 0.6))
		for target in _find_targets_in_stream(stream_direction, _stream_range() * range_scale, _stream_width()):
			var target_id := target.get_instance_id()
			if hit_ids.has(target_id):
				continue
			hit_ids[target_id] = true
			_apply_damage(
				target,
				float(dish_data.effect_values.get("damage", dish_data.actual_damage)) * effect_scale,
				float(dish_data.effect_values.get("knockback", 0.0)) * effect_scale
			)


func _apply_beef_hit(target: Node) -> void:
	var target_id := target.get_instance_id()
	if focus_target_id != target_id:
		focus_target_id = target_id
		focus_stacks = 0
	focus_time_left = float(dish_data.effect_values.get("focus_timeout", 0.75))
	var multiplier := 1.0
	if dish_data.quality == ItemData.Quality.PERFECT:
		focus_stacks = mini(
			int(dish_data.effect_values.get("focus_max_stacks", 5)),
			focus_stacks + 1
		)
		multiplier += float(focus_stacks) * float(dish_data.effect_values.get("focus_gain", 0.06))
	visual_level = focus_stacks
	visual_intensity = maxf(visual_intensity, float(visual_level))
	_apply_damage(target, float(dish_data.effect_values.get("damage", dish_data.actual_damage)) * multiplier, 0.0)


func _apply_damage(target: Node, amount: float, knockback: float) -> void:
	var context := DamageContext.new()
	context.source_entity = source_player
	context.source_dish = dish_data
	context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
	context.attacker_faction = CombatRules.Faction.PLAYER
	context.target_faction = CombatRules.Faction.ENEMY
	context.base_damage = amount
	context.friendly_fire = false
	context.allow_direct_attack_bonus = true
	# A zero stagger value reaches the threshold of basic enemies. A negative
	# value explicitly preserves the soup designs: push only for greens, and
	# neither stagger nor attack interruption for beef.
	target.receive_damage_context(context, direction, knockback, -1.0)


func _find_first_target(stream_direction: Vector2, stream_range: float, width: float) -> Node:
	var best: Node
	var best_projection: float = INF
	for target in _find_targets_in_stream(stream_direction, stream_range, width):
		var target_2d := target as Node2D
		var projection: float = (target_2d.global_position - global_position).dot(stream_direction)
		if projection < best_projection:
			best_projection = projection
			best = target
	return best


func _find_targets_in_stream(stream_direction: Vector2, stream_range: float, width: float) -> Array[Node]:
	var result: Array[Node] = []
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_damage_context"):
			continue
		if int(target.get_combat_faction()) != CombatRules.Faction.ENEMY:
			continue
		if not target is Node2D:
			continue
		var offset: Vector2 = (target as Node2D).global_position - global_position
		var projection: float = offset.dot(stream_direction)
		if projection < 0.0 or projection > stream_range:
			continue
		var lateral := absf(offset.cross(stream_direction))
		var radius := float((target as BasicTasteEnemy).enemy_collision_radius) if target is BasicTasteEnemy else 16.0
		if lateral <= width * 0.5 + radius:
			result.append(target)
	return result


func _stream_range() -> float:
	return float(dish_data.effect_values.get("range", 280.0))


func _stream_width() -> float:
	return float(dish_data.effect_values.get("width", 48.0))


func _clear_focus() -> void:
	focus_target_id = 0
	focus_stacks = 0
	focus_time_left = 0.0
	visual_level = 0


func _draw() -> void:
	var base_color := Color("8bd6b0") if mode == Mode.GREENS else Color("c69a6b")
	if mode == Mode.BEEF and visual_intensity > 0.0:
		base_color = base_color.darkened(visual_intensity * 0.055)
	var texture_key := &"soup_stream_greens_beef" if mode == Mode.GREENS else &"soup_stream_beef"
	var stream_texture := CombatArtCatalog.get_texture(texture_key)
	var directions: Array[Vector2] = [direction]
	if mode == Mode.GREENS and dish_data != null and dish_data.quality == ItemData.Quality.PERFECT:
		var side_angle := deg_to_rad(float(dish_data.effect_values.get("side_angle_degrees", 20.0)))
		directions.append(direction.rotated(-side_angle))
		directions.append(direction.rotated(side_angle))
	for stream_index in directions.size():
		var scale := 1.0 if stream_index == 0 else float(dish_data.effect_values.get("side_range_multiplier", 0.85))
		var width_scale := 0.45 if stream_index == 0 else 0.24
		var visual_width := maxf(14.0, _stream_width() * width_scale)
		var visual_range := _stream_range() * scale
		draw_set_transform(Vector2.ZERO, directions[stream_index].angle(), Vector2.ONE)
		draw_texture_rect(
			stream_texture,
			Rect2(Vector2(0.0, -visual_width * 0.5), Vector2(visual_range, visual_width)),
			false,
			Color(base_color, 0.84)
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mode == Mode.BEEF:
		for particle_index in ceili(visual_intensity) * 2:
			var along := 40.0 + float(particle_index) * 20.0
			var side := -5.0 if particle_index % 2 == 0 else 5.0
			draw_circle(direction * along + direction.orthogonal() * side, 3.0, Color("7f4f35"))
