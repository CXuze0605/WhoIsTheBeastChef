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


func record_enemy_defeated(is_special: bool) -> void:
	if not tracking_active:
		return
	if is_special:
		special_enemies_defeated += 1
	else:
		basic_enemies_defeated += 1
	stats_changed.emit()


func record_teammate_knocked_down() -> void:
	if not tracking_active:
		return
	teammates_knocked_down += 1
	stats_changed.emit()


func record_loot_spawned() -> void:
	if not tracking_active:
		return
	loot_spawned += 1
	stats_changed.emit()


func record_loot_picked_up() -> void:
	if not tracking_active:
		return
	loot_picked_up += 1
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
