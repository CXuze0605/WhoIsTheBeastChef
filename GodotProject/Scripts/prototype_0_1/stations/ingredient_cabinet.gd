class_name IngredientCabinet
extends Interactable

signal stock_changed

@export_category("Prototype 0.6A initial actual items")
@export var raw_beef_stock: int = 1
@export var marinade_stock: int = 1
@export var chili_stock: int = 2
@export var cooking_oil_stock: int = 2
@export var salt_stock: int = 1
@export var mustard_stock: int = 1

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
	})


func get_primary_prompt(_player: Node) -> String:
	return "[E] 打开异形食材柜"


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
		return "测试大厅全物品柜（20×20，无限取用）\n%s" % get_stock_summary()
	return "异形食材柜（10×8，正式有限库存）\n%s" % get_stock_summary()


func get_stock_summary() -> String:
	var lines: PackedStringArray = []
	for item_type in get_supported_item_types():
		lines.append("%s：%s" % [
			ItemCatalog.create(item_type).display_name,
			"∞" if lobby_unlimited else str(get_stock(item_type)),
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
	]


static func get_all_item_types() -> Array[int]:
	# Largest shapes first so one representative of all 22 current item types
	# fits in the existing 10x8 test-lobby cabinet.
	return [
		ItemData.ItemType.RAW_BEEF_CHUNK,
		ItemData.ItemType.WOK,
		ItemData.ItemType.SOUP_POT,
		ItemData.ItemType.PAN,
		ItemData.ItemType.PLATED_TOMAHAWK_STEAK,
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF,
		ItemData.ItemType.PLATED_STIR_FRY_BEEF,
		ItemData.ItemType.CLEAN_PLATE,
		ItemData.ItemType.DIRTY_PLATE,
		ItemData.ItemType.RAW_STEAK,
		ItemData.ItemType.TOMAHAWK_STEAK,
		ItemData.ItemType.BIG_BONE,
		ItemData.ItemType.COOKING_OIL,
		ItemData.ItemType.RAW_BEEF_SLICES,
		ItemData.ItemType.MARINATED_BEEF_SLICES,
		ItemData.ItemType.MARINADE,
		ItemData.ItemType.CHILI_SEGMENTS,
		ItemData.ItemType.CHARCOAL,
		ItemData.ItemType.SALT,
		ItemData.ItemType.MUSTARD,
		ItemData.ItemType.SHABU_BEEF,
		ItemData.ItemType.MUSHY_BOILED_BEEF,
	]


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
		set_placeholder_status("[E] 测试大厅 · 全物品无限取用")
	else:
		set_placeholder_status("[E] 正式本局 · 10×8 有限实际仓储")


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
		if not storage.add_item_auto(item, false):
			push_error("Test-lobby unlimited cabinet could not fit item_type=%d" % item_type)
			item.queue_free()


func _create_lobby_sample_data(item_type: int) -> ItemData:
	var data := ItemCatalog.create(item_type)
	data.stack_count = 1
	var combat_config := PrototypeCombatConfig.new()
	match item_type:
		ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			combat_config.apply_combat_dish_stats(data)
		ItemData.ItemType.TOMAHAWK_STEAK, ItemData.ItemType.PLATED_TOMAHAWK_STEAK:
			combat_config.apply_tomahawk_stats(data)
	return data
