class_name PanItem
extends CookwareItem

enum PanState { CLEAN, OILED, STUCK }
enum CookStage { EMPTY, FIRST_SIDE, FLIP_WINDOW, SECOND_SIDE, READY, BURNT_TAGGED, CHARCOAL }

var pan_state: int = PanState.CLEAN
var cook_stage: int = CookStage.EMPTY
var content_data: ItemData
var dish_recorded_for_content: bool = false
var flipped: bool = false


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


func can_add_salt() -> bool:
	return content_data != null and not is_stuck() and cook_stage in [CookStage.FIRST_SIDE, CookStage.FLIP_WINDOW, CookStage.SECOND_SIDE] and not content_data.has_active_modifier(ItemData.ActiveModifier.SALTED)


func add_salt() -> bool:
	if not can_add_salt():
		return false
	content_data.add_active_modifier(ItemData.ActiveModifier.SALTED)
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


func complete_steak() -> void:
	content_data = ItemCatalog.transform(content_data, ItemData.ItemType.TOMAHAWK_STEAK)
	cook_stage = CookStage.READY
	pan_state = PanState.CLEAN
	data.processing_state = ItemData.ProcessingState.PAN_CLEAN
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
