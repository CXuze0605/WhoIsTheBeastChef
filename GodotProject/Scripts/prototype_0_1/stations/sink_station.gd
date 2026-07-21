class_name SinkStation
extends ProcessingStation

@export var prototype_stuck_wok_wash_time: float = 2.2

enum WashMode {
	NONE,
	WOK,
	PLATES,
}

var dirty_plate_count: int = 0
var active_wash_mode: int = WashMode.NONE
var locked_plate_wash_duration: float = 0.0
var locked_plate_speed_tier: String = "无"
var clean_plate_pile: CleanPlatePile
var combat_config := PrototypeCombatConfig.new()


func _ready() -> void:
	display_title = "水池"
	placeholder_color = Color("397b8f")
	super._ready()
	var combat_runtime := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat_runtime != null:
		combat_config = combat_runtime.config
	clean_plate_pile = get_tree().get_first_node_in_group("clean_plate_pile") as CleanPlatePile
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if player.held_item is SoupPotItem and not (player.held_item as SoupPotItem).has_water:
		return "[F] 给汤锅加水"
	if player.held_item != null and player.held_item.data.item_type == ItemData.ItemType.DIRTY_PLATE:
		return "[F] 将脏盘子投入水池"
	return ""


func carry_interact(player: Node) -> void:
	if player.held_item is SoupPotItem:
		var pot := player.held_item as SoupPotItem
		if pot.fill_water():
			player.notify_feedback("汤锅已加水；放到开火灶位后自动加热")
			return
		player.notify_feedback("汤锅已有水或锅内有内容")
		return
	if player.held_item == null or player.held_item.data.item_type != ItemData.ItemType.DIRTY_PLATE:
		player.notify_feedback("需要当前选中脏盘子")
		return
	var dirty_stack: CarryableItem = player.take_selected_item_node()
	dirty_plate_count += dirty_stack.data.stack_count
	dirty_stack.queue_free()
	hold_progress.cancel()
	active_wash_mode = WashMode.NONE
	player.notify_feedback("脏盘子已投入水池：当前 %d 个" % dirty_plate_count)
	_refresh_status()


func get_primary_prompt(player: Node) -> String:
	if player.held_item is CookwareItem and (player.held_item as CookwareItem).is_stuck():
		return "[按住 E] 清洗粘锅"
	if dirty_plate_count > 0:
		return "[按住 E] 连续清洗脏盘子"
	return ""


func begin_primary_interaction(player: Node) -> bool:
	if player.held_item is CookwareItem and (player.held_item as CookwareItem).is_stuck():
		active_wash_mode = WashMode.WOK
		hold_progress.begin(prototype_stuck_wok_wash_time)
		player.notify_feedback("清洗粘锅中；优先于脏盘，松开后进度归零")
		return true
	if dirty_plate_count <= 0:
		player.notify_feedback("水池中没有脏盘子；粘锅需手持清洗")
		return false
	active_wash_mode = WashMode.PLATES
	var multiplier := combat_config.get_plate_wash_multiplier(dirty_plate_count)
	locked_plate_wash_duration = combat_config.plate_wash_base_time * multiplier
	locked_plate_speed_tier = combat_config.get_plate_wash_tier_text(dirty_plate_count)
	hold_progress.begin(locked_plate_wash_duration)
	player.notify_feedback("开始连续洗盘：%s；松开当前盘进度归零" % locked_plate_speed_tier)
	_refresh_status()
	return true


func update_primary_interaction(player: Node, delta: float) -> bool:
	if active_wash_mode == WashMode.WOK:
		if not (player.held_item is CookwareItem) or not (player.held_item as CookwareItem).is_stuck():
			hold_progress.cancel()
			active_wash_mode = WashMode.NONE
			return false
		if hold_progress.advance(delta):
			(player.held_item as CookwareItem).clean_after_washing()
			active_wash_mode = WashMode.NONE
			player.notify_feedback("锅具清洗完成；仍在手中，请亲自带回任一空灶位")
			_refresh_status()
			return false
	if active_wash_mode == WashMode.PLATES:
		if dirty_plate_count <= 0:
			hold_progress.cancel()
			active_wash_mode = WashMode.NONE
			return false
		if hold_progress.advance(delta):
			dirty_plate_count -= 1
			if clean_plate_pile != null:
				clean_plate_pile.add_washed_plate(1)
			player.notify_feedback("洗净 1 个盘子；水池剩余 %d" % dirty_plate_count)
			_refresh_status()
			if dirty_plate_count > 0:
				hold_progress.begin(locked_plate_wash_duration)
				return true
			active_wash_mode = WashMode.NONE
			return false
	return true


func cancel_primary_interaction(player: Node) -> void:
	if active_wash_mode == WashMode.WOK:
		cancel_processing(player, "粘锅清洗中断：当前炒锅清洗进度归零")
	elif active_wash_mode == WashMode.PLATES:
		cancel_processing(player, "洗盘中断：当前盘子进度归零，已洗净盘子保留")
	active_wash_mode = WashMode.NONE
	_refresh_status()


func blocks_movement_during_primary() -> bool:
	return true


func get_debug_state() -> String:
	return "水池\n脏盘池：%d\n锁定速度：%s\n清洗进度：%d%%\n粘锅始终优先且不受脏盘加速" % [dirty_plate_count, locked_plate_speed_tier, roundi(get_progress_ratio() * 100.0)]


func _refresh_status() -> void:
	set_placeholder_status("脏盘 %d / %s" % [dirty_plate_count, locked_plate_speed_tier])


func reset_for_new_game() -> void:
	hold_progress.cancel()
	dirty_plate_count = 0
	active_wash_mode = WashMode.NONE
	locked_plate_wash_duration = 0.0
	locked_plate_speed_tier = "无"
	_refresh_status()
