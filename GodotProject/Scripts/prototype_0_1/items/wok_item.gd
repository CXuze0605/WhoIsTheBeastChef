class_name WokItem
extends CookwareItem

enum WokState {
	CLEAN,
	OILED,
	STUCK,
}

enum CookStage {
	EMPTY,
	RAW_LOADED,
	STAGE_ONE_DONE,
	STAGE_TWO_DONE,
	BURNT_TAGGED,
	CHARCOAL,
}

var wok_state: int = WokState.CLEAN
var cook_stage: int = CookStage.EMPTY
var content_data: ItemData
var dish_recorded_for_content: bool = false
var pending_recipe: StringName = &""
var chili_preheated: bool = false
var recipe_sources: Array[ItemData] = []
func setup_wok(station_id: StringName) -> void:
	cookware_kind = CookwareKind.WOK
	origin_station_id = station_id
	setup(ItemCatalog.create(ItemData.ItemType.WOK))


func has_oil() -> bool:
	return wok_state == WokState.OILED


func is_stuck() -> bool:
	return wok_state == WokState.STUCK


func add_oil() -> bool:
	if wok_state != WokState.CLEAN or content_data != null:
		return false
	wok_state = WokState.OILED
	data.processing_state = ItemData.ProcessingState.WOK_OILED
	var oil_source := ItemCatalog.create(ItemData.ItemType.COOKING_OIL)
	oil_source.remaining_portions = 1
	oil_source.max_remaining_portions = 1
	recipe_sources.append(oil_source)
	refresh_visual()
	return true


func can_preheat_chili() -> bool:
	return has_oil() and content_data == null and not chili_preheated and not is_stuck()


func preheat_chili(chili_data: ItemData) -> bool:
	if not can_preheat_chili():
		return false
	chili_preheated = true
	recipe_sources.append(ItemCatalog.duplicate_data(chili_data))
	refresh_visual()
	return true


func can_insert_greens(item_data: ItemData) -> bool:
	return (
		has_oil()
		and content_data == null
		and not is_stuck()
		and item_data != null
		and item_data.item_type == ItemData.ItemType.GREENS_LEAF
		and item_data.stack_count >= 1
	)


func insert_greens(item_data: ItemData) -> bool:
	if not can_insert_greens(item_data):
		return false
	content_data = ItemCatalog.duplicate_data(item_data)
	content_data.leaf_count = clampi(item_data.stack_count, 1, 5)
	content_data.stack_count = 1
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	pending_recipe = (
		ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS
		if chili_preheated
		else ExpandedRecipeCatalog.STIR_FRY_GREENS
	)
	cook_stage = CookStage.RAW_LOADED
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_insert_meat(item_data: ItemData) -> bool:
	if content_data != null or is_stuck() or item_data == null:
		return false
	return (
		item_data.item_type in [
			ItemData.ItemType.RAW_BEEF_SLICES,
			ItemData.ItemType.MARINATED_BEEF_SLICES,
		]
		and maxi(item_data.beef_portion_count, item_data.remaining_portions) >= 5
	)


func insert_meat(item_data: ItemData) -> bool:
	if not can_insert_meat(item_data):
		return false
	content_data = item_data
	if chili_preheated:
		content_data.add_component(ItemData.ComponentType.CHILI_SEGMENTS)
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	pending_recipe = ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF
	dish_recorded_for_content = false
	if content_data.item_type == ItemData.ItemType.RAW_BEEF_SLICES:
		content_data.add_failure_tag(ItemData.FailureTag.UNMARINATED)
	if content_data.processing_state == ItemData.ProcessingState.STIR_FRY_STAGE_ONE:
		cook_stage = CookStage.STAGE_ONE_DONE
	else:
		cook_stage = CookStage.RAW_LOADED
	refresh_visual()
	return true


func can_insert_cooked_rice_base(item_data: ItemData) -> bool:
	return (
		has_oil()
		and content_data == null
		and not is_stuck()
		and item_data != null
		and item_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE
		and not item_data.has_been_used
		and item_data.current_durability == item_data.max_durability
	)


func insert_cooked_rice_base(item_data: ItemData) -> bool:
	if not can_insert_cooked_rice_base(item_data):
		return false
	content_data = ItemCatalog.duplicate_data(item_data)
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	pending_recipe = ExpandedRecipeCatalog.SPICY_FRIED_RICE if chili_preheated else ExpandedRecipeCatalog.FRIED_WHITE_RICE
	if chili_preheated:
		content_data.add_component(ItemData.ComponentType.CHILI_SEGMENTS)
	cook_stage = CookStage.RAW_LOADED
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_insert_dice(item_data: ItemData) -> bool:
	if (
		not has_oil()
		or is_stuck()
		or item_data == null
		or item_data.item_type not in [ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE]
		or maxi(item_data.beef_portion_count, item_data.remaining_portions) < 5
	):
		return false
	return content_data == null or (
		pending_recipe in [
			ExpandedRecipeCatalog.FRIED_WHITE_RICE,
			ExpandedRecipeCatalog.GREENS_FRIED_RICE,
			ExpandedRecipeCatalog.SPICY_FRIED_RICE,
		]
		and cook_stage == CookStage.RAW_LOADED
	)


func insert_dice(item_data: ItemData) -> bool:
	if not can_insert_dice(item_data):
		return false
	if content_data != null:
		recipe_sources.append(ItemCatalog.duplicate_data(item_data))
		content_data.beef_portion_count = maxi(item_data.beef_portion_count, item_data.remaining_portions)
		content_data.is_marinated = item_data.item_type == ItemData.ItemType.MARINATED_BEEF_DICE
		if pending_recipe == ExpandedRecipeCatalog.SPICY_FRIED_RICE:
			pending_recipe = (
				ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE
				if bool(content_data.effect_values.get("has_greens", false))
				else ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE
			)
		else:
			pending_recipe = (
				ExpandedRecipeCatalog.MIXED_FRIED_RICE
				if pending_recipe == ExpandedRecipeCatalog.GREENS_FRIED_RICE
				else ExpandedRecipeCatalog.BEEF_FRIED_RICE
			)
		refresh_visual()
		return true
	content_data = ItemCatalog.duplicate_data(item_data)
	if chili_preheated:
		content_data.add_component(ItemData.ComponentType.CHILI_SEGMENTS)
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	pending_recipe = ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE if chili_preheated else ExpandedRecipeCatalog.BEEF_FRIED_RICE
	cook_stage = CookStage.RAW_LOADED
	dish_recorded_for_content = false
	refresh_visual()
	return true


func can_add_combination_greens(item_data: ItemData) -> bool:
	if item_data == null or item_data.item_type != ItemData.ItemType.GREENS_LEAF or item_data.stack_count < 5:
		return false
	if content_data == null or cook_stage != CookStage.STAGE_ONE_DONE:
		return (
			content_data != null
			and pending_recipe in [
				ExpandedRecipeCatalog.FRIED_WHITE_RICE,
				ExpandedRecipeCatalog.BEEF_FRIED_RICE,
				ExpandedRecipeCatalog.SPICY_FRIED_RICE,
				ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE,
			]
			and cook_stage == CookStage.RAW_LOADED
		)
	if pending_recipe in [ExpandedRecipeCatalog.BEEF_FRIED_RICE, ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE]:
		return (
			cook_stage in [CookStage.RAW_LOADED, CookStage.STAGE_ONE_DONE]
			and not bool(content_data.effect_values.get("has_greens", false))
		)
	return (
		pending_recipe in [&"", ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF]
		and content_data.item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES]
	)


func add_combination_greens(item_data: ItemData) -> bool:
	if not can_add_combination_greens(item_data):
		return false
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	content_data.leaf_count = 5
	content_data.effect_values["has_greens"] = true
	if pending_recipe == ExpandedRecipeCatalog.FRIED_WHITE_RICE:
		pending_recipe = ExpandedRecipeCatalog.GREENS_FRIED_RICE
	elif pending_recipe == ExpandedRecipeCatalog.SPICY_FRIED_RICE:
		# Keep the spicy base until beef arrives; this prevents a non-existent
		# "spicy greens fried rice" from swallowing the full mixed recipe.
		content_data.effect_values["has_greens"] = true
	elif pending_recipe == ExpandedRecipeCatalog.BEEF_FRIED_RICE:
		pending_recipe = (
			ExpandedRecipeCatalog.MIXED_FRIED_RICE
			if _has_recipe_source_type(ItemData.ItemType.UNPLATED_WHITE_RICE)
			else ExpandedRecipeCatalog.BEEF_FRIED_RICE
		)
	elif pending_recipe == ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE:
		pending_recipe = ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE
	elif pending_recipe == &"" or pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF:
		pending_recipe = (
			ExpandedRecipeCatalog.SPICY_BEEF_GREENS
			if content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS)
			else ExpandedRecipeCatalog.BEEF_GREENS
		)
		cook_stage = CookStage.RAW_LOADED
	refresh_visual()
	return true


func _has_recipe_source_type(item_type: int) -> bool:
	for source in recipe_sources:
		if source != null and source.item_type == item_type:
			return true
	return false


func can_add_cooked_rice(item_data: ItemData) -> bool:
	if (
		item_data == null
		or item_data.item_type != ItemData.ItemType.UNPLATED_WHITE_RICE
		or item_data.has_been_used
		or item_data.current_durability != item_data.max_durability
	):
		return false
	if content_data == null:
		return false
	if pending_recipe in [ExpandedRecipeCatalog.BEEF_FRIED_RICE, ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE] and cook_stage == CookStage.STAGE_ONE_DONE:
		return true
	return (
		content_data.recipe_id == ExpandedRecipeCatalog.STIR_FRY_GREENS
		and cook_stage == CookStage.STAGE_TWO_DONE
	)


func add_cooked_rice(item_data: ItemData) -> bool:
	if not can_add_cooked_rice(item_data):
		return false
	recipe_sources.append(ItemCatalog.duplicate_data(item_data))
	if content_data.recipe_id == ExpandedRecipeCatalog.STIR_FRY_GREENS:
		recipe_sources.insert(0, ItemCatalog.duplicate_data(content_data))
		pending_recipe = ExpandedRecipeCatalog.GREENS_FRIED_RICE
	else:
		pending_recipe = (
			ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE
			if pending_recipe == ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE and bool(content_data.effect_values.get("has_greens", false))
			else ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE
			if pending_recipe == ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE
			else ExpandedRecipeCatalog.MIXED_FRIED_RICE
			if bool(content_data.effect_values.get("has_greens", false))
			else ExpandedRecipeCatalog.BEEF_FRIED_RICE
		)
	cook_stage = CookStage.RAW_LOADED
	content_data.display_name = "炒饭最终翻炒"
	refresh_visual()
	return true


func can_add_chili() -> bool:
	return (
		content_data != null
		and not is_stuck()
		and cook_stage in [CookStage.RAW_LOADED, CookStage.STAGE_ONE_DONE]
		and not content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS)
	)


func add_chili() -> bool:
	if not can_add_chili():
		return false
	content_data.add_component(ItemData.ComponentType.CHILI_SEGMENTS)
	recipe_sources.append(ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS))
	if pending_recipe == ExpandedRecipeCatalog.STIR_FRY_GREENS:
		pending_recipe = ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS
	elif pending_recipe == ExpandedRecipeCatalog.FRIED_WHITE_RICE:
		pending_recipe = ExpandedRecipeCatalog.SPICY_FRIED_RICE
	elif pending_recipe == ExpandedRecipeCatalog.BEEF_GREENS:
		pending_recipe = ExpandedRecipeCatalog.SPICY_BEEF_GREENS
	elif pending_recipe == ExpandedRecipeCatalog.BEEF_FRIED_RICE:
		pending_recipe = ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE
	elif pending_recipe == ExpandedRecipeCatalog.MIXED_FRIED_RICE:
		pending_recipe = ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE
	elif pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF:
		# The first-stage beef branch remains the existing chili stir-fry route.
		pending_recipe = &""
	if cook_stage == CookStage.RAW_LOADED:
		content_data.add_failure_tag(ItemData.FailureTag.CHILI_TOO_EARLY)
	refresh_visual()
	return true


func can_add_salt() -> bool:
	return (
		content_data != null
		and not is_stuck()
		and cook_stage in [CookStage.RAW_LOADED, CookStage.STAGE_ONE_DONE]
		and not content_data.has_active_modifier(ItemData.ActiveModifier.SALTED)
	)


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


func complete_stage_one() -> void:
	if content_data == null:
		return
	if pending_recipe in [
		ExpandedRecipeCatalog.STIR_FRY_GREENS,
		ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS,
		ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
	]:
		cook_stage = CookStage.STAGE_TWO_DONE
		content_data.processing_state = ItemData.ProcessingState.READY_TO_PLATE
		return
	cook_stage = CookStage.STAGE_ONE_DONE
	content_data.processing_state = ItemData.ProcessingState.STIR_FRY_STAGE_ONE
	content_data.display_name = "牛肉丁第一阶段" if pending_recipe == ExpandedRecipeCatalog.BEEF_FRIED_RICE else "短炒牛肉片"
	refresh_visual()


func complete_stage_two() -> void:
	if content_data == null:
		return
	content_data = ItemCatalog.transform(content_data, ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	cook_stage = CookStage.STAGE_TWO_DONE
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	_record_completed_dish()
	refresh_visual()


func complete_greens(config: PrototypeCombatConfig) -> void:
	if content_data == null or pending_recipe not in [
		ExpandedRecipeCatalog.STIR_FRY_GREENS,
		ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS,
		ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
	]:
		return
	content_data = ExpandedRecipeCatalog.create_stir_fry_greens(
		content_data.leaf_count,
		pending_recipe,
		recipe_sources,
		config
	)
	cook_stage = CookStage.STAGE_TWO_DONE
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	chili_preheated = false
	recipe_sources.clear()
	_record_completed_dish()
	refresh_visual()


func complete_wok_combination(config: PrototypeCombatConfig) -> void:
	if pending_recipe not in [
		ExpandedRecipeCatalog.BEEF_GREENS,
		ExpandedRecipeCatalog.GREENS_FRIED_RICE,
		ExpandedRecipeCatalog.BEEF_FRIED_RICE,
		ExpandedRecipeCatalog.MIXED_FRIED_RICE,
	]:
		return
	content_data = ExpandedRecipeCatalog.create_wok_combination(pending_recipe, recipe_sources, config)
	cook_stage = CookStage.STAGE_TWO_DONE
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	pending_recipe = &""
	recipe_sources.clear()
	_record_completed_dish()
	refresh_visual()


func complete_groups_6_7_wok(config: PrototypeCombatConfig) -> void:
	if pending_recipe not in [
		ExpandedRecipeCatalog.SPICY_FRIED_RICE,
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS,
		ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE,
		ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
	]:
		return
	content_data = ExpandedRecipeCatalog.create_groups_6_7_dish(
		pending_recipe,
		recipe_sources,
		config,
		content_data.leaf_count if content_data != null else 0
	)
	cook_stage = CookStage.STAGE_TWO_DONE
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	pending_recipe = &""
	recipe_sources.clear()
	_record_completed_dish()
	refresh_visual()


func complete_missing_group_1(config: PrototypeCombatConfig) -> void:
	if pending_recipe not in [
		ExpandedRecipeCatalog.FRIED_WHITE_RICE,
		ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
	]:
		return
	content_data = ExpandedRecipeCatalog.create_missing_group_1_dish(pending_recipe, recipe_sources, config)
	cook_stage = CookStage.STAGE_TWO_DONE
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
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
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	refresh_visual()


func trigger_no_oil_accident() -> ItemData:
	content_data = null
	cook_stage = CookStage.EMPTY
	wok_state = WokState.STUCK
	data.processing_state = ItemData.ProcessingState.WOK_STUCK
	refresh_visual()
	return ItemCatalog.create(ItemData.ItemType.CHARCOAL)


func take_content() -> ItemData:
	var result := content_data
	content_data = null
	cook_stage = CookStage.EMPTY
	pending_recipe = &""
	chili_preheated = false
	recipe_sources.clear()
	refresh_visual()
	return result


func clean_after_washing() -> void:
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	refresh_visual()


func refresh_visual() -> void:
	if data == null or placeholder == null:
		return
	PrototypeArtCatalog.apply_to(placeholder, &"wok")
	var title := "炒锅"
	var color := Color("60636b")
	match wok_state:
		WokState.OILED:
			title = "炒锅（已加油）"
			color = Color("9a8e37")
		WokState.STUCK:
			title = "炒锅【粘锅】"
			color = Color("5a3333")
	if content_data != null:
		title += "\n锅内：%s" % content_data.display_name
	elif chili_preheated:
		title += "\n炝香辣椒：等待青菜叶"
	placeholder.set_title(title)
	placeholder.set_color(color)
	var status_parts: PackedStringArray = []
	if content_data != null and not content_data.failure_tags.is_empty():
		status_parts.append(content_data.get_failure_tags_text())
	if content_data != null and not content_data.active_modifiers.is_empty():
		status_parts.append("调味：%s" % content_data.get_active_modifiers_text())
	placeholder.set_status("\n".join(status_parts))


func get_debug_description() -> String:
	var state_text := "正常"
	if wok_state == WokState.OILED:
		state_text = "已加油"
	elif wok_state == WokState.STUCK:
		state_text = "【粘锅】"
	var content_text := "无"
	if content_data != null:
		content_text = "%s / 失败：%s / 调味：%s / 品质：%s" % [content_data.display_name, content_data.get_failure_tags_text(), content_data.get_active_modifiers_text(), content_data.get_quality_text()]
	return "炒锅状态：%s\n锅内：%s" % [state_text, content_text]
