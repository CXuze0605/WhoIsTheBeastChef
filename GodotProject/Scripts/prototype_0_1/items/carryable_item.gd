class_name CarryableItem
extends Interactable

var data: ItemData
var pickup_enabled: bool = true
var storage_rotated: bool = false
var is_loot_drop: bool = false
var loot_pickup_counted: bool = false

const DEFAULT_HELD_SCALE := Vector2(0.68, 0.68)
const TOMAHAWK_HELD_ART_SCALE: float = 3.2


func setup(item_data: ItemData) -> void:
	data = item_data
	display_title = data.display_name
	placeholder_size = Vector2(86.0, 44.0)
	placeholder_color = ItemCatalog.get_item_color(data.item_type)
	if is_node_ready():
		refresh_visual()


func _ready() -> void:
	super._ready()
	refresh_visual()


func can_interact(player: Node) -> bool:
	return pickup_enabled and super.can_interact(player)


func get_carry_prompt(player: Node) -> String:
	if player.can_receive_item(self):
		return "[F] 拿起 %s" % data.display_name
	return ""


func carry_interact(player: Node) -> void:
	player.pickup_item(self)


func set_held(anchor: Node2D) -> void:
	visible = true
	pickup_enabled = false
	interaction_enabled = false
	if get_parent() != anchor:
		reparent(anchor)
	position = Vector2.ZERO
	scale = DEFAULT_HELD_SCALE
	z_index = 20
	_apply_default_visual_pose()
	if _is_unplated_tomahawk():
		placeholder.set_text_visible(false)


func set_inventory_stored(container: Node2D) -> void:
	pickup_enabled = false
	interaction_enabled = false
	if get_parent() != container:
		reparent(container)
	position = Vector2.ZERO
	scale = Vector2.ONE
	z_index = 0
	visible = false
	_apply_default_visual_pose()


func set_stored(container: Node, local_position: Vector2) -> void:
	visible = true
	pickup_enabled = false
	interaction_enabled = false
	if get_parent() != container:
		reparent(container)
	position = local_position
	scale = Vector2(0.58, 0.58)
	z_index = 5
	_apply_default_visual_pose()


func release_to_world(world: Node, world_position: Vector2) -> void:
	visible = true
	if get_parent() != world:
		reparent(world)
	global_position = world_position
	scale = Vector2.ONE
	z_index = 5
	pickup_enabled = true
	interaction_enabled = true
	_apply_default_visual_pose()


func update_held_pose(facing_direction: Vector2) -> void:
	if placeholder == null:
		return
	if not _is_unplated_tomahawk():
		placeholder.set_art_transform()
		return
	# The source art points toward local up. Rotate its steak head outward while
	# keeping the long bone close to the player's hand, so it reads as an axe.
	var direction := facing_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	placeholder.set_art_transform(TOMAHAWK_HELD_ART_SCALE, direction.angle() + PI * 0.5)


func _apply_default_visual_pose() -> void:
	if placeholder == null:
		return
	placeholder.set_art_transform()
	placeholder.set_text_visible(true)


func _is_unplated_tomahawk() -> bool:
	return data != null and data.item_type == ItemData.ItemType.TOMAHAWK_STEAK


func mark_as_loot_drop() -> void:
	is_loot_drop = true
	loot_pickup_counted = false
	add_to_group("loot_drop")
	refresh_visual()


func mark_loot_picked_up() -> void:
	is_loot_drop = false
	remove_from_group("loot_drop")
	refresh_visual()


func refresh_visual() -> void:
	if data == null or placeholder == null:
		return
	display_title = data.display_name
	placeholder.set_title(data.display_name)
	placeholder.set_color(ItemCatalog.get_item_color(data.item_type))
	PrototypeArtCatalog.apply_to(placeholder, ItemCatalog.get_art_key_for_data(data))
	var status := ""
	var title := data.display_name
	if data.is_stackable:
		title += " ×%d" % data.stack_count
	if data.item_type == ItemData.ItemType.RAW_BEEF_SLICES:
		title += "（剩余%d片）" % data.remaining_portions
	placeholder.set_title(title)
	if not data.failure_tags.is_empty():
		status = data.get_failure_tags_text()
	if not data.active_modifiers.is_empty():
		status = "%s主动调味：%s" % [(status + "\n") if not status.is_empty() else "", data.get_active_modifiers_text()]
	if data.is_combat_dish:
		status = "%s%s  耐久 %d/%d" % ["怪异 · " if data.is_weird_dish() else "", data.get_quality_text(), data.current_durability, data.max_durability]
	placeholder.set_status(status)


func get_debug_description() -> String:
	if data == null:
		return "空物品"
	var stack_text := "\n数量：%d/%d" % [data.stack_count, data.max_stack_count] if data.is_stackable else ""
	var portion_text := "\n原料份数：%d/5" % data.remaining_portions if data.item_type == ItemData.ItemType.RAW_BEEF_SLICES else ""
	var combat_text := "\n耐久：%d/%d\n伤害：%.1f\n已使用：%s\n完美终结：%s" % [data.current_durability, data.max_durability, data.actual_damage, "是" if data.has_been_used else "否", "是" if data.has_perfect_finisher else "否"] if data.is_combat_dish else ""
	return "%s%s%s\n失败标签：%s\n主动调味：%s\n怪异料理：%s\n品质：%s%s" % [data.display_name, stack_text, portion_text, data.get_failure_tags_text(), data.get_active_modifiers_text(), "是" if data.is_weird_dish() else "否", data.get_quality_text(), combat_text]
