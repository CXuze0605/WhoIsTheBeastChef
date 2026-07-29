class_name CombatManager
extends Node2D

var config := PrototypeCombatConfig.new()
var normal_bulls_spawned: int = 0
var raging_bulls_spawned: int = 0
var melee_swings_spawned: int = 0
var big_bones_spawned: int = 0
var rice_balls_spawned: int = 0
var crispy_traps_spawned: int = 0
var greens_leaves_spawned: int = 0
var beef_greens_swings_spawned: int = 0
var fried_rice_projectiles_spawned: int = 0
var mustard_greens_projectiles_spawned: int = 0
var fried_white_rice_grains_spawned: int = 0
var clear_beef_combos_spawned: int = 0
var held_soup_streams_spawned: int = 0
var spicy_attacks_spawned: int = 0
var spicy_grains_spawned: int = 0
var rice_cake_entities_spawned: int = 0
var ring_random := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("combat_runtime")
	ring_random.randomize()


func spawn_normal_bull(origin: Vector2, direction: Vector2, damage: float, on_hit_effect: StatusEffectData = null, source_entity: Node = null, source_dish: ItemData = null) -> NormalBull:
	var bull := NormalBull.new()
	bull.setup(origin, direction, damage, config, CombatRules.Faction.PLAYER, on_hit_effect, source_entity, source_dish)
	add_child(bull)
	normal_bulls_spawned += 1
	return bull


func spawn_raging_bull(origin: Vector2, direction: Vector2) -> RagingBull:
	var bull := RagingBull.new()
	bull.setup(origin, direction, config)
	add_child(bull)
	raging_bulls_spawned += 1
	return bull


func spawn_melee_swing(origin: Vector2, direction: Vector2, item_data: ItemData, source_entity: Node = null) -> MeleeSwing:
	var swing := MeleeSwing.new()
	swing.setup(origin, direction, item_data, config, source_entity)
	add_child(swing)
	melee_swings_spawned += 1
	return swing


func spawn_big_bone(origin: Vector2, direction: Vector2, callback: Callable) -> BigBoneProjectile:
	var bone := BigBoneProjectile.new()
	bone.setup(origin, direction, config, callback)
	add_child(bone)
	big_bones_spawned += 1
	return bone


func spawn_rice_ball(origin: Vector2, direction: Vector2, damage: float, source_entity: Node = null, source_dish: ItemData = null) -> RiceBallProjectile:
	var rice_ball := RiceBallProjectile.new()
	rice_ball.setup(origin, direction, damage, config, source_entity, source_dish)
	add_child(rice_ball)
	rice_balls_spawned += 1
	return rice_ball


func spawn_fried_white_rice_ring(origin: Vector2, dish_data: ItemData, source_player: Node) -> Array[RiceBallProjectile]:
	var grains: Array[RiceBallProjectile] = []
	var count := maxi(1, int(dish_data.effect_values.get("grain_count", config.fried_white_rice_grain_count)))
	var jitter := deg_to_rad(float(dish_data.effect_values.get("angle_jitter_degrees", config.fried_white_rice_angle_jitter_degrees)))
	var rotation_offset := ring_random.randf_range(-jitter, jitter)
	var perfect := dish_data.quality == ItemData.Quality.PERFECT
	for index in count:
		var direction := Vector2.RIGHT.rotated(rotation_offset + TAU * float(index) / float(count))
		var grain := spawn_rice_ball(origin + direction * 18.0, direction, float(dish_data.effect_values.get("grain_damage", dish_data.actual_damage)), source_player, dish_data)
		grain.configure_grain(
			float(dish_data.effect_values.get("grain_speed", config.fried_white_rice_grain_speed)),
			float(dish_data.effect_values.get("range", config.fried_white_rice_grain_range)),
			float(dish_data.effect_values.get("move_slow", config.fried_white_rice_perfect_move_slow)) if perfect else 0.0,
			float(dish_data.effect_values.get("slow_duration", config.fried_white_rice_perfect_slow_duration)) if perfect else 0.0,
			dish_data.source_recipe_instance_id
		)
		grains.append(grain)
		fried_white_rice_grains_spawned += 1
	return grains


func spawn_spicy_fried_rice_ring(origin: Vector2, dish_data: ItemData, source_player: Node, perfect_finisher: bool) -> Array[RiceBallProjectile]:
	var grains := _spawn_spicy_ring_now(origin, dish_data, source_player, perfect_finisher, 0.0)
	if perfect_finisher:
		_spawn_delayed_spicy_ring(origin, dish_data, source_player)
	return grains


func _spawn_delayed_spicy_ring(origin: Vector2, dish_data: ItemData, source_player: Node) -> void:
	await get_tree().create_timer(float(dish_data.effect_values.get("second_ring_delay", config.spicy_fried_rice_second_ring_delay))).timeout
	if source_player == null or not is_instance_valid(source_player):
		return
	_spawn_spicy_ring_now(origin, dish_data, source_player, true, PI / 18.0)


func _spawn_spicy_ring_now(origin: Vector2, dish_data: ItemData, source_player: Node, perfect_finisher: bool, extra_rotation: float) -> Array[RiceBallProjectile]:
	var grains: Array[RiceBallProjectile] = []
	var count := maxi(1, int(dish_data.effect_values.get("grain_count", config.spicy_fried_rice_grain_count)))
	var rotation_offset := ring_random.randf_range(-0.08, 0.08) + extra_rotation
	var vulnerability := float(dish_data.effect_values.get("perfect_vulnerability", 0.10)) if perfect_finisher else float(dish_data.effect_values.get("vulnerability", 0.05))
	var duration := float(dish_data.effect_values.get("perfect_duration", 3.0)) if perfect_finisher else float(dish_data.effect_values.get("vulnerability_duration", 2.0))
	for index in count:
		var direction := Vector2.RIGHT.rotated(rotation_offset + TAU * float(index) / float(count))
		var grain := spawn_rice_ball(origin + direction * 18.0, direction, float(dish_data.effect_values.get("grain_damage", dish_data.actual_damage)), source_player, dish_data)
		grain.configure_grain(config.fried_white_rice_grain_speed, float(dish_data.effect_values.get("range", config.spicy_fried_rice_range)), 0.0, 0.0, dish_data.source_recipe_instance_id)
		grain.configure_vulnerability(vulnerability, duration, dish_data.source_recipe_instance_id)
		grains.append(grain)
		spicy_grains_spawned += 1
	return grains


func spawn_spicy_beef_attack(origin: Vector2, direction: Vector2, dish_data: ItemData, source_player: Node, perfect_finisher: bool) -> SpicyBeefAttack:
	var attack := SpicyBeefAttack.new()
	attack.setup(origin, direction, dish_data, source_player, perfect_finisher)
	add_child(attack)
	spicy_attacks_spawned += 1
	return attack


func spawn_rice_cake(mode: int, source_player: Node2D, dish_data: ItemData, direction: Vector2) -> RiceCakeCombatEntity:
	var entity := RiceCakeCombatEntity.new()
	entity.setup(mode, source_player, dish_data, direction)
	add_child(entity)
	rice_cake_entities_spawned += 1
	return entity


func spawn_clear_beef_combo(origin: Vector2, direction: Vector2, dish_data: ItemData, source_player: Node2D, perfect_finisher: bool) -> ClearBeefComboAttack:
	var combo := ClearBeefComboAttack.new()
	combo.setup(origin, direction, dish_data, source_player, perfect_finisher, config)
	add_child(combo)
	clear_beef_combos_spawned += 1
	return combo


func spawn_held_soup_stream(source_player: PrototypePlayer, dish_item: CarryableItem, mode: int) -> HeldSoupStream:
	var stream := HeldSoupStream.new()
	stream.setup(source_player, dish_item, mode)
	add_child(stream)
	held_soup_streams_spawned += 1
	return stream


func spawn_crispy_rice_trap(origin: Vector2, owner_player: PrototypePlayer) -> CrispyRiceTrap:
	var trap := CrispyRiceTrap.new()
	trap.setup(origin, owner_player, config)
	add_child(trap)
	crispy_traps_spawned += 1
	return trap


func spawn_greens_leaf(
	origin: Vector2,
	direction: Vector2,
	dish_data: ItemData,
	source_player: Node2D,
	mode: int,
	resolved_callback: Callable = Callable()
) -> GreensLeafProjectile:
	var leaf := GreensLeafProjectile.new()
	leaf.setup(origin, direction, dish_data, source_player, mode, resolved_callback)
	add_child(leaf)
	greens_leaves_spawned += 1
	return leaf


func spawn_beef_greens_swing(origin: Vector2, direction: Vector2, dish_data: ItemData, source_player: Node, radial: bool) -> BeefGreensSwing:
	var swing := BeefGreensSwing.new()
	swing.setup(origin, direction, dish_data, source_player, radial)
	add_child(swing)
	beef_greens_swings_spawned += 1
	return swing


func spawn_fried_rice(
	origin: Vector2,
	target_position: Vector2,
	dish_data: ItemData,
	source_player: Node,
	mode: int,
	finisher: bool
) -> FriedRiceProjectile:
	var projectile := FriedRiceProjectile.new()
	projectile.setup(origin, target_position, dish_data, source_player, mode, finisher, config)
	add_child(projectile)
	fried_rice_projectiles_spawned += 1
	return projectile


func spawn_mustard_greens_leaf(
	origin: Vector2,
	direction: Vector2,
	item: CarryableItem,
	resolved_callback: Callable
) -> MustardGreensProjectile:
	var projectile := MustardGreensProjectile.new()
	projectile.setup(origin, direction, item, config, resolved_callback)
	add_child(projectile)
	mustard_greens_projectiles_spawned += 1
	return projectile


func reset_for_new_game() -> void:
	clear_active_attacks()
	normal_bulls_spawned = 0
	raging_bulls_spawned = 0
	melee_swings_spawned = 0
	big_bones_spawned = 0
	rice_balls_spawned = 0
	crispy_traps_spawned = 0
	greens_leaves_spawned = 0
	beef_greens_swings_spawned = 0
	fried_rice_projectiles_spawned = 0
	mustard_greens_projectiles_spawned = 0
	fried_white_rice_grains_spawned = 0
	clear_beef_combos_spawned = 0
	held_soup_streams_spawned = 0
	spicy_attacks_spawned = 0
	spicy_grains_spawned = 0
	rice_cake_entities_spawned = 0


func clear_active_attacks() -> void:
	for child in get_children():
		if child is NormalBull or child is RagingBull or child is MeleeSwing or child is BigBoneProjectile or child is RiceBallProjectile or child is CrispyRiceTrap or child is GreensLeafProjectile or child is BeefGreensSwing or child is FriedRiceProjectile or child is MustardGreensProjectile:
			child.queue_free()
	for deployable in get_tree().get_nodes_in_group("run_deployable"):
		if is_instance_valid(deployable):
			deployable.queue_free()
	for attack_entity in get_tree().get_nodes_in_group("temporary_attack_entity"):
		if is_instance_valid(attack_entity):
			attack_entity.queue_free()
