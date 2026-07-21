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
	refresh_visual()
	return true


func can_insert_meat(item_data: ItemData) -> bool:
	if content_data != null or is_stuck():
		return false
	return item_data.item_type in [
		ItemData.ItemType.RAW_BEEF_SLICES,
		ItemData.ItemType.MARINATED_BEEF_SLICES,
	]


func insert_meat(item_data: ItemData) -> bool:
	if not can_insert_meat(item_data):
		return false
	content_data = item_data
	if content_data.item_type == ItemData.ItemType.RAW_BEEF_SLICES:
		content_data.add_failure_tag(ItemData.FailureTag.UNMARINATED)
	if content_data.processing_state == ItemData.ProcessingState.STIR_FRY_STAGE_ONE:
		cook_stage = CookStage.STAGE_ONE_DONE
	else:
		cook_stage = CookStage.RAW_LOADED
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
	refresh_visual()
	return true


func complete_stage_one() -> void:
	if content_data == null:
		return
	cook_stage = CookStage.STAGE_ONE_DONE
	content_data.processing_state = ItemData.ProcessingState.STIR_FRY_STAGE_ONE
	content_data.display_name = "短炒牛肉片"
	refresh_visual()


func complete_stage_two() -> void:
	if content_data == null:
		return
	content_data = ItemCatalog.transform(content_data, ItemData.ItemType.UNPLATED_STIR_FRY_BEEF)
	cook_stage = CookStage.STAGE_TWO_DONE
	wok_state = WokState.CLEAN
	data.processing_state = ItemData.ProcessingState.WOK_CLEAN
	refresh_visual()


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
