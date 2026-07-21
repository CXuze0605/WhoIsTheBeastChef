class_name IngredientDispenser
extends Interactable

@export var prototype_item_type: int = ItemData.ItemType.RAW_BEEF_CHUNK
@export var debug_stock: int = 12


func _ready() -> void:
	display_title = "Debug 食材柜"
	placeholder_color = Color("426b55")
	super._ready()
	add_to_group("debug_dispenser")
	_refresh_status()


func get_primary_prompt(_player: Node) -> String:
	return "[E] 取得 %s" % ItemCatalog.create(prototype_item_type).display_name


func begin_primary_interaction(player: Node) -> bool:
	if player.held_item != null:
		player.notify_feedback("请先腾出手持位置")
		return false
	if debug_stock <= 0:
		player.notify_feedback("该 Debug 食材柜库存已空")
		return false
	debug_stock -= 1
	player.receive_item_data(ItemCatalog.create(prototype_item_type))
	player.notify_feedback("取得：%s（Debug 库存剩余 %d）" % [ItemCatalog.create(prototype_item_type).display_name, debug_stock])
	_refresh_status()
	return false


func get_debug_state() -> String:
	return "%s\nDebug 库存：%d（非正式数值）" % [ItemCatalog.create(prototype_item_type).display_name, debug_stock]


func _refresh_status() -> void:
	var item_name := ItemCatalog.create(prototype_item_type).display_name
	if placeholder != null:
		placeholder.set_title("食材柜\n%s" % item_name)
		placeholder.set_status("Debug 库存：%d" % debug_stock)
