class_name RestaurantWhiteboxLayout
extends Node2D

# Prototype-only restaurant graybox. Interactive stations remain separate scene nodes;
# this layer owns the four real L-shaped kitchen-island collision footprints.

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

# Each island uses two joined rectangles: one horizontal arm and one vertical arm.
# These values are the world-space projection of the alpha bounds of
# CookingIslandsArt (placed at 1776,1392 and scaled from 1448x1086). Keeping the
# footprint here, instead of on individual appliance nodes, makes navigation
# match the static counter pixels and leaves a clean upgrade point for a future
# visual/animation adapter.
const RESERVED_COUNTER_SPECS: Array[Dictionary] = [
	{"name": &"NorthWestHorizontal", "island": &"north_west", "rect": Rect2(1820.0, 1438.0, 420.0, 108.0)},
	{"name": &"NorthWestVertical", "island": &"north_west", "rect": Rect2(1820.0, 1438.0, 108.0, 232.0)},
	{"name": &"NorthEastHorizontal", "island": &"north_east", "rect": Rect2(2384.0, 1438.0, 404.0, 108.0)},
	{"name": &"NorthEastVertical", "island": &"north_east", "rect": Rect2(2680.0, 1438.0, 108.0, 232.0)},
	{"name": &"SouthWestVertical", "island": &"south_west", "rect": Rect2(1820.0, 1780.0, 108.0, 240.0)},
	{"name": &"SouthWestHorizontal", "island": &"south_west", "rect": Rect2(1820.0, 1857.0, 420.0, 95.0)},
	{"name": &"SouthEastVertical", "island": &"south_east", "rect": Rect2(2680.0, 1780.0, 108.0, 240.0)},
	{"name": &"SouthEastHorizontal", "island": &"south_east", "rect": Rect2(2370.0, 1857.0, 418.0, 95.0)},
]

var map_bounds := DEFAULT_MAP_BOUNDS
@export var draw_legacy_visuals: bool = true
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
	if not draw_legacy_visuals:
		return
	# The visual floor and restaurant furniture are drawn by RestaurantVisualLayer.
	# These counter bodies match the collision exactly; appliances remain separate.
	for spec in RESERVED_COUNTER_SPECS:
		var rect: Rect2 = spec["rect"]
		_draw_counter_segment(rect)


func _draw_counter_segment(rect: Rect2) -> void:
	# Neutral graphite cabinetry with a warm service-light toe-kick. It is purposely
	# axis-aligned so later final art can replace it without changing the footprint.
	draw_rect(rect, Color("#20262b"), true)
	draw_rect(rect.grow(-5.0), Color("#343b40"), true)
	draw_rect(rect.grow(-11.0), Color("#2a3035"), true)
	draw_rect(rect, Color("#637078"), false, 3.0)
	draw_rect(rect.grow(-8.0), Color("#151a1e"), false, 2.0)

	var light_y := rect.end.y - 16.0
	draw_line(Vector2(rect.position.x + 16.0, light_y), Vector2(rect.end.x - 16.0, light_y), Color("#dca952", 0.8), 3.0)
	if rect.size.x > rect.size.y:
		var module_count := maxi(1, floori((rect.size.x - 40.0) / 72.0))
		for index in range(module_count):
			var module_x := rect.position.x + 24.0 + index * 72.0
			draw_rect(Rect2(module_x, rect.position.y + 22.0, 44.0, 18.0), Color("#4a5359"), true)
			draw_rect(Rect2(module_x, rect.position.y + 22.0, 44.0, 18.0), Color("#7b858a"), false, 1.0)
	else:
		var module_count := maxi(1, floori((rect.size.y - 40.0) / 64.0))
		for index in range(module_count):
			var module_y := rect.position.y + 20.0 + index * 64.0
			draw_rect(Rect2(rect.position.x + 22.0, module_y, 18.0, 38.0), Color("#4a5359"), true)
			draw_rect(Rect2(rect.position.x + 22.0, module_y, 18.0, 38.0), Color("#7b858a"), false, 1.0)


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
