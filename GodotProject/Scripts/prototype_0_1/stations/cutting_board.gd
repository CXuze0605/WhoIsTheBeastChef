class_name CuttingBoard
extends ProcessingStation

@export var prototype_first_cut_time: float = 1.2
@export var prototype_second_cut_time: float = 1.2

var stored_item: CarryableItem
var pending_outputs: Array[CarryableItem] = []


func _ready() -> void:
	add_to_group("cutting_board")
	display_title = "切菜板"
	placeholder_color = Color("8c6b45")
	super._ready()
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if not pending_outputs.is_empty():
		return "[F] 取走牛排（剩余 %d 块）" % pending_outputs.size()
	if stored_item != null:
		return "[F] 取回 %s" % stored_item.data.display_name
	if player.held_item != null and _can_cut(player.held_item.data):
		return "[F] 放到切菜板"
	return ""


func carry_interact(player: Node) -> void:
	if not pending_outputs.is_empty():
		var output := pending_outputs[0]
		if player.pickup_item(output):
			pending_outputs.pop_front()
			_reposition_pending_outputs()
			player.notify_feedback("取走一块生牛排；切菜板剩余 %d 块" % pending_outputs.size())
		_refresh_status()
		return
	if stored_item != null:
		hold_progress.cancel()
		var item := stored_item
		if player.pickup_item(item):
			stored_item = null
	else:
		if player.held_item == null:
			player.notify_feedback("切菜板上没有物品")
			return
		if not _can_cut(player.held_item.data):
			player.notify_feedback("该物品不能在这里加工")
			return
		if not pending_outputs.is_empty():
			player.notify_feedback("请先取完切菜板上的全部牛排")
			return
		stored_item = player.release_held_to_container(self, Vector2(0.0, -8.0))
		hold_progress.cancel()
		player.notify_feedback("已放入切菜板")
	_refresh_status()


func get_primary_prompt(_player: Node) -> String:
	return "[按住 E] 切割" if stored_item != null and _can_cut(stored_item.data) else ""


func begin_primary_interaction(player: Node) -> bool:
	if stored_item == null or not _can_cut(stored_item.data):
		player.notify_feedback("需要先放入可切割的牛肉")
		return false
	var duration := prototype_second_cut_time if stored_item.data.item_type == ItemData.ItemType.RAW_STEAK else prototype_first_cut_time
	hold_progress.begin(duration)
	player.notify_feedback("切割中；松开或离开会使本阶段进度归零")
	return true


func update_primary_interaction(player: Node, delta: float) -> bool:
	if stored_item == null:
		hold_progress.cancel()
		return false
	if not hold_progress.advance(delta):
		return true
	if stored_item.data.item_type == ItemData.ItemType.RAW_BEEF_CHUNK:
		_complete_chunk_cut()
		player.notify_feedback("切割完成：产出 3 块独立生牛排，请逐块取走")
	else:
		stored_item.data = ItemCatalog.transform(stored_item.data, ItemData.ItemType.RAW_BEEF_SLICES)
		stored_item.data.remaining_portions = 5
		stored_item.refresh_visual()
		player.notify_feedback("切割完成：1 份生牛肉片包（可涮 5 片）")
	_refresh_status()
	return false


func cancel_primary_interaction(player: Node) -> void:
	cancel_processing(player, "切割中断：本阶段进度归零，不会提前产出")


func get_debug_state() -> String:
	var item_text := stored_item.data.display_name if stored_item != null else "空"
	return "切菜板\n当前物品：%s\n待取牛排：%d\n进度：%d%%" % [
		item_text,
		pending_outputs.size(),
		roundi(get_progress_ratio() * 100.0),
	]


func _can_cut(item_data: ItemData) -> bool:
	return item_data.item_type in [ItemData.ItemType.RAW_BEEF_CHUNK, ItemData.ItemType.RAW_STEAK]


func _complete_chunk_cut() -> void:
	var source := stored_item
	var source_data := ItemCatalog.duplicate_data(source.data)
	stored_item = null
	source.queue_free()
	for index in 3:
		var steak_data := ItemCatalog.transform(source_data, ItemData.ItemType.RAW_STEAK)
		steak_data.stack_count = 1
		var steak := ItemFactory.create_carryable(steak_data)
		add_child(steak)
		steak.set_stored(self, Vector2((index - 1) * 25.0, -8.0))
		pending_outputs.append(steak)


func _reposition_pending_outputs() -> void:
	for index in pending_outputs.size():
		var item := pending_outputs[index]
		if is_instance_valid(item):
			item.set_stored(self, Vector2((index - (pending_outputs.size() - 1) * 0.5) * 25.0, -8.0))


func reset_for_new_game() -> void:
	hold_progress.cancel()
	if stored_item != null and is_instance_valid(stored_item):
		stored_item.queue_free()
	stored_item = null
	for output in pending_outputs:
		if is_instance_valid(output):
			output.queue_free()
	pending_outputs.clear()
	_refresh_status()


func _refresh_status() -> void:
	if not pending_outputs.is_empty():
		set_placeholder_status("待取生牛排：%d/3" % pending_outputs.size())
	elif stored_item != null:
		set_placeholder_status(stored_item.data.display_name)
	else:
		set_placeholder_status("空")
