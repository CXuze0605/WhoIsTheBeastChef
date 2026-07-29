class_name IngredientCabinet
extends Interactable

signal stock_changed

@export_category("Prototype 0.6A initial actual items")
@export var raw_beef_stock: int = 1
@export var marinade_stock: int = 1
@export var chili_stock: int = 2
@export var cooking_oil_stock: int = 1
@export var salt_stock: int = 1
@export var mustard_stock: int = 1
@export var rice_bag_stock: int = 1
@export var whole_greens_stock: int = 1

var storage: GridInventory
var storage_node: Node2D
var lobby_unlimited: bool = false
var lobby_replenishing: bool = false
var lobby_replenish_queued: bool = false


func _ready() -> void:
	display_title = "异形食材柜"
	placeholder_size = Vector2(220.0, 88.0)
	placeholder_color = Color("426b55")
	super._ready()
	add_to_group("ingredient_cabinet")
	storage_node = Node2D.new()
	storage_node.name = "CabinetStorage"
	add_child(storage_node)
	storage = GridInventory.new(
		ItemStorageCatalog.CABINET_SIZE.x,
		ItemStorageCatalog.CABINET_SIZE.y,
		storage_node
	)
	storage.changed.connect(_on_storage_changed)
	configure_prototype_stock({
		ItemData.ItemType.RAW_BEEF_CHUNK: raw_beef_stock,
		ItemData.ItemType.MARINADE: marinade_stock,
		ItemData.ItemType.CHILI_SEGMENTS: chili_stock,
		ItemData.ItemType.COOKING_OIL: cooking_oil_stock,
		ItemData.ItemType.SALT: salt_stock,
		ItemData.ItemType.MUSTARD: mustard_stock,
		ItemData.ItemType.RICE_BAG: rice_bag_stock,
		ItemData.ItemType.WHOLE_GREENS: whole_greens_stock,
	})


func get_primary_prompt(_player: Node) -> String:
	return "[%s] 打开异形食材柜" % InputPrompt.action_text(&"interact_primary", "E")


func begin_primary_interaction(player: Node) -> bool:
	var cabinet_ui := get_tree().get_first_node_in_group("ingredient_cabinet_ui") as IngredientCabinetUI
	if cabinet_ui == null:
		player.notify_feedback("食材柜界面未就绪")
		return false
	cabinet_ui.open_cabinet(self, player)
	get_viewport().set_input_as_handled()
	return false


func get_storage() -> GridInventory:
	return storage


func get_stock(item_type: int) -> int:
	var total := 0
	if storage == null:
		return total
	for item in storage.get_items():
		if item.data.item_type == item_type:
			total += item.data.stack_count
	return total


func get_resource_portions(item_type: int) -> int:
	var total := 0
	if storage == null:
		return total
	for item in storage.get_items():
		if item.data.item_type != item_type:
			continue
		total += item.data.remaining_portions if item.data.is_reusable_resource_container() else item.data.stack_count
	return total


func configure_prototype_stock(values: Dictionary) -> void:
	if storage == null:
		return
	lobby_unlimited = false
	lobby_replenish_queued = false
	storage.clear_all()
	if not storage.resize_grid(ItemStorageCatalog.FORMAL_CABINET_SIZE.x, ItemStorageCatalog.FORMAL_CABINET_SIZE.y):
		push_error("Formal cabinet could not resize to %s" % ItemStorageCatalog.FORMAL_CABINET_SIZE)
		return
	for item_type in get_formal_item_types():
		var remaining := maxi(0, int(values.get(item_type, 0)))
		while remaining > 0:
			var data := ItemCatalog.create(item_type)
			var created_count := mini(remaining, data.max_stack_count)
			data.stack_count = created_count
			var item := ItemFactory.create_carryable(data)
			add_child(item)
			if not storage.add_item_auto(item, true):
				push_error("Prototype 0.6A cabinet initial stock does not fit: item_type=%d" % item_type)
				item.queue_free()
				break
			remaining -= created_count
	_refresh_status()


func configure_lobby_unlimited_catalog() -> void:
	if storage == null:
		return
	lobby_unlimited = true
	lobby_replenish_queued = false
	lobby_replenishing = true
	storage.clear_all()
	if not storage.resize_grid(ItemStorageCatalog.LOBBY_TEST_CABINET_SIZE.x, ItemStorageCatalog.LOBBY_TEST_CABINET_SIZE.y):
		lobby_replenishing = false
		push_error("Test-lobby cabinet could not resize to %s" % ItemStorageCatalog.LOBBY_TEST_CABINET_SIZE)
		return
	_populate_missing_lobby_items()
	lobby_replenishing = false
	_refresh_status()


func request_take(item_type: int, player: PrototypePlayer) -> bool:
	if lobby_unlimited:
		var unlimited_data := _create_lobby_sample_data(item_type)
		if not player.receive_item_data(unlimited_data):
			return false
		player.notify_feedback("测试大厅无限取用：%s" % unlimited_data.display_name)
		return true
	var source := _find_item(item_type)
	if source == null:
		player.notify_feedback("库存不足")
		return false
	var unit_data := ItemCatalog.duplicate_data(source.data)
	unit_data.stack_count = 1
	if not player.can_receive_item_data(unit_data):
		player.notify_feedback("快捷栏和背包均没有足够空间")
		return false
	if source.data.stack_count > 1:
		if not player.receive_item_data(unit_data):
			return false
		source.data.stack_count -= 1
		source.refresh_visual()
		storage.changed.emit()
	else:
		var old_placement := storage.remove_item(source)
		if not player.pickup_item(source):
			storage.add_item_at(source, old_placement.origin, old_placement.rotated)
			return false
	_refresh_status()
	player.notify_feedback("从食材柜取出：%s（剩余 %d）" % [unit_data.display_name, get_stock(item_type)])
	return true


func store_item(item: CarryableItem, origin := Vector2i(-1, -1), rotated: bool = false) -> bool:
	if storage == null or item == null:
		return false
	if origin.x < 0 or origin.y < 0:
		return storage.add_item_auto(item)
	return storage.add_item_at(item, origin, rotated)


func take_item(item: CarryableItem) -> GridInventory.Placement:
	return storage.remove_item(item) if storage != null else null


func get_debug_state() -> String:
	if lobby_unlimited:
		return "测试大厅全物品柜（20×80，无限取用）\n%s" % get_stock_summary()
	return "异形食材柜（10×8，正式有限库存）\n%s" % get_stock_summary()


func get_stock_summary() -> String:
	var lines: PackedStringArray = []
	for item_type in get_supported_item_types():
		var sample := ItemCatalog.create(item_type)
		var amount_text := "∞" if lobby_unlimited else str(get_stock(item_type))
		if not lobby_unlimited and sample.is_reusable_resource_container():
			amount_text = "%d件 / %d份" % [get_stock(item_type), get_resource_portions(item_type)]
		lines.append("%s：%s" % [
			sample.display_name,
			amount_text,
		])
	return "\n".join(lines)


func get_supported_item_types() -> Array[int]:
	return get_all_item_types() if lobby_unlimited else get_formal_item_types()


static func get_formal_item_types() -> Array[int]:
	return [
		ItemData.ItemType.RAW_BEEF_CHUNK,
		ItemData.ItemType.MARINADE,
		ItemData.ItemType.CHILI_SEGMENTS,
		ItemData.ItemType.COOKING_OIL,
		ItemData.ItemType.SALT,
		ItemData.ItemType.MUSTARD,
		ItemData.ItemType.RICE_BAG,
		ItemData.ItemType.WHOLE_GREENS,
	]


static func get_all_item_types() -> Array[int]:
	var all_types: Array[int] = []
	for item_type in ItemData.ItemType.size():
		all_types.append(item_type)
	return all_types


func _find_item(item_type: int) -> CarryableItem:
	for item in storage.get_items():
		if item.data.item_type == item_type:
			return item
	return null


func _on_storage_changed() -> void:
	stock_changed.emit()
	if lobby_unlimited and not lobby_replenishing and not lobby_replenish_queued:
		lobby_replenish_queued = true
		call_deferred("_replenish_lobby_catalog")
	_refresh_status()


func _refresh_status() -> void:
	if lobby_unlimited:
		set_placeholder_status("[%s] 测试大厅 · 全物品无限取用" % InputPrompt.action_text(&"interact_primary", "E"))
	else:
		set_placeholder_status("[%s] 正式本局 · 10×8 有限实际仓储" % InputPrompt.action_text(&"interact_primary", "E"))


func _replenish_lobby_catalog() -> void:
	lobby_replenish_queued = false
	if not lobby_unlimited or storage == null:
		return
	lobby_replenishing = true
	_populate_missing_lobby_items()
	lobby_replenishing = false
	_refresh_status()


func _populate_missing_lobby_items() -> void:
	for item_type in get_all_item_types():
		if _find_item(item_type) != null:
			continue
		var item := ItemFactory.create_carryable(_create_lobby_sample_data(item_type))
		add_child(item)
		var catalog_position := _find_lobby_catalog_position(item)
		if catalog_position == Vector2i(-1, -1) or not storage.add_item_at(item, catalog_position, false):
			push_error("Test-lobby unlimited cabinet could not fit item_type=%d" % item_type)
			item.queue_free()


func _find_lobby_catalog_position(item: CarryableItem) -> Vector2i:
	# Keep the first three rows empty as a visible manipulation workbench. This
	# makes rotating and comparing large items practical instead of packing the
	# unlimited catalog into every available top-left cell. The scan deliberately
	# uses storage.height so replenishment can continue through the full
	# 20×80 test-only catalog as the ItemType list grows.
	var bounds := ItemStorageCatalog.get_shape_bounds(
		ItemStorageCatalog.get_shape_cells_for_data(item.data, false)
	)
	for y in range(3, storage.height - bounds.y + 1):
		for x in range(0, storage.width - bounds.x + 1):
			var origin := Vector2i(x, y)
			if storage.can_place_item(item, origin, false):
				return origin
	return Vector2i(-1, -1)


func _create_lobby_sample_data(item_type: int) -> ItemData:
	var data := ItemCatalog.create(item_type)
	data.stack_count = 1
	var combat_config := PrototypeCombatConfig.new()
	match item_type:
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			combat_config.apply_combat_dish_stats(data)
		ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			combat_config.apply_tomahawk_stats(data)
		ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE:
			combat_config.apply_white_rice_stats(data)
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE, ItemData.ItemType.PLATED_RICE_PORRIDGE:
			combat_config.apply_rice_porridge_stats(data)
		ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE:
			combat_config.apply_crispy_rice_stats(data)
		ItemData.ItemType.UNPLATED_BOILED_GREENS, ItemData.ItemType.PLATED_BOILED_GREENS:
			data = ExpandedRecipeCatalog.create_boiled_greens(5, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_BOILED_GREENS:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_STIR_FRY_GREENS, ItemData.ItemType.PLATED_STIR_FRY_GREENS:
			data = ExpandedRecipeCatalog.create_stir_fry_greens(5, ExpandedRecipeCatalog.STIR_FRY_GREENS, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_STIR_FRY_GREENS:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS, ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS:
			data = ExpandedRecipeCatalog.create_stir_fry_greens(5, ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS, ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS:
			data = ExpandedRecipeCatalog.create_stir_fry_greens(5, ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE, ItemData.ItemType.PLATED_GREENS_PORRIDGE:
			data = ExpandedRecipeCatalog.create_porridge(ExpandedRecipeCatalog.GREENS_PORRIDGE, 5, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_GREENS_PORRIDGE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE, ItemData.ItemType.PLATED_BEEF_PORRIDGE:
			data = ExpandedRecipeCatalog.create_porridge(ExpandedRecipeCatalog.BEEF_PORRIDGE, 0, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_BEEF_PORRIDGE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE, ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE:
			data = ExpandedRecipeCatalog.create_porridge(ExpandedRecipeCatalog.PLAIN_BEEF_PORRIDGE, 0, [], combat_config)
			if item_type == ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_GREENS, ItemData.ItemType.PLATED_BEEF_GREENS:
			data = ExpandedRecipeCatalog.create_wok_combination(ExpandedRecipeCatalog.BEEF_GREENS, [ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), _lobby_leaf_stack()], combat_config)
			if item_type == ItemData.ItemType.PLATED_BEEF_GREENS:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE, ItemData.ItemType.PLATED_GREENS_FRIED_RICE:
			data = ExpandedRecipeCatalog.create_wok_combination(ExpandedRecipeCatalog.GREENS_FRIED_RICE, [_lobby_leaf_stack(), ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)], combat_config)
			if item_type == ItemData.ItemType.PLATED_GREENS_FRIED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_BEEF_FRIED_RICE:
			data = ExpandedRecipeCatalog.create_wok_combination(ExpandedRecipeCatalog.BEEF_FRIED_RICE, [ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)], combat_config)
			if item_type == ItemData.ItemType.PLATED_BEEF_FRIED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_MIXED_FRIED_RICE:
			data = ExpandedRecipeCatalog.create_wok_combination(ExpandedRecipeCatalog.MIXED_FRIED_RICE, [ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE), _lobby_leaf_stack(), ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)], combat_config)
			if item_type == ItemData.ItemType.PLATED_MIXED_FRIED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE, ItemData.ItemType.PLATED_VEGETABLE_RICE:
			data = ExpandedRecipeCatalog.create_rice_function_dish(ExpandedRecipeCatalog.VEGETABLE_RICE, 5, [_lobby_leaf_stack()], combat_config)
			if item_type == ItemData.ItemType.PLATED_VEGETABLE_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_SOAKED_RICE, ItemData.ItemType.PLATED_SOAKED_RICE:
			data = ExpandedRecipeCatalog.create_rice_function_dish(ExpandedRecipeCatalog.SOAKED_RICE, 0, [ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)], combat_config)
			if item_type == ItemData.ItemType.PLATED_SOAKED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_SOAKED_RICE:
			data = ExpandedRecipeCatalog.create_rice_function_dish(ExpandedRecipeCatalog.GREENS_SOAKED_RICE, 5, [ItemCatalog.create(ItemData.ItemType.UNPLATED_SOAKED_RICE), _lobby_leaf_stack()], combat_config)
			if item_type == ItemData.ItemType.PLATED_GREENS_SOAKED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL:
			data = ExpandedRecipeCatalog.create_advanced_dish(
				ExpandedRecipeCatalog.BEEF_GREENS_RICE_BOWL,
				5,
				[ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE), ExpandedRecipeCatalog.create_wok_combination(ExpandedRecipeCatalog.BEEF_GREENS, [ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), _lobby_leaf_stack()], combat_config)],
				combat_config
			)
		ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP, ItemData.ItemType.PLATED_BEEF_GREENS_SOUP:
			data = ExpandedRecipeCatalog.create_advanced_dish(ExpandedRecipeCatalog.BEEF_GREENS_SOUP, 5, [ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES), _lobby_leaf_stack()], combat_config)
			if item_type == ItemData.ItemType.PLATED_BEEF_GREENS_SOUP:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_MUSTARD_GREENS, ItemData.ItemType.PLATED_MUSTARD_GREENS:
			data = ExpandedRecipeCatalog.create_advanced_dish(ExpandedRecipeCatalog.MUSTARD_GREENS, 5, [_lobby_leaf_stack(), ItemCatalog.create(ItemData.ItemType.MUSTARD)], combat_config)
			if item_type == ItemData.ItemType.PLATED_MUSTARD_GREENS:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_FRIED_WHITE_RICE, ItemData.ItemType.PLATED_FRIED_WHITE_RICE:
			data = ExpandedRecipeCatalog.create_missing_group_1_dish(
				ExpandedRecipeCatalog.FRIED_WHITE_RICE,
				[ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_FRIED_WHITE_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_CLEAR_STIR_FRY_BEEF, ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF:
			data = ExpandedRecipeCatalog.create_missing_group_1_dish(
				ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
				[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_SOUP, ItemData.ItemType.PLATED_GREENS_SOUP:
			data = ExpandedRecipeCatalog.create_missing_group_1_dish(
				ExpandedRecipeCatalog.GREENS_SOUP,
				[_lobby_leaf_stack()],
				combat_config,
				5
			)
			if item_type == ItemData.ItemType.PLATED_GREENS_SOUP:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_SOUP, ItemData.ItemType.PLATED_BEEF_SOUP:
			data = ExpandedRecipeCatalog.create_missing_group_1_dish(
				ExpandedRecipeCatalog.BEEF_SOUP,
				[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_BEEF_SOUP:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL, ItemData.ItemType.PLATED_GREENS_RICE_BOWL:
			var greens_component := ExpandedRecipeCatalog.create_boiled_greens(5, [_lobby_leaf_stack()], combat_config)
			data = ExpandedRecipeCatalog.create_group_2_rice_bowl(
				ExpandedRecipeCatalog.GREENS_RICE_BOWL,
				[ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE), greens_component],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_GREENS_RICE_BOWL:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL, ItemData.ItemType.PLATED_BEEF_RICE_BOWL:
			var beef_component := ExpandedRecipeCatalog.create_missing_group_1_dish(
				ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
				[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
				combat_config
			)
			data = ExpandedRecipeCatalog.create_group_2_rice_bowl(
				ExpandedRecipeCatalog.BEEF_RICE_BOWL,
				[ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE), beef_component],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_BEEF_RICE_BOWL:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_BEEF_BRAISED_RICE:
			data = ExpandedRecipeCatalog.create_group_3_braised_rice(
				ExpandedRecipeCatalog.BEEF_BRAISED_RICE,
				[
					ItemCatalog.create(ItemData.ItemType.RAW_RICE),
					ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE),
				],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_BEEF_BRAISED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE:
			data = ExpandedRecipeCatalog.create_group_3_braised_rice(
				ExpandedRecipeCatalog.GREENS_BEEF_BRAISED_RICE,
				[
					ItemCatalog.create(ItemData.ItemType.RAW_RICE),
					ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE),
					_lobby_leaf_stack(),
				],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE, ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE:
			data = ExpandedRecipeCatalog.create_porridge(
				ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE,
				5,
				[
					ItemCatalog.create(ItemData.ItemType.UNPLATED_RICE_PORRIDGE),
					ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES),
					_lobby_leaf_stack(),
				],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_BEEF_SOAKED_RICE:
			data = ExpandedRecipeCatalog.create_rice_function_dish(
				ExpandedRecipeCatalog.BEEF_SOAKED_RICE,
				0,
				[
					ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE),
					ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES),
				],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_BEEF_SOAKED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE:
			data = ExpandedRecipeCatalog.create_rice_function_dish(
				ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
				5,
				[
					ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE),
					ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES),
					_lobby_leaf_stack(),
				],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF, ItemData.ItemType.PLATED_CRISPY_RICE_BEEF:
			var crispy_component := ItemCatalog.create(ItemData.ItemType.UNPLATED_CRISPY_RICE)
			combat_config.apply_crispy_rice_stats(crispy_component)
			var clear_beef_component := ExpandedRecipeCatalog.create_missing_group_1_dish(
				ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF,
				[ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)],
				combat_config
			)
			data = ExpandedRecipeCatalog.create_group_5_crispy_beef(
				[crispy_component, clear_beef_component],
				combat_config
			)
			if item_type == ItemData.ItemType.PLATED_CRISPY_RICE_BEEF:
				data = ItemCatalog.transform(data, item_type)
		ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE, ItemData.ItemType.PLATED_SPICY_FRIED_RICE, \
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS, ItemData.ItemType.PLATED_SPICY_BEEF_GREENS, \
		ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE, \
		ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE, \
		ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP, ItemData.ItemType.PLATED_SPICY_BEEF_SOUP, \
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP, ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP, \
		ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE, ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE, \
		ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE, ItemData.ItemType.PLATED_GREENS_RICE_CAKE, \
		ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE, ItemData.ItemType.PLATED_BEEF_RICE_CAKE, \
		ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE, ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE:
			data = _create_groups_6_7_lobby_sample(item_type, combat_config)
	_finalize_lobby_sample_quality(data, item_type, combat_config)
	return data


func _create_groups_6_7_lobby_sample(item_type: int, combat_config: PrototypeCombatConfig) -> ItemData:
	var recipe_by_type := {
		ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE: ExpandedRecipeCatalog.SPICY_FRIED_RICE,
		ItemData.ItemType.PLATED_SPICY_FRIED_RICE: ExpandedRecipeCatalog.SPICY_FRIED_RICE,
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS: ExpandedRecipeCatalog.SPICY_BEEF_GREENS,
		ItemData.ItemType.PLATED_SPICY_BEEF_GREENS: ExpandedRecipeCatalog.SPICY_BEEF_GREENS,
		ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE: ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE,
		ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE: ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE,
		ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE: ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
		ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE: ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
		ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP: ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
		ItemData.ItemType.PLATED_SPICY_BEEF_SOUP: ExpandedRecipeCatalog.SPICY_BEEF_SOUP,
		ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP: ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
		ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP: ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
		ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE: ExpandedRecipeCatalog.PAN_FRIED_RICE_CAKE,
		ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE: ExpandedRecipeCatalog.PAN_FRIED_RICE_CAKE,
		ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE: ExpandedRecipeCatalog.GREENS_RICE_CAKE,
		ItemData.ItemType.PLATED_GREENS_RICE_CAKE: ExpandedRecipeCatalog.GREENS_RICE_CAKE,
		ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE: ExpandedRecipeCatalog.BEEF_RICE_CAKE,
		ItemData.ItemType.PLATED_BEEF_RICE_CAKE: ExpandedRecipeCatalog.BEEF_RICE_CAKE,
		ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE: ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
		ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE: ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
	}
	var recipe: StringName = recipe_by_type[item_type]
	var rice := ItemCatalog.create(ItemData.ItemType.UNPLATED_WHITE_RICE)
	combat_config.apply_white_rice_stats(rice)
	var beef_slices := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_SLICES)
	var beef_dice := ItemCatalog.create(ItemData.ItemType.MARINATED_BEEF_DICE)
	var chili := ItemCatalog.create(ItemData.ItemType.CHILI_SEGMENTS)
	var oil := ItemCatalog.create(ItemData.ItemType.COOKING_OIL)
	var leaves := _lobby_leaf_stack()
	var crumbs := ItemCatalog.create(ItemData.ItemType.GREENS_CRUMBS)
	crumbs.stack_count = 5
	crumbs.leaf_count = 5
	var sources: Array[ItemData] = [rice, oil]
	if recipe == ExpandedRecipeCatalog.SPICY_FRIED_RICE:
		sources.append(chili)
	elif recipe == ExpandedRecipeCatalog.SPICY_BEEF_GREENS:
		sources = [beef_slices, leaves, chili, oil]
	elif recipe == ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE:
		sources = [beef_dice, rice, chili, oil]
	elif recipe == ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE:
		sources = [beef_dice, leaves, rice, chili, oil]
	elif recipe == ExpandedRecipeCatalog.SPICY_BEEF_SOUP:
		sources = [beef_dice, chili]
	elif recipe == ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP:
		sources = [beef_slices, leaves, chili]
	elif recipe == ExpandedRecipeCatalog.GREENS_RICE_CAKE:
		sources = [rice, crumbs, oil]
	elif recipe == ExpandedRecipeCatalog.BEEF_RICE_CAKE:
		sources = [beef_dice, rice, oil]
	elif recipe == ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE:
		sources = [beef_dice, rice, crumbs, oil]
	var data := ExpandedRecipeCatalog.create_groups_6_7_dish(recipe, sources, combat_config, 5 if recipe in [
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS,
		ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
		ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP,
		ExpandedRecipeCatalog.GREENS_RICE_CAKE,
		ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
	] else 0)
	if String(ItemData.ItemType.keys()[item_type]).begins_with("PLATED_"):
		data = ItemCatalog.transform(data, item_type)
	return data


func _finalize_lobby_sample_quality(data: ItemData, item_type: int, combat_config: PrototypeCombatConfig) -> void:
	if data == null:
		return
	var enum_name := String(ItemData.ItemType.keys()[item_type])
	if (
		not enum_name.begins_with("PLATED_")
		or not data.is_combat_dish
		or data.is_weird_dish()
		or data.quality_cap != ItemData.Quality.PERFECT
		or not data.failure_tags.is_empty()
	):
		return
	data.set_quality_with_cap(ItemData.Quality.PERFECT)
	match item_type:
		ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			combat_config.apply_combat_dish_stats(data)
		ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			combat_config.apply_tomahawk_stats(data)
		ItemData.ItemType.PLATED_WHITE_RICE:
			combat_config.apply_white_rice_stats(data)
		ItemData.ItemType.PLATED_RICE_PORRIDGE:
			combat_config.apply_rice_porridge_stats(data)
		ItemData.ItemType.PLATED_CRISPY_RICE:
			combat_config.apply_crispy_rice_stats(data)
		_:
			ExpandedRecipeCatalog.refresh_after_plating(data, combat_config)
	data.current_durability = data.max_durability


func _lobby_leaf_stack() -> ItemData:
	var leaves := ItemCatalog.create(ItemData.ItemType.GREENS_LEAF)
	leaves.stack_count = 5
	leaves.leaf_count = 5
	return leaves
