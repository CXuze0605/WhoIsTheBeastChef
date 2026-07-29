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
		place_selected_deployable()
		get_viewport().set_input_as_handled()


func place_selected_deployable() -> bool:
	if player == null or player.held_item == null:
		return false
	match player.held_item.data.item_type:
		ItemData.ItemType.SHABU_BEEF:
			return place_selected_shabu()
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE, ItemData.ItemType.PLATED_VEGETABLE_RICE, \
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_BEEF_BRAISED_RICE, \
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE:
			return deploy_selected_vegetable_rice()
		ItemData.ItemType.UNPLATED_SOAKED_RICE, ItemData.ItemType.PLATED_SOAKED_RICE, \
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_SOAKED_RICE, \
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_BEEF_SOAKED_RICE, \
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE:
			return pour_selected_soaked_rice()
		ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL, \
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL, ItemData.ItemType.PLATED_GREENS_RICE_BOWL, \
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL, ItemData.ItemType.PLATED_BEEF_RICE_BOWL:
			return deploy_selected_rice_bowl_turret()
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF, ItemData.ItemType.PLATED_CRISPY_RICE_BEEF:
			return deploy_selected_crispy_beef_bomb()
	return false


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


func deploy_selected_vegetable_rice() -> bool:
	if not _can_deploy():
		return false
	var item := player.held_item
	if item == null or item.data.current_durability <= 0:
		return false
	var placement := player.global_position + player.facing_direction * combat_manager.config.rice_zone_throw_distance * 0.45
	if not navigation.is_position_walkable(placement):
		player.notify_feedback("这里不能部署菜饭补给点")
		return false
	var removed := player.take_selected_item_node()
	if removed == null:
		return false
	var station := VegetableRiceStation.new()
	station.setup(removed.data)
	get_tree().current_scene.add_child(station)
	station.global_position = placement
	removed.queue_free()
	player.notify_feedback("已部署菜饭：进入用餐区域后按住 %s 恢复护盾" % InputPrompt.action_text(&"interact_primary", "E"))
	return true


func pour_selected_soaked_rice() -> bool:
	if not _can_deploy():
		return false
	var item := player.held_item
	if item == null or item.data.current_durability <= 0:
		return false
	var placement := player.global_position + player.facing_direction * combat_manager.config.rice_zone_throw_distance
	if not navigation.is_position_walkable(placement):
		player.notify_feedback("这里不能泼洒泡饭")
		return false
	var is_final := item.data.current_durability == 1
	var perfect := is_final and item.data.quality == ItemData.Quality.PERFECT
	var zone_data := ItemCatalog.duplicate_data(item.data)
	var zone := RiceEffectZone.new()
	zone.setup(placement, zone_data, combat_manager.config, perfect)
	get_tree().current_scene.add_child(zone)
	item.data.current_durability -= 1
	item.data.mark_used()
	if item.data.current_durability <= 0:
		var depleted := player.take_selected_item_node()
		if depleted != null:
			_spawn_dirty_plate_if_needed(depleted.data)
			depleted.queue_free()
	else:
		item.refresh_visual()
		player.inventory.notify_item_changed()
	player.notify_feedback("泼洒%s：区域内敌我单位均受影响" % item.data.display_name)
	return true


func deploy_selected_rice_bowl_turret() -> bool:
	if not _can_deploy():
		return false
	var item := player.held_item
	if item == null or item.data.current_durability <= 0:
		return false
	var placement := player.global_position + player.facing_direction * 82.0
	if not navigation.is_position_walkable(placement):
		player.notify_feedback("这里不能部署盖饭炮台")
		return false
	var removed := player.take_selected_item_node()
	if removed == null:
		return false
	var turret := RiceBowlTurret.new()
	turret.setup(removed.data, combat_manager.config)
	get_tree().current_scene.add_child(turret)
	turret.global_position = placement
	removed.queue_free()
	player.notify_feedback("盖饭炮台已部署：无敌人不空射，每三发随机袋包含三种弹药")
	return true


func deploy_selected_crispy_beef_bomb() -> bool:
	if not _can_deploy():
		return false
	var item := player.held_item
	if item == null or item.data.current_durability <= 0:
		return false
	var placement := player.global_position + player.facing_direction * combat_manager.config.crispy_beef_place_distance
	if not navigation.is_position_walkable(placement):
		player.notify_feedback("这里不能布置锅巴牛肉")
		return false
	var removed := player.take_selected_item_node()
	if removed == null:
		return false
	var bomb_data := ItemCatalog.duplicate_data(removed.data)
	bomb_data.mark_used()
	var perfect_snapshot := (
		bomb_data.item_type == ItemData.ItemType.PLATED_CRISPY_RICE_BEEF
		and bomb_data.quality == ItemData.Quality.PERFECT
	)
	var bomb := CrispyBeefBomb.new()
	bomb.setup_main(
		bomb_data,
		player,
		combat_manager.config,
		perfect_snapshot,
		maxi(1, bomb_data.source_recipe_instance_id)
	)
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = placement
	_spawn_dirty_plate_if_needed(removed.data)
	removed.queue_free()
	player.notify_feedback(
		"锅巴牛肉已布置：%.1f秒后可触发，注意友军伤害"
		% combat_manager.config.crispy_beef_main_arm_time
	)
	return true


func _can_deploy() -> bool:
	if player == null or player.modal_ui_open or player.action_stun_left > 0.0:
		return false
	if combat_manager == null or navigation == null:
		_resolve_runtime()
	if combat_manager == null or navigation == null:
		player.notify_feedback("部署运行节点未就绪")
		return false
	return true


func _spawn_dirty_plate_if_needed(data: ItemData) -> void:
	if data == null or data.carried_plate_state != ItemData.PlateState.CLEAN:
		return
	var plate := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE))
	get_tree().current_scene.add_child(plate)
	plate.release_to_world(
		get_tree().current_scene,
		player.global_position + player.facing_direction * 42.0
	)


func _resolve_runtime() -> void:
	combat_manager = get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	navigation = get_tree().get_first_node_in_group("kitchen_navigation") as KitchenNavigationGrid
