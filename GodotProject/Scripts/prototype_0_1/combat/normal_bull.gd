class_name NormalBull
extends Node2D

var direction := Vector2.RIGHT
var damage: float = 0.0
var attacker_faction: int = CombatRules.Faction.PLAYER
var config: PrototypeCombatConfig
var traveled_distance: float = 0.0
var hit_target_ids: Dictionary = {}
var on_hit_effect: StatusEffectData


func setup(
	spawn_position: Vector2,
	move_direction: Vector2,
	attack_damage: float,
	combat_config: PrototypeCombatConfig,
	spawn_faction: int = CombatRules.Faction.PLAYER,
	status_effect: StatusEffectData = null
) -> void:
	global_position = spawn_position
	direction = move_direction.normalized() if not move_direction.is_zero_approx() else Vector2.RIGHT
	damage = attack_damage
	config = combat_config
	attacker_faction = spawn_faction
	on_hit_effect = status_effect.copy_effect() if status_effect != null else null


func _ready() -> void:
	add_to_group("normal_bull")
	var visual := PlaceholderVisual.new()
	add_child(visual)
	visual.configure(Vector2(92.0, 54.0), Color("d97927"), "愤怒公牛", "穿透冲锋")
	rotation = direction.angle()


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
			if target.receive_combat_hit(damage, attacker_faction, direction, config.normal_bull_knockback, false, config.normal_bull_stagger_power):
				hit_target_ids[target_id] = true
				if on_hit_effect != null and target.has_method("apply_status_effect"):
					target.apply_status_effect(on_hit_effect.copy_effect())


func _inside_combat_bounds(point: Vector2) -> bool:
	return config.combat_bounds.has_point(point)
