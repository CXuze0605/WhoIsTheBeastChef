class_name RiceBowlTurret
extends Node2D

var dish_data: ItemData
var config: PrototypeCombatConfig
var cooldown_left: float = 0.0
var random := RandomNumberGenerator.new()
var shot_bag: Array[int] = []
var shot_history: Array[int] = []
var projectiles_fired: int = 0


func setup(data: ItemData, combat_config: PrototypeCombatConfig, seed_value: int = -1) -> void:
	dish_data = data
	config = combat_config
	dish_data.deployment_state = ItemData.DeploymentState.DEPLOYED
	if seed_value >= 0:
		random.seed = seed_value
	else:
		random.randomize()


func _ready() -> void:
	add_to_group("run_deployable")
	add_to_group("rice_bowl_turret")
	z_index = 7
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 30.0, Color("a88752"))
	draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 24, Color("f1d69c"), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(-24.0, -42.0), "盖饭炮台", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


func _process(delta: float) -> void:
	if dish_data == null or dish_data.current_durability <= 0:
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if cooldown_left > 0.0:
		return
	var enemies := _enemies_in_range()
	if enemies.is_empty():
		return
	var is_final := dish_data.current_durability == 1
	var turret_kind := StringName(dish_data.effect_values.get("turret_kind", &"mixed"))
	if turret_kind == &"greens":
		if is_final and dish_data.quality == ItemData.Quality.PERFECT:
			_fire_greens_fan(enemies[0])
		else:
			_fire_mode(TurretDishProjectile.Mode.GREENS_PIERCE, enemies)
	elif turret_kind == &"beef":
		_fire_mode(
			TurretDishProjectile.Mode.BEEF_SINGLE,
			enemies,
			float(dish_data.effect_values.get("beef_finisher_damage", 90.0))
			if is_final and dish_data.quality == ItemData.Quality.PERFECT
			else -1.0,
			is_final and dish_data.quality == ItemData.Quality.PERFECT
		)
	elif is_final and dish_data.quality == ItemData.Quality.PERFECT:
		for mode in [
			TurretDishProjectile.Mode.RICE_AOE,
			TurretDishProjectile.Mode.GREENS_PIERCE,
			TurretDishProjectile.Mode.BEEF_SINGLE,
		]:
			_fire_mode(mode, enemies)
	else:
		_fire_mode(_draw_bag_mode(), enemies)
	dish_data.current_durability -= 1
	dish_data.mark_used()
	cooldown_left = float(dish_data.effect_values.get("interval", config.rice_bowl_turret_interval))
	if dish_data.current_durability <= 0:
		_spawn_dirty_plate()
		queue_free()


func _draw_bag_mode() -> int:
	if shot_bag.is_empty():
		shot_bag = [
			TurretDishProjectile.Mode.RICE_AOE,
			TurretDishProjectile.Mode.GREENS_PIERCE,
			TurretDishProjectile.Mode.BEEF_SINGLE,
		]
		for index in range(shot_bag.size() - 1, 0, -1):
			var swap_index := random.randi_range(0, index)
			var temp := shot_bag[index]
			shot_bag[index] = shot_bag[swap_index]
			shot_bag[swap_index] = temp
	return shot_bag.pop_back()


func _fire_mode(mode: int, enemies: Array[Node2D], damage_override: float = -1.0, force_healthiest: bool = false) -> void:
	var target := _choose_target(mode, enemies, force_healthiest)
	if target == null:
		return
	var projectile := TurretDishProjectile.new()
	projectile.setup(global_position, target, mode, dish_data, self, damage_override)
	get_tree().current_scene.add_child(projectile)
	shot_history.append(mode)
	projectiles_fired += 1


func _fire_greens_fan(target: Node2D) -> void:
	if target == null:
		return
	var count := maxi(1, int(dish_data.effect_values.get("finisher_count", 5)))
	var arc := deg_to_rad(float(dish_data.effect_values.get("finisher_arc_degrees", 70.0)))
	var center := global_position.direction_to(target.global_position).angle()
	for index in count:
		var ratio := 0.5 if count == 1 else float(index) / float(count - 1)
		var direction := Vector2.from_angle(center + lerpf(-arc * 0.5, arc * 0.5, ratio))
		var projectile := TurretDishProjectile.new()
		projectile.setup_direction(global_position, direction, dish_data, self)
		get_tree().current_scene.add_child(projectile)
		shot_history.append(TurretDishProjectile.Mode.GREENS_PIERCE)
		projectiles_fired += 1


func _choose_target(mode: int, enemies: Array[Node2D], force_healthiest: bool = false) -> Node2D:
	if enemies.is_empty():
		return null
	var turret_kind := StringName(dish_data.effect_values.get("turret_kind", &"mixed"))
	if mode == TurretDishProjectile.Mode.BEEF_SINGLE and (force_healthiest or turret_kind == &"mixed"):
		var healthiest := enemies[0]
		for enemy in enemies:
			if float(enemy.get("current_health")) > float(healthiest.get("current_health")):
				healthiest = enemy
		return healthiest
	if mode == TurretDishProjectile.Mode.BEEF_SINGLE:
		return _nearest_enemy(enemies)
	if mode == TurretDishProjectile.Mode.RICE_AOE:
		var best := enemies[0]
		var best_neighbors := -1
		for candidate in enemies:
			var neighbors := 0
			for other in enemies:
				if candidate.global_position.distance_to(other.global_position) <= float(dish_data.effect_values.get("rice_radius", 82.0)):
					neighbors += 1
			if neighbors > best_neighbors:
				best_neighbors = neighbors
				best = candidate
		return best
	var best_line := enemies[0]
	var best_hits := -1
	for candidate in enemies:
		var shot_direction := global_position.direction_to(candidate.global_position)
		var hits := 0
		for other in enemies:
			var along := (other.global_position - global_position).dot(shot_direction)
			var lateral := absf((other.global_position - global_position).cross(shot_direction))
			if along > 0.0 and lateral <= 32.0:
				hits += 1
		if hits > best_hits:
			best_hits = hits
			best_line = candidate
	return best_line


func _nearest_enemy(enemies: Array[Node2D]) -> Node2D:
	var nearest := enemies[0]
	for enemy in enemies:
		if global_position.distance_squared_to(enemy.global_position) < global_position.distance_squared_to(nearest.global_position):
			nearest = enemy
	return nearest


func _enemies_in_range() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var attack_range := float(dish_data.effect_values.get("range", config.rice_bowl_turret_range))
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if (
			candidate is Node2D
			and candidate.has_method("get_combat_faction")
			and int(candidate.get_combat_faction()) == CombatRules.Faction.ENEMY
			and global_position.distance_to(candidate.global_position) <= attack_range
		):
			result.append(candidate)
	return result


func _spawn_dirty_plate() -> void:
	if dish_data == null or dish_data.carried_plate_state != ItemData.PlateState.CLEAN:
		return
	var plate := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE))
	get_tree().current_scene.add_child(plate)
	plate.release_to_world(get_tree().current_scene, global_position)
