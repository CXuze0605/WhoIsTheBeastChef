class_name KitchenNavigationGrid
extends Node2D

@export var walkable_bounds := Rect2(42.0, 42.0, 1792.0, 1300.0)
@export var cell_size: float = 32.0
@export var agent_radius: float = 15.0

var grid := AStarGrid2D.new()


func _ready() -> void:
	add_to_group("kitchen_navigation")
	call_deferred("rebuild")


func rebuild() -> void:
	var cells := Vector2i(
		maxi(1, ceili(walkable_bounds.size.x / cell_size)),
		maxi(1, ceili(walkable_bounds.size.y / cell_size))
	)
	grid.region = Rect2i(Vector2i.ZERO, cells)
	grid.cell_size = Vector2(cell_size, cell_size)
	grid.offset = walkable_bounds.position + Vector2.ONE * cell_size * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for obstacle_node in get_tree().get_nodes_in_group("kitchen_obstacle"):
		var obstacle := obstacle_node as KitchenObstacle
		if obstacle == null:
			continue
		var blocked_rect := obstacle.get_navigation_rect(agent_radius)
		for y in cells.y:
			for x in cells.x:
				var id := Vector2i(x, y)
				if blocked_rect.has_point(grid.get_point_position(id)):
					grid.set_point_solid(id, true)


func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	if grid.region.size == Vector2i.ZERO:
		rebuild()
	var from_id := _nearest_open_id(_world_to_id(from_world))
	var to_id := _nearest_open_id(_world_to_id(to_world))
	if from_id.x < 0 or to_id.x < 0:
		return PackedVector2Array()
	return grid.get_point_path(from_id, to_id)


func is_position_walkable(world_position: Vector2) -> bool:
	if not walkable_bounds.has_point(world_position):
		return false
	var id: Vector2i = _world_to_id(world_position)
	return grid.is_in_boundsv(id) and not grid.is_point_solid(id)


func _world_to_id(world_position: Vector2) -> Vector2i:
	var local := (world_position - grid.offset) / grid.cell_size
	return Vector2i(roundi(local.x), roundi(local.y))


func _nearest_open_id(origin: Vector2i) -> Vector2i:
	if grid.is_in_boundsv(origin) and not grid.is_point_solid(origin):
		return origin
	for radius in range(1, 5):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate := Vector2i(x, y)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)
