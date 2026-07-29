class_name PrototypeCombatConfig
extends Resource

@export_category("Dish attributes - Prototype values")
@export var standard_damage: float = 20.0
@export var standard_durability: int = 10
@export var flawed_durability_multiplier: float = 0.7
@export var bad_damage_multiplier: float = 0.7
@export var bad_durability_multiplier: float = 0.5
@export var attack_interval: float = 0.35

@export_category("Tomahawk steak melee - Prototype values")
@export var tomahawk_damage: float = 42.0
@export var tomahawk_durability: int = 8
@export var tomahawk_attack_interval: float = 0.78
@export var tomahawk_input_buffer_time: float = 0.16
@export var tomahawk_range: float = 112.0
@export var tomahawk_arc_degrees: float = 92.0
@export var tomahawk_knockback: float = 130.0
@export var tomahawk_stagger_power: float = 100.0
@export var mustard_melee_sneeze_stun: float = 0.32

@export_category("Pan cooking - Prototype values")
@export var pan_first_side_time: float = 4.2
@export var pan_flip_window_time: float = 1.4
@export var pan_second_side_time: float = 4.0
@export var pan_ready_to_burn_time: float = 3.0
@export var pan_burnt_to_charcoal_time: float = 2.0

@export_category("Soup pot and shabu - Prototype values")
@export var soup_water_heat_time: float = 2.4
@export var shabu_cook_time: float = 1.0
@export var shabu_overcook_time: float = 1.6
@export var shabu_mushy_time: float = 1.2
@export var shabu_aroma_radius: float = 310.0
@export var shabu_place_distance: float = 74.0
@export var shabu_standard_damage: float = 26.0
@export var shabu_standard_taste_time: float = 1.0
@export var shabu_one_tag_multiplier: float = 0.72
@export var shabu_two_tag_multiplier: float = 0.48
@export var shabu_lock_timeout: float = 7.0

@export_category("Rice cooking - Prototype 0.6B values")
@export var rice_bag_capacity: int = 20
@export var white_rice_cook_time: float = 8.0
@export var rice_porridge_cook_time: float = 12.0
@export var crispy_rice_cook_time: float = 5.0
@export var crispy_rice_burn_time: float = 4.0

@export_category("White rice weapon - Prototype 0.6B values")
@export var white_rice_durability: int = 18
@export var white_rice_attack_interval: float = 0.30
@export var white_rice_damage: float = 6.7
@export var white_rice_projectile_speed: float = 720.0
@export var white_rice_projectile_range: float = 560.0
@export var white_rice_perfect_damage_multiplier: float = 1.15

@export_category("Rice porridge healing - Prototype 0.6B values")
@export var rice_porridge_durability: int = 2
@export var rice_porridge_use_time: float = 2.0
@export var rice_porridge_perfect_heal: float = 12.0
@export var rice_porridge_normal_heal: float = 10.0
@export var rice_porridge_flawed_heal: float = 8.0
@export var rice_porridge_bad_heal: float = 5.0
@export var rice_porridge_hot_time: float = 10.0
@export var rice_porridge_burn_damage: float = 4.0
@export var rice_porridge_burn_duration: float = 2.0

@export_category("Crispy rice armor - Prototype 0.6B values")
@export var crispy_rice_durability: int = 5
@export var crispy_rice_perfect_reduction: float = 0.35
@export var crispy_rice_normal_reduction: float = 0.25
@export var crispy_rice_flawed_reduction: float = 0.15
@export var crispy_rice_bad_reduction: float = 0.10
@export var crispy_trap_damage: float = 20.0
@export var crispy_trap_arm_time: float = 0.5
@export var crispy_trap_radius: float = 34.0

@export_category("Emergency eating - Prototype 0.6B values")
@export var emergency_eating_enabled: bool = true
@export var emergency_heal: float = 5.0
@export var emergency_use_time: float = 1.25
@export var emergency_durability_ratio: float = 0.50

@export_category("Big bone - Prototype values")
@export var big_bone_damage: float = 30.0
@export var big_bone_speed: float = 540.0
@export var big_bone_distance: float = 520.0
@export var big_bone_hit_radius: float = 22.0
@export var big_bone_stagger_power: float = 58.0

@export_category("Stagger powers - Prototype values")
@export var normal_bull_stagger_power: float = 22.0
@export var raging_bull_stagger_power: float = 120.0

@export_category("Automatic cooking - Prototype values")
@export var automatic_stage_one_time: float = 3.6
@export var automatic_stage_two_time: float = 3.9
@export var automatic_burn_time: float = 2.7
@export var automatic_charcoal_time: float = 2.0
@export var burn_warning_ratio: float = 0.65

@export_category("Expanded combat map - Prototype values")
@export var combat_bounds := Rect2(28.0, 28.0, 1820.0, 1328.0)

@export_category("Seasoning modifiers - Prototype values")
@export var salt_durability_bonus: int = 2
@export var mustard_direct_damage_multiplier: float = 0.85
@export var mustard_poison_damage: float = 3.0
@export var mustard_poison_interval: float = 0.5
@export var mustard_poison_duration: float = 2.0
@export var mustard_poison_refresh_duration: bool = true

@export_category("Mustard aim side effect - Prototype values")
@export var mustard_sway_amplitude_degrees: float = 4.0
@export var mustard_sway_cycles_per_second: float = 0.85
@export var mustard_sneeze_check_interval: float = 1.5
@export var mustard_sneeze_chance: float = 0.35
@export var mustard_sneeze_warning_time: float = 0.18
@export var mustard_sneeze_min_degrees: float = 20.0
@export var mustard_sneeze_max_degrees: float = 34.0
@export var mustard_sneeze_hold_time: float = 0.2
@export var mustard_sneeze_recovery_time: float = 0.28
@export var mustard_ally_influence_radius: float = 450.0

@export_category("Normal bull - Prototype values")
@export var normal_bull_speed: float = 500.0
@export var normal_bull_distance: float = 430.0
@export var normal_bull_width: float = 76.0
@export var normal_bull_knockback: float = 42.0

@export_category("Raging bull - Prototype values")
@export var raging_bull_damage: float = 48.0
@export var raging_bull_speed: float = 800.0
@export var raging_bull_duration: float = 24.0
@export var raging_bull_radius: float = 65.0
@export var raging_bull_visual_size := Vector2(198.0, 135.0)
@export var raging_bull_knockback: float = 95.0
@export var raging_bull_hit_cooldown: float = 0.45
@export var raging_bull_friendly_fire_damage: float = 18.0
@export var raging_bull_friendly_knockback: float = 68.0
@export var raging_bull_warning_distance: float = 320.0
@export var random_turn_check_interval: float = 0.9
@export var random_turn_chance: float = 0.25
@export var random_turn_warning_time: float = 0.22

@export_category("QTE - Prototype values")
@export var qte_pointer_speed: float = 0.75
@export var qte_perfect_min: float = 0.43
@export var qte_perfect_max: float = 0.57

@export_category("Plate washing - Prototype values")
@export var plate_wash_base_time: float = 1.6
@export var wash_multiplier_two_to_four: float = 0.82
@export var wash_multiplier_five_to_eight: float = 0.62
@export var wash_multiplier_nine_plus: float = 0.45

@export_category("Content expansion cooking - Prototype values")
@export var active_stir_stage_one_time: float = 2.2
@export var active_stir_stage_two_time: float = 2.4
@export var active_stir_interrupt_keeps_progress: bool = false
@export var active_stir_unattended_burn_time: float = 4.0
@export var flash_stir_qte_speed: float = 1.2
@export var flash_stir_smoke_duration: float = 1.2

@export_category("Content expansion durability - Prototype values")
@export var shabu_stack_max: int = 5
@export var boiled_greens_durability_per_leaf: int = 1
@export var stir_fry_greens_durability: int = 14
@export var beef_greens_durability: int = 16
@export var greens_fried_rice_durability: int = 14
@export var beef_fried_rice_durability: int = 12
@export var mixed_fried_rice_durability: int = 14
@export var vegetable_rice_durability: int = 8
@export var soaked_rice_durability: int = 3
@export var rice_bowl_turret_durability: int = 15
@export var beef_greens_soup_durability: int = 18
@export var mustard_greens_max_leaves: int = 5

@export_category("Shared statuses - Prototype values")
@export var spicy_vulnerability: float = 0.08
@export var spicy_vulnerability_duration: float = 3.0
@export var choking_duration: float = 4.0
@export var choking_melee_miss_chance: float = 0.18
@export var choking_aim_degrees: float = 14.0
@export var beef_porridge_direct_bonus: float = 0.10
@export var plain_beef_porridge_direct_bonus: float = 0.08
@export var perfect_beef_porridge_direct_bonus: float = 0.20
@export var beef_porridge_bonus_duration: float = 6.0
@export var perfect_beef_porridge_bonus_duration: float = 8.0
@export var soaked_rice_move_slow: float = 0.25
@export var soaked_rice_attack_slow: float = 0.20
@export var perfect_soaked_rice_move_slow: float = 0.35
@export var perfect_soaked_rice_attack_slow: float = 0.30
@export var greens_soaked_rice_weakness_per_leaf: float = 0.03
@export var greens_soaked_rice_weakness_cap: float = 0.15
@export var vegetable_rice_shield_per_bite: float = 7.0
@export var vegetable_rice_final_reduction: float = 0.15
@export var vegetable_rice_final_reduction_duration: float = 5.0
@export var greens_porridge_hot_reduction_per_leaf: float = 1.0
@export var greens_porridge_min_hot_time: float = 5.0
@export var greens_porridge_hot_heal_per_second: float = 1.0
@export var greens_porridge_hot_heal_duration: float = 5.0

@export_category("Milestone C greens combat - Prototype values")
@export var boiled_greens_trigger_radius: float = 124.0
@export var boiled_greens_trigger_cooldown: float = 0.8
@export var boiled_greens_knockback: float = 105.0
@export var boiled_greens_stun: float = 0.18
@export var greens_leaf_damage: float = 14.0
@export var greens_leaf_attack_interval: float = 0.42
@export var greens_leaf_speed: float = 560.0
@export var greens_leaf_range: float = 460.0
@export var greens_leaf_pierce_count: int = 3
@export var flash_leaf_damage: float = 18.0
@export var flash_leaf_speed: float = 760.0
@export var flash_leaf_range: float = 540.0
@export var flash_leaf_burst_radius: float = 105.0
@export var flash_leaf_finisher_damage: float = 22.0
@export var greens_porridge_short_cook_time: float = 3.0
@export var beef_porridge_short_cook_time: float = 3.6
@export var greens_porridge_base_heal: float = 10.0
@export var beef_porridge_heal: float = 8.0
@export var porridge_durability: int = 2

@export_category("Milestone D stir-fry and fried rice - Prototype values")
@export var beef_greens_center_damage: float = 36.0
@export var beef_greens_side_damage: float = 18.0
@export var beef_greens_range: float = 148.0
@export var beef_greens_arc_degrees: float = 104.0
@export var beef_greens_center_degrees: float = 42.0
@export var beef_greens_knockback: float = 42.0
@export var beef_greens_attack_interval: float = 0.62
@export var fried_rice_throw_range: float = 540.0
@export var fried_rice_flight_time: float = 0.48
@export var fried_rice_attack_interval: float = 0.68
@export var greens_fried_rice_damage: float = 15.0
@export var greens_fried_rice_radius: float = 112.0
@export var greens_fried_rice_perfect_radius: float = 182.0
@export var beef_fried_rice_damage: float = 50.0
@export var beef_fried_rice_snap_radius: float = 48.0
@export var beef_fried_rice_stagger: float = 28.0
@export var beef_fried_rice_perfect_multiplier: float = 1.28
@export var unmarinated_fried_rice_damage_multiplier: float = 0.86
@export var mixed_fried_rice_primary_damage: float = 40.0
@export var mixed_fried_rice_aoe_damage: float = 11.0
@export var mixed_fried_rice_radius: float = 92.0
@export var mixed_fried_rice_perfect_radius: float = 132.0
@export var mixed_fried_rice_snap_radius: float = 58.0
@export var mixed_fried_rice_stagger: float = 18.0
@export var mixed_fried_rice_perfect_multiplier: float = 1.18

@export_category("Milestone E functional rice - Prototype values")
@export var vegetable_rice_cook_time: float = 9.0
@export var soaked_rice_cook_time: float = 3.2
@export var greens_soaked_rice_cook_time: float = 2.6
@export var vegetable_rice_bite_time: float = 0.85
@export var soaked_rice_radius: float = 145.0
@export var soaked_rice_zone_duration: float = 5.0
@export var perfect_soaked_rice_radius: float = 205.0
@export var perfect_soaked_rice_duration: float = 7.0
@export var soaked_rice_residual_duration: float = 0.35
@export var rice_zone_throw_distance: float = 245.0

@export_category("Milestone F advanced dishes - Prototype values")
@export var rice_bowl_turret_range: float = 430.0
@export var rice_bowl_turret_interval: float = 0.72
@export var rice_bowl_rice_damage: float = 12.0
@export var rice_bowl_rice_radius: float = 82.0
@export var rice_bowl_greens_damage: float = 18.0
@export var rice_bowl_greens_range: float = 470.0
@export var rice_bowl_beef_damage: float = 38.0

@export_category("Missing recipes group 2 - rice bowl turrets")
@export var greens_rice_bowl_base_durability: int = 8
@export var greens_rice_bowl_damage: float = 18.0
@export var greens_rice_bowl_range: float = 410.0
@export var greens_rice_bowl_interval: float = 0.68
@export var greens_rice_bowl_pierce: int = 3
@export var greens_rice_bowl_finisher_count: int = 5
@export var greens_rice_bowl_finisher_arc_degrees: float = 70.0
@export var beef_rice_bowl_base_durability: int = 7
@export var beef_rice_bowl_damage: float = 42.0
@export var beef_rice_bowl_range: float = 450.0
@export var beef_rice_bowl_interval: float = 0.88
@export var beef_rice_bowl_finisher_damage: float = 90.0
@export var soup_base_cook_time: float = 2.8
@export var beef_greens_soup_finish_time: float = 3.2
@export var beef_greens_soup_range: float = 360.0
@export var beef_greens_soup_turn_speed: float = 4.5
@export var beef_greens_soup_tick_interval: float = 0.48
@export var beef_greens_soup_center_damage: float = 9.0
@export var beef_greens_soup_outer_damage: float = 4.0
@export var beef_greens_soup_knockback: float = 28.0
@export var beef_greens_soup_finisher_damage: float = 26.0
@export var beef_greens_soup_finisher_radius: float = 118.0
@export var mustard_greens_mix_time: float = 1.8
@export var mustard_greens_projectile_speed: float = 560.0
@export var mustard_greens_range: float = 420.0
@export var mustard_greens_attack_interval: float = 0.52
@export var mustard_primary_weakness: float = 0.18
@export var mustard_primary_move_slow: float = 0.30
@export var mustard_primary_attack_slow: float = 0.25
@export var mustard_primary_vulnerability: float = 0.18
@export var mustard_aura_radius: float = 120.0
@export var mustard_aura_move_slow: float = 0.14
@export var mustard_aura_vulnerability: float = 0.10
@export var mustard_carrier_vulnerability: float = 0.12
@export var mustard_nearest_teammate_slow: float = 0.16

# Missing recipes group 1. These are Prototype tuning values, centralized here
# so recipe creation, stations, attacks and tests share one source of truth.
@export var fried_white_rice_stir_time: float = 1.5
@export var fried_white_rice_durability: int = 16
@export var fried_white_rice_attack_interval: float = 0.65
@export var fried_white_rice_grain_count: int = 20
@export var fried_white_rice_grain_damage: float = 3.0
@export var fried_white_rice_grain_speed: float = 620.0
@export var fried_white_rice_grain_range: float = 280.0
@export var fried_white_rice_angle_jitter_degrees: float = 5.0
@export var fried_white_rice_perfect_move_slow: float = 0.08
@export var fried_white_rice_perfect_slow_duration: float = 0.8

@export var clear_beef_stage_one_time: float = 1.2
@export var clear_beef_stage_two_time: float = 1.0
@export var clear_beef_durability: int = 12
@export var clear_beef_unmarinated_durability: int = 10
@export var clear_beef_hit_damage: float = 6.0
@export var clear_beef_unmarinated_damage_multiplier: float = 0.8
@export var clear_beef_attack_interval: float = 0.48
@export var clear_beef_combo_duration: float = 0.22
@export var clear_beef_range: float = 115.0
@export var clear_beef_arc_degrees: float = 42.0
@export var clear_beef_final_knockback: float = 16.0
@export var clear_beef_perfect_hits: int = 6
@export var clear_beef_perfect_duration: float = 0.45
@export var clear_beef_perfect_final_arc: float = 70.0
@export var clear_beef_perfect_final_knockback: float = 42.0
@export var clear_beef_perfect_final_stun: float = 0.15

@export var greens_soup_finish_time: float = 2.0
@export var greens_soup_base_durability: int = 5
@export var greens_soup_range: float = 280.0
@export var greens_soup_width: float = 48.0
@export var greens_soup_tick_interval: float = 0.25
@export var greens_soup_damage: float = 2.0
@export var greens_soup_knockback: float = 10.0
@export var greens_soup_durability_interval: float = 0.5
@export var greens_soup_move_slow: float = 0.10
@export var greens_soup_side_angle_degrees: float = 20.0
@export var greens_soup_side_multiplier: float = 0.60
@export var greens_soup_side_range_multiplier: float = 0.85

@export var beef_soup_stage_one_time: float = 2.0
@export var beef_soup_finish_time: float = 2.5
@export var beef_soup_overcook_time: float = 2.0
@export var beef_soup_durability: int = 14
@export var beef_soup_unmarinated_durability: int = 12
@export var beef_soup_range: float = 360.0
@export var beef_soup_width: float = 34.0
@export var beef_soup_tick_interval: float = 0.25
@export var beef_soup_damage: float = 5.0
@export var beef_soup_unmarinated_damage: float = 4.0
@export var beef_soup_durability_interval: float = 0.5
@export var beef_soup_move_slow: float = 0.12
@export var beef_soup_focus_gain: float = 0.06
@export var beef_soup_focus_max_stacks: int = 5
@export var beef_soup_focus_timeout: float = 0.75
@export var beef_soup_visual_fade_speed: float = 7.5

# Missing recipes group 3: braised-rice shared food stations.
@export var beef_braised_rice_cook_time: float = 9.0
@export var beef_braised_rice_durability: int = 10
@export var beef_braised_rice_unmarinated_durability: int = 9
@export var beef_braised_rice_bite_time: float = 0.85
@export var beef_braised_rice_direct_bonus: float = 0.12
@export var beef_braised_rice_unmarinated_bonus: float = 0.09
@export var beef_braised_rice_bonus_duration: float = 7.0
@export var beef_braised_rice_perfect_bonus: float = 0.20
@export var beef_braised_rice_perfect_duration: float = 10.0

@export var greens_beef_braised_rice_durability: int = 12
@export var greens_beef_braised_rice_unmarinated_durability: int = 11
@export var greens_beef_braised_rice_bite_time: float = 0.90
@export var greens_beef_braised_rice_shield_per_bite: float = 4.0
@export var greens_beef_braised_rice_direct_bonus: float = 0.08
@export var greens_beef_braised_rice_unmarinated_bonus: float = 0.06
@export var greens_beef_braised_rice_bonus_duration: float = 6.0
@export var greens_beef_braised_rice_perfect_shield: float = 8.0
@export var greens_beef_braised_rice_perfect_bonus: float = 0.15
@export var greens_beef_braised_rice_perfect_duration: float = 8.0
@export var greens_beef_braised_rice_perfect_reduction: float = 0.10
@export var greens_beef_braised_rice_perfect_reduction_duration: float = 5.0

# Missing recipes group 4: combined porridge and soaked-rice zones.
@export var greens_beef_porridge_cook_time: float = 3.2
@export var greens_beef_porridge_durability: int = 3
@export var greens_beef_porridge_use_time: float = 2.0
@export var greens_beef_porridge_base_heal: float = 8.0
@export var greens_beef_porridge_direct_bonus: float = 0.08
@export var greens_beef_porridge_unmarinated_bonus: float = 0.06
@export var greens_beef_porridge_bonus_duration: float = 6.0
@export var greens_beef_porridge_perfect_bonus: float = 0.15
@export var greens_beef_porridge_perfect_bonus_duration: float = 8.0
@export var greens_beef_porridge_perfect_hot_heal_per_second: float = 1.0
@export var greens_beef_porridge_perfect_hot_heal_duration: float = 5.0
@export var group_4_soaked_rice_cook_time: float = 2.6
@export var beef_soaked_rice_vulnerability_per_portion: float = 0.03
@export var beef_soaked_rice_vulnerability_cap: float = 0.15
@export var perfect_beef_soaked_rice_vulnerability_per_portion: float = 0.04
@export var perfect_beef_soaked_rice_vulnerability_cap: float = 0.20
@export var perfect_greens_soaked_rice_weakness_per_leaf: float = 0.04
@export var perfect_greens_soaked_rice_weakness_cap: float = 0.20

# Missing recipes group 5: crispy-rice beef friendly-fire bomb.
@export var crispy_beef_place_distance: float = 82.0
@export var crispy_beef_main_arm_time: float = 0.8
@export var crispy_beef_main_trigger_radius: float = 52.0
@export var crispy_beef_main_radius: float = 180.0
@export var crispy_beef_main_damage: float = 120.0
@export var crispy_beef_main_friendly_damage_multiplier: float = 0.40
@export var crispy_beef_main_knockback: float = 185.0
@export var crispy_beef_fragment_count: int = 8
@export var crispy_beef_fragment_scatter_min: float = 90.0
@export var crispy_beef_fragment_scatter_max: float = 230.0
@export var crispy_beef_fragment_arm_time: float = 0.7
@export var crispy_beef_fragment_lifetime: float = 15.0
@export var crispy_beef_fragment_trigger_radius: float = 36.0
@export var crispy_beef_fragment_radius: float = 85.0
@export var crispy_beef_fragment_damage: float = 35.0
@export var crispy_beef_fragment_friendly_damage_multiplier: float = 0.50
@export var crispy_beef_fragment_knockback: float = 72.0
@export var crispy_beef_perfect_main_radius: float = 220.0
@export var crispy_beef_perfect_main_damage: float = 150.0
@export var crispy_beef_perfect_fragment_count: int = 12
@export var crispy_beef_perfect_scatter_min: float = 100.0
@export var crispy_beef_perfect_scatter_max: float = 280.0

# Missing recipes group 6: spicy variants.
@export var spicy_fried_rice_grain_count: int = 18
@export var spicy_fried_rice_grain_damage: float = 2.5
@export var spicy_fried_rice_range: float = 280.0
@export var spicy_fried_rice_interval: float = 0.65
@export var spicy_fried_rice_durability: int = 16
@export var spicy_fried_rice_vulnerability: float = 0.05
@export var spicy_fried_rice_vulnerability_duration: float = 2.0
@export var spicy_fried_rice_perfect_vulnerability: float = 0.10
@export var spicy_fried_rice_perfect_duration: float = 3.0
@export var spicy_fried_rice_second_ring_delay: float = 0.15

@export var spicy_beef_greens_range: float = 148.0
@export var spicy_beef_greens_arc: float = 104.0
@export var spicy_beef_greens_center_arc: float = 42.0
@export var spicy_beef_greens_center_damage: float = 30.0
@export var spicy_beef_greens_side_damage: float = 15.0
@export var spicy_beef_greens_interval: float = 0.62
@export var spicy_beef_greens_durability: int = 16
@export var spicy_beef_greens_vulnerability: float = 0.08
@export var spicy_beef_greens_unmarinated_vulnerability: float = 0.06
@export var spicy_beef_greens_vulnerability_duration: float = 3.0
@export var spicy_beef_greens_knockback: float = 18.0
@export var spicy_beef_greens_perfect_radius: float = 175.0
@export var spicy_beef_greens_perfect_damage: float = 27.0
@export var spicy_beef_greens_perfect_vulnerability: float = 0.15
@export var spicy_beef_greens_perfect_duration: float = 4.0

@export var spicy_beef_fried_rice_damage: float = 38.0
@export var spicy_beef_fried_rice_unmarinated_damage: float = 32.0
@export var spicy_beef_fried_rice_snap_radius: float = 48.0
@export var spicy_beef_fried_rice_stun: float = 0.10
@export var spicy_beef_fried_rice_vulnerability: float = 0.12
@export var spicy_beef_fried_rice_unmarinated_vulnerability: float = 0.09
@export var spicy_beef_fried_rice_duration: float = 4.0
@export var spicy_beef_fried_rice_durability: int = 14
@export var spicy_beef_fried_rice_interval: float = 0.72
@export var spicy_beef_fried_rice_perfect_damage: float = 65.0
@export var spicy_beef_fried_rice_perfect_vulnerability: float = 0.20
@export var spicy_beef_fried_rice_perfect_duration: float = 5.0
@export var spicy_beef_fried_rice_perfect_stun: float = 0.20

@export var spicy_mixed_fried_rice_main_damage: float = 30.0
@export var spicy_mixed_fried_rice_unmarinated_main_damage: float = 25.0
@export var spicy_mixed_fried_rice_splash_damage: float = 14.0
@export var spicy_mixed_fried_rice_unmarinated_splash_damage: float = 12.0
@export var spicy_mixed_fried_rice_radius: float = 105.0
@export var spicy_mixed_fried_rice_range: float = 420.0
@export var spicy_mixed_fried_rice_durability: int = 15
@export var spicy_mixed_fried_rice_interval: float = 0.78
@export var spicy_mixed_fried_rice_vulnerability: float = 0.08
@export var spicy_mixed_fried_rice_unmarinated_vulnerability: float = 0.06
@export var spicy_mixed_fried_rice_duration: float = 3.0
@export var spicy_mixed_fried_rice_perfect_main_damage: float = 55.0
@export var spicy_mixed_fried_rice_perfect_splash_damage: float = 24.0
@export var spicy_mixed_fried_rice_perfect_radius: float = 180.0
@export var spicy_mixed_fried_rice_perfect_vulnerability: float = 0.14
@export var spicy_mixed_fried_rice_perfect_duration: float = 4.0
@export var spicy_mixed_fried_rice_perfect_knockback: float = 70.0

@export var spicy_beef_soup_range: float = 360.0
@export var spicy_beef_soup_width: float = 30.0
@export var spicy_beef_soup_tick_interval: float = 0.25
@export var spicy_beef_soup_damage: float = 4.0
@export var spicy_beef_soup_unmarinated_damage: float = 3.5
@export var spicy_beef_soup_durability_interval: float = 0.5
@export var spicy_beef_soup_durability: int = 14
@export var spicy_beef_soup_vulnerability_per_stack: float = 0.02
@export var spicy_beef_soup_unmarinated_vulnerability_per_stack: float = 0.016
@export var spicy_beef_soup_max_stacks: int = 5
@export var spicy_beef_soup_stack_timeout: float = 3.0
@export var spicy_beef_soup_finisher_range: float = 420.0
@export var spicy_beef_soup_finisher_width: float = 70.0
@export var spicy_beef_soup_finisher_duration: float = 0.5
@export var spicy_beef_soup_finisher_damage: float = 5.0
@export var spicy_beef_soup_finisher_vulnerability: float = 0.15
@export var spicy_beef_soup_finisher_status_duration: float = 4.0

@export var spicy_beef_greens_soup_interval: float = 0.48
@export var spicy_beef_greens_soup_range: float = 360.0
@export var spicy_beef_greens_soup_base_width: float = 30.0
@export var spicy_beef_greens_soup_width_per_extra_leaf: float = 2.0
@export var spicy_beef_greens_soup_max_width: float = 38.0
@export var spicy_beef_greens_soup_base_durability: int = 13
@export var spicy_beef_greens_soup_primary_vulnerability: float = 0.08
@export var spicy_beef_greens_soup_primary_weakness: float = 0.10
@export var spicy_beef_greens_soup_line_vulnerability: float = 0.05
@export var spicy_beef_greens_soup_line_weakness: float = 0.06
@export var spicy_beef_greens_soup_unmarinated_primary_vulnerability: float = 0.06
@export var spicy_beef_greens_soup_unmarinated_primary_weakness: float = 0.08
@export var spicy_beef_greens_soup_unmarinated_line_vulnerability: float = 0.04
@export var spicy_beef_greens_soup_unmarinated_line_weakness: float = 0.05
@export var spicy_beef_greens_soup_status_duration: float = 3.0
@export var spicy_beef_greens_soup_finisher_radius: float = 150.0
@export var spicy_beef_greens_soup_finisher_vulnerability: float = 0.12
@export var spicy_beef_greens_soup_finisher_weakness: float = 0.15
@export var spicy_beef_greens_soup_finisher_duration: float = 4.0

# Missing recipes group 7: rice cakes.
@export var rice_cake_press_time: float = 0.8
@export var rice_cake_first_side_time: float = 2.0
@export var rice_cake_second_side_time: float = 1.5
@export var rice_cake_flip_early_window: float = 0.45
@export var rice_cake_flip_late_time: float = 1.0
@export var pan_fried_rice_cake_out_damage: float = 16.0
@export var pan_fried_rice_cake_return_damage: float = 12.0
@export var pan_fried_rice_cake_range: float = 360.0
@export var pan_fried_rice_cake_speed: float = 430.0
@export var pan_fried_rice_cake_pierce: int = 3
@export var pan_fried_rice_cake_durability: int = 12
@export var pan_fried_rice_cake_interval: float = 0.7
@export var pan_fried_rice_cake_perfect_out_damage: float = 22.0
@export var pan_fried_rice_cake_perfect_return_damage: float = 18.0
@export var pan_fried_rice_cake_perfect_orbit_radius: float = 95.0
@export var pan_fried_rice_cake_perfect_orbit_duration: float = 0.8
@export var pan_fried_rice_cake_perfect_orbit_damage: float = 12.0

@export var greens_rice_cake_orbit_radius: float = 115.0
@export var greens_rice_cake_lap_time: float = 1.1
@export var greens_rice_cake_damage: float = 11.0
@export var greens_rice_cake_slow: float = 0.12
@export var greens_rice_cake_slow_duration: float = 2.0
@export var greens_rice_cake_hit_cooldown: float = 0.6
@export var greens_rice_cake_base_durability: int = 9
@export var greens_rice_cake_max_lifetime: float = 8.0
@export var greens_rice_cake_perfect_damage: float = 16.0
@export var greens_rice_cake_perfect_slow: float = 0.20
@export var greens_rice_cake_perfect_slow_duration: float = 2.5
@export var greens_rice_cake_leaf_damage: float = 7.0

@export var beef_rice_cake_damage: float = 26.0
@export var beef_rice_cake_unmarinated_damage: float = 22.0
@export var beef_rice_cake_max_hits: int = 4
@export var beef_rice_cake_target_radius: float = 190.0
@export var beef_rice_cake_same_target_cooldown: float = 0.45
@export var beef_rice_cake_knockback: float = 62.0
@export var beef_rice_cake_stun: float = 0.18
@export var beef_rice_cake_unmarinated_stun: float = 0.12
@export var beef_rice_cake_lifetime: float = 4.0
@export var beef_rice_cake_perfect_hit_1: float = 26.0
@export var beef_rice_cake_perfect_hit_2: float = 29.0
@export var beef_rice_cake_perfect_hit_3: float = 32.0
@export var beef_rice_cake_perfect_hit_4: float = 35.0
@export var beef_rice_cake_perfect_slam_damage: float = 45.0
@export var beef_rice_cake_perfect_slam_radius: float = 105.0
@export var beef_rice_cake_perfect_splash_damage: float = 18.0
@export var beef_rice_cake_perfect_stun: float = 0.35

@export var mixed_rice_cake_orbit_radius: float = 120.0
@export var mixed_rice_cake_lap_time: float = 1.15
@export var mixed_rice_cake_body_damages: Array[float] = [16.0, 14.0, 12.0, 10.0, 8.0]
@export var mixed_rice_cake_body_slow: float = 0.10
@export var mixed_rice_cake_body_slow_duration: float = 2.0
@export var mixed_rice_cake_body_hit_cooldown: float = 0.65
@export var mixed_rice_cake_split_interval: float = 1.25
@export var mixed_rice_cake_max_lifetime: float = 10.0
@export var mixed_rice_cake_split_target_radius: float = 280.0
@export var mixed_rice_cake_split_hits: int = 3
@export var mixed_rice_cake_salted_split_hits: int = 4
@export var mixed_rice_cake_split_damage: float = 14.0
@export var mixed_rice_cake_unmarinated_split_damage: float = 11.0
@export var mixed_rice_cake_split_same_target_cooldown: float = 0.35
@export var mixed_rice_cake_split_slow: float = 0.12
@export var mixed_rice_cake_split_slow_duration: float = 2.0
@export var mixed_rice_cake_split_knockback: float = 28.0
@export var mixed_rice_cake_split_stun: float = 0.10
@export var mixed_rice_cake_core_hits: int = 5
@export var mixed_rice_cake_core_damage: float = 20.0
@export var mixed_rice_cake_core_stun: float = 0.18
@export var mixed_rice_cake_core_final_damage: float = 25.0
@export var mixed_rice_cake_core_radius: float = 110.0
@export var mixed_rice_cake_core_splash_damage: float = 15.0
@export var mixed_rice_cake_core_slow: float = 0.20
@export var mixed_rice_cake_core_slow_duration: float = 2.5


func apply_combat_dish_stats(data: ItemData) -> void:
	# Prototype 0.2.1 calculation order: quality base -> salt durability -> mustard damage/poison -> finisher eligibility.
	data.base_damage = standard_damage
	data.actual_damage = standard_damage
	data.max_durability = standard_durability
	match data.quality:
		ItemData.Quality.FLAWED:
			data.max_durability = maxi(1, roundi(standard_durability * flawed_durability_multiplier))
		ItemData.Quality.BAD:
			data.max_durability = maxi(1, roundi(standard_durability * bad_durability_multiplier))
			data.actual_damage = standard_damage * bad_damage_multiplier
	if data.has_active_modifier(ItemData.ActiveModifier.SALTED):
		data.max_durability += salt_durability_bonus
	if data.has_active_modifier(ItemData.ActiveModifier.MUSTARD):
		data.actual_damage *= mustard_direct_damage_multiplier
		data.poison_damage = mustard_poison_damage
		data.poison_interval = mustard_poison_interval
		data.poison_duration = mustard_poison_duration
		data.poison_refresh_duration = mustard_poison_refresh_duration
	else:
		data.poison_damage = 0.0
		data.poison_interval = 0.0
		data.poison_duration = 0.0
	data.has_perfect_finisher = data.quality == ItemData.Quality.PERFECT and not data.is_weird_dish()
	data.current_durability = data.max_durability
	data.attack_form = ItemData.AttackForm.PROJECTILE
	data.cooking_method = ItemData.CookingMethod.STIR_FRY
	data.stagger_power = normal_bull_stagger_power


func apply_tomahawk_stats(data: ItemData) -> void:
	# One calculation point shared by direct and plated versions.
	data.is_combat_dish = true
	data.base_damage = tomahawk_damage
	data.actual_damage = tomahawk_damage
	data.max_durability = tomahawk_durability
	match data.quality:
		ItemData.Quality.FLAWED:
			data.max_durability = maxi(1, roundi(tomahawk_durability * flawed_durability_multiplier))
		ItemData.Quality.BAD:
			data.max_durability = maxi(1, roundi(tomahawk_durability * bad_durability_multiplier))
			data.actual_damage = tomahawk_damage * bad_damage_multiplier
	if data.has_active_modifier(ItemData.ActiveModifier.SALTED):
		data.max_durability += salt_durability_bonus
	if data.has_active_modifier(ItemData.ActiveModifier.MUSTARD):
		data.actual_damage *= mustard_direct_damage_multiplier
		data.poison_damage = mustard_poison_damage
		data.poison_interval = mustard_poison_interval
		data.poison_duration = mustard_poison_duration
		data.poison_refresh_duration = mustard_poison_refresh_duration
	else:
		data.poison_damage = 0.0
		data.poison_interval = 0.0
		data.poison_duration = 0.0
	data.attack_form = ItemData.AttackForm.MELEE
	data.cooking_method = ItemData.CookingMethod.PAN_FRY
	data.stagger_power = tomahawk_stagger_power
	data.has_perfect_finisher = data.quality == ItemData.Quality.PERFECT and not data.is_weird_dish()
	data.current_durability = data.max_durability


func apply_white_rice_stats(data: ItemData) -> void:
	data.is_combat_dish = true
	data.base_damage = white_rice_damage
	data.actual_damage = white_rice_damage * (white_rice_perfect_damage_multiplier if data.quality == ItemData.Quality.PERFECT else 1.0)
	data.max_durability = white_rice_durability
	data.current_durability = data.max_durability
	data.attack_form = ItemData.AttackForm.PROJECTILE
	data.cooking_method = ItemData.CookingMethod.BOIL
	data.has_perfect_finisher = false
	data.emergency_edible = true


func apply_rice_porridge_stats(data: ItemData) -> void:
	data.is_combat_dish = true
	data.emergency_edible = false
	data.max_durability = rice_porridge_durability
	data.current_durability = data.max_durability
	data.use_duration = rice_porridge_use_time
	match data.quality:
		ItemData.Quality.PERFECT:
			data.healing_per_use = rice_porridge_perfect_heal
		ItemData.Quality.FLAWED:
			data.healing_per_use = rice_porridge_flawed_heal
		ItemData.Quality.BAD:
			data.healing_per_use = rice_porridge_bad_heal
		_:
			data.healing_per_use = rice_porridge_normal_heal


func apply_crispy_rice_stats(data: ItemData) -> void:
	data.is_combat_dish = true
	data.emergency_edible = false
	data.max_durability = crispy_rice_durability
	data.current_durability = data.max_durability
	data.cooking_method = ItemData.CookingMethod.BOIL
	match data.quality:
		ItemData.Quality.PERFECT:
			data.armor_reduction = crispy_rice_perfect_reduction
		ItemData.Quality.FLAWED:
			data.armor_reduction = crispy_rice_flawed_reduction
		ItemData.Quality.BAD:
			data.armor_reduction = crispy_rice_bad_reduction
		_:
			data.armor_reduction = crispy_rice_normal_reduction


func create_on_hit_effect(data: ItemData, source_faction: int = CombatRules.Faction.PLAYER) -> StatusEffectData:
	if data == null or data.poison_damage <= 0.0 or data.poison_duration <= 0.0:
		return null
	var effect := StatusEffectData.new()
	effect.effect_type = StatusEffectData.EffectType.POISON
	effect.damage_per_tick = data.poison_damage
	effect.tick_interval = data.poison_interval
	effect.duration = data.poison_duration
	effect.source_faction = source_faction
	effect.refresh_duration = data.poison_refresh_duration
	effect.attack_form = ItemData.AttackForm.DAMAGE_OVER_TIME
	effect.cooking_method = data.cooking_method
	return effect


func get_plate_wash_multiplier(dirty_count: int) -> float:
	if dirty_count >= 9:
		return wash_multiplier_nine_plus
	if dirty_count >= 5:
		return wash_multiplier_five_to_eight
	if dirty_count >= 2:
		return wash_multiplier_two_to_four
	return 1.0


func get_plate_wash_tier_text(dirty_count: int) -> String:
	if dirty_count >= 9:
		return "最高速度（9+）"
	if dirty_count >= 5:
		return "明显加速（5-8）"
	if dirty_count >= 2:
		return "轻微加速（2-4）"
	return "基础速度（1）"
