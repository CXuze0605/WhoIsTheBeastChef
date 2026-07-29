class_name FreshnessCatalog
extends RefCounted

# Prototype freshness and waste values are centralized here. They are deliberately
# generous for the first playable pass and are not final balance values.
const FRESH_LIMIT := 0.40
const STILL_FRESH_LIMIT := 0.75

const RAW_CHUNK_LIFETIME := 720.0
const RAW_STEAK_LIFETIME := 600.0
const RAW_SMALL_CUT_LIFETIME := 420.0
const MARINATED_BEEF_LIFETIME := 660.0
const WHOLE_GREENS_LIFETIME := 540.0
const GREENS_LEAF_LIFETIME := 360.0
const DISH_LIFETIME := 600.0

const WASTE_HEALTH_PER_UNIT := 0.005
const WASTE_DAMAGE_PER_UNIT := 0.0025
const FALLBACK_DISH_WASTE_UNITS := 1

const DISH_TYPES: Array[int] = [
	ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.PLATED_STIR_FRY_BEEF,
	ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK,
	ItemData.ItemType.SHABU_BEEF, ItemData.ItemType.MUSHY_BOILED_BEEF,
	ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE,
	ItemData.ItemType.UNPLATED_RICE_PORRIDGE, ItemData.ItemType.PLATED_RICE_PORRIDGE,
	ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE,
	ItemData.ItemType.UNPLATED_BOILED_GREENS, ItemData.ItemType.PLATED_BOILED_GREENS,
	ItemData.ItemType.UNPLATED_STIR_FRY_GREENS, ItemData.ItemType.PLATED_STIR_FRY_GREENS,
	ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS, ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS,
	ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS, ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS,
	ItemData.ItemType.UNPLATED_GREENS_PORRIDGE, ItemData.ItemType.PLATED_GREENS_PORRIDGE,
	ItemData.ItemType.UNPLATED_BEEF_PORRIDGE, ItemData.ItemType.PLATED_BEEF_PORRIDGE,
	ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE, ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE,
	ItemData.ItemType.UNPLATED_BEEF_GREENS, ItemData.ItemType.PLATED_BEEF_GREENS,
	ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE, ItemData.ItemType.PLATED_GREENS_FRIED_RICE,
	ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_BEEF_FRIED_RICE,
	ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_MIXED_FRIED_RICE,
	ItemData.ItemType.UNPLATED_VEGETABLE_RICE, ItemData.ItemType.PLATED_VEGETABLE_RICE,
	ItemData.ItemType.UNPLATED_SOAKED_RICE, ItemData.ItemType.PLATED_SOAKED_RICE,
	ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_SOAKED_RICE,
	ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL,
	ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP, ItemData.ItemType.PLATED_BEEF_GREENS_SOUP,
	ItemData.ItemType.UNPLATED_MUSTARD_GREENS, ItemData.ItemType.PLATED_MUSTARD_GREENS,
	ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE, ItemData.ItemType.PLATED_FRIED_WHITE_RICE,
	ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF, ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF,
	ItemData.ItemType.UNPLATED_GREENS_SOUP, ItemData.ItemType.PLATED_GREENS_SOUP,
	ItemData.ItemType.UNPLATED_BEEF_SOUP, ItemData.ItemType.PLATED_BEEF_SOUP,
	ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL, ItemData.ItemType.PLATED_GREENS_RICE_BOWL,
	ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL, ItemData.ItemType.PLATED_BEEF_RICE_BOWL,
	ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_BEEF_BRAISED_RICE,
	ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE,
	ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE, ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE,
	ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_BEEF_SOAKED_RICE,
	ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE,
	ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF, ItemData.ItemType.PLATED_CRISPY_RICE_BEEF,
	ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE, ItemData.ItemType.PLATED_SPICY_FRIED_RICE,
	ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS, ItemData.ItemType.PLATED_SPICY_BEEF_GREENS,
	ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE,
	ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE,
	ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP, ItemData.ItemType.PLATED_SPICY_BEEF_SOUP,
	ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP, ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP,
	ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE, ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE,
	ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE, ItemData.ItemType.PLATED_GREENS_RICE_CAKE,
	ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE, ItemData.ItemType.PLATED_BEEF_RICE_CAKE,
	ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE, ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE,
]


static func get_lifetime(item_type: int) -> float:
	match item_type:
		ItemData.ItemType.RAW_BEEF_CHUNK:
			return RAW_CHUNK_LIFETIME
		ItemData.ItemType.RAW_STEAK:
			return RAW_STEAK_LIFETIME
		ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.RAW_BEEF_DICE:
			return RAW_SMALL_CUT_LIFETIME
		ItemData.ItemType.MARINATED_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_DICE:
			return MARINATED_BEEF_LIFETIME
		ItemData.ItemType.WHOLE_GREENS:
			return WHOLE_GREENS_LIFETIME
		ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS:
			return GREENS_LEAF_LIFETIME
	if item_type in DISH_TYPES:
		return DISH_LIFETIME
	return 0.0


static func is_perishable_type(item_type: int) -> bool:
	return get_lifetime(item_type) > 0.0


static func is_dish_type(item_type: int) -> bool:
	return item_type in DISH_TYPES


static func should_refresh_cycle(source_type: int, target_type: int) -> bool:
	if target_type in [ItemData.ItemType.MARINATED_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_DICE]:
		return true
	return is_dish_type(target_type) and not is_dish_type(source_type)


static func configure_new_item(data: ItemData) -> void:
	if data == null:
		return
	data.freshness_lifetime = get_lifetime(data.item_type)
	data.spoilage_ratio = 0.0
	data.freshness_clock_stamp = -1.0
	data.freshness_pause_reason = ""


static func get_state_for_ratio(ratio: float) -> int:
	if ratio >= 1.0:
		return ItemData.FreshnessState.ROTTEN
	if ratio >= STILL_FRESH_LIMIT:
		return ItemData.FreshnessState.NEAR_EXPIRY
	if ratio >= FRESH_LIMIT:
		return ItemData.FreshnessState.STILL_FRESH
	return ItemData.FreshnessState.FRESH


static func freshness_supply_multiplier(data: ItemData) -> float:
	if data == null or not data.is_perishable():
		return 1.0
	match data.get_freshness_state():
		ItemData.FreshnessState.NEAR_EXPIRY:
			return 0.5
		ItemData.FreshnessState.ROTTEN:
			return 0.0
	return 1.0


static func get_actual_units(data: ItemData) -> int:
	if data == null:
		return 0
	if data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		return maxi(0, data.waste_units_snapshot)
	if data.item_type == ItemData.ItemType.RAW_BEEF_CHUNK:
		return 15
	if data.item_type == ItemData.ItemType.RAW_STEAK:
		return 5
	if data.item_type in [
		ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES,
		ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE,
	]:
		return maxi(1, maxi(data.beef_portion_count, data.remaining_portions))
	if data.item_type == ItemData.ItemType.WHOLE_GREENS:
		return maxi(1, data.leaf_count)
	if data.item_type == ItemData.ItemType.GREENS_LEAF:
		return maxi(1, maxi(data.leaf_count, data.stack_count))
	if data.is_reusable_resource_container():
		return maxi(0, data.remaining_portions)
	return maxi(1, data.stack_count)


static func get_waste_units(data: ItemData) -> int:
	if data == null:
		return 0
	if data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		return maxi(0, data.waste_units_snapshot)
	if data.item_type in [
		ItemData.ItemType.WOK, ItemData.ItemType.PAN, ItemData.ItemType.SOUP_POT,
		ItemData.ItemType.CLEAN_PLATE, ItemData.ItemType.DIRTY_PLATE,
		ItemData.ItemType.CHARCOAL, ItemData.ItemType.BIG_BONE,
	]:
		return 0
	if is_dish_type(data.item_type):
		var total := 0
		for value in data.ingredient_counts.values():
			total += maxi(0, int(value))
		return maxi(FALLBACK_DISH_WASTE_UNITS, total)
	if data.item_type == ItemData.ItemType.RAW_BEEF_CHUNK:
		return 15
	if data.item_type == ItemData.ItemType.RAW_STEAK:
		return 5
	if data.item_type == ItemData.ItemType.WHOLE_GREENS:
		return 5
	if data.item_type in [
		ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES,
		ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE,
		ItemData.ItemType.GREENS_LEAF,
	]:
		return get_actual_units(data)
	if data.item_type in [
		ItemData.ItemType.RICE_BAG, ItemData.ItemType.SMALL_RICE_BAG,
		ItemData.ItemType.COOKING_OIL, ItemData.ItemType.SALT,
	]:
		return maxi(0, data.remaining_portions)
	if data.is_ingredient or data.is_auxiliary:
		return maxi(1, data.stack_count)
	return 0


static func get_health_multiplier(waste_units: int) -> float:
	return 1.0 + maxf(0.0, float(waste_units)) * WASTE_HEALTH_PER_UNIT


static func get_damage_multiplier(waste_units: int) -> float:
	return 1.0 + maxf(0.0, float(waste_units)) * WASTE_DAMAGE_PER_UNIT
