class_name TrashBin
extends Interactable

var destroyed_item_count: int = 0


func _ready() -> void:
	display_title = "垃圾桶"
	placeholder_size = Vector2(76.0, 78.0)
	placeholder_color = Color("4f5b57")
	super._ready()
	add_to_group("trash_bin")
	set_placeholder_status("手持物品后按 %s 直接销毁" % InputPrompt.action_text(&"interact_primary", "E"))


func get_primary_prompt(player: Node) -> String:
	var target_player := player as PrototypePlayer
	if target_player == null or target_player.held_item == null:
		return "[%s] 垃圾桶（当前未手持物品）" % InputPrompt.action_text(&"interact_primary", "E")
	return "[%s] 丢弃并销毁：%s" % [InputPrompt.action_text(&"interact_primary", "E"), target_player.held_item.data.display_name]


func begin_primary_interaction(player: Node) -> bool:
	var target_player := player as PrototypePlayer
	if target_player == null or target_player.held_item == null:
		if target_player != null:
			target_player.notify_feedback("需要先在快捷栏选中要丢弃的物品")
		return false
	var item_name := target_player.held_item.data.display_name
	var freshness := get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
	if freshness != null:
		freshness.settle_waste(target_player.held_item.data, &"trash")
	target_player.record_discarded_item(target_player.held_item.data)
	target_player.consume_held_item()
	destroyed_item_count += 1
	set_placeholder_status("已销毁 %d 件 / 堆物品" % destroyed_item_count)
	target_player.notify_feedback("垃圾桶已销毁：%s" % item_name)
	return false


func get_debug_state() -> String:
	return "垃圾桶\n已销毁：%d 件 / 堆" % destroyed_item_count
