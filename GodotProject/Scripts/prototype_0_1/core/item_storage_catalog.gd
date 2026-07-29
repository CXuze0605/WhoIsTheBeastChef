class_name ItemStorageCatalog
extends RefCounted

# Prototype 0.6A values. Shapes, stack limits and container sizes are centralized
# here so the backpack, cabinet and future fridge do not infer rules from names.
const BACKPACK_SIZE := Vector2i(6, 6)
const FORMAL_CABINET_SIZE := Vector2i(10, 8)
const LOBBY_TEST_CABINET_SIZE := Vector2i(20, 80)
# Compatibility alias: historical code/tests using CABINET_SIZE refer to the
# formal run container, not the expanded free-lobby test catalog.
const CABINET_SIZE := FORMAL_CABINET_SIZE

const SHAPE_SIZES := {
	ItemData.ItemType.RAW_BEEF_CHUNK: Vector2i(3, 3),
	ItemData.ItemType.RAW_STEAK: Vector2i(3, 1),
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
	ItemData.ItemType.TOMAHAWK_STEAK: Vector2i(2, 3),
	ItemData.ItemType.PLATED_TOMAHAWK_STEAK: Vector2i(2, 3),
	ItemData.ItemType.BIG_BONE: Vector2i(1, 3),
	ItemData.ItemType.SHABU_BEEF: Vector2i(1, 1),
	ItemData.ItemType.MUSHY_BOILED_BEEF: Vector2i(1, 1),
	ItemData.ItemType.RICE_BAG: Vector2i(3, 4),
	ItemData.ItemType.SMALL_RICE_BAG: Vector2i(2, 2),
	ItemData.ItemType.RAW_RICE: Vector2i(1, 1),
	ItemData.ItemType.UNPLATED_WHITE_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_WHITE_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_RICE_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_RICE_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_CRISPY_RICE: Vector2i(3, 3),
	ItemData.ItemType.PLATED_CRISPY_RICE: Vector2i(3, 3),
	ItemData.ItemType.WHOLE_GREENS: Vector2i(2, 3),
	ItemData.ItemType.GREENS_LEAF: Vector2i(1, 1),
	ItemData.ItemType.RAW_BEEF_DICE: Vector2i(1, 1),
	ItemData.ItemType.MARINATED_BEEF_DICE: Vector2i(1, 1),
	ItemData.ItemType.UNPLATED_BOILED_GREENS: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BOILED_GREENS: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_STIR_FRY_GREENS: Vector2i(2, 2),
	ItemData.ItemType.PLATED_STIR_FRY_GREENS: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS: Vector2i(2, 2),
	ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_GREENS: Vector2i(2, 3),
	ItemData.ItemType.PLATED_BEEF_GREENS: Vector2i(2, 3),
	ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE: Vector2i(3, 2),
	ItemData.ItemType.PLATED_MIXED_FRIED_RICE: Vector2i(3, 2),
	ItemData.ItemType.UNPLATED_VEGETABLE_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_VEGETABLE_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL: Vector2i(3, 3),
	ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP: Vector2i(3, 2),
	ItemData.ItemType.PLATED_BEEF_GREENS_SOUP: Vector2i(3, 2),
	ItemData.ItemType.UNPLATED_MUSTARD_GREENS: Vector2i(2, 2),
	ItemData.ItemType.PLATED_MUSTARD_GREENS: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_FRIED_WHITE_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF: Vector2i(2, 2),
	ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_SOUP: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_SOUP: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_SOUP: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_SOUP: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_RICE_BOWL: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_RICE_BOWL: Vector2i(2, 2),
	ItemData.ItemType.GREENS_CRUMBS: Vector2i(1, 1),
	ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_BRAISED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF: Vector2i(2, 2),
	ItemData.ItemType.PLATED_CRISPY_RICE_BEEF: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_BEEF_GREENS: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_BEEF_SOUP: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP: Vector2i(2, 2),
	ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_BEEF_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE: Vector2i(2, 2),
	ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE: Vector2i(2, 2),
}

const SHAPE_MASKS := {
	ItemData.ItemType.TOMAHAWK_STEAK: [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
		Vector2i(0, 2),
	],
	ItemData.ItemType.PLATED_TOMAHAWK_STEAK: [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
		Vector2i(0, 2),
	],
}

const STACK_LIMITS := {
	ItemData.ItemType.MARINADE: 3,
	ItemData.ItemType.CHILI_SEGMENTS: 3,
	ItemData.ItemType.CHARCOAL: 3,
	ItemData.ItemType.CLEAN_PLATE: 4,
	ItemData.ItemType.DIRTY_PLATE: 4,
	ItemData.ItemType.MUSTARD: 3,
	ItemData.ItemType.SHABU_BEEF: 5,
	ItemData.ItemType.GREENS_LEAF: 5,
	ItemData.ItemType.GREENS_CRUMBS: 5,
}


static func apply_storage_defaults(data: ItemData) -> void:
	if data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		data.max_stack_count = 1
		data.is_stackable = false
		data.stack_count = 1
		return
	var limit := get_stack_limit(data.item_type)
	data.max_stack_count = limit
	data.is_stackable = limit > 1
	data.stack_count = clampi(data.stack_count, 1, limit)


static func get_stack_limit(item_type: int) -> int:
	return int(STACK_LIMITS.get(item_type, 1))


static func get_default_size(item_type: int) -> Vector2i:
	return Vector2i(SHAPE_SIZES.get(item_type, Vector2i.ONE))


static func get_shape_cells(item_type: int, rotated: bool = false) -> Array[Vector2i]:
	if SHAPE_MASKS.has(item_type):
		var masked_cells: Array[Vector2i] = []
		for cell: Vector2i in SHAPE_MASKS[item_type]:
			masked_cells.append(cell)
		return rotate_shape_cells(masked_cells) if rotated else masked_cells
	var size := get_default_size(item_type)
	var cells: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			cells.append(Vector2i(x, y))
	return rotate_shape_cells(cells) if rotated else cells


static func get_shape_cells_for_data(data: ItemData, rotated: bool = false) -> Array[Vector2i]:
	if data == null:
		return []
	if not data.rotten_shape_cells.is_empty():
		var copied: Array[Vector2i] = []
		for cell in data.rotten_shape_cells:
			copied.append(cell)
		return rotate_shape_cells(copied) if rotated else copied
	return get_shape_cells(data.item_type, rotated)


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
	var bounds := get_shape_bounds(get_shape_cells_for_data(data, rotated))
	return "%d×%d%s" % [bounds.x, bounds.y, "（已旋转）" if rotated else ""]
