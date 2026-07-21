class_name QuickInventory
extends RefCounted

signal changed
signal selection_changed(index: int)

const SLOT_COUNT := 5

var slots: Array[CarryableItem] = []
var selected_index: int = 0


func _init() -> void:
	slots.resize(SLOT_COUNT)


func get_selected_item() -> CarryableItem:
	return slots[selected_index]


func get_item(slot_index: int) -> CarryableItem:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return null
	return slots[slot_index]


func is_full() -> bool:
	return find_destination_slot() == -1


func can_accept_data(item_data: ItemData) -> bool:
	if item_data == null:
		return false
	if not item_data.is_stackable:
		return find_destination_slot() != -1
	if item_data.stack_count <= 0 or item_data.stack_count > item_data.max_stack_count:
		return false
	var remaining := item_data.stack_count
	for slot_index in _ordered_slot_indices():
		var existing := slots[slot_index]
		if existing != null and existing.data.can_stack_with(item_data):
			remaining -= existing.data.max_stack_count - existing.data.stack_count
	for slot_index in _ordered_slot_indices():
		if slots[slot_index] == null:
			remaining -= item_data.max_stack_count
	return remaining <= 0


func find_destination_slot() -> int:
	if slots[selected_index] == null:
		return selected_index
	for slot_index in SLOT_COUNT:
		if slots[slot_index] == null:
			return slot_index
	return -1


func find_destination_slot_for(item_data: ItemData) -> int:
	var selected_item := slots[selected_index]
	if selected_item != null and selected_item.data.can_stack_with(item_data):
		return selected_index
	for slot_index in SLOT_COUNT:
		var existing := slots[slot_index]
		if existing != null and existing.data.can_stack_with(item_data):
			return slot_index
	if selected_item == null:
		return selected_index
	for slot_index in SLOT_COUNT:
		if slots[slot_index] == null:
			return slot_index
	return -1


func add_item(item: CarryableItem) -> int:
	if item == null or item.data == null or not can_accept_data(item.data):
		return -1
	var first_destination := -1
	if item.data.is_stackable:
		for slot_index in _ordered_slot_indices():
			var existing := slots[slot_index]
			if existing == null or not existing.data.can_stack_with(item.data):
				continue
			var accepted := existing.data.add_to_stack(item.data.stack_count)
			if accepted <= 0:
				continue
			item.data.stack_count -= accepted
			existing.refresh_visual()
			if first_destination == -1:
				first_destination = slot_index
			if item.data.stack_count <= 0:
				item.queue_free()
				changed.emit()
				return first_destination
	var destination := find_destination_slot()
	if destination == -1:
		return -1
	slots[destination] = item
	if first_destination == -1:
		first_destination = destination
	changed.emit()
	return first_destination


func find_item_slot(item_type: int) -> int:
	if slots[selected_index] != null and slots[selected_index].data.item_type == item_type:
		return selected_index
	for slot_index in SLOT_COUNT:
		if slots[slot_index] != null and slots[slot_index].data.item_type == item_type:
			return slot_index
	return -1


func consume_one_of_type(item_type: int) -> bool:
	var slot_index := find_item_slot(item_type)
	if slot_index == -1:
		return false
	var item := slots[slot_index]
	item.data.consume_stack_unit()
	if item.data.stack_count <= 0:
		slots[slot_index] = null
		item.queue_free()
	else:
		item.refresh_visual()
	changed.emit()
	return true


func notify_item_changed() -> void:
	changed.emit()


func take_selected_item() -> CarryableItem:
	return take_item(selected_index)


func take_item(slot_index: int) -> CarryableItem:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return null
	var item := slots[slot_index]
	if item == null:
		return null
	slots[slot_index] = null
	changed.emit()
	return item


func select(slot_index: int) -> bool:
	var wrapped_index := posmod(slot_index, SLOT_COUNT)
	if wrapped_index == selected_index:
		return false
	selected_index = wrapped_index
	selection_changed.emit(selected_index)
	changed.emit()
	return true


func cycle(direction: int) -> bool:
	if direction == 0:
		return false
	return select(selected_index + signi(direction))


func clear_all() -> void:
	for slot_index in SLOT_COUNT:
		var item := slots[slot_index]
		slots[slot_index] = null
		if item != null and is_instance_valid(item):
			item.queue_free()
	selected_index = 0
	selection_changed.emit(selected_index)
	changed.emit()


func _ordered_slot_indices() -> Array[int]:
	var ordered: Array[int] = [selected_index]
	for slot_index in SLOT_COUNT:
		if slot_index != selected_index:
			ordered.append(slot_index)
	return ordered
