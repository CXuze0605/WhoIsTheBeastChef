class_name PrototypePlayer
extends CharacterBody2D

signal player_defeated
signal health_changed(current: float, maximum: float)

@export var prototype_move_speed: float = 240.0
@export var prototype_interaction_distance: float = 108.0
@export var prototype_max_health: float = 100.0

@onready var held_anchor: Node2D = $HeldAnchor
@onready var inventory_storage: Node2D = $InventoryStorage
@onready var direction_marker: Polygon2D = $DirectionMarker

var inventory := QuickInventory.new()
var held_item: CarryableItem:
	get:
		return inventory.get_selected_item()
var current_target: Interactable
var active_interactable: Interactable
var facing_direction := Vector2.DOWN
var feedback_text: String = "Prototype 0.2.1 已启动"
var feedback_time_left: float = 4.0
var modal_ui_open: bool = false
var current_health: float
var knockback_velocity := Vector2.ZERO
var spawn_position := Vector2.ZERO
var hit_protection_time: float = 0.22
var hit_protection_left: float = 0.0
var is_defeated: bool = false
var hit_flash_left: float = 0.0
var action_stun_left: float = 0.0


func _ready() -> void:
	current_health = prototype_max_health
	spawn_position = global_position
	add_to_group("damageable")
	add_to_group("player_target")
	collision_layer = 2
	collision_mask = 5
	inventory.changed.connect(_refresh_inventory_visuals)
	inventory.selection_changed.connect(_on_inventory_selection_changed)
	_refresh_inventory_visuals()
	health_changed.emit(current_health, prototype_max_health)


func _physics_process(delta: float) -> void:
	feedback_time_left = maxf(0.0, feedback_time_left - delta)
	hit_protection_left = maxf(0.0, hit_protection_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	action_stun_left = maxf(0.0, action_stun_left - delta)
	modulate = Color("ffadad") if hit_flash_left > 0.0 else Color.WHITE
	if modal_ui_open:
		current_target = null
	else:
		_update_current_target()
	var movement_locked := is_defeated or modal_ui_open or action_stun_left > 0.0 or (active_interactable != null and active_interactable.blocks_movement_during_primary())
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement_locked:
		velocity = Vector2.ZERO
	else:
		velocity = input_direction * prototype_move_speed + knockback_velocity
		if not input_direction.is_zero_approx():
			facing_direction = input_direction.normalized()
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	_update_facing_visual()
	_update_active_interaction(delta)


func _unhandled_input(event: InputEvent) -> void:
	if modal_ui_open or is_defeated or action_stun_left > 0.0:
		return
	for slot_index in QuickInventory.SLOT_COUNT:
		if event.is_action_pressed("select_hotbar_%d" % (slot_index + 1)):
			inventory.select(slot_index)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			inventory.cycle(-1)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			inventory.cycle(1)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact_carry"):
		if current_target != null:
			current_target.carry_interact(self)
		else:
			notify_feedback("附近没有可拿取或放置的对象")
	elif event.is_action_pressed("interact_cookware"):
		if current_target != null:
			current_target.secondary_interact(self)
		else:
			notify_feedback("附近没有锅具工位")
	elif event.is_action_pressed("drop_item"):
		drop_held_item()
	elif event.is_action_pressed("interact_primary"):
		_start_primary_interaction()
	elif event.is_action_released("interact_primary"):
		_cancel_active_interaction()


func pickup_item(item: CarryableItem) -> bool:
	var destination := inventory.add_item(item)
	if destination == -1:
		notify_feedback("物品栏已满")
		return false
	_refresh_inventory_visuals()
	notify_feedback("收纳到格子 %d：%s" % [destination + 1, item.data.display_name])
	return true


func can_receive_item(item: CarryableItem = null) -> bool:
	return inventory.can_accept_data(item.data) if item != null else not inventory.is_full()


func can_receive_item_data(item_data: ItemData) -> bool:
	return inventory.can_accept_data(item_data)


func release_held_to_container(container: Node, local_position: Vector2) -> CarryableItem:
	if held_item == null:
		return null
	var item := inventory.take_selected_item()
	item.set_stored(container, local_position)
	return item


func consume_held_item() -> void:
	if held_item == null:
		return
	var item := inventory.take_selected_item()
	item.queue_free()


func receive_item_data(item_data: ItemData) -> bool:
	if not can_receive_item_data(item_data):
		notify_feedback("物品栏已满")
		return false
	var item := ItemFactory.create_carryable(item_data)
	get_tree().current_scene.add_child(item)
	item.global_position = global_position
	if pickup_item(item):
		return true
	item.queue_free()
	return false


func take_selected_item_node() -> CarryableItem:
	var item := inventory.take_selected_item()
	_refresh_inventory_visuals()
	return item


func drop_held_item() -> void:
	if held_item == null:
		notify_feedback("当前选中格为空")
		return
	var item := inventory.take_selected_item()
	item.release_to_world(get_tree().current_scene, global_position + facing_direction * 58.0)
	notify_feedback("放下：%s" % item.data.display_name)


func notify_feedback(message: String) -> void:
	feedback_text = message
	feedback_time_left = 4.0


func get_visible_feedback() -> String:
	return feedback_text if feedback_time_left > 0.0 else ""


func get_interaction_prompt() -> String:
	if modal_ui_open:
		return "界面操作中"
	if current_target == null:
		return "附近没有可交互目标"
	var prompts: PackedStringArray = []
	var carry_prompt := current_target.get_carry_prompt(self)
	var primary_prompt := current_target.get_primary_prompt(self)
	var secondary_prompt := current_target.get_secondary_prompt(self)
	if not carry_prompt.is_empty():
		prompts.append(carry_prompt)
	if not primary_prompt.is_empty():
		prompts.append(primary_prompt)
	if not secondary_prompt.is_empty():
		prompts.append(secondary_prompt)
	return "  ".join(prompts) if not prompts.is_empty() else "当前目标没有可用操作"


func get_inspected_item_data() -> ItemData:
	if held_item == null:
		return null
	if held_item is WokItem:
		var wok := held_item as WokItem
		return wok.content_data
	if held_item is PanItem:
		return (held_item as PanItem).content_data
	if held_item is SoupPotItem:
		return (held_item as SoupPotItem).content_data
	return held_item.data


func _start_primary_interaction() -> void:
	if modal_ui_open:
		return
	if current_target == null:
		notify_feedback("附近没有可操作目标")
		return
	if active_interactable != null:
		return
	if current_target.begin_primary_interaction(self):
		active_interactable = current_target


func _cancel_active_interaction() -> void:
	if active_interactable == null:
		return
	if is_instance_valid(active_interactable):
		active_interactable.cancel_primary_interaction(self)
	active_interactable = null


func _update_active_interaction(delta: float) -> void:
	if active_interactable == null:
		return
	if not is_instance_valid(active_interactable):
		active_interactable = null
		return
	if global_position.distance_to(active_interactable.global_position) > prototype_interaction_distance:
		_cancel_active_interaction()
		return
	if not Input.is_action_pressed("interact_primary"):
		_cancel_active_interaction()
		return
	if not active_interactable.update_primary_interaction(self, delta):
		active_interactable = null


func set_modal_ui_open(value: bool) -> void:
	if modal_ui_open == value:
		return
	modal_ui_open = value
	if modal_ui_open:
		_cancel_active_interaction()
		velocity = Vector2.ZERO


func get_combat_faction() -> int:
	return CombatRules.Faction.PLAYER


func receive_combat_hit(
	damage: float,
	attacker_faction: int,
	knockback_direction: Vector2,
	knockback_force: float,
	friendly_fire: bool,
	_stagger_power: float = 0.0
) -> bool:
	if is_defeated or hit_protection_left > 0.0:
		return false
	if not CombatRules.can_damage(attacker_faction, get_combat_faction(), friendly_fire):
		return false
	current_health = maxf(0.0, current_health - damage)
	health_changed.emit(current_health, prototype_max_health)
	knockback_velocity += knockback_direction.normalized() * knockback_force
	hit_protection_left = hit_protection_time
	hit_flash_left = 0.16
	notify_feedback("受到伤害：%.0f" % damage)
	if current_health <= 0.0:
		is_defeated = true
		velocity = Vector2.ZERO
		notify_feedback("Prototype：测试波次失败，按 T 重新开始")
		player_defeated.emit()
	return true


func configure_wave_health(max_health: float, protection_time: float) -> void:
	prototype_max_health = max_health
	current_health = max_health
	hit_protection_time = protection_time
	is_defeated = false
	health_changed.emit(current_health, prototype_max_health)


func apply_action_stun(duration: float, message: String = "短暂僵直") -> void:
	action_stun_left = maxf(action_stun_left, duration)
	velocity = Vector2.ZERO
	notify_feedback(message)


func reset_wave_health() -> void:
	current_health = prototype_max_health
	hit_protection_left = 0.0
	is_defeated = false
	global_position = spawn_position
	knockback_velocity = Vector2.ZERO
	health_changed.emit(current_health, prototype_max_health)


func reset_for_new_game(max_health: float, protection_time: float) -> void:
	_cancel_active_interaction()
	inventory.clear_all()
	prototype_max_health = max_health
	current_health = max_health
	hit_protection_time = protection_time
	hit_protection_left = 0.0
	hit_flash_left = 0.0
	action_stun_left = 0.0
	is_defeated = false
	knockback_velocity = Vector2.ZERO
	global_position = spawn_position
	facing_direction = Vector2.DOWN
	modal_ui_open = false
	health_changed.emit(current_health, prototype_max_health)
	_refresh_inventory_visuals()


func _on_inventory_selection_changed(_slot_index: int) -> void:
	_cancel_active_interaction()
	_refresh_inventory_visuals()
	var item := held_item
	notify_feedback("切换到格子 %d：%s" % [inventory.selected_index + 1, item.data.display_name if item != null else "空"])


func _refresh_inventory_visuals() -> void:
	if not is_node_ready():
		return
	for slot_index in QuickInventory.SLOT_COUNT:
		var item := inventory.get_item(slot_index)
		if item == null or not is_instance_valid(item):
			continue
		if slot_index == inventory.selected_index:
			item.set_held(held_anchor)
		else:
			item.set_inventory_stored(inventory_storage)


func _update_current_target() -> void:
	var nearest: Interactable
	var nearest_distance := prototype_interaction_distance
	for candidate_node in get_tree().get_nodes_in_group("interactable"):
		var candidate := candidate_node as Interactable
		if candidate == null or not candidate.can_interact(self):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	current_target = nearest


func _update_facing_visual() -> void:
	direction_marker.rotation = facing_direction.angle() + PI * 0.5
	held_anchor.position = facing_direction * 34.0
