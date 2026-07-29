extends SceneTree

class FrameCounter extends Node:
	var frames: int = 0

	func _process(_delta: float) -> void:
		frames += 1


var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_grid_and_atomic_instances()
	await _test_stack_compatibility_and_limits()
	await _test_pickup_route_and_reset()
	await _test_actual_cabinet_and_modal_input()
	await _test_three_steak_processing()
	await _test_physical_loot_loop()
	if failures.is_empty():
		print("PROTOTYPE_0_6A_REGRESSION_TEST: PASS (6/6 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_6A_REGRESSION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_grid_and_atomic_instances() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var grid := GridInventory.new(6, 6, holder)
	var chunk := _new_item(holder, ItemData.ItemType.RAW_BEEF_CHUNK)
	chunk.data.add_failure_tag(ItemData.FailureTag.UNMARINATED)
	_expect(grid.add_item_at(chunk, Vector2i.ZERO), "Grid: 3x3 chunk must fit at the origin")
	_expect(not grid.can_place_item(chunk, Vector2i(4, 4)), "Grid: out-of-bounds placement must be rejected")
	var steak := _new_item(holder, ItemData.ItemType.RAW_STEAK)
	_expect(not grid.add_item_at(steak, Vector2i(2, 0)), "Grid: overlap must be rejected")
	_expect(grid.get_placement(steak) == null and steak.get_parent() == holder, "Grid: failed placement must keep the real item instance untouched")
	_expect(grid.add_item_at(steak, Vector2i(3, 0), true), "Grid: rotating the confirmed 3x1 steak to 1x3 must permit a legal placement")
	var steak_id := steak.get_instance_id()
	_expect(grid.move_item(steak, Vector2i(3, 1), true), "Grid: an existing item must move atomically")
	_expect(grid.get_item_at(Vector2i(3, 2)) == steak and steak.get_instance_id() == steak_id, "Grid: moving must preserve the same actual item instance")
	_expect(chunk.data.has_failure_tag(ItemData.FailureTag.UNMARINATED), "Grid: stored processing/failure state must survive placement")
	var l_shape: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
	_expect(not grid.can_place_shape(l_shape, Vector2i(2, 2)), "Grid: arbitrary mask overlap must be evaluated per occupied cell")
	var rotated_l := ItemStorageCatalog.rotate_shape_cells(l_shape)
	_expect(ItemStorageCatalog.get_shape_bounds(rotated_l) == Vector2i(2, 2), "Grid: arbitrary shape masks must support 90-degree rotation")
	var rotate_holder := Node2D.new()
	root.add_child(rotate_holder)
	var rotate_grid := GridInventory.new(3, 1, rotate_holder)
	var oil := _new_item(rotate_holder, ItemData.ItemType.COOKING_OIL)
	_expect(rotate_grid.add_item_auto(oil) and rotate_grid.get_placement(oil).rotated, "Grid: auto placement must try the rotated orientation after the default direction fails")
	rotate_holder.queue_free()
	holder.queue_free()
	await process_frame


func _test_stack_compatibility_and_limits() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var grid := GridInventory.new(4, 4, holder)
	var salt := _new_item(holder, ItemData.ItemType.SALT)
	salt.data.stack_count = 2
	var more_salt := _new_item(holder, ItemData.ItemType.SALT)
	more_salt.data.stack_count = 2
	_expect(grid.add_item_auto(salt), "Stack: first compatible stack must be placeable")
	_expect(grid.add_item_auto(more_salt), "Stack: overflow must merge to the limit and place the remainder")
	var salt_total := 0
	for item in grid.get_items():
		if item.data.item_type == ItemData.ItemType.SALT:
			salt_total += item.data.stack_count
	_expect(salt_total == 4 and grid.get_items().size() == 2, "Stack: limit 3 must preserve the exact overflow remainder")
	var flawed_salt := _new_item(holder, ItemData.ItemType.SALT)
	flawed_salt.data.add_failure_tag(ItemData.FailureTag.BURNT)
	var previous_count := grid.get_items().size()
	_expect(grid.add_item_auto(flawed_salt), "Stack: incompatible state may occupy its own legal cell")
	_expect(grid.get_items().size() == previous_count + 1, "Stack: different quality/failure tags must never merge")
	var modified_salt := ItemCatalog.create(ItemData.ItemType.SALT)
	modified_salt.add_active_modifier(ItemData.ActiveModifier.MUSTARD)
	var quality_salt := ItemCatalog.create(ItemData.ItemType.SALT)
	quality_salt.quality = ItemData.Quality.BAD
	_expect(not salt.data.can_stack_with(modified_salt) and not salt.data.can_stack_with(quality_salt), "Stack: active seasoning modifiers and quality differences must block merging")
	var steak_a := _new_item(holder, ItemData.ItemType.RAW_STEAK)
	var steak_b := _new_item(holder, ItemData.ItemType.RAW_STEAK)
	_expect(not steak_a.data.can_stack_with(steak_b.data), "Stack: steaks must remain independent")
	var wok_a := _new_item(holder, ItemData.ItemType.WOK)
	var wok_b := _new_item(holder, ItemData.ItemType.WOK)
	var dish_a := _new_item(holder, ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	var dish_b := _new_item(holder, ItemData.ItemType.PLATED_STIR_FRY_BEEF)
	_expect(not wok_a.data.can_stack_with(wok_b.data) and not dish_a.data.can_stack_with(dish_b.data), "Stack: cookware and dishes must never stack")
	_expect(
		ItemCatalog.get_art_key(ItemData.ItemType.DIRTY_PLATE) == &"dirty_plate"
		and PrototypeArtCatalog.TEXTURES.get(&"dirty_plate") is Texture2D,
		"Art: dirty plates must use the dedicated dirty-plate texture"
	)
	_expect(
		ItemCatalog.get_art_key(ItemData.ItemType.TOMAHAWK_STEAK) == &"tomahawk_steak"
		and PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak") is Texture2D,
		"Art: unplated tomahawk steak must use the dedicated bone-in steak texture"
	)
	var tomahawk_image := (PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak") as Texture2D).get_image()
	var tomahawk_texture := PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak") as Texture2D
	var tomahawk_ui_region := PrototypeArtCatalog.get_ui_source_rect(&"tomahawk_steak", tomahawk_texture)
	_expect(
		tomahawk_image.get_pixel(0, 0).a == 0.0
		and tomahawk_image.get_pixel(floori(tomahawk_image.get_width() * 0.5), floori(tomahawk_image.get_height() * 0.5)).a > 0.99,
		"Art: tomahawk steak must have a transparent background while preserving the opaque steak subject"
	)
	_expect(
		tomahawk_ui_region == Rect2(Vector2.ZERO, tomahawk_texture.get_size())
		and tomahawk_texture.get_size() == Vector2(64.0, 96.0),
		"Art: the accepted 64x96 tomahawk must use its complete transparent game canvas"
	)
	var held_anchor := Node2D.new()
	holder.add_child(held_anchor)
	var held_tomahawk := _new_item(holder, ItemData.ItemType.TOMAHAWK_STEAK)
	held_tomahawk.set_held(held_anchor)
	held_tomahawk.update_held_pose(Vector2.RIGHT)
	_expect(
		held_tomahawk.placeholder.art_scale_multiplier >= 3.0
		and is_equal_approx(held_tomahawk.placeholder.art_rotation, PI * 0.5)
		and not held_tomahawk.placeholder.title_label.visible,
		"Art: held tomahawk must use the enlarged directional axe pose instead of the tiny generic carried-item pose"
	)
	held_tomahawk.set_inventory_stored(holder)
	_expect(
		is_equal_approx(held_tomahawk.placeholder.art_scale_multiplier, 1.0)
		and is_zero_approx(held_tomahawk.placeholder.art_rotation)
		and held_tomahawk.placeholder.title_label.visible,
		"Art: leaving the hand must restore the normal storage/world visual transform"
	)
	var marinade_texture := PrototypeArtCatalog.TEXTURES.get(&"marinade") as Texture2D
	var mustard_texture := PrototypeArtCatalog.TEXTURES.get(&"mustard") as Texture2D
	_expect(
		marinade_texture.resource_path.ends_with("ingredient_marinade_seasoning.png"),
		"Art: marinade must use the authoritative V3 marinade asset, not a reversed cache"
	)
	_expect(
		mustard_texture.resource_path.ends_with("ingredient_mustard_sauce.png")
		and mustard_texture.resource_path != marinade_texture.resource_path,
		"Art: mustard must use the distinct authoritative V3 mustard asset, not a reversed cache"
	)
	var animation_keys: Array[StringName] = [
		&"player_walk_sheet",
		&"basic_taste_enemy_walk_sheet",
		&"heavy_taste_enemy_walk_sheet",
		&"fast_taste_enemy_walk_sheet",
	]
	_expect(
		animation_keys.all(func(key: StringName): return PrototypeArtCatalog.TEXTURES.get(key) is Texture2D),
		"Animation art: all four 4x3 character sheets must be stored in the centralized art catalog"
	)
	var direction_sprite := Sprite2D.new()
	holder.add_child(direction_sprite)
	var direction_animator := DirectionalWalkAnimator.new()
	holder.add_child(direction_animator)
	direction_animator.configure(
		direction_sprite,
		PrototypeArtCatalog.TEXTURES.get(&"player_walk_sheet") as Texture2D,
		Vector2(64.0, 64.0),
		10.0,
		false,
		false,
		false
	)
	direction_animator.update_animation(0.12, Vector2.RIGHT)
	var right_frame := direction_sprite.frame
	_expect(direction_sprite.flip_h and right_frame > 0, "Animation: a source-left character moving right must flip and advance its walk frames")
	direction_animator.update_animation(0.12, Vector2.DOWN)
	_expect(direction_sprite.flip_h, "Animation: pure vertical movement must preserve the most recent horizontal facing")
	direction_animator.update_animation(0.12, Vector2.LEFT)
	_expect(not direction_sprite.flip_h, "Animation: moving left must restore the source-left orientation")
	direction_animator.update_animation(0.12, Vector2.ZERO)
	_expect(direction_sprite.frame == 0, "Animation: an idle character must return to the first frame")
	holder.queue_free()
	await process_frame


func _test_pickup_route_and_reset() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	for index in QuickInventory.SLOT_COUNT:
		var steak := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
		scene.add_child(steak)
		_expect(player.pickup_item(steak), "Pickup: first five items must enter the quick bar")
	var loot := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	scene.add_child(loot)
	loot.release_to_world(scene, player.global_position)
	loot.mark_as_loot_drop()
	_expect(player.pickup_item(loot) and player.backpack.get_placement(loot) != null, "Pickup: a full quick bar must route the same real item into the backpack")
	for y in player.backpack.height:
		for x in player.backpack.width:
			if player.backpack.get_item_at(Vector2i(x, y)) != null:
				continue
			var filler := _new_item(scene, ItemData.ItemType.MUSHY_BOILED_BEEF)
			_expect(player.backpack.add_item_at(filler, Vector2i(x, y)), "Pickup: every remaining backpack cell must accept a 1x1 filler")
	var blocked := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.SALT))
	scene.add_child(blocked)
	blocked.release_to_world(scene, player.global_position + Vector2(20.0, 0.0))
	_expect(not player.pickup_item(blocked), "Pickup: full quick bar and full backpack must reject pickup")
	_expect(blocked.get_parent() == scene and blocked.pickup_enabled and blocked.data.stack_count == 1, "Pickup: rejection must leave the world item intact and pickable")
	player.reset_for_new_game(100.0, 0.22)
	await process_frame
	_expect(player.inventory.slots.all(func(item): return item == null) and player.backpack.get_items().is_empty(), "Pickup: formal reset must clear quick bar and backpack")
	await _dispose_scene(scene)


func _test_actual_cabinet_and_modal_input() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var ui := scene.get_node("IngredientCabinetUI") as IngredientCabinetUI
	var overlay := scene.get_node("PrototypeToolsOverlay") as PrototypeToolsOverlay
	var action_rect := Rect2(StartGameUI.ACTION_PANEL_POSITION, StartGameUI.ACTION_PANEL_SIZE)
	_expect(
		not action_rect.intersects(Rect2(20.0, 18.0, 340.0, 136.0))
		and not action_rect.intersects(Rect2(952.0, 0.0, 328.0, 720.0))
		and not action_rect.intersects(Rect2(100.0, 540.0, 752.0, 116.0)),
		"Start UI: the service button must avoid the health/danger HUD, developer panel, and quick bar"
	)
	_expect(cabinet.storage != null and cabinet.storage.get_items().all(func(item): return item is CarryableItem), "Cabinet: initial stock must be actual item instances")
	var lobby_types := IngredientCabinet.get_all_item_types()
	_expect(
		cabinet.lobby_unlimited
		and cabinet.storage.width == 20
		and cabinet.storage.height == 40
		and cabinet.storage.width * cabinet.storage.height == 800
		and lobby_types.size() == cabinet.get_all_item_types().size()
		and cabinet.storage.get_items().size() == lobby_types.size()
		and lobby_types.all(func(item_type: int): return cabinet._find_item(item_type) != null),
		"Cabinet: the free test lobby must expose one real representative of every current item type"
	)
	_expect(
		cabinet._find_item(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF).data.current_durability > 0
		and cabinet._find_item(ItemData.ItemType.PLATED_TOMAHAWK_STEAK).data.current_durability > 0,
		"Cabinet: lobby finished dishes must be immediately usable test samples with initialized combat durability"
	)
	player.walk_animator.update_animation(Vector2.RIGHT, Vector2.RIGHT, false, false)
	_expect(player.walk_animator.sprite.animation == &"run_east" and not player.walk_animator.sprite.flip_h, "Animation: the player must use the native east running frames")
	player.walk_animator.update_animation(Vector2.UP, Vector2.UP, false, false)
	_expect(player.walk_animator.sprite.animation == &"run_north" and not player.walk_animator.sprite.flip_h, "Animation: moving north must use its native frames")
	player.walk_animator.update_animation(Vector2.LEFT, Vector2.LEFT, false, false)
	_expect(player.walk_animator.sprite.animation == &"run_west" and not player.walk_animator.sprite.flip_h, "Animation: moving west must use its native frames without mirroring")
	_expect(player.get_node_or_null("DirectionMarker") == null, "Animation: the player must not keep a graybox direction arrow after directional walk art is available")
	var initial_chunk := cabinet._find_item(ItemData.ItemType.RAW_BEEF_CHUNK)
	var initial_id := initial_chunk.get_instance_id()
	var old := cabinet.storage.get_placement(initial_chunk)
	player.global_position = cabinet.global_position
	ui.open_cabinet(cabinet, player)
	_expect(
		ui.cabinet_scroll.visible
		and ui.cabinet_view.cell_size == 32.0
		and ui.cabinet_view.custom_minimum_size == Vector2(640.0, 1280.0)
		and ui.cabinet_title_label.text == "20×40 测试目录（滚动查看·取走后自动补充）",
		"Cabinet UI: the 20x40 lobby catalog must use a scrollable 640x1280 grid and the exact test-tool title"
	)
	await process_frame
	ui.cabinet_scroll.scroll_vertical = 100000
	await process_frame
	_expect(ui.cabinet_scroll.scroll_vertical > 640, "Cabinet UI: vertical scrolling must reach the lower half containing rows 21-40")
	ui.cabinet_scroll.scroll_vertical = 0
	await process_frame
	var cabinet_tomahawk := cabinet._find_item(ItemData.ItemType.TOMAHAWK_STEAK)
	var cabinet_tomahawk_texture := PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak") as Texture2D
	_expect(
		ui.cabinet_view.get_item_art_source_rect(cabinet_tomahawk)
		== Rect2(Vector2.ZERO, cabinet_tomahawk_texture.get_size()),
		"Cabinet UI: the accepted tomahawk must use its complete 64x96 transparent texture"
	)
	var hover_event := InputEventMouseMotion.new()
	hover_event.position = (Vector2(old.origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	ui.cabinet_view._gui_input(hover_event)
	_expect(
		ui.item_detail_label.text.contains(initial_chunk.data.display_name)
		and ui.item_detail_label.text.contains("占格 3×3")
		and ui.cabinet_view.get_item_detail_text(initial_chunk).contains(initial_chunk.data.display_name),
		"Cabinet UI: hovering must show the complete item name and shape in a dedicated detail area instead of forcing long text into grid cells"
	)
	var chunk_press := ui.cabinet_view.global_position + (Vector2(old.origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_grid_mouse_press(ui.cabinet_view, chunk_press)
	_expect(ui.dragged_item == initial_chunk, "Cabinet: a real GUI mouse press must start dragging the selected cabinet item")
	_expect(ui.drag_preview.visible and ui.cabinet_view.hidden_drag_item == initial_chunk, "Cabinet: dragging must show a preview and hide the source-grid rendering")
	ui._position_drag_preview(Vector2(180.0, 160.0))
	var first_preview_position := ui.drag_preview.position
	ui._position_drag_preview(Vector2(360.0, 280.0))
	_expect(ui.drag_preview.position != first_preview_position, "Cabinet: the visible dragged item must follow mouse-position updates before release")
	_send_ui_mouse_release(ui, ui.quick_buttons[0].get_global_rect().get_center())
	_expect(player.inventory.get_item(0) != null and player.inventory.get_item(0).get_instance_id() == initial_id and not ui.drag_preview.visible, "Cabinet: transfer must preserve object identity and hide the preview after release")
	var quick_press := InputEventMouseButton.new()
	quick_press.button_index = MOUSE_BUTTON_LEFT
	quick_press.pressed = true
	ui._on_quick_gui_input(quick_press, 0)
	var cabinet_drop := ui.cabinet_view.global_position + (Vector2(old.origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_ui_mouse_release(ui, cabinet_drop)
	_expect(cabinet.storage.get_placement(initial_chunk) != null and initial_chunk.get_instance_id() == initial_id, "Cabinet: mouse drag back must preserve the same instance")
	var oil := cabinet._find_item(ItemData.ItemType.COOKING_OIL)
	var oil_placement := cabinet.storage.get_placement(oil)
	var oil_press := ui.cabinet_view.global_position + (Vector2(oil_placement.origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_grid_mouse_press(ui.cabinet_view, oil_press)
	var rotation_before := ui.drag_rotated
	var preview_size_before := ui.drag_preview.size
	var icon_rotation_before := ui.drag_preview_icon.is_rotated
	var hover_origin := Vector2i(6, 1)
	var hover_point := ui.cabinet_view.global_position + (Vector2(hover_origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	ui._update_drop_target_preview(hover_point)
	_expect(ui.cabinet_view.drop_preview_cells.size() == 2, "Cabinet: hovering a grid during drag must outline every occupied target cell")
	var hover_relative_before: Array[Vector2i] = []
	for cell in ui.cabinet_view.drop_preview_cells:
		hover_relative_before.append(cell - hover_origin)
	var hover_bounds_before := ItemStorageCatalog.get_shape_bounds(hover_relative_before)
	var rotate_event := InputEventAction.new()
	rotate_event.action = "rotate_inventory_item"
	rotate_event.pressed = true
	ui._input(rotate_event)
	ui._update_drop_target_preview(hover_point)
	var hover_relative_after: Array[Vector2i] = []
	for cell in ui.cabinet_view.drop_preview_cells:
		hover_relative_after.append(cell - hover_origin)
	var hover_bounds_after := ItemStorageCatalog.get_shape_bounds(hover_relative_after)
	_expect(ui.drag_rotated != rotation_before and ui.drag_preview.size == Vector2(preview_size_before.y, preview_size_before.x), "Cabinet: R during a real drag must rotate the pending placement and preview bounds immediately")
	_expect(ui.drag_preview_icon.is_rotated != icon_rotation_before, "Cabinet: R must visibly rotate the dragged item artwork, not only swap the preview frame size")
	_expect(hover_bounds_after == Vector2i(hover_bounds_before.y, hover_bounds_before.x), "Cabinet: R must immediately rotate the red target-cell outline")
	var oil_origin := cabinet.storage.get_placement(oil).origin
	var blocked_drop := ui.cabinet_view.global_position + (Vector2(cabinet.storage.get_placement(initial_chunk).origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_ui_mouse_release(ui, blocked_drop)
	_expect(cabinet.storage.get_placement(oil).origin == oil_origin, "Cabinet: failed mouse drop must return the item to its exact original placement")
	var retry_placement := cabinet.storage.get_placement(oil)
	var retry_press := ui.cabinet_view.global_position + (Vector2(retry_placement.origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_grid_mouse_press(ui.cabinet_view, retry_press)
	if not ui.drag_rotated:
		ui._input(rotate_event)
	var ignored_oil: Array[CarryableItem] = [oil]
	var rotated_target: Vector2i = cabinet.storage.find_first_position(oil, true, ignored_oil)
	_expect(rotated_target != Vector2i(-1, -1), "Cabinet: test cabinet must have a legal horizontal position for the oil bottle")
	var rotated_drop := ui.cabinet_view.global_position + (Vector2(rotated_target) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_ui_mouse_release(ui, rotated_drop)
	_expect(cabinet.storage.get_placement(oil).rotated and ui.cabinet_view.get_item_art_rotation_degrees(oil) == 90.0, "Cabinet: a successfully rotated placement must render the artwork sideways instead of stretching upright art into horizontal cells")
	var unlimited_source := cabinet._find_item(ItemData.ItemType.MUSTARD)
	var unlimited_placement := cabinet.storage.get_placement(unlimited_source)
	var unlimited_press := ui.cabinet_view.global_position + (Vector2(unlimited_placement.origin) + Vector2(0.5, 0.5)) * ui.cabinet_view.cell_size
	_send_grid_mouse_press(ui.cabinet_view, unlimited_press)
	_send_ui_mouse_release(ui, ui.quick_buttons[0].get_global_rect().get_center())
	await process_frame
	await process_frame
	var unlimited_replacement := cabinet._find_item(ItemData.ItemType.MUSTARD)
	_expect(
		player.inventory.get_item(0) == unlimited_source
		and unlimited_replacement != null
		and unlimited_replacement != unlimited_source
		and cabinet.get_stock(ItemData.ItemType.MUSTARD) == 1,
		"Cabinet: dragging a lobby item out must preserve the taken instance and replenish a new unlimited source copy"
	)
	ui.close_cabinet()
	var tab_probe := InputEventKey.new()
	tab_probe.keycode = KEY_TAB
	tab_probe.physical_keycode = KEY_TAB
	tab_probe.pressed = true
	_expect(InputMap.has_action("toggle_backpack") and InputMap.event_is_action(tab_probe, "toggle_backpack"), "Input: semantic toggle_backpack action must be bound to Tab")
	var counter := FrameCounter.new()
	scene.add_child(counter)
	await _press_key(KEY_TAB)
	_expect(ui.is_open() and not paused and player.modal_ui_open, "Input: Tab must open backpack without pausing the world and lock player actions")
	var frames_before := counter.frames
	await process_frame
	await process_frame
	_expect(counter.frames > frames_before, "Input: backpack must leave world processing, cooking and waves running")
	await _press_key(KEY_ESCAPE)
	_expect(not ui.is_open() and not paused and not player.modal_ui_open and overlay.mode == PrototypeToolsOverlay.Mode.NONE, "Input: ESC must close backpack before global pause")
	ui.open_cabinet(cabinet, player)
	await _press_key(KEY_ESCAPE)
	_expect(not ui.is_open() and not paused and overlay.mode == PrototypeToolsOverlay.Mode.NONE, "Input: ESC must also close cabinet before global pause")
	var trash_bin := scene.get_node("Kitchen/TrashBin") as TrashBin
	var discarded_item := player.held_item
	_expect(discarded_item == unlimited_source and trash_bin != null, "Trash: the actual scene bin and selected lobby test item must be available")
	trash_bin.begin_primary_interaction(player)
	await process_frame
	_expect(player.held_item == null and not is_instance_valid(discarded_item) and trash_bin.destroyed_item_count == 1, "Trash: using the bin must remove and destroy the entire selected item instance")
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.start_service_early()
	await process_frame
	_expect(
		not cabinet.lobby_unlimited
		and cabinet.storage.width == 10
		and cabinet.storage.height == 8
		and cabinet.get_supported_item_types().size() == 8
		and cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == manager.config.raw_beef_stock
		and cabinet.get_stock(ItemData.ItemType.TOMAHAWK_STEAK) == 0,
		"Cabinet: starting formal service must replace the unlimited lobby catalog with centralized finite run stock"
	)
	manager.return_to_lobby()
	await process_frame
	_expect(
		cabinet.lobby_unlimited
		and cabinet.storage.width == 20
		and cabinet.storage.height == 40
		and cabinet.storage.get_items().size() == lobby_types.size()
		and lobby_types.all(func(item_type: int): return cabinet._find_item(item_type) != null),
		"Cabinet: returning to the free lobby must restore the complete unlimited test catalog"
	)
	await _dispose_scene(scene)


func _test_three_steak_processing() -> void:
	var scene := await _spawn_main_scene()
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	board.stored_item = _store_item(scene, board, ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	_expect(board.begin_primary_interaction(player), "Cut: first-stage hold must begin")
	board.update_primary_interaction(player, board.prototype_first_cut_time + 0.01)
	_expect(board.stored_item == null and board.pending_outputs.size() == 3, "Cut: one chunk must produce exactly three pending steaks")
	var ids := {}
	for steak in board.pending_outputs:
		ids[steak.get_instance_id()] = true
		_expect(steak.data.item_type == ItemData.ItemType.RAW_STEAK and steak.data.stack_count == 1, "Cut: every output must be one independent raw steak")
	_expect(ids.size() == 3, "Cut: outputs must not duplicate an instance or compress into a stack")
	board.carry_interact(player)
	_expect(board.pending_outputs.size() == 2 and player.held_item != null, "Cut: one interaction must take exactly one steak")
	player.inventory.clear_all()
	for index in QuickInventory.SLOT_COUNT:
		var filler := _new_item(scene, ItemData.ItemType.RAW_STEAK)
		player.inventory.add_item_to_empty(filler)
	var backpack_steak := board.pending_outputs[0]
	board.carry_interact(player)
	_expect(board.pending_outputs.size() == 1 and player.backpack.get_placement(backpack_steak) != null, "Cut: when quick bar is full, one pending steak must route into backpack")
	for y in player.backpack.height:
		for x in player.backpack.width:
			if player.backpack.get_item_at(Vector2i(x, y)) == null:
				player.backpack.add_item_at(_new_item(scene, ItemData.ItemType.MUSHY_BOILED_BEEF), Vector2i(x, y))
	var blocked_output := board.pending_outputs[0]
	board.carry_interact(player)
	_expect(board.pending_outputs.size() == 1 and board.pending_outputs[0] == blocked_output and blocked_output.get_parent() == board, "Cut: if quick bar and backpack are full, the remaining steak must stay on the board")
	board.reset_for_new_game()
	var second_stage := _store_item(scene, board, ItemCatalog.create(ItemData.ItemType.RAW_STEAK))
	board.stored_item = second_stage
	board.begin_primary_interaction(player)
	board.update_primary_interaction(player, board.prototype_second_cut_time + 0.01)
	_expect(second_stage.data.item_type == ItemData.ItemType.RAW_BEEF_SLICES and second_stage.data.remaining_portions == 5, "Cut: each steak must independently become one five-portion slices pack")
	board.reset_for_new_game()
	board.stored_item = _store_item(scene, board, ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	board.begin_primary_interaction(player)
	board.cancel_primary_interaction(player)
	_expect(board.pending_outputs.is_empty() and board.stored_item != null, "Cut: interruption must reset progress without producing steaks")
	await _dispose_scene(scene)


func _test_physical_loot_loop() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var stats := scene.get_node("RunStats") as RunStats
	stats.begin_run()
	_expect(
		is_equal_approx(manager.config.basic_loot_chance, 0.30)
		and manager.config.basic_loot_oil_weight == 35.0
		and manager.config.basic_loot_whole_greens_weight == 20.0,
		"Loot: basic 30% chance and its oil/salt/whole-greens pool must remain centralized Prototype parameters"
	)
	var debug_dummy := scene.get_node("Kitchen/EnemyDummyA") as DebugCombatTarget
	_expect(not debug_dummy.is_in_group("basic_taste_enemy") and not debug_dummy.has_signal("reflavor_completed"), "Loot: lobby test dummies must have no formal enemy loot settlement route")
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	_expect(
		player.walk_animator != null
		and player.walk_animator.sprite is AnimatedSprite2D
		and player.walk_animator.sprite.sprite_frames.has_animation(&"idle_south")
		and player.walk_animator.sprite.sprite_frames.has_animation(&"walk_south")
		and player.walk_animator.sprite.sprite_frames.has_animation(&"run_south")
		and player.walk_animator.sprite.sprite_frames.has_animation(&"defeat_fall"),
		"Animation: the actual player node must expose native eight-direction idle, walk, run, and defeat animations"
	)
	var normal := manager.spawn_enemy_for_test(Vector2(900.0, 700.0))
	normal.set_physics_process(false)
	_expect(
		normal.character_animator != null
		and normal.walk_animator == null
		and normal.character_animator.sprite is AnimatedSprite2D
		and normal.character_animator.sprite.sprite_frames.has_animation(&"run_south"),
		"Animation: the actual normal enemy must use its native PixelLab character animation set"
	)
	var normal_loot := manager.settle_enemy_loot_for_test(normal)
	_expect(normal_loot != null and normal_loot.is_loot_drop and normal_loot.pickup_enabled, "Loot: normal enemy forced test settlement must create one physical pickable resource")
	_expect(manager.settle_enemy_loot_for_test(normal) == null, "Loot: the same normal enemy must settle at most once")
	var heavy := manager.spawn_heavy_enemy_for_test(Vector2(980.0, 700.0))
	heavy.set_physics_process(false)
	_expect(
		heavy.walk_animator != null
		and heavy.walk_animator.sprite.texture == PrototypeArtCatalog.TEXTURES.get(&"heavy_taste_enemy_walk_sheet"),
		"Animation: the actual heavy enemy must use its dedicated walk sheet"
	)
	var heavy_loot := manager.settle_enemy_loot_for_test(heavy)
	_expect(heavy_loot != null and heavy_loot.data.item_type == ItemData.ItemType.RAW_STEAK, "Loot: heavy enemy must guarantee one horizontal 3x1 raw steak")
	_expect(heavy_loot is Node2D and not heavy_loot.has_method("get_collision_layer"), "Loot: world drops must not block navigation or physical movement")
	var combat := scene.get_node("CombatRuntime") as CombatManager
	var aroma_trap := ShabuTrap.new()
	aroma_trap.setup(ItemCatalog.create(ItemData.ItemType.SHABU_BEEF), combat.config)
	scene.add_child(aroma_trap)
	await process_frame
	_expect(
		aroma_trap.aroma_indicator != null
		and aroma_trap.get_aroma_visual_radius() == combat.config.shabu_aroma_radius
		and aroma_trap.aroma_indicator.z_index < 0,
		"Shabu: the visible aroma indicator must use the exact centralized gameplay radius and render behind the trap"
	)
	normal.global_position = aroma_trap.global_position + Vector2(combat.config.shabu_aroma_radius - 1.0, 0.0)
	_expect(aroma_trap.is_available_for(normal), "Shabu: a target just inside the visible aroma boundary must be eligible")
	normal.global_position = aroma_trap.global_position + Vector2(combat.config.shabu_aroma_radius + 1.0, 0.0)
	_expect(not aroma_trap.is_available_for(normal), "Shabu: a target just outside the visible aroma boundary must not be eligible")
	var snapshot := stats.get_snapshot()
	_expect(snapshot["loot_spawned"] == 2, "Loot: generated-loot statistics must count each settled item once")
	player.global_position = normal_loot.global_position
	_expect(player.pickup_item(normal_loot), "Loot: player must personally pick up the physical resource")
	_expect(stats.get_snapshot()["loot_picked_up"] == 1, "Loot: pickup statistics must count a successful personal pickup")
	manager._reset_wave_counters_only()
	_expect(is_instance_valid(heavy_loot), "Loot: uncollected physical loot must persist across wave counters/intermission")
	manager.return_to_lobby()
	await process_frame
	_expect(not is_instance_valid(heavy_loot), "Loot: formal/lobby reset must clean uncollected world loot")
	await _dispose_scene(scene)


func _new_item(parent: Node, item_type: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(ItemCatalog.create(item_type))
	parent.add_child(item)
	return item


func _store_item(scene: Node, container: Node, data: ItemData) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_stored(container, Vector2.ZERO)
	return item


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if paused:
		paused = false
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _press_key(keycode: int) -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = keycode
	pressed.physical_keycode = keycode
	pressed.pressed = true
	root.push_input(pressed)
	await process_frame
	var released := pressed.duplicate() as InputEventKey
	released.pressed = false
	root.push_input(released)
	await process_frame


func _send_grid_mouse_press(view: InventoryGridView, global_mouse_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = global_mouse_position - view.global_position
	event.global_position = global_mouse_position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	view._gui_input(event)


func _send_ui_mouse_release(ui: IngredientCabinetUI, global_mouse_position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = global_mouse_position
	event.global_position = global_mouse_position
	event.button_mask = 0
	ui._input(event)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
