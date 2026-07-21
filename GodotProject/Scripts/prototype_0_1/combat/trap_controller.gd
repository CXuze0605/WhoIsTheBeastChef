class_name TrapController
extends Node

var player: PrototypePlayer
var combat_manager: CombatManager
var navigation: KitchenNavigationGrid


func _ready() -> void:
	player = get_parent() as PrototypePlayer
	call_deferred("_resolve_runtime")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("place_trap"):
		place_selected_shabu()
		get_viewport().set_input_as_handled()


func place_selected_shabu() -> bool:
	if player == null or player.modal_ui_open or player.action_stun_left > 0.0:
		return false
	if combat_manager == null or navigation == null:
		_resolve_runtime()
	if combat_manager == null or navigation == null:
		player.notify_feedback("陷阱运行节点未就绪")
		return false
	var item := player.held_item
	if item == null or item.data.item_type != ItemData.ItemType.SHABU_BEEF:
		return false
	var placement := player.global_position + player.facing_direction * combat_manager.config.shabu_place_distance
	if not navigation.is_position_walkable(placement):
		player.notify_feedback("这里不能放置涮牛肉")
		return false
	var trap := ShabuTrap.new()
	trap.setup(item.data, combat_manager.config)
	get_tree().current_scene.add_child(trap)
	trap.global_position = placement
	item.data.consume_stack_unit()
	if item.data.stack_count <= 0:
		var removed := player.inventory.take_selected_item()
		if removed != null:
			removed.queue_free()
	else:
		item.refresh_visual()
		player.inventory.notify_item_changed()
	player.notify_feedback("放置 1 片涮牛肉诱食陷阱（临时餐垫，不消耗正式盘子）")
	return true


func _resolve_runtime() -> void:
	combat_manager = get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	navigation = get_tree().get_first_node_in_group("kitchen_navigation") as KitchenNavigationGrid
