class_name DishAttackController
extends Node

enum SneezePhase {
	NONE,
	WARNING,
	OFFSET,
	RECOVERY,
}

var player: PrototypePlayer
var combat_manager: CombatManager
var cooldown_left: float = 0.0
var attack_buffer_left: float = 0.0
var mustard_attack_active: bool = false
var aim_time: float = 0.0
var current_sway_angle: float = 0.0
var current_sneeze_offset: float = 0.0
var sneeze_target_offset: float = 0.0
var sneeze_check_left: float = 0.0
var sneeze_phase: int = SneezePhase.NONE
var sneeze_phase_left: float = 0.0
var sneeze_warning_count: int = 0
var random := RandomNumberGenerator.new()
var aim_line: Line2D
var active_soup_stream: HeldSoupStream
var active_soup_item: CarryableItem


func _ready() -> void:
	player = get_parent() as PrototypePlayer
	random.randomize()
	_build_aim_indicator()
	call_deferred("_find_combat_manager")


func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	attack_buffer_left = maxf(0.0, attack_buffer_left - delta)
	var can_attack := player != null and not player.modal_ui_open and not player.action_qte_locked and player.action_stun_left <= 0.0 and not player.is_consuming
	var dish := player.held_item if player != null else null
	var held_soup_selected := (
		dish != null
		and dish.data.recipe_id in [ExpandedRecipeCatalog.GREENS_SOUP, ExpandedRecipeCatalog.BEEF_SOUP]
	)
	if active_soup_stream != null and (
		not is_instance_valid(active_soup_stream)
		or not can_attack
		or not Input.is_action_pressed("dish_attack")
		or dish != active_soup_item
	):
		_stop_soup_stream()
	if held_soup_selected:
		attack_buffer_left = 0.0
		_update_mustard_aim(delta, false)
		_update_aim_indicator()
		if can_attack and Input.is_action_pressed("dish_attack") and dish.data.current_durability > 0:
			if active_soup_stream == null:
				_start_soup_stream(dish)
			elif is_instance_valid(active_soup_stream):
				active_soup_stream.update_direction(get_current_aim_direction())
		return
	var melee_or_bone := dish != null and (dish.data.attack_form == ItemData.AttackForm.MELEE or dish.data.item_type == ItemData.ItemType.BIG_BONE)
	if melee_or_bone and can_attack and Input.is_action_just_pressed("dish_attack"):
		var buffer_duration := combat_manager.config.tomahawk_input_buffer_time if combat_manager != null else 0.16
		attack_buffer_left = maxf(attack_buffer_left, buffer_duration)
	elif not melee_or_bone:
		attack_buffer_left = 0.0
	var attack_pressed := can_attack and (attack_buffer_left > 0.0 if melee_or_bone else Input.is_action_pressed("dish_attack"))
	var mustard_selected := (
		attack_pressed
		and dish != null
		and dish.data.is_combat_dish
		and dish.data.cooking_method == ItemData.CookingMethod.STIR_FRY
		and dish.data.current_durability > 0
		and dish.data.has_active_modifier(ItemData.ActiveModifier.MUSTARD)
	)
	_update_mustard_aim(delta, mustard_selected)
	_update_aim_indicator()
	if attack_pressed and cooldown_left <= 0.0:
		if fire_once():
			attack_buffer_left = 0.0


func fire_once(forced_direction: Vector2 = Vector2.ZERO) -> bool:
	if player == null or player.modal_ui_open or player.action_qte_locked or player.action_stun_left > 0.0:
		return false
	if combat_manager == null:
		_find_combat_manager()
	if combat_manager == null:
		player.notify_feedback("战斗运行节点未就绪")
		return false
	var dish := player.held_item
	if dish == null or not dish.data.is_combat_dish:
		return false
	if dish.data.attack_form == ItemData.AttackForm.NONE:
		return false
	var attack_direction := forced_direction.normalized() if not forced_direction.is_zero_approx() else get_current_aim_direction()
	if dish.data.item_type == ItemData.ItemType.BIG_BONE:
		return _throw_big_bone(dish, attack_direction)
	if dish.data.current_durability <= 0:
		return false
	if dish.data.recipe_id == ExpandedRecipeCatalog.BEEF_GREENS:
		return _swing_beef_greens(dish, attack_direction)
	if dish.data.recipe_id == ExpandedRecipeCatalog.FRIED_WHITE_RICE:
		return _fire_fried_white_rice(dish)
	if dish.data.recipe_id == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF:
		return _swing_clear_beef(dish, attack_direction)
	if dish.data.recipe_id == ExpandedRecipeCatalog.SPICY_FRIED_RICE:
		return _fire_spicy_fried_rice(dish)
	if dish.data.recipe_id == ExpandedRecipeCatalog.SPICY_BEEF_GREENS:
		return _swing_spicy_beef_greens(dish, attack_direction)
	if dish.data.recipe_id in [ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE, ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE]:
		return _throw_spicy_fried_rice(dish, attack_direction)
	if dish.data.recipe_id in [ExpandedRecipeCatalog.SPICY_BEEF_SOUP, ExpandedRecipeCatalog.SPICY_BEEF_GREENS_SOUP]:
		return false
	if dish.data.recipe_id in [
		ExpandedRecipeCatalog.PAN_FRIED_RICE_CAKE,
		ExpandedRecipeCatalog.GREENS_RICE_CAKE,
		ExpandedRecipeCatalog.BEEF_RICE_CAKE,
		ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE,
	]:
		return _use_rice_cake(dish, attack_direction)
	if dish.data.recipe_id in [
		ExpandedRecipeCatalog.GREENS_FRIED_RICE,
		ExpandedRecipeCatalog.BEEF_FRIED_RICE,
		ExpandedRecipeCatalog.MIXED_FRIED_RICE,
	]:
		return _throw_fried_rice(dish, attack_direction)
	if dish.data.recipe_id == ExpandedRecipeCatalog.MUSTARD_GREENS:
		return _throw_mustard_greens(dish, attack_direction)
	if dish.data.attack_form == ItemData.AttackForm.MELEE:
		return _swing_tomahawk(dish, attack_direction)
	if dish.data.item_type in [ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE]:
		return _throw_rice_ball(dish, attack_direction)
	if dish.data.recipe_id in [
		ExpandedRecipeCatalog.STIR_FRY_GREENS,
		ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS,
		ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
	]:
		return _throw_greens_leaf(dish, attack_direction)
	var is_perfect_finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	var was_unused := not dish.data.has_been_used
	if is_perfect_finisher:
		combat_manager.spawn_raging_bull(player.global_position + attack_direction * 72.0, attack_direction)
	else:
		var on_hit_effect := combat_manager.config.create_on_hit_effect(dish.data)
		combat_manager.spawn_normal_bull(player.global_position + attack_direction * 58.0, attack_direction, dish.data.actual_damage, on_hit_effect, player, dish.data)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.attack_interval
	if dish.data.current_durability <= 0:
		if dish.data.carried_plate_state == ItemData.PlateState.NONE:
			_remove_unplated_dish(dish)
			player.notify_feedback("未摆盘小炒耗尽：料理直接消失，不产生脏盘")
		else:
			_convert_dish_to_dirty_plate(dish)
			player.notify_feedback("料理耗尽：%s" % ("释放大型暴怒公牛并留下脏盘子" if is_perfect_finisher else "留下脏盘子"))
	else:
		dish.refresh_visual()
		player.inventory.notify_item_changed()
		if was_unused and dish.data.item_type == ItemData.ItemType.UNPLATED_STIR_FRY_BEEF:
			player.notify_feedback("未摆盘小炒已使用：永久失去摆盘资格")
	return true


func _fire_fried_white_rice(dish: CarryableItem) -> bool:
	combat_manager.spawn_fried_white_rice_ring(player.global_position, dish.data, player)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.fried_white_rice_attack_interval
	_resolve_expanded_durability(dish)
	return true


func _fire_spicy_fried_rice(dish: CarryableItem) -> bool:
	var finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	combat_manager.spawn_spicy_fried_rice_ring(player.global_position, dish.data, player, finisher)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = float(dish.data.effect_values.get("interval", combat_manager.config.spicy_fried_rice_interval))
	_resolve_expanded_durability(dish)
	return true


func _swing_spicy_beef_greens(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	combat_manager.spawn_spicy_beef_attack(player.global_position, attack_direction, dish.data, player, finisher)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = float(dish.data.effect_values.get("interval", combat_manager.config.spicy_beef_greens_interval))
	_resolve_expanded_durability(dish)
	return true


func _throw_spicy_fried_rice(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var mode := FriedRiceProjectile.Mode.SPICY_BEEF_SINGLE
	if dish.data.recipe_id == ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE:
		mode = FriedRiceProjectile.Mode.SPICY_MIXED
	var finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	var target_position := player.global_position + attack_direction * float(dish.data.effect_values.get("range", combat_manager.config.fried_rice_throw_range))
	if finisher and dish.data.recipe_id == ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE:
		var priority_target := _highest_health_enemy_in_aim(attack_direction, combat_manager.config.fried_rice_throw_range)
		if priority_target != null:
			target_position = priority_target.global_position
	else:
		var mouse_offset := player.get_global_mouse_position() - player.global_position
		var target_distance := minf(mouse_offset.length(), combat_manager.config.fried_rice_throw_range)
		if target_distance >= 40.0:
			target_position = player.global_position + attack_direction * target_distance
	combat_manager.spawn_fried_rice(player.global_position + attack_direction * 28.0, target_position, dish.data, player, mode, finisher)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = float(dish.data.effect_values.get("interval", combat_manager.config.fried_rice_attack_interval))
	_resolve_expanded_durability(dish)
	return true


func _highest_health_enemy_in_aim(direction: Vector2, max_range: float) -> Node2D:
	var best: Node2D
	var best_health := -INF
	for target in get_tree().get_nodes_in_group("damageable"):
		if not target is Node2D or not target.has_method("get_combat_faction") or int(target.get_combat_faction()) != CombatRules.Faction.ENEMY:
			continue
		var offset: Vector2 = target.global_position - player.global_position
		if offset.length() > max_range or absf(direction.angle_to(offset.normalized())) > deg_to_rad(38.0):
			continue
		var health := float(target.get("current_health")) if "current_health" in target else 1.0
		if health > best_health:
			best = target
			best_health = health
	return best


func _use_rice_cake(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var mode := RiceCakeCombatEntity.Mode.BOOMERANG
	if dish.data.recipe_id == ExpandedRecipeCatalog.GREENS_RICE_CAKE:
		mode = RiceCakeCombatEntity.Mode.GREENS_ORBIT
	elif dish.data.recipe_id == ExpandedRecipeCatalog.BEEF_RICE_CAKE:
		mode = RiceCakeCombatEntity.Mode.BEEF_BOUNCE
	elif dish.data.recipe_id == ExpandedRecipeCatalog.GREENS_BEEF_RICE_CAKE:
		mode = RiceCakeCombatEntity.Mode.MIXED_ORBIT
	combat_manager.spawn_rice_cake(mode, player, dish.data, attack_direction)
	dish.data.mark_used()
	cooldown_left = float(dish.data.effect_values.get("interval", 0.7))
	if mode == RiceCakeCombatEntity.Mode.BOOMERANG:
		dish.data.current_durability -= 1
		_resolve_expanded_durability(dish)
	else:
		if dish.data.carried_plate_state == ItemData.PlateState.CLEAN:
			_convert_dish_to_dirty_plate(dish)
		else:
			_remove_unplated_dish(dish)
	return true


func _swing_clear_beef(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var finisher := (
		dish.data.quality == ItemData.Quality.PERFECT
		and dish.data.has_perfect_finisher
		and dish.data.current_durability == 1
	)
	combat_manager.spawn_clear_beef_combo(player.global_position, attack_direction, dish.data, player, finisher)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.clear_beef_attack_interval
	_resolve_expanded_durability(dish)
	return true


func _start_soup_stream(dish: CarryableItem) -> void:
	var mode := HeldSoupStream.Mode.GREENS if dish.data.recipe_id == ExpandedRecipeCatalog.GREENS_SOUP else HeldSoupStream.Mode.BEEF
	active_soup_item = dish
	active_soup_stream = combat_manager.spawn_held_soup_stream(player, dish, mode)
	active_soup_stream.durability_spent.connect(_on_soup_durability_spent)
	active_soup_stream.update_direction(get_current_aim_direction())
	if player.combat_statuses != null:
		player.combat_statuses.apply_status(
			CombatStatusController.StatusType.MOVE_SLOW,
			active_soup_stream.get_instance_id(),
			float(dish.data.effect_values.get("move_slow", 0.0)),
			0.0,
			true
		)


func _on_soup_durability_spent() -> void:
	if active_soup_item == null or not is_instance_valid(active_soup_item):
		_stop_soup_stream()
		return
	var dish := active_soup_item
	dish.data.current_durability -= 1
	dish.data.mark_used()
	if dish.data.current_durability <= 0:
		_stop_soup_stream()
		_resolve_expanded_durability(dish)
	else:
		dish.refresh_visual()
		player.inventory.notify_item_changed()


func _stop_soup_stream() -> void:
	if active_soup_stream != null:
		var source_id := active_soup_stream.get_instance_id() if is_instance_valid(active_soup_stream) else 0
		if is_instance_valid(active_soup_stream):
			active_soup_stream.stop_stream()
		if player != null and player.combat_statuses != null and source_id != 0:
			player.combat_statuses.remove_source(source_id)
	active_soup_stream = null
	active_soup_item = null


func _throw_rice_ball(dish: CarryableItem, attack_direction: Vector2) -> bool:
	combat_manager.spawn_rice_ball(player.global_position + attack_direction * 42.0, attack_direction, dish.data.actual_damage, player, dish.data)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.white_rice_attack_interval
	if dish.data.current_durability <= 0:
		if dish.data.carried_plate_state == ItemData.PlateState.NONE:
			_remove_unplated_dish(dish)
			player.notify_feedback("未摆盘白米饭耗尽：直接消失")
		else:
			_convert_dish_to_dirty_plate(dish)
			player.notify_feedback("盘装白米饭耗尽：留下脏盘子")
	else:
		dish.refresh_visual()
		player.inventory.notify_item_changed()
		player.notify_feedback("投出饭团：单体、无穿透")
	return true


func _throw_greens_leaf(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var mode := GreensLeafProjectile.Mode.BOOMERANG
	if dish.data.recipe_id == ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS:
		mode = GreensLeafProjectile.Mode.SPICY_BOOMERANG
	elif dish.data.recipe_id == ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS:
		mode = GreensLeafProjectile.Mode.FLASH
	var is_finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	var callback := Callable()
	if is_finisher:
		callback = _resolve_greens_finisher.bind(dish.data)
	combat_manager.spawn_greens_leaf(
		player.global_position + attack_direction * 38.0,
		attack_direction,
		dish.data,
		player,
		mode,
		callback
	)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.greens_leaf_attack_interval
	if dish.data.current_durability <= 0:
		if dish.data.carried_plate_state == ItemData.PlateState.NONE:
			_remove_unplated_dish(dish)
		else:
			_convert_dish_to_dirty_plate(dish)
	else:
		dish.refresh_visual()
		player.inventory.notify_item_changed()
	return true


func _swing_beef_greens(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	combat_manager.spawn_beef_greens_swing(player.global_position, attack_direction, dish.data, player, finisher)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.beef_greens_attack_interval
	_resolve_expanded_durability(dish)
	return true


func _throw_fried_rice(dish: CarryableItem, attack_direction: Vector2) -> bool:
	var mode := FriedRiceProjectile.Mode.GREENS_AOE
	if dish.data.recipe_id == ExpandedRecipeCatalog.BEEF_FRIED_RICE:
		mode = FriedRiceProjectile.Mode.BEEF_SINGLE
	elif dish.data.recipe_id == ExpandedRecipeCatalog.MIXED_FRIED_RICE:
		mode = FriedRiceProjectile.Mode.MIXED
	var mouse_offset := player.get_global_mouse_position() - player.global_position
	var target_distance := minf(mouse_offset.length(), combat_manager.config.fried_rice_throw_range)
	if target_distance < 40.0:
		target_distance = combat_manager.config.fried_rice_throw_range * 0.55
	var target_position := player.global_position + attack_direction * target_distance
	var finisher := dish.data.has_perfect_finisher and dish.data.current_durability == 1
	combat_manager.spawn_fried_rice(player.global_position + attack_direction * 28.0, target_position, dish.data, player, mode, finisher)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.fried_rice_attack_interval
	_resolve_expanded_durability(dish)
	return true


func _throw_mustard_greens(dish: CarryableItem, attack_direction: Vector2) -> bool:
	combat_manager.spawn_mustard_greens_leaf(
		player.global_position + attack_direction * 36.0,
		attack_direction,
		dish,
		_resolve_mustard_greens_shot.bind(dish)
	)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.mustard_greens_attack_interval
	if dish.data.current_durability <= 0:
		dish.data.deployment_state = ItemData.DeploymentState.EFFECT_MAINTENANCE
	dish.refresh_visual()
	player.inventory.notify_item_changed()
	player.notify_feedback("发射芥末菜叶：命中本身不造成伤害")
	return true


func _resolve_mustard_greens_shot(target: Node, dish: CarryableItem) -> void:
	if dish == null or not is_instance_valid(dish) or dish.data.recipe_id != ExpandedRecipeCatalog.MUSTARD_GREENS:
		return
	var registered := false
	if target != null and player.auto_dish_controller != null:
		registered = player.auto_dish_controller.register_mustard_target(dish, target)
	if registered:
		player.notify_feedback("芥末青菜已标记目标：四重减益和移动影响圈生效")
	elif dish.data.current_durability <= 0 and dish.data.linked_target_ids.is_empty():
		_convert_dish_to_dirty_plate(dish)
		player.notify_feedback("最后一片芥末菜叶落空：残盘转为脏盘")


func _resolve_expanded_durability(dish: CarryableItem) -> void:
	if dish.data.current_durability <= 0:
		if dish.data.carried_plate_state == ItemData.PlateState.NONE:
			_remove_unplated_dish(dish)
		else:
			_convert_dish_to_dirty_plate(dish)
	else:
		dish.refresh_visual()
		player.inventory.notify_item_changed()


func _resolve_greens_finisher(origin: Vector2, source_data: ItemData) -> void:
	if source_data == null:
		return
	if source_data.recipe_id == ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS:
		for target in get_tree().get_nodes_in_group("damageable"):
			if not is_instance_valid(target) or not target.has_method("get_combat_faction"):
				continue
			if int(target.get_combat_faction()) != CombatRules.Faction.ENEMY:
				continue
			var statuses := CombatStatusController.ensure_on(target)
			if not statuses.has_status(CombatStatusController.StatusType.AIM_DISRUPTION):
				continue
			var context := DamageContext.new()
			context.source_entity = player
			context.source_dish = source_data
			context.source_type = DamageContext.SourceType.STATUS_TRIGGER
			context.attacker_faction = CombatRules.Faction.PLAYER
			context.target_faction = CombatRules.Faction.ENEMY
			context.base_damage = float(source_data.effect_values.get("finisher_damage", 0.0))
			context.allow_direct_attack_bonus = false
			target.receive_damage_context(context, Vector2.ZERO, 0.0, 0.0)
		return
	var radius := 96.0
	for target in get_tree().get_nodes_in_group("damageable"):
		if not is_instance_valid(target) or not target.has_method("get_combat_faction"):
			continue
		if int(target.get_combat_faction()) != CombatRules.Faction.ENEMY or origin.distance_to(target.global_position) > radius:
			continue
		var context := DamageContext.new()
		context.source_entity = player
		context.source_dish = source_data
		context.source_type = DamageContext.SourceType.PLAYER_DIRECT_RANGED
		context.attacker_faction = CombatRules.Faction.PLAYER
		context.target_faction = CombatRules.Faction.ENEMY
		context.base_damage = source_data.actual_damage
		context.allow_direct_attack_bonus = true
		target.receive_damage_context(context, target.global_position.direction_to(player.global_position), 0.0, 0.0)


func _swing_tomahawk(dish: CarryableItem, attack_direction: Vector2) -> bool:
	combat_manager.spawn_melee_swing(player.global_position + attack_direction * 26.0, attack_direction, dish.data, player)
	dish.data.current_durability -= 1
	dish.data.mark_used()
	cooldown_left = combat_manager.config.tomahawk_attack_interval
	_update_mustard_melee_sneeze(dish)
	if dish.data.current_durability <= 0:
		_finish_tomahawk(dish)
	else:
		dish.refresh_visual()
		player.inventory.notify_item_changed()
		player.notify_feedback("战斧挥砍已发动")
	return true


func _finish_tomahawk(dish: CarryableItem) -> void:
	if dish.data.item_type == ItemData.ItemType.TOMAHAWK_STEAK:
		var removed := player.inventory.take_selected_item()
		if removed != null:
			removed.queue_free()
		player.notify_feedback("未装盘战斧牛排耗尽：料理直接消失")
		return
	if dish.data.has_perfect_finisher and not dish.data.is_weird_dish():
		dish.data = ItemCatalog.create(ItemData.ItemType.BIG_BONE)
		dish.refresh_visual()
		player.inventory.notify_item_changed()
		player.notify_feedback("完美战斧牛排耗尽：大骨头保留在当前格")
	else:
		_convert_dish_to_dirty_plate(dish)
		player.notify_feedback("盘装战斧牛排耗尽：留下脏盘子")


func _throw_big_bone(dish: CarryableItem, attack_direction: Vector2) -> bool:
	if dish.data.bone_thrown:
		return false
	dish.data.bone_thrown = true
	dish.data.mark_used()
	combat_manager.spawn_big_bone(player.global_position + attack_direction * 44.0, attack_direction, _complete_big_bone.bind(dish))
	player.notify_feedback("大骨头已投掷；命中首个目标或飞出范围后留下脏盘子")
	return true


func _complete_big_bone(item: CarryableItem) -> void:
	if item == null or not is_instance_valid(item) or item.data.item_type != ItemData.ItemType.BIG_BONE:
		return
	item.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
	item.refresh_visual()
	player.inventory.notify_item_changed()


func _update_mustard_melee_sneeze(dish: CarryableItem) -> void:
	if not dish.data.has_active_modifier(ItemData.ActiveModifier.MUSTARD):
		return
	if dish.data.next_sneeze_attack <= 0:
		dish.data.next_sneeze_attack = random.randi_range(2, 3)
	dish.data.attack_count += 1
	if dish.data.attack_count < dish.data.next_sneeze_attack:
		return
	dish.data.attack_count = 0
	dish.data.next_sneeze_attack = random.randi_range(2, 3)
	player.apply_action_stun(combat_manager.config.mustard_melee_sneeze_stun, "芥末喷嚏！短暂无法移动和攻击")


func get_current_aim_direction() -> Vector2:
	var base_direction := _get_base_aim_direction()
	var smoke_offset := 0.0
	if player != null and player.combat_statuses != null and player.combat_statuses.has_status(CombatStatusController.StatusType.AIM_DISRUPTION):
		smoke_offset = deg_to_rad(combat_manager.config.choking_aim_degrees if combat_manager != null else 0.0) * sin(Time.get_ticks_msec() * 0.012)
	return base_direction.rotated(current_sway_angle + current_sneeze_offset + smoke_offset).normalized()


func get_aim_debug_text() -> String:
	if not mustard_attack_active:
		return "芥末瞄准：未启用"
	var phase_text := "平滑摆动"
	match sneeze_phase:
		SneezePhase.WARNING:
			phase_text = "喷嚏预警"
		SneezePhase.OFFSET:
			phase_text = "喷嚏偏移"
		SneezePhase.RECOVERY:
			phase_text = "快速恢复"
	return "芥末瞄准：%s / 摆动 %.1f° / 偏移 %.1f°" % [phase_text, rad_to_deg(current_sway_angle), rad_to_deg(current_sneeze_offset)]


func force_sneeze_warning_for_test(offset_degrees: float) -> void:
	if combat_manager == null:
		_find_combat_manager()
	sneeze_target_offset = deg_to_rad(offset_degrees)
	sneeze_phase = SneezePhase.WARNING
	sneeze_phase_left = combat_manager.config.mustard_sneeze_warning_time
	sneeze_warning_count += 1


func update_mustard_aim_for_test(delta: float, active: bool = true) -> void:
	_update_mustard_aim(delta, active)
	_update_aim_indicator()


func _update_mustard_aim(delta: float, active: bool) -> void:
	if combat_manager == null:
		_find_combat_manager()
	if not active or combat_manager == null:
		_reset_mustard_aim()
		return
	if not mustard_attack_active:
		mustard_attack_active = true
		sneeze_check_left = combat_manager.config.mustard_sneeze_check_interval
	aim_time += delta
	current_sway_angle = deg_to_rad(combat_manager.config.mustard_sway_amplitude_degrees) * sin(aim_time * TAU * combat_manager.config.mustard_sway_cycles_per_second)
	_update_sneeze_phase(delta)
	if sneeze_phase == SneezePhase.NONE:
		sneeze_check_left -= delta
		if sneeze_check_left <= 0.0:
			sneeze_check_left = combat_manager.config.mustard_sneeze_check_interval
			if random.randf() <= combat_manager.config.mustard_sneeze_chance:
				var magnitude := random.randf_range(combat_manager.config.mustard_sneeze_min_degrees, combat_manager.config.mustard_sneeze_max_degrees)
				force_sneeze_warning_for_test(magnitude * (-1.0 if random.randf() < 0.5 else 1.0))
	_apply_friendly_aim_influence(true)


func _update_sneeze_phase(delta: float) -> void:
	if sneeze_phase == SneezePhase.NONE:
		current_sneeze_offset = 0.0
		return
	sneeze_phase_left -= delta
	match sneeze_phase:
		SneezePhase.WARNING:
			current_sneeze_offset = 0.0
			if sneeze_phase_left <= 0.0:
				sneeze_phase = SneezePhase.OFFSET
				sneeze_phase_left = combat_manager.config.mustard_sneeze_hold_time
				current_sneeze_offset = sneeze_target_offset
		SneezePhase.OFFSET:
			current_sneeze_offset = sneeze_target_offset
			if sneeze_phase_left <= 0.0:
				sneeze_phase = SneezePhase.RECOVERY
				sneeze_phase_left = combat_manager.config.mustard_sneeze_recovery_time
		SneezePhase.RECOVERY:
			var ratio := clampf(sneeze_phase_left / maxf(combat_manager.config.mustard_sneeze_recovery_time, 0.01), 0.0, 1.0)
			current_sneeze_offset = sneeze_target_offset * ratio
			if sneeze_phase_left <= 0.0:
				sneeze_phase = SneezePhase.NONE
				current_sneeze_offset = 0.0
				sneeze_target_offset = 0.0


func _reset_mustard_aim() -> void:
	if mustard_attack_active:
		_apply_friendly_aim_influence(false)
	mustard_attack_active = false
	aim_time = 0.0
	current_sway_angle = 0.0
	current_sneeze_offset = 0.0
	sneeze_target_offset = 0.0
	sneeze_phase = SneezePhase.NONE
	sneeze_phase_left = 0.0
	sneeze_check_left = 0.0


func _apply_friendly_aim_influence(active: bool) -> void:
	if player == null or combat_manager == null:
		return
	for target in get_tree().get_nodes_in_group("aim_influence_receiver"):
		if not is_instance_valid(target) or not target.has_method("set_external_aim_influence"):
			continue
		var in_range := player.global_position.distance_to(target.global_position) <= combat_manager.config.mustard_ally_influence_radius
		target.set_external_aim_influence(get_instance_id(), current_sway_angle, current_sneeze_offset, active and in_range)


func _convert_dish_to_dirty_plate(dish: CarryableItem) -> void:
	dish.data = ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE)
	dish.refresh_visual()
	player.inventory.notify_item_changed()
	_reset_mustard_aim()


func _remove_unplated_dish(dish: CarryableItem) -> void:
	var selected := player.inventory.get_selected_item()
	if selected != dish:
		push_error("Unplated dish exhaustion lost its selected inventory reference")
		return
	var removed := player.inventory.take_selected_item()
	if removed != null:
		removed.queue_free()
	_reset_mustard_aim()


func reset_for_new_game() -> void:
	_stop_soup_stream()
	cooldown_left = 0.0
	attack_buffer_left = 0.0
	_reset_mustard_aim()


func _get_base_aim_direction() -> Vector2:
	var mouse_direction := player.get_global_mouse_position() - player.global_position
	return mouse_direction.normalized() if not mouse_direction.is_zero_approx() else player.facing_direction


func _find_combat_manager() -> void:
	combat_manager = get_tree().get_first_node_in_group("combat_runtime") as CombatManager


func _build_aim_indicator() -> void:
	aim_line = Line2D.new()
	aim_line.name = "PrototypeAimIndicator"
	aim_line.width = 4.0
	aim_line.default_color = Color("f4d35e")
	aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT * 96.0])
	aim_line.z_index = 15
	player.call_deferred("add_child", aim_line)


func _update_aim_indicator() -> void:
	if aim_line == null or not is_instance_valid(aim_line):
		return
	var direction := get_current_aim_direction() if player != null else Vector2.RIGHT
	aim_line.points = PackedVector2Array([Vector2.ZERO, direction * 96.0])
	aim_line.default_color = Color("d8a928") if mustard_attack_active else Color("8ecae6")
	aim_line.visible = mustard_attack_active
