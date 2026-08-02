class_name PrototypeWaveConfig
extends Resource

const INITIAL_OIL_BOTTLE_PORTIONS: int = 6
const DROP_OIL_BOTTLE_PORTIONS: int = 2
const INITIAL_SALT_BOTTLE_PORTIONS: int = 10
const DROP_SALT_BOTTLE_PORTIONS: int = 3
const STARTING_RICE_BAG_PORTIONS: int = 20
const DROP_SMALL_RICE_BAG_PORTIONS: int = 2

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
@export var wave_three_normal_per_batch: int = 2
@export var wave_three_heavy_per_batch: int = 1

@export_category("Basic Taste-True enemy")
@export var enemy_max_health: float = 60.0
@export var enemy_move_speed: float = 164.0
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
@export var separation_force: float = 96.0
@export var chase_slot_radius: float = 30.0
@export var stuck_repath_time: float = 0.75
@export var stuck_minimum_speed: float = 12.0
@export var stuck_steer_time: float = 0.5
@export var stuck_lateral_weight: float = 0.7
@export var reflavor_exit_time: float = 0.48

@export_category("Heavy Taste-True enemy - Prototype values")
@export var heavy_max_health: float = 165.0
@export var heavy_move_speed: float = 104.0
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
@export var player_max_shield: float = 30.0
@export var player_shield_regen_delay: float = 4.0
@export var player_shield_regen_per_second: float = 10.0

@export_category("Player Prototype sprint")
@export var player_max_stamina: float = 100.0
@export var player_sprint_speed_multiplier: float = 2.0
@export var player_sprint_drain_per_second: float = 30.0
@export var player_stamina_regen_delay: float = 0.8
@export var player_stamina_regen_per_second: float = 25.0

@export_category("Fast enemy - Prototype 0.6B values")
@export var fast_max_health_multiplier: float = 0.60
@export var fast_move_speed_multiplier: float = 1.45
@export var fast_charge_trigger_distance: float = 230.0
@export var fast_charge_windup_time: float = 0.60
@export var fast_direction_lock_ratio: float = 0.50
@export var fast_dash_time: float = 0.36
@export var fast_dash_speed: float = 620.0
@export var fast_dash_damage: float = 18.0
@export var fast_dash_knockback: float = 92.0
@export var fast_miss_recovery: float = 0.70
@export var fast_wall_recovery: float = 1.0
@export var fast_hit_recovery: float = 0.50
@export var fast_dash_cooldown: float = 2.7
@export var fast_concurrent_limit: int = 4
@export var fast_spawn_grace_time: float = 0.8

@export_category("Ranged enemy - Prototype 0.6B values")
@export var ranged_max_health_multiplier: float = 0.80
@export var ranged_move_speed_multiplier: float = 0.82
@export var ranged_preferred_min_distance: float = 250.0
@export var ranged_preferred_max_distance: float = 430.0
@export var ranged_eating_time: float = 0.75
@export var ranged_retch_windup_time: float = 0.65
@export var ranged_lock_ratio: float = 0.55
@export var ranged_volley_count: int = 3
@export var ranged_volley_interval: float = 0.22
@export var ranged_shoot_recovery: float = 0.70
@export var ranged_attack_cycle_interval: float = 4.5
@export var ranged_volley_spread: float = 26.0
@export var ranged_projectile_damage: float = 8.0
@export var ranged_projectile_splash_damage: float = 4.0
@export var ranged_projectile_splash_radius: float = 32.0
@export var ranged_projectile_speed: float = 360.0
@export var ranged_projectile_range: float = 720.0
@export var ranged_projectile_radius: float = 11.0
@export var ranged_projectile_arc_height: float = 48.0
@export var ranged_projectile_knockback: float = 28.0
@export var ranged_shots_before_reposition: int = 2
@export var ranged_close_distance: float = 116.0
@export var ranged_shove_windup: float = 0.40
@export var ranged_shove_damage: float = 8.0
@export var ranged_shove_knockback: float = 50.0
@export var ranged_shove_recovery: float = 1.0
@export var ranged_concurrent_limit: int = 2

@export_category("Prototype 0.6A actual cabinet stock")
@export var raw_beef_stock: int = 1
@export var marinade_stock: int = 1
@export var chili_stock: int = 2
@export var cooking_oil_stock: int = 1
@export var salt_stock: int = 1
@export var mustard_stock: int = 1
@export var clean_plate_stock: int = 6
@export var rice_bag_stock: int = 1
@export var whole_greens_stock: int = 1

@export_category("Prototype physical loot - per enemy type")
@export_range(0.0, 1.0, 0.01) var basic_loot_chance: float = 0.30
@export var basic_loot_oil_weight: float = 35.0
@export var basic_loot_salt_weight: float = 30.0
@export var basic_loot_whole_greens_weight: float = 20.0
@export var basic_loot_chili_weight: float = 10.0
@export var basic_loot_marinade_weight: float = 5.0
@export_range(0.0, 1.0, 0.01) var fast_loot_chance: float = 0.40
@export var fast_loot_whole_greens_weight: float = 35.0
@export var fast_loot_chili_weight: float = 30.0
@export var fast_loot_oil_weight: float = 20.0
@export var fast_loot_marinade_weight: float = 10.0
@export var fast_loot_salt_weight: float = 5.0
@export_range(0.0, 1.0, 0.01) var ranged_loot_chance: float = 0.50
@export var ranged_loot_salt_weight: float = 35.0
@export var ranged_loot_marinade_weight: float = 25.0
@export var ranged_loot_mustard_weight: float = 20.0
@export var ranged_loot_small_rice_bag_weight: float = 10.0
@export var ranged_loot_chili_weight: float = 10.0
@export var loot_spawn_radius: float = 26.0

@export_category("Prototype shared shortage compensation")
@export var shortage_scan_interval: float = 0.5
@export var shortage_oil_safe_portions: float = 2.0
@export var shortage_greens_safe_leaves: float = 5.0
@export var shortage_salt_safe_portions: float = 2.0
@export var shortage_marinade_safe_units: float = 1.0
@export var shortage_rice_safe_equivalents: float = 2.0
@export var shortage_chili_safe_units: float = 1.0
@export var shortage_beef_safe_units: float = 1.0
@export var shortage_oil_delay: float = 8.0
@export var shortage_greens_delay: float = 10.0
@export var shortage_salt_delay: float = 12.0
@export var shortage_marinade_delay: float = 10.0
@export var shortage_rice_delay: float = 18.0
@export var shortage_chili_delay: float = 18.0
@export var shortage_oil_max_multiplier: float = 3.0
@export var shortage_greens_max_multiplier: float = 2.6
@export var shortage_salt_max_multiplier: float = 2.0
@export var shortage_marinade_max_multiplier: float = 2.6
@export var shortage_rice_max_multiplier: float = 3.5
@export var shortage_chili_max_multiplier: float = 1.35
@export var shortage_rice_drop_cooldown: float = 24.0
@export var shortage_growth_seconds: float = 18.0
@export var small_rice_bag_potential_healing_per_rice: float = 20.0

@export_category("Manual kitchen processing - Prototype values")
@export var first_cut_time: float = 1.4
@export var second_cut_time: float = 1.4
@export var dice_cut_time: float = 1.0
@export var marinating_time: float = 1.8

@export_category("Expanded test map - Prototype values")
@export var map_bounds := Rect2(0.0, 0.0, 4608.0, 3456.0)
@export var navigation_inset: float = 32.0
@export var spawn_edge_inset: float = 96.0
@export var kitchen_offset := Vector2(1776.0, 1392.0)
@export var camera_limit_margin: float = 0.0
@export var camera_zoom := Vector2(0.75, 0.75)


func get_total_batches(wave_index: int) -> int:
	match wave_index:
		2:
			return wave_two_batches
		3:
			return wave_three_batches
	return total_batches


func get_normal_per_batch(wave_index: int, _batch_index: int = 1) -> int:
	match wave_index:
		2:
			return wave_two_normal_per_batch
		3:
			return wave_three_normal_per_batch
	return enemies_per_batch


func get_heavy_per_batch(wave_index: int, _batch_index: int = 1) -> int:
	match wave_index:
		2:
			return wave_two_heavy_per_batch
		3:
			return wave_three_heavy_per_batch
	return 0


func get_fast_per_batch(wave_index: int, batch_index: int = 1) -> int:
	match wave_index:
		1:
			return 1 if batch_index >= 2 else 0
		2:
			return 1 if batch_index >= 2 else 0
		3:
			return 1
	return 0


func get_ranged_per_batch(wave_index: int, batch_index: int = 1) -> int:
	match wave_index:
		2:
			return 1 if batch_index == 1 else 0
		3:
			return 1 if batch_index % 2 == 1 else 0
	return 0


func get_enemies_in_batch(wave_index: int, batch_index: int = 1) -> int:
	return (
		get_normal_per_batch(wave_index, batch_index)
		+ get_heavy_per_batch(wave_index, batch_index)
		+ get_fast_per_batch(wave_index, batch_index)
		+ get_ranged_per_batch(wave_index, batch_index)
	)


func get_planned_enemy_total(wave_index: int) -> int:
	var total := 0
	for batch_index in range(1, get_total_batches(wave_index) + 1):
		total += get_enemies_in_batch(wave_index, batch_index)
	return total
