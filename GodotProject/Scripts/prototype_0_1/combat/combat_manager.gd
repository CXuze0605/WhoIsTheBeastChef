class_name CombatManager
extends Node2D

var config := PrototypeCombatConfig.new()
var normal_bulls_spawned: int = 0
var raging_bulls_spawned: int = 0
var melee_swings_spawned: int = 0
var big_bones_spawned: int = 0


func _ready() -> void:
	add_to_group("combat_runtime")


func spawn_normal_bull(origin: Vector2, direction: Vector2, damage: float, on_hit_effect: StatusEffectData = null) -> NormalBull:
	var bull := NormalBull.new()
	bull.setup(origin, direction, damage, config, CombatRules.Faction.PLAYER, on_hit_effect)
	add_child(bull)
	normal_bulls_spawned += 1
	return bull


func spawn_raging_bull(origin: Vector2, direction: Vector2) -> RagingBull:
	var bull := RagingBull.new()
	bull.setup(origin, direction, config)
	add_child(bull)
	raging_bulls_spawned += 1
	return bull


func spawn_melee_swing(origin: Vector2, direction: Vector2, item_data: ItemData) -> MeleeSwing:
	var swing := MeleeSwing.new()
	swing.setup(origin, direction, item_data, config)
	add_child(swing)
	melee_swings_spawned += 1
	return swing


func spawn_big_bone(origin: Vector2, direction: Vector2, callback: Callable) -> BigBoneProjectile:
	var bone := BigBoneProjectile.new()
	bone.setup(origin, direction, config, callback)
	add_child(bone)
	big_bones_spawned += 1
	return bone


func reset_for_new_game() -> void:
	clear_active_attacks()
	normal_bulls_spawned = 0
	raging_bulls_spawned = 0
	melee_swings_spawned = 0
	big_bones_spawned = 0


func clear_active_attacks() -> void:
	for child in get_children():
		if child is NormalBull or child is RagingBull or child is MeleeSwing or child is BigBoneProjectile:
			child.queue_free()
