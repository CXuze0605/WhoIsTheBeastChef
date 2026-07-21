class_name SoupPotItem
extends CookwareItem

enum CookStage { EMPTY, WATER_HEATING, BOILING, SLICE_COOKING, READY, OVERCOOKED, MUSHY }

var cook_stage: int = CookStage.EMPTY
var has_water: bool = false
var content_data: ItemData


func setup_soup_pot(station_id: StringName = &"") -> void:
	cookware_kind = CookwareKind.SOUP_POT
	origin_station_id = station_id
	setup(ItemCatalog.create(ItemData.ItemType.SOUP_POT))


func fill_water() -> bool:
	if has_water or content_data != null:
		return false
	has_water = true
	cook_stage = CookStage.WATER_HEATING
	data.processing_state = ItemData.ProcessingState.SOUP_POT_WATER
	refresh_visual()
	return true


func mark_boiling() -> void:
	if not has_water or content_data != null:
		return
	cook_stage = CookStage.BOILING
	data.processing_state = ItemData.ProcessingState.SOUP_POT_BOILING
	refresh_visual()


func can_insert_slice() -> bool:
	return has_water and content_data == null and cook_stage in [CookStage.WATER_HEATING, CookStage.BOILING]


func insert_slice(slice_data: ItemData) -> bool:
	if not can_insert_slice():
		return false
	content_data = ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	if cook_stage != CookStage.BOILING:
		content_data.add_failure_tag(ItemData.FailureTag.COLD_WATER_ENTRY)
	cook_stage = CookStage.SLICE_COOKING
	data.processing_state = ItemData.ProcessingState.SOUP_COOKING
	refresh_visual()
	return true


func complete_slice() -> void:
	cook_stage = CookStage.READY
	data.processing_state = ItemData.ProcessingState.SOUP_READY
	refresh_visual()


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
	cook_stage = CookStage.BOILING if has_water else CookStage.EMPTY
	data.processing_state = ItemData.ProcessingState.SOUP_POT_BOILING if has_water else ItemData.ProcessingState.SOUP_POT_EMPTY
	refresh_visual()
	return result


func refresh_visual() -> void:
	if data == null or placeholder == null:
		return
	PrototypeArtCatalog.apply_to(placeholder, &"soup_pot")
	var title := "汤锅"
	if has_water:
		title += "（沸水）" if cook_stage == CookStage.BOILING else "（有水）"
	if content_data != null:
		title += "\n锅内：%s" % content_data.display_name
	placeholder.set_title(title)
	placeholder.set_color(Color("457b9d"))
	placeholder.set_status(content_data.get_failure_tags_text() if content_data != null and not content_data.failure_tags.is_empty() else "")


func get_debug_description() -> String:
	return "汤锅\n水：%s\n锅内：%s\n阶段：%d" % ["有" if has_water else "无", content_data.display_name if content_data != null else "无", cook_stage]
