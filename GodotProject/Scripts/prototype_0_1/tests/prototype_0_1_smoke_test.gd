extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cutting_and_interruption()
	_test_correct_recipe()
	_test_unmarinated_recipe()
	_test_early_chili_recipe()
	_test_two_failure_tags()
	_test_overcook_route()
	_test_no_oil_and_washing()
	await _test_main_scene_loads()
	await _test_quick_inventory_and_full_pickup()
	await _test_station_inventory_safety()
	await _test_unified_cabinet_and_modal_input()
	await _test_wok_instance_survives_slot_switching()
	await _test_integrated_correct_flow()
	await _test_integrated_accident_flow()
	await _test_integrated_interruption_rules()
	if failures.is_empty():
		print("PROTOTYPE_0_1_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_0_1_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_cutting_and_interruption() -> void:
	var beef := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK)
	var tracker := HoldProgress.new()
	tracker.begin(1.0)
	tracker.advance(0.4)
	tracker.cancel()
	_expect(tracker.get_ratio() == 0.0, "切割中断后进度应归零")
	_expect(beef.item_type == ItemData.ItemType.RAW_BEEF_CHUNK, "未完成切割时物品状态不应改变")
	beef = ItemCatalog.transform(beef, ItemData.ItemType.RAW_STEAK)
	_expect(beef.item_type == ItemData.ItemType.RAW_STEAK, "第一次切割应得到生牛排")
	beef = ItemCatalog.transform(beef, ItemData.ItemType.RAW_BEEF_SLICES)
	_expect(beef.item_type == ItemData.ItemType.RAW_BEEF_SLICES, "第二次切割应得到生牛肉片")


func _test_correct_recipe() -> void:
	var wok := _new_wok()
	var meat := ItemCatalog.transform(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES), ItemData.ItemType.MARINATED_BEEF_SLICES)
	_expect(wok.add_oil(), "正确路线应能提前加油")
	_expect(wok.insert_meat(meat), "正确路线应能放入腌牛肉片")
	wok.complete_stage_one()
	_expect(wok.add_chili(), "第一阶段后应能加入辣椒段")
	wok.complete_stage_two()
	_expect(wok.content_data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, "正确路线应产出待摆盘小炒黄牛肉")
	_expect(wok.content_data.failure_tags.is_empty(), "正确路线不应带失败标签")
	_expect(wok.content_data.quality == ItemData.Quality.NORMAL, "正确路线品质应为正常")
	_expect(not wok.has_oil(), "Prototype 临时规则：完成一次料理后油应耗尽")
	wok.free()


func _test_unmarinated_recipe() -> void:
	var wok := _new_wok()
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	wok.complete_stage_one()
	wok.add_chili()
	wok.complete_stage_two()
	_expect(wok.content_data.has_failure_tag(ItemData.FailureTag.UNMARINATED), "未腌制路线应保留临时失败标签")
	_expect(wok.content_data.quality == ItemData.Quality.FLAWED, "一个失败标签的品质应为瑕疵")
	wok.free()


func _test_early_chili_recipe() -> void:
	var wok := _new_wok()
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.add_chili()
	wok.complete_stage_one()
	wok.complete_stage_two()
	_expect(wok.content_data.has_failure_tag(ItemData.FailureTag.CHILI_TOO_EARLY), "辣椒过早应保留临时失败标签")
	_expect(wok.content_data.quality == ItemData.Quality.FLAWED, "辣椒过早单标签品质应为瑕疵")
	wok.free()


func _test_two_failure_tags() -> void:
	var wok := _new_wok()
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	wok.add_chili()
	wok.complete_stage_one()
	wok.complete_stage_two()
	_expect(wok.content_data.failure_tags.size() == 2, "未腌制且辣椒过早应有两个失败标签")
	_expect(wok.content_data.quality == ItemData.Quality.BAD, "两个失败标签的品质应为糟糕")
	wok.free()


func _test_overcook_route() -> void:
	var wok := _new_wok()
	wok.add_oil()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok.complete_stage_one()
	wok.add_chili()
	wok.complete_stage_two()
	wok.mark_burnt()
	_expect(wok.content_data.has_failure_tag(ItemData.FailureTag.BURNT), "过度加热应添加正式【焦糊】标签")
	_expect(wok.content_data.quality == ItemData.Quality.FLAWED, "焦糊单标签品质应为瑕疵")
	wok.turn_content_to_charcoal()
	_expect(wok.content_data.item_type == ItemData.ItemType.CHARCOAL, "继续长时间加热应变为焦炭")
	wok.free()


func _test_no_oil_and_washing() -> void:
	var wok := _new_wok()
	wok.insert_meat(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	var charcoal := wok.trigger_no_oil_accident()
	_expect(charcoal.item_type == ItemData.ItemType.CHARCOAL, "未加油事故应产生焦炭")
	_expect(wok.is_stuck(), "未加油事故应使炒锅进入粘锅状态")
	_expect(wok.content_data == null, "事故后的焦炭应能作为独立物品取出")
	wok.clean_after_washing()
	_expect(not wok.is_stuck(), "清洗完成后炒锅应恢复正常")
	_expect(wok.origin_station_id == &"smoke_test_wok", "炒锅应保留原工位标识")
	wok.free()


func _test_main_scene_loads() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact_primary", "interact_carry", "interact_cookware", "drop_item", "debug_reset"]:
		_expect(InputMap.has_action(action), "项目应注册输入动作：%s" % action)
		_expect(not InputMap.action_get_events(action).is_empty(), "输入动作应配置按键：%s" % action)
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	_expect(packed != null, "主测试场景应可加载")
	if packed == null:
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	_expect(scene.get_node_or_null("Kitchen/Player") != null, "主场景应包含玩家")
	_expect(scene.get_node_or_null("Kitchen/CuttingBoard") != null, "主场景应包含切菜板")
	_expect(scene.get_node_or_null("Kitchen/MarinatingStation") != null, "主场景应包含腌制区域")
	_expect(scene.get_node_or_null("Kitchen/WokStation") != null, "主场景应包含炒锅工位")
	_expect(scene.get_node_or_null("Kitchen/Sink") != null, "主场景应包含水池")
	_expect(scene.get_node_or_null("Kitchen/IngredientCabinet") != null, "主场景应包含一个统一食材柜")
	_expect(scene.get_node_or_null("Kitchen/BeefDispenser") == null, "旧独立牛肉柜不应继续存在")
	_expect(scene.get_node_or_null("QuickInventoryUI") != null, "主场景应包含五格快捷栏 UI")
	_expect(scene.get_node_or_null("IngredientCabinetUI") != null, "主场景应包含统一食材柜 UI")
	scene.queue_free()
	await process_frame


func _test_quick_inventory_and_full_pickup() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	_expect(player.inventory.slots.size() == 5, "快捷栏应固定包含五个格子")
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINADE))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.SALT))
	_expect(player.inventory.get_item(0).data.item_type == ItemData.ItemType.RAW_BEEF_CHUNK, "第一件物品应优先进入当前格")
	_expect(player.inventory.get_item(1).data.item_type == ItemData.ItemType.MARINADE, "当前格占用后应使用第一个空格")
	_expect(player.inventory.get_item(2).data.item_type == ItemData.ItemType.COOKING_OIL, "第三件物品应进入最后空格")

	var wheel_down := InputEventMouseButton.new()
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_down.pressed = true
	player._unhandled_input(wheel_down)
	_expect(player.inventory.selected_index == 1, "滚轮向下应只切换到下一格")
	var wheel_up := InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	player._unhandled_input(wheel_up)
	_expect(player.inventory.selected_index == 0, "滚轮向上应切换到上一格")
	player._unhandled_input(wheel_up)
	_expect(player.inventory.selected_index == 4, "从第一格向上应循环到第五格")
	_expect(player.held_item == player.inventory.get_item(4), "手持对象应始终是当前选中格的实例")

	var extra := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS))
	scene.add_child(extra)
	extra.global_position = player.global_position + Vector2(40.0, 0.0)
	var original_parent := extra.get_parent()
	_expect(player.pickup_item(extra), "0.6A：五格全满时第六件物品应进入背包")
	_expect(extra.is_queued_for_deletion() and player.inventory.get_item(3).data.stack_count == 2, "0.6A：拾取应优先合并快捷栏中的兼容堆")
	_expect(player.get_visible_feedback().contains("快捷栏"), "0.6A：优先合并应显示明确的快捷栏提示")
	var slot_zero_item := player.inventory.get_item(0)
	var slot_one_item := player.inventory.get_item(1)
	player.drop_held_item()
	_expect(player.inventory.get_item(4) == null, "丢弃只应清空当前选中格")
	_expect(player.inventory.get_item(0) == slot_zero_item and player.inventory.get_item(1) == slot_one_item, "丢弃当前格不能影响其他格子")
	await _dispose_scene(scene)


func _test_station_inventory_safety() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	var beef_instance := player.held_item
	board.carry_interact(player)
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINADE))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.SALT))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MUSTARD))
	_expect(player.inventory.is_full(), "工位满栏测试前快捷栏应为满")
	board.carry_interact(player)
	_expect(board.stored_item == null, "0.6A：快捷栏满时应通过背包取回工位物品")
	_expect(player.backpack.get_placement(beef_instance) != null, "0.6A：工位取回必须保留同一个加工物品实例")
	await _dispose_scene(scene)


func _test_unified_cabinet_and_modal_input() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.start_service_early()
	await process_frame
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var cabinet_ui := scene.get_node("IngredientCabinetUI") as IngredientCabinetUI
	_expect(manager.phase == PrototypeWaveManager.Phase.PREPARATION and not cabinet.lobby_unlimited, "开始营业后应切换到正式有限库存柜")
	_expect(cabinet.get_supported_item_types().size() == 6, "正式食材柜应包含牛肉、腌肉料、辣椒、油、盐和芥末六种当前流程物品")
	var initial_beef := cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK)
	cabinet.begin_primary_interaction(player)
	_expect(cabinet_ui.is_open() and player.modal_ui_open, "按交互打开柜子后应显示 UI 并锁定玩家输入")
	_expect(not paused, "柜子打开时世界不应暂停")
	var same_frame_interact := InputEventAction.new()
	same_frame_interact.action = "interact_primary"
	same_frame_interact.pressed = true
	cabinet_ui._unhandled_input(same_frame_interact)
	_expect(cabinet_ui.is_open(), "打开柜子的同一帧交互事件不能立刻关闭界面")
	var selected_before_wheel := player.inventory.selected_index
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	player._unhandled_input(wheel)
	_expect(player.inventory.selected_index == selected_before_wheel, "柜子打开时滚轮不能切换快捷栏")
	var beef_button := cabinet_ui.find_child("TakeItem%d" % ItemData.ItemType.RAW_BEEF_CHUNK, true, false) as Button
	_expect(beef_button != null, "柜子 UI 应为整块生牛肉提供取出按钮")
	if beef_button != null:
		beef_button.pressed.emit()
	_expect(cabinet.get_stock(ItemData.ItemType.RAW_BEEF_CHUNK) == initial_beef - 1, "成功取出后对应库存应减少一")
	var close_button := cabinet_ui.find_child("CloseButton", true, false) as Button
	_expect(close_button != null, "柜子 UI 应包含关闭按钮")
	if close_button != null:
		close_button.pressed.emit()
	_expect(not cabinet_ui.is_open() and not player.modal_ui_open, "关闭柜子后应恢复玩家输入")
	player.global_position = cabinet.global_position
	cabinet.begin_primary_interaction(player)
	player.global_position += Vector2(player.prototype_interaction_distance + 10.0, 0.0)
	cabinet_ui._process(0.0)
	_expect(not cabinet_ui.is_open() and not player.modal_ui_open, "玩家离柜过远时界面应安全关闭并恢复输入")
	player.global_position = cabinet.global_position
	cabinet.begin_primary_interaction(player)
	cabinet_ui.opened_frame = -1
	var escape_event := InputEventAction.new()
	escape_event.action = "ui_cancel"
	escape_event.pressed = true
	cabinet_ui._unhandled_input(escape_event)
	_expect(not cabinet_ui.is_open() and not player.modal_ui_open, "Esc 应关闭柜子并恢复输入")

	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINADE))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.SALT))
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MUSTARD))
	var oil_before := cabinet.get_stock(ItemData.ItemType.COOKING_OIL)
	_expect(player.inventory.is_full(), "柜子满栏测试前快捷栏应为满")
	_expect(cabinet.request_take(ItemData.ItemType.COOKING_OIL, player), "0.6A：快捷栏满时柜子取料应进入背包")
	_expect(cabinet.get_stock(ItemData.ItemType.COOKING_OIL) == oil_before - 1, "0.6A：背包后备取料成功后实际库存应减少")
	await _dispose_scene(scene)


func _test_wok_instance_survives_slot_switching() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var wok_station := scene.get_node("Kitchen/WokStation") as WokStation
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	wok_station.wok_item.add_oil()
	var carried_content := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)
	wok_station.wok_item.insert_meat(carried_content)
	var original_wok := wok_station.wok_item
	wok_station.secondary_interact(player)
	_expect(player.held_item == original_wok and original_wok.has_oil(), "已加油炒锅应作为同一实例进入当前格")
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINADE))
	player.inventory.select(1)
	_expect(player.held_item.data.item_type == ItemData.ItemType.MARINADE, "切到其他格时应显示该格物品")
	player.inventory.select(0)
	_expect(player.held_item == original_wok and original_wok.has_oil(), "切回后炒锅实例和已加油状态必须保留")
	_expect(original_wok.content_data == carried_content, "炒锅内物品数据跨格切换后必须保留")
	wok_station.secondary_interact(player)
	_expect(wok_station.wok_item == original_wok, "放回工位的必须是原炒锅实例")
	original_wok.take_content()
	original_wok.trigger_no_oil_accident()
	wok_station.secondary_interact(player)
	player.inventory.select(1)
	player.inventory.select(0)
	_expect(player.held_item == original_wok and original_wok.is_stuck(), "粘锅跨格切换后状态必须保留")
	sink.begin_primary_interaction(player)
	sink.update_primary_interaction(player, sink.prototype_stuck_wok_wash_time + 0.1)
	_expect(player.held_item == original_wok and not original_wok.is_stuck(), "清洗后同一炒锅应留在当前使用格")
	wok_station.secondary_interact(player)
	_expect(wok_station.wok_item == original_wok and player.inventory.get_item(0) == null, "放回炒锅后对应格应清空")
	await _dispose_scene(scene)


func _test_integrated_correct_flow() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var cabinet := scene.get_node("Kitchen/IngredientCabinet") as IngredientCabinet
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	var marinating := scene.get_node("Kitchen/MarinatingStation") as MarinatingStation
	var wok_station := scene.get_node("Kitchen/WokStation") as WokStation

	cabinet.request_take(ItemData.ItemType.RAW_BEEF_CHUNK, player)
	cabinet.request_take(ItemData.ItemType.MARINADE, player)
	cabinet.request_take(ItemData.ItemType.COOKING_OIL, player)
	player.inventory.select(0)
	board.carry_interact(player)
	board.begin_primary_interaction(player)
	board.update_primary_interaction(player, board.prototype_first_cut_time + 0.1)
	board.carry_interact(player)
	board.carry_interact(player)
	board.carry_interact(player)
	player.inventory.select(0)
	board.carry_interact(player)
	board.begin_primary_interaction(player)
	board.update_primary_interaction(player, board.prototype_second_cut_time + 0.1)
	board.carry_interact(player)
	_expect(player.held_item.data.item_type == ItemData.ItemType.RAW_BEEF_SLICES, "集成正确流程：两次切割应得到生牛肉片")

	marinating.carry_interact(player)
	player.inventory.select(1)
	marinating.carry_interact(player)
	marinating.begin_primary_interaction(player)
	marinating.update_primary_interaction(player, marinating.prototype_marinating_time + 0.1)
	marinating.carry_interact(player)
	_expect(player.held_item.data.item_type == ItemData.ItemType.MARINATED_BEEF_SLICES, "集成正确流程：腌制应得到腌牛肉片")

	player.inventory.select(2)
	wok_station.carry_interact(player)
	player.inventory.select(1)
	wok_station.carry_interact(player)
	wok_station.set_burner_on(true, player)
	wok_station.advance_automatic_cooking(wok_station.config.automatic_stage_one_time + 0.1, player)
	cabinet.request_take(ItemData.ItemType.CHILI_SEGMENTS, player)
	wok_station.carry_interact(player)
	wok_station.advance_automatic_cooking(wok_station.config.automatic_stage_two_time + 0.1, player)
	wok_station.carry_interact(player)
	var cooked_dish := player.held_item
	if cooked_dish == null or cooked_dish.data.item_type != ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
		var dish_slot := player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
		cooked_dish = player.inventory.get_item(dish_slot) if dish_slot >= 0 else null
	_expect(cooked_dish != null and cooked_dish.data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, "集成正确流程：应取出待摆盘小炒黄牛肉")
	_expect(cooked_dish != null and cooked_dish.data.failure_tags.is_empty(), "集成正确流程：成品不应有失败标签")
	_expect(cooked_dish != null and cooked_dish.data.quality == ItemData.Quality.NORMAL, "集成正确流程：成品品质应为正常")
	await _dispose_scene(scene)


func _test_integrated_accident_flow() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var wok_station := scene.get_node("Kitchen/WokStation") as WokStation
	var sink := scene.get_node("Kitchen/Sink") as SinkStation
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	wok_station.carry_interact(player)
	wok_station.begin_primary_interaction(player)
	_expect(wok_station.wok_item.is_stuck(), "集成事故流程：未加油开始加热后炒锅应粘锅")
	var found_charcoal := false
	for candidate in get_nodes_in_group("interactable"):
		if candidate is CarryableItem and (candidate as CarryableItem).data.item_type == ItemData.ItemType.CHARCOAL:
			found_charcoal = true
			break
	_expect(found_charcoal, "集成事故流程：事故焦炭应作为可拿取物品出现")
	wok_station.secondary_interact(player)
	_expect(player.held_item is WokItem, "集成事故流程：玩家应能拿起粘锅")
	sink.begin_primary_interaction(player)
	sink.update_primary_interaction(player, sink.prototype_stuck_wok_wash_time + 0.1)
	_expect(not (player.held_item as WokItem).is_stuck(), "集成事故流程：清洗后锅应恢复正常并留在手中")
	wok_station.secondary_interact(player)
	_expect(player.held_item == null and wok_station.wok_item != null, "集成事故流程：炒锅应能放回原工位")
	_expect(not wok_station.wok_item.is_stuck(), "集成事故流程：放回后工位应可再次使用")
	await _dispose_scene(scene)


func _test_integrated_interruption_rules() -> void:
	var scene := await _spawn_main_scene()
	if scene == null:
		return
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var board := scene.get_node("Kitchen/CuttingBoard") as CuttingBoard
	var marinating := scene.get_node("Kitchen/MarinatingStation") as MarinatingStation
	var wok_station := scene.get_node("Kitchen/WokStation") as WokStation
	var sink := scene.get_node("Kitchen/Sink") as SinkStation

	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_CHUNK))
	board.carry_interact(player)
	board.begin_primary_interaction(player)
	board.update_primary_interaction(player, board.prototype_first_cut_time * 0.4)
	board.cancel_primary_interaction(player)
	_expect(board.get_progress_ratio() == 0.0, "集成中断：切割进度应归零")
	_expect(board.stored_item.data.item_type == ItemData.ItemType.RAW_BEEF_CHUNK, "集成中断：未完成切割不应改变离散状态")
	board.carry_interact(player)
	player.drop_held_item()

	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES))
	marinating.carry_interact(player)
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINADE))
	marinating.carry_interact(player)
	marinating.begin_primary_interaction(player)
	marinating.update_primary_interaction(player, marinating.prototype_marinating_time * 0.4)
	marinating.cancel_primary_interaction(player)
	_expect(marinating.get_progress_ratio() == 0.0, "集成中断：腌制进度应归零")
	_expect(marinating.meat_item.data.item_type == ItemData.ItemType.RAW_BEEF_SLICES, "集成中断：未完成腌制不应改变离散状态")

	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.COOKING_OIL))
	wok_station.carry_interact(player)
	player.receive_item_data(ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES))
	wok_station.carry_interact(player)
	wok_station.set_burner_on(true, player)
	wok_station.advance_automatic_cooking(wok_station.config.automatic_stage_one_time * 0.4, player)
	wok_station.set_burner_on(false, player)
	_expect(wok_station.get_progress_ratio() == 0.0, "集成中断：当前炒制阶段进度应归零")
	_expect(wok_station.wok_item.cook_stage == WokItem.CookStage.RAW_LOADED, "集成中断：未完成第一阶段不应推进离散状态")

	wok_station.wok_item.trigger_no_oil_accident()
	wok_station.secondary_interact(player)
	sink.begin_primary_interaction(player)
	sink.update_primary_interaction(player, sink.prototype_stuck_wok_wash_time * 0.4)
	sink.cancel_primary_interaction(player)
	_expect(sink.get_progress_ratio() == 0.0, "集成中断：粘锅清洗进度应归零")
	_expect((player.held_item as WokItem).is_stuck(), "集成中断：未完成清洗时粘锅状态应保留")
	await _dispose_scene(scene)


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "无法加载集成测试主场景")
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.start_game()
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _new_wok() -> WokItem:
	var wok := WokItem.new()
	wok.setup_wok(&"smoke_test_wok")
	return wok


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
