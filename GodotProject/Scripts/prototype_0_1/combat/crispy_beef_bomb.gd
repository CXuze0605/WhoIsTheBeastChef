class_name CrispyBeefBomb
extends Node2D

enum BombKind { MAIN, FRAGMENT }

var source_data: ItemData
var owner_player: PrototypePlayer
var config: PrototypeCombatConfig
var kind: int = BombKind.MAIN
var perfect_snapshot: bool = false
var arm_left: float = 0.0
var lifetime_left: float = -1.0
var triggered: bool = false
var fragments_spawned: int = 0
var random_seed: int = 1


func setup_main(
	data: ItemData,
	source_player: PrototypePlayer,
	combat_config: PrototypeCombatConfig,
	is_perfect: bool,
	seed_value: int = 0
) -> void:
	source_data = data
	owner_player = source_player
	config = combat_config
	kind = BombKind.MAIN
	perfect_snapshot = is_perfect
	arm_left = combat_config.crispy_beef_main_arm_time
	lifetime_left = -1.0
	random_seed = seed_value if seed_value != 0 else maxi(1, data.source_recipe_instance_id)


func setup_fragment(
	data: ItemData,
	source_player: PrototypePlayer,
	combat_config: PrototypeCombatConfig,
	seed_value: int
) -> void:
	source_data = data
	owner_player = source_player
	config = combat_config
	kind = BombKind.FRAGMENT
	perfect_snapshot = false
	arm_left = combat_config.crispy_beef_fragment_arm_time
	lifetime_left = combat_config.crispy_beef_fragment_lifetime
	random_seed = maxi(1, seed_value)


func _ready() -> void:
	add_to_group("run_deployable")
	add_to_group("crispy_beef_bomb")
	z_index = 5
	queue_redraw()


func _process(delta: float) -> void:
	if triggered or config == null:
		return
	arm_left = maxf(0.0, arm_left - delta)
	if lifetime_left >= 0.0:
		lifetime_left -= delta
		if lifetime_left <= 0.0:
			queue_free()
			return
	queue_redraw()
	if arm_left > 0.0:
		return
	var trigger_radius := (
		config.crispy_beef_main_trigger_radius
		if kind == BombKind.MAIN
		else config.crispy_beef_fragment_trigger_radius
	)
	for target in get_tree().get_nodes_in_group("damageable"):
		if _is_valid_trigger_target(target, trigger_radius):
			_explode()
			return


func _is_valid_trigger_target(target: Node, trigger_radius: float) -> bool:
	if (
		not is_instance_valid(target)
		or not target is Node2D
		or not target.has_method("get_combat_faction")
		or not target.has_method("receive_damage_context")
	):
		return false
	var faction := int(target.get_combat_faction())
	if faction not in [CombatRules.Faction.PLAYER, CombatRules.Faction.ENEMY, CombatRules.Faction.FRIENDLY]:
		return false
	return global_position.distance_to((target as Node2D).global_position) <= trigger_radius


func _explode() -> void:
	if triggered or config == null:
		return
	triggered = true
	var radius := _get_explosion_radius()
	var enemy_damage := _get_enemy_damage()
	var friendly_multiplier := (
		config.crispy_beef_main_friendly_damage_multiplier
		if kind == BombKind.MAIN
		else config.crispy_beef_fragment_friendly_damage_multiplier
	)
	var knockback := (
		config.crispy_beef_main_knockback
		if kind == BombKind.MAIN
		else config.crispy_beef_fragment_knockback
	)
	for target in get_tree().get_nodes_in_group("damageable"):
		if (
			not is_instance_valid(target)
			or not target is Node2D
			or not target.has_method("get_combat_faction")
			or not target.has_method("receive_damage_context")
		):
			continue
		var target_position := (target as Node2D).global_position
		if global_position.distance_to(target_position) > radius:
			continue
		var faction := int(target.get_combat_faction())
		if faction not in [CombatRules.Faction.PLAYER, CombatRules.Faction.ENEMY, CombatRules.Faction.FRIENDLY]:
			continue
		var direction := global_position.direction_to(target_position)
		if direction.is_zero_approx():
			direction = Vector2.UP
		var context := DamageContext.new()
		context.source_entity = owner_player
		context.source_dish = source_data
		context.source_type = DamageContext.SourceType.TRAP
		context.attacker_faction = CombatRules.Faction.PLAYER
		context.target_faction = faction
		context.base_damage = enemy_damage if faction == CombatRules.Faction.ENEMY else enemy_damage * friendly_multiplier
		context.friendly_fire = true
		context.allow_direct_attack_bonus = false
		target.receive_damage_context(context, direction, knockback, 0.0)
	if kind == BombKind.MAIN:
		_scatter_fragments()
	_spawn_explosion_vfx(radius)
	queue_free()


func _spawn_explosion_vfx(radius: float) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var burst := CombatVfxBurst.new()
	burst.setup(
		CombatVfxBurst.Kind.CRISPY_BEEF_EXPLOSION,
		global_position,
		radius,
		Color("ffcf5a") if kind == BombKind.MAIN else Color("f39a45")
	)
	parent.add_child(burst)


func _scatter_fragments() -> void:
	var count := (
		config.crispy_beef_perfect_fragment_count
		if perfect_snapshot
		else config.crispy_beef_fragment_count
	)
	var min_distance := (
		config.crispy_beef_perfect_scatter_min
		if perfect_snapshot
		else config.crispy_beef_fragment_scatter_min
	)
	var max_distance := (
		config.crispy_beef_perfect_scatter_max
		if perfect_snapshot
		else config.crispy_beef_fragment_scatter_max
	)
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	var scene := get_tree().current_scene
	if scene == null:
		scene = get_parent()
	for index in count:
		var angle := random.randf_range(0.0, TAU)
		var distance := random.randf_range(min_distance, max_distance)
		var fragment := CrispyBeefBomb.new()
		fragment.setup_fragment(
			source_data,
			owner_player,
			config,
			random_seed + (index + 1) * 7919
		)
		scene.add_child(fragment)
		fragment.global_position = global_position + Vector2.RIGHT.rotated(angle) * distance
		fragments_spawned += 1


func _get_explosion_radius() -> float:
	if kind == BombKind.FRAGMENT:
		return config.crispy_beef_fragment_radius
	return config.crispy_beef_perfect_main_radius if perfect_snapshot else config.crispy_beef_main_radius


func _get_enemy_damage() -> float:
	if kind == BombKind.FRAGMENT:
		return config.crispy_beef_fragment_damage
	return config.crispy_beef_perfect_main_damage if perfect_snapshot else config.crispy_beef_main_damage


func force_explode_for_test() -> void:
	_explode()


func _draw() -> void:
	if config == null:
		return
	var armed := arm_left <= 0.0
	var body_radius := 19.0 if kind == BombKind.MAIN else 9.0
	var key := &"crispy_beef_bomb_large" if kind == BombKind.MAIN else &"crispy_beef_bomb_small"
	var texture := CombatArtCatalog.get_texture(key)
	var size := Vector2.ONE * (48.0 if kind == BombKind.MAIN else 24.0)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, Color(1.0, 1.0, 1.0, 1.0 if armed else 0.62))
	draw_arc(Vector2.ZERO, body_radius + 4.0, 0.0, TAU, 28, Color("ffcb69") if armed else Color("f6e7cb"), 2.0)
	if not armed:
		var total_arm := config.crispy_beef_main_arm_time if kind == BombKind.MAIN else config.crispy_beef_fragment_arm_time
		var ratio := 1.0 - clampf(arm_left / maxf(0.01, total_arm), 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius + 8.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, Color("fff1a8"), 3.0)
