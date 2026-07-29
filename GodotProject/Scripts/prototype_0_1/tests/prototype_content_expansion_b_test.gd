extends SceneTree

class FeedbackStub:
	extends Node
	var messages: PackedStringArray = []

	func notify_feedback(message: String) -> void:
		messages.append(message)


var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_new_ingredient_catalog_and_shapes()
	await _test_beef_dicing_preserves_portion_and_marinade()
	await _test_mobile_greens_split_in_quick_and_backpack()
	await _test_formal_and_lobby_cabinet_entries()
	if failures.is_empty():
		print("PROTOTYPE_CONTENT_EXPANSION_B_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_CONTENT_EXPANSION_B_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_new_ingredient_catalog_and_shapes() -> void:
	var whole := ItemCatalog.create(ItemData.ItemType.WHOLE_GREENS)
	var leaf := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	var raw_dice := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_DICE)
	var marinated_dice := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)
	_expect(
		ItemStorageCatalog.get_default_size(whole.item_type) == Vector2i(2, 3)
		and ItemStorageCatalog.get_default_size(leaf.item_type) == Vector2i.ONE
		and leaf.max_stack_count == 5,
		"Milestone B ingredients: provisional whole-greens shape and five-leaf stack must be centralized"
	)
	_expect(
		raw_dice.beef_portion_count == 5
		and not raw_dice.is_marinated
		and marinated_dice.beef_portion_count == 5
		and marinated_dice.is_marinated,
		"Milestone B ingredients: dicing must preserve one steak's meat amount without multiplication"
	)


func _test_beef_dicing_preserves_portion_and_marinade() -> void:
	var feedback := FeedbackStub.new()
	root.add_child(feedback)
	var board := CuttingBoard.new()
	root.add_child(board)
	await process_frame
	var raw_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	board.add_child(raw_item)
	raw_item.set_stored(board, Vector2.ZERO)
	board.stored_item = raw_item
	_expect(board.begin_primary_interaction(feedback), "Milestone B dicing: a raw slice group must enter the existing hold interaction")
	board.update_primary_interaction(feedback, board.prototype_dice_cut_time + 0.01)
	_expect(
		board.stored_item.data.item_type == ItemData.ItemType.RAW_BEEF_DICE
		and board.stored_item.data.beef_portion_count == 5,
		"Milestone B dicing: one raw slice group must become exactly one raw dice group"
	)
	board.stored_item.queue_free()
	board.stored_item = null
	var marinated_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	board.add_child(marinated_item)
	marinated_item.set_stored(board, Vector2.ZERO)
	board.stored_item = marinated_item
	board.begin_primary_interaction(feedback)
	board.update_primary_interaction(feedback, board.prototype_dice_cut_time + 0.01)
	_expect(
		board.stored_item.data.item_type == ItemData.ItemType.MARINATED_BEEF_DICE
		and board.stored_item.data.is_marinated,
		"Milestone B dicing: cutting after marinating must retain the marinated state"
	)
	var marinade := MarinatingStation.new()
	root.add_child(marinade)
	await process_frame
	var raw_dice_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_DICE))
	var marinade_item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.MARINADE))
	marinade.add_child(raw_dice_item)
	marinade.add_child(marinade_item)
	marinade.meat_item = raw_dice_item
	marinade.marinade_item = marinade_item
	marinade.begin_primary_interaction(feedback)
	marinade.update_primary_interaction(feedback, marinade.prototype_marinating_time + 0.01)
	_expect(
		marinade.meat_item.data.item_type == ItemData.ItemType.MARINATED_BEEF_DICE
		and marinade.meat_item.data.beef_portion_count == 5,
		"Milestone B dicing: marinating after cutting must produce the same marinated dice state"
	)
	board.queue_free()
	marinade.queue_free()
	feedback.queue_free()
	await process_frame


func _test_mobile_greens_split_in_quick_and_backpack() -> void:
	var scene := await _spawn_main_scene()
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var controller := scene.get_node("PlatingController") as PlatingController
	player.inventory.clear_all()
	player.backpack.clear_all()
	var quick_whole := _put_quick_item(scene, player, ItemCatalog.create(ItemData.ItemType.WHOLE_GREENS), 0)
	_expect(controller.request_split_greens(quick_whole, false), "Milestone B greens: held whole greens must start the shared mobile QTE")
	_expect(
		player.action_qte_locked and not player.modal_ui_open,
		"Milestone B greens: split QTE must allow movement while locking normal actions"
	)
	controller.cancel_active_plating()
	_expect(
		quick_whole.data.item_type == ItemData.ItemType.WHOLE_GREENS,
		"Milestone B greens: cancel must not consume or partially split whole greens"
	)
	controller.request_split_greens(quick_whole, false)
	controller.complete_for_test(false)
	_expect(
		quick_whole.data.item_type == ItemData.ItemType.GREENS_LEAF
		and quick_whole.data.stack_count == 5
		and quick_whole.data.leaf_count == 5,
		"Milestone B greens: QTE result must always be exactly five leaves even outside the perfect zone"
	)
	var backpack_whole := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.WHOLE_GREENS))
	scene.add_child(backpack_whole)
	_expect(player.backpack.add_item_auto(backpack_whole), "Milestone B test setup: whole greens must fit the backpack")
	_expect(controller.request_split_greens(backpack_whole, true), "Milestone B greens: backpack item action must start on the same real instance")
	controller.complete_for_test(true)
	_expect(
		backpack_whole.data.item_type == ItemData.ItemType.GREENS_LEAF
		and backpack_whole.data.stack_count == 5
		and player.backpack.get_placement(backpack_whole) != null,
		"Milestone B greens: backpack split must preserve ownership and atomically shrink the same instance"
	)
	await _dispose_scene(scene)


func _test_formal_and_lobby_cabinet_entries() -> void:
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	await process_frame
	_expect(
		cabinet.get_stock(ItemData.ItemType.WHOLE_GREENS) == cabinet.whole_greens_stock,
		"Milestone B cabinet: a formal run must start with the centralized whole-greens stock"
	)
	cabinet.configure_lobby_unlimited_catalog()
	_expect(
		ItemData.ItemType.WHOLE_GREENS in cabinet.get_supported_item_types()
		and ItemData.ItemType.GREENS_LEAF in cabinet.get_supported_item_types()
		and ItemData.ItemType.RAW_BEEF_DICE in cabinet.get_supported_item_types()
		and ItemData.ItemType.MARINATED_BEEF_DICE in cabinet.get_supported_item_types(),
		"Milestone B cabinet: the 20x40 lobby catalog must expose every newly implemented ingredient state"
	)
	cabinet.queue_free()
	await process_frame


func _put_quick_item(scene: Node, player: PrototypePlayer, data: ItemData, slot_index: int) -> CarryableItem:
	var item := ItemFactory.create_carryable(data)
	scene.add_child(item)
	item.set_inventory_stored(player)
	_expect(player.inventory.put_item(slot_index, item), "Milestone B test setup: quick slot must be empty")
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
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
