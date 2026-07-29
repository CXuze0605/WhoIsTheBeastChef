class_name RiceEffectZone
extends Node2D

var dish_data: ItemData
var duration_left: float = 0.0
var radius: float = 145.0
var source_id: String
var config: PrototypeCombatConfig
var perfect_snapshot: bool = false


func setup(origin: Vector2, data: ItemData, combat_config: PrototypeCombatConfig, perfect: bool) -> void:
	global_position = origin
	dish_data = data
	config = combat_config
	perfect_snapshot = perfect
	radius = float(data.effect_values.get("perfect_radius", 205.0)) if perfect else float(data.effect_values.get("radius", 145.0))
	duration_left = float(data.effect_values.get("perfect_duration", 7.0)) if perfect else float(data.effect_values.get("duration", 5.0))
	source_id = "rice_zone_%d" % get_instance_id()


func _ready() -> void:
	add_to_group("run_deployable")
	add_to_group("rice_effect_zone")
	z_index = 4
	queue_redraw()


func _draw() -> void:
	var greens := dish_data.recipe_id in [
		ExpandedRecipeCatalog.GREENS_SOAKED_RICE,
		ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
	]
	var color := Color(0.42, 0.76, 0.48, 0.22) if greens else Color(0.58, 0.78, 0.88, 0.22)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, color.lightened(0.2), 4.0)


func _process(delta: float) -> void:
	duration_left -= delta
	for target in get_tree().get_nodes_in_group("damageable"):
		if not target is Node2D or not is_instance_valid(target):
			continue
		if global_position.distance_to((target as Node2D).global_position) > radius:
			continue
		var statuses := CombatStatusController.ensure_on(target)
		statuses.apply_status(
			CombatStatusController.StatusType.MOVE_SLOW,
			source_id,
			_get_move_slow(),
			config.soaked_rice_residual_duration
		)
		statuses.apply_status(
			CombatStatusController.StatusType.ATTACK_SPEED_SLOW,
			source_id,
			_get_attack_slow(),
			config.soaked_rice_residual_duration
		)
		var weakness := float(dish_data.effect_values.get(
			"perfect_weakness" if perfect_snapshot else "weakness",
			dish_data.effect_values.get("weakness", 0.0)
		))
		if weakness > 0.0:
			statuses.apply_status(
				CombatStatusController.StatusType.WEAKNESS,
				source_id,
				weakness,
				config.soaked_rice_residual_duration
			)
		var vulnerability := float(dish_data.effect_values.get(
			"perfect_vulnerability" if perfect_snapshot else "vulnerability",
			dish_data.effect_values.get("vulnerability", 0.0)
		))
		if vulnerability > 0.0:
			statuses.apply_status(
				CombatStatusController.StatusType.VULNERABILITY,
				source_id,
				vulnerability,
				config.soaked_rice_residual_duration
			)
	if duration_left <= 0.0:
		queue_free()


func _get_move_slow() -> float:
	return float(dish_data.effect_values.get(
		"perfect_move_slow" if perfect_snapshot else "move_slow",
		0.0
	))


func _get_attack_slow() -> float:
	return float(dish_data.effect_values.get(
		"perfect_attack_slow" if perfect_snapshot else "attack_slow",
		0.0
	))
