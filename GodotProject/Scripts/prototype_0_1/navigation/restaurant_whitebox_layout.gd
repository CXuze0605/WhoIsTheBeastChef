class_name RestaurantWhiteboxLayout
extends Node2D

# Prototype-only restaurant graybox. Interactive stations remain separate scene nodes;
# this layer owns only floor zoning, static dining furniture and reserved counters.

const DEFAULT_MAP_BOUNDS := Rect2(0.0, 0.0, 4608.0, 3456.0)
const KITCHEN_FLOOR_RECT := Rect2(1776.0, 1392.0, 1056.0, 672.0)
const CENTRAL_CLEAR_CORE := Rect2(2112.0, 1600.0, 384.0, 256.0)

const DINING_OBSTACLE_SPECS: Array[Dictionary] = [
	{"name": &"NorthTableWest", "rect": Rect2(780.0, 432.0, 360.0, 144.0)},
	{"name": &"NorthTableEast", "rect": Rect2(3468.0, 432.0, 360.0, 144.0)},
	{"name": &"WestTableNorth", "rect": Rect2(480.0, 1008.0, 240.0, 224.0)},
	{"name": &"WestTableSouth", "rect": Rect2(480.0, 2224.0, 240.0, 224.0)},
	{"name": &"EastServiceIsland", "rect": Rect2(3990.0, 1136.0, 220.0, 480.0)},
	{"name": &"SouthTableWest", "rect": Rect2(780.0, 2792.0, 360.0, 144.0)},
]

const RESERVED_COUNTER_SPECS: Array[Dictionary] = [
	{"name": &"NorthWestCornerCounter", "rect": Rect2(1824.0, 1548.0, 128.0, 72.0)},
	{"name": &"NorthEastCornerCounter", "rect": Rect2(2656.0, 1548.0, 128.0, 72.0)},
	{"name": &"SouthWestSpareCounter", "rect": Rect2(2080.0, 1932.0, 128.0, 72.0)},
	{"name": &"SouthEastVerticalCounter", "rect": Rect2(2656.0, 1888.0, 128.0, 72.0)},
	{"name": &"SouthEastCounterLeft", "rect": Rect2(2400.0, 1932.0, 128.0, 72.0)},
	{"name": &"SouthEastCounterCenter", "rect": Rect2(2528.0, 1932.0, 128.0, 72.0)},
	{"name": &"SouthEastCounterRight", "rect": Rect2(2656.0, 1932.0, 128.0, 72.0)},
]

var map_bounds := DEFAULT_MAP_BOUNDS
var spawned_obstacles: Array[KitchenObstacle] = []


func _ready() -> void:
	add_to_group("restaurant_whitebox_layout")
	_spawn_static_obstacles()
	queue_redraw()


func configure(bounds: Rect2) -> void:
	map_bounds = bounds
	queue_redraw()


func _spawn_static_obstacles() -> void:
	if not spawned_obstacles.is_empty():
		return
	for spec in DINING_OBSTACLE_SPECS + RESERVED_COUNTER_SPECS:
		var rect: Rect2 = spec["rect"]
		var obstacle := KitchenObstacle.new()
		obstacle.name = StringName(spec["name"])
		obstacle.position = rect.get_center()
		obstacle.obstacle_size = rect.size
		add_child(obstacle)
		spawned_obstacles.append(obstacle)


func _draw() -> void:
	draw_rect(map_bounds, Color("#30363d"), true)
	draw_rect(map_bounds.grow(-24.0), Color("#49515a"), false, 4.0)
	draw_rect(KITCHEN_FLOOR_RECT, Color("#59646b"), true)
	draw_rect(KITCHEN_FLOOR_RECT, Color("#aab7bd"), false, 4.0)
	draw_rect(CENTRAL_CLEAR_CORE, Color(0.72, 0.78, 0.78, 0.16), true)
	draw_rect(CENTRAL_CLEAR_CORE, Color(0.73, 0.84, 0.84, 0.65), false, 3.0)

	for spec in DINING_OBSTACLE_SPECS:
		var rect: Rect2 = spec["rect"]
		draw_rect(rect, Color("#665c55"), true)
		draw_rect(rect, Color("#c0aaa0"), false, 3.0)
	for spec in RESERVED_COUNTER_SPECS:
		var rect: Rect2 = spec["rect"]
		draw_rect(rect, Color("#344a54"), true)
		draw_rect(rect, Color("#8fb2bf"), false, 3.0)

	# Boundary-only modern service silhouettes. They deliberately have no gameplay
	# collision yet, so the south combat lane remains broad during graybox testing.
	draw_rect(Rect2(2160.0, 3328.0, 288.0, 64.0), Color("#27333a"), true)
	draw_rect(Rect2(2160.0, 3328.0, 288.0, 64.0), Color("#8da2ad"), false, 3.0)


func get_dining_obstacle_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in DINING_OBSTACLE_SPECS:
		result.append(spec["rect"])
	return result


func get_reserved_counter_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in RESERVED_COUNTER_SPECS:
		result.append(spec["rect"])
	return result
