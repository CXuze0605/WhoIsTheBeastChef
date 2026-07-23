class_name GridInventory
extends RefCounted

signal changed


class Placement extends RefCounted:
	var item: CarryableItem
	var origin := Vector2i.ZERO
	var rotated: bool = false

	func _init(target_item: CarryableItem, target_origin: Vector2i, target_rotated: bool) -> void:
		item = target_item
		origin = target_origin
		rotated = target_rotated


var width: int
var height: int
var placements: Array[Placement] = []
var storage_parent: Node2D


func _init(grid_width: int = 1, grid_height: int = 1, target_storage_parent: Node2D = null) -> void:
	width = maxi(1, grid_width)
	height = maxi(1, grid_height)
	storage_parent = target_storage_parent


func set_storage_parent(target: Node2D) -> void:
	storage_parent = target
	for placement in placements:
		_store_item_node(placement.item)


func resize_grid(new_width: int, new_height: int) -> bool:
	var target_width := maxi(1, new_width)
	var target_height := maxi(1, new_height)
	for placement in placements:
		for cell in get_cells_for_placement(placement):
			if cell.x < 0 or cell.y < 0 or cell.x >= target_width or cell.y >= target_height:
				return false
	width = target_width
	height = target_height
	changed.emit()
	return true


func get_items() -> Array[CarryableItem]:
	var result: Array[CarryableItem] = []
	for placement in placements:
		if placement.item != null and is_instance_valid(placement.item):
			result.append(placement.item)
	return result


func get_placement(item: CarryableItem) -> Placement:
	for placement in placements:
		if placement.item == item:
			return placement
	return null


func get_item_at(cell: Vector2i) -> CarryableItem:
	for placement in placements:
		for occupied in get_cells_for_placement(placement):
			if occupied == cell:
				return placement.item
	return null


func get_cells_for_placement(placement: Placement) -> Array[Vector2i]:
	if placement == null or placement.item == null or placement.item.data == null:
		return []
	var cells: Array[Vector2i] = []
	for shape_cell in ItemStorageCatalog.get_shape_cells(placement.item.data.item_type, placement.rotated):
		cells.append(placement.origin + shape_cell)
	return cells


func can_place_item(item: CarryableItem, origin: Vector2i, rotated: bool = false, ignored_items: Array[CarryableItem] = []) -> bool:
	if item == null or item.data == null:
		return false
	return can_place_shape(ItemStorageCatalog.get_shape_cells(item.data.item_type, rotated), origin, ignored_items)


func can_place_shape(shape_cells: Array[Vector2i], origin: Vector2i, ignored_items: Array[CarryableItem] = []) -> bool:
	if shape_cells.is_empty():
		return false
	var occupied := _build_occupied_cells(ignored_items)
	for shape_cell in shape_cells:
		var cell := origin + shape_cell
		if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
			return false
		if occupied.has(cell):
			return false
	return true


func find_first_position(item: CarryableItem, rotated: bool = false, ignored_items: Array[CarryableItem] = []) -> Vector2i:
	if item == null or item.data == null:
		return Vector2i(-1, -1)
	var bounds := ItemStorageCatalog.get_shape_bounds(ItemStorageCatalog.get_shape_cells(item.data.item_type, rotated))
	for y in maxi(0, height - bounds.y + 1):
		for x in maxi(0, width - bounds.x + 1):
			var origin := Vector2i(x, y)
			if can_place_item(item, origin, rotated, ignored_items):
				return origin
	return Vector2i(-1, -1)


func can_accept_data(data: ItemData) -> bool:
	if data == null:
		return false
	var remaining := data.stack_count
	if data.is_stackable:
		for placement in placements:
			if placement.item.data.can_stack_with(data):
				remaining -= placement.item.data.max_stack_count - placement.item.data.stack_count
				if remaining <= 0:
					return true
	var probe := ItemFactory.create_carryable(ItemCatalog.duplicate_data(data))
	var fits := find_first_position(probe, false) != Vector2i(-1, -1)
	if not fits and _has_distinct_rotated_shape(probe):
		fits = find_first_position(probe, true) != Vector2i(-1, -1)
	probe.free()
	return fits


func add_item_at(item: CarryableItem, origin: Vector2i, rotated: bool = false) -> bool:
	if get_placement(item) != null or not can_place_item(item, origin, rotated):
		return false
	var placement := Placement.new(item, origin, rotated)
	placements.append(placement)
	item.storage_rotated = rotated
	_store_item_node(item)
	changed.emit()
	return true


func add_item_auto(item: CarryableItem, allow_stacking: bool = true) -> bool:
	if item == null or item.data == null:
		return false
	var preferred_rotation := item.storage_rotated
	var origin := find_first_position(item, preferred_rotation)
	var alternate_rotation := not preferred_rotation
	var chosen_rotation := preferred_rotation
	if origin == Vector2i(-1, -1) and _has_distinct_rotated_shape(item):
		origin = find_first_position(item, alternate_rotation)
		chosen_rotation = alternate_rotation
	var stack_capacity := _get_stack_capacity(item.data) if allow_stacking else 0
	var needs_placement := item.data.stack_count > stack_capacity
	if needs_placement and origin == Vector2i(-1, -1):
		return false
	if allow_stacking:
		merge_from_item(item)
		if item.data.stack_count <= 0:
			item.queue_free()
			changed.emit()
			return true
	return add_item_at(item, origin, chosen_rotation)


func merge_from_item(item: CarryableItem) -> int:
	if item == null or item.data == null or not item.data.is_stackable:
		return 0
	var accepted_total := 0
	for placement in placements:
		var existing := placement.item
		if existing == item or not existing.data.can_stack_with(item.data):
			continue
		var accepted := existing.data.add_to_stack(item.data.stack_count)
		if accepted <= 0:
			continue
		item.data.stack_count -= accepted
		accepted_total += accepted
		existing.refresh_visual()
		if item.data.stack_count <= 0:
			break
	if accepted_total > 0:
		changed.emit()
	return accepted_total


func remove_item(item: CarryableItem) -> Placement:
	var placement := get_placement(item)
	if placement == null:
		return null
	placements.erase(placement)
	item.storage_rotated = placement.rotated
	changed.emit()
	return placement


func move_item(item: CarryableItem, new_origin: Vector2i, rotated: bool = false) -> bool:
	var placement := get_placement(item)
	if placement == null or not can_place_item(item, new_origin, rotated, [item]):
		return false
	placement.origin = new_origin
	placement.rotated = rotated
	item.storage_rotated = rotated
	changed.emit()
	return true


func rotate_item(item: CarryableItem) -> bool:
	var placement := get_placement(item)
	if placement == null:
		return false
	return move_item(item, placement.origin, not placement.rotated)


func swap_items(first: CarryableItem, second: CarryableItem) -> bool:
	var first_placement := get_placement(first)
	var second_placement := get_placement(second)
	if first_placement == null or second_placement == null or first == second:
		return false
	var ignored: Array[CarryableItem] = [first, second]
	if not can_place_item(first, second_placement.origin, first_placement.rotated, ignored):
		return false
	if not can_place_item(second, first_placement.origin, second_placement.rotated, ignored):
		return false
	var first_cells := _translated_shape(first, second_placement.origin, first_placement.rotated)
	var second_cells := _translated_shape(second, first_placement.origin, second_placement.rotated)
	for cell in first_cells:
		if cell in second_cells:
			return false
	var original_first_origin := first_placement.origin
	first_placement.origin = second_placement.origin
	second_placement.origin = original_first_origin
	changed.emit()
	return true


func clear_all(queue_items: bool = true) -> void:
	var old_items := get_items()
	placements.clear()
	if queue_items:
		for item in old_items:
			if is_instance_valid(item):
				item.queue_free()
	changed.emit()


func _build_occupied_cells(ignored_items: Array[CarryableItem]) -> Dictionary:
	var occupied := {}
	for placement in placements:
		if placement.item in ignored_items:
			continue
		for cell in get_cells_for_placement(placement):
			occupied[cell] = placement.item
	return occupied


func _translated_shape(item: CarryableItem, origin: Vector2i, rotated: bool) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for shape_cell in ItemStorageCatalog.get_shape_cells(item.data.item_type, rotated):
		cells.append(origin + shape_cell)
	return cells


func _has_distinct_rotated_shape(item: CarryableItem) -> bool:
	var normal := {}
	for cell in ItemStorageCatalog.get_shape_cells(item.data.item_type, false):
		normal[cell] = true
	var rotated := {}
	for cell in ItemStorageCatalog.get_shape_cells(item.data.item_type, true):
		rotated[cell] = true
	return normal != rotated


func _get_stack_capacity(data: ItemData) -> int:
	if data == null or not data.is_stackable:
		return 0
	var capacity := 0
	for placement in placements:
		if placement.item.data.can_stack_with(data):
			capacity += placement.item.data.max_stack_count - placement.item.data.stack_count
	return capacity


func _store_item_node(item: CarryableItem) -> void:
	if storage_parent != null and item != null and is_instance_valid(item):
		item.set_inventory_stored(storage_parent)
