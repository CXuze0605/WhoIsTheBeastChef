class_name PrototypeMapController
extends Node

# Applies the centralized PrototypeWaveConfig spatial values to the graybox scene.
# The layout is intentionally replaceable and is not a final level-design decision.

var config: PrototypeWaveConfig


func _ready() -> void:
	add_to_group("prototype_map_controller")
	var manager := get_parent().get_node_or_null("WaveManager") as PrototypeWaveManager
	config = manager.config if manager != null else PrototypeWaveConfig.new()
	_apply_expanded_map()


func _apply_expanded_map() -> void:
	var scene_root := get_parent()
	var bounds := config.map_bounds
	var floor := scene_root.get_node_or_null("Floor") as Polygon2D
	if floor != null:
		floor.polygon = PackedVector2Array([
			bounds.position,
			Vector2(bounds.end.x, bounds.position.y),
			bounds.end,
			Vector2(bounds.position.x, bounds.end.y),
		])
	var floor_art := scene_root.get_node_or_null("FloorArt") as NinePatchRect
	if floor_art != null:
		floor_art.position = bounds.position
		floor_art.size = bounds.size
	var whitebox := scene_root.get_node_or_null("RestaurantWhitebox") as RestaurantWhiteboxLayout
	if whitebox != null:
		whitebox.configure(bounds)
	var title := scene_root.get_node_or_null("PrototypeTitle") as Label
	if title != null:
		title.position = Vector2(bounds.position.x, bounds.end.y - 38.0)
		title.size = Vector2(bounds.size.x, 30.0)

	var kitchen := scene_root.get_node_or_null("Kitchen") as Node2D
	if kitchen != null:
		kitchen.position = config.kitchen_offset
		var player := kitchen.get_node_or_null("Player") as PrototypePlayer
		if player != null:
			player.spawn_position = player.global_position

	_apply_boundary_bodies(scene_root, bounds)
	_apply_navigation(scene_root, bounds)
	_apply_spawn_points(scene_root, bounds)
	_apply_camera(scene_root, bounds)
	_apply_combat_bounds(scene_root, bounds)


func _apply_boundary_bodies(scene_root: Node, bounds: Rect2) -> void:
	var horizontal_size := Vector2(bounds.size.x + 20.0, 28.0)
	var vertical_size := Vector2(28.0, bounds.size.y + 16.0)
	var center := bounds.get_center()
	var top := scene_root.get_node_or_null("Bounds/Top") as StaticBody2D
	var bottom := scene_root.get_node_or_null("Bounds/Bottom") as StaticBody2D
	var left := scene_root.get_node_or_null("Bounds/Left") as StaticBody2D
	var right := scene_root.get_node_or_null("Bounds/Right") as StaticBody2D
	if top != null:
		top.position = Vector2(center.x, bounds.position.y - 8.0)
		_set_rectangle_size(top, horizontal_size)
	if bottom != null:
		bottom.position = Vector2(center.x, bounds.end.y + 8.0)
		_set_rectangle_size(bottom, horizontal_size)
	if left != null:
		left.position = Vector2(bounds.position.x - 8.0, center.y)
		_set_rectangle_size(left, vertical_size)
	if right != null:
		right.position = Vector2(bounds.end.x + 8.0, center.y)
		_set_rectangle_size(right, vertical_size)


func _set_rectangle_size(body: StaticBody2D, size: Vector2) -> void:
	var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var rectangle := collision.shape as RectangleShape2D
	if rectangle != null:
		# Duplicate shared scene shapes so each orientation remains independent.
		rectangle = rectangle.duplicate() as RectangleShape2D
		collision.shape = rectangle
		rectangle.size = size


func _apply_navigation(scene_root: Node, bounds: Rect2) -> void:
	var navigation := scene_root.get_node_or_null("KitchenNavigation") as KitchenNavigationGrid
	if navigation == null:
		return
	var inset := config.navigation_inset
	navigation.walkable_bounds = Rect2(
		bounds.position + Vector2.ONE * inset,
		bounds.size - Vector2.ONE * inset * 2.0
	)
	navigation.call_deferred("rebuild")


func _apply_spawn_points(scene_root: Node, bounds: Rect2) -> void:
	var points := scene_root.get_node_or_null("SpawnPoints")
	if points == null:
		return
	var edge_inset := maxf(config.spawn_edge_inset, config.navigation_inset + 16.0)
	var left_x := bounds.position.x + edge_inset
	var right_x := bounds.end.x - edge_inset
	var top_y := bounds.position.y + edge_inset
	var bottom_y := bounds.end.y - edge_inset
	var positions := {
		"LeftTop": Vector2(left_x, bounds.position.y + bounds.size.y * 0.315),
		"LeftBottom": Vector2(left_x, bounds.position.y + bounds.size.y * 0.685),
		"RightTop": Vector2(right_x, bounds.position.y + bounds.size.y * 0.315),
		"RightBottom": Vector2(right_x, bounds.position.y + bounds.size.y * 0.685),
		"TopLeft": Vector2(bounds.position.x + bounds.size.x / 6.0, top_y),
		"TopCenter": Vector2(bounds.get_center().x, top_y),
		"TopRight": Vector2(bounds.position.x + bounds.size.x * 5.0 / 6.0, top_y),
		"BottomLeft": Vector2(bounds.position.x + bounds.size.x / 6.0, bottom_y),
		"BottomCenter": Vector2(bounds.get_center().x, bottom_y),
		"BottomRight": Vector2(bounds.position.x + bounds.size.x * 5.0 / 6.0, bottom_y),
	}
	for point_name in positions:
		var point := points.get_node_or_null(NodePath(point_name)) as Marker2D
		if point != null:
			point.position = positions[point_name]


func _apply_camera(scene_root: Node, bounds: Rect2) -> void:
	var camera := scene_root.get_node_or_null("Kitchen/Player/Camera2D") as Camera2D
	if camera == null:
		return
	var margin := config.camera_limit_margin
	camera.limit_left = roundi(bounds.position.x - margin)
	camera.limit_top = roundi(bounds.position.y - margin)
	camera.limit_right = roundi(bounds.end.x + margin)
	camera.limit_bottom = roundi(bounds.end.y + margin)
	camera.zoom = config.camera_zoom
	camera.enabled = true


func _apply_combat_bounds(scene_root: Node, bounds: Rect2) -> void:
	var combat := scene_root.get_node_or_null("CombatRuntime") as CombatManager
	if combat != null:
		combat.config.combat_bounds = bounds


func get_map_bounds() -> Rect2:
	return config.map_bounds if config != null else Rect2()
