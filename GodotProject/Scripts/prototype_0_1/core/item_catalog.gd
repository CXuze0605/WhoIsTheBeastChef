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
			data.max_remaining_portions = 5
			data.beef_portion_count = 5
		ItemData.ItemType.MARINATED_BEEF_SLICES:
			_configure(data, "腌牛肉片", ItemData.ProcessingState.MARINATED, true, false, false, [ItemData.StationType.CUTTING_BOARD, ItemData.StationType.WOK])
			data.remaining_portions = 5
			data.max_remaining_portions = 5
			data.beef_portion_count = 5
			data.is_marinated = true
		ItemData.ItemType.MARINADE:
			_configure(data, "腌肉料", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.MARINATING])
		ItemData.ItemType.CHILI_SEGMENTS:
			_configure(data, "辣椒段", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.WOK])
		ItemData.ItemType.COOKING_OIL:
			_configure(data, "食用油", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.WOK])
			data.remaining_portions = PrototypeWaveConfig.INITIAL_OIL_BOTTLE_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.INITIAL_OIL_BOTTLE_PORTIONS
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			_configure(data, "待摆盘小炒黄牛肉", ItemData.ProcessingState.READY_TO_PLATE, true, false, false, [])
			data.can_be_plated = true
			data.is_combat_dish = true
			data.attack_form = ItemData.AttackForm.PROJECTILE
			data.cooking_method = ItemData.CookingMethod.STIR_FRY
			data.emergency_edible = true
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
			data.emergency_edible = true
		ItemData.ItemType.SALT:
			_configure(data, "盐", ItemData.ProcessingState.AUXILIARY, false, true, false, [ItemData.StationType.WOK])
			data.remaining_portions = PrototypeWaveConfig.INITIAL_SALT_BOTTLE_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.INITIAL_SALT_BOTTLE_PORTIONS
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
			data.emergency_edible = true
		ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			_configure(data, "盘装战斧牛排", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.attack_form = ItemData.AttackForm.MELEE
			data.cooking_method = ItemData.CookingMethod.PAN_FRY
			data.emergency_edible = true
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
		ItemData.ItemType.RICE_BAG:
			_configure(data, "开局大米袋", ItemData.ProcessingState.RICE_RAW, true, false, false, [])
			data.remaining_portions = PrototypeWaveConfig.STARTING_RICE_BAG_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.STARTING_RICE_BAG_PORTIONS
		ItemData.ItemType.RAW_RICE:
			_configure(data, "生米", ItemData.ProcessingState.RICE_RAW, true, false, false, [ItemData.StationType.STOVE])
		ItemData.ItemType.UNPLATED_WHITE_RICE:
			_configure(data, "待摆盘白米饭", ItemData.ProcessingState.WHITE_RICE_READY, true, false, false, [])
			data.can_be_plated = true
			data.is_combat_dish = true
			data.attack_form = ItemData.AttackForm.PROJECTILE
			data.cooking_method = ItemData.CookingMethod.BOIL
			data.emergency_edible = true
		ItemData.ItemType.PLATED_WHITE_RICE:
			_configure(data, "盘装白米饭", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.attack_form = ItemData.AttackForm.PROJECTILE
			data.cooking_method = ItemData.CookingMethod.BOIL
			data.emergency_edible = true
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE:
			_configure(data, "待摆盘白粥", ItemData.ProcessingState.PORRIDGE_READY, true, false, false, [])
			data.can_be_plated = true
			data.is_combat_dish = true
			data.cooking_method = ItemData.CookingMethod.BOIL
		ItemData.ItemType.PLATED_RICE_PORRIDGE:
			_configure(data, "盘装白粥", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.cooking_method = ItemData.CookingMethod.BOIL
		ItemData.ItemType.UNPLATED_CRISPY_RICE:
			_configure(data, "待摆盘锅巴", ItemData.ProcessingState.CRISPY_RICE_READY, true, false, false, [])
			data.can_be_plated = true
			data.is_combat_dish = true
			data.cooking_method = ItemData.CookingMethod.BOIL
		ItemData.ItemType.PLATED_CRISPY_RICE:
			_configure(data, "盘装锅巴", ItemData.ProcessingState.PLATED, false, false, false, [])
			data.is_combat_dish = true
			data.carried_plate_state = ItemData.PlateState.CLEAN
			data.cooking_method = ItemData.CookingMethod.BOIL
		ItemData.ItemType.WHOLE_GREENS:
			_configure(data, "整颗青菜", ItemData.ProcessingState.GREENS_WHOLE, true, false, false, [])
			data.leaf_count = 5
		ItemData.ItemType.GREENS_LEAF:
			_configure(data, "青菜叶", ItemData.ProcessingState.GREENS_LEAVES, true, false, false, [ItemData.StationType.WOK, ItemData.StationType.STOVE])
			data.leaf_count = 1
		ItemData.ItemType.RAW_BEEF_DICE:
			_configure(data, "生牛肉丁组", ItemData.ProcessingState.DICED, true, false, false, [ItemData.StationType.MARINATING, ItemData.StationType.WOK])
			data.remaining_portions = 5
			data.max_remaining_portions = 5
			data.beef_portion_count = 5
		ItemData.ItemType.MARINATED_BEEF_DICE:
			_configure(data, "腌牛肉丁组", ItemData.ProcessingState.MARINATED, true, false, false, [ItemData.StationType.WOK])
			data.remaining_portions = 5
			data.max_remaining_portions = 5
			data.beef_portion_count = 5
			data.is_marinated = true
		ItemData.ItemType.UNPLATED_BOILED_GREENS:
			_configure_expanded_dish(data, "待摆盘盐水青菜", &"boiled_greens", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
		ItemData.ItemType.PLATED_BOILED_GREENS:
			_configure_expanded_dish(data, "盘装盐水青菜", &"boiled_greens", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
		ItemData.ItemType.UNPLATED_STIR_FRY_GREENS:
			_configure_expanded_dish(data, "待摆盘清炒青菜", &"stir_fry_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_STIR_FRY_GREENS:
			_configure_expanded_dish(data, "盘装清炒青菜", &"stir_fry_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS:
			_configure_expanded_dish(data, "待摆盘辣味清炒青菜", &"spicy_stir_fry_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS:
			_configure_expanded_dish(data, "盘装辣味清炒青菜", &"spicy_stir_fry_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS:
			_configure_expanded_dish(data, "待摆盘炝炒青菜", &"flash_stir_fry_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS:
			_configure_expanded_dish(data, "盘装炝炒青菜", &"flash_stir_fry_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE:
			_configure_expanded_dish(data, "待摆盘青菜粥", &"greens_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
		ItemData.ItemType.PLATED_GREENS_PORRIDGE:
			_configure_expanded_dish(data, "盘装青菜粥", &"greens_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE:
			_configure_expanded_dish(data, "待摆盘生滚牛肉粥", &"beef_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
		ItemData.ItemType.PLATED_BEEF_PORRIDGE:
			_configure_expanded_dish(data, "盘装生滚牛肉粥", &"beef_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE:
			_configure_expanded_dish(data, "待摆盘普通牛肉粥", &"plain_beef_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
			data.quality_cap = ItemData.Quality.NORMAL
		ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE:
			_configure_expanded_dish(data, "盘装普通牛肉粥", &"plain_beef_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
			data.quality_cap = ItemData.Quality.NORMAL
		ItemData.ItemType.UNPLATED_BEEF_GREENS:
			_configure_expanded_dish(data, "待摆盘青菜炒牛肉", &"beef_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.MELEE, false)
		ItemData.ItemType.PLATED_BEEF_GREENS:
			_configure_expanded_dish(data, "盘装青菜炒牛肉", &"beef_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.MELEE, true)
		ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE:
			_configure_expanded_dish(data, "待摆盘青菜炒饭", &"greens_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_GREENS_FRIED_RICE:
			_configure_expanded_dish(data, "盘装青菜炒饭", &"greens_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE:
			_configure_expanded_dish(data, "待摆盘牛肉炒饭", &"beef_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_BEEF_FRIED_RICE:
			_configure_expanded_dish(data, "盘装牛肉炒饭", &"beef_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE:
			_configure_expanded_dish(data, "待摆盘青菜牛肉炒饭", &"mixed_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_MIXED_FRIED_RICE:
			_configure_expanded_dish(data, "盘装青菜牛肉炒饭", &"mixed_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE:
			_configure_expanded_dish(data, "待摆盘菜饭", &"vegetable_rice", ItemData.CookingMethod.BRAISE, ItemData.AttackForm.NONE, false)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.PLATED_VEGETABLE_RICE:
			_configure_expanded_dish(data, "盘装菜饭", &"vegetable_rice", ItemData.CookingMethod.BRAISE, ItemData.AttackForm.NONE, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.UNPLATED_SOAKED_RICE:
			_configure_expanded_dish(data, "待摆盘泡饭", &"soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, false)
		ItemData.ItemType.PLATED_SOAKED_RICE:
			_configure_expanded_dish(data, "盘装泡饭", &"soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, true)
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE:
			_configure_expanded_dish(data, "待摆盘菜泡饭", &"greens_soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, false)
		ItemData.ItemType.PLATED_GREENS_SOAKED_RICE:
			_configure_expanded_dish(data, "盘装菜泡饭", &"greens_soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, true)
		ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL:
			_configure_expanded_dish(data, "青菜牛肉盖饭炮台", &"beef_greens_rice_bowl", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP:
			_configure_expanded_dish(data, "待摆盘青菜牛肉汤", &"beef_greens_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
			data.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
		ItemData.ItemType.PLATED_BEEF_GREENS_SOUP:
			_configure_expanded_dish(data, "盘装青菜牛肉汤", &"beef_greens_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
			data.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
		ItemData.ItemType.UNPLATED_MUSTARD_GREENS:
			_configure_expanded_dish(data, "芥末青菜", &"mustard_greens", ItemData.CookingMethod.MIX, ItemData.AttackForm.PROJECTILE, false)
			data.weird_recipe = true
			data.quality_cap = ItemData.Quality.NORMAL
		ItemData.ItemType.PLATED_MUSTARD_GREENS:
			_configure_expanded_dish(data, "盘装芥末青菜", &"mustard_greens", ItemData.CookingMethod.MIX, ItemData.AttackForm.PROJECTILE, true)
			data.weird_recipe = true
			data.quality_cap = ItemData.Quality.NORMAL
		ItemData.ItemType.SMALL_RICE_BAG:
			_configure(data, "敌人掉落小米袋", ItemData.ProcessingState.RICE_RAW, true, false, false, [])
			data.remaining_portions = PrototypeWaveConfig.DROP_SMALL_RICE_BAG_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.DROP_SMALL_RICE_BAG_PORTIONS
		ItemData.ItemType.ROTTEN_WASTE:
			_configure(data, "腐败物", ItemData.ProcessingState.OVERCOOKED, false, false, false, [])
		ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE:
			_configure_expanded_dish(data, "待摆盘炒白饭", &"fried_white_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_FRIED_WHITE_RICE:
			_configure_expanded_dish(data, "盘装炒白饭", &"fried_white_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF:
			_configure_expanded_dish(data, "待摆盘清炒牛肉", &"clear_stir_fry_beef", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.MELEE, false)
		ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF:
			_configure_expanded_dish(data, "盘装清炒牛肉", &"clear_stir_fry_beef", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.MELEE, true)
		ItemData.ItemType.UNPLATED_GREENS_SOUP:
			_configure_expanded_dish(data, "待摆盘青菜汤", &"greens_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_GREENS_SOUP:
			_configure_expanded_dish(data, "盘装青菜汤", &"greens_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_BEEF_SOUP:
			_configure_expanded_dish(data, "待摆盘牛肉汤", &"beef_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_BEEF_SOUP:
			_configure_expanded_dish(data, "盘装牛肉汤", &"beef_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL:
			_configure_expanded_dish(data, "待摆盘青菜盖饭", &"greens_rice_bowl", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, false)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.PLATED_GREENS_RICE_BOWL:
			_configure_expanded_dish(data, "盘装青菜盖饭", &"greens_rice_bowl", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL:
			_configure_expanded_dish(data, "待摆盘牛肉盖饭", &"beef_rice_bowl", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, false)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.PLATED_BEEF_RICE_BOWL:
			_configure_expanded_dish(data, "盘装牛肉盖饭", &"beef_rice_bowl", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.GREENS_CRUMBS:
			_configure(data, "青菜碎", ItemData.ProcessingState.GREENS_LEAVES, true, false, false, [ItemData.StationType.WOK, ItemData.StationType.STOVE])
			data.is_stackable = true
			data.stack_count = 1
			data.max_stack_count = 5
			data.leaf_count = 1
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE:
			_configure_expanded_dish(data, "待摆盘牛肉焖饭", &"beef_braised_rice", ItemData.CookingMethod.BRAISE, ItemData.AttackForm.TRAP, false)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.PLATED_BEEF_BRAISED_RICE:
			_configure_expanded_dish(data, "盘装牛肉焖饭", &"beef_braised_rice", ItemData.CookingMethod.BRAISE, ItemData.AttackForm.TRAP, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE:
			_configure_expanded_dish(data, "待摆盘青菜牛肉焖饭", &"greens_beef_braised_rice", ItemData.CookingMethod.BRAISE, ItemData.AttackForm.TRAP, false)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE:
			_configure_expanded_dish(data, "盘装青菜牛肉焖饭", &"greens_beef_braised_rice", ItemData.CookingMethod.BRAISE, ItemData.AttackForm.TRAP, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE:
			_configure_expanded_dish(data, "待摆盘青菜牛肉粥", &"greens_beef_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
		ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE:
			_configure_expanded_dish(data, "盘装青菜牛肉粥", &"greens_beef_porridge", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE:
			_configure_expanded_dish(data, "待摆盘牛肉泡饭", &"beef_soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, false)
		ItemData.ItemType.PLATED_BEEF_SOAKED_RICE:
			_configure_expanded_dish(data, "盘装牛肉泡饭", &"beef_soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, true)
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE:
			_configure_expanded_dish(data, "待摆盘青菜牛肉泡饭", &"greens_beef_soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, false)
		ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE:
			_configure_expanded_dish(data, "盘装青菜牛肉泡饭", &"greens_beef_soaked_rice", ItemData.CookingMethod.BOIL, ItemData.AttackForm.TRAP, true)
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF:
			_configure_expanded_dish(data, "待摆盘锅巴牛肉", &"crispy_rice_beef", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, false)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.PLATED_CRISPY_RICE_BEEF:
			_configure_expanded_dish(data, "盘装锅巴牛肉", &"crispy_rice_beef", ItemData.CookingMethod.MIX, ItemData.AttackForm.TRAP, true)
			data.processing_state = ItemData.ProcessingState.DEPLOYABLE_READY
		ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE:
			_configure_expanded_dish(data, "待摆盘辣椒炒饭", &"spicy_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_SPICY_FRIED_RICE:
			_configure_expanded_dish(data, "盘装辣椒炒饭", &"spicy_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS:
			_configure_expanded_dish(data, "待摆盘辣味青菜炒牛肉", &"spicy_beef_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.MELEE, false)
		ItemData.ItemType.PLATED_SPICY_BEEF_GREENS:
			_configure_expanded_dish(data, "盘装辣味青菜炒牛肉", &"spicy_beef_greens", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.MELEE, true)
		ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE:
			_configure_expanded_dish(data, "待摆盘辣味牛肉炒饭", &"spicy_beef_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE:
			_configure_expanded_dish(data, "盘装辣味牛肉炒饭", &"spicy_beef_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE:
			_configure_expanded_dish(data, "待摆盘辣味青菜牛肉炒饭", &"spicy_mixed_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE:
			_configure_expanded_dish(data, "盘装辣味青菜牛肉炒饭", &"spicy_mixed_fried_rice", ItemData.CookingMethod.STIR_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP:
			_configure_expanded_dish(data, "待摆盘辣牛肉汤", &"spicy_beef_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.PROJECTILE, false)
			data.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
		ItemData.ItemType.PLATED_SPICY_BEEF_SOUP:
			_configure_expanded_dish(data, "盘装辣牛肉汤", &"spicy_beef_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.PROJECTILE, true)
			data.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP:
			_configure_expanded_dish(data, "待摆盘辣味青菜牛肉汤", &"spicy_beef_greens_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, false)
			data.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
		ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP:
			_configure_expanded_dish(data, "盘装辣味青菜牛肉汤", &"spicy_beef_greens_soup", ItemData.CookingMethod.BOIL, ItemData.AttackForm.NONE, true)
			data.processing_state = ItemData.ProcessingState.AUTO_EQUIPMENT_READY
		ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE:
			_configure_expanded_dish(data, "待摆盘香煎米饼", &"pan_fried_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE:
			_configure_expanded_dish(data, "盘装香煎米饼", &"pan_fried_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE:
			_configure_expanded_dish(data, "待摆盘青菜米饼", &"greens_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_GREENS_RICE_CAKE:
			_configure_expanded_dish(data, "盘装青菜米饼", &"greens_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE:
			_configure_expanded_dish(data, "待摆盘牛肉米饼", &"beef_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_BEEF_RICE_CAKE:
			_configure_expanded_dish(data, "盘装牛肉米饼", &"beef_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, true)
		ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE:
			_configure_expanded_dish(data, "待摆盘青菜牛肉米饼", &"greens_beef_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, false)
		ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE:
			_configure_expanded_dish(data, "盘装青菜牛肉米饼", &"greens_beef_rice_cake", ItemData.CookingMethod.PAN_FRY, ItemData.AttackForm.PROJECTILE, true)
	ItemStorageCatalog.apply_storage_defaults(data)
	FreshnessCatalog.configure_new_item(data)
	data.recalculate_quality()
	return data


static func transform(existing: ItemData, target_type: int) -> ItemData:
	var result := create(target_type)
	result.failure_tags = existing.failure_tags.duplicate()
	result.components = existing.components.duplicate()
	result.active_modifiers = existing.active_modifiers.duplicate()
	result.has_been_used = existing.has_been_used
	result.current_durability = existing.current_durability
	result.max_durability = existing.max_durability
	result.base_damage = existing.base_damage
	result.actual_damage = existing.actual_damage
	result.has_perfect_finisher = existing.has_perfect_finisher
	if target_type != ItemData.ItemType.RAW_BEEF_SLICES or existing.item_type == ItemData.ItemType.RAW_BEEF_SLICES:
		result.remaining_portions = existing.remaining_portions
	result.attack_count = existing.attack_count
	result.next_sneeze_attack = existing.next_sneeze_attack
	result.bone_thrown = existing.bone_thrown
	result.max_remaining_portions = existing.max_remaining_portions
	result.hot_time_left = existing.hot_time_left
	result.emergency_edible = existing.emergency_edible
	result.healing_per_use = existing.healing_per_use
	result.use_duration = existing.use_duration
	result.armor_reduction = existing.armor_reduction
	result.recipe_id = existing.recipe_id
	result.ingredient_counts = existing.ingredient_counts.duplicate(true)
	result.ingredient_order = existing.ingredient_order.duplicate()
	result.completed_cooking_nodes = existing.completed_cooking_nodes.duplicate()
	result.quality_cap = existing.quality_cap
	result.weird_recipe = existing.weird_recipe
	result.deployment_state = existing.deployment_state
	result.source_recipe_instance_id = existing.source_recipe_instance_id
	result.linked_target_ids = existing.linked_target_ids.duplicate()
	result.leaf_count = existing.leaf_count
	result.beef_portion_count = existing.beef_portion_count
	result.is_marinated = existing.is_marinated
	result.auto_equipment_enabled = existing.auto_equipment_enabled
	result.effect_values = existing.effect_values.duplicate(true)
	result.spoilage_ratio = existing.spoilage_ratio
	result.freshness_lifetime = FreshnessCatalog.get_lifetime(target_type)
	result.freshness_clock_stamp = existing.freshness_clock_stamp
	result.freshness_pause_reason = existing.freshness_pause_reason
	result.rotten_source_item_type = existing.rotten_source_item_type
	result.rotten_source_name = existing.rotten_source_name
	result.rotten_source_art_key = existing.rotten_source_art_key
	result.rotten_shape_cells = existing.rotten_shape_cells.duplicate()
	result.waste_units_snapshot = existing.waste_units_snapshot
	result.waste_source_units = existing.waste_source_units
	result.waste_penalty_settled = existing.waste_penalty_settled
	if FreshnessCatalog.should_refresh_cycle(existing.item_type, target_type):
		result.reset_freshness_cycle()
	result.recalculate_quality()
	return result


static func duplicate_data(existing: ItemData) -> ItemData:
	if existing == null:
		return null
	var result := create(existing.item_type)
	result.display_name = existing.display_name
	result.processing_state = existing.processing_state
	result.is_ingredient = existing.is_ingredient
	result.is_auxiliary = existing.is_auxiliary
	result.is_cookware = existing.is_cookware
	result.allowed_stations = existing.allowed_stations.duplicate()
	result.failure_tags = existing.failure_tags.duplicate()
	result.components = existing.components.duplicate()
	result.active_modifiers = existing.active_modifiers.duplicate()
	result.quality = existing.quality
	result.is_stackable = existing.is_stackable
	result.stack_count = existing.stack_count
	result.max_stack_count = existing.max_stack_count
	result.can_be_plated = existing.can_be_plated
	result.is_combat_dish = existing.is_combat_dish
	result.current_durability = existing.current_durability
	result.max_durability = existing.max_durability
	result.base_damage = existing.base_damage
	result.actual_damage = existing.actual_damage
	result.has_perfect_finisher = existing.has_perfect_finisher
	result.carried_plate_state = existing.carried_plate_state
	result.poison_damage = existing.poison_damage
	result.poison_interval = existing.poison_interval
	result.poison_duration = existing.poison_duration
	result.poison_refresh_duration = existing.poison_refresh_duration
	result.has_been_used = existing.has_been_used
	result.remaining_portions = existing.remaining_portions
	result.attack_count = existing.attack_count
	result.next_sneeze_attack = existing.next_sneeze_attack
	result.bone_thrown = existing.bone_thrown
	result.attack_form = existing.attack_form
	result.cooking_method = existing.cooking_method
	result.stagger_power = existing.stagger_power
	result.max_remaining_portions = existing.max_remaining_portions
	result.hot_time_left = existing.hot_time_left
	result.emergency_edible = existing.emergency_edible
	result.healing_per_use = existing.healing_per_use
	result.use_duration = existing.use_duration
	result.armor_reduction = existing.armor_reduction
	result.recipe_id = existing.recipe_id
	result.ingredient_counts = existing.ingredient_counts.duplicate(true)
	result.ingredient_order = existing.ingredient_order.duplicate()
	result.completed_cooking_nodes = existing.completed_cooking_nodes.duplicate()
	result.quality_cap = existing.quality_cap
	result.weird_recipe = existing.weird_recipe
	result.deployment_state = existing.deployment_state
	result.source_recipe_instance_id = existing.source_recipe_instance_id
	result.linked_target_ids = existing.linked_target_ids.duplicate()
	result.leaf_count = existing.leaf_count
	result.beef_portion_count = existing.beef_portion_count
	result.is_marinated = existing.is_marinated
	result.auto_equipment_enabled = existing.auto_equipment_enabled
	result.effect_values = existing.effect_values.duplicate(true)
	result.spoilage_ratio = existing.spoilage_ratio
	result.freshness_lifetime = existing.freshness_lifetime
	result.freshness_clock_stamp = existing.freshness_clock_stamp
	result.freshness_pause_reason = existing.freshness_pause_reason
	result.rotten_source_item_type = existing.rotten_source_item_type
	result.rotten_source_name = existing.rotten_source_name
	result.rotten_source_art_key = existing.rotten_source_art_key
	result.rotten_shape_cells = existing.rotten_shape_cells.duplicate()
	result.waste_units_snapshot = existing.waste_units_snapshot
	result.waste_source_units = existing.waste_source_units
	result.waste_penalty_settled = existing.waste_penalty_settled
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
		ItemData.ItemType.RICE_BAG:
			return Color("b08968")
		ItemData.ItemType.SMALL_RICE_BAG:
			return Color("c9aa7b")
		ItemData.ItemType.RAW_RICE:
			return Color("f5f0df")
		ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE:
			return Color("fff8e7")
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE, ItemData.ItemType.PLATED_RICE_PORRIDGE:
			return Color("edf6f9")
		ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE:
			return Color("d4a373")
		ItemData.ItemType.WHOLE_GREENS:
			return Color("4f9f55")
		ItemData.ItemType.GREENS_LEAF:
			return Color("7acb62")
		ItemData.ItemType.RAW_BEEF_DICE:
			return Color("c65b65")
		ItemData.ItemType.MARINATED_BEEF_DICE:
			return Color("9b593d")
		ItemData.ItemType.UNPLATED_BOILED_GREENS, ItemData.ItemType.PLATED_BOILED_GREENS:
			return Color("8fd36c")
		ItemData.ItemType.UNPLATED_STIR_FRY_GREENS, ItemData.ItemType.PLATED_STIR_FRY_GREENS:
			return Color("4fa95e")
		ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS, ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS:
			return Color("8fbd4b")
		ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS, ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS:
			return Color("d87837")
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE, ItemData.ItemType.PLATED_GREENS_PORRIDGE:
			return Color("cce7bd")
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE, ItemData.ItemType.PLATED_BEEF_PORRIDGE:
			return Color("d9b1a0")
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE, ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE:
			return Color("c7aaa0")
		ItemData.ItemType.UNPLATED_BEEF_GREENS, ItemData.ItemType.PLATED_BEEF_GREENS:
			return Color("8c9f50")
		ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE, ItemData.ItemType.PLATED_GREENS_FRIED_RICE:
			return Color("c9b85e")
		ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_BEEF_FRIED_RICE:
			return Color("b9784d")
		ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_MIXED_FRIED_RICE:
			return Color("a89150")
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE, ItemData.ItemType.PLATED_VEGETABLE_RICE:
			return Color("b9c978")
		ItemData.ItemType.UNPLATED_SOAKED_RICE, ItemData.ItemType.PLATED_SOAKED_RICE:
			return Color("bfdde0")
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_SOAKED_RICE:
			return Color("9ecf9b")
		ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL:
			return Color("a88752")
		ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP, ItemData.ItemType.PLATED_BEEF_GREENS_SOUP:
			return Color("77a7a0")
		ItemData.ItemType.UNPLATED_MUSTARD_GREENS, ItemData.ItemType.PLATED_MUSTARD_GREENS:
			return Color("a7c847")
		ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE, ItemData.ItemType.PLATED_FRIED_WHITE_RICE:
			return Color("e4d28d")
		ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF, ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF:
			return Color("b56d43")
		ItemData.ItemType.UNPLATED_GREENS_SOUP, ItemData.ItemType.PLATED_GREENS_SOUP:
			return Color("8ccfa5")
		ItemData.ItemType.UNPLATED_BEEF_SOUP, ItemData.ItemType.PLATED_BEEF_SOUP:
			return Color("a97955")
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL, ItemData.ItemType.PLATED_GREENS_RICE_BOWL:
			return Color("91ad62")
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL, ItemData.ItemType.PLATED_BEEF_RICE_BOWL:
			return Color("a76e4e")
		ItemData.ItemType.GREENS_CRUMBS:
			return Color("65ad58")
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_BEEF_BRAISED_RICE:
			return Color("a77a52")
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE:
			return Color("8d9b55")
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE, ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE:
			return Color("b6c59c")
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_BEEF_SOAKED_RICE:
			return Color("c49a78")
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE:
			return Color("a6b783")
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF, ItemData.ItemType.PLATED_CRISPY_RICE_BEEF:
			return Color("9f633f")
	return Color.WHITE


static func get_art_key(item_type: int) -> StringName:
	match item_type:
		ItemData.ItemType.RAW_BEEF_CHUNK:
			return &"raw_beef_chunk"
		ItemData.ItemType.RAW_STEAK:
			return &"raw_steak"
		ItemData.ItemType.RAW_BEEF_SLICES:
			return &"raw_beef_slices"
		ItemData.ItemType.MARINATED_BEEF_SLICES:
			return &"marinated_beef_slices"
		ItemData.ItemType.SHABU_BEEF:
			return &"shabu_beef_slices"
		ItemData.ItemType.CHILI_SEGMENTS:
			return &"chili_segment"
		ItemData.ItemType.CHARCOAL:
			return &"charcoal"
		ItemData.ItemType.COOKING_OIL:
			return &"cooking_oil_bottle"
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			return &"stir_fry_beef_unplated"
		ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			return &"stir_fry_beef_plated"
		ItemData.ItemType.WOK:
			return &"wok"
		ItemData.ItemType.CLEAN_PLATE:
			return &"clean_plate_stack"
		ItemData.ItemType.DIRTY_PLATE:
			return &"dirty_plate"
		ItemData.ItemType.SALT:
			return &"salt_bottle"
		ItemData.ItemType.MARINADE:
			return &"marinade"
		ItemData.ItemType.MUSTARD:
			return &"mustard"
		ItemData.ItemType.PAN:
			return &"frying_pan"
		ItemData.ItemType.SOUP_POT:
			return &"soup_pot"
		ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			return &"tomahawk_steak"
		ItemData.ItemType.BIG_BONE:
			return &"big_bone"
		ItemData.ItemType.RICE_BAG:
			return &"rice_bag_large"
		ItemData.ItemType.SMALL_RICE_BAG:
			return &"rice_bag_small"
		ItemData.ItemType.RAW_RICE:
			return &"raw_rice"
		ItemData.ItemType.UNPLATED_WHITE_RICE:
			return &"white_rice_unplated"
		ItemData.ItemType.PLATED_WHITE_RICE:
			return &"white_rice_plated"
		ItemData.ItemType.WHOLE_GREENS:
			return &"whole_greens"
		ItemData.ItemType.GREENS_LEAF:
			return &"greens_leaf"
		ItemData.ItemType.RAW_BEEF_DICE:
			return &"raw_beef_dice"
		ItemData.ItemType.MARINATED_BEEF_DICE:
			return &"marinated_beef_dice"
		ItemData.ItemType.MUSHY_BOILED_BEEF:
			return &"mushy_boiled_beef"
		ItemData.ItemType.UNPLATED_CRISPY_RICE:
			return &"crispy_rice_unplated"
		ItemData.ItemType.PLATED_CRISPY_RICE:
			return &"crispy_rice_plated"
		ItemData.ItemType.UNPLATED_BOILED_GREENS:
			return &"boiled_greens_unplated"
		ItemData.ItemType.PLATED_BOILED_GREENS:
			return &"boiled_greens_plated"
		ItemData.ItemType.UNPLATED_STIR_FRY_GREENS:
			return &"stir_fry_greens_unplated"
		ItemData.ItemType.PLATED_STIR_FRY_GREENS:
			return &"stir_fry_greens_plated"
		ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS:
			return &"spicy_stir_fry_greens_unplated"
		ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS:
			return &"spicy_stir_fry_greens_plated"
		ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS:
			return &"flash_stir_fry_greens_unplated"
		ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS:
			return &"flash_stir_fry_greens_plated"
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE:
			return &"rice_porridge_unplated"
		ItemData.ItemType.PLATED_RICE_PORRIDGE:
			return &"rice_porridge_plated"
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE:
			return &"greens_porridge_unplated"
		ItemData.ItemType.PLATED_GREENS_PORRIDGE:
			return &"greens_porridge_plated"
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE:
			return &"beef_porridge_unplated"
		ItemData.ItemType.PLATED_BEEF_PORRIDGE:
			return &"beef_porridge_plated"
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE:
			return &"plain_beef_porridge_unplated"
		ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE:
			return &"plain_beef_porridge_plated"
		ItemData.ItemType.UNPLATED_BEEF_GREENS:
			return &"beef_greens_unplated"
		ItemData.ItemType.PLATED_BEEF_GREENS:
			return &"beef_greens_plated"
		ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE:
			return &"greens_fried_rice_unplated"
		ItemData.ItemType.PLATED_GREENS_FRIED_RICE:
			return &"greens_fried_rice_plated"
		ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE:
			return &"beef_fried_rice_unplated"
		ItemData.ItemType.PLATED_BEEF_FRIED_RICE:
			return &"beef_fried_rice_plated"
		ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE:
			return &"mixed_fried_rice_unplated"
		ItemData.ItemType.PLATED_MIXED_FRIED_RICE:
			return &"mixed_fried_rice_plated"
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE:
			return &"vegetable_rice_unplated"
		ItemData.ItemType.PLATED_VEGETABLE_RICE:
			return &"vegetable_rice_plated"
		ItemData.ItemType.UNPLATED_SOAKED_RICE:
			return &"soaked_rice_unplated"
		ItemData.ItemType.PLATED_SOAKED_RICE:
			return &"soaked_rice_plated"
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE:
			return &"greens_soaked_rice_unplated"
		ItemData.ItemType.PLATED_GREENS_SOAKED_RICE:
			return &"greens_soaked_rice_plated"
		ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL:
			return &"beef_greens_rice_bowl_plated"
		ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP:
			return &"beef_greens_soup_unplated"
		ItemData.ItemType.PLATED_BEEF_GREENS_SOUP:
			return &"beef_greens_soup_plated"
		ItemData.ItemType.UNPLATED_MUSTARD_GREENS:
			return &"mustard_greens_unplated"
		ItemData.ItemType.PLATED_MUSTARD_GREENS:
			return &"mustard_greens_plated"
		ItemData.ItemType.ROTTEN_WASTE:
			return &"rotten_waste"
		ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE:
			return &"white_rice_unplated"
		ItemData.ItemType.PLATED_FRIED_WHITE_RICE:
			return &"white_rice_plated"
		ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF:
			return &"stir_fry_beef_unplated"
		ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF:
			return &"stir_fry_beef_plated"
		ItemData.ItemType.UNPLATED_GREENS_SOUP:
			return &"greens_porridge_unplated"
		ItemData.ItemType.PLATED_GREENS_SOUP:
			return &"greens_porridge_plated"
		ItemData.ItemType.UNPLATED_BEEF_SOUP:
			return &"beef_porridge_unplated"
		ItemData.ItemType.PLATED_BEEF_SOUP:
			return &"beef_porridge_plated"
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL:
			return &"greens_rice_bowl_unplated"
		ItemData.ItemType.PLATED_GREENS_RICE_BOWL:
			return &"greens_rice_bowl_plated"
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL:
			return &"beef_rice_bowl_unplated"
		ItemData.ItemType.PLATED_BEEF_RICE_BOWL:
			return &"beef_rice_bowl_plated"
		ItemData.ItemType.GREENS_CRUMBS:
			return &"greens_leaf"
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE:
			return &"beef_braised_rice_unplated"
		ItemData.ItemType.PLATED_BEEF_BRAISED_RICE:
			return &"beef_braised_rice_plated"
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE:
			return &"greens_beef_braised_rice_unplated"
		ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE:
			return &"greens_beef_braised_rice_plated"
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE:
			return &"greens_beef_congee_unplated"
		ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE:
			return &"greens_beef_congee_plated"
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE:
			return &"beef_soaked_rice_unplated"
		ItemData.ItemType.PLATED_BEEF_SOAKED_RICE:
			return &"beef_soaked_rice_plated"
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE:
			return &"greens_beef_soaked_rice_unplated"
		ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE:
			return &"greens_beef_soaked_rice_plated"
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF:
			return &"crispy_rice_beef_unplated"
		ItemData.ItemType.PLATED_CRISPY_RICE_BEEF:
			return &"crispy_rice_beef_plated"
		ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE:
			return &"spicy_fried_rice_unplated"
		ItemData.ItemType.PLATED_SPICY_FRIED_RICE:
			return &"spicy_fried_rice_plated"
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS:
			return &"spicy_greens_beef_unplated"
		ItemData.ItemType.PLATED_SPICY_BEEF_GREENS:
			return &"spicy_greens_beef_plated"
		ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE:
			return &"spicy_beef_fried_rice_unplated"
		ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE:
			return &"spicy_beef_fried_rice_plated"
		ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE:
			return &"spicy_mixed_fried_rice_unplated"
		ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE:
			return &"spicy_mixed_fried_rice_plated"
		ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP:
			return &"spicy_beef_soup_unplated"
		ItemData.ItemType.PLATED_SPICY_BEEF_SOUP:
			return &"spicy_beef_soup_plated"
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP:
			return &"spicy_greens_beef_soup_unplated"
		ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP:
			return &"spicy_greens_beef_soup_plated"
		ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE:
			return &"plain_rice_cake_unplated"
		ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE:
			return &"plain_rice_cake_plated"
		ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE:
			return &"greens_rice_cake_unplated"
		ItemData.ItemType.PLATED_GREENS_RICE_CAKE:
			return &"greens_rice_cake_plated"
		ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE:
			return &"beef_rice_cake_unplated"
		ItemData.ItemType.PLATED_BEEF_RICE_CAKE:
			return &"beef_rice_cake_plated"
		ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE:
			return &"greens_beef_rice_cake_unplated"
		ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE:
			return &"greens_beef_rice_cake_plated"
	return &""


static func get_art_key_for_data(data: ItemData) -> StringName:
	if data == null:
		return &""
	if data.item_type == ItemData.ItemType.ROTTEN_WASTE and data.rotten_source_art_key != &"":
		return data.rotten_source_art_key
	match data.item_type:
		ItemData.ItemType.RAW_BEEF_SLICES:
			return &"raw_beef_slice_single" if data.remaining_portions <= 1 else &"raw_beef_slices"
		ItemData.ItemType.SHABU_BEEF:
			return &"shabu_beef_single" if data.stack_count <= 1 else &"shabu_beef_slices"
		ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			return &"tomahawk_steak_perfect" if data.quality == ItemData.Quality.PERFECT else &"tomahawk_steak"
	return get_art_key(data.item_type)


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


static func _configure_expanded_dish(
	data: ItemData,
	display_name: String,
	recipe_id: StringName,
	cooking_method: int,
	attack_form: int,
	plated: bool
) -> void:
	_configure(
		data,
		display_name,
		ItemData.ProcessingState.PLATED if plated else ItemData.ProcessingState.READY_TO_PLATE,
		not plated,
		false,
		false,
		[]
	)
	data.recipe_id = recipe_id
	data.cooking_method = cooking_method
	data.attack_form = attack_form
	data.is_combat_dish = true
	data.can_be_plated = not plated
	data.carried_plate_state = ItemData.PlateState.CLEAN if plated else ItemData.PlateState.NONE
