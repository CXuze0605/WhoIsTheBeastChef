class_name ItemStorageCatalog
extends RefCounted

# Prototype 0.6A values. Shapes, stack limits and container sizes are centralized
# here so the backpack, cabinet and future fridge do not infer rules from names.
const BACKPACK_SIZE := Vector2i(6, 6)
const FORMAL_CABINET_SIZE := Vector2i(10, 8)
const LOBBY_TEST_CABINET_SIZE := Vector2i(20, 20)
# Compatibility alias: historical code/tests using CABINET_SIZE refer to the
# formal run container, not the expanded free-lobby test catalog.
const CABINET_SIZE := FORMAL_CABINET_SIZE

const SHAPE_SIZES := {
	ItemData.ItemType.RAW_BEEF_CHUNK: Vector2i(3, 3),
	ItemData.ItemType.RAW_STEAK: Vector2i(1, 3),
	ItemData.ItemType.RAW_BEEF_SLICES: Vector2i(1, 1),
	ItemData.ItemType.MARINATED_BEEF_SLICES: Vector2i(1, 1),
	ItemData.ItemType.MARINADE: Vector2i(1, 1),
	ItemData.ItemType.CHILI_SEGMENTS: Vector2i(1, 1),
	ItemData.ItemType.COOKING_OIL: Vector2i(1, 2),
	ItemData.ItemType.UNPLATED_STIR_FRY_BEEF: Vector2i(2, 2),
	ItemData.ItemType.CHARCOAL: Vector2i(1, 1),
	ItemData.ItemType.WOK: Vector2i(3, 3),
	ItemData.ItemType.CLEAN_PLATE: Vector2i(2, 2),
	ItemData.ItemType.DIRTY_PLATE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_STIR_FRY_BEEF: Vector2i(2, 2),
	ItemData.ItemType.SALT: Vector2i(1, 1),
	ItemData.ItemType.MUSTARD: Vector2i(1, 1),
	ItemData.ItemType.PAN: Vector2i(2, 3),
	ItemData.ItemType.SOUP_POT: Vector2i(3, 3),
	ItemData.ItemType.TOMAHAWK_STEAK: Vector2i(1, 3),
	ItemData.ItemType.PLATED_TOMAHAWK_STEAK: Vector2i(2, 3),
	ItemData.ItemType.BIG_BONE: Vector2i(1, 3),
	ItemData.ItemType.SHABU_BEEF: Vector2i(1, 1),
	ItemData.ItemType.MUSHY_BOILED_BEEF: Vector2i(1, 1),
}

const STACK_LIMITS := {
	ItemData.ItemType.MARINADE: 3,
	ItemData.ItemType.CHILI_SEGMENTS: 3,
	ItemData.ItemType.COOKING_OIL: 2,
	ItemData.ItemType.CHARCOAL: 3,
	ItemData.ItemType.CLEAN_PLATE: 4,
	ItemData.ItemType.DIRTY_PLATE: 4,
	ItemData.ItemType.SALT: 3,
	ItemData.ItemType.MUSTARD: 3,
	ItemData.ItemType.SHABU_BEEF: 5,
}


static func apply_storage_defaults(data: ItemData) -> void:
	var limit := get_stack_limit(data.item_type)
	data.max_stack_count = limit
	data.is_stackable = limit > 1
	data.stack_count = clampi(data.stack_count, 1, limit)


static func get_stack_limit(item_type: int) -> int:
	return int(STACK_LIMITS.get(item_type, 1))


static func get_default_size(item_type: int) -> Vector2i:
	return Vector2i(SHAPE_SIZES.get(item_type, Vector2i.ONE))


static func get_shape_cells(item_type: int, rotated: bool = false) -> Array[Vector2i]:
	var size := get_default_size(item_type)
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			cells.append(Vector2i(x, y))
	return rotate_shape_cells(cells) if rotated else cells


static func rotate_shape_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.is_empty():
		return []
	var bounds := get_shape_bounds(cells)
	var rotated_cells: Array[Vector2i] = []
	for cell in cells:
		rotated_cells.append(Vector2i(bounds.y - 1 - cell.y, cell.x))
	return rotated_cells


static func get_shape_bounds(cells: Array[Vector2i]) -> Vector2i:
	var maximum := Vector2i.ZERO
	for cell in cells:
		maximum.x = maxi(maximum.x, cell.x + 1)
		maximum.y = maxi(maximum.y, cell.y + 1)
	return maximum


static func get_shape_text(data: ItemData, rotated: bool = false) -> String:
	var bounds := get_shape_bounds(get_shape_cells(data.item_type, rotated))
	return "%d×%d%s" % [bounds.x, bounds.y, "（已旋转）" if rotated else ""]
