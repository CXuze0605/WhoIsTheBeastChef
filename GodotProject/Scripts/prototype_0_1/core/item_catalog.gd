class_name ItemCatalog
extends RefCounted


static func create(item_type: int) -> ItemData:
	var data := ItemData.new()
	data.item_type = item_type
	match item_type:
		ItemData.ItemType.RAW_BEEF_CHUNK:
			_configure(data, "整块生牛肉", ItemData.ProcessingState.RAW, true, false, false, [ItemData.StationType.CUTTING_BOARD])
		ItemData.ItemType.RAW_STEAK:
			_configure(data, "生牛排", ItemData.ProcessingState.CUT_ONCE, true, false, false, [ItemData.StationType.CUTTING_BOARD, ItemData.StationType.STOVE])
		ItemData.ItemType.RAW_BEEF_SLICES:
			_configure(data, "生牛肉片", ItemData.ProcessingState.SLICED, true, false, false, [ItemData.StationType.MARINATING, ItemData.StationType.WOK, ItemData.StationType.STOVE])
			data.remaining_portions = 5
		ItemData.ItemType.MARINATED_BEEF_SLICES:
			_configure(data, "腌牛肉片", ItemData.ProcessingState.MARINATED, true, false, false, [ItemData.StationType.WOK])
		ItemData.ItemType.MARINADE:
			_configure(data, "腌肉料", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.MARINATING])
		ItemData.ItemType.CHILI_SEGMENTS:
			_configure(data, "辣椒段", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.WOK])
		ItemData.ItemType.COOKING_OIL:
			_configure(data, "食用油", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.WOK])
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			_configure(data, "待摆盘小炒黄牛肉", ItemData.ProcessingState.READY_TO_PLATE, true, false, false, [])
			data.can_be_plated = true
			data.max_durability = 1
			data.current_durability = 1
			data.attack_form = ItemData.AttackForm.PROJECTILE
			data.cooking_method = ItemData.CookingMethod.STIR_FRY
		ItemData.ItemType.CHARCOAL:
			_configure(data, "焦炭", ItemData.ProcessingState.CHARCOAL, false, false, false, [])
		ItemData.ItemType.WOK:
			_configure(data, "炒锅", ItemData.ProcessingState.WOK_CLEAN, false, false, true, [ItemData.StationType.WOK, ItemData.StationType.SINK])
		ItemData.ItemType.CLEAN_PLATE:
			_configure(data, "干净盘子", ItemData.ProcessingState.AUXILIARY, false, false, false, [])
			_configure_plate_stack(data, ItemData.PlateState.CLEAN)
		ItemData.ItemType.DIRTY_PLATE:
			_configure(data, "脏盘子", ItemData.ProcessingState.AUXILIARY, false, false, false, [ItemData.StationType.SINK])
			_configure_plate_stack(data, ItemData.PlateState.DIRTY)
		ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			_configure(data, "已摆盘小炒黄牛肉", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.attack_form = ItemData.AttackForm.PROJECTILE
			data.cooking_method = ItemData.CookingMethod.STIR_FRY
		ItemData.ItemType.SALT:
			_configure(data, "盐", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.WOK])
		ItemData.ItemType.MUSTARD:
			_configure(data, "芥末", ItemData.ProcessingState.AUXILIARY, false, true, false, [])
		ItemData.ItemType.PAN:
			_configure(data, "煎锅", ItemData.ProcessingState.PAN_CLEAN, false, false, true, [ItemData.StationType.STOVE, ItemData.StationType.SINK])
		ItemData.ItemType.SOUP_POT:
			_configure(data, "汤锅", ItemData.ProcessingState.SOUP_POT_EMPTY, false, false, true, [ItemData.StationType.STOVE, ItemData.StationType.SINK])
		ItemData.ItemType.TOMAHAWK_STEAK:
			_configure(data, "战斧牛排", ItemData.ProcessingState.READY_TO_PLATE, true, false, false, [])
			data.can_be_plated = true
			data.is_combat_dish = true
			data.attack_form = ItemData.AttackForm.MELEE
			data.cooking_method = ItemData.CookingMethod.PAN_FRY
		ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			_configure(data, "盘装战斧牛排", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.attack_form = ItemData.AttackForm.MELEE
			data.cooking_method = ItemData.CookingMethod.PAN_FRY
		ItemData.ItemType.BIG_BONE:
			_configure(data, "大骨头", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.attack_form = ItemData.AttackForm.PROJECTILE
			data.cooking_method = ItemData.CookingMethod.PAN_FRY
		ItemData.ItemType.SHABU_BEEF:
			_configure(data, "涮牛肉", ItemData.ProcessingState.SOUP_READY, true, false, false, [])
			data.is_stackable = true
			data.stack_count = 1
			data.max_stack_count = 5
			data.attack_form = ItemData.AttackForm.TRAP
			data.cooking_method = ItemData.CookingMethod.BOIL
		ItemData.ItemType.MUSHY_BOILED_BEEF:
			_configure(data, "【煮烂牛肉】", ItemData.ProcessingState.OVERCOOKED, true, false, false, [])
			data.cooking_method = ItemData.CookingMethod.BOIL
	data.recalculate_quality()
	return data


static func transform(existing: ItemData, target_type: int) -> ItemData:
	var result := create(target_type)
	result.failure_tags = existing.failure_tags.duplicate()
	result.components = existing.components.duplicate()
	result.active_modifiers = existing.active_modifiers.duplicate()
	result.has_been_used = existing.has_been_used
	if target_type != ItemData.ItemType.RAW_BEEF_SLICES or existing.item_type == ItemData.ItemType.RAW_BEEF_SLICES:
		result.remaining_portions = existing.remaining_portions
	result.attack_count = existing.attack_count
	result.next_sneeze_attack = existing.next_sneeze_attack
	result.bone_thrown = existing.bone_thrown
	result.recalculate_quality()
	return result


static func get_item_color(item_type: int) -> Color:
	match item_type:
		ItemData.ItemType.RAW_BEEF_CHUNK:
			return Color("9d3f46")
		ItemData.ItemType.RAW_STEAK:
			return Color("bd5961")
		ItemData.ItemType.RAW_BEEF_SLICES:
			return Color("dd7a80")
		ItemData.ItemType.MARINATED_BEEF_SLICES:
			return Color("a95d39")
		ItemData.ItemType.MARINADE:
			return Color("d9b66f")
		ItemData.ItemType.CHILI_SEGMENTS:
			return Color("d62d2d")
		ItemData.ItemType.COOKING_OIL:
			return Color("e9d95b")
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			return Color("b84d28")
		ItemData.ItemType.CHARCOAL:
			return Color("303036")
		ItemData.ItemType.WOK:
			return Color("60636b")
		ItemData.ItemType.CLEAN_PLATE:
			return Color("d8eef2")
		ItemData.ItemType.DIRTY_PLATE:
			return Color("8f765f")
		ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			return Color("d45a2a")
		ItemData.ItemType.SALT:
			return Color("f4f1de")
		ItemData.ItemType.MUSTARD:
			return Color("d8a928")
		ItemData.ItemType.PAN:
			return Color("6d6875")
		ItemData.ItemType.SOUP_POT:
			return Color("457b9d")
		ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			return Color("8f3b2f")
		ItemData.ItemType.BIG_BONE:
			return Color("e9dcc9")
		ItemData.ItemType.SHABU_BEEF:
			return Color("e5989b")
		ItemData.ItemType.MUSHY_BOILED_BEEF:
			return Color("8d99ae")
	return Color.WHITE


static func get_art_key(item_type: int) -> StringName:
	match item_type:
		ItemData.ItemType.RAW_STEAK:
			return &"raw_steak"
		ItemData.ItemType.CHILI_SEGMENTS:
			return &"chili_segment"
		ItemData.ItemType.COOKING_OIL:
			return &"cooking_oil_bottle"
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			return &"plated_stir_fry_beef"
		ItemData.ItemType.WOK:
			return &"wok"
		ItemData.ItemType.CLEAN_PLATE:
			return &"clean_plate_stack"
		ItemData.ItemType.SALT:
			return &"salt_bottle"
		ItemData.ItemType.PAN:
			return &"frying_pan"
		ItemData.ItemType.SOUP_POT:
			return &"soup_pot"
	return &""


static func _configure(
	data: ItemData,
	display_name: String,
	processing_state: int,
	is_ingredient: bool,
	is_auxiliary: bool,
	is_cookware: bool,
	allowed_stations: Array[int]
) -> void:
	data.display_name = display_name
	data.processing_state = processing_state
	data.is_ingredient = is_ingredient
	data.is_auxiliary = is_auxiliary
	data.is_cookware = is_cookware
	data.allowed_stations = allowed_stations


static func _configure_plate_stack(data: ItemData, plate_state: int) -> void:
	data.is_stackable = true
	data.stack_count = 1
	data.max_stack_count = 4
	data.carried_plate_state = plate_state
