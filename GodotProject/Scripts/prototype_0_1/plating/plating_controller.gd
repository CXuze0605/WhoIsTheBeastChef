class_name PlatingController
extends Node

enum ActionMode { NONE, PLATING, SPLIT_GREENS, COMBINE_RICE_BOWL }

@export var player_path: NodePath
@export var qte_ui_path: NodePath

var player: PrototypePlayer
var qte_ui: PlatingQTEUI
var combat_manager: CombatManager
var active: bool = false
var locked_dish: CarryableItem
var locked_dish_slot: int = -1
var opened_frame: int = -1
var action_mode: int = ActionMode.NONE
var locked_from_backpack: bool = false
var locked_component: CarryableItem
var locked_component_slot: int = -1
var locked_combination_recipe: StringName = &""


func _ready() -> void:
	player = get_node(player_path) as PrototypePlayer
	qte_ui = get_node(qte_ui_path) as PlatingQTEUI
	combat_manager = get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	add_to_group("plating_controller")
	add_to_group("prototype_local_modal")


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
	if player.modal_ui_open or player.action_qte_locked:
		player.notify_feedback("当前界面打开中，不能摆盘")
		return false
	if player.active_interactable != null:
		player.notify_feedback("请先结束当前持续交互")
		return false
	if player.held_item != null and player.held_item.data.item_type == ItemData.ItemType.WHOLE_GREENS:
		return request_split_greens(player.held_item, false)
	var combination := _find_crispy_beef_components()
	if combination.is_empty():
		combination = _find_rice_bowl_components()
	if not combination.is_empty():
		return _start_rice_bowl_combination(combination)
	var dish_slot := _find_plating_candidate()
	if dish_slot == -1:
		player.notify_feedback("需要一份 100% 耐久且从未使用的可摆盘料理")
		return false
	if player.inventory.find_item_slot(ItemData.ItemType.CLEAN_PLATE) == -1:
		player.notify_feedback("需要一个干净盘子")
		return false
	locked_dish_slot = dish_slot
	locked_dish = player.inventory.get_item(dish_slot)
	action_mode = ActionMode.PLATING
	locked_from_backpack = false
	locked_component = null
	locked_component_slot = -1
	locked_combination_recipe = &""
	active = true
	opened_frame = Engine.get_process_frames()
	player.set_action_qte_locked(true)
	qte_ui.open_qte(combat_manager.config)
	player.notify_feedback("摆盘中：可 %s 移动；再次按 %s 确认，ESC 取消" % [_movement_hint(), InputPrompt.action_text(&"plate_dish", "Space")])
	return true


func request_split_greens(item: CarryableItem, from_backpack: bool = false) -> bool:
	if active or item == null or item.data == null or item.data.item_type != ItemData.ItemType.WHOLE_GREENS:
		return false
	if player.modal_ui_open or player.action_qte_locked or player.active_interactable != null:
		player.notify_feedback("请先关闭当前界面或结束持续交互")
		return false
	if from_backpack:
		if player.backpack == null or player.backpack.get_placement(item) == null:
			return false
		locked_dish_slot = -1
	else:
		locked_dish_slot = player.inventory.find_item_slot(ItemData.ItemType.WHOLE_GREENS)
		if locked_dish_slot == -1 or player.inventory.get_item(locked_dish_slot) != item:
			return false
	locked_dish = item
	locked_from_backpack = from_backpack
	action_mode = ActionMode.SPLIT_GREENS
	active = true
	opened_frame = Engine.get_process_frames()
	player.set_action_qte_locked(true)
	qte_ui.open_qte(combat_manager.config)
	player.notify_feedback("拆菜 QTE：可 %s 移动；%s 完成，ESC 取消（产量固定 5 片）" % [_movement_hint(), InputPrompt.action_text(&"plate_dish", "Space")])
	return true


func _movement_hint() -> String:
	return "%s/%s/%s/%s" % [
		InputPrompt.action_text(&"move_up", "W"),
		InputPrompt.action_text(&"move_left", "A"),
		InputPrompt.action_text(&"move_down", "S"),
		InputPrompt.action_text(&"move_right", "D"),
	]


func request_apply_mustard() -> bool:
	if active or player.modal_ui_open or player.action_qte_locked:
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
	else:
		combat_manager.config.apply_combat_dish_stats(dish.data)
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


func is_local_modal_open() -> bool:
	return active


func close_local_modal() -> void:
	cancel_active_plating()


func cancel_active_plating() -> bool:
	if not active:
		return false
	active = false
	locked_dish = null
	locked_dish_slot = -1
	action_mode = ActionMode.NONE
	locked_from_backpack = false
	locked_component = null
	locked_component_slot = -1
	locked_combination_recipe = &""
	qte_ui.close_qte()
	player.set_action_qte_locked(false)
	player.notify_feedback("已取消摆盘；料理和干净盘子均未消耗")
	return true


func _finish_plating(hit_perfect: bool) -> bool:
	if action_mode == ActionMode.SPLIT_GREENS:
		return _finish_greens_split()
	if action_mode == ActionMode.COMBINE_RICE_BOWL:
		return _finish_rice_bowl_combination(hit_perfect)
	if not is_instance_valid(locked_dish) or player.inventory.get_item(locked_dish_slot) != locked_dish:
		_abort_invalid_state()
		return false
	var target_type := _get_plated_type(locked_dish.data.item_type)
	if target_type < 0:
		_abort_invalid_state()
		return false
	if not player.inventory.consume_one_of_type(ItemData.ItemType.CLEAN_PLATE):
		_abort_invalid_state()
		player.notify_feedback("干净盘子已不在快捷栏，摆盘未消耗料理")
		return false
	var plated_data := ItemCatalog.transform(locked_dish.data, target_type)
	if plated_data.failure_tags.is_empty() and hit_perfect and not plated_data.is_weird_dish():
		plated_data.set_quality_with_cap(ItemData.Quality.PERFECT)
	else:
		plated_data.recalculate_quality()
	if target_type == ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
		combat_manager.config.apply_tomahawk_stats(plated_data)
	elif target_type == ItemData.ItemType.PLATED_WHITE_RICE:
		combat_manager.config.apply_white_rice_stats(plated_data)
	elif target_type == ItemData.ItemType.PLATED_RICE_PORRIDGE:
		combat_manager.config.apply_rice_porridge_stats(plated_data)
	elif target_type == ItemData.ItemType.PLATED_CRISPY_RICE:
		combat_manager.config.apply_crispy_rice_stats(plated_data)
	elif plated_data.recipe_id != &"":
		ExpandedRecipeCatalog.refresh_after_plating(plated_data, combat_manager.config)
	else:
		combat_manager.config.apply_combat_dish_stats(plated_data)
	locked_dish.data = plated_data
	locked_dish.refresh_visual()
	player.inventory.notify_item_changed()
	var result_text := plated_data.get_quality_text()
	active = false
	locked_dish = null
	locked_dish_slot = -1
	action_mode = ActionMode.NONE
	locked_from_backpack = false
	qte_ui.close_qte()
	player.set_action_qte_locked(false)
	player.notify_feedback("摆盘完成：%s%s品质%s" % ["怪异料理 / " if plated_data.is_weird_dish() else "", result_text, plated_data.display_name])
	return true


func _find_rice_bowl_components() -> Dictionary:
	var rice_slot := player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_WHITE_RICE)
	if rice_slot < 0:
		return {}
	var rice := player.inventory.get_item(rice_slot)
	if rice == null or not rice.data.is_eligible_for_plating():
		return {}
	var priorities := [
		{
			"type": ItemData.ItemType.UNPLATED_BEEF_GREENS,
			"recipe": ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL,
		},
		{
			"type": ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF,
			"recipe": ExpandedRecipeCatalog.BEEF_RICE_BOWL,
		},
		{
			"type": ItemData.ItemType.UNPLATED_BOILED_GREENS,
			"recipe": ExpandedRecipeCatalog.GREENS_RICE_BOWL,
		},
		{
			"type": ItemData.ItemType.UNPLATED_STIR_FRY_GREENS,
			"recipe": ExpandedRecipeCatalog.GREENS_RICE_BOWL,
		},
	]
	for option in priorities:
		var component_slot := player.inventory.find_item_slot(int(option["type"]))
		if component_slot < 0:
			continue
		var component := player.inventory.get_item(component_slot)
		if component == null or not component.data.is_eligible_for_plating():
			continue
		return {
			"rice_slot": rice_slot,
			"component_slot": component_slot,
			"rice": rice,
			"component": component,
			"recipe": option["recipe"],
		}
	return {}


func _find_crispy_beef_components() -> Dictionary:
	var crispy_slot := player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_CRISPY_RICE)
	var beef_slot := player.inventory.find_item_slot(ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF)
	if crispy_slot < 0 or beef_slot < 0:
		return {}
	var crispy := player.inventory.get_item(crispy_slot)
	var beef := player.inventory.get_item(beef_slot)
	if (
		crispy == null
		or beef == null
		or not crispy.data.is_eligible_for_plating()
		or not beef.data.is_eligible_for_plating()
	):
		return {}
	return {
		"rice_slot": crispy_slot,
		"component_slot": beef_slot,
		"rice": crispy,
		"component": beef,
		"recipe": ExpandedRecipeCatalog.CRISPY_RICE_BEEF,
	}


func _start_rice_bowl_combination(parts: Dictionary) -> bool:
	var recipe := StringName(parts.get("recipe", &""))
	var requires_plate := recipe == ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL
	if requires_plate and player.inventory.find_item_slot(ItemData.ItemType.CLEAN_PLATE) < 0:
		player.notify_feedback("青菜牛肉盖饭需要一个干净盘子")
		return false
	locked_dish_slot = int(parts["rice_slot"])
	locked_dish = parts["rice"] as CarryableItem
	locked_component_slot = int(parts["component_slot"])
	locked_component = parts["component"] as CarryableItem
	locked_combination_recipe = recipe
	action_mode = ActionMode.COMBINE_RICE_BOWL
	locked_from_backpack = false
	active = true
	opened_frame = Engine.get_process_frames()
	player.set_action_qte_locked(true)
	qte_ui.open_qte(combat_manager.config)
	player.notify_feedback(
		"%s组合 QTE：可 WASD 移动；成功后%s"
		% [
			"锅巴牛肉" if recipe == ExpandedRecipeCatalog.CRISPY_RICE_BEEF else "盖饭",
			"两个完整组件与一只盘子原子合并" if requires_plate else "两个完整组件合并为待摆盘料理",
		]
	)
	return true


func _finish_rice_bowl_combination(hit_perfect: bool) -> bool:
	if (
		not is_instance_valid(locked_dish)
		or not is_instance_valid(locked_component)
		or player.inventory.get_item(locked_dish_slot) != locked_dish
		or player.inventory.get_item(locked_component_slot) != locked_component
		or not locked_dish.data.is_eligible_for_plating()
		or not locked_component.data.is_eligible_for_plating()
	):
		_abort_invalid_state()
		return false
	var direct_plated := locked_combination_recipe == ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL
	if direct_plated and not player.inventory.consume_one_of_type(ItemData.ItemType.CLEAN_PLATE):
		_abort_invalid_state()
		player.notify_feedback("干净盘已不在快捷栏，盖饭组合未消耗两个料理")
		return false
	var source_data: Array[ItemData] = [locked_dish.data, locked_component.data]
	var result: ItemData
	if direct_plated:
		result = ExpandedRecipeCatalog.create_advanced_dish(
			ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL,
			locked_component.data.leaf_count,
			source_data,
			combat_manager.config
		)
	elif locked_combination_recipe == ExpandedRecipeCatalog.CRISPY_RICE_BEEF:
		result = ExpandedRecipeCatalog.create_group_5_crispy_beef(source_data, combat_manager.config)
	else:
		result = ExpandedRecipeCatalog.create_group_2_rice_bowl(
			locked_combination_recipe,
			source_data,
			combat_manager.config
		)
	if direct_plated and hit_perfect and result.failure_tags.is_empty() and not result.is_weird_dish():
		result.set_quality_with_cap(ItemData.Quality.PERFECT)
		ExpandedRecipeCatalog.refresh_after_plating(result, combat_manager.config)
	var consumed_component := player.inventory.take_item(locked_component_slot)
	if consumed_component != null:
		consumed_component.queue_free()
	locked_dish.data = result
	locked_dish.refresh_visual()
	player.inventory.notify_item_changed()
	var result_text := result.get_quality_text()
	active = false
	locked_dish = null
	locked_dish_slot = -1
	locked_component = null
	locked_component_slot = -1
	var completed_recipe := locked_combination_recipe
	locked_combination_recipe = &""
	action_mode = ActionMode.NONE
	qte_ui.close_qte()
	player.set_action_qte_locked(false)
	player.notify_feedback(
		"组合完成：%s%s"
		% [
			"%s品质" % result_text if direct_plated else "",
			"青菜牛肉盖饭炮台" if completed_recipe == ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL else result.display_name,
		]
	)
	return true


func _finish_greens_split() -> bool:
	if not is_instance_valid(locked_dish):
		_abort_invalid_state()
		return false
	var still_owned := (
		player.backpack.get_placement(locked_dish) != null
		if locked_from_backpack
		else locked_dish_slot >= 0 and player.inventory.get_item(locked_dish_slot) == locked_dish
	)
	if not still_owned:
		_abort_invalid_state()
		return false
	var source_data := locked_dish.data
	var leaves := ItemCatalog.transform(source_data, ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	leaves.leaf_count = 5
	locked_dish.data = leaves
	locked_dish.refresh_visual()
	if locked_from_backpack:
		player.backpack.changed.emit()
	else:
		player.inventory.notify_item_changed()
	active = false
	locked_dish = null
	locked_dish_slot = -1
	action_mode = ActionMode.NONE
	locked_from_backpack = false
	qte_ui.close_qte()
	player.set_action_qte_locked(false)
	player.notify_feedback("拆菜完成：固定获得 5 片青菜叶")
	return true


func _find_plating_candidate() -> int:
	var ordered: Array[int] = [player.inventory.selected_index]
	for slot_index in QuickInventory.SLOT_COUNT:
		if slot_index != player.inventory.selected_index:
			ordered.append(slot_index)
	for slot_index in ordered:
		var item := player.inventory.get_item(slot_index)
		if item != null and item.data.item_type in [
			ItemData.ItemType.UNPLATED_STIR_FRY_BEEF,
			ItemData.ItemType.TOMAHAWK_STEAK,
			ItemData.ItemType.UNPLATED_WHITE_RICE,
			ItemData.ItemType.UNPLATED_RICE_PORRIDGE,
			ItemData.ItemType.UNPLATED_CRISPY_RICE,
			ItemData.ItemType.UNPLATED_BOILED_GREENS,
			ItemData.ItemType.UNPLATED_STIR_FRY_GREENS,
			ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS,
			ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS,
			ItemData.ItemType.UNPLATED_GREENS_PORRIDGE,
			ItemData.ItemType.UNPLATED_BEEF_PORRIDGE,
			ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE,
			ItemData.ItemType.UNPLATED_BEEF_GREENS,
			ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE,
			ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE,
			ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE,
			ItemData.ItemType.UNPLATED_VEGETABLE_RICE,
			ItemData.ItemType.UNPLATED_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP,
			ItemData.ItemType.UNPLATED_MUSTARD_GREENS,
			ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE,
			ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF,
			ItemData.ItemType.UNPLATED_GREENS_SOUP,
			ItemData.ItemType.UNPLATED_BEEF_SOUP,
			ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL,
			ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL,
			ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE,
			ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF,
			ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE,
			ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS,
			ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE,
			ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE,
			ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP,
			ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP,
			ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE,
			ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE,
			ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE,
			ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE,
		] and item.data.is_eligible_for_plating():
			return slot_index
	return -1


func _get_plated_type(source_type: int) -> int:
	match source_type:
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			return ItemData.ItemType.PLATED_STIR_FRY_BEEF
		ItemData.ItemType.TOMAHAWK_STEAK:
			return ItemData.ItemType.PLATED_TOMAHAWK_STEAK
		ItemData.ItemType.UNPLATED_WHITE_RICE:
			return ItemData.ItemType.PLATED_WHITE_RICE
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE:
			return ItemData.ItemType.PLATED_RICE_PORRIDGE
		ItemData.ItemType.UNPLATED_CRISPY_RICE:
			return ItemData.ItemType.PLATED_CRISPY_RICE
		ItemData.ItemType.UNPLATED_BOILED_GREENS:
			return ItemData.ItemType.PLATED_BOILED_GREENS
		ItemData.ItemType.UNPLATED_STIR_FRY_GREENS:
			return ItemData.ItemType.PLATED_STIR_FRY_GREENS
		ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS:
			return ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS
		ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS:
			return ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE:
			return ItemData.ItemType.PLATED_GREENS_PORRIDGE
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE:
			return ItemData.ItemType.PLATED_BEEF_PORRIDGE
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE:
			return ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE
		ItemData.ItemType.UNPLATED_BEEF_GREENS:
			return ItemData.ItemType.PLATED_BEEF_GREENS
		ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE:
			return ItemData.ItemType.PLATED_GREENS_FRIED_RICE
		ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE:
			return ItemData.ItemType.PLATED_BEEF_FRIED_RICE
		ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE:
			return ItemData.ItemType.PLATED_MIXED_FRIED_RICE
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE:
			return ItemData.ItemType.PLATED_VEGETABLE_RICE
		ItemData.ItemType.UNPLATED_SOAKED_RICE:
			return ItemData.ItemType.PLATED_SOAKED_RICE
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE:
			return ItemData.ItemType.PLATED_GREENS_SOAKED_RICE
		ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP:
			return ItemData.ItemType.PLATED_BEEF_GREENS_SOUP
		ItemData.ItemType.UNPLATED_MUSTARD_GREENS:
			return ItemData.ItemType.PLATED_MUSTARD_GREENS
		ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE:
			return ItemData.ItemType.PLATED_FRIED_WHITE_RICE
		ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF:
			return ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF
		ItemData.ItemType.UNPLATED_GREENS_SOUP:
			return ItemData.ItemType.PLATED_GREENS_SOUP
		ItemData.ItemType.UNPLATED_BEEF_SOUP:
			return ItemData.ItemType.PLATED_BEEF_SOUP
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL:
			return ItemData.ItemType.PLATED_GREENS_RICE_BOWL
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL:
			return ItemData.ItemType.PLATED_BEEF_RICE_BOWL
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE:
			return ItemData.ItemType.PLATED_BEEF_BRAISED_RICE
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE:
			return ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE:
			return ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE:
			return ItemData.ItemType.PLATED_BEEF_SOAKED_RICE
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE:
			return ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF:
			return ItemData.ItemType.PLATED_CRISPY_RICE_BEEF
		ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE:
			return ItemData.ItemType.PLATED_SPICY_FRIED_RICE
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS:
			return ItemData.ItemType.PLATED_SPICY_BEEF_GREENS
		ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE:
			return ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE
		ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE:
			return ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE
		ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP:
			return ItemData.ItemType.PLATED_SPICY_BEEF_SOUP
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP:
			return ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP
		ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE:
			return ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE
		ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE:
			return ItemData.ItemType.PLATED_GREENS_RICE_CAKE
		ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE:
			return ItemData.ItemType.PLATED_BEEF_RICE_CAKE
		ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE:
			return ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE
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
	action_mode = ActionMode.NONE
	locked_from_backpack = false
	locked_component = null
	locked_component_slot = -1
	locked_combination_recipe = &""
	qte_ui.close_qte()
	player.set_action_qte_locked(false)
	player.notify_feedback("摆盘状态异常，流程已安全结束")


func reset_for_new_game() -> void:
	active = false
	locked_dish = null
	locked_dish_slot = -1
	action_mode = ActionMode.NONE
	locked_from_backpack = false
	locked_component = null
	locked_component_slot = -1
	locked_combination_recipe = &""
	if qte_ui != null:
		qte_ui.close_qte()
	if player != null:
		player.set_action_qte_locked(false)
