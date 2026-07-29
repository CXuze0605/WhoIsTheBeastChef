class_name ExpandedRecipeCatalog
extends RefCounted

const BOILED_GREENS := &"boiled_greens"
const STIR_FRY_GREENS := &"stir_fry_greens"
const SPICY_STIR_FRY_GREENS := &"spicy_stir_fry_greens"
const FLASH_STIR_FRY_GREENS := &"flash_stir_fry_greens"
const GREENS_PORRIDGE := &"greens_porridge"
const BEEF_PORRIDGE := &"beef_porridge"
const PLAIN_BEEF_PORRIDGE := &"plain_beef_porridge"
const BEEF_GREENS := &"beef_greens"
const GREENS_FRIED_RICE := &"greens_fried_rice"
const BEEF_FRIED_RICE := &"beef_fried_rice"
const MIXED_FRIED_RICE := &"mixed_fried_rice"
const VEGETABLE_RICE := &"vegetable_rice"
const SOAKED_RICE := &"soaked_rice"
const GREENS_SOAKED_RICE := &"greens_soaked_rice"
const BEEF_GREENS_RICE_BOWL := &"beef_greens_rice_bowl"
const BEEF_GREENS_SOUP := &"beef_greens_soup"
const MUSTARD_GREENS := &"mustard_greens"
const FRIED_WHITE_RICE := &"fried_white_rice"
const CLEAR_STIR_FRY_BEEF := &"clear_stir_fry_beef"
const GREENS_SOUP := &"greens_soup"
const BEEF_SOUP := &"beef_soup"
const GREENS_RICE_BOWL := &"greens_rice_bowl"
const BEEF_RICE_BOWL := &"beef_rice_bowl"
const BEEF_BRAISED_RICE := &"beef_braised_rice"
const GREENS_BEEF_BRAISED_RICE := &"greens_beef_braised_rice"
const GREENS_BEEF_PORRIDGE := &"greens_beef_porridge"
const BEEF_SOAKED_RICE := &"beef_soaked_rice"
const GREENS_BEEF_SOAKED_RICE := &"greens_beef_soaked_rice"
const CRISPY_RICE_BEEF := &"crispy_rice_beef"
const SPICY_FRIED_RICE := &"spicy_fried_rice"
const SPICY_BEEF_GREENS := &"spicy_beef_greens"
const SPICY_BEEF_FRIED_RICE := &"spicy_beef_fried_rice"
const SPICY_MIXED_FRIED_RICE := &"spicy_mixed_fried_rice"
const SPICY_BEEF_SOUP := &"spicy_beef_soup"
const SPICY_BEEF_GREENS_SOUP := &"spicy_beef_greens_soup"
const PAN_FRIED_RICE_CAKE := &"pan_fried_rice_cake"
const GREENS_RICE_CAKE := &"greens_rice_cake"
const BEEF_RICE_CAKE := &"beef_rice_cake"
const GREENS_BEEF_RICE_CAKE := &"greens_beef_rice_cake"


static func create_boiled_greens(leaves: int, sources: Array[ItemData], config: PrototypeCombatConfig) -> ItemData:
	var result := ItemCatalog.create(ItemData.ItemType.UNPLATED_BOILED_GREENS)
	_initialize_recipe(result, BOILED_GREENS, sources)
	result.leaf_count = clampi(leaves, 1, 5)
	result.max_durability = result.leaf_count
	result.current_durability = result.max_durability
	result.effect_values = {
		"trigger_radius": config.boiled_greens_trigger_radius,
		"trigger_cooldown": config.boiled_greens_trigger_cooldown,
		"knockback": config.boiled_greens_knockback,
		"stun": config.boiled_greens_stun,
	}
	return result


static func create_stir_fry_greens(
	leaves: int,
	variant: StringName,
	sources: Array[ItemData],
	config: PrototypeCombatConfig
) -> ItemData:
	var target_type := ItemData.ItemType.UNPLATED_STIR_FRY_GREENS
	if variant == SPICY_STIR_FRY_GREENS:
		target_type = ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS
	elif variant == FLASH_STIR_FRY_GREENS:
		target_type = ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, variant, sources)
	result.leaf_count = clampi(leaves, 1, 5)
	result.max_durability = config.stir_fry_greens_durability
	result.current_durability = result.max_durability
	result.base_damage = config.flash_leaf_damage if variant == FLASH_STIR_FRY_GREENS else config.greens_leaf_damage
	result.actual_damage = result.base_damage
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT
	result.effect_values = {
		"projectile_speed": config.flash_leaf_speed if variant == FLASH_STIR_FRY_GREENS else config.greens_leaf_speed,
		"range": config.flash_leaf_range if variant == FLASH_STIR_FRY_GREENS else config.greens_leaf_range,
		"pierce": 1 if variant == FLASH_STIR_FRY_GREENS else config.greens_leaf_pierce_count,
		"vulnerability": config.spicy_vulnerability if variant == SPICY_STIR_FRY_GREENS else 0.0,
		"vulnerability_duration": config.spicy_vulnerability_duration,
		"choking_duration": config.choking_duration if variant == FLASH_STIR_FRY_GREENS else 0.0,
		"burst_radius": config.flash_leaf_burst_radius,
		"finisher_damage": config.flash_leaf_finisher_damage,
	}
	return result


static func create_porridge(
	recipe: StringName,
	leaves: int,
	sources: Array[ItemData],
	config: PrototypeCombatConfig
) -> ItemData:
	var target_type := ItemData.ItemType.UNPLATED_GREENS_PORRIDGE
	if recipe == BEEF_PORRIDGE:
		target_type = ItemData.ItemType.UNPLATED_BEEF_PORRIDGE
	elif recipe == PLAIN_BEEF_PORRIDGE:
		target_type = ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE
	elif recipe == GREENS_BEEF_PORRIDGE:
		target_type = ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = clampi(leaves, 0, 5)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	result.max_durability = config.porridge_durability
	if recipe == GREENS_BEEF_PORRIDGE:
		result.max_durability = config.greens_beef_porridge_durability
	result.current_durability = result.max_durability
	result.use_duration = (
		config.greens_beef_porridge_use_time
		if recipe == GREENS_BEEF_PORRIDGE
		else config.rice_porridge_use_time
	)
	result.hot_time_left = maxf(
		config.greens_porridge_min_hot_time,
		config.rice_porridge_hot_time - float(result.leaf_count) * config.greens_porridge_hot_reduction_per_leaf
	) if recipe == GREENS_PORRIDGE else config.rice_porridge_hot_time
	result.healing_per_use = config.beef_porridge_heal
	if recipe == GREENS_PORRIDGE:
		result.healing_per_use = config.greens_porridge_base_heal + float(result.leaf_count)
	elif recipe == GREENS_BEEF_PORRIDGE:
		result.healing_per_use = config.greens_beef_porridge_base_heal + float(result.leaf_count)
	result.effect_values = {
		"direct_bonus": (
			config.greens_beef_porridge_direct_bonus if recipe == GREENS_BEEF_PORRIDGE and result.is_marinated
			else config.greens_beef_porridge_unmarinated_bonus if recipe == GREENS_BEEF_PORRIDGE
			else config.beef_porridge_direct_bonus if recipe == BEEF_PORRIDGE
			else config.plain_beef_porridge_direct_bonus if recipe == PLAIN_BEEF_PORRIDGE
			else 0.0
		),
		"direct_bonus_duration": (
			config.greens_beef_porridge_bonus_duration
			if recipe == GREENS_BEEF_PORRIDGE
			else config.beef_porridge_bonus_duration
		),
		"perfect_bonus": (
			config.greens_beef_porridge_perfect_bonus
			if recipe == GREENS_BEEF_PORRIDGE
			else config.perfect_beef_porridge_direct_bonus
		),
		"perfect_bonus_duration": (
			config.greens_beef_porridge_perfect_bonus_duration
			if recipe == GREENS_BEEF_PORRIDGE
			else config.perfect_beef_porridge_bonus_duration
		),
		"perfect_hot_heal_per_second": (
			config.greens_beef_porridge_perfect_hot_heal_per_second
			if recipe == GREENS_BEEF_PORRIDGE
			else config.greens_porridge_hot_heal_per_second
		),
		"perfect_hot_heal_duration": (
			config.greens_beef_porridge_perfect_hot_heal_duration
			if recipe == GREENS_BEEF_PORRIDGE
			else config.greens_porridge_hot_heal_duration
		),
	}
	if recipe == GREENS_BEEF_PORRIDGE and not result.is_marinated:
		result.add_failure_tag(ItemData.FailureTag.UNMARINATED)
		result.quality_cap = ItemData.Quality.NORMAL
		result.recalculate_quality()
	return result


static func _initialize_recipe(result: ItemData, recipe: StringName, sources: Array[ItemData]) -> void:
	result.recipe_id = recipe
	if result.source_recipe_instance_id == 0:
		result.source_recipe_instance_id = result.get_instance_id()
	result.ingredient_counts.clear()
	result.ingredient_order.clear()
	for source in sources:
		if source == null:
			continue
		var key := StringName(str(source.item_type))
		result.ingredient_counts[key] = int(result.ingredient_counts.get(key, 0)) + max(
			1,
			FreshnessCatalog.get_actual_units(source)
		)
		result.ingredient_order.append(key)
	result.inherit_recipe_state(sources)
	for source in sources:
		if source == null:
			continue
		for modifier in source.active_modifiers:
			result.add_active_modifier(modifier)
		if source.item_type == ItemData.ItemType.SALT:
			result.add_active_modifier(ItemData.ActiveModifier.SALTED)
	result.recalculate_quality()


static func refresh_after_plating(data: ItemData, config: PrototypeCombatConfig) -> void:
	if data == null:
		return
	data.has_perfect_finisher = data.quality == ItemData.Quality.PERFECT and not data.is_weird_dish()
	if data.recipe_id in [FRIED_WHITE_RICE, GREENS_SOUP, BEEF_SOUP]:
		data.has_perfect_finisher = false
	if data.recipe_id == GREENS_PORRIDGE:
		data.healing_per_use = config.greens_porridge_base_heal + float(data.leaf_count)
	elif data.recipe_id in [BEEF_PORRIDGE, PLAIN_BEEF_PORRIDGE]:
		data.healing_per_use = config.beef_porridge_heal
	elif data.recipe_id == GREENS_BEEF_PORRIDGE:
		data.healing_per_use = config.greens_beef_porridge_base_heal + float(data.leaf_count)
	if data.current_durability <= 0 or not data.has_been_used:
		data.current_durability = data.max_durability


static func create_missing_group_1_dish(
	recipe: StringName,
	sources: Array[ItemData],
	config: PrototypeCombatConfig,
	leaves: int = 0
) -> ItemData:
	var target_type := ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE
	match recipe:
		CLEAR_STIR_FRY_BEEF:
			target_type = ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF
		GREENS_SOUP:
			target_type = ItemData.ItemType.UNPLATED_GREENS_SOUP
		BEEF_SOUP:
			target_type = ItemData.ItemType.UNPLATED_BEEF_SOUP
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = clampi(leaves if leaves > 0 else _sum_leaf_count(sources), 0, 5)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	var salted := result.has_active_modifier(ItemData.ActiveModifier.SALTED)
	if recipe in [GREENS_SOUP, BEEF_SOUP]:
		result.ingredient_counts[&"water"] = 2
		result.ingredient_order.insert(0, &"water")
	match recipe:
		FRIED_WHITE_RICE:
			result.max_durability = config.fried_white_rice_durability
			result.base_damage = config.fried_white_rice_grain_damage
			result.effect_values = {
				"grain_count": config.fried_white_rice_grain_count,
				"grain_damage": config.fried_white_rice_grain_damage,
				"grain_speed": config.fried_white_rice_grain_speed,
				"range": config.fried_white_rice_grain_range,
				"angle_jitter_degrees": config.fried_white_rice_angle_jitter_degrees,
				"move_slow": config.fried_white_rice_perfect_move_slow,
				"slow_duration": config.fried_white_rice_perfect_slow_duration,
			}
		CLEAR_STIR_FRY_BEEF:
			if not result.is_marinated:
				result.add_failure_tag(ItemData.FailureTag.UNMARINATED)
				result.quality_cap = ItemData.Quality.NORMAL
			result.max_durability = config.clear_beef_durability if result.is_marinated else config.clear_beef_unmarinated_durability
			result.base_damage = config.clear_beef_hit_damage * (1.0 if result.is_marinated else config.clear_beef_unmarinated_damage_multiplier)
			result.effect_values = {
				"hit_damage": result.base_damage,
				"range": config.clear_beef_range,
				"arc_degrees": config.clear_beef_arc_degrees,
				"combo_duration": config.clear_beef_combo_duration,
				"final_knockback": config.clear_beef_final_knockback,
				"perfect_hits": config.clear_beef_perfect_hits,
				"perfect_duration": config.clear_beef_perfect_duration,
				"perfect_final_arc": config.clear_beef_perfect_final_arc,
				"perfect_final_knockback": config.clear_beef_perfect_final_knockback,
				"perfect_final_stun": config.clear_beef_perfect_final_stun,
			}
		GREENS_SOUP:
			result.max_durability = config.greens_soup_base_durability + result.leaf_count
			result.base_damage = config.greens_soup_damage
			result.effect_values = {
				"range": config.greens_soup_range,
				"width": config.greens_soup_width,
				"tick_interval": config.greens_soup_tick_interval,
				"damage": config.greens_soup_damage,
				"knockback": config.greens_soup_knockback,
				"durability_interval": config.greens_soup_durability_interval,
				"move_slow": config.greens_soup_move_slow,
				"side_angle_degrees": config.greens_soup_side_angle_degrees,
				"side_multiplier": config.greens_soup_side_multiplier,
				"side_range_multiplier": config.greens_soup_side_range_multiplier,
			}
		BEEF_SOUP:
			if not result.is_marinated:
				result.add_failure_tag(ItemData.FailureTag.UNMARINATED)
				result.quality_cap = ItemData.Quality.NORMAL
			result.max_durability = config.beef_soup_durability if result.is_marinated else config.beef_soup_unmarinated_durability
			result.base_damage = config.beef_soup_damage if result.is_marinated else config.beef_soup_unmarinated_damage
			result.effect_values = {
				"range": config.beef_soup_range,
				"width": config.beef_soup_width,
				"tick_interval": config.beef_soup_tick_interval,
				"damage": result.base_damage,
				"durability_interval": config.beef_soup_durability_interval,
				"move_slow": config.beef_soup_move_slow,
				"focus_gain": config.beef_soup_focus_gain,
				"focus_max_stacks": config.beef_soup_focus_max_stacks,
				"focus_timeout": config.beef_soup_focus_timeout,
				"visual_fade_speed": config.beef_soup_visual_fade_speed,
			}
	if salted:
		result.max_durability += config.salt_durability_bonus
	result.current_durability = result.max_durability
	result.actual_damage = result.base_damage
	result.has_perfect_finisher = recipe == CLEAR_STIR_FRY_BEEF and result.quality == ItemData.Quality.PERFECT
	result.recalculate_quality()
	return result


static func create_group_2_rice_bowl(
	recipe: StringName,
	sources: Array[ItemData],
	config: PrototypeCombatConfig
) -> ItemData:
	var target_type := (
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL
		if recipe == GREENS_RICE_BOWL
		else ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL
	)
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = clampi(_sum_leaf_count(sources), 0, 5)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
	result.has_perfect_finisher = false
	if recipe == GREENS_RICE_BOWL:
		result.max_durability = config.greens_rice_bowl_base_durability + result.leaf_count
		result.effect_values = {
			"turret_kind": &"greens",
			"range": config.greens_rice_bowl_range,
			"interval": config.greens_rice_bowl_interval,
			"greens_damage": config.greens_rice_bowl_damage,
			"greens_range": config.greens_rice_bowl_range,
			"greens_pierce": config.greens_rice_bowl_pierce,
			"finisher_count": config.greens_rice_bowl_finisher_count,
			"finisher_arc_degrees": config.greens_rice_bowl_finisher_arc_degrees,
		}
	else:
		result.max_durability = config.beef_rice_bowl_base_durability + maxi(1, result.beef_portion_count)
		result.effect_values = {
			"turret_kind": &"beef",
			"range": config.beef_rice_bowl_range,
			"interval": config.beef_rice_bowl_interval,
			"beef_damage": config.beef_rice_bowl_damage,
			"beef_finisher_damage": config.beef_rice_bowl_finisher_damage,
		}
	result.current_durability = result.max_durability
	return result


static func create_group_3_braised_rice(
	recipe: StringName,
	sources: Array[ItemData],
	config: PrototypeCombatConfig
) -> ItemData:
	var target_type := (
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE
		if recipe == GREENS_BEEF_BRAISED_RICE
		else ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE
	)
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = _sum_leaf_count(sources)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	result.ingredient_counts[&"water"] = 1
	result.ingredient_order.insert(0, &"water")
	result.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
	if not result.is_marinated:
		result.add_failure_tag(ItemData.FailureTag.UNMARINATED)
		result.quality_cap = ItemData.Quality.NORMAL
		result.recalculate_quality()
	if recipe == GREENS_BEEF_BRAISED_RICE:
		result.max_durability = (
			config.greens_beef_braised_rice_durability
			if result.is_marinated
			else config.greens_beef_braised_rice_unmarinated_durability
		)
		result.effect_values = {
			"station_kind": &"greens_beef_braised",
			"bite_time": config.greens_beef_braised_rice_bite_time,
			"shield_per_bite": config.greens_beef_braised_rice_shield_per_bite,
			"direct_bonus": (
				config.greens_beef_braised_rice_direct_bonus
				if result.is_marinated
				else config.greens_beef_braised_rice_unmarinated_bonus
			),
			"direct_bonus_duration": config.greens_beef_braised_rice_bonus_duration,
			"perfect_shield": config.greens_beef_braised_rice_perfect_shield,
			"perfect_bonus": config.greens_beef_braised_rice_perfect_bonus,
			"perfect_bonus_duration": config.greens_beef_braised_rice_perfect_duration,
			"perfect_reduction": config.greens_beef_braised_rice_perfect_reduction,
			"perfect_reduction_duration": config.greens_beef_braised_rice_perfect_reduction_duration,
		}
	else:
		result.max_durability = (
			config.beef_braised_rice_durability
			if result.is_marinated
			else config.beef_braised_rice_unmarinated_durability
		)
		result.effect_values = {
			"station_kind": &"beef_braised",
			"bite_time": config.beef_braised_rice_bite_time,
			"shield_per_bite": 0.0,
			"direct_bonus": (
				config.beef_braised_rice_direct_bonus
				if result.is_marinated
				else config.beef_braised_rice_unmarinated_bonus
			),
			"direct_bonus_duration": config.beef_braised_rice_bonus_duration,
			"perfect_shield": 0.0,
			"perfect_bonus": config.beef_braised_rice_perfect_bonus,
			"perfect_bonus_duration": config.beef_braised_rice_perfect_duration,
			"perfect_reduction": 0.0,
			"perfect_reduction_duration": 0.0,
		}
	if result.has_active_modifier(ItemData.ActiveModifier.SALTED):
		result.max_durability += config.salt_durability_bonus
	result.current_durability = result.max_durability
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT
	return result


static func create_group_5_crispy_beef(
	sources: Array[ItemData],
	config: PrototypeCombatConfig
) -> ItemData:
	var result := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF)
	_initialize_recipe(result, CRISPY_RICE_BEEF, sources)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	result.max_durability = 1
	result.current_durability = 1
	result.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
	result.effect_values = {
		"place_distance": config.crispy_beef_place_distance,
		"main_arm_time": config.crispy_beef_main_arm_time,
		"main_trigger_radius": config.crispy_beef_main_trigger_radius,
		"main_radius": config.crispy_beef_main_radius,
		"main_damage": config.crispy_beef_main_damage,
		"main_friendly_multiplier": config.crispy_beef_main_friendly_damage_multiplier,
		"main_knockback": config.crispy_beef_main_knockback,
		"fragment_count": config.crispy_beef_fragment_count,
		"fragment_scatter_min": config.crispy_beef_fragment_scatter_min,
		"fragment_scatter_max": config.crispy_beef_fragment_scatter_max,
		"fragment_arm_time": config.crispy_beef_fragment_arm_time,
		"fragment_lifetime": config.crispy_beef_fragment_lifetime,
		"fragment_trigger_radius": config.crispy_beef_fragment_trigger_radius,
		"fragment_radius": config.crispy_beef_fragment_radius,
		"fragment_damage": config.crispy_beef_fragment_damage,
		"fragment_friendly_multiplier": config.crispy_beef_fragment_friendly_damage_multiplier,
		"fragment_knockback": config.crispy_beef_fragment_knockback,
		"perfect_main_radius": config.crispy_beef_perfect_main_radius,
		"perfect_main_damage": config.crispy_beef_perfect_main_damage,
		"perfect_fragment_count": config.crispy_beef_perfect_fragment_count,
		"perfect_scatter_min": config.crispy_beef_perfect_scatter_min,
		"perfect_scatter_max": config.crispy_beef_perfect_scatter_max,
	}
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT
	return result


static func create_wok_combination(
	recipe: StringName,
	sources: Array[ItemData],
	config: PrototypeCombatConfig
) -> ItemData:
	var target_type := ItemData.ItemType.UNPLATED_BEEF_GREENS
	if recipe == GREENS_FRIED_RICE:
		target_type = ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE
	elif recipe == BEEF_FRIED_RICE:
		target_type = ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE
	elif recipe == MIXED_FRIED_RICE:
		target_type = ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = _sum_leaf_count(sources)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	if recipe in [BEEF_GREENS, BEEF_FRIED_RICE, MIXED_FRIED_RICE] and not result.is_marinated:
		result.quality_cap = ItemData.Quality.NORMAL
		result.recalculate_quality()
	match recipe:
		BEEF_GREENS:
			result.max_durability = config.beef_greens_durability
			result.base_damage = config.beef_greens_center_damage
			result.attack_form = ItemData.AttackForm.MELEE
			result.effect_values = {
				"center_damage": config.beef_greens_center_damage,
				"side_damage": config.beef_greens_side_damage,
				"range": config.beef_greens_range,
				"arc_degrees": config.beef_greens_arc_degrees,
				"center_degrees": config.beef_greens_center_degrees,
				"knockback": config.beef_greens_knockback,
			}
		GREENS_FRIED_RICE:
			result.max_durability = config.greens_fried_rice_durability
			result.base_damage = config.greens_fried_rice_damage
			result.effect_values = {
				"aoe_damage": config.greens_fried_rice_damage,
				"radius": config.greens_fried_rice_radius,
				"perfect_radius": config.greens_fried_rice_perfect_radius,
			}
		BEEF_FRIED_RICE:
			result.max_durability = config.beef_fried_rice_durability
			result.base_damage = config.beef_fried_rice_damage * (1.0 if result.is_marinated else config.unmarinated_fried_rice_damage_multiplier)
			result.effect_values = {
				"single_damage": result.base_damage,
				"snap_radius": config.beef_fried_rice_snap_radius,
				"stagger": config.beef_fried_rice_stagger,
				"perfect_multiplier": config.beef_fried_rice_perfect_multiplier,
			}
		MIXED_FRIED_RICE:
			result.max_durability = config.mixed_fried_rice_durability
			result.base_damage = config.mixed_fried_rice_primary_damage * (1.0 if result.is_marinated else config.unmarinated_fried_rice_damage_multiplier)
			result.effect_values = {
				"single_damage": result.base_damage,
				"aoe_damage": config.mixed_fried_rice_aoe_damage,
				"radius": config.mixed_fried_rice_radius,
				"perfect_radius": config.mixed_fried_rice_perfect_radius,
				"snap_radius": config.mixed_fried_rice_snap_radius,
				"stagger": config.mixed_fried_rice_stagger,
				"perfect_multiplier": config.mixed_fried_rice_perfect_multiplier,
			}
	result.actual_damage = result.base_damage
	result.current_durability = result.max_durability
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT
	return result


static func _sum_leaf_count(sources: Array[ItemData]) -> int:
	var total := 0
	for source in sources:
		if source != null:
			total += (
				maxi(source.leaf_count, source.stack_count)
				if source.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]
				else source.leaf_count
			)
	return clampi(total, 0, 5)


static func _sum_beef_portions(sources: Array[ItemData]) -> int:
	var total := 0
	for source in sources:
		if source != null:
			total += source.beef_portion_count
	return total


static func _contains_marinated_beef(sources: Array[ItemData]) -> bool:
	for source in sources:
		if source != null and source.is_marinated:
			return true
	return false


static func create_rice_function_dish(
	recipe: StringName,
	leaves: int,
	sources: Array[ItemData],
	config: PrototypeCombatConfig,
	recommended_order: bool = true
) -> ItemData:
	var target_type := ItemData.ItemType.UNPLATED_VEGETABLE_RICE
	if recipe == SOAKED_RICE:
		target_type = ItemData.ItemType.UNPLATED_SOAKED_RICE
	elif recipe == GREENS_SOAKED_RICE:
		target_type = ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE
	elif recipe == BEEF_SOAKED_RICE:
		target_type = ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE
	elif recipe == GREENS_BEEF_SOAKED_RICE:
		target_type = ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = clampi(leaves, 0, 5)
	if not recommended_order:
		result.quality_cap = ItemData.Quality.NORMAL
		result.recalculate_quality()
	match recipe:
		VEGETABLE_RICE:
			result.max_durability = config.vegetable_rice_durability
			result.effect_values = {
				"shield_per_bite": config.vegetable_rice_shield_per_bite,
				"bite_time": config.vegetable_rice_bite_time,
				"final_reduction": config.vegetable_rice_final_reduction,
				"final_reduction_duration": config.vegetable_rice_final_reduction_duration,
			}
		SOAKED_RICE, GREENS_SOAKED_RICE, BEEF_SOAKED_RICE, GREENS_BEEF_SOAKED_RICE:
			result.max_durability = config.soaked_rice_durability
			result.beef_portion_count = clampi(_sum_beef_portions(sources), 0, 5)
			result.effect_values = {
				"radius": config.soaked_rice_radius,
				"duration": config.soaked_rice_zone_duration,
				"perfect_radius": config.perfect_soaked_rice_radius,
				"perfect_duration": config.perfect_soaked_rice_duration,
				"move_slow": config.soaked_rice_move_slow,
				"attack_slow": config.soaked_rice_attack_slow,
				"perfect_move_slow": config.perfect_soaked_rice_move_slow,
				"perfect_attack_slow": config.perfect_soaked_rice_attack_slow,
				"weakness": (
					minf(config.greens_soaked_rice_weakness_cap, float(result.leaf_count) * config.greens_soaked_rice_weakness_per_leaf)
					if recipe in [GREENS_SOAKED_RICE, GREENS_BEEF_SOAKED_RICE]
					else 0.0
				),
				"perfect_weakness": (
					minf(config.perfect_greens_soaked_rice_weakness_cap, float(result.leaf_count) * config.perfect_greens_soaked_rice_weakness_per_leaf)
					if recipe == GREENS_BEEF_SOAKED_RICE
					else 0.0
				),
				"vulnerability": (
					minf(config.beef_soaked_rice_vulnerability_cap, float(result.beef_portion_count) * config.beef_soaked_rice_vulnerability_per_portion)
					if recipe in [BEEF_SOAKED_RICE, GREENS_BEEF_SOAKED_RICE]
					else 0.0
				),
				"perfect_vulnerability": (
					minf(config.perfect_beef_soaked_rice_vulnerability_cap, float(result.beef_portion_count) * config.perfect_beef_soaked_rice_vulnerability_per_portion)
					if recipe in [BEEF_SOAKED_RICE, GREENS_BEEF_SOAKED_RICE]
					else 0.0
				),
			}
	result.current_durability = result.max_durability
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT
	return result


static func create_advanced_dish(
	recipe: StringName,
	leaves: int,
	sources: Array[ItemData],
	config: PrototypeCombatConfig,
	recommended_order: bool = true
) -> ItemData:
	var target_type := ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL
	if recipe == BEEF_GREENS_SOUP:
		target_type = ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP
	elif recipe == MUSTARD_GREENS:
		target_type = ItemData.ItemType.UNPLATED_MUSTARD_GREENS
	var result := ItemCatalog.create(target_type)
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = clampi(leaves, 0, config.mustard_greens_max_leaves)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	if not recommended_order:
		result.quality_cap = ItemData.Quality.NORMAL
	if recipe == BEEF_GREENS_SOUP and not result.is_marinated:
		result.quality_cap = ItemData.Quality.NORMAL
	if recipe == MUSTARD_GREENS:
		result.weird_recipe = true
		result.quality_cap = ItemData.Quality.NORMAL
	result.recalculate_quality()
	match recipe:
		BEEF_GREENS_RICE_BOWL:
			result.max_durability = config.rice_bowl_turret_durability
			result.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
			result.effect_values = {
				"range": config.rice_bowl_turret_range,
				"interval": config.rice_bowl_turret_interval,
				"rice_damage": config.rice_bowl_rice_damage,
				"rice_radius": config.rice_bowl_rice_radius,
				"greens_damage": config.rice_bowl_greens_damage,
				"greens_range": config.rice_bowl_greens_range,
				"beef_damage": config.rice_bowl_beef_damage,
			}
		BEEF_GREENS_SOUP:
			result.max_durability = config.beef_greens_soup_durability
			result.deployment_state = ItemData.DeploymentState.CARRIED_DISABLED
			result.effect_values = {
				"range": config.beef_greens_soup_range,
				"turn_speed": config.beef_greens_soup_turn_speed,
				"tick_interval": config.beef_greens_soup_tick_interval,
				"center_damage": config.beef_greens_soup_center_damage * (1.0 if result.is_marinated else 0.86),
				"outer_damage": config.beef_greens_soup_outer_damage,
				"knockback": config.beef_greens_soup_knockback,
				"finisher_damage": config.beef_greens_soup_finisher_damage,
				"finisher_radius": config.beef_greens_soup_finisher_radius,
			}
		MUSTARD_GREENS:
			result.max_durability = maxi(1, result.leaf_count)
			result.attack_form = ItemData.AttackForm.PROJECTILE
			result.effect_values = {
				"projectile_speed": config.mustard_greens_projectile_speed,
				"range": config.mustard_greens_range,
				"primary_weakness": config.mustard_primary_weakness,
				"primary_move_slow": config.mustard_primary_move_slow,
				"primary_attack_slow": config.mustard_primary_attack_slow,
				"primary_vulnerability": config.mustard_primary_vulnerability,
				"aura_radius": config.mustard_aura_radius,
				"aura_move_slow": config.mustard_aura_move_slow,
				"aura_vulnerability": config.mustard_aura_vulnerability,
				"carrier_vulnerability": config.mustard_carrier_vulnerability,
				"nearest_teammate_slow": config.mustard_nearest_teammate_slow,
			}
	result.current_durability = result.max_durability
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT and not result.is_weird_dish()
	return result


static func create_groups_6_7_dish(
	recipe: StringName,
	sources: Array[ItemData],
	config: PrototypeCombatConfig,
	leaves: int = 0
) -> ItemData:
	var type_by_recipe := {
		SPICY_FRIED_RICE: ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE,
		SPICY_BEEF_GREENS: ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS,
		SPICY_BEEF_FRIED_RICE: ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE,
		SPICY_MIXED_FRIED_RICE: ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE,
		SPICY_BEEF_SOUP: ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP,
		SPICY_BEEF_GREENS_SOUP: ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP,
		PAN_FRIED_RICE_CAKE: ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE,
		GREENS_RICE_CAKE: ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE,
		BEEF_RICE_CAKE: ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE,
		GREENS_BEEF_RICE_CAKE: ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE,
	}
	if not type_by_recipe.has(recipe):
		return null
	var result := ItemCatalog.create(int(type_by_recipe[recipe]))
	_initialize_recipe(result, recipe, sources)
	result.leaf_count = clampi(leaves if leaves > 0 else _sum_leaf_count(sources), 0, 5)
	result.beef_portion_count = _sum_beef_portions(sources)
	result.is_marinated = _contains_marinated_beef(sources)
	var has_beef := recipe in [
		SPICY_BEEF_GREENS, SPICY_BEEF_FRIED_RICE, SPICY_MIXED_FRIED_RICE,
		SPICY_BEEF_SOUP, SPICY_BEEF_GREENS_SOUP, BEEF_RICE_CAKE, GREENS_BEEF_RICE_CAKE,
	]
	if has_beef and not result.is_marinated:
		result.add_failure_tag(ItemData.FailureTag.UNMARINATED)
		result.quality_cap = ItemData.Quality.NORMAL
	result.attack_form = ItemData.AttackForm.PROJECTILE
	result.cooking_method = ItemData.CookingMethod.STIR_FRY
	match recipe:
		SPICY_FRIED_RICE:
			result.max_durability = config.spicy_fried_rice_durability
			result.base_damage = config.spicy_fried_rice_grain_damage
			result.effect_values = {
				"grain_count": config.spicy_fried_rice_grain_count,
				"grain_damage": config.spicy_fried_rice_grain_damage,
				"range": config.spicy_fried_rice_range,
				"interval": config.spicy_fried_rice_interval,
				"vulnerability": config.spicy_fried_rice_vulnerability,
				"vulnerability_duration": config.spicy_fried_rice_vulnerability_duration,
				"perfect_vulnerability": config.spicy_fried_rice_perfect_vulnerability,
				"perfect_duration": config.spicy_fried_rice_perfect_duration,
				"second_ring_delay": config.spicy_fried_rice_second_ring_delay,
			}
		SPICY_BEEF_GREENS:
			result.attack_form = ItemData.AttackForm.MELEE
			result.max_durability = config.spicy_beef_greens_durability
			result.base_damage = config.spicy_beef_greens_center_damage
			result.effect_values = {
				"range": config.spicy_beef_greens_range,
				"arc": config.spicy_beef_greens_arc,
				"center_arc": config.spicy_beef_greens_center_arc,
				"center_damage": config.spicy_beef_greens_center_damage,
				"side_damage": config.spicy_beef_greens_side_damage,
				"interval": config.spicy_beef_greens_interval,
				"vulnerability": config.spicy_beef_greens_vulnerability if result.is_marinated else config.spicy_beef_greens_unmarinated_vulnerability,
				"vulnerability_duration": config.spicy_beef_greens_vulnerability_duration,
				"knockback": config.spicy_beef_greens_knockback,
				"perfect_radius": config.spicy_beef_greens_perfect_radius,
				"perfect_damage": config.spicy_beef_greens_perfect_damage,
				"perfect_vulnerability": config.spicy_beef_greens_perfect_vulnerability,
				"perfect_duration": config.spicy_beef_greens_perfect_duration,
			}
		SPICY_BEEF_FRIED_RICE:
			result.max_durability = config.spicy_beef_fried_rice_durability
			result.base_damage = config.spicy_beef_fried_rice_damage if result.is_marinated else config.spicy_beef_fried_rice_unmarinated_damage
			result.effect_values = {
				"single_damage": result.base_damage,
				"snap_radius": config.spicy_beef_fried_rice_snap_radius,
				"stun": config.spicy_beef_fried_rice_stun,
				"interval": config.spicy_beef_fried_rice_interval,
				"vulnerability": config.spicy_beef_fried_rice_vulnerability if result.is_marinated else config.spicy_beef_fried_rice_unmarinated_vulnerability,
				"vulnerability_duration": config.spicy_beef_fried_rice_duration,
				"perfect_damage": config.spicy_beef_fried_rice_perfect_damage,
				"perfect_vulnerability": config.spicy_beef_fried_rice_perfect_vulnerability,
				"perfect_duration": config.spicy_beef_fried_rice_perfect_duration,
				"perfect_stun": config.spicy_beef_fried_rice_perfect_stun,
			}
		SPICY_MIXED_FRIED_RICE:
			result.max_durability = config.spicy_mixed_fried_rice_durability
			result.base_damage = config.spicy_mixed_fried_rice_main_damage if result.is_marinated else config.spicy_mixed_fried_rice_unmarinated_main_damage
			result.effect_values = {
				"single_damage": result.base_damage,
				"aoe_damage": config.spicy_mixed_fried_rice_splash_damage if result.is_marinated else config.spicy_mixed_fried_rice_unmarinated_splash_damage,
				"radius": config.spicy_mixed_fried_rice_radius,
				"range": config.spicy_mixed_fried_rice_range,
				"interval": config.spicy_mixed_fried_rice_interval,
				"vulnerability": config.spicy_mixed_fried_rice_vulnerability if result.is_marinated else config.spicy_mixed_fried_rice_unmarinated_vulnerability,
				"vulnerability_duration": config.spicy_mixed_fried_rice_duration,
				"perfect_damage": config.spicy_mixed_fried_rice_perfect_main_damage,
				"perfect_aoe_damage": config.spicy_mixed_fried_rice_perfect_splash_damage,
				"perfect_radius": config.spicy_mixed_fried_rice_perfect_radius,
				"perfect_vulnerability": config.spicy_mixed_fried_rice_perfect_vulnerability,
				"perfect_duration": config.spicy_mixed_fried_rice_perfect_duration,
				"perfect_knockback": config.spicy_mixed_fried_rice_perfect_knockback,
			}
		SPICY_BEEF_SOUP:
			result.cooking_method = ItemData.CookingMethod.BOIL
			result.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
			result.auto_equipment_enabled = true
			result.deployment_state = ItemData.DeploymentState.CARRIED_ENABLED
			result.max_durability = config.spicy_beef_soup_durability
			result.base_damage = config.spicy_beef_soup_damage if result.is_marinated else config.spicy_beef_soup_unmarinated_damage
			result.effect_values = {
				"range": config.spicy_beef_soup_range, "width": config.spicy_beef_soup_width,
				"tick_interval": config.spicy_beef_soup_tick_interval, "damage": result.base_damage,
				"durability_interval": config.spicy_beef_soup_durability_interval,
				"vulnerability_per_stack": config.spicy_beef_soup_vulnerability_per_stack if result.is_marinated else config.spicy_beef_soup_unmarinated_vulnerability_per_stack,
				"max_stacks": config.spicy_beef_soup_max_stacks, "stack_timeout": config.spicy_beef_soup_stack_timeout,
				"finisher_range": config.spicy_beef_soup_finisher_range, "finisher_width": config.spicy_beef_soup_finisher_width,
				"finisher_duration": config.spicy_beef_soup_finisher_duration, "finisher_damage": config.spicy_beef_soup_finisher_damage,
				"finisher_vulnerability": config.spicy_beef_soup_finisher_vulnerability,
				"finisher_status_duration": config.spicy_beef_soup_finisher_status_duration,
			}
		SPICY_BEEF_GREENS_SOUP:
			result.cooking_method = ItemData.CookingMethod.BOIL
			result.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
			result.auto_equipment_enabled = true
			result.deployment_state = ItemData.DeploymentState.CARRIED_ENABLED
			result.max_durability = config.spicy_beef_greens_soup_base_durability + result.leaf_count
			result.base_damage = 0.0
			result.effect_values = {
				"range": config.spicy_beef_greens_soup_range,
				"width": minf(config.spicy_beef_greens_soup_max_width, config.spicy_beef_greens_soup_base_width + maxf(0.0, float(result.leaf_count - 1)) * config.spicy_beef_greens_soup_width_per_extra_leaf),
				"interval": config.spicy_beef_greens_soup_interval,
				"primary_vulnerability": config.spicy_beef_greens_soup_primary_vulnerability if result.is_marinated else config.spicy_beef_greens_soup_unmarinated_primary_vulnerability,
				"primary_weakness": config.spicy_beef_greens_soup_primary_weakness if result.is_marinated else config.spicy_beef_greens_soup_unmarinated_primary_weakness,
				"line_vulnerability": config.spicy_beef_greens_soup_line_vulnerability if result.is_marinated else config.spicy_beef_greens_soup_unmarinated_line_vulnerability,
				"line_weakness": config.spicy_beef_greens_soup_line_weakness if result.is_marinated else config.spicy_beef_greens_soup_unmarinated_line_weakness,
				"status_duration": config.spicy_beef_greens_soup_status_duration,
				"finisher_radius": config.spicy_beef_greens_soup_finisher_radius,
				"finisher_vulnerability": config.spicy_beef_greens_soup_finisher_vulnerability,
				"finisher_weakness": config.spicy_beef_greens_soup_finisher_weakness,
				"finisher_duration": config.spicy_beef_greens_soup_finisher_duration,
			}
		PAN_FRIED_RICE_CAKE:
			result.cooking_method = ItemData.CookingMethod.PAN_FRY
			result.max_durability = config.pan_fried_rice_cake_durability
			result.base_damage = config.pan_fried_rice_cake_out_damage
			result.effect_values = {
				"out_damage": config.pan_fried_rice_cake_out_damage, "return_damage": config.pan_fried_rice_cake_return_damage,
				"range": config.pan_fried_rice_cake_range, "speed": config.pan_fried_rice_cake_speed,
				"pierce": config.pan_fried_rice_cake_pierce, "interval": config.pan_fried_rice_cake_interval,
				"perfect_out_damage": config.pan_fried_rice_cake_perfect_out_damage,
				"perfect_return_damage": config.pan_fried_rice_cake_perfect_return_damage,
				"perfect_orbit_radius": config.pan_fried_rice_cake_perfect_orbit_radius,
				"perfect_orbit_duration": config.pan_fried_rice_cake_perfect_orbit_duration,
				"perfect_orbit_damage": config.pan_fried_rice_cake_perfect_orbit_damage,
			}
		GREENS_RICE_CAKE:
			result.cooking_method = ItemData.CookingMethod.PAN_FRY
			result.max_durability = config.greens_rice_cake_base_durability + result.leaf_count
			result.base_damage = config.greens_rice_cake_damage
			result.effect_values = {
				"orbit_radius": config.greens_rice_cake_orbit_radius, "lap_time": config.greens_rice_cake_lap_time,
				"damage": config.greens_rice_cake_damage, "slow": config.greens_rice_cake_slow,
				"slow_duration": config.greens_rice_cake_slow_duration, "hit_cooldown": config.greens_rice_cake_hit_cooldown,
				"max_lifetime": config.greens_rice_cake_max_lifetime, "perfect_damage": config.greens_rice_cake_perfect_damage,
				"perfect_slow": config.greens_rice_cake_perfect_slow, "perfect_slow_duration": config.greens_rice_cake_perfect_slow_duration,
				"leaf_damage": config.greens_rice_cake_leaf_damage,
			}
		BEEF_RICE_CAKE:
			result.cooking_method = ItemData.CookingMethod.PAN_FRY
			result.max_durability = config.beef_rice_cake_max_hits + (1 if result.has_active_modifier(ItemData.ActiveModifier.SALTED) else 0)
			result.base_damage = config.beef_rice_cake_damage if result.is_marinated else config.beef_rice_cake_unmarinated_damage
			result.effect_values = {
				"damage": result.base_damage, "target_radius": config.beef_rice_cake_target_radius,
				"same_target_cooldown": config.beef_rice_cake_same_target_cooldown, "knockback": config.beef_rice_cake_knockback,
				"stun": config.beef_rice_cake_stun if result.is_marinated else config.beef_rice_cake_unmarinated_stun,
				"max_lifetime": config.beef_rice_cake_lifetime,
				"perfect_hits": [config.beef_rice_cake_perfect_hit_1, config.beef_rice_cake_perfect_hit_2, config.beef_rice_cake_perfect_hit_3, config.beef_rice_cake_perfect_hit_4],
				"slam_damage": config.beef_rice_cake_perfect_slam_damage, "slam_radius": config.beef_rice_cake_perfect_slam_radius,
				"splash_damage": config.beef_rice_cake_perfect_splash_damage, "perfect_stun": config.beef_rice_cake_perfect_stun,
			}
		GREENS_BEEF_RICE_CAKE:
			result.cooking_method = ItemData.CookingMethod.PAN_FRY
			result.max_durability = 5
			result.base_damage = config.mixed_rice_cake_body_damages[0]
			result.effect_values = {
				"orbit_radius": config.mixed_rice_cake_orbit_radius, "lap_time": config.mixed_rice_cake_lap_time,
				"body_damages": config.mixed_rice_cake_body_damages, "body_slow": config.mixed_rice_cake_body_slow,
				"body_slow_duration": config.mixed_rice_cake_body_slow_duration, "body_hit_cooldown": config.mixed_rice_cake_body_hit_cooldown,
				"split_interval": config.mixed_rice_cake_split_interval, "max_lifetime": config.mixed_rice_cake_max_lifetime,
				"split_target_radius": config.mixed_rice_cake_split_target_radius,
				"split_hits": config.mixed_rice_cake_salted_split_hits if result.has_active_modifier(ItemData.ActiveModifier.SALTED) else config.mixed_rice_cake_split_hits,
				"split_damage": config.mixed_rice_cake_split_damage if result.is_marinated else config.mixed_rice_cake_unmarinated_split_damage,
				"split_same_target_cooldown": config.mixed_rice_cake_split_same_target_cooldown,
				"split_slow": config.mixed_rice_cake_split_slow, "split_slow_duration": config.mixed_rice_cake_split_slow_duration,
				"split_knockback": config.mixed_rice_cake_split_knockback, "split_stun": config.mixed_rice_cake_split_stun,
				"core_hits": config.mixed_rice_cake_core_hits, "core_damage": config.mixed_rice_cake_core_damage,
				"core_stun": config.mixed_rice_cake_core_stun, "core_final_damage": config.mixed_rice_cake_core_final_damage,
				"core_radius": config.mixed_rice_cake_core_radius, "core_splash_damage": config.mixed_rice_cake_core_splash_damage,
				"core_slow": config.mixed_rice_cake_core_slow, "core_slow_duration": config.mixed_rice_cake_core_slow_duration,
			}
	if result.has_active_modifier(ItemData.ActiveModifier.SALTED) and recipe not in [BEEF_RICE_CAKE, GREENS_BEEF_RICE_CAKE]:
		result.max_durability += config.salt_durability_bonus
	result.actual_damage = result.base_damage
	result.current_durability = result.max_durability
	result.is_combat_dish = true
	result.can_be_plated = true
	result.recalculate_quality()
	result.has_perfect_finisher = result.quality == ItemData.Quality.PERFECT
	return result
