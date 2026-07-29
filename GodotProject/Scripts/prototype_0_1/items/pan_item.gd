class_name PanItem
extends CookwareItem

enum PanState { CLEAN, OILED, STUCK }
enum CookStage { EMPTY, PRESS_READY, PRESSING, FIRST_SIDE, FLIP_WINDOW, SECOND_SIDE, READY, BURNT_TAGGED, CHARCOAL }

var pan_state: int = PanState.CLEAN
var cook_stage: int = CookStage.EMPTY
var content_data: ItemData
var dish_recorded_for_content: bool = false
var flipped: bool = false
var pending_recipe: StringName = &""
var recipe_sources: Array[ItemData] = []


func setup_pan(station_id: StringName = &"") -> void:
	cookware_kind = CookwareKind.PAN
	origin_station_id = station_id
	setup(ItemCatalog.create(ItemData.ItemType.PAN))


func has_oil() -> bool:
	return pan_state == PanState.OILED


func is_stuck() -> bool:
	return pan_state == PanState.STUCK


func add_oil() -> bool:
	if pan_state != PanState.CLEAN or content_data != null:
		return false
	pan_state = PanState.OILED
	data.processing_state = ItemData.ProcessingState.PAN_OILED
	var oil_source := ItemCatalog.create(ItemData.ItemType.COOKING_OIL)
	oil_source.remaining_portions = 1
	oil_source.max_remaining_portions = 1
	recipe_sources.append(oil_source)
	refresh_visual()
	return true


func insert_steak(item_data: ItemData) -> bool:
	if content_data != null or is_stuck() or item_data.item_type != ItemData.ItemType.RAW_STEAK:
		return false
	content_data = item_data
	dish_recorded_for_content = false
	cook_stage = CookStage.FIRST_SIDE
	content_data.processing_state = ItemData.ProcessingState.PAN_FIRST_SIDE
	refresh_visual()
	return true


func can_insert_rice_cake_base(item_data: ItemData) -> bool:
	if not has_oil() or is_stuck() or item_data == null:
		return false
	if item_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE:
		return (
			not item_data.has_been_used
			and item_data.current_durability == item_data.max_durability
			and (content_data == null or pending_recipe in [ExpandedRecipeCatalog.BEEF_RICE_CAKE, ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE])
			and cook_stage in [CookStage.EMPTY, CookStage.PRESS_READY]
		)
	if item_data.item_type in [ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE]:
		return content_data == null and maxi(item_data.beef_portion_count, item_data.remaining_portions) >= 5
	return false


func insert_rice_cake_base(item_data: ItemData) -> bool:
	if not can_insert_rice_cake_base(item_data):
		return false
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	if item_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE:
		if content_data == null:
			content_data = ItemCatalog.duplicate_data(item_data)
			pending_recipe = ExpandedRecipeCatalog.PAN_FRIED_RICE_CAKE
		else:
			pending_recipe = (
				ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE
				if bool(content_data.effect_values.get("has_greens", false))
				else ExpandedRecipeCatalog.BEEF_RICE_CAKE
			)
	else:
		content_data = ItemCatalog.duplicate_data(item_data)
		pending_recipe = ExpandedRecipeCatalog.BEEF_RICE_CAKE
	cook_stage = CookStage.PRESS_READY
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_greens_crumbs(item_data: ItemData) -> bool:
	return (
		content_data != null
		and cook_stage == CookStage.PRESS_READY
		and item_data != null
		and item_data.item_type == ItemData.ItemType.GREENS_CRUMBS
		and item_data.stack_count >= 1
		and not bool(content_data.effect_values.get("has_greens", false))
	)


func add_greens_crumbs(item_data: ItemData) -> bool:
	if not can_add_greens_crumbs(item_data):
		return false
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	content_data.leaf_count = clampi(item_data.stack_count, 1, 5)
	content_data.effect_values["has_greens"] = true
	pending_recipe = (
		ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE
		if pending_recipe == ExpandedRecipeCatalog.BEEF_RICE_CAKE
		else ExpandedRecipeCatalog.GREENS_RICE_CAKE
	)
	refresh_visual()
	return true


func can_press_rice_cake() -> bool:
	if cook_stage != CookStage.PRESS_READY or pending_recipe == &"":
		return false
	if pending_recipe in [ExpandedRecipeCatalog.BEEF_RICE_CAKE, ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE]:
		return recipe_sources.any(func(source: ItemData) -> bool: return source.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE)
	return true


func begin_pressing() -> bool:
	if not can_press_rice_cake():
		return false
	cook_stage = CookStage.PRESSING
	refresh_visual()
	return true


func finish_pressing() -> void:
	if cook_stage != CookStage.PRESSING:
		return
	cook_stage = CookStage.FIRST_SIDE
	content_data.processing_state = ItemData.ProcessingState.PAN_FIRST_SIDE
	refresh_visual()


func is_rice_cake() -> bool:
	return pending_recipe in [
		ExpandedRecipeCatalog.PAN_FRIED_RICE_CAKE,
		ExpandedRecipeCatalog.GREENS_RICE_CAKE,
		ExpandedRecipeCatalog.BEEF_RICE_CAKE,
		ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
	]


func can_add_salt() -> bool:
	return content_data != null and not is_stuck() and cook_stage in [CookStage.PRESS_READY, CookStage.FIRST_SIDE, CookStage.FLIP_WINDOW, CookStage.SECOND_SIDE] and not content_data.has_active_modifier(ItemData.ActiveModifier.SALTED)


func add_salt() -> bool:
	if not can_add_salt():
		return false
	content_data.add_active_modifier(ItemData.ActiveModifier.SALTED)
	var salt_source := ItemCatalog.create(ItemData.ItemType.SALT)
	salt_source.remaining_portions = 1
	salt_source.max_remaining_portions = 1
	recipe_sources.append(salt_source)
	refresh_visual()
	return true


func open_flip_window() -> void:
	cook_stage = CookStage.FLIP_WINDOW
	content_data.processing_state = ItemData.ProcessingState.PAN_FLIP_WINDOW
	refresh_visual()


func flip(late: bool = false) -> void:
	if content_data == null or cook_stage != CookStage.FLIP_WINDOW:
		return
	if late:
		content_data.add_failure_tag(ItemData.FailureTag.FLIPPED_LATE)
	flipped = true
	cook_stage = CookStage.SECOND_SIDE
	content_data.processing_state = ItemData.ProcessingState.PAN_SECOND_SIDE
	refresh_visual()


func flip_early() -> void:
	if content_data == null or cook_stage != CookStage.FIRST_SIDE or not is_rice_cake():
		return
	content_data.add_failure_tag(ItemData.FailureTag.OUTSIDE_RAW)
	flipped = true
	cook_stage = CookStage.SECOND_SIDE
	content_data.processing_state = ItemData.ProcessingState.PAN_SECOND_SIDE
	refresh_visual()


func complete_steak() -> void:
	content_data = ItemCatalog.transform(content_data, ItemData.ItemType.TOMAHAWK_STEAK)
	cook_stage = CookStage.READY
	pan_state = PanState.CLEAN
	data.processing_state = ItemData.ProcessingState.PAN_CLEAN
	_record_completed_dish()
	refresh_visual()


func complete_rice_cake(config: PrototypeCombatConfig) -> void:
	if not is_rice_cake():
		return
	var final_failure_tags := content_data.failure_tags.duplicate()
	content_data = ExpandedRecipeCatalog.create_groups_6_7_dish(
		pending_recipe,
		recipe_sources,
		config,
		content_data.leaf_count
	)
	for tag in final_failure_tags:
		content_data.add_failure_tag(tag)
	content_data.recalculate_quality()
	cook_stage = CookStage.READY
	pan_state = PanState.CLEAN
	data.processing_state = ItemData.ProcessingState.PAN_CLEAN
	pending_recipe = &""
	recipe_sources.clear()
	_record_completed_dish()
	refresh_visual()


func _record_completed_dish() -> void:
	if dish_recorded_for_content or not is_inside_tree():
		return
	dish_recorded_for_content = true
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_dish_created(content_data)


func mark_burnt() -> void:
	if content_data == null:
		return
	content_data.add_failure_tag(ItemData.FailureTag.BURNT)
	content_data.processing_state = ItemData.ProcessingState.OVERCOOKED
	cook_stage = CookStage.BURNT_TAGGED
	refresh_visual()


func turn_content_to_charcoal() -> void:
	content_data = ItemCatalog.create(ItemData.ItemType.CHARCOAL)
	cook_stage = CookStage.CHARCOAL
	pan_state = PanState.CLEAN
	data.processing_state = ItemData.ProcessingState.PAN_CLEAN
	refresh_visual()


func trigger_no_oil_accident() -> ItemData:
	content_data = null
	cook_stage = CookStage.EMPTY
	pan_state = PanState.STUCK
	data.processing_state = ItemData.ProcessingState.PAN_STUCK
	refresh_visual()
	return ItemCatalog.create(ItemData.ItemType.CHARCOAL)


func take_content() -> ItemData:
	var result := content_data
	content_data = null
	cook_stage = CookStage.EMPTY
	flipped = false
	pending_recipe = &""
	recipe_sources.clear()
	refresh_visual()
	return result


func clean_after_washing() -> void:
	pan_state = PanState.CLEAN
	data.processing_state = ItemData.ProcessingState.PAN_CLEAN
	refresh_visual()


func refresh_visual() -> void:
	if data == null or placeholder == null:
		return
	PrototypeArtCatalog.apply_to(placeholder, &"frying_pan")
	var title := "煎锅"
	var color := Color("6d6875")
	if pan_state == PanState.OILED:
		title = "煎锅（已加油）"
		color = Color("9a8e37")
	elif pan_state == PanState.STUCK:
		title = "煎锅【粘锅】"
		color = Color("5a3333")
	if content_data != null:
		title += "\n锅内：%s" % content_data.display_name
	placeholder.set_title(title)
	placeholder.set_color(color)
	placeholder.set_status(content_data.get_failure_tags_text() if content_data != null and not content_data.failure_tags.is_empty() else "")


func get_debug_description() -> String:
	return "%s\n锅内：%s\n阶段：%d" % ["煎锅【粘锅】" if is_stuck() else "煎锅", content_data.display_name if content_data != null else "无", cook_stage]
