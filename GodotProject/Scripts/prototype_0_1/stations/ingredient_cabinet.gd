class_name IngredientCabinet
extends Interactable

signal stock_changed

@export_category("Prototype / Debug finite stock")
@export var raw_beef_stock: int = 12
@export var marinade_stock: int = 12
@export var chili_stock: int = 12
@export var cooking_oil_stock: int = 12
@export var salt_stock: int = 12
@export var mustard_stock: int = 12

var stock: Dictionary = {}


func _ready() -> void:
	display_title = "统一食材柜"
	placeholder_size = Vector2(220.0, 88.0)
	placeholder_color = Color("426b55")
	stock = {
		ItemData.ItemType.RAW_BEEF_CHUNK: raw_beef_stock,
		ItemData.ItemType.MARINADE: marinade_stock,
		ItemData.ItemType.CHILI_SEGMENTS: chili_stock,
		ItemData.ItemType.COOKING_OIL: cooking_oil_stock,
		ItemData.ItemType.SALT: salt_stock,
		ItemData.ItemType.MUSTARD: mustard_stock,
	}
	super._ready()
	add_to_group("ingredient_cabinet")
	_refresh_status()


func get_primary_prompt(_player: Node) -> String:
	return "[E] 打开食材柜"


func begin_primary_interaction(player: Node) -> bool:
	var cabinet_ui := get_tree().get_first_node_in_group("ingredient_cabinet_ui") as IngredientCabinetUI
	if cabinet_ui == null:
		player.notify_feedback("食材柜界面未就绪")
		return false
	cabinet_ui.open_cabinet(self, player)
	get_viewport().set_input_as_handled()
	return false


func get_stock(item_type: int) -> int:
	return int(stock.get(item_type, 0))


func configure_prototype_stock(values: Dictionary) -> void:
	# Called once by PrototypeWaveManager. The same dictionary then persists through
	# preparation, warnings, combat and wave completion without any refill.
	for item_type in get_supported_item_types():
		stock[item_type] = maxi(0, int(values.get(item_type, get_stock(item_type))))
	stock_changed.emit()
	_refresh_status()


func request_take(item_type: int, player: PrototypePlayer) -> bool:
	if get_stock(item_type) <= 0:
		player.notify_feedback("库存不足")
		return false
	if not player.can_receive_item():
		player.notify_feedback("物品栏已满")
		return false
	var item_data := ItemCatalog.create(item_type)
	if not player.receive_item_data(item_data):
		return false
	stock[item_type] = get_stock(item_type) - 1
	stock_changed.emit()
	_refresh_status()
	player.notify_feedback("从食材柜取出：%s（剩余 %d）" % [item_data.display_name, get_stock(item_type)])
	return true


func get_debug_state() -> String:
	return "统一食材柜（Prototype 有限库存）\n%s" % get_stock_summary()


func get_stock_summary() -> String:
	var lines: PackedStringArray = []
	for item_type in get_supported_item_types():
		lines.append("%s：%d" % [ItemCatalog.create(item_type).display_name, get_stock(item_type)])
	return "\n".join(lines)


func get_supported_item_types() -> Array[int]:
	return [
		ItemData.ItemType.RAW_BEEF_CHUNK,
		ItemData.ItemType.MARINADE,
		ItemData.ItemType.CHILI_SEGMENTS,
		ItemData.ItemType.COOKING_OIL,
		ItemData.ItemType.SALT,
		ItemData.ItemType.MUSTARD,
	]


func _refresh_status() -> void:
	set_placeholder_status("[E] 选择取料 · 有限 Debug 库存")
