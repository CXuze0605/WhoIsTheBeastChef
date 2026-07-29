class_name RunStats
extends Node

signal stats_changed

var tracking_active: bool = false
var dishes_created: int = 0
var total_damage_dealt: float = 0.0
var basic_enemies_defeated: int = 0
var special_enemies_defeated: int = 0
var friendly_fire_damage: float = 0.0
var teammates_knocked_down: int = 0
var loot_spawned: int = 0
var loot_picked_up: int = 0
var enemy_spawned_by_type: Dictionary = {}
var enemy_reflavored_by_type: Dictionary = {}
var enemy_spawned_by_rank: Dictionary = {}
var enemy_reflavored_by_rank: Dictionary = {}
var loot_spawned_by_item: Dictionary = {}
var loot_spawned_portions_by_item: Dictionary = {}
var loot_picked_up_by_item: Dictionary = {}
var loot_picked_up_portions_by_item: Dictionary = {}
var discarded_by_item: Dictionary = {}
var discarded_portions_by_item: Dictionary = {}
var consumed_resource_portions: Dictionary = {}
var shortage_seconds: Dictionary = {}
var compensation_trigger_count: int = 0
var compensation_items: Dictionary = {}
var compensation_portions: Dictionary = {}
var world_leftover_items: Dictionary = {}
var world_leftover_portions: Dictionary = {}
var end_resource_portions: Dictionary = {}
var small_rice_bag_potential_healing: float = 0.0
var natural_spoiled_items: int = 0
var natural_spoiled_food_units: int = 0
var rotten_waste_generated: int = 0
var rotten_waste_trashed: int = 0
var usable_food_trashed: int = 0
var rotten_waste_dropped: int = 0
var waste_units: int = 0
var final_waste_health_multiplier: float = 1.0
var final_waste_damage_multiplier: float = 1.0
var near_expiry_ingredients_processed: int = 0
var near_expiry_dishes_used: int = 0
var dishes_lost_to_spoilage: int = 0


func _ready() -> void:
	add_to_group("run_stats")
	reset_for_lobby()


func begin_run() -> void:
	_reset_values()
	tracking_active = true
	stats_changed.emit()


func finish_run() -> void:
	tracking_active = false
	stats_changed.emit()


func reset_for_lobby() -> void:
	tracking_active = false
	_reset_values()
	stats_changed.emit()


func record_dish_created(_dish_data: ItemData = null) -> void:
	if not tracking_active:
		return
	dishes_created += 1
	stats_changed.emit()


func record_damage(amount: float, attacker_faction: int, target_faction: int) -> void:
	if not tracking_active or amount <= 0.0 or attacker_faction != CombatRules.Faction.PLAYER:
		return
	if target_faction == CombatRules.Faction.ENEMY:
		total_damage_dealt += amount
	elif target_faction in [CombatRules.Faction.PLAYER, CombatRules.Faction.FRIENDLY]:
		friendly_fire_damage += amount
	stats_changed.emit()


func record_damage_context(context: DamageContext) -> void:
	if context == null:
		return
	record_damage(context.get_actual_damage(), context.attacker_faction, context.target_faction)


func record_enemy_spawned(enemy_type: StringName, enemy_rank: StringName = &"ordinary") -> void:
	if not tracking_active:
		return
	_increment(enemy_spawned_by_type, enemy_type, 1)
	_increment(enemy_spawned_by_rank, enemy_rank, 1)
	stats_changed.emit()


func record_enemy_defeated(is_special: bool, _enemy_type: StringName = &"basic", _enemy_rank: StringName = &"ordinary") -> void:
	if not tracking_active:
		return
	if is_special:
		special_enemies_defeated += 1
	else:
		basic_enemies_defeated += 1
	stats_changed.emit()


func record_enemy_reflavor_completed(enemy_type: StringName, enemy_rank: StringName = &"ordinary") -> void:
	if not tracking_active:
		return
	_increment(enemy_reflavored_by_type, enemy_type, 1)
	_increment(enemy_reflavored_by_rank, enemy_rank, 1)
	stats_changed.emit()


func record_teammate_knocked_down() -> void:
	if not tracking_active:
		return
	teammates_knocked_down += 1
	stats_changed.emit()


func record_loot_spawned(data: ItemData = null) -> void:
	if not tracking_active:
		return
	loot_spawned += 1
	if data != null:
		var key := _item_key(data)
		_increment(loot_spawned_by_item, key, 1)
		_increment(loot_spawned_portions_by_item, key, _resource_portions(data))
	stats_changed.emit()


func record_loot_picked_up(data: ItemData = null) -> void:
	if not tracking_active:
		return
	loot_picked_up += 1
	if data != null:
		var key := _item_key(data)
		_increment(loot_picked_up_by_item, key, 1)
		_increment(loot_picked_up_portions_by_item, key, _resource_portions(data))
	stats_changed.emit()


func record_item_discarded(data: ItemData) -> void:
	if not tracking_active or data == null:
		return
	var key := _item_key(data)
	_increment(discarded_by_item, key, 1)
	_increment(discarded_portions_by_item, key, _resource_portions(data))
	stats_changed.emit()


func record_resource_consumed(item_type: int, portions: int = 1) -> void:
	if not tracking_active or portions <= 0:
		return
	var key := _item_type_key(item_type)
	_increment(consumed_resource_portions, key, portions)
	stats_changed.emit()


func add_shortage_time(resource_key: StringName, seconds: float) -> void:
	if not tracking_active or seconds <= 0.0:
		return
	shortage_seconds[resource_key] = float(shortage_seconds.get(resource_key, 0.0)) + seconds


func record_compensation_spawn(data: ItemData, potential_healing: float = 0.0) -> void:
	if not tracking_active or data == null:
		return
	compensation_trigger_count += 1
	var key := _item_key(data)
	_increment(compensation_items, key, 1)
	_increment(compensation_portions, key, _resource_portions(data))
	small_rice_bag_potential_healing += maxf(0.0, potential_healing)
	stats_changed.emit()


func record_small_rice_bag_potential_healing(amount: float) -> void:
	if not tracking_active or amount <= 0.0:
		return
	small_rice_bag_potential_healing += amount
	stats_changed.emit()


func record_natural_spoilage(data: ItemData, food_units: int, was_dish: bool) -> void:
	if not tracking_active:
		return
	natural_spoiled_items += 1
	natural_spoiled_food_units += maxi(0, food_units)
	rotten_waste_generated += 1
	if was_dish:
		dishes_lost_to_spoilage += 1
	stats_changed.emit()


func record_food_waste(data: ItemData, amount: int, reason: StringName) -> void:
	if not tracking_active or data == null or amount <= 0:
		return
	waste_units += amount
	if data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		if reason == &"trash":
			rotten_waste_trashed += 1
		elif reason in [&"drop", &"natural_world_spoilage"]:
			rotten_waste_dropped += 1
	elif reason == &"trash":
		usable_food_trashed += 1
	final_waste_health_multiplier = FreshnessCatalog.get_health_multiplier(waste_units)
	final_waste_damage_multiplier = FreshnessCatalog.get_damage_multiplier(waste_units)
	stats_changed.emit()


func record_near_expiry_processed() -> void:
	if tracking_active:
		near_expiry_ingredients_processed += 1
		stats_changed.emit()


func record_near_expiry_dish_used() -> void:
	if tracking_active:
		near_expiry_dishes_used += 1
		stats_changed.emit()


func capture_resource_end_state(supply: Dictionary, world_items: Dictionary, world_portions: Dictionary) -> void:
	if not tracking_active:
		return
	end_resource_portions = supply.duplicate(true)
	world_leftover_items = world_items.duplicate(true)
	world_leftover_portions = world_portions.duplicate(true)
	stats_changed.emit()


func get_snapshot() -> Dictionary:
	return {
		"dishes_created": dishes_created,
		"total_damage_dealt": total_damage_dealt,
		"basic_enemies_defeated": basic_enemies_defeated,
		"special_enemies_defeated": special_enemies_defeated,
		"friendly_fire_damage": friendly_fire_damage,
		"teammates_knocked_down": teammates_knocked_down,
		"loot_spawned": loot_spawned,
		"loot_picked_up": loot_picked_up,
		"enemy_spawned_by_type": enemy_spawned_by_type.duplicate(true),
		"enemy_reflavored_by_type": enemy_reflavored_by_type.duplicate(true),
		"enemy_spawned_by_rank": enemy_spawned_by_rank.duplicate(true),
		"enemy_reflavored_by_rank": enemy_reflavored_by_rank.duplicate(true),
		"loot_spawned_by_item": loot_spawned_by_item.duplicate(true),
		"loot_spawned_portions_by_item": loot_spawned_portions_by_item.duplicate(true),
		"loot_picked_up_by_item": loot_picked_up_by_item.duplicate(true),
		"loot_picked_up_portions_by_item": loot_picked_up_portions_by_item.duplicate(true),
		"discarded_by_item": discarded_by_item.duplicate(true),
		"discarded_portions_by_item": discarded_portions_by_item.duplicate(true),
		"consumed_resource_portions": consumed_resource_portions.duplicate(true),
		"shortage_seconds": shortage_seconds.duplicate(true),
		"compensation_trigger_count": compensation_trigger_count,
		"compensation_items": compensation_items.duplicate(true),
		"compensation_portions": compensation_portions.duplicate(true),
		"world_leftover_items": world_leftover_items.duplicate(true),
		"world_leftover_portions": world_leftover_portions.duplicate(true),
		"end_resource_portions": end_resource_portions.duplicate(true),
		"small_rice_bag_potential_healing": small_rice_bag_potential_healing,
		"natural_spoiled_items": natural_spoiled_items,
		"natural_spoiled_food_units": natural_spoiled_food_units,
		"rotten_waste_generated": rotten_waste_generated,
		"rotten_waste_trashed": rotten_waste_trashed,
		"usable_food_trashed": usable_food_trashed,
		"rotten_waste_dropped": rotten_waste_dropped,
		"waste_units": waste_units,
		"final_waste_health_multiplier": final_waste_health_multiplier,
		"final_waste_damage_multiplier": final_waste_damage_multiplier,
		"near_expiry_ingredients_processed": near_expiry_ingredients_processed,
		"near_expiry_dishes_used": near_expiry_dishes_used,
		"dishes_lost_to_spoilage": dishes_lost_to_spoilage,
	}


func _reset_values() -> void:
	dishes_created = 0
	total_damage_dealt = 0.0
	basic_enemies_defeated = 0
	special_enemies_defeated = 0
	friendly_fire_damage = 0.0
	teammates_knocked_down = 0
	loot_spawned = 0
	loot_picked_up = 0
	enemy_spawned_by_type.clear()
	enemy_reflavored_by_type.clear()
	enemy_spawned_by_rank.clear()
	enemy_reflavored_by_rank.clear()
	loot_spawned_by_item.clear()
	loot_spawned_portions_by_item.clear()
	loot_picked_up_by_item.clear()
	loot_picked_up_portions_by_item.clear()
	discarded_by_item.clear()
	discarded_portions_by_item.clear()
	consumed_resource_portions.clear()
	shortage_seconds.clear()
	compensation_trigger_count = 0
	compensation_items.clear()
	compensation_portions.clear()
	world_leftover_items.clear()
	world_leftover_portions.clear()
	end_resource_portions.clear()
	small_rice_bag_potential_healing = 0.0
	natural_spoiled_items = 0
	natural_spoiled_food_units = 0
	rotten_waste_generated = 0
	rotten_waste_trashed = 0
	usable_food_trashed = 0
	rotten_waste_dropped = 0
	waste_units = 0
	final_waste_health_multiplier = 1.0
	final_waste_damage_multiplier = 1.0
	near_expiry_ingredients_processed = 0
	near_expiry_dishes_used = 0
	dishes_lost_to_spoilage = 0


func _increment(target: Dictionary, key: Variant, amount: int) -> void:
	target[key] = int(target.get(key, 0)) + amount


func _item_key(data: ItemData) -> StringName:
	return _item_type_key(data.item_type)


func _item_type_key(item_type: int) -> StringName:
	var keys := ItemData.ItemType.keys()
	return StringName(str(keys[item_type]).to_lower()) if item_type >= 0 and item_type < keys.size() else &"unknown"


func _resource_portions(data: ItemData) -> int:
	if data.is_reusable_resource_container():
		return maxi(0, data.remaining_portions)
	return maxi(1, data.stack_count)
