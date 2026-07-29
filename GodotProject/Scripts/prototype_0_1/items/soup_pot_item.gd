class_name SoupPotItem
extends CookwareItem

enum CookStage {
	EMPTY,
	WATER_HEATING,
	BOILING,
	SLICE_COOKING,
	READY,
	OVERCOOKED,
	MUSHY,
	RICE_COOKING,
	RICE_READY,
	PORRIDGE_COOKING,
	PORRIDGE_READY,
	CRISPY_COOKING,
	CRISPY_READY,
	CRISPY_BURNT,
	GREENS_COOKING,
	ENRICHED_PORRIDGE_COOKING,
	VEGETABLE_RICE_COOKING,
	SOAKED_RICE_COOKING,
	GREENS_SOAKED_RICE_COOKING,
	BEEF_SOUP_BASE_COOKING,
	BEEF_SOUP_WAITING_GREENS,
	BEEF_GREENS_SOUP_COOKING,
	GREENS_SOUP_BLANCHING,
	GREENS_SOUP_FINISHING,
	BEEF_SOUP_FINISHING,
	BEEF_SOUP_READY,
	BEEF_BRAISED_RICE_COOKING,
	GREENS_BEEF_BRAISED_RICE_COOKING,
}

var cook_stage: int = CookStage.EMPTY
var water_units: int = 0
var has_water: bool:
	get:
		return water_units > 0
	set(value):
		water_units = 1 if value else 0
var content_data: ItemData
var dish_recorded_for_content: bool = false
var salted_water: bool = false
var pending_recipe: StringName = &""
var recipe_sources: Array[ItemData] = []


func setup_soup_pot(station_id: StringName = &"") -> void:
	cookware_kind = CookwareKind.SOUP_POT
	origin_station_id = station_id
	setup(ItemCatalog.create(ItemData.ItemType.SOUP_POT))


func fill_water() -> bool:
	if water_units >= 2 or content_data != null:
		return false
	water_units += 1
	cook_stage = CookStage.WATER_HEATING
	data.processing_state = ItemData.ProcessingState.SOUP_POT_WATER
	refresh_visual()
	return true


func drain_water() -> bool:
	if content_data != null or water_units <= 0:
		return false
	water_units = 0
	salted_water = false
	cook_stage = CookStage.EMPTY
	data.processing_state = ItemData.ProcessingState.SOUP_POT_EMPTY
	refresh_visual()
	return true


func can_add_salt() -> bool:
	return (
		not salted_water
		and (
			(water_units > 0 and content_data == null)
			or (
				content_data != null
				and pending_recipe in [
					ExpandedRecipeCatalog.GREENS_SOUP,
					ExpandedRecipeCatalog.BEEF_SOUP,
					ExpandedRecipeCatalog.BEEF_BRAISED_RICE,
					ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE,
				]
				and cook_stage in [
					CookStage.GREENS_SOUP_BLANCHING,
					CookStage.GREENS_SOUP_FINISHING,
					CookStage.BEEF_SOUP_BASE_COOKING,
					CookStage.BEEF_SOUP_FINISHING,
					CookStage.BEEF_BRAISED_RICE_COOKING,
					CookStage.GREENS_BEEF_BRAISED_RICE_COOKING,
				]
			)
		)
	)


func add_salt(salt_data: ItemData) -> bool:
	if not can_add_salt():
		return false
	salted_water = true
	var salt_source := ItemCatalog.duplicate_data(salt_data)
	salt_source.remaining_portions = 1
	salt_source.max_remaining_portions = 1
	recipe_sources.append(salt_source)
	if content_data != null:
		content_data.add_active_modifier(ItemData.ActiveModifier.SALTED)
	refresh_visual()
	return true


func can_insert_greens(item_data: ItemData) -> bool:
	if item_data == null or item_data.item_type != ItemData.ItemType.GREENS_LEAF:
		return false
	return (
		(salted_water and water_units == 1 and content_data == null)
		or (water_units == 2 and content_data == null and cook_stage == CookStage.BOILING)
		or (
			content_data != null
			and content_data.item_type == ItemData.ItemType.UNPLATED_RICE_PORRIDGE
			and cook_stage == CookStage.PORRIDGE_READY
		)
	)


func insert_greens(item_data: ItemData) -> bool:
	if not can_insert_greens(item_data):
		return false
	var leaves := clampi(item_data.stack_count, 1, 5)
	var leaf_source := ItemCatalog.duplicate_data(item_data)
	if content_data == null:
		recipe_sources.append(leaf_source)
		content_data = ExpandedRecipeCatalog.create_boiled_greens(leaves, recipe_sources, PrototypeCombatConfig.new())
		var making_soup := water_units == 2
		pending_recipe = ExpandedRecipeCatalog.GREENS_SOUP if making_soup else ExpandedRecipeCatalog.BOILED_GREENS
		water_units = 0
		salted_water = false
		cook_stage = CookStage.GREENS_SOUP_BLANCHING if making_soup else CookStage.GREENS_COOKING
	else:
		var porridge_source := ItemCatalog.duplicate_data(content_data)
		recipe_sources = [porridge_source, leaf_source]
		content_data = ExpandedRecipeCatalog.create_porridge(
			ExpandedRecipeCatalog.GREENS_PORRIDGE,
			leaves,
			recipe_sources,
			PrototypeCombatConfig.new()
		)
		pending_recipe = ExpandedRecipeCatalog.GREENS_PORRIDGE
		cook_stage = CookStage.ENRICHED_PORRIDGE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_insert_porridge_beef(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES]
		and content_data != null
		and (
			(
				content_data.item_type == ItemData.ItemType.UNPLATED_RICE_PORRIDGE
				and cook_stage == CookStage.PORRIDGE_READY
			)
			or (
				content_data.item_type == ItemData.ItemType.UNPLATED_GREENS_PORRIDGE
				and pending_recipe == ExpandedRecipeCatalog.GREENS_PORRIDGE
				and cook_stage == CookStage.ENRICHED_PORRIDGE_COOKING
			)
		)
	)


func insert_porridge_beef(item_data: ItemData) -> bool:
	if not can_insert_porridge_beef(item_data):
		return false
	var beef_source := ItemCatalog.duplicate_data(item_data)
	var upgrading_greens := pending_recipe == ExpandedRecipeCatalog.GREENS_PORRIDGE
	if upgrading_greens:
		recipe_sources.append(beef_source)
		pending_recipe = ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE
	else:
		var porridge_source := ItemCatalog.duplicate_data(content_data)
		recipe_sources = [porridge_source, beef_source]
		pending_recipe = (
			ExpandedRecipeCatalog.BEEF_PORRIDGE
			if item_data.item_type == ItemData.ItemType.MARINATED_BEEF_SLICES
			else ExpandedRecipeCatalog.PLAIN_BEEF_PORRIDGE
		)
	content_data = ExpandedRecipeCatalog.create_porridge(
		pending_recipe,
		content_data.leaf_count if upgrading_greens else 0,
		recipe_sources,
		PrototypeCombatConfig.new()
	)
	cook_stage = CookStage.ENRICHED_PORRIDGE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_porridge_greens(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]
		and content_data != null
		and content_data.item_type in [
			ItemData.ItemType.UNPLATED_BEEF_PORRIDGE,
			ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE,
		]
		and pending_recipe in [ExpandedRecipeCatalog.BEEF_PORRIDGE, ExpandedRecipeCatalog.PLAIN_BEEF_PORRIDGE]
		and cook_stage == CookStage.ENRICHED_PORRIDGE_COOKING
	)


func add_porridge_greens(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_add_porridge_greens(item_data):
		return false
	var leaf_source := ItemCatalog.duplicate_data(item_data)
	recipe_sources.append(leaf_source)
	var leaves := clampi(maxi(item_data.stack_count, item_data.leaf_count), 1, 5)
	pending_recipe = ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE
	content_data = ExpandedRecipeCatalog.create_porridge(
		pending_recipe,
		leaves,
		recipe_sources,
		config
	)
	cook_stage = CookStage.ENRICHED_PORRIDGE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func complete_expanded_recipe(config: PrototypeCombatConfig) -> void:
	if content_data == null or pending_recipe == &"":
		return
	if pending_recipe == ExpandedRecipeCatalog.BOILED_GREENS:
		content_data = ExpandedRecipeCatalog.create_boiled_greens(content_data.leaf_count, recipe_sources, config)
	else:
		content_data = ExpandedRecipeCatalog.create_porridge(
			pending_recipe,
			content_data.leaf_count,
			recipe_sources,
			config
		)
	cook_stage = CookStage.PORRIDGE_READY if pending_recipe != ExpandedRecipeCatalog.BOILED_GREENS else CookStage.READY
	pending_recipe = &""
	recipe_sources.clear()
	_record_completed_dish()
	refresh_visual()


func can_add_vegetable_rice_greens(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]
		and item_data.stack_count >= 5
		and content_data != null
		and content_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE
		and cook_stage == CookStage.RICE_COOKING
	)


func add_vegetable_rice_greens(item_data: ItemData, recommended_order: bool, config: PrototypeCombatConfig) -> bool:
	if not can_add_vegetable_rice_greens(item_data):
		return false
	recipe_sources = [ItemCatalog.duplicate_data(content_data), ItemCatalog.duplicate_data(item_data)]
	content_data = ExpandedRecipeCatalog.create_rice_function_dish(
		ExpandedRecipeCatalog.VEGETABLE_RICE,
		5,
		recipe_sources,
		config,
		recommended_order
	)
	pending_recipe = ExpandedRecipeCatalog.VEGETABLE_RICE
	cook_stage = CookStage.VEGETABLE_RICE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_braised_rice_beef(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE]
		and maxi(item_data.beef_portion_count, item_data.remaining_portions) >= 5
		and content_data != null
		and cook_stage in [CookStage.RICE_COOKING, CookStage.VEGETABLE_RICE_COOKING]
	)


func add_braised_rice_beef(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_add_braised_rice_beef(item_data):
		return false
	if recipe_sources.is_empty():
		recipe_sources.append(ItemCatalog.duplicate_data(content_data))
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	var has_greens := false
	for source in recipe_sources:
		if source != null and source.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]:
			has_greens = true
			break
	pending_recipe = (
		ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE
		if has_greens
		else ExpandedRecipeCatalog.BEEF_BRAISED_RICE
	)
	content_data = ExpandedRecipeCatalog.create_group_3_braised_rice(pending_recipe, recipe_sources, config)
	cook_stage = (
		CookStage.GREENS_BEEF_BRAISED_RICE_COOKING
		if has_greens
		else CookStage.BEEF_BRAISED_RICE_COOKING
	)
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_braised_rice_greens(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]
		and maxi(item_data.stack_count, item_data.leaf_count) >= 5
		and content_data != null
		and pending_recipe == ExpandedRecipeCatalog.BEEF_BRAISED_RICE
		and cook_stage == CookStage.BEEF_BRAISED_RICE_COOKING
	)


func add_braised_rice_greens(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_add_braised_rice_greens(item_data):
		return false
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	pending_recipe = ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE
	content_data = ExpandedRecipeCatalog.create_group_3_braised_rice(pending_recipe, recipe_sources, config)
	cook_stage = CookStage.GREENS_BEEF_BRAISED_RICE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func complete_braised_rice(config: PrototypeCombatConfig) -> void:
	if pending_recipe not in [
		ExpandedRecipeCatalog.BEEF_BRAISED_RICE,
		ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE,
	]:
		return
	content_data = ExpandedRecipeCatalog.create_group_3_braised_rice(pending_recipe, recipe_sources, config)
	pending_recipe = &""
	recipe_sources.clear()
	cook_stage = CookStage.READY
	_record_completed_dish()
	refresh_visual()


func can_insert_cooked_rice(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE
		and not item_data.has_been_used
		and item_data.current_durability == item_data.max_durability
		and water_units == 1
		and content_data == null
	)


func insert_cooked_rice(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_insert_cooked_rice(item_data):
		return false
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	content_data = ExpandedRecipeCatalog.create_rice_function_dish(
		ExpandedRecipeCatalog.SOAKED_RICE,
		0,
		recipe_sources,
		config
	)
	pending_recipe = ExpandedRecipeCatalog.SOAKED_RICE
	water_units = 0
	cook_stage = CookStage.SOAKED_RICE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_soaked_greens(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]
		and item_data.stack_count >= 1
		and content_data != null
		and content_data.item_type in [
			ItemData.ItemType.UNPLATED_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE,
		]
		and cook_stage in [CookStage.SOAKED_RICE_COOKING, CookStage.READY, CookStage.GREENS_SOAKED_RICE_COOKING]
	)


func add_soaked_greens(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_add_soaked_greens(item_data):
		return false
	if recipe_sources.is_empty():
		recipe_sources.append(ItemCatalog.duplicate_data(content_data))
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	var total_leaves := mini(5, content_data.leaf_count + item_data.stack_count)
	var has_beef := content_data.beef_portion_count > 0 or pending_recipe in [
		ExpandedRecipeCatalog.BEEF_SOAKED_RICE,
		ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
	]
	var recipe := (
		ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE
		if has_beef
		else ExpandedRecipeCatalog.GREENS_SOAKED_RICE
	)
	content_data = ExpandedRecipeCatalog.create_rice_function_dish(
		recipe,
		total_leaves,
		recipe_sources,
		config
	)
	pending_recipe = recipe
	cook_stage = CookStage.GREENS_SOAKED_RICE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_soaked_beef(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type == ItemData.ItemType.MARINATED_BEEF_SLICES
		and maxi(item_data.remaining_portions, item_data.beef_portion_count) >= 1
		and content_data != null
		and content_data.item_type in [
			ItemData.ItemType.UNPLATED_SOAKED_RICE,
			ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE,
		]
		and cook_stage in [CookStage.SOAKED_RICE_COOKING, CookStage.GREENS_SOAKED_RICE_COOKING]
	)


func add_soaked_beef(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_add_soaked_beef(item_data):
		return false
	if recipe_sources.is_empty():
		recipe_sources.append(ItemCatalog.duplicate_data(content_data))
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	var recipe := (
		ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE
		if content_data.leaf_count > 0
		else ExpandedRecipeCatalog.BEEF_SOAKED_RICE
	)
	content_data = ExpandedRecipeCatalog.create_rice_function_dish(
		recipe,
		content_data.leaf_count,
		recipe_sources,
		config
	)
	pending_recipe = recipe
	cook_stage = CookStage.GREENS_SOAKED_RICE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func complete_function_rice(config: PrototypeCombatConfig) -> void:
	if pending_recipe not in [
		ExpandedRecipeCatalog.VEGETABLE_RICE,
		ExpandedRecipeCatalog.SOAKED_RICE,
		ExpandedRecipeCatalog.GREENS_SOAKED_RICE,
		ExpandedRecipeCatalog.BEEF_SOAKED_RICE,
		ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
	]:
		return
	content_data = ExpandedRecipeCatalog.create_rice_function_dish(
		pending_recipe,
		content_data.leaf_count,
		recipe_sources,
		config,
		content_data.quality_cap == ItemData.Quality.PERFECT
	)
	cook_stage = CookStage.READY
	pending_recipe = &""
	recipe_sources.clear()
	_record_completed_dish()
	refresh_visual()


func can_insert_beef_soup_base(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type in [
			ItemData.ItemType.RAW_BEEF_SLICES,
			ItemData.ItemType.MARINATED_BEEF_SLICES,
			ItemData.ItemType.RAW_BEEF_DICE,
			ItemData.ItemType.MARINATED_BEEF_DICE,
		]
		and maxi(item_data.beef_portion_count, item_data.remaining_portions) >= 5
		and water_units == 2
		and content_data == null
	)


func insert_beef_soup_base(item_data: ItemData) -> bool:
	if not can_insert_beef_soup_base(item_data):
		return false
	recipe_sources = [ItemCatalog.duplicate_data(item_data)]
	content_data = ItemCatalog.duplicate_data(item_data)
	pending_recipe = (
		ExpandedRecipeCatalog.BEEF_SOUP
		if item_data.item_type in [ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE]
		else ExpandedRecipeCatalog.BEEF_GREENS_SOUP
	)
	water_units = 0
	cook_stage = CookStage.BEEF_SOUP_BASE_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func complete_beef_soup_base() -> void:
	if cook_stage != CookStage.BEEF_SOUP_BASE_COOKING:
		return
	cook_stage = CookStage.BEEF_SOUP_FINISHING if pending_recipe in [
		ExpandedRecipeCatalog.BEEF_SOUP,
		ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
	] else CookStage.BEEF_SOUP_WAITING_GREENS
	refresh_visual()


func can_add_beef_soup_greens(item_data: ItemData) -> bool:
	return (
		item_data != null
		and item_data.item_type == ItemData.ItemType.GREENS_LEAF
		and content_data != null
		and pending_recipe in [
			ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
			ExpandedRecipeCatalog.BEEF_SOUP,
			ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
			ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
		]
		and cook_stage in [
			CookStage.BEEF_SOUP_BASE_COOKING,
			CookStage.BEEF_SOUP_WAITING_GREENS,
			CookStage.BEEF_SOUP_FINISHING,
		]
	)


func add_beef_soup_greens(item_data: ItemData, config: PrototypeCombatConfig) -> bool:
	if not can_add_beef_soup_greens(item_data):
		return false
	var recommended := cook_stage in [
		CookStage.BEEF_SOUP_WAITING_GREENS,
		CookStage.BEEF_SOUP_FINISHING,
	]
	pending_recipe = (
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP
		if pending_recipe in [ExpandedRecipeCatalog.SPICY_BEEF_SOUP, ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP]
		else ExpandedRecipeCatalog.BEEF_GREENS_SOUP
	)
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	if pending_recipe == ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP:
		content_data = ExpandedRecipeCatalog.create_groups_6_7_dish(
			pending_recipe, recipe_sources, config, item_data.stack_count
		)
	else:
		content_data = ExpandedRecipeCatalog.create_advanced_dish(
			ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
			item_data.stack_count,
			recipe_sources,
			config,
			recommended
		)
	cook_stage = CookStage.BEEF_GREENS_SOUP_COOKING
	dish_recorded_for_content = false
	refresh_visual()
	return true


func complete_greens_soup_blanching(config: PrototypeCombatConfig) -> void:
	if cook_stage != CookStage.GREENS_SOUP_BLANCHING:
		return
	# At this discrete node the current content can be taken as boiled/salt-water
	# greens. Leaving it on heat advances to the distinct soup recipe.
	content_data = ExpandedRecipeCatalog.create_boiled_greens(content_data.leaf_count, recipe_sources, config)
	cook_stage = CookStage.GREENS_SOUP_FINISHING
	refresh_visual()


func complete_greens_soup(config: PrototypeCombatConfig) -> void:
	if cook_stage != CookStage.GREENS_SOUP_FINISHING:
		return
	content_data = ExpandedRecipeCatalog.create_missing_group_1_dish(
		ExpandedRecipeCatalog.GREENS_SOUP,
		recipe_sources,
		config,
		content_data.leaf_count
	)
	pending_recipe = &""
	recipe_sources.clear()
	cook_stage = CookStage.READY
	_record_completed_dish()
	refresh_visual()


func complete_beef_soup(config: PrototypeCombatConfig) -> void:
	if cook_stage != CookStage.BEEF_SOUP_FINISHING:
		return
	content_data = (
		ExpandedRecipeCatalog.create_groups_6_7_dish(pending_recipe, recipe_sources, config)
		if pending_recipe == ExpandedRecipeCatalog.SPICY_BEEF_SOUP
		else ExpandedRecipeCatalog.create_missing_group_1_dish(ExpandedRecipeCatalog.BEEF_SOUP, recipe_sources, config)
	)
	pending_recipe = &""
	recipe_sources.clear()
	cook_stage = CookStage.BEEF_SOUP_READY
	_record_completed_dish()
	refresh_visual()


func complete_beef_greens_soup(config: PrototypeCombatConfig) -> void:
	if cook_stage != CookStage.BEEF_GREENS_SOUP_COOKING:
		return
	content_data = (
		ExpandedRecipeCatalog.create_groups_6_7_dish(pending_recipe, recipe_sources, config, content_data.leaf_count)
		if pending_recipe == ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP
		else ExpandedRecipeCatalog.create_advanced_dish(
			ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
			content_data.leaf_count,
			recipe_sources,
			config,
			content_data.quality_cap == ItemData.Quality.PERFECT
		)
	)
	pending_recipe = &""
	recipe_sources.clear()
	cook_stage = CookStage.READY
	_record_completed_dish()
	refresh_visual()


func can_add_chili() -> bool:
	return (
		content_data != null
		and pending_recipe in [
			ExpandedRecipeCatalog.BEEF_SOUP,
			ExpandedRecipeCatalog.BEEF_GREENS_SOUP,
		]
		and cook_stage in [
			CookStage.BEEF_SOUP_BASE_COOKING,
			CookStage.BEEF_SOUP_WAITING_GREENS,
			CookStage.BEEF_SOUP_FINISHING,
			CookStage.BEEF_GREENS_SOUP_COOKING,
		]
		and not content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS)
	)


func add_chili(item_data: ItemData) -> bool:
	if not can_add_chili():
		return false
	content_data.add_component(ItemData.ComponentType.CHILI_SEGMENTS)
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	pending_recipe = (
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP
		if pending_recipe == ExpandedRecipeCatalog.BEEF_GREENS_SOUP
		else ExpandedRecipeCatalog.SPICY_BEEF_SOUP
	)
	refresh_visual()
	return true


func mark_boiling() -> void:
	if not has_water or content_data != null:
		return
	cook_stage = CookStage.BOILING
	data.processing_state = ItemData.ProcessingState.SOUP_POT_BOILING
	refresh_visual()


func can_insert_slice() -> bool:
	return water_units > 0 and content_data == null and cook_stage in [CookStage.WATER_HEATING, CookStage.BOILING]


func insert_slice(slice_data: ItemData) -> bool:
	if not can_insert_slice():
		return false
	content_data = ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	content_data.inherit_recipe_state([slice_data])
	content_data.reset_freshness_cycle()
	dish_recorded_for_content = false
	if cook_stage != CookStage.BOILING:
		content_data.add_failure_tag(ItemData.FailureTag.COLD_WATER_ENTRY)
	cook_stage = CookStage.SLICE_COOKING
	data.processing_state = ItemData.ProcessingState.SOUP_COOKING
	refresh_visual()
	return true


func can_insert_rice() -> bool:
	return water_units in [1, 2] and content_data == null and cook_stage in [CookStage.WATER_HEATING, CookStage.BOILING]


func insert_rice(rice_data: ItemData) -> bool:
	if not can_insert_rice():
		return false
	var used_water := water_units
	water_units = 0
	recipe_sources.append(ItemCatalog.duplicate_data(rice_data))
	if used_water == 1:
		content_data = ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
		cook_stage = CookStage.RICE_COOKING
	else:
		content_data = ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE)
		cook_stage = CookStage.PORRIDGE_COOKING
	dish_recorded_for_content = false
	data.processing_state = ItemData.ProcessingState.RICE_COOKING
	refresh_visual()
	return true


func complete_rice(combat_config: PrototypeCombatConfig) -> void:
	if content_data == null:
		return
	if cook_stage == CookStage.RICE_COOKING:
		cook_stage = CookStage.RICE_READY
		content_data.processing_state = ItemData.ProcessingState.WHITE_RICE_READY
		combat_config.apply_white_rice_stats(content_data)
	elif cook_stage == CookStage.PORRIDGE_COOKING:
		cook_stage = CookStage.PORRIDGE_READY
		content_data.processing_state = ItemData.ProcessingState.PORRIDGE_READY
		content_data.hot_time_left = combat_config.rice_porridge_hot_time
		combat_config.apply_rice_porridge_stats(content_data)
	_record_completed_dish()
	refresh_visual()


func begin_crispy_rice() -> void:
	if cook_stage != CookStage.RICE_READY or content_data == null:
		return
	cook_stage = CookStage.CRISPY_COOKING
	refresh_visual()


func complete_crispy_rice(combat_config: PrototypeCombatConfig) -> void:
	if content_data == null:
		return
	content_data = ItemCatalog.transform(content_data, ItemData.ItemType.UNPLATED_CRISPY_RICE)
	combat_config.apply_crispy_rice_stats(content_data)
	cook_stage = CookStage.CRISPY_READY
	refresh_visual()


func burn_crispy_rice(combat_config: PrototypeCombatConfig) -> void:
	if content_data == null:
		return
	content_data.add_failure_tag(ItemData.FailureTag.BURNT)
	combat_config.apply_crispy_rice_stats(content_data)
	cook_stage = CookStage.CRISPY_BURNT
	refresh_visual()


func complete_slice() -> void:
	cook_stage = CookStage.READY
	data.processing_state = ItemData.ProcessingState.SOUP_READY
	_record_completed_dish()
	refresh_visual()


func _record_completed_dish() -> void:
	if dish_recorded_for_content or not is_inside_tree():
		return
	dish_recorded_for_content = true
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_dish_created(content_data)


func mark_overcooked() -> void:
	if content_data == null:
		return
	content_data.add_failure_tag(ItemData.FailureTag.OVERBOILED)
	cook_stage = CookStage.OVERCOOKED
	refresh_visual()


func turn_to_mushy() -> void:
	content_data = ItemCatalog.transform(content_data, ItemData.ItemType.MUSHY_BOILED_BEEF)
	cook_stage = CookStage.MUSHY
	refresh_visual()


func take_content() -> ItemData:
	var result := content_data
	content_data = null
	dish_recorded_for_content = false
	pending_recipe = &""
	recipe_sources.clear()
	cook_stage = CookStage.BOILING if water_units > 0 else CookStage.EMPTY
	data.processing_state = ItemData.ProcessingState.SOUP_POT_BOILING if water_units > 0 else ItemData.ProcessingState.SOUP_POT_EMPTY
	refresh_visual()
	return result


func refresh_visual() -> void:
	if data == null or placeholder == null:
		return
	PrototypeArtCatalog.apply_to(placeholder, &"soup_pot")
	var title := "汤锅"
	if water_units > 0:
		title += "（水 %d/2%s）" % [water_units, " · 沸腾" if cook_stage == CookStage.BOILING else ""]
	if content_data != null:
		title += "\n锅内：%s" % content_data.display_name
	if salted_water:
		title += "\n已加盐"
	placeholder.set_title(title)
	placeholder.set_color(Color("457b9d"))
	placeholder.set_status(content_data.get_failure_tags_text() if content_data != null and not content_data.failure_tags.is_empty() else "")


func get_debug_description() -> String:
	return "汤锅\n水：%d/2\n锅内：%s\n阶段：%d" % [water_units, content_data.display_name if content_data != null else "无", cook_stage]
