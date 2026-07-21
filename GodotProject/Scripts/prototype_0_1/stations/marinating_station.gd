class_name MarinatingStation
extends ProcessingStation

@export var prototype_marinating_time: float = 1.6

var meat_item: CarryableItem
var marinade_item: CarryableItem


func _ready() -> void:
	add_to_group("marinating_station")
	display_title = "腌制区域"
	placeholder_color = Color("6c5c84")
	super._ready()
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if player.held_item != null:
		if player.held_item.data.item_type == ItemData.ItemType.RAW_BEEF_SLICES and meat_item == null:
			return "[F] 放入生牛肉片"
		if player.held_item.data.item_type == ItemData.ItemType.MARINADE and marinade_item == null:
			return "[F] 放入腌肉料"
	if meat_item != null:
		return "[F] 取回 %s" % meat_item.data.display_name
	if marinade_item != null:
		return "[F] 取回腌肉料"
	return ""


func carry_interact(player: Node) -> void:
	if player.held_item != null:
		var item_type: int = player.held_item.data.item_type
		if item_type == ItemData.ItemType.RAW_BEEF_SLICES and meat_item == null:
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
	if meat_item != null:
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
	return "[按住 E] 腌制" if meat_item != null and marinade_item != null else ""


func begin_primary_interaction(player: Node) -> bool:
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
	if meat_item == null or marinade_item == null:
		hold_progress.cancel()
		return false
	if hold_progress.advance(delta):
		meat_item.data = ItemCatalog.transform(meat_item.data, ItemData.ItemType.MARINATED_BEEF_SLICES)
		meat_item.refresh_visual()
		marinade_item.queue_free()
		marinade_item = null
		player.notify_feedback("腌制完成：腌牛肉片；腌肉料已消耗")
		_refresh_status()
		return false
	return true


func cancel_primary_interaction(player: Node) -> void:
	cancel_processing(player, "腌制中断：本次进度归零，腌肉料未消耗")


func get_debug_state() -> String:
	var meat_text := meat_item.data.display_name if meat_item != null else "空"
	var marinade_text := "已放入" if marinade_item != null else "未放入"
	return "腌制区域\n牛肉：%s\n腌肉料：%s\n进度：%d%%" % [meat_text, marinade_text, roundi(get_progress_ratio() * 100.0)]


func _refresh_status() -> void:
	var meat_text := meat_item.data.display_name if meat_item != null else "无牛肉"
	var marinade_text := "有腌料" if marinade_item != null else "无腌料"
	set_placeholder_status("%s / %s" % [meat_text, marinade_text])


func reset_for_new_game() -> void:
	hold_progress.cancel()
	if meat_item != null and is_instance_valid(meat_item):
		meat_item.queue_free()
	if marinade_item != null and is_instance_valid(marinade_item):
		marinade_item.queue_free()
	meat_item = null
	marinade_item = null
	_refresh_status()
