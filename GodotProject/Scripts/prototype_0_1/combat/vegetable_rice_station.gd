class_name VegetableRiceStation
extends ProcessingStation

var dish_data: ItemData
var interaction_mode: StringName = &""


func setup(data: ItemData) -> void:
	dish_data = data
	dish_data.deployment_state = ItemData.DeploymentState.DEPLOYED
	display_title = _station_title()
	placeholder_size = Vector2(118.0, 74.0)
	placeholder_color = Color("91b66d")


func _ready() -> void:
	super._ready()
	add_to_group("run_deployable")
	add_to_group("vegetable_rice_station")
	_refresh()


func get_primary_prompt(player: Node) -> String:
	if dish_data == null:
		return ""
	if _is_braised_station():
		return "[按住 %s] 吃一口%s（剩余 %d）" % [
			InputPrompt.action_text(&"interact_primary", "E"),
			_station_title(),
			dish_data.current_durability,
		]
	if player is PrototypePlayer and (player as PrototypePlayer).current_shield < (player as PrototypePlayer).prototype_max_shield:
		return "[按住 %s] 吃一口菜饭恢复护盾（剩余 %d）" % [
			InputPrompt.action_text(&"interact_primary", "E"),
			dish_data.current_durability,
		]
	return "[按住 %s] 收回菜饭（护盾已满）" % InputPrompt.action_text(&"interact_primary", "E")


func begin_primary_interaction(player: Node) -> bool:
	if dish_data == null:
		return false
	var can_eat_base := (
		player is PrototypePlayer
		and (player as PrototypePlayer).current_shield < (player as PrototypePlayer).prototype_max_shield
	)
	if _is_braised_station() or can_eat_base:
		interaction_mode = &"eat"
		hold_progress.begin(float(dish_data.effect_values.get("bite_time", 0.85)))
	else:
		interaction_mode = &"pickup"
		hold_progress.begin(1.1)
	return true


func update_primary_interaction(player: Node, delta: float) -> bool:
	if not hold_progress.advance(delta):
		return true
	if interaction_mode == &"eat":
		_complete_bite(player as PrototypePlayer)
	else:
		_complete_pickup(player as PrototypePlayer)
	return false


func cancel_primary_interaction(player: Node) -> void:
	if hold_progress.active:
		hold_progress.cancel()
		player.notify_feedback("%s交互取消：未消耗耐久" % _station_title())
	interaction_mode = &""


func blocks_movement_during_primary() -> bool:
	return false


func _complete_bite(player: PrototypePlayer) -> void:
	if player == null or dish_data == null:
		return
	if not _is_braised_station() and player.current_shield >= player.prototype_max_shield:
		return
	var final_bite := dish_data.current_durability == 1
	var perfect_final := final_bite and dish_data.quality == ItemData.Quality.PERFECT
	var shield_amount := float(dish_data.effect_values.get("shield_per_bite", 0.0))
	if perfect_final:
		shield_amount = float(dish_data.effect_values.get("perfect_shield", shield_amount))
	var restored := player.restore_shield(shield_amount) if shield_amount > 0.0 else 0.0
	var bonus := float(dish_data.effect_values.get("direct_bonus", 0.0))
	var bonus_duration := float(dish_data.effect_values.get("direct_bonus_duration", 0.0))
	if perfect_final:
		bonus = float(dish_data.effect_values.get("perfect_bonus", bonus))
		bonus_duration = float(dish_data.effect_values.get("perfect_bonus_duration", bonus_duration))
	if bonus > 0.0:
		var source_id := "shared_meal_%d" % dish_data.source_recipe_instance_id
		player.combat_statuses.apply_status(
			CombatStatusController.StatusType.DIRECT_MELEE_BONUS,
			source_id,
			bonus,
			bonus_duration
		)
		player.combat_statuses.apply_status(
			CombatStatusController.StatusType.DIRECT_RANGED_BONUS,
			source_id,
			bonus,
			bonus_duration
		)
	if perfect_final:
		var reduction := float(dish_data.effect_values.get(
			"perfect_reduction",
			dish_data.effect_values.get("final_reduction", 0.0)
		))
		if reduction > 0.0:
			player.combat_statuses.apply_status(
				CombatStatusController.StatusType.DAMAGE_REDUCTION,
				"shared_meal_reduction_%d" % dish_data.source_recipe_instance_id,
				reduction,
				float(dish_data.effect_values.get(
					"perfect_reduction_duration",
					dish_data.effect_values.get("final_reduction_duration", 0.0)
				))
			)
	dish_data.current_durability -= 1
	dish_data.mark_used()
	if dish_data.current_durability <= 0:
		_exhaust()
	else:
		_refresh()
		player.notify_feedback("%s：护盾 +%.1f，本体伤害 +%.0f%%，剩余 %d 口" % [
			_station_title(),
			restored,
			bonus * 100.0,
			dish_data.current_durability,
		])


func _complete_pickup(player: PrototypePlayer) -> void:
	if player == null:
		return
	var pickup_data := ItemCatalog.duplicate_data(dish_data)
	pickup_data.deployment_state = ItemData.DeploymentState.NONE
	if not player.receive_item_data(pickup_data):
		player.notify_feedback("快捷栏和背包没有空间，料理仍留在地面")
		return
	player.notify_feedback("已收回%s，品质和剩余耐久保留" % _station_title())
	queue_free()


func _exhaust() -> void:
	if dish_data.carried_plate_state == ItemData.PlateState.CLEAN:
		var plate := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.DIRTY_PLATE))
		get_tree().current_scene.add_child(plate)
		plate.global_position = global_position
	queue_free()


func _refresh() -> void:
	if placeholder == null or dish_data == null:
		return
	placeholder.set_title(_station_title())
	if _is_braised_station():
		placeholder.set_status("共享耐久 %d/%d · 每口本体伤害 +%.0f%% · 护盾 +%.0f" % [
			dish_data.current_durability,
			dish_data.max_durability,
			float(dish_data.effect_values.get("direct_bonus", 0.0)) * 100.0,
			float(dish_data.effect_values.get("shield_per_bite", 0.0)),
		])
	else:
		placeholder.set_status("共享耐久 %d/%d · 每口护盾 +%.0f" % [
			dish_data.current_durability,
			dish_data.max_durability,
			float(dish_data.effect_values.get("shield_per_bite", 0.0)),
		])


func _station_title() -> String:
	if dish_data == null:
		return "共享进食点"
	match StringName(dish_data.effect_values.get("station_kind", &"")):
		&"beef_braised":
			return "牛肉焖饭共享进食点"
		&"greens_beef_braised":
			return "青菜牛肉焖饭共享进食点"
	return "菜饭护盾补给点"


func _is_braised_station() -> bool:
	return dish_data != null and StringName(dish_data.effect_values.get("station_kind", &"")) in [
		&"beef_braised",
		&"greens_beef_braised",
	]
