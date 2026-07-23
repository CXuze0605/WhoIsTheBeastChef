class_name PrototypeWaveConfig
extends Resource

# Prototype 0.3.1 centralized test values. None of these are final balance or final map design.
@export_category("Preparation and wave")
@export var preparation_time: float = 32.0
@export var global_warning_time: float = 2.0
@export var local_warning_time: float = 0.8
@export var total_batches: int = 3
@export var enemies_per_batch: int = 2
@export var batch_interval: float = 4.2
@export var same_batch_spawn_interval: float = 0.55
@export var minimum_spawn_distance: float = 220.0
@export var spawn_clearance: float = 48.0
@export var run_total_waves: int = 3
@export var intermission_time: float = 20.0
@export var wave_two_batches: int = 3
@export var wave_two_normal_per_batch: int = 2
@export var wave_two_heavy_per_batch: int = 1
@export var wave_three_batches: int = 4
@export var wave_three_normal_per_batch: int = 3
@export var wave_three_heavy_per_batch: int = 1

@export_category("Basic Taste-True enemy")
@export var enemy_max_health: float = 60.0
@export var enemy_move_speed: float = 82.0
@export var chase_refresh_interval: float = 0.28
@export var attack_distance: float = 58.0
@export var attack_range: float = 78.0
@export var attack_width: float = 68.0
@export var windup_time: float = 0.36
@export var attack_active_time: float = 0.12
@export var recovery_time: float = 0.28
@export var attack_damage: float = 12.0
@export var player_knockback: float = 58.0
@export var attack_cooldown: float = 0.7
@export var hit_stun_time: float = 0.14
@export var knockback_decay: float = 520.0
@export var separation_radius: float = 40.0
@export var separation_force: float = 48.0
@export var chase_slot_radius: float = 30.0
@export var stuck_repath_time: float = 0.75
@export var stuck_minimum_speed: float = 6.0
@export var stuck_steer_time: float = 0.5
@export var stuck_lateral_weight: float = 0.7
@export var reflavor_exit_time: float = 0.48

@export_category("Heavy Taste-True enemy - Prototype values")
@export var heavy_max_health: float = 165.0
@export var heavy_move_speed: float = 52.0
@export var heavy_attack_distance: float = 72.0
@export var heavy_attack_range: float = 98.0
@export var heavy_attack_width: float = 112.0
@export var heavy_windup_time: float = 0.75
@export var heavy_attack_active_time: float = 0.18
@export var heavy_recovery_time: float = 0.48
@export var heavy_attack_damage: float = 22.0
@export var heavy_player_knockback: float = 88.0
@export var heavy_attack_cooldown: float = 1.05
@export var heavy_stagger_threshold: float = 70.0
@export var heavy_hit_stun_time: float = 0.11
@export var heavy_knockback_multiplier: float = 0.38
@export var heavy_taste_time_multiplier: float = 1.25

@export_category("Player Prototype health")
@export var player_max_health: float = 100.0
@export var player_hit_protection_time: float = 0.22

@export_category("Prototype 0.6A actual cabinet stock")
@export var raw_beef_stock: int = 1
@export var marinade_stock: int = 1
@export var chili_stock: int = 2
@export var cooking_oil_stock: int = 2
@export var salt_stock: int = 1
@export var mustard_stock: int = 1
@export var clean_plate_stock: int = 6

@export_category("Prototype 0.6A physical loot")
@export_range(0.0, 1.0, 0.01) var normal_loot_chance: float = 0.35
@export var normal_loot_oil_weight: float = 24.0
@export var normal_loot_salt_weight: float = 24.0
@export var normal_loot_chili_weight: float = 24.0
@export var normal_loot_marinade_weight: float = 20.0
@export var normal_loot_mustard_weight: float = 8.0
@export var loot_spawn_radius: float = 26.0

@export_category("Manual kitchen processing - Prototype values")
@export var first_cut_time: float = 1.4
@export var second_cut_time: float = 1.4
@export var marinating_time: float = 1.8

@export_category("Expanded test map - Prototype values")
@export var map_bounds := Rect2(28.0, 28.0, 1820.0, 1328.0)
@export var navigation_inset: float = 14.0
@export var kitchen_offset := Vector2(240.0, 220.0)
@export var camera_limit_margin: float = 0.0
@export var camera_zoom := Vector2(0.75, 0.75)


func get_total_batches(wave_index: int) -> int:
	match wave_index:
		2:
			return wave_two_batches
		3:
			return wave_three_batches
	return total_batches


func get_normal_per_batch(wave_index: int) -> int:
	match wave_index:
		2:
			return wave_two_normal_per_batch
		3:
			return wave_three_normal_per_batch
	return enemies_per_batch


func get_heavy_per_batch(wave_index: int) -> int:
	match wave_index:
		2:
			return wave_two_heavy_per_batch
		3:
			return wave_three_heavy_per_batch
	return 0


func get_enemies_in_batch(wave_index: int) -> int:
	return get_normal_per_batch(wave_index) + get_heavy_per_batch(wave_index)


func get_planned_enemy_total(wave_index: int) -> int:
	return get_total_batches(wave_index) * get_enemies_in_batch(wave_index)
