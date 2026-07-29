class_name ItemData
extends Resource

enum ItemType {
	RAW_BEEF_CHUNK,
	RAW_STEAK,
	RAW_BEEF_SLICES,
	MARINATED_BEEF_SLICES,
	MARINADE,
	CHILI_SEGMENTS,
	COOKING_OIL,
	UNPLATED_STIR_FRY_BEEF,
	CHARCOAL,
	WOK,
	CLEAN_PLATE,
	DIRTY_PLATE,
	PLATED_STIR_FRY_BEEF,
	SALT,
	MUSTARD,
	PAN,
	SOUP_POT,
	TOMAHAWK_STEAK,
	PLATED_TOMAHAWK_STEAK,
	BIG_BONE,
	SHABU_BEEF,
	MUSHY_BOILED_BEEF,
	RICE_BAG,
	RAW_RICE,
	UNPLATED_WHITE_RICE,
	PLATED_WHITE_RICE,
	UNPLATED_RICE_PORRIDGE,
	PLATED_RICE_PORRIDGE,
	UNPLATED_CRISPY_RICE,
	PLATED_CRISPY_RICE,
	WHOLE_GREENS,
	GREENS_LEAF,
	RAW_BEEF_DICE,
	MARINATED_BEEF_DICE,
	UNPLATED_BOILED_GREENS,
	PLATED_BOILED_GREENS,
	UNPLATED_STIR_FRY_GREENS,
	PLATED_STIR_FRY_GREENS,
	UNPLATED_SPICY_STIR_FRY_GREENS,
	PLATED_SPICY_STIR_FRY_GREENS,
	UNPLATED_FLASH_STIR_FRY_GREENS,
	PLATED_FLASH_STIR_FRY_GREENS,
	UNPLATED_GREENS_PORRIDGE,
	PLATED_GREENS_PORRIDGE,
	UNPLATED_BEEF_PORRIDGE,
	PLATED_BEEF_PORRIDGE,
	UNPLATED_PLAIN_BEEF_PORRIDGE,
	PLATED_PLAIN_BEEF_PORRIDGE,
	UNPLATED_BEEF_GREENS,
	PLATED_BEEF_GREENS,
	UNPLATED_GREENS_FRIED_RICE,
	PLATED_GREENS_FRIED_RICE,
	UNPLATED_BEEF_FRIED_RICE,
	PLATED_BEEF_FRIED_RICE,
	UNPLATED_MIXED_FRIED_RICE,
	PLATED_MIXED_FRIED_RICE,
	UNPLATED_VEGETABLE_RICE,
	PLATED_VEGETABLE_RICE,
	UNPLATED_SOAKED_RICE,
	PLATED_SOAKED_RICE,
	UNPLATED_GREENS_SOAKED_RICE,
	PLATED_GREENS_SOAKED_RICE,
	PLATED_BEEF_GREENS_RICE_BOWL,
	UNPLATED_BEEF_GREENS_SOUP,
	PLATED_BEEF_GREENS_SOUP,
	UNPLATED_MUSTARD_GREENS,
	PLATED_MUSTARD_GREENS,
	SMALL_RICE_BAG,
	ROTTEN_WASTE,
	UNPLATED_FRIED_WHITE_RICE,
	PLATED_FRIED_WHITE_RICE,
	UNPLATED_CLEAR_STIR_FRY_BEEF,
	PLATED_CLEAR_STIR_FRY_BEEF,
	UNPLATED_GREENS_SOUP,
	PLATED_GREENS_SOUP,
	UNPLATED_BEEF_SOUP,
	PLATED_BEEF_SOUP,
	UNPLATED_GREENS_RICE_BOWL,
	PLATED_GREENS_RICE_BOWL,
	UNPLATED_BEEF_RICE_BOWL,
	PLATED_BEEF_RICE_BOWL,
	GREENS_CRUMBS,
	UNPLATED_BEEF_BRAISED_RICE,
	PLATED_BEEF_BRAISED_RICE,
	UNPLATED_GREENS_BEEF_BRAISED_RICE,
	PLATED_GREENS_BEEF_BRAISED_RICE,
	UNPLATED_GREENS_BEEF_PORRIDGE,
	PLATED_GREENS_BEEF_PORRIDGE,
	UNPLATED_BEEF_SOAKED_RICE,
	PLATED_BEEF_SOAKED_RICE,
	UNPLATED_GREENS_BEEF_SOAKED_RICE,
	PLATED_GREENS_BEEF_SOAKED_RICE,
	UNPLATED_CRISPY_RICE_BEEF,
	PLATED_CRISPY_RICE_BEEF,
	UNPLATED_SPICY_FRIED_RICE,
	PLATED_SPICY_FRIED_RICE,
	UNPLATED_SPICY_BEEF_GREENS,
	PLATED_SPICY_BEEF_GREENS,
	UNPLATED_SPICY_BEEF_FRIED_RICE,
	PLATED_SPICY_BEEF_FRIED_RICE,
	UNPLATED_SPICY_MIXED_FRIED_RICE,
	PLATED_SPICY_MIXED_FRIED_RICE,
	UNPLATED_SPICY_BEEF_SOUP,
	PLATED_SPICY_BEEF_SOUP,
	UNPLATED_SPICY_BEEF_GREENS_SOUP,
	PLATED_SPICY_BEEF_GREENS_SOUP,
	UNPLATED_PAN_FRIED_RICE_CAKE,
	PLATED_PAN_FRIED_RICE_CAKE,
	UNPLATED_GREENS_RICE_CAKE,
	PLATED_GREENS_RICE_CAKE,
	UNPLATED_BEEF_RICE_CAKE,
	PLATED_BEEF_RICE_CAKE,
	UNPLATED_GREENS_BEEF_RICE_CAKE,
	PLATED_GREENS_BEEF_RICE_CAKE,
}

enum ProcessingState {
	RAW,
	CUT_ONCE,
	SLICED,
	MARINATED,
	AUXILIARY,
	STIR_FRY_STAGE_ONE,
	READY_TO_PLATE,
	OVERCOOKED,
	CHARCOAL,
	WOK_CLEAN,
	WOK_OILED,
	WOK_STUCK,
	PLATED,
	PAN_CLEAN,
	PAN_OILED,
	PAN_STUCK,
	PAN_FIRST_SIDE,
	PAN_FLIP_WINDOW,
	PAN_SECOND_SIDE,
	SOUP_POT_EMPTY,
	SOUP_POT_WATER,
	SOUP_POT_BOILING,
	SOUP_COOKING,
	SOUP_READY,
	RICE_RAW,
	RICE_COOKING,
	WHITE_RICE_READY,
	PORRIDGE_READY,
	CRISPY_RICE_READY,
	DICED,
	GREENS_WHOLE,
	GREENS_LEAVES,
	COMBINATION_COOKING,
	DEPLOYABLE_READY,
	AUTO_EQUIPMENT_READY,
}

enum PlateState {
	NONE,
	CLEAN,
	DIRTY,
}

enum StationType {
	CUTTING_BOARD,
	MARINATING,
	WOK,
	SINK,
	STOVE,
}

enum FailureTag {
	UNMARINATED,
	CHILI_TOO_EARLY,
	BURNT,
	FLIPPED_LATE,
	COLD_WATER_ENTRY,
	OVERBOILED,
	NEAR_EXPIRY,
	OUTSIDE_RAW,
}

enum FreshnessState {
	FRESH,
	STILL_FRESH,
	NEAR_EXPIRY,
	ROTTEN,
}

enum ComponentType {
	CHILI_SEGMENTS,
}

enum ActiveModifier {
	SALTED,
	MUSTARD,
}

enum Quality {
	PERFECT,
	NORMAL,
	FLAWED,
	BAD,
}

enum AttackForm {
	NONE,
	MELEE,
	PROJECTILE,
	TRAP,
	DAMAGE_OVER_TIME,
}

enum CookingMethod {
	NONE,
	STIR_FRY,
	PAN_FRY,
	BOIL,
	DEEP_FRY,
	STEAM,
	MIX,
	BRAISE,
}

enum DeploymentState {
	NONE,
	CARRIED_DISABLED,
	CARRIED_ENABLED,
	DEPLOYED,
	EFFECT_MAINTENANCE,
}

var item_type: int = ItemType.RAW_BEEF_CHUNK
var display_name: String = ""
var processing_state: int = ProcessingState.RAW
var is_ingredient: bool = false
var is_auxiliary: bool = false
var is_cookware: bool = false
var allowed_stations: Array[int] = []
var failure_tags: Array[int] = []
var components: Array[int] = []
var active_modifiers: Array[int] = []
var quality: int = Quality.NORMAL
var is_stackable: bool = false
var stack_count: int = 1
var max_stack_count: int = 1
var can_be_plated: bool = false
var is_combat_dish: bool = false
var current_durability: int = 0
var max_durability: int = 0
var base_damage: float = 0.0
var actual_damage: float = 0.0
var has_perfect_finisher: bool = false
var carried_plate_state: int = PlateState.NONE
var poison_damage: float = 0.0
var poison_interval: float = 0.0
var poison_duration: float = 0.0
var poison_refresh_duration: bool = true
var has_been_used: bool = false
var remaining_portions: int = 1
var attack_count: int = 0
var next_sneeze_attack: int = 0
var bone_thrown: bool = false
var attack_form: int = AttackForm.NONE
var cooking_method: int = CookingMethod.NONE
var stagger_power: float = 0.0
var max_remaining_portions: int = 1
var hot_time_left: float = 0.0
var emergency_edible: bool = false
var healing_per_use: float = 0.0
var use_duration: float = 0.0
var armor_reduction: float = 0.0
var recipe_id: StringName = &""
var ingredient_counts: Dictionary = {}
var ingredient_order: Array[StringName] = []
var completed_cooking_nodes: Array[StringName] = []
var quality_cap: int = Quality.PERFECT
var weird_recipe: bool = false
var deployment_state: int = DeploymentState.NONE
var source_recipe_instance_id: int = 0
var linked_target_ids: Array[int] = []
var leaf_count: int = 0
var beef_portion_count: int = 0
var is_marinated: bool = false
var auto_equipment_enabled: bool = false
var effect_values: Dictionary = {}
var spoilage_ratio: float = 0.0
var freshness_lifetime: float = 0.0
var freshness_clock_stamp: float = -1.0
var freshness_pause_reason: String = ""
var rotten_source_item_type: int = -1
var rotten_source_name: String = ""
var rotten_source_art_key: StringName = &""
var rotten_shape_cells: Array[Vector2i] = []
var waste_units_snapshot: int = 0
var waste_source_units: int = 0
var waste_penalty_settled: bool = false


func can_process_at(station_type: int) -> bool:
	return not is_rotten() and station_type in allowed_stations


func add_failure_tag(tag: int) -> void:
	if tag not in failure_tags:
		failure_tags.append(tag)
	recalculate_quality()


func has_failure_tag(tag: int) -> bool:
	return tag in failure_tags


func add_component(component: int) -> void:
	if component not in components:
		components.append(component)


func has_component(component: int) -> bool:
	return component in components


func add_active_modifier(modifier: int) -> void:
	if modifier not in active_modifiers:
		active_modifiers.append(modifier)


func has_active_modifier(modifier: int) -> bool:
	return modifier in active_modifiers


func is_weird_dish() -> bool:
	return weird_recipe or has_active_modifier(ActiveModifier.MUSTARD)


func get_active_modifiers_text() -> String:
	if active_modifiers.is_empty():
		return "无"
	var labels: PackedStringArray = []
	for modifier in active_modifiers:
		labels.append(get_active_modifier_text(modifier))
	return "、".join(labels)


func recalculate_quality() -> void:
	if failure_tags.is_empty():
		quality = Quality.NORMAL
	elif failure_tags.size() == 1:
		quality = Quality.FLAWED
	else:
		quality = Quality.BAD
	apply_quality_cap()


func apply_quality_cap() -> void:
	if is_weird_dish():
		quality_cap = maxi(quality_cap, Quality.NORMAL)
	quality = maxi(quality, quality_cap)


func set_quality_with_cap(requested_quality: int) -> void:
	quality = requested_quality
	apply_quality_cap()


func inherit_recipe_state(components_data: Array[ItemData]) -> void:
	for component_data in components_data:
		if component_data == null:
			continue
		for tag in component_data.failure_tags:
			add_failure_tag(tag)
		quality_cap = maxi(quality_cap, component_data.quality_cap)
		if component_data.is_weird_dish():
			weird_recipe = true
	apply_quality_cap()


func can_stack_with(other: ItemData) -> bool:
	return (
		other != null
		and is_stackable
		and other.is_stackable
		and item_type == other.item_type
		and processing_state == other.processing_state
		and failure_tags == other.failure_tags
		and components == other.components
		and active_modifiers == other.active_modifiers
		and quality == other.quality
		and carried_plate_state == other.carried_plate_state
		and is_combat_dish == other.is_combat_dish
		and current_durability == other.current_durability
		and max_durability == other.max_durability
		and base_damage == other.base_damage
		and actual_damage == other.actual_damage
		and has_perfect_finisher == other.has_perfect_finisher
		and poison_damage == other.poison_damage
		and poison_interval == other.poison_interval
		and poison_duration == other.poison_duration
		and poison_refresh_duration == other.poison_refresh_duration
		and has_been_used == other.has_been_used
		and remaining_portions == other.remaining_portions
		and attack_count == other.attack_count
		and next_sneeze_attack == other.next_sneeze_attack
		and bone_thrown == other.bone_thrown
		and attack_form == other.attack_form
		and cooking_method == other.cooking_method
		and stagger_power == other.stagger_power
		and max_remaining_portions == other.max_remaining_portions
		and hot_time_left == other.hot_time_left
		and emergency_edible == other.emergency_edible
		and healing_per_use == other.healing_per_use
		and use_duration == other.use_duration
		and armor_reduction == other.armor_reduction
		and recipe_id == other.recipe_id
		and ingredient_counts == other.ingredient_counts
		and ingredient_order == other.ingredient_order
		and completed_cooking_nodes == other.completed_cooking_nodes
		and quality_cap == other.quality_cap
		and weird_recipe == other.weird_recipe
		and deployment_state == other.deployment_state
		and source_recipe_instance_id == other.source_recipe_instance_id
		and linked_target_ids == other.linked_target_ids
		and leaf_count == other.leaf_count
		and beef_portion_count == other.beef_portion_count
		and is_marinated == other.is_marinated
		and auto_equipment_enabled == other.auto_equipment_enabled
		and effect_values == other.effect_values
		and _freshness_can_stack_with(other)
		and stack_count < max_stack_count
		and max_stack_count == other.max_stack_count
	)


func is_perishable() -> bool:
	return freshness_lifetime > 0.0 and item_type != ItemType.ROTTEN_WASTE


func get_freshness_state() -> int:
	if item_type == ItemType.ROTTEN_WASTE:
		return FreshnessState.ROTTEN
	return FreshnessCatalog.get_state_for_ratio(spoilage_ratio)


func get_freshness_text() -> String:
	match get_freshness_state():
		FreshnessState.FRESH:
			return "新鲜"
		FreshnessState.STILL_FRESH:
			return "尚鲜"
		FreshnessState.NEAR_EXPIRY:
			return "临期"
		FreshnessState.ROTTEN:
			return "腐败"
	return "未知"


func get_remaining_freshness_seconds() -> float:
	return maxf(0.0, freshness_lifetime * (1.0 - clampf(spoilage_ratio, 0.0, 1.0)))


func set_spoilage_ratio(value: float) -> bool:
	var previous_state := get_freshness_state()
	spoilage_ratio = clampf(value, 0.0, 1.0)
	var current_state := get_freshness_state()
	if current_state >= FreshnessState.NEAR_EXPIRY and item_type != ItemType.ROTTEN_WASTE:
		add_failure_tag(FailureTag.NEAR_EXPIRY)
		has_perfect_finisher = false
		current_durability = mini(current_durability, max_durability)
	return current_state != previous_state


func advance_spoilage(seconds: float) -> bool:
	if not is_perishable() or seconds <= 0.0:
		return false
	return set_spoilage_ratio(spoilage_ratio + seconds / maxf(0.001, freshness_lifetime))


func reset_freshness_cycle() -> void:
	freshness_lifetime = FreshnessCatalog.get_lifetime(item_type)
	spoilage_ratio = 0.0
	freshness_clock_stamp = -1.0
	freshness_pause_reason = ""


func is_rotten() -> bool:
	return item_type == ItemType.ROTTEN_WASTE or get_freshness_state() == FreshnessState.ROTTEN


func add_from_stack(other: ItemData, requested_amount: int = -1) -> int:
	if other == null or not can_stack_with(other):
		return 0
	var amount := other.stack_count if requested_amount < 0 else mini(requested_amount, other.stack_count)
	var accepted := mini(amount, max_stack_count - stack_count)
	if accepted <= 0:
		return 0
	if is_perishable() and other.is_perishable():
		var existing_units := float(_stack_freshness_units(stack_count))
		var incoming_units := float(other._stack_freshness_units(accepted))
		spoilage_ratio = (
			spoilage_ratio * existing_units + other.spoilage_ratio * incoming_units
		) / maxf(1.0, existing_units + incoming_units)
	stack_count += accepted
	return accepted


func _stack_freshness_units(count: int) -> int:
	if item_type == ItemType.GREENS_LEAF:
		return maxi(1, count)
	return maxi(1, count)


func _freshness_can_stack_with(other: ItemData) -> bool:
	if other == null or is_rotten() or other.is_rotten():
		return false
	if not is_perishable() and not other.is_perishable():
		return true
	if is_perishable() != other.is_perishable():
		return false
	var has_near := has_failure_tag(FailureTag.NEAR_EXPIRY)
	var other_has_near := other.has_failure_tag(FailureTag.NEAR_EXPIRY)
	if has_near != other_has_near:
		return false
	var state := get_freshness_state()
	var other_state := other.get_freshness_state()
	if state == FreshnessState.NEAR_EXPIRY or other_state == FreshnessState.NEAR_EXPIRY:
		return state == FreshnessState.NEAR_EXPIRY and other_state == FreshnessState.NEAR_EXPIRY
	return state in [FreshnessState.FRESH, FreshnessState.STILL_FRESH] and other_state in [FreshnessState.FRESH, FreshnessState.STILL_FRESH]


func is_eligible_for_plating() -> bool:
	return (
		not is_rotten()
		and
		can_be_plated
		and not has_been_used
		and max_durability > 0
		and current_durability == max_durability
		and deployment_state in [DeploymentState.NONE, DeploymentState.CARRIED_DISABLED]
	)


func mark_used() -> void:
	if not has_been_used and is_combat_dish and has_failure_tag(FailureTag.NEAR_EXPIRY):
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			var stats := tree.get_first_node_in_group("run_stats") as RunStats
			if stats != null:
				stats.record_near_expiry_dish_used()
	has_been_used = true


func is_hot() -> bool:
	return hot_time_left > 0.0


func add_to_stack(amount: int) -> int:
	if not is_stackable or amount <= 0:
		return 0
	var accepted := mini(amount, max_stack_count - stack_count)
	stack_count += accepted
	return accepted


func consume_stack_unit() -> bool:
	if stack_count <= 0:
		return false
	stack_count -= 1
	return true


func is_reusable_resource_container() -> bool:
	return item_type in [
		ItemType.COOKING_OIL,
		ItemType.SALT,
		ItemType.RICE_BAG,
		ItemType.SMALL_RICE_BAG,
	]


func consume_resource_portions(amount: int = 1) -> bool:
	if not is_reusable_resource_container() or amount <= 0 or remaining_portions < amount:
		return false
	remaining_portions -= amount
	return true


func get_portion_label() -> String:
	match item_type:
		ItemType.COOKING_OIL:
			return "油 %d/%d" % [remaining_portions, max_remaining_portions]
		ItemType.SALT:
			return "盐 %d/%d" % [remaining_portions, max_remaining_portions]
		ItemType.RICE_BAG, ItemType.SMALL_RICE_BAG:
			return "米 %d/%d" % [remaining_portions, max_remaining_portions]
	return ""


func get_failure_tags_text() -> String:
	if failure_tags.is_empty():
		return "无"
	var labels: PackedStringArray = []
	for tag in failure_tags:
		labels.append(get_failure_tag_text(tag))
	return " ".join(labels)


func get_quality_text() -> String:
	match quality:
		Quality.PERFECT:
			return "完美"
		Quality.NORMAL:
			return "正常"
		Quality.FLAWED:
			return "瑕疵"
		Quality.BAD:
			return "糟糕"
	return "未知"


static func get_failure_tag_text(tag: int) -> String:
	match tag:
		FailureTag.UNMARINATED:
			return "【未腌制·临时标签】"
		FailureTag.CHILI_TOO_EARLY:
			return "【辣椒过早·临时标签】"
		FailureTag.BURNT:
			return "【焦糊】"
		FailureTag.FLIPPED_LATE:
			return "【翻面过晚】"
		FailureTag.COLD_WATER_ENTRY:
			return "【冷水下锅】"
		FailureTag.OVERBOILED:
			return "【煮老】"
		FailureTag.OUTSIDE_RAW:
			return "【外焦里生】"
		FailureTag.NEAR_EXPIRY:
			return "【临期】"
	return "【未知标签】"


static func get_active_modifier_text(modifier: int) -> String:
	match modifier:
		ActiveModifier.SALTED:
			return "盐"
		ActiveModifier.MUSTARD:
			return "芥末"
	return "未知改造"
