extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var navigation := scene.get_node("KitchenNavigation") as KitchenNavigationGrid
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	var spawn_points: Array[Node] = get_nodes_in_group("enemy_spawn_point")

	_expect(manager.config.map_bounds == Rect2(0.0, 0.0, 4608.0, 3456.0), "Map bounds must use the approved doubled 4608x3456 restaurant graybox")
	_expect(manager.config.kitchen_offset == Vector2(1776.0, 1392.0), "The unchanged 1056x672 open kitchen must be centered in the doubled map")
	_expect(manager.config.enemy_move_speed == 164.0 and manager.config.heavy_move_speed == 104.0, "Ordinary enemy traversal speeds must double with the larger restaurant")
	_expect(manager.config.fast_dash_speed == 620.0 and manager.config.ranged_projectile_speed == 360.0, "Fast pounce and ranged projectile speeds must not be doubled")
	_expect(player.global_position == manager.config.map_bounds.get_center(), "The player and central kitchen core must begin at the geometric center of the doubled map")
	_expect(scene.get_node_or_null("RestaurantWhitebox") == null, "The 0.0.3 art rollback must remove the later shared L-shaped kitchen layer")
	var static_station_names := ["IngredientCabinet", "CuttingBoard", "MarinatingStation", "WokStation", "StoveStation2", "CookwareRack", "CleanPlatePile", "Sink", "TrashBin"]
	for station_name in static_station_names:
		var station := scene.get_node("Kitchen/" + station_name) as Interactable
		_expect(station != null and station.show_placeholder_art and station.use_individual_obstacle, "0.0.3 station %s must use its own static art and collision" % station_name)
	var cutting_boards := get_nodes_in_group("cutting_board")
	_expect(cutting_boards.size() == 1, "The 0.0.3 kitchen must expose one cutting-board interaction point")
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	_expect(sink.position == Vector2(840.0, 320.0), "The sink interaction point must return to the 0.0.3 layout")
	player.global_position = sink.global_position + Vector2(-100.0, 0.0)
	player._update_current_target()
	_expect(player.current_target == sink and player.get_interaction_prompt().begins_with("水池："), "Approaching the sink must show the sink name instead of a cooking prompt")
	await process_frame
	var interaction_panel := hud.find_child("InteractionPromptPanel", true, false) as PanelContainer
	_expect(interaction_panel != null and interaction_panel.visible, "A nearby station must expose the high-contrast interaction prompt panel")
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	player.global_position = cabinet.global_position + Vector2(-80.0, 0.0)
	player._update_current_target()
	_expect(player.current_target == cabinet and player.get_interaction_prompt().begins_with("异形食材柜："), "The ingredient cabinet must remain reachable in the restored 0.0.3 kitchen layout")
	player.global_position = manager.config.map_bounds.get_center()
	player._update_current_target()
	_expect(spawn_points.size() == 10, "The map must expose ten candidate edge spawn lanes")

	var lane_ids: Dictionary = {}
	var edge_counts := {"上侧": 0, "下侧": 0, "左侧": 0, "右侧": 0}
	for node in spawn_points:
		var point := node as WaveSpawnPoint
		lane_ids[point.lane_id] = true
		edge_counts[point.edge_label] = int(edge_counts.get(point.edge_label, 0)) + 1
		_expect(navigation.is_position_walkable(point.global_position), "Spawn lane %s must begin on a walkable cell" % point.lane_id)
		_expect(not navigation.find_path(point.global_position, player.global_position).is_empty(), "Spawn lane %s must have a route into the kitchen" % point.lane_id)
	_expect(lane_ids.size() == 10, "Every candidate spawn lane must have a unique stable ID")
	_expect(edge_counts == {"上侧": 3, "下侧": 3, "左侧": 2, "右侧": 2}, "Spawn lanes must remain distributed 3/3/2/2 across the four map edges")

	for station_name in static_station_names:
		var station_obstacle := scene.get_node("Kitchen/" + station_name + "/Obstacle") as KitchenObstacle
		_expect(station_obstacle != null and station_obstacle.navigation_enabled and station_obstacle.obstacle_size.x > 0.0 and station_obstacle.obstacle_size.y > 0.0, "0.0.3 station %s must retain its own collision" % station_name)

	var route_pairs := [
		[Vector2(2304.0, 96.0), Vector2(2304.0, 1728.0)],
		[Vector2(2304.0, 3360.0), Vector2(2304.0, 1728.0)],
		[Vector2(96.0, 1728.0), Vector2(2304.0, 1728.0)],
		[Vector2(4512.0, 1728.0), Vector2(2304.0, 1728.0)],
	]
	for pair in route_pairs:
		_expect(not navigation.find_path(pair[0], pair[1]).is_empty(), "Each cardinal kitchen entrance must retain a legal route to the clear core")

	var stamina_row := hud.find_child("StaminaRow", true, false) as HBoxContainer
	var stamina_bar := hud.find_child("StaminaBar", true, false) as ProgressBar
	_expect(stamina_row != null and stamina_bar != null and not stamina_row.visible, "Full stamina must keep the temporary HUD row hidden")
	player.consume_stamina(10.0)
	await process_frame
	_expect(stamina_row.visible and is_equal_approx(stamina_bar.value, 90.0), "Using stamina must reveal the HUD row with the live value")
	player.restore_stamina(999.0)
	await process_frame
	_expect(not stamina_row.visible, "The stamina HUD row must hide again after recovery reaches full")

	if failures.is_empty():
		print("PROTOTYPE_RESTAURANT_WHITEBOX_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_RESTAURANT_WHITEBOX_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
