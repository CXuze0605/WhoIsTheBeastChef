class_name RestaurantVisualLayer
extends Node2D

# Presentation-only foundation layer. It deliberately follows the current
# whitebox footprint and never creates collisions, navigation or interactables.

const MAP_BOUNDS := RestaurantWhiteboxLayout.DEFAULT_MAP_BOUNDS
const KITCHEN_RECT := RestaurantWhiteboxLayout.KITCHEN_FLOOR_RECT

const RESTAURANT_TILE := preload("res://Assets/VisualLock/MapFloor/map_floor_restaurant_terrazzo_32.png")
const KITCHEN_TILE := preload("res://Assets/VisualLock/MapFloor/map_floor_kitchen_antislip_32.png")
const TABLE_TWO := preload("res://Assets/VisualLock/Furniture/south_facing_v1/furniture_table_two_person_south_v1.png")
const TABLE_LONG := preload("res://Assets/VisualLock/Furniture/south_facing_v1/furniture_table_communal_south_v1.png")
const DRINKS := preload("res://Assets/VisualLock/Furniture/south_facing_v1/furniture_drinks_cabinet_south_v1.png")
const SERVING := preload("res://Assets/VisualLock/Furniture/south_facing_v1/furniture_serving_shelf_south_v1.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -8
	call_deferred("queue_redraw")

func _draw() -> void:
	_draw_tiled_rect(RESTAURANT_TILE, MAP_BOUNDS)
	_draw_tiled_rect(KITCHEN_TILE, KITCHEN_RECT)
	_draw_restaurant_architecture()
	_draw_kitchen_lighting()
	_draw_dining_furniture()


func _draw_restaurant_architecture() -> void:
	# Visual-only perimeter: dark window mullions, night-city glow and warm wall light.
	var frame := 112.0
	draw_rect(MAP_BOUNDS, Color("#151b21"), false, frame)
	draw_rect(MAP_BOUNDS.grow(-frame + 12.0), Color("#52606a"), false, 3.0)
	for x in range(224, int(MAP_BOUNDS.size.x - 224.0), 224):
		_draw_window_panel(Rect2(float(x), 26.0, 176.0, 70.0))
		_draw_window_panel(Rect2(float(x), MAP_BOUNDS.end.y - 96.0, 176.0, 70.0))
	for y in range(224, int(MAP_BOUNDS.size.y - 224.0), 224):
		_draw_window_panel(Rect2(26.0, float(y), 70.0, 176.0))
		_draw_window_panel(Rect2(MAP_BOUNDS.end.x - 96.0, float(y), 70.0, 176.0))


func _draw_window_panel(rect: Rect2) -> void:
	draw_rect(rect, Color("#101b27"), true)
	draw_rect(rect.grow(-6.0), Color("#0d3552"), true)
	draw_rect(rect, Color("#5a6670"), false, 2.0)
	var center := rect.get_center()
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.16, Color("#4fb2d1", 0.32))
	draw_circle(center + Vector2(12.0, -8.0), 3.0, Color("#a6d9e9", 0.75))


func _draw_kitchen_lighting() -> void:
	# Wide warm pools make the open kitchen read as an intentional centerpiece.
	var light_points := [
		Vector2(1960.0, 1510.0), Vector2(2648.0, 1510.0),
		Vector2(1960.0, 1946.0), Vector2(2648.0, 1946.0),
	]
	for point in light_points:
		draw_circle(point, 178.0, Color("#e4ad5d", 0.055))
		draw_circle(point, 104.0, Color("#f3c879", 0.055))
	draw_rect(KITCHEN_RECT, Color("#72808a", 0.7), false, 2.0)

func _draw_tiled_rect(texture: Texture2D, rect: Rect2) -> void:
	var tile_size := texture.get_size()
	var columns := ceili(rect.size.x / tile_size.x)
	var rows := ceili(rect.size.y / tile_size.y)
	for row in range(rows):
		for column in range(columns):
			draw_texture(texture, rect.position + Vector2(column * tile_size.x, row * tile_size.y))

func _draw_dining_furniture() -> void:
	# These positions match RestaurantWhiteboxLayout.DINING_OBSTACLE_SPECS.
	_draw_centered(TABLE_LONG, Vector2(960, 504), Vector2(288, 128))
	_draw_centered(TABLE_LONG, Vector2(3648, 504), Vector2(288, 128))
	_draw_centered(TABLE_TWO, Vector2(600, 1120), Vector2(192, 192))
	_draw_centered(TABLE_TWO, Vector2(600, 2336), Vector2(192, 192))
	_draw_centered(DRINKS, Vector2(4100, 1376), Vector2(176, 384))
	_draw_centered(TABLE_LONG, Vector2(960, 2864), Vector2(288, 128))
	_draw_centered(SERVING, Vector2(2304, 3360), Vector2(256, 96))

func _draw_centered(texture: Texture2D, center: Vector2, size: Vector2) -> void:
	draw_texture_rect(texture, Rect2(center - size * 0.5, size), false)
