class_name MustardGreensProjectile
extends Node2D

var direction := Vector2.RIGHT
var speed: float = 560.0
var max_range: float = 420.0
var travelled: float = 0.0
var source_item: CarryableItem
var resolved_callback: Callable


func setup(
	origin: Vector2,
	shot_direction: Vector2,
	item: CarryableItem,
	combat_config: PrototypeCombatConfig,
	callback: Callable
) -> void:
	global_position = origin
	direction = shot_direction.normalized()
	source_item = item
	resolved_callback = callback
	speed = float(item.data.effect_values.get("projectile_speed", combat_config.mustard_greens_projectile_speed))
	max_range = float(item.data.effect_values.get("range", combat_config.mustard_greens_range))


func _ready() -> void:
	z_index = 13
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color("a7c847"))
	draw_circle(Vector2.ZERO, 4.0, Color("d8a928"))


func _process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	travelled += step.length()
	var controller := get_tree().get_first_node_in_group("auto_dish_controller") as AutoDishEquipmentController
	for target in get_tree().get_nodes_in_group("damageable"):
		if (
			target is Node2D
			and target.has_method("get_combat_faction")
			and int(target.get_combat_faction()) == CombatRules.Faction.ENEMY
			and global_position.distance_to(target.global_position) <= 20.0
			and (controller == null or not controller.is_target_marked_by_any(target))
		):
			if not resolved_callback.is_null():
				resolved_callback.call(target)
			queue_free()
			return
	if travelled >= max_range:
		if not resolved_callback.is_null():
			resolved_callback.call(null)
		queue_free()
