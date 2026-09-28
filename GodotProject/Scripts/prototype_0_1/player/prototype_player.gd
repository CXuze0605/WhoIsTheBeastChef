class_name PrototypePlayer
extends CharacterBody2D

signal player_defeated
signal health_changed(current: float, maximum: float)
signal shield_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal shield_feedback(event_name: StringName)
signal effective_damage_received

@export var prototype_move_speed: float = 240.0
@export var prototype_sprint_speed_multiplier: float = 2.0
@export var prototype_max_stamina: float = 100.0
@export var prototype_sprint_drain_per_second: float = 30.0
@export var prototype_stamina_regen_delay: float = 0.8
@export var prototype_stamina_regen_per_second: float = 25.0
@export var prototype_interaction_distance: float = 108.0
@export var prototype_max_health: float = 100.0

@onready var held_anchor: Node2D = $HeldAnchor
@onready var inventory_storage: Node2D = $InventoryStorage

var inventory := QuickInventory.new()
var backpack: GridInventory
var backpack_storage: Node2D
var held_item: CarryableItem:
	get:
		return inventory.get_selected_item()
var current_target: Interactable
var active_interactable: Interactable
var facing_direction := Vector2.DOWN
var feedback_text: String = "Prototype 0.2.1 已启动"
var feedback_time_left: float = 4.0
var modal_ui_open: bool = false
var action_qte_locked: bool = false
var current_health: float
var prototype_max_shield: float = 30.0
var current_shield: float = 30.0
var shield_regen_delay: float = 4.0
var shield_regen_per_second: float = 10.0
var time_since_last_damage: float = 999.0
var shield_was_regenerating: bool = false
var current_stamina: float = 100.0
var stamina_regen_delay_left: float = 0.0
var is_sprinting: bool = false
var sprint_exhausted: bool = false
var knockback_velocity := Vector2.ZERO
var spawn_position := Vector2.ZERO
var hit_protection_time: float = 0.22
var hit_protection_left: float = 0.0
var is_defeated: bool = false
var hit_flash_left: float = 0.0
var action_stun_left: float = 0.0
var global_modal_overlay_open: bool = false
var hold_progress_bar: ProgressBar
var walk_animator: PlayerCharacterAnimator
var is_consuming: bool = false
var consuming_item: CarryableItem
var consuming_elapsed: float = 0.0
var consuming_duration: float = 0.0
var consuming_heal_total: float = 0.0
var consuming_healed: float = 0.0
var consuming_is_porridge: bool = false
var hot_burn_time_left: float = 0.0
var hot_burn_damage_left: float = 0.0
var healing_over_time_left: float = 0.0
var healing_over_time_rate: float = 0.0
var boiled_greens_cooldown_left: float = 0.0
var boiled_greens_inside: Dictionary = {}
var combat_statuses: CombatStatusController
var auto_dish_controller: AutoDishEquipmentController


func _ready() -> void:
	current_health = prototype_max_health
	current_stamina = prototype_max_stamina
	spawn_position = global_position
	add_to_group("damageable")
	add_to_group("player_target")
	combat_statuses = CombatStatusController.ensure_on(self)
	collision_layer = 2
	collision_mask = 5
	inventory.changed.connect(_refresh_inventory_visuals)
	inventory.selection_changed.connect(_on_inventory_selection_changed)
	backpack_storage = Node2D.new()
	backpack_storage.name = "BackpackStorage"
	add_child(backpack_storage)
	backpack = GridInventory.new(
		ItemStorageCatalog.BACKPACK_SIZE.x,
		ItemStorageCatalog.BACKPACK_SIZE.y,
		backpack_storage
	)
	backpack.changed.connect(_refresh_inventory_visuals)
	auto_dish_controller = AutoDishEquipmentController.new()
	auto_dish_controller.name = "AutoDishEquipmentController"
	auto_dish_controller.setup(self)
	add_child(auto_dish_controller)
	walk_animator = PlayerCharacterAnimator.new()
	walk_animator.name = "PlayerCharacterAnimator"
	add_child(walk_animator)
	walk_animator.configure($PlayerArt as AnimatedSprite2D)
	_build_hold_progress_indicator()
	effective_damage_received.connect(_on_effective_damage_received)
	_refresh_inventory_visuals()
	health_changed.emit(current_health, prototype_max_health)
	shield_changed.emit(current_shield, prototype_max_shield)
	stamina_changed.emit(current_stamina, prototype_max_stamina)


func _physics_process(delta: float) -> void:
	feedback_time_left = maxf(0.0, feedback_time_left - delta)
	hit_protection_left = maxf(0.0, hit_protection_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	action_stun_left = maxf(0.0, action_stun_left - delta)
	_update_shield_regeneration(delta)
	_update_consumption(delta)
	_update_hot_burn(delta)
	_update_healing_over_time(delta)
	_update_boiled_greens(delta)
	modulate = Color("ffadad") if hit_flash_left > 0.0 else Color.WHITE
	if modal_ui_open:
		current_target = null
	else:
		_update_current_target()
	var movement_locked := is_defeated or modal_ui_open or action_stun_left > 0.0 or is_consuming or (active_interactable != null and active_interactable.blocks_movement_during_primary())
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var movement_speed_multiplier := 1.0
	var sprint_requested := Input.is_action_pressed("sprint")
	is_sprinting = _update_stamina(
		delta,
		not movement_locked and not input_direction.is_zero_approx(),
		sprint_requested
	)
	if movement_locked:
		velocity = Vector2.ZERO
	else:
		movement_speed_multiplier = combat_statuses.get_move_speed_multiplier() if combat_statuses != null else 1.0
		var sprint_multiplier := prototype_sprint_speed_multiplier if is_sprinting else 1.0
		velocity = input_direction * prototype_move_speed * movement_speed_multiplier * sprint_multiplier + knockback_velocity
		if not input_direction.is_zero_approx():
			facing_direction = input_direction.normalized()
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	if walk_animator != null:
		walk_animator.update_animation(
			Vector2.ZERO if movement_locked else input_direction,
			facing_direction,
			movement_speed_multiplier < 0.999,
			is_defeated,
			is_sprinting
		)
	_update_facing_visual()
	_update_active_interaction(delta)
	_update_hold_progress_indicator()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("secondary_use") and is_consuming:
		_cancel_consumption("主动停止进食")
		get_viewport().set_input_as_handled()
		return
	if modal_ui_open or action_qte_locked or is_defeated or action_stun_left > 0.0:
		return
	if is_consuming:
		return
	if event.is_action_pressed("secondary_use"):
		_start_secondary_use()
		get_viewport().set_input_as_handled()
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


func _pickup_item_hotbar_only(item: CarryableItem) -> bool:
	var destination := inventory.add_item(item)
	if destination == -1:
		notify_feedback("物品栏已满")
		return false
	_refresh_inventory_visuals()
	notify_feedback("收纳到格子 %d：%s" % [destination + 1, item.data.display_name])
	return true


func pickup_item(item: CarryableItem) -> bool:
	if item == null or item.data == null:
		return false
	var item_name := item.data.display_name
	var accepted_any := inventory.merge_from_item(item) > 0
	if item.data.stack_count <= 0:
		_finish_world_pickup(item, accepted_any)
		item.queue_free()
		notify_feedback("已合并到快捷栏：%s" % item_name)
		return true
	var destination := inventory.add_item_to_empty(item)
	if destination != -1:
		_finish_world_pickup(item, true)
		_refresh_inventory_visuals()
		notify_feedback("收纳到快捷栏 %d：%s" % [destination + 1, item_name])
		return true
	if backpack != null and backpack.merge_from_item(item) > 0:
		accepted_any = true
	if item.data.stack_count <= 0:
		_finish_world_pickup(item, accepted_any)
		item.queue_free()
		notify_feedback("已合并到异形背包：%s" % item_name)
		return true
	if backpack != null and backpack.add_item_auto(item, false):
		_finish_world_pickup(item, true)
		notify_feedback("快捷栏已满，已收入异形背包：%s" % item_name)
		return true
	if accepted_any:
		_finish_world_pickup(item, true)
		item.release_to_world(get_tree().current_scene, item.global_position)
		notify_feedback("已收纳部分物品；快捷栏和背包均没有足够空间")
		return false
	notify_feedback("快捷栏和背包均没有足够空间")
	return false


func _can_receive_item_hotbar_only(item: CarryableItem = null) -> bool:
	return inventory.can_accept_data(item.data) if item != null else not inventory.is_full()


func can_receive_item(item: CarryableItem = null) -> bool:
	if item == null:
		if inventory.find_destination_slot() != -1:
			return true
		if backpack == null:
			return false
		for y in backpack.height:
			for x in backpack.width:
				if backpack.can_place_shape([Vector2i.ZERO], Vector2i(x, y)):
					return true
		return false
	return can_receive_item_data(item.data)


func can_receive_item_data(item_data: ItemData) -> bool:
	if item_data == null:
		return false
	if inventory.can_accept_data(item_data):
		return true
	var remaining := item_data.stack_count
	if item_data.is_stackable:
		remaining -= inventory.get_stack_capacity_for(item_data)
		if remaining <= 0:
			return true
	if inventory.find_destination_slot() != -1:
		return true
	if backpack == null:
		return false
	var probe_data := ItemCatalog.duplicate_data(item_data)
	probe_data.stack_count = maxi(1, remaining)
	return backpack.can_accept_data(probe_data)


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


func consume_held_resource_portion(expected_item_type: int) -> bool:
	if held_item == null or held_item.data == null or held_item.data.item_type != expected_item_type:
		return false
	var item := held_item
	if not item.data.consume_resource_portions(1):
		return false
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_resource_consumed(item.data.item_type, 1)
	if item.data.remaining_portions <= 0:
		var removed := inventory.take_selected_item()
		if removed != null:
			removed.queue_free()
	else:
		item.refresh_visual()
		inventory.notify_item_changed()
	_refresh_inventory_visuals()
	return true


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


func get_backpack() -> GridInventory:
	return backpack


func move_quick_item_to_backpack(slot_index: int, origin := Vector2i(-1, -1), rotated: bool = false) -> bool:
	var item := inventory.get_item(slot_index)
	if item == null or backpack == null:
		return false
	var placed := false
	if origin.x < 0 or origin.y < 0:
		placed = backpack.add_item_auto(item)
	else:
		placed = backpack.add_item_at(item, origin, rotated)
	if not placed:
		return false
	inventory.take_item(slot_index)
	_refresh_inventory_visuals()
	return true


func move_backpack_item_to_quick(item: CarryableItem, slot_index: int = -1) -> bool:
	if backpack == null or backpack.get_placement(item) == null:
		return false
	var destination := slot_index if slot_index >= 0 else inventory.find_destination_slot()
	if destination < 0 or inventory.get_item(destination) != null:
		return false
	var old_placement := backpack.remove_item(item)
	if inventory.put_item(destination, item):
		_refresh_inventory_visuals()
		return true
	backpack.add_item_at(item, old_placement.origin, old_placement.rotated)
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
	record_discarded_item(item.data)
	item.release_to_world(get_tree().current_scene, global_position + facing_direction * 58.0)
	if item.data.item_type == ItemData.ItemType.ROTTEN_WASTE:
		var freshness := get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
		if freshness != null:
			freshness.settle_waste(item.data, &"drop")
	notify_feedback("放下：%s" % item.data.display_name)


func record_discarded_item(data: ItemData) -> void:
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_item_discarded(data)


func record_resource_consumed(item_type: int, portions: int = 1) -> void:
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_resource_consumed(item_type, portions)


func notify_feedback(message: String) -> void:
	feedback_text = message
	feedback_time_left = 4.0


func get_visible_feedback() -> String:
	return feedback_text if feedback_time_left > 0.0 else ""


func get_interaction_prompt() -> String:
	if modal_ui_open:
		return "界面操作中"
	if action_qte_locked:
		return "QTE 进行中：可移动，攻击/交互/切换已锁定"
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
	var target_name := current_target.display_title
	return "%s：%s" % [target_name, "  ".join(prompts)] if not prompts.is_empty() else "%s：当前没有可用操作" % target_name


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
		_hide_hold_progress_indicator()
		return
	if is_instance_valid(active_interactable):
		active_interactable.cancel_primary_interaction(self)
	active_interactable = null
	_hide_hold_progress_indicator()


func _update_active_interaction(delta: float) -> void:
	if active_interactable == null:
		return
	if not is_instance_valid(active_interactable):
		active_interactable = null
		_hide_hold_progress_indicator()
		return
	if global_position.distance_to(active_interactable.global_position) > prototype_interaction_distance:
		_cancel_active_interaction()
		return
	if not Input.is_action_pressed("interact_primary"):
		_cancel_active_interaction()
		return
	if not active_interactable.update_primary_interaction(self, delta):
		active_interactable = null
		_hide_hold_progress_indicator()


func set_modal_ui_open(value: bool) -> void:
	if modal_ui_open == value:
		return
	modal_ui_open = value
	if modal_ui_open:
		_cancel_consumption("界面打开，进食中断")
		_cancel_active_interaction()
		velocity = Vector2.ZERO
	_hide_hold_progress_indicator()


func set_action_qte_locked(value: bool) -> void:
	action_qte_locked = value
	if action_qte_locked:
		_cancel_consumption("QTE 开始，进食中断")
		_cancel_active_interaction()
	_hide_hold_progress_indicator()


func set_global_modal_overlay_open(value: bool) -> void:
	global_modal_overlay_open = value
	if global_modal_overlay_open:
		_hide_hold_progress_indicator()
	else:
		_update_hold_progress_indicator()


func get_active_interaction_progress_ratio() -> float:
	if active_interactable == null or not is_instance_valid(active_interactable) or not active_interactable.has_method("get_progress_ratio"):
		return 0.0
	return clampf(float(active_interactable.get_progress_ratio()), 0.0, 1.0)


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
	var context := DamageContext.from_legacy(
		damage,
		attacker_faction,
		get_combat_faction(),
		friendly_fire
	)
	return receive_damage_context(context, knockback_direction, knockback_force)


func receive_damage_context(
	context: DamageContext,
	knockback_direction: Vector2 = Vector2.ZERO,
	knockback_force: float = 0.0,
	_stagger_power: float = 0.0
) -> bool:
	if is_defeated or hit_protection_left > 0.0:
		return false
	if context == null or not CombatRules.can_damage(context.attacker_faction, get_combat_faction(), context.friendly_fire):
		return false
	context.target_faction = get_combat_faction()
	var resolved_damage := CombatRules.resolve_damage(context, self)
	var reduced_damage := _apply_active_crispy_rice(maxf(1.0, resolved_damage))
	var shield_before := current_shield
	var absorbed := minf(current_shield, reduced_damage)
	current_shield = maxf(0.0, current_shield - absorbed)
	var health_damage := maxf(0.0, reduced_damage - absorbed)
	var health_before := current_health
	current_health = maxf(0.0, current_health - health_damage)
	context.actual_shield_damage = absorbed
	context.actual_health_damage = health_before - current_health
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_damage_context(context)
	health_changed.emit(current_health, prototype_max_health)
	shield_changed.emit(current_shield, prototype_max_shield)
	time_since_last_damage = 0.0
	shield_was_regenerating = false
	if shield_before > 0.0 and current_shield <= 0.0:
		shield_feedback.emit(&"broken")
	else:
		shield_feedback.emit(&"hit")
	effective_damage_received.emit()
	knockback_velocity += knockback_direction.normalized() * knockback_force
	hit_protection_left = hit_protection_time
	hit_flash_left = 0.16
	notify_feedback("受到伤害：%.0f（护盾吸收 %.0f）" % [reduced_damage, absorbed])
	if current_health <= 0.0:
		is_defeated = true
		velocity = Vector2.ZERO
		if walk_animator != null:
			walk_animator.play_defeat()
		notify_feedback("厨房失守：请查看本局结算")
		player_defeated.emit()
	return true


func configure_wave_health(
	max_health: float,
	protection_time: float,
	max_shield: float = 30.0,
	regen_delay: float = 4.0,
	regen_per_second: float = 10.0,
	max_stamina: float = 100.0,
	sprint_speed_multiplier: float = 2.0,
	sprint_drain_per_second: float = 30.0,
	stamina_regen_delay: float = 0.8,
	stamina_regen_per_second: float = 25.0
) -> void:
	prototype_max_health = max_health
	current_health = max_health
	hit_protection_time = protection_time
	prototype_max_shield = maxf(0.0, max_shield)
	current_shield = prototype_max_shield
	shield_regen_delay = maxf(0.0, regen_delay)
	shield_regen_per_second = maxf(0.0, regen_per_second)
	_configure_stamina(
		max_stamina,
		sprint_speed_multiplier,
		sprint_drain_per_second,
		stamina_regen_delay,
		stamina_regen_per_second
	)
	time_since_last_damage = shield_regen_delay
	shield_was_regenerating = false
	is_defeated = false
	if walk_animator != null:
		walk_animator.show_idle(facing_direction)
	health_changed.emit(current_health, prototype_max_health)
	shield_changed.emit(current_shield, prototype_max_shield)
	stamina_changed.emit(current_stamina, prototype_max_stamina)


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
	if walk_animator != null:
		walk_animator.show_idle(facing_direction)
	health_changed.emit(current_health, prototype_max_health)
	restore_shield_for_wave()


func reset_for_new_game(
	max_health: float,
	protection_time: float,
	max_shield: float = 30.0,
	regen_delay: float = 4.0,
	regen_per_second: float = 10.0,
	max_stamina: float = 100.0,
	sprint_speed_multiplier: float = 2.0,
	sprint_drain_per_second: float = 30.0,
	stamina_regen_delay: float = 0.8,
	stamina_regen_per_second: float = 25.0
) -> void:
	_cancel_active_interaction()
	if is_consuming:
		_clear_consumption_state()
	hot_burn_time_left = 0.0
	hot_burn_damage_left = 0.0
	inventory.clear_all()
	if backpack != null:
		backpack.clear_all()
	prototype_max_health = max_health
	current_health = max_health
	hit_protection_time = protection_time
	prototype_max_shield = maxf(0.0, max_shield)
	current_shield = prototype_max_shield
	shield_regen_delay = maxf(0.0, regen_delay)
	shield_regen_per_second = maxf(0.0, regen_per_second)
	_configure_stamina(
		max_stamina,
		sprint_speed_multiplier,
		sprint_drain_per_second,
		stamina_regen_delay,
		stamina_regen_per_second
	)
	time_since_last_damage = shield_regen_delay
	shield_was_regenerating = false
	hit_protection_left = 0.0
	hit_flash_left = 0.0
	action_stun_left = 0.0
	if combat_statuses != null:
		combat_statuses.clear_all()
	is_defeated = false
	knockback_velocity = Vector2.ZERO
	global_position = spawn_position
	facing_direction = Vector2.DOWN
	modal_ui_open = false
	action_qte_locked = false
	global_modal_overlay_open = false
	if walk_animator != null:
		walk_animator.show_idle(facing_direction)
	health_changed.emit(current_health, prototype_max_health)
	shield_changed.emit(current_shield, prototype_max_shield)
	stamina_changed.emit(current_stamina, prototype_max_stamina)
	_refresh_inventory_visuals()
	_hide_hold_progress_indicator()
	var attack_controller := get_node_or_null("DishAttackController") as DishAttackController
	if attack_controller != null:
		attack_controller.reset_for_new_game()
	if auto_dish_controller != null:
		auto_dish_controller.reset_for_new_game()


func restore_shield_for_wave() -> void:
	var was_not_full := current_shield < prototype_max_shield
	current_shield = prototype_max_shield
	time_since_last_damage = shield_regen_delay
	shield_was_regenerating = false
	shield_changed.emit(current_shield, prototype_max_shield)
	if was_not_full:
		shield_feedback.emit(&"full")


func restore_shield(amount: float) -> float:
	if amount <= 0.0 or current_shield >= prototype_max_shield:
		return 0.0
	var before := current_shield
	current_shield = minf(prototype_max_shield, current_shield + amount)
	shield_changed.emit(current_shield, prototype_max_shield)
	if current_shield >= prototype_max_shield:
		shield_feedback.emit(&"full")
	return current_shield - before


func heal_health(amount: float) -> float:
	if amount <= 0.0 or is_defeated:
		return 0.0
	var before := current_health
	current_health = minf(prototype_max_health, current_health + amount)
	if current_health != before:
		health_changed.emit(current_health, prototype_max_health)
	return current_health - before


func receive_direct_health_burn(amount: float) -> float:
	# Prototype 0.6B porridge exception only: bypass shield/crispy rice and never
	# defeat the player. Do not reuse this as a general damage path.
	if amount <= 0.0 or is_defeated:
		return 0.0
	var before := current_health
	current_health = maxf(1.0, current_health - amount)
	health_changed.emit(current_health, prototype_max_health)
	hit_flash_left = maxf(hit_flash_left, 0.12)
	return before - current_health


func _start_secondary_use() -> void:
	var item := held_item
	if item == null or item.data == null:
		notify_feedback("当前没有可使用物品")
		return
	if item.data.item_type in [ItemData.ItemType.RICE_BAG, ItemData.ItemType.SMALL_RICE_BAG]:
		_take_one_rice_from_bag(item)
		return
	if current_health >= prototype_max_health:
		notify_feedback("生命已满，不能开始进食")
		return
	var combat := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat == null:
		return
	if item.data.item_type in [
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE,
		ItemData.ItemType.PLATED_RICE_PORRIDGE,
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE,
		ItemData.ItemType.PLATED_GREENS_PORRIDGE,
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE,
		ItemData.ItemType.PLATED_BEEF_PORRIDGE,
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE,
		ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE,
		ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE,
		ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE,
	]:
		_begin_consumption(item, 1, item.data.healing_per_use, maxf(0.05, item.data.use_duration), true, combat.config)
		return
	if not combat.config.emergency_eating_enabled or not item.data.emergency_edible or item.data.is_weird_dish():
		notify_feedback("该物品不能使用通用应急进食")
		return
	var requested_cost := maxi(1, ceili(float(item.data.max_durability) * combat.config.emergency_durability_ratio))
	var paid_cost := mini(requested_cost, item.data.current_durability)
	if paid_cost <= 0:
		notify_feedback("料理耐久不足")
		return
	var scaled_heal := combat.config.emergency_heal * float(paid_cost) / float(requested_cost)
	_begin_consumption(item, paid_cost, scaled_heal, combat.config.emergency_use_time, false, combat.config)


func _take_one_rice_from_bag(bag: CarryableItem) -> bool:
	if bag.data.remaining_portions <= 0:
		notify_feedback("米袋已空")
		return false
	var raw_rice := ItemCatalog.create(ItemData.ItemType.RAW_RICE)
	if not can_receive_item_data(raw_rice):
		notify_feedback("快捷栏和背包均没有空间，米袋数量未扣除")
		return false
	if not receive_item_data(raw_rice):
		notify_feedback("生米收纳失败，米袋数量未扣除")
		return false
	bag.data.remaining_portions -= 1
	if bag.data.remaining_portions <= 0:
		var removed := inventory.take_selected_item()
		if removed != null:
			removed.queue_free()
		notify_feedback("取出最后一份生米：空米袋已消失")
	else:
		bag.refresh_visual()
		inventory.notify_item_changed()
		notify_feedback("取出 1 份生米；米袋剩余 %d/%d" % [bag.data.remaining_portions, bag.data.max_remaining_portions])
	return true


func _begin_consumption(
	item: CarryableItem,
	durability_cost: int,
	total_heal: float,
	duration: float,
	is_porridge: bool,
	combat_config: PrototypeCombatConfig
) -> void:
	if item == null or item.data.current_durability < durability_cost or durability_cost <= 0:
		return
	_cancel_active_interaction()
	item.data.current_durability -= durability_cost
	item.data.mark_used()
	item.refresh_visual()
	inventory.notify_item_changed()
	is_consuming = true
	consuming_item = item
	consuming_elapsed = 0.0
	consuming_duration = maxf(0.05, duration)
	consuming_heal_total = maxf(0.0, total_heal)
	consuming_healed = 0.0
	consuming_is_porridge = is_porridge
	if is_porridge and item.data.is_hot():
		hot_burn_time_left = combat_config.rice_porridge_burn_duration
		hot_burn_damage_left += combat_config.rice_porridge_burn_damage
		notify_feedback("白粥仍然滚烫：饮用期间会受到烫伤")
	else:
		notify_feedback("开始饮用白粥" if is_porridge else "开始应急进食")
	_update_hold_progress_indicator()


func _update_consumption(delta: float) -> void:
	if not is_consuming:
		return
	if consuming_item == null or not is_instance_valid(consuming_item) or held_item != consuming_item:
		_cancel_consumption("料理状态变化，进食中断")
		return
	if not Input.is_action_pressed("secondary_use"):
		_cancel_consumption("主动停止进食")
		return
	var previous_ratio := clampf(consuming_elapsed / consuming_duration, 0.0, 1.0)
	consuming_elapsed = minf(consuming_duration, consuming_elapsed + delta)
	var current_ratio := clampf(consuming_elapsed / consuming_duration, 0.0, 1.0)
	var target_healed := consuming_heal_total * current_ratio
	var heal_delta := maxf(0.0, target_healed - consuming_healed)
	consuming_healed += heal_health(heal_delta)
	if current_ratio > previous_ratio:
		_update_hold_progress_indicator()
	if consuming_elapsed >= consuming_duration:
		_finish_consumption()


func _finish_consumption() -> void:
	if not is_consuming:
		return
	var item := consuming_item
	var healed := consuming_healed
	_clear_consumption_state()
	_apply_completed_porridge_effect(item)
	_resolve_consumed_dish(item)
	notify_feedback("饮用完成，恢复 %.1f 生命" % healed)


func _cancel_consumption(reason: String) -> void:
	if not is_consuming:
		return
	var item := consuming_item
	var healed := consuming_healed
	_clear_consumption_state()
	_resolve_consumed_dish(item)
	notify_feedback("%s；已恢复 %.1f，预扣耐久不返还" % [reason, healed])


func _clear_consumption_state() -> void:
	is_consuming = false
	consuming_item = null
	consuming_elapsed = 0.0
	consuming_duration = 0.0
	consuming_heal_total = 0.0
	consuming_healed = 0.0
	consuming_is_porridge = false
	_hide_hold_progress_indicator()


func _resolve_consumed_dish(item) -> void:
	# The inventory can be reset or the selected node can be destroyed on the
	# same frame that an active drink/eat action is cancelled. Keep this
	# boundary untyped so a previously freed Object can be rejected safely.
	if item == null or not is_instance_valid(item):
		return
	if item.data.current_durability > 0:
		if item != null and is_instance_valid(item):
			item.refresh_visual()
			inventory.notify_item_changed()
		return
	if item.data.carried_plate_state == ItemData.PlateState.CLEAN:
		item.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
		item.refresh_visual()
		inventory.notify_item_changed()
		return
	for slot_index in QuickInventory.SLOT_COUNT:
		if inventory.get_item(slot_index) == item:
			inventory.take_item(slot_index)
			item.queue_free()
			return


func _on_effective_damage_received() -> void:
	if is_consuming:
		_cancel_consumption("受到攻击，进食被打断")


func _update_hot_burn(delta: float) -> void:
	if hot_burn_time_left <= 0.0 or hot_burn_damage_left <= 0.0:
		return
	var step_time := minf(delta, hot_burn_time_left)
	var damage_step := hot_burn_damage_left * step_time / maxf(hot_burn_time_left, 0.001)
	hot_burn_time_left = maxf(0.0, hot_burn_time_left - step_time)
	hot_burn_damage_left = maxf(0.0, hot_burn_damage_left - damage_step)
	receive_direct_health_burn(damage_step)


func _update_healing_over_time(delta: float) -> void:
	if healing_over_time_left <= 0.0 or healing_over_time_rate <= 0.0:
		return
	var step := minf(delta, healing_over_time_left)
	healing_over_time_left = maxf(0.0, healing_over_time_left - step)
	heal_health(healing_over_time_rate * step)


func _update_boiled_greens(delta: float) -> void:
	boiled_greens_cooldown_left = maxf(0.0, boiled_greens_cooldown_left - delta)
	var dish := _get_first_carried_recipe(ExpandedRecipeCatalog.BOILED_GREENS)
	if dish == null:
		boiled_greens_inside.clear()
		return
	var radius := float(dish.data.effect_values.get("trigger_radius", 124.0))
	var current_inside: Dictionary = {}
	var entrants: Array[Node] = []
	for target in get_tree().get_nodes_in_group("damageable"):
		if target == self or not is_instance_valid(target) or not target.has_method("get_combat_faction"):
			continue
		if int(target.get_combat_faction()) != CombatRules.Faction.ENEMY:
			continue
		if global_position.distance_to(target.global_position) > radius:
			continue
		var target_id := target.get_instance_id()
		current_inside[target_id] = true
		if not boiled_greens_inside.has(target_id):
			entrants.append(target)
	boiled_greens_inside = current_inside
	if entrants.is_empty() or boiled_greens_cooldown_left > 0.0:
		return
	entrants.sort_custom(func(a: Node, b: Node) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	var targets: Array[Node] = entrants
	var final_perfect := dish.data.quality == ItemData.Quality.PERFECT and dish.data.current_durability == 1
	if not final_perfect:
		targets = [entrants[0]]
	for target in targets:
		var direction := global_position.direction_to(target.global_position)
		var heavy := target is HeavyTasteEnemy
		target.receive_combat_hit(
			0.0,
			CombatRules.Faction.PLAYER,
			direction,
			float(dish.data.effect_values.get("knockback", 105.0)) * (0.35 if heavy else 1.0),
			false,
			0.0 if heavy else 100.0
		)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	boiled_greens_cooldown_left = float(dish.data.effect_values.get("trigger_cooldown", 0.8))
	if dish.data.current_durability <= 0:
		_exhaust_carried_recipe(dish)
	else:
		dish.refresh_visual()
		inventory.notify_item_changed()
		if backpack != null:
			backpack.changed.emit()


func _get_first_carried_recipe(recipe: StringName) -> CarryableItem:
	for slot_index in QuickInventory.SLOT_COUNT:
		var item := inventory.get_item(slot_index)
		if item != null and item.data.recipe_id == recipe and item.data.current_durability > 0:
			return item
	if backpack != null:
		for placement in backpack.placements:
			var item := placement.item
			if item != null and item.data.recipe_id == recipe and item.data.current_durability > 0:
				return item
	return null


func _exhaust_carried_recipe(item: CarryableItem) -> void:
	if item.data.carried_plate_state == ItemData.PlateState.CLEAN:
		item.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
		item.refresh_visual()
		inventory.notify_item_changed()
		if backpack != null:
			backpack.changed.emit()
		return
	for slot_index in QuickInventory.SLOT_COUNT:
		if inventory.get_item(slot_index) == item:
			inventory.take_item(slot_index)
			item.queue_free()
			return
	if backpack != null and backpack.get_placement(item) != null:
		backpack.remove_item(item)
		item.queue_free()


func _apply_completed_porridge_effect(item) -> void:
	if item == null or not is_instance_valid(item) or item.data == null:
		return
	var recipe: StringName = item.data.recipe_id
	if recipe == ExpandedRecipeCatalog.GREENS_PORRIDGE:
		if item.data.quality == ItemData.Quality.PERFECT and item.data.current_durability <= 0:
			healing_over_time_rate = float(item.data.effect_values.get("perfect_hot_heal_per_second", 0.0))
			healing_over_time_left = float(item.data.effect_values.get("perfect_hot_heal_duration", 0.0))
			notify_feedback("完美青菜粥最后一份：获得短时持续恢复")
		return
	if recipe not in [
		ExpandedRecipeCatalog.BEEF_PORRIDGE,
		ExpandedRecipeCatalog.PLAIN_BEEF_PORRIDGE,
		ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE,
	]:
		return
	var bonus := float(item.data.effect_values.get("direct_bonus", 0.0))
	var duration := float(item.data.effect_values.get("direct_bonus_duration", 0.0))
	if recipe in [ExpandedRecipeCatalog.BEEF_PORRIDGE, ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE] and item.data.quality == ItemData.Quality.PERFECT and item.data.current_durability <= 0:
		bonus = float(item.data.effect_values.get("perfect_bonus", bonus))
		duration = float(item.data.effect_values.get("perfect_bonus_duration", duration))
		if recipe == ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE:
			healing_over_time_rate = float(item.data.effect_values.get("perfect_hot_heal_per_second", 0.0))
			healing_over_time_left = float(item.data.effect_values.get("perfect_hot_heal_duration", 0.0))
	var source_id := "porridge_%d" % item.data.source_recipe_instance_id
	combat_statuses.apply_status(CombatStatusController.StatusType.DIRECT_MELEE_BONUS, source_id, bonus, duration)
	combat_statuses.apply_status(CombatStatusController.StatusType.DIRECT_RANGED_BONUS, source_id, bonus, duration)


func _update_shield_regeneration(delta: float) -> void:
	if is_defeated or prototype_max_shield <= 0.0 or current_shield >= prototype_max_shield:
		shield_was_regenerating = false
		return
	time_since_last_damage += delta
	if time_since_last_damage < shield_regen_delay:
		return
	if not shield_was_regenerating:
		shield_was_regenerating = true
		shield_feedback.emit(&"regen_started")
	var before := current_shield
	current_shield = minf(prototype_max_shield, current_shield + shield_regen_per_second * delta)
	if current_shield != before:
		shield_changed.emit(current_shield, prototype_max_shield)
	if current_shield >= prototype_max_shield:
		shield_was_regenerating = false
		shield_feedback.emit(&"full")


func _configure_stamina(
	max_stamina: float,
	sprint_speed_multiplier: float,
	drain_per_second: float,
	regen_delay: float,
	regen_per_second: float
) -> void:
	prototype_max_stamina = maxf(1.0, max_stamina)
	prototype_sprint_speed_multiplier = maxf(1.0, sprint_speed_multiplier)
	prototype_sprint_drain_per_second = maxf(0.0, drain_per_second)
	prototype_stamina_regen_delay = maxf(0.0, regen_delay)
	prototype_stamina_regen_per_second = maxf(0.0, regen_per_second)
	current_stamina = prototype_max_stamina
	stamina_regen_delay_left = 0.0
	is_sprinting = false
	sprint_exhausted = false


func _update_stamina(delta: float, can_sprint: bool, sprint_requested: bool) -> bool:
	if is_defeated:
		is_sprinting = false
		return false
	if sprint_exhausted and not sprint_requested:
		sprint_exhausted = false
	var sprint_active := (
		can_sprint
		and sprint_requested
		and not sprint_exhausted
		and current_stamina > 0.0
	)
	var before := current_stamina
	if sprint_active:
		current_stamina = maxf(0.0, current_stamina - prototype_sprint_drain_per_second * delta)
		stamina_regen_delay_left = prototype_stamina_regen_delay
		if current_stamina <= 0.0:
			sprint_exhausted = true
	else:
		stamina_regen_delay_left = maxf(0.0, stamina_regen_delay_left - delta)
		if stamina_regen_delay_left <= 0.0 and current_stamina < prototype_max_stamina:
			current_stamina = minf(
				prototype_max_stamina,
				current_stamina + prototype_stamina_regen_per_second * delta
			)
	is_sprinting = sprint_active
	if not is_equal_approx(before, current_stamina):
		stamina_changed.emit(current_stamina, prototype_max_stamina)
	return sprint_active


func consume_stamina(amount: float) -> float:
	if amount <= 0.0 or current_stamina <= 0.0:
		return 0.0
	var before := current_stamina
	current_stamina = maxf(0.0, current_stamina - amount)
	stamina_regen_delay_left = prototype_stamina_regen_delay
	if current_stamina <= 0.0:
		sprint_exhausted = true
	stamina_changed.emit(current_stamina, prototype_max_stamina)
	return before - current_stamina


func restore_stamina(amount: float) -> float:
	if amount <= 0.0 or current_stamina >= prototype_max_stamina:
		return 0.0
	var before := current_stamina
	current_stamina = minf(prototype_max_stamina, current_stamina + amount)
	stamina_changed.emit(current_stamina, prototype_max_stamina)
	return current_stamina - before


func _apply_active_crispy_rice(raw_damage: float) -> float:
	var armor := get_active_crispy_rice()
	if armor == null:
		return raw_damage
	var reduced := maxf(1.0, raw_damage * (1.0 - clampf(armor.data.armor_reduction, 0.0, 0.95)))
	armor.data.current_durability -= 1
	armor.data.mark_used()
	armor.refresh_visual()
	inventory.notify_item_changed()
	if backpack != null:
		backpack.changed.emit()
	notify_feedback("锅巴减伤 %.0f%%，剩余耐久 %d/%d" % [armor.data.armor_reduction * 100.0, maxi(0, armor.data.current_durability), armor.data.max_durability])
	if armor.data.current_durability <= 0:
		_break_crispy_rice(armor)
	return reduced


func get_active_crispy_rice() -> CarryableItem:
	for slot_index in QuickInventory.SLOT_COUNT:
		var quick_item := inventory.get_item(slot_index)
		if _is_available_crispy_rice(quick_item):
			return quick_item
	if backpack == null:
		return null
	var ordered := backpack.placements.duplicate()
	ordered.sort_custom(func(a: GridInventory.Placement, b: GridInventory.Placement) -> bool:
		return a.origin.y < b.origin.y or (a.origin.y == b.origin.y and a.origin.x < b.origin.x)
	)
	for placement in ordered:
		if _is_available_crispy_rice(placement.item):
			return placement.item
	return null


func _is_available_crispy_rice(item: CarryableItem) -> bool:
	return (
		item != null
		and is_instance_valid(item)
		and item.data.item_type in [ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE]
		and item.data.current_durability > 0
	)


func _break_crispy_rice(item: CarryableItem) -> void:
	var combat := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat != null:
		combat.spawn_crispy_rice_trap(global_position, self)
	var plated := item.data.carried_plate_state == ItemData.PlateState.CLEAN
	if plated:
		item.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
		item.refresh_visual()
		inventory.notify_item_changed()
		if backpack != null:
			backpack.changed.emit()
	else:
		var removed := false
		for slot_index in QuickInventory.SLOT_COUNT:
			if inventory.get_item(slot_index) == item:
				inventory.take_item(slot_index)
				removed = true
				break
		if not removed and backpack != null and backpack.get_placement(item) != null:
			backpack.remove_item(item)
		item.queue_free()
	notify_feedback("锅巴破碎：已在脚下形成一次性锅巴碎陷阱")


func _finish_world_pickup(item: CarryableItem, accepted: bool) -> void:
	if not accepted or item == null or not item.is_loot_drop or item.loot_pickup_counted:
		return
	item.loot_pickup_counted = true
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null and stats.has_method("record_loot_picked_up"):
		stats.record_loot_picked_up(item.data)
	item.mark_loot_picked_up()


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
	held_anchor.position = facing_direction * 34.0
	if held_item != null and is_instance_valid(held_item):
		held_item.update_held_pose(facing_direction)


func _build_hold_progress_indicator() -> void:
	hold_progress_bar = ProgressBar.new()
	hold_progress_bar.name = "HoldInteractionProgress"
	hold_progress_bar.position = Vector2(-34.0, -72.0)
	hold_progress_bar.size = Vector2(68.0, 9.0)
	hold_progress_bar.min_value = 0.0
	hold_progress_bar.max_value = 100.0
	hold_progress_bar.value = 0.0
	hold_progress_bar.show_percentage = false
	hold_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold_progress_bar.z_index = 40
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.035, 0.045, 0.065, 0.92)
	background.border_color = Color(0.88, 0.92, 0.98, 0.9)
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffd166")
	fill.set_corner_radius_all(2)
	hold_progress_bar.add_theme_stylebox_override("background", background)
	hold_progress_bar.add_theme_stylebox_override("fill", fill)
	add_child(hold_progress_bar)
	hold_progress_bar.visible = false


func _update_hold_progress_indicator() -> void:
	if hold_progress_bar == null:
		return
	var should_show := (
		not modal_ui_open
		and not global_modal_overlay_open
		and (
			is_consuming
			or (
				active_interactable != null
				and is_instance_valid(active_interactable)
				and active_interactable.has_method("get_progress_ratio")
			)
		)
	)
	hold_progress_bar.visible = should_show
	if should_show:
		hold_progress_bar.value = (
			clampf(consuming_elapsed / maxf(consuming_duration, 0.001), 0.0, 1.0) * 100.0
			if is_consuming
			else get_active_interaction_progress_ratio() * 100.0
		)


func _hide_hold_progress_indicator() -> void:
	if hold_progress_bar == null:
		return
	hold_progress_bar.visible = false
	hold_progress_bar.value = 0.0
