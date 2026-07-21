class_name CuttingBoard
extends ProcessingStation

@export var prototype_first_cut_time: float = 1.2
@export var prototype_second_cut_time: float = 1.2

var stored_item: CarryableItem


func _ready() -> void:
	add_to_group("cutting_board")
	display_title = "切菜板"
	placeholder_color = Color("8c6b45")
	super._ready()
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if stored_item != null:
		return "[F] 取回 %s" % stored_item.data.display_name
	if player.held_item != null and _can_cut(player.held_item.data):
		return "[F] 放到切菜板"
	return ""


func carry_interact(player: Node) -> void:
	if stored_item != null:
		if not player.can_receive_item():
			player.notify_feedback("物品栏已满")
			return
		hold_progress.cancel()
		var item := stored_item
		if player.pickup_item(item):
			stored_item = null
	else:
		if player.held_item != null:
			if not _can_cut(player.held_item.data):
				player.notify_feedback("该物品不能在这里加工")
				return
			stored_item = player.release_held_to_container(self, Vector2(0.0, -8.0))
			hold_progress.cancel()
			player.notify_feedback("已放入切菜板")
		else:
			player.notify_feedback("切菜板上没有物品")
			return
	_refresh_status()


func get_primary_prompt(_player: Node) -> String:
	return "[按住 E] 切割" if stored_item != null and _can_cut(stored_item.data) else ""


func begin_primary_interaction(player: Node) -> bool:
	if stored_item == null or not _can_cut(stored_item.data):
		player.notify_feedback("需要先放入可切割的牛肉")
		return false
	var duration := prototype_first_cut_time
	if stored_item.data.item_type == ItemData.ItemType.RAW_STEAK:
		duration = prototype_second_cut_time
	hold_progress.begin(duration)
	player.notify_feedback("切割中；松开或离开会使本阶段进度归零")
	return true


func update_primary_interaction(player: Node, delta: float) -> bool:
	if stored_item == null:
		hold_progress.cancel()
		return false
	if hold_progress.advance(delta):
		if stored_item.data.item_type == ItemData.ItemType.RAW_BEEF_CHUNK:
			stored_item.data = ItemCatalog.transform(stored_item.data, ItemData.ItemType.RAW_STEAK)
		else:
			stored_item.data = ItemCatalog.transform(stored_item.data, ItemData.ItemType.RAW_BEEF_SLICES)
		stored_item.refresh_visual()
		player.notify_feedback("切割完成：%s" % stored_item.data.display_name)
		_refresh_status()
		return false
	return true


func cancel_primary_interaction(player: Node) -> void:
	cancel_processing(player, "切割中断：本阶段进度归零，离散状态不变")


func get_debug_state() -> String:
	var item_text := stored_item.data.display_name if stored_item != null else "空"
	return "切菜板\n当前物品：%s\n进度：%d%%" % [item_text, roundi(get_progress_ratio() * 100.0)]


func _can_cut(item_data: ItemData) -> bool:
	return item_data.item_type in [ItemData.ItemType.RAW_BEEF_CHUNK, ItemData.ItemType.RAW_STEAK]


func reset_for_new_game() -> void:
	hold_progress.cancel()
	if stored_item != null and is_instance_valid(stored_item):
		stored_item.queue_free()
	stored_item = null
	_refresh_status()


func _refresh_status() -> void:
	set_placeholder_status(stored_item.data.display_name if stored_item != null else "空")
