class_name ShabuTrap
extends Interactable

var serving_data: ItemData
var config: PrototypeCombatConfig
var locked_enemy: BasicTasteEnemy
var lock_elapsed: float = 0.0


func setup(item_data: ItemData, combat_config: PrototypeCombatConfig) -> void:
	serving_data = ItemCatalog.transform(item_data, ItemData.ItemType.SHABU_BEEF)
	serving_data.stack_count = 1
	config = combat_config


func _ready() -> void:
	display_title = "涮牛肉诱食陷阱"
	placeholder_size = Vector2(72.0, 42.0)
	placeholder_color = Color("e5989b")
	super._ready()
	add_to_group("shabu_trap")
	_refresh_visual()


func _process(delta: float) -> void:
	if locked_enemy != null:
		lock_elapsed += delta
		if not is_instance_valid(locked_enemy) or locked_enemy.state in [BasicTasteEnemy.State.REFLAVORING, BasicTasteEnemy.State.DISABLED] or lock_elapsed > config.shabu_lock_timeout:
			release_claim(locked_enemy)
	_refresh_visual()


func can_interact(player: Node) -> bool:
	return locked_enemy == null and super.can_interact(player)


func get_carry_prompt(player: Node) -> String:
	return "[F] 收回 1 片涮牛肉" if locked_enemy == null and player.can_receive_item_data(serving_data) else ""


func carry_interact(player: Node) -> void:
	if locked_enemy != null:
		player.notify_feedback("这片涮牛肉已被味真族锁定")
		return
	var returned := ItemCatalog.transform(serving_data, ItemData.ItemType.SHABU_BEEF)
	returned.stack_count = 1
	if player.receive_item_data(returned):
		player.notify_feedback("已收回 1 片涮牛肉")
		queue_free()


func is_available_for(enemy: BasicTasteEnemy) -> bool:
	return locked_enemy == null and is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= config.shabu_aroma_radius


func try_claim(enemy: BasicTasteEnemy) -> bool:
	if not is_available_for(enemy):
		return false
	locked_enemy = enemy
	lock_elapsed = 0.0
	_refresh_visual()
	return true


func release_claim(enemy: BasicTasteEnemy) -> void:
	if enemy != null and locked_enemy != enemy:
		return
	locked_enemy = null
	lock_elapsed = 0.0
	_refresh_visual()


func get_taste_damage() -> float:
	var multiplier := 1.0
	if serving_data.failure_tags.size() == 1:
		multiplier = config.shabu_one_tag_multiplier
	elif serving_data.failure_tags.size() >= 2:
		multiplier = config.shabu_two_tag_multiplier
	return config.shabu_standard_damage * multiplier


func get_taste_duration() -> float:
	var multiplier := 1.0
	if serving_data.failure_tags.size() == 1:
		multiplier = config.shabu_one_tag_multiplier
	elif serving_data.failure_tags.size() >= 2:
		multiplier = config.shabu_two_tag_multiplier
	return config.shabu_standard_taste_time * multiplier


func consume_by(enemy: BasicTasteEnemy) -> void:
	if enemy != locked_enemy:
		return
	locked_enemy = null
	enemy.receive_trap_reflavor_damage(get_taste_damage())
	queue_free()


func _refresh_visual() -> void:
	if placeholder == null:
		return
	placeholder.set_title("涮牛肉\n（临时餐垫）")
	placeholder.set_status("已锁定" if locked_enemy != null else "香气范围 · 可收回")
	placeholder.set_color(Color("ef9a9a") if locked_enemy != null else Color("e5989b"))
