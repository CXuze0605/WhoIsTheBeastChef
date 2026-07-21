class_name CleanPlatePile
extends Interactable

@export var prototype_initial_stock: int = 6

var washed_plate_count: int = 0
var total_claimed: int = 0
var available_plate_count: int = 0


func _ready() -> void:
	display_title = "干净盘子堆"
	placeholder_size = Vector2(150.0, 76.0)
	placeholder_color = Color("8fc7d1")
	super._ready()
	add_to_group("clean_plate_pile")
	available_plate_count = prototype_initial_stock
	_refresh_status()


func get_carry_prompt(_player: Node) -> String:
	return "[F] 取得 1 个干净盘子"


func carry_interact(player: Node) -> void:
	if available_plate_count <= 0:
		player.notify_feedback("干净盘子库存不足")
		return
	var plate_data := ItemCatalog.create(ItemData.ItemType.CLEAN_PLATE)
	if not player.can_receive_item_data(plate_data):
		player.notify_feedback("物品栏已满")
		return
	if player.receive_item_data(plate_data):
		available_plate_count -= 1
		total_claimed += 1
		player.notify_feedback("取得干净盘子（剩余 %d）" % available_plate_count)
		_refresh_status()


func add_washed_plate(amount: int = 1) -> void:
	var actual := maxi(0, amount)
	washed_plate_count += actual
	available_plate_count += actual
	_refresh_status()


func configure_initial_stock(amount: int) -> void:
	prototype_initial_stock = maxi(0, amount)
	available_plate_count = prototype_initial_stock
	_refresh_status()


func reset_for_new_game(amount: int) -> void:
	prototype_initial_stock = maxi(0, amount)
	available_plate_count = prototype_initial_stock
	washed_plate_count = 0
	total_claimed = 0
	_refresh_status()


func get_debug_state() -> String:
	return "干净盘子堆\n当前可领取：%d（Prototype 有限初始量）\n洗净累计：%d\n领取累计：%d" % [available_plate_count, washed_plate_count, total_claimed]


func _refresh_status() -> void:
	set_placeholder_status("可领取 %d / 洗净累计 %d" % [available_plate_count, washed_plate_count])
