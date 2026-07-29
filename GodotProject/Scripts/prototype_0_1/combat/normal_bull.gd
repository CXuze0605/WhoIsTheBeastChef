class_name NormalBull
extends Node2D

var direction := Vector2.RIGHT
var damage: float = 0.0
var attacker_faction: int = CombatRules.Faction.PLAYER
var config: PrototypeCombatConfig
var traveled_distance: float = 0.0
var hit_target_ids: Dictionary = {}
var on_hit_effect: StatusEffectData
var visual: PlaceholderVisual
var visual_animator: NormalBullVisualAnimator
var source_entity: Node
var source_dish: ItemData


func setup(
	spawn_position: Vector2,
	move_direction: Vector2,
	attack_damage: float,
	combat_config: PrototypeCombatConfig,
	spawn_faction: int = CombatRules.Faction.PLAYER,
	status_effect: StatusEffectData = null,
	attack_source: Node = null,
	dish_data: ItemData = null
) -> void:
	global_position = spawn_position
	direction = move_direction.normalized() if not move_direction.is_zero_approx() else Vector2.RIGHT
	damage = attack_damage
	config = combat_config
	attacker_faction = spawn_faction
	on_hit_effect = status_effect.copy_effect() if status_effect != null else null
	source_entity = attack_source
	source_dish = dish_data


func _ready() -> void:
	add_to_group("normal_bull")
	visual = PlaceholderVisual.new()
	add_child(visual)
	PrototypeArtCatalog.apply_to(visual, &"normal_bull")
	visual.configure(Vector2(92.0, 54.0), Color("d97927"), "愤怒公牛", "穿透冲锋")
	var frames := load(
		"res://Assets/Combat/DishAttacks/StirFryNormalBull01/stir_fry_normal_bull_01_sprite_frames.tres"
	) as SpriteFrames
	visual_animator = NormalBullVisualAnimator.new()
	visual_animator.name = "NormalBullVisualAnimator"
	add_child(visual_animator)
	visual_animator.configure(visual, frames)
	visual_animator.set_direction(direction)


func _physics_process(delta: float) -> void:
	var movement := direction * config.normal_bull_speed * delta
	global_position += movement
	traveled_distance += movement.length()
	_hit_targets_once()
	if traveled_distance >= config.normal_bull_distance or not _inside_combat_bounds(global_position):
		queue_free()


func _hit_targets_once() -> void:
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction") or not target.has_method("receive_combat_hit"):
			continue
		var target_id := target.get_instance_id()
		if hit_target_ids.has(target_id):
			continue
		var offset: Vector2 = target.global_position - global_position
		var forward := offset.dot(direction)
		var side := absf(offset.dot(direction.orthogonal()))
		if absf(forward) <= 55.0 and side <= config.normal_bull_width * 0.5:
			var hit_succeeded := false
			if target.has_method("receive_damage_context"):
				var context := DamageContext.new()
				context.source_entity = source_entity
				context.source_dish = source_dish
				context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
				context.attacker_faction = attacker_faction
				context.target_faction = int(target.get_combat_faction())
				context.base_damage = damage
				context.friendly_fire = false
				context.allow_direct_attack_bonus = true
				hit_succeeded = target.receive_damage_context(context, direction, config.normal_bull_knockback, config.normal_bull_stagger_power)
			else:
				hit_succeeded = target.receive_combat_hit(damage, attacker_faction, direction, config.normal_bull_knockback, false, config.normal_bull_stagger_power)
			if hit_succeeded:
				hit_target_ids[target_id] = true
				if on_hit_effect != null and target.has_method("apply_status_effect"):
					target.apply_status_effect(on_hit_effect.copy_effect())


func _inside_combat_bounds(point: Vector2) -> bool:
	return config.combat_bounds.has_point(point)
