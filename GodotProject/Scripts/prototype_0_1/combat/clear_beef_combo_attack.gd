class_name ClearBeefComboAttack
extends Node2D

var source_player: Node2D
var dish_data: ItemData
var direction := Vector2.RIGHT
var hit_count: int = 3
var combo_duration: float = 0.22
var elapsed: float = 0.0
var next_hit_index: int = 0
var resolved_hits: int = 0
var hit_damage: float = 6.0
var attack_range: float = 115.0
var arc_degrees: float = 42.0
var final_arc_degrees: float = 42.0
var final_knockback: float = 16.0
var final_stun: float = 0.0
var follow_player_direction: bool = false


func setup(origin: Vector2, attack_direction: Vector2, item: ItemData, player: Node2D, perfect_finisher: bool, config: PrototypeCombatConfig) -> void:
	global_position = origin
	source_player = player
	dish_data = item
	direction = attack_direction.normalized() if not attack_direction.is_zero_approx() else Vector2.RIGHT
	hit_damage = float(item.effect_values.get("hit_damage", config.clear_beef_hit_damage))
	attack_range = float(item.effect_values.get("range", config.clear_beef_range))
	arc_degrees = float(item.effect_values.get("arc_degrees", config.clear_beef_arc_degrees))
	final_arc_degrees = arc_degrees
	combo_duration = float(item.effect_values.get("combo_duration", config.clear_beef_combo_duration))
	final_knockback = float(item.effect_values.get("final_knockback", config.clear_beef_final_knockback))
	if perfect_finisher:
		hit_count = int(item.effect_values.get("perfect_hits", config.clear_beef_perfect_hits))
		combo_duration = float(item.effect_values.get("perfect_duration", config.clear_beef_perfect_duration))
		final_arc_degrees = float(item.effect_values.get("perfect_final_arc", config.clear_beef_perfect_final_arc))
		final_knockback = float(item.effect_values.get("perfect_final_knockback", config.clear_beef_perfect_final_knockback))
		final_stun = float(item.effect_values.get("perfect_final_stun", config.clear_beef_perfect_final_stun))
		follow_player_direction = true


func _ready() -> void:
	add_to_group("temporary_attack_entity")
	add_to_group("clear_beef_combo_attack")
	z_index = 18
	queue_redraw()
	_resolve_hit(0)
	next_hit_index = 1


func _process(delta: float) -> void:
	if source_player == null or not is_instance_valid(source_player):
		queue_free()
		return
	global_position = source_player.global_position
	elapsed += delta
	while next_hit_index < hit_count and elapsed + 0.0001 >= combo_duration * float(next_hit_index) / float(maxi(1, hit_count - 1)):
		_resolve_hit(next_hit_index)
		next_hit_index += 1
		queue_redraw()
	if next_hit_index >= hit_count and elapsed >= combo_duration + 0.08:
		queue_free()


func _resolve_hit(hit_index: int) -> void:
	if follow_player_direction and source_player.has_method("get"):
		var facing: Variant = source_player.get("facing_direction")
		if facing is Vector2 and not (facing as Vector2).is_zero_approx():
			direction = (facing as Vector2).normalized()
	var is_final := hit_index == hit_count - 1
	var current_arc := final_arc_degrees if is_final else arc_degrees
	var hit_this_segment: Dictionary = {}
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or target == source_player:
			continue
		if not target.has_method("get_combat_faction") or not target.has_method("receive_damage_context"):
			continue
		if int(target.get_combat_faction()) != CombatRules.Faction.ENEMY:
			continue
		var target_id := target.get_instance_id()
		if hit_this_segment.has(target_id):
			continue
		var offset: Vector2 = target.global_position - global_position
		var radius := float((target as BasicTasteEnemy).enemy_collision_radius) if target is BasicTasteEnemy else 16.0
		if offset.length() > attack_range + radius:
			continue
		if offset.length() > 0.001:
			var allowance := asin(clampf(radius / maxf(offset.length(), radius), 0.0, 1.0))
			if absf(direction.angle_to(offset.normalized())) > deg_to_rad(current_arc * 0.5) + allowance:
				continue
		var context := DamageContext.new()
		context.source_entity = source_player
		context.source_dish = dish_data
		context.source_type = DamageContext.SourceType.PLAYER_DIRECT_MELEE
		context.attacker_faction = CombatRules.Faction.PLAYER
		context.target_faction = CombatRules.Faction.ENEMY
		context.base_damage = hit_damage
		context.friendly_fire = false
		context.allow_direct_attack_bonus = true
		target.receive_damage_context(
			context,
			direction,
			final_knockback if is_final else 0.0,
			final_stun if is_final and final_stun > 0.0 else -1.0
		)
		hit_this_segment[target_id] = true
		resolved_hits += 1


func _draw() -> void:
	var progress := clampf(float(maxi(1, next_hit_index)) / float(maxi(1, hit_count)), 0.0, 1.0)
	var current_arc := final_arc_degrees if next_hit_index >= hit_count else arc_degrees
	var start := direction.angle() - deg_to_rad(current_arc * 0.5)
	var finish := direction.angle() + deg_to_rad(current_arc * 0.5)
	draw_arc(Vector2.ZERO, attack_range * (0.72 + progress * 0.12), start, finish, 18, Color(1.0, 0.78, 0.35, 0.8), 5.0)
