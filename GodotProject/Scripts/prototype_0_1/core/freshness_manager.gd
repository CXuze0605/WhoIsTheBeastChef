class_name FreshnessManager
extends Node

signal freshness_state_changed(data: ItemData, previous_state: int, current_state: int)
signal waste_changed(waste_units: int, health_multiplier: float, damage_multiplier: float)

const SCAN_INTERVAL := 0.20

var run_active: bool = false
var formal_elapsed: float = 0.0
var scan_left: float = 0.0
var waste_units: int = 0
var run_stats: RunStats


func _ready() -> void:
	add_to_group("freshness_manager")
	run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats


func _process(delta: float) -> void:
	if not run_active:
		return
	formal_elapsed += delta
	scan_left -= delta
	if scan_left > 0.0:
		return
	scan_left = SCAN_INTERVAL
	process_all_items_now()


func begin_formal_run() -> void:
	formal_elapsed = 0.0
	waste_units = 0
	run_active = true
	scan_left = 0.0
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	waste_changed.emit(waste_units, get_enemy_health_multiplier(), get_enemy_damage_multiplier())


func stop_for_lobby() -> void:
	run_active = false
	formal_elapsed = 0.0
	waste_units = 0
	scan_left = 0.0
	waste_changed.emit(waste_units, 1.0, 1.0)


func finish_formal_run() -> void:
	process_all_items_now()
	run_active = false


func process_all_items_now() -> void:
	if not run_active:
		return
	var records := _collect_live_item_records()
	for record in records.values():
		_process_record(record)


func advance_for_test(seconds: float) -> void:
	if not run_active or seconds <= 0.0:
		return
	formal_elapsed += seconds
	process_all_items_now()


func settle_waste(data: ItemData, reason: StringName = &"trash") -> int:
	if data == null or data.waste_penalty_settled:
		return 0
	data.waste_penalty_settled = true
	if not run_active:
		return 0
	var amount := FreshnessCatalog.get_waste_units(data)
	if amount <= 0:
		return 0
	waste_units += amount
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.record_food_waste(data, amount, reason)
	var health_bonus := (get_enemy_health_multiplier() - 1.0) * 100.0
	var damage_bonus := (get_enemy_damage_multiplier() - 1.0) * 100.0
	_notify_player("浪费粮食 +%d｜累计浪费 %d｜后续味真族生命 +%.1f%%，伤害 +%.1f%%" % [
		amount, waste_units, health_bonus, damage_bonus,
	])
	waste_changed.emit(waste_units, get_enemy_health_multiplier(), get_enemy_damage_multiplier())
	return amount


func get_enemy_health_multiplier() -> float:
	return FreshnessCatalog.get_health_multiplier(waste_units)


func get_enemy_damage_multiplier() -> float:
	return FreshnessCatalog.get_damage_multiplier(waste_units)


func get_debug_summary() -> String:
	return "新鲜度时钟：%s %.1fs\n累计浪费：%d\n后续味真族：生命×%.3f / 伤害×%.3f" % [
		"运行" if run_active else "停止",
		formal_elapsed,
		waste_units,
		get_enemy_health_multiplier(),
		get_enemy_damage_multiplier(),
	]


func _process_record(record: Dictionary) -> void:
	var data := record.get("data") as ItemData
	var owner := record.get("owner") as Node
	if data == null or data.item_type == ItemData.ItemType.ROTTEN_WASTE or not data.is_perishable():
		return
	if data.freshness_clock_stamp < 0.0:
		data.freshness_clock_stamp = formal_elapsed
		return
	var elapsed := maxf(0.0, formal_elapsed - data.freshness_clock_stamp)
	data.freshness_clock_stamp = formal_elapsed
	var pause_reason := _get_pause_reason(owner, data)
	data.freshness_pause_reason = pause_reason
	if not pause_reason.is_empty() or elapsed <= 0.0:
		return
	var previous_state := data.get_freshness_state()
	data.advance_spoilage(elapsed)
	var current_state := data.get_freshness_state()
	if current_state != previous_state:
		if current_state == ItemData.FreshnessState.NEAR_EXPIRY:
			_refresh_quality_dependent_stats(data)
		freshness_state_changed.emit(data, previous_state, current_state)
		_refresh_owner(owner)
	if current_state == ItemData.FreshnessState.ROTTEN:
		_convert_to_rotten(data, owner)


func _convert_to_rotten(data: ItemData, owner: Node) -> void:
	if data == null or data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		return
	var original_type := data.item_type
	var original_name := data.display_name
	var was_dish := FreshnessCatalog.is_dish_type(original_type)
	data.rotten_source_item_type = original_type
	data.rotten_source_name = original_name
	data.rotten_source_art_key = ItemCatalog.get_art_key_for_data(data)
	data.rotten_shape_cells = ItemStorageCatalog.get_shape_cells_for_data(data, false)
	data.waste_source_units = FreshnessCatalog.get_actual_units(data)
	data.waste_units_snapshot = FreshnessCatalog.get_waste_units(data)
	data.item_type = ItemData.ItemType.ROTTEN_WASTE
	data.display_name = "腐败物（%s）" % original_name
	data.processing_state = ItemData.ProcessingState.OVERCOOKED
	data.is_ingredient = false
	data.is_auxiliary = false
	data.is_cookware = false
	data.allowed_stations.clear()
	data.is_stackable = false
	data.stack_count = 1
	data.max_stack_count = 1
	data.recipe_id = &""
	data.components.clear()
	data.active_modifiers.clear()
	data.attack_form = ItemData.AttackForm.NONE
	data.cooking_method = ItemData.CookingMethod.NONE
	data.can_be_plated = false
	data.is_combat_dish = false
	data.current_durability = 0
	data.max_durability = 0
	data.base_damage = 0.0
	data.actual_damage = 0.0
	data.has_perfect_finisher = false
	data.emergency_edible = false
	data.auto_equipment_enabled = false
	data.deployment_state = ItemData.DeploymentState.NONE
	data.freshness_lifetime = 0.0
	data.spoilage_ratio = 1.0
	data.freshness_pause_reason = ""
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.record_natural_spoilage(data, data.waste_source_units, was_dish)
	_notify_owner_rotten(owner, data)
	if owner is CarryableItem:
		var item := owner as CarryableItem
		item.refresh_visual()
		if item.pickup_enabled and item.get_parent() == get_tree().current_scene:
			settle_waste(data, &"natural_world_spoilage")
	else:
		_replace_deployable_with_world_waste(owner, data)


func _replace_deployable_with_world_waste(owner: Node, data: ItemData) -> void:
	if owner == null or owner is WokStation:
		return
	if owner is Node2D and (owner.is_in_group("run_deployable") or owner is ShabuTrap):
		var item := ItemFactory.create_carryable(data)
		get_tree().current_scene.add_child(item)
		item.release_to_world(get_tree().current_scene, (owner as Node2D).global_position)
		settle_waste(data, &"natural_world_spoilage")
		owner.queue_free()


func _refresh_quality_dependent_stats(data: ItemData) -> void:
	if data == null or not data.is_combat_dish:
		return
	var previous_durability := data.current_durability
	var was_used := data.has_been_used
	var config := PrototypeCombatConfig.new()
	match data.item_type:
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			config.apply_combat_dish_stats(data)
		ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			config.apply_tomahawk_stats(data)
		ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE:
			config.apply_white_rice_stats(data)
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE, ItemData.ItemType.PLATED_RICE_PORRIDGE:
			config.apply_rice_porridge_stats(data)
		ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE:
			config.apply_crispy_rice_stats(data)
		_:
			ExpandedRecipeCatalog.refresh_after_plating(data, config)
	data.current_durability = mini(previous_durability, data.max_durability)
	data.has_been_used = was_used
	data.has_perfect_finisher = false


func _collect_live_item_records() -> Dictionary:
	var records := {}
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is CarryableItem and is_instance_valid(node):
			var item := node as CarryableItem
			_add_record(records, item.data, item)
	for node in get_tree().get_nodes_in_group("stove_station"):
		if node is WokStation:
			var station := node as WokStation
			_add_record(records, station.get_freshness_content_data(), station)
	for node in get_tree().get_nodes_in_group("run_deployable"):
		if node != null and is_instance_valid(node):
			_add_record(records, node.get("dish_data") as ItemData, node)
	for node in get_tree().get_nodes_in_group("shabu_trap"):
		if node is ShabuTrap:
			_add_record(records, (node as ShabuTrap).serving_data, node)
	return records


func _add_record(records: Dictionary, data: ItemData, owner: Node) -> void:
	if data == null:
		return
	var key := data.get_instance_id()
	if not records.has(key):
		records[key] = {"data": data, "owner": owner}


func _get_pause_reason(owner: Node, data: ItemData) -> String:
	if owner != null and owner.has_method("get_freshness_pause_reason"):
		return str(owner.call("get_freshness_pause_reason", data))
	return ""


func _notify_owner_rotten(owner: Node, data: ItemData) -> void:
	if owner != null and owner.has_method("handle_rotten_item_data"):
		owner.call("handle_rotten_item_data", data)
	if owner is CarryableItem:
		var parent := owner.get_parent()
		if parent != null and parent.has_method("handle_rotten_item_data"):
			parent.call("handle_rotten_item_data", data)


func _refresh_owner(owner: Node) -> void:
	if owner is CarryableItem:
		(owner as CarryableItem).refresh_visual()
	elif owner != null and owner.has_method("refresh_visual"):
		owner.call("refresh_visual")


func _notify_player(message: String) -> void:
	var player := get_tree().get_first_node_in_group("player_target") as PrototypePlayer
	if player != null:
		player.notify_feedback(message)
