class_name AutoDishEquipmentController
extends Node

const MustardMarkerScript := preload("res://Scripts/prototype_0_1/combat/mustard_target_marker.gd")

var player: PrototypePlayer
var config := PrototypeCombatConfig.new()
var soup_streams: Dictionary = {}
var previous_mustard_sources: Dictionary = {}


func setup(owner_player: PrototypePlayer) -> void:
	player = owner_player


func _ready() -> void:
	add_to_group("auto_dish_controller")
	var combat := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat != null:
		config = combat.config


func _process(_delta: float) -> void:
	if player == null:
		return
	_update_soup_streams()
	_update_mustard_sources()


func toggle_auto_equipment(item: CarryableItem) -> bool:
	if item == null or item.data == null or item.data.recipe_id not in [
		ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
		ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
	]:
		return false
	if not _is_carried(item):
		return false
	item.data.auto_equipment_enabled = not item.data.auto_equipment_enabled
	item.data.deployment_state = (
		ItemData.DeploymentState.CARRIED_ENABLED
		if item.data.auto_equipment_enabled
		else ItemData.DeploymentState.CARRIED_DISABLED
	)
	item.refresh_visual()
	player.inventory.notify_item_changed()
	if player.backpack != null:
		player.backpack.changed.emit()
	player.notify_feedback("青菜牛肉汤自动喷流：%s" % ("开启" if item.data.auto_equipment_enabled else "关闭"))
	return true


func register_mustard_target(item: CarryableItem, target: Node) -> bool:
	if item == null or target == null or not _is_carried(item) or is_target_marked_by_any(target):
		return false
	var target_id := target.get_instance_id()
	if target_id not in item.data.linked_target_ids:
		item.data.linked_target_ids.append(target_id)
	item.data.deployment_state = ItemData.DeploymentState.EFFECT_MAINTENANCE
	var source_id := "mustard_greens_%d" % item.data.source_recipe_instance_id
	var marker := MustardMarkerScript.new()
	marker.setup(source_id)
	target.add_child(marker)
	return true


func is_target_marked_by_any(target: Node) -> bool:
	if target == null:
		return false
	var target_id := target.get_instance_id()
	for item in _carried_items():
		if item.data.recipe_id == ExpandedRecipeCatalog.MUSTARD_GREENS and target_id in item.data.linked_target_ids:
			return true
	return false


func _update_soup_streams() -> void:
	var active_ids: Dictionary = {}
	var display_index := 0
	for item in _carried_items():
		if item.data.recipe_id not in [
			ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
			ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
			ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
		] or not item.data.auto_equipment_enabled or item.data.current_durability <= 0:
			continue
		var item_id := item.get_instance_id()
		active_ids[item_id] = true
		if not soup_streams.has(item_id) or not is_instance_valid(soup_streams[item_id]):
			var stream := BeefGreensSoupStream.new()
			stream.setup(player, item, config, display_index, _on_soup_depleted)
			player.add_child(stream)
			soup_streams[item_id] = stream
		else:
			(soup_streams[item_id] as BeefGreensSoupStream).display_index = display_index
		display_index += 1
	for item_id in soup_streams.keys():
		if active_ids.has(item_id):
			continue
		var stream: Node = soup_streams[item_id]
		if is_instance_valid(stream):
			var source := (stream as BeefGreensSoupStream).source_item
			if source != null and is_instance_valid(source):
				source.data.auto_equipment_enabled = false
				source.data.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
			stream.queue_free()
		soup_streams.erase(item_id)


func _update_mustard_sources() -> void:
	var current_sources: Dictionary = {}
	var carried := _carried_items()
	for item in carried:
		if item.data.recipe_id != ExpandedRecipeCatalog.MUSTARD_GREENS:
			continue
		var source_id := "mustard_greens_%d" % item.data.source_recipe_instance_id
		current_sources[source_id] = item
		_remove_status_source_everywhere(source_id)
		_apply_mustard_carry_curse(item, source_id)
		var alive_ids: Array[int] = []
		for target_id in item.data.linked_target_ids:
			var target := instance_from_id(target_id) as Node
			if not _is_alive_enemy(target):
				continue
			alive_ids.append(target_id)
			_apply_mustard_aura(item, target, source_id)
			_apply_mustard_primary(item, target, source_id)
		item.data.linked_target_ids = alive_ids
		if item.data.current_durability <= 0 and alive_ids.is_empty():
			_replace_item_with_dirty_plate(item)
	for old_source in previous_mustard_sources.keys():
		if not current_sources.has(old_source):
			_remove_status_source_everywhere(old_source)
			var old_item := previous_mustard_sources[old_source] as CarryableItem
			if old_item != null and is_instance_valid(old_item):
				old_item.data.linked_target_ids.clear()
				old_item.data.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
	previous_mustard_sources = current_sources


func _apply_mustard_carry_curse(item: CarryableItem, source_id: String) -> void:
	player.combat_statuses.apply_status(
		CombatStatusController.StatusType.VULNERABILITY,
		source_id,
		float(item.data.effect_values.get("carrier_vulnerability", config.mustard_carrier_vulnerability)),
		0.0,
		true
	)
	var teammate := _nearest_other_player()
	if teammate != null:
		CombatStatusController.ensure_on(teammate).apply_status(
			CombatStatusController.StatusType.MOVE_SLOW,
			source_id,
			float(item.data.effect_values.get("nearest_teammate_slow", config.mustard_nearest_teammate_slow)),
			0.0,
			true
		)


func _apply_mustard_aura(item: CarryableItem, primary: Node, source_id: String) -> void:
	var radius := float(item.data.effect_values.get("aura_radius", config.mustard_aura_radius))
	for candidate in get_tree().get_nodes_in_group("damageable"):
		if candidate == primary or not _is_alive_enemy(candidate) or primary.global_position.distance_to(candidate.global_position) > radius:
			continue
		var statuses := CombatStatusController.ensure_on(candidate)
		statuses.apply_status(CombatStatusController.StatusType.MOVE_SLOW, source_id, float(item.data.effect_values.get("aura_move_slow", config.mustard_aura_move_slow)), 0.0, true)
		statuses.apply_status(CombatStatusController.StatusType.VULNERABILITY, source_id, float(item.data.effect_values.get("aura_vulnerability", config.mustard_aura_vulnerability)), 0.0, true)


func _apply_mustard_primary(item: CarryableItem, target: Node, source_id: String) -> void:
	var statuses := CombatStatusController.ensure_on(target)
	statuses.apply_status(CombatStatusController.StatusType.WEAKNESS, source_id, float(item.data.effect_values.get("primary_weakness", config.mustard_primary_weakness)), 0.0, true)
	statuses.apply_status(CombatStatusController.StatusType.MOVE_SLOW, source_id, float(item.data.effect_values.get("primary_move_slow", config.mustard_primary_move_slow)), 0.0, true)
	statuses.apply_status(CombatStatusController.StatusType.ATTACK_SPEED_SLOW, source_id, float(item.data.effect_values.get("primary_attack_slow", config.mustard_primary_attack_slow)), 0.0, true)
	statuses.apply_status(CombatStatusController.StatusType.VULNERABILITY, source_id, float(item.data.effect_values.get("primary_vulnerability", config.mustard_primary_vulnerability)), 0.0, true)


func _nearest_other_player() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("player_target"):
		if candidate == player or not candidate is Node2D:
			continue
		var distance := player.global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _remove_status_source_everywhere(source_id: String) -> void:
	for candidate in get_tree().get_nodes_in_group("damageable"):
		var statuses := candidate.get_node_or_null("CombatStatusController") as CombatStatusController
		if statuses != null:
			statuses.remove_source(source_id)
	for marker in get_tree().get_nodes_in_group("mustard_target_marker"):
		if str(marker.get("source_id")) == source_id:
			marker.queue_free()


func _on_soup_depleted(item: CarryableItem) -> void:
	_replace_or_remove_depleted(item)


func _replace_or_remove_depleted(item: CarryableItem) -> void:
	if item == null or not is_instance_valid(item):
		return
	if item.data.carried_plate_state == ItemData.PlateState.CLEAN:
		item.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
		item.refresh_visual()
		player.inventory.notify_item_changed()
		if player.backpack != null:
			player.backpack.changed.emit()
	else:
		_remove_carried_item(item)


func _replace_item_with_dirty_plate(item: CarryableItem) -> void:
	if item == null or not is_instance_valid(item):
		return
	item.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
	item.refresh_visual()
	player.inventory.notify_item_changed()
	if player.backpack != null:
		player.backpack.changed.emit()


func _remove_carried_item(item: CarryableItem) -> void:
	for slot_index in QuickInventory.SLOT_COUNT:
		if player.inventory.get_item(slot_index) == item:
			player.inventory.take_item(slot_index)
			item.queue_free()
			return
	if player.backpack != null:
		var placement := player.backpack.remove_item(item)
		if placement != null:
			item.queue_free()


func _is_carried(item: CarryableItem) -> bool:
	return item in _carried_items()


func _carried_items() -> Array[CarryableItem]:
	var result: Array[CarryableItem] = []
	for item in player.inventory.slots:
		if item != null:
			result.append(item)
	if player.backpack != null:
		for item in player.backpack.get_items():
			if item not in result:
				result.append(item)
	return result


func _is_alive_enemy(candidate: Node) -> bool:
	if (
		candidate == null
		or not is_instance_valid(candidate)
		or not candidate.has_method("get_combat_faction")
		or int(candidate.get_combat_faction()) != CombatRules.Faction.ENEMY
	):
		return false
	if "current_health" in candidate:
		return float(candidate.get("current_health")) > 0.0
	return true


func reset_for_new_game() -> void:
	for source_id in previous_mustard_sources.keys():
		_remove_status_source_everywhere(source_id)
	previous_mustard_sources.clear()
	for stream in soup_streams.values():
		if is_instance_valid(stream):
			stream.queue_free()
	soup_streams.clear()
