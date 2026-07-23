class_name ShabuTrap
extends Interactable

class AromaRangeIndicator:
	extends Node2D

	var radius: float = 0.0
	var locked: bool = false
	var pulse: float = 0.0

	func configure(new_radius: float) -> void:
		radius = maxf(0.0, new_radius)
		queue_redraw()

	func set_visual_state(is_locked: bool, elapsed: float) -> void:
		locked = is_locked
		pulse = 0.5 + sin(elapsed * 2.4) * 0.5
		queue_redraw()

	func _draw() -> void:
		if radius <= 0.0:
			return
		var base_color := Color("ff8f70") if locked else Color("f6bd60")
		draw_circle(Vector2.ZERO, radius, Color(base_color, 0.035 + pulse * 0.025), true)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(base_color, 0.76), 3.0, true)
		draw_arc(Vector2.ZERO, radius - 7.0, 0.0, TAU, 96, Color(base_color, 0.18 + pulse * 0.16), 2.0, true)
		for index in 12:
			var angle := TAU * float(index) / 12.0
			var direction := Vector2.RIGHT.rotated(angle)
			draw_line(direction * (radius - 13.0), direction * (radius + 3.0), Color(base_color, 0.82), 2.0, true)

var serving_data: ItemData
var config: PrototypeCombatConfig
var locked_enemy: BasicTasteEnemy
var lock_elapsed: float = 0.0
var aroma_visual_time: float = 0.0
var aroma_indicator: AromaRangeIndicator


func setup(item_data: ItemData, combat_config: PrototypeCombatConfig) -> void:
	serving_data = ItemCatalog.transform(item_data, ItemData.ItemType.SHABU_BEEF)
	serving_data.stack_count = 1
	config = combat_config


func _ready() -> void:
	if config == null:
		config = PrototypeCombatConfig.new()
	display_title = "涮牛肉诱食陷阱"
	placeholder_size = Vector2(72.0, 42.0)
	placeholder_color = Color("e5989b")
	super._ready()
	add_to_group("shabu_trap")
	aroma_indicator = AromaRangeIndicator.new()
	aroma_indicator.name = "AromaRangeIndicator"
	aroma_indicator.z_index = -1
	aroma_indicator.show_behind_parent = true
	add_child(aroma_indicator)
	aroma_indicator.configure(config.shabu_aroma_radius)
	_refresh_visual()


func _process(delta: float) -> void:
	aroma_visual_time += delta
	if locked_enemy != null:
		lock_elapsed += delta
		if not is_instance_valid(locked_enemy) or locked_enemy.state in [BasicTasteEnemy.State.REFLAVORING, BasicTasteEnemy.State.DISABLED] or lock_elapsed > config.shabu_lock_timeout:
			release_claim(locked_enemy)
	if aroma_indicator != null:
		aroma_indicator.set_visual_state(locked_enemy != null, aroma_visual_time)
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


func get_aroma_visual_radius() -> float:
	return aroma_indicator.radius if aroma_indicator != null else 0.0


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
	PrototypeArtCatalog.apply_to(placeholder, &"shabu_beef_single")
	placeholder.set_title("涮牛肉\n（临时餐垫）")
	placeholder.set_status("已锁定" if locked_enemy != null else "香气范围 · 可收回")
	placeholder.set_color(Color("ef9a9a") if locked_enemy != null else Color("e5989b"))
