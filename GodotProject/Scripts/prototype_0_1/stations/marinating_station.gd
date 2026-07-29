class_name MarinatingStation
extends ProcessingStation

@export var prototype_marinating_time: float = 1.6

var meat_item: CarryableItem
var marinade_item: CarryableItem
var greens_item: CarryableItem
var mustard_item: CarryableItem
var combat_config := PrototypeCombatConfig.new()


func _ready() -> void:
	add_to_group("marinating_station")
	display_title = "腌制区域"
	placeholder_color = Color("6c5c84")
	super._ready()
	var combat := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat != null:
		combat_config = combat.config
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if player.held_item != null:
		if player.held_item.data.item_type == ItemData.ItemType.GREENS_LEAF and greens_item == null and meat_item == null:
			return "[F] 放入 1～5 片青菜叶"
		if player.held_item.data.item_type == ItemData.ItemType.MUSTARD and mustard_item == null and marinade_item == null:
			return "[F] 放入芥末"
		if player.held_item.data.item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.RAW_BEEF_DICE] and meat_item == null:
			return "[F] 放入生牛肉片/牛肉丁"
		if player.held_item.data.item_type == ItemData.ItemType.MARINADE and marinade_item == null:
			return "[F] 放入腌肉料"
	if greens_item != null:
		return "[F] 取回 %s" % greens_item.data.display_name
	if mustard_item != null:
		return "[F] 取回芥末"
	if meat_item != null:
		return "[F] 取回 %s" % meat_item.data.display_name
	if marinade_item != null:
		return "[F] 取回腌肉料"
	return ""


func carry_interact(player: Node) -> void:
	if player.held_item != null:
		var item_type: int = player.held_item.data.item_type
		if item_type == ItemData.ItemType.GREENS_LEAF and greens_item == null and meat_item == null:
			greens_item = player.release_held_to_container(self, Vector2(-30.0, -8.0))
		elif item_type == ItemData.ItemType.MUSTARD and mustard_item == null and marinade_item == null:
			mustard_item = player.release_held_to_container(self, Vector2(30.0, -8.0))
		elif item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.RAW_BEEF_DICE] and meat_item == null:
			meat_item = player.release_held_to_container(self, Vector2(-30.0, -8.0))
		elif item_type == ItemData.ItemType.MARINADE and marinade_item == null:
			marinade_item = player.release_held_to_container(self, Vector2(30.0, -8.0))
		else:
			_take_available_item(player)
			_refresh_status()
			return
		hold_progress.cancel()
		player.notify_feedback("已放入腌制区域")
	else:
		_take_available_item(player)
	_refresh_status()


func _take_available_item(player: Node) -> void:
	if not player.can_receive_item():
		player.notify_feedback("物品栏已满")
		return
	var item_to_take: CarryableItem
	if greens_item != null:
		item_to_take = greens_item
		if player.pickup_item(item_to_take):
			greens_item = null
	elif mustard_item != null:
		item_to_take = mustard_item
		if player.pickup_item(item_to_take):
			mustard_item = null
	elif meat_item != null:
		item_to_take = meat_item
		if player.pickup_item(item_to_take):
			meat_item = null
	elif marinade_item != null:
		item_to_take = marinade_item
		if player.pickup_item(item_to_take):
			marinade_item = null
	else:
		player.notify_feedback("腌制区域为空")
		return
	hold_progress.cancel()
	player.notify_feedback("已从腌制区域取回物品")


func get_primary_prompt(_player: Node) -> String:
	if greens_item != null and mustard_item != null:
		return "[按住 %s] 拌制芥末青菜" % InputPrompt.action_text(&"interact_primary", "E")
	return "[按住 %s] 腌制" % InputPrompt.action_text(&"interact_primary", "E") if meat_item != null and marinade_item != null else ""


func begin_primary_interaction(player: Node) -> bool:
	if greens_item != null or mustard_item != null:
		if greens_item == null or mustard_item == null:
			player.notify_feedback("拌制芥末青菜需要青菜叶与一份芥末")
			return false
		hold_progress.begin(combat_config.mustard_greens_mix_time)
		player.notify_feedback("拌制芥末青菜中；松开会使本次进度归零")
		return true
	if meat_item == null:
		player.notify_feedback("需要先放入牛肉片")
		return false
	if marinade_item == null:
		player.notify_feedback("需要腌肉料")
		return false
	hold_progress.begin(prototype_marinating_time)
	player.notify_feedback("腌制中；松开或离开会使本次进度归零")
	return true


func update_primary_interaction(player: Node, delta: float) -> bool:
	if greens_item != null or mustard_item != null:
		if greens_item == null or mustard_item == null:
			hold_progress.cancel()
			return false
		if hold_progress.advance(delta):
			var sources: Array[ItemData] = [greens_item.data, mustard_item.data]
			greens_item.data = ExpandedRecipeCatalog.create_advanced_dish(
				ExpandedRecipeCatalog.MUSTARD_GREENS,
				greens_item.data.stack_count,
				sources,
				combat_config
			)
			greens_item.refresh_visual()
			mustard_item.queue_free()
			mustard_item = null
			player.notify_feedback("芥末青菜完成：怪异料理，最高正常品质")
			_refresh_status()
			return false
		return true
	if meat_item == null or marinade_item == null:
		hold_progress.cancel()
		return false
	if hold_progress.advance(delta):
		var was_near_expiry := meat_item.data.has_failure_tag(ItemData.FailureTag.NEAR_EXPIRY)
		var target_type := (
			ItemData.ItemType.MARINATED_BEEF_DICE
			if meat_item.data.item_type == ItemData.ItemType.RAW_BEEF_DICE
			else ItemData.ItemType.MARINATED_BEEF_SLICES
		)
		meat_item.data = ItemCatalog.transform(meat_item.data, target_type)
		meat_item.data.is_marinated = true
		if was_near_expiry:
			var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
			if stats != null:
				stats.record_near_expiry_processed()
		meat_item.refresh_visual()
		marinade_item.queue_free()
		marinade_item = null
		player.notify_feedback("腌制完成：%s；腌肉料已消耗" % meat_item.data.display_name)
		_refresh_status()
		return false
	return true


func handle_rotten_item_data(data: ItemData) -> void:
	var meat_rotted := meat_item != null and meat_item.data == data
	if meat_rotted or (greens_item != null and greens_item.data == data):
		var was_processing := hold_progress.active
		hold_progress.cancel()
		if meat_rotted and was_processing and marinade_item != null:
			marinade_item.queue_free()
			marinade_item = null
		_refresh_status()


func cancel_primary_interaction(player: Node) -> void:
	cancel_processing(player, "腌制中断：本次进度归零，腌肉料未消耗")


func get_debug_state() -> String:
	if greens_item != null or mustard_item != null:
		return "拌制区域\n青菜：%s\n芥末：%s\n进度：%d%%" % [
			greens_item.data.display_name if greens_item != null else "无",
			"已放入" if mustard_item != null else "未放入",
			roundi(get_progress_ratio() * 100.0),
		]
	var meat_text := meat_item.data.display_name if meat_item != null else "空"
	var marinade_text := "已放入" if marinade_item != null else "未放入"
	return "腌制区域\n牛肉：%s\n腌肉料：%s\n进度：%d%%" % [meat_text, marinade_text, roundi(get_progress_ratio() * 100.0)]


func _refresh_status() -> void:
	if greens_item != null or mustard_item != null:
		set_placeholder_status("%s / %s" % [
			greens_item.data.display_name if greens_item != null else "无青菜",
			"有芥末" if mustard_item != null else "无芥末",
		])
		return
	var meat_text := meat_item.data.display_name if meat_item != null else "无牛肉"
	var marinade_text := "有腌料" if marinade_item != null else "无腌料"
	set_placeholder_status("%s / %s" % [meat_text, marinade_text])


func reset_for_new_game() -> void:
	hold_progress.cancel()
	if meat_item != null and is_instance_valid(meat_item):
		meat_item.queue_free()
	if marinade_item != null and is_instance_valid(marinade_item):
		marinade_item.queue_free()
	if greens_item != null and is_instance_valid(greens_item):
		greens_item.queue_free()
	if mustard_item != null and is_instance_valid(mustard_item):
		mustard_item.queue_free()
	meat_item = null
	marinade_item = null
	greens_item = null
	mustard_item = null
	_refresh_status()
