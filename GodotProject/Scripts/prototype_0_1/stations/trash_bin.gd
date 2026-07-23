class_name TrashBin
extends Interactable

var destroyed_item_count: int = 0


func _ready() -> void:
	display_title = "垃圾桶"
	placeholder_size = Vector2(76.0, 78.0)
	placeholder_color = Color("4f5b57")
	super._ready()
	add_to_group("trash_bin")
	set_placeholder_status("手持物品后按 E 直接销毁")


func get_primary_prompt(player: Node) -> String:
	var target_player := player as PrototypePlayer
	if target_player == null or target_player.held_item == null:
		return "[E] 垃圾桶（当前未手持物品）"
	return "[E] 丢弃并销毁：%s" % target_player.held_item.data.display_name


func begin_primary_interaction(player: Node) -> bool:
	var target_player := player as PrototypePlayer
	if target_player == null or target_player.held_item == null:
		if target_player != null:
			target_player.notify_feedback("需要先在快捷栏选中要丢弃的物品")
		return false
	var item_name := target_player.held_item.data.display_name
	target_player.consume_held_item()
	destroyed_item_count += 1
	set_placeholder_status("已销毁 %d 件 / 堆物品" % destroyed_item_count)
	target_player.notify_feedback("垃圾桶已销毁：%s" % item_name)
	return false


func get_debug_state() -> String:
	return "垃圾桶\n已销毁：%d 件 / 堆" % destroyed_item_count
