class_name PrototypeCombatConfig
extends Resource

@export_category("Dish attributes - Prototype values")
@export var standard_damage: float = 20.0
@export var standard_durability: int = 5
@export var flawed_durability_multiplier: float = 0.7
@export var bad_damage_multiplier: float = 0.7
@export var bad_durability_multiplier: float = 0.5
@export var attack_interval: float = 0.35

@export_category("Tomahawk steak melee - Prototype values")
@export var tomahawk_damage: float = 42.0
@export var tomahawk_durability: int = 4
@export var tomahawk_attack_interval: float = 0.78
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
