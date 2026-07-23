extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_01_health_hud()
	await _test_02_waiting_and_manual_start_reset()
	await _test_03_five_slot_hotbar()
	await _test_04_strengthened_raging_bull()
	await _test_05_local_cooking_indicator()
	await _test_06_camera_and_canvas_ui()
	await _test_07_regression_contract()
	if failures.is_empty():
		print("PROTOTYPE_0_3_2_SMOKE_TEST: PASS (7/7 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_3_2_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_01_health_hud() -> void:
	var scene := await _spawn_main_scene(false)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	_expect(hud != null and hud.health_bar != null and hud.health_label != null, "01: fixed player health HUD must exist")
	var old_value := hud.health_bar.value
	player.set_modal_ui_open(false)
	player.receive_combat_hit(20.0, CombatRules.Faction.ENEMY, Vector2.RIGHT, 0.0, false)
	_expect(hud.health_bar.value == old_value - 20.0 and hud.health_label.text == "80 / 100", "01: HUD must immediately follow existing player health data")
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.phase = PrototypeWaveManager.Phase.FAILED
	manager.start_game()
	_expect(hud.health_bar.value == 100.0 and hud.health_label.text == "100 / 100", "01: restarting a failed run must restore full health in HUD")
	await _dispose_scene(scene)


func _test_02_waiting_and_manual_start_reset() -> void:
	var scene := await _spawn_main_scene(false)
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var pile := scene.get_node("Kitchen/CleanPlatePile") as CleanPlatePile
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var start_ui := scene.get_node("StartGameUI") as StartGameUI
	_expect(manager.phase == PrototypeWaveManager.Phase.FREE_PREPARATION, "02: scene must enter FREE_PREPARATION")
	manager.force_advance_phase_for_test(5.0)
	_expect(manager.spawned_total == 0, "02: free preparation must not advance spawning")
	_expect(not player.modal_ui_open and start_ui.root_control.visible, "02: edge Start Service UI must not lock world input")
	cabinet.request_take(ItemData.ItemType.RAW_BEEF_CHUNK, player)
	pile.available_plate_count = 0
	station.wok_item.add_oil()
	station.set_burner_on(true)
	_expect(manager.start_service_early(), "02: Start Service must begin formal preparation")
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and manager.preparation_left >= 30.0, "02: Start Service must reset lobby practice state before formal preparation")
	_expect(player.inventory.get_selected_item() == null and cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == manager.config.raw_beef_stock, "02: formal preparation must restore initial inventory and finite stock")
	_expect(pile.available_plate_count == manager.config.clean_plate_stock and not station.burner_on and not station.wok_item.has_oil(), "02: formal preparation must restore plate, burner and cookware state")
	_expect(not manager.early_started and is_zero_approx(manager.early_seconds), "02: initial free preparation must not record an early reward")
	await _dispose_scene(scene)


func _test_03_five_slot_hotbar() -> void:
	var scene := await _spawn_main_scene(true)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var hotbar := scene.get_node("QuickInventoryUI") as QuickInventoryUI
	_expect(QuickInventory.SLOT_COUNT == 5 and player.inventory.slots.size() == 5, "03: inventory data must contain five slots")
	_expect(hotbar.slot_panels.size() == 5 and hotbar.slot_labels.size() == 5, "03: hotbar UI must render five slots")
	var types := [ItemData.ItemType.RAW_BEEF_CHUNK, ItemData.ItemType.MARINADE, ItemData.ItemType.CHILI_SEGMENTS, ItemData.ItemType.COOKING_OIL, ItemData.ItemType.SALT]
	for item_type in types:
		player.receive_item_data(ItemCatalog.create(item_type))
	_expect(player.inventory.is_full(), "03: five non-stackable items must fill the Prototype hotbar")
	player.inventory.select(4)
	player.inventory.cycle(1)
	_expect(player.inventory.selected_index == 0, "03: wheel cycling must wrap from slot five to slot one")
	player.inventory.select(3)
	_expect(player.held_item == player.inventory.get_item(3), "03: selected slot must remain the complete held item instance")
	for index in range(1, 6):
		_expect(InputMap.has_action("select_hotbar_%d" % index), "03: numeric hotbar action %d must be registered" % index)
	var numeric_select := InputEventAction.new()
	numeric_select.action = "select_hotbar_5"
	numeric_select.pressed = true
	player._unhandled_input(numeric_select)
	_expect(player.inventory.selected_index == 4 and player.held_item == player.inventory.get_item(4), "03: numeric key action must directly select the matching complete item instance")
	var sixth := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.MUSTARD))
	scene.add_child(sixth)
	_expect(player.pickup_item(sixth) and player.backpack.get_placement(sixth) != null, "03: 0.6A must preserve the sixth real instance in backpack fallback")
	await _dispose_scene(scene)


func _test_04_strengthened_raging_bull() -> void:
	var scene := await _spawn_main_scene(true)
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var config := combat.config
	_expect(is_equal_approx(config.raging_bull_duration, 24.0), "04: raging bull duration must increase from 6 to 24 seconds")
	_expect(is_equal_approx(config.raging_bull_speed, 800.0), "04: raging bull speed must increase from 320 to 800")
	_expect(is_equal_approx(config.raging_bull_radius, 65.0) and config.raging_bull_visual_size == Vector2(198.0, 135.0), "04: raging bull hit size and visual must grow proportionally")
	var bounds := config.combat_bounds
	var bull := combat.spawn_raging_bull(Vector2(bounds.end.x - config.raging_bull_radius - 2.0, bounds.get_center().y), Vector2.RIGHT)
	await process_frame
	bull._physics_process(0.2)
	_expect(bull.reflection_count >= 1 and bull.direction.x < 0.0, "04: high-speed bull must still reflect from the boundary")
	_expect(bounds.grow(-config.raging_bull_radius).has_point(bull.global_position), "04: high-speed bull must remain inside the safe combat bounds")
	_expect(bull.visual.visual_size == config.raging_bull_visual_size and bull.lifetime_left > 20.0, "04: runtime visual and extended lifetime must use centralized values")
	await _dispose_scene(scene)


func _test_05_local_cooking_indicator() -> void:
	var scene := await _spawn_main_scene(true)
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	station.set_process(false)
	_expect(scene.get_node_or_null("CookingStatusUI") == null, "05: screen-fixed ordinary cooking prompt layer must be removed")
	_expect(station.circular_indicator != null and station.circular_indicator.state_key == "burner_off", "05: wok must own a local world-space circular indicator")
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(1.0)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "stage_one" and station.circular_indicator.timed, "05: stage one must show local timed ring progress")
	station.advance_automatic_cooking(station.config.automatic_stage_one_time)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "waiting_chili" and not station.circular_indicator.timed, "05: waiting for chili must use a distinct static ring state")
	station.wok_item.add_chili()
	station.advance_automatic_cooking(0.1)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "stage_two", "05: stage two must use a distinct local state")
	station.advance_automatic_cooking(station.config.automatic_stage_two_time)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "dish_ready", "05: completed dish must be locally distinguishable")
	station.advance_automatic_cooking(station.config.automatic_burn_time * station.config.burn_warning_ratio + 0.01)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "burn_warning", "05: approaching burn must flash locally")
	station.advance_automatic_cooking(station.config.automatic_burn_time)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "burnt_to_charcoal", "05: burnt state must show charcoal countdown")
	station.advance_automatic_cooking(station.config.automatic_charcoal_time + 0.01)
	station._refresh_status()
	_expect(station.circular_indicator.state_key == "charcoal", "05: charcoal must have a static local state")
	await _dispose_scene(scene)


func _test_06_camera_and_canvas_ui() -> void:
	var scene := await _spawn_main_scene(true)
	var camera := scene.get_node("Kitchen/Player/Camera2D") as Camera2D
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	_expect(camera.zoom == Vector2(0.75, 0.75) and camera.zoom == manager.config.camera_zoom, "06: runtime camera must zoom from 1.0 to centralized 0.75")
	_expect(camera.limit_left == roundi(manager.config.map_bounds.position.x) and camera.limit_right == roundi(manager.config.map_bounds.end.x), "06: expanded view must retain map-edge camera limits")
	_expect(scene.get_node("PlayerHUD") is CanvasLayer and scene.get_node("QuickInventoryUI") is CanvasLayer and scene.get_node("StartGameUI") is CanvasLayer, "06: HUD, hotbar and start overlay must remain screen-space CanvasLayers")
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	var warning := scene.get_node("WaveWarningUI") as WaveWarningUI
	_expect(hud.panel.position.x + hud.panel.size.x <= warning.edge_label.position.x, "06: top-left health HUD must not overlap the wave edge warning")
	await _dispose_scene(scene)


func _test_07_regression_contract() -> void:
	var scene := await _spawn_main_scene(true)
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	var station := scene.get_node("Kitchen/WokStation") as WokStation
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	_expect(cabinet.lobby_unlimited and cabinet.get_supported_item_types().size() == ItemData.ItemType.size(), "07: free lobby must expose the unlimited all-item test catalog")
	manager.start_service_early()
	await process_frame
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION, "07: preparation Start Service and wave flow must remain intact")
	_expect(cabinet.get_supported_item_types().size() == 6 and cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == manager.config.raw_beef_stock, "07: finite unified cabinet must remain intact")
	station.wok_item.add_oil()
	station.wok_item.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	station.set_burner_on(true)
	station.advance_automatic_cooking(station.config.automatic_stage_one_time + 0.01)
	station.wok_item.add_chili()
	station.advance_automatic_cooking(station.config.automatic_stage_two_time + 0.01)
	_expect(station.wok_item.cook_stage == WokItem.CookStage.STAGE_TWO_DONE and station.wok_item.content_data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, "07: existing automatic recipe route must remain complete")
	_expect(scene.get_node_or_null("PlatingController") != null and scene.get_node_or_null("CombatRuntime") != null and scene.get_node_or_null("Kitchen/Sink") != null, "07: plating, combat and plate/wok cleaning systems must remain connected")
	await _dispose_scene(scene)


func _spawn_main_scene(start_game: bool) -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "Unable to load Prototype 0.3.2 main scene")
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	if start_game:
		(scene.get_node("WaveManager") as PrototypeWaveManager).start_game()
		await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
