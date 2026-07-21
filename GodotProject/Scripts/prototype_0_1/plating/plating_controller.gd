class_name PlatingController
extends Node

@export var player_path: NodePath
@export var qte_ui_path: NodePath

var player: PrototypePlayer
var qte_ui: PlatingQTEUI
var combat_manager: CombatManager
var active: bool = false
var locked_dish: CarryableItem
var locked_dish_slot: int = -1
var opened_frame: int = -1


func _ready() -> void:
	player = get_node(player_path) as PrototypePlayer
	qte_ui = get_node(qte_ui_path) as PlatingQTEUI
	combat_manager = get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	add_to_group("plating_controller")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("season_dish"):
		request_apply_mustard()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("plate_dish"):
		return
	if active:
		if Engine.get_process_frames() > opened_frame:
			confirm_qte()
	else:
		request_start()
	get_viewport().set_input_as_handled()


func request_start() -> bool:
	if active:
		return false
	if player.modal_ui_open:
		player.notify_feedback("当前界面打开中，不能摆盘")
		return false
	if player.active_interactable != null:
		player.notify_feedback("请先结束当前持续交互")
		return false
	var dish_slot := _find_plating_candidate()
	if dish_slot == -1:
		player.notify_feedback("需要一份 100% 耐久且从未使用的可摆盘料理")
		return false
	if player.inventory.find_item_slot(ItemData.ItemType.CLEAN_PLATE) == -1:
		player.notify_feedback("需要一个干净盘子")
		return false
	locked_dish_slot = dish_slot
	locked_dish = player.inventory.get_item(dish_slot)
	if not player.inventory.consume_one_of_type(ItemData.ItemType.CLEAN_PLATE):
		return false
	active = true
	opened_frame = Engine.get_process_frames()
	player.set_modal_ui_open(true)
	qte_ui.open_qte(combat_manager.config)
	player.notify_feedback("摆盘中：再次按 Space 确认位置")
	return true


func request_apply_mustard() -> bool:
	if active or player.modal_ui_open:
		player.notify_feedback("当前界面或摆盘流程进行中，不能加入芥末")
		return false
	if player.active_interactable != null:
		player.notify_feedback("请先结束当前持续交互")
		return false
	var dish_slot := _find_mustard_candidate()
	if dish_slot == -1:
		player.notify_feedback("芥末只能加入待摆盘小炒，或完整未使用的战斧牛排")
		return false
	if player.inventory.find_item_slot(ItemData.ItemType.MUSTARD) == -1:
		player.notify_feedback("需要一份芥末")
		return false
	var dish := player.inventory.get_item(dish_slot)
	if dish.data.has_active_modifier(ItemData.ActiveModifier.MUSTARD):
		player.notify_feedback("这份料理已经加入芥末")
		return false
	if not player.inventory.consume_one_of_type(ItemData.ItemType.MUSTARD):
		return false
	dish.data.add_active_modifier(ItemData.ActiveModifier.MUSTARD)
	if dish.data.item_type == ItemData.ItemType.TOMAHAWK_STEAK:
		combat_manager.config.apply_tomahawk_stats(dish.data)
	dish.refresh_visual()
	player.inventory.notify_item_changed()
	player.notify_feedback("已加入芥末：料理成为怪异料理，无法获得完美品质（Prototype）")
	return true


func confirm_qte() -> bool:
	if not active:
		return false
	return _finish_plating(qte_ui.is_pointer_perfect())


func complete_for_test(hit_perfect: bool) -> bool:
	if not active:
		return false
	return _finish_plating(hit_perfect)


func _finish_plating(hit_perfect: bool) -> bool:
	if not is_instance_valid(locked_dish) or player.inventory.get_item(locked_dish_slot) != locked_dish:
		_abort_invalid_state()
		return false
	var target_type := ItemData.ItemType.PLATED_TOMAHAWK_STEAK if locked_dish.data.item_type == ItemData.ItemType.TOMAHAWK_STEAK else ItemData.ItemType.PLATED_STIR_FRY_BEEF
	var plated_data := ItemCatalog.transform(locked_dish.data, target_type)
	if plated_data.failure_tags.is_empty() and hit_perfect and not plated_data.is_weird_dish():
		plated_data.quality = ItemData.Quality.PERFECT
	else:
		plated_data.recalculate_quality()
	if target_type == ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
		combat_manager.config.apply_tomahawk_stats(plated_data)
	else:
		combat_manager.config.apply_combat_dish_stats(plated_data)
	locked_dish.data = plated_data
	locked_dish.refresh_visual()
	player.inventory.notify_item_changed()
	var result_text := plated_data.get_quality_text()
	active = false
	locked_dish = null
	locked_dish_slot = -1
	qte_ui.close_qte()
	player.set_modal_ui_open(false)
	player.notify_feedback("摆盘完成：%s%s品质%s" % ["怪异料理 / " if plated_data.is_weird_dish() else "", result_text, plated_data.display_name])
	return true


func _find_plating_candidate() -> int:
	var ordered: Array[int] = [player.inventory.selected_index]
	for slot_index in QuickInventory.SLOT_COUNT:
		if slot_index != player.inventory.selected_index:
			ordered.append(slot_index)
	for slot_index in ordered:
		var item := player.inventory.get_item(slot_index)
		if item != null and item.data.item_type in [ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.TOMAHAWK_STEAK] and item.data.is_eligible_for_plating():
			return slot_index
	return -1


func _find_mustard_candidate() -> int:
	for item_type in [ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.TOMAHAWK_STEAK]:
		var slot_index := player.inventory.find_item_slot(item_type)
		if slot_index == -1:
			continue
		var item := player.inventory.get_item(slot_index)
		if item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF or item.data.is_eligible_for_plating():
			return slot_index
	return -1


func _abort_invalid_state() -> void:
	active = false
	locked_dish = null
	locked_dish_slot = -1
	qte_ui.close_qte()
	player.set_modal_ui_open(false)
	player.notify_feedback("摆盘状态异常，流程已安全结束")


func reset_for_new_game() -> void:
	active = false
	locked_dish = null
	locked_dish_slot = -1
	if qte_ui != null:
		qte_ui.close_qte()
