class_name CombatStatusController
extends Node

enum StatusType {
	MOVE_SLOW,
	ATTACK_SPEED_SLOW,
	WEAKNESS,
	VULNERABILITY,
	AIM_DISRUPTION,
	DIRECT_MELEE_BONUS,
	DIRECT_RANGED_BONUS,
	DAMAGE_REDUCTION,
	CARRY_CURSE,
}

# status_type -> source_id -> { magnitude, remaining, persistent }
var sources: Dictionary = {}


func _process(delta: float) -> void:
	advance(delta)


func apply_status(
	status_type: int,
	source_id: Variant,
	magnitude: float,
	duration: float,
	persistent: bool = false
) -> void:
	var by_source: Dictionary = sources.get(status_type, {})
	by_source[source_id] = {
		"magnitude": maxf(0.0, magnitude),
		"remaining": maxf(0.0, duration),
		"persistent": persistent,
	}
	sources[status_type] = by_source


func remove_source(source_id: Variant) -> void:
	for status_type in sources.keys():
		var by_source: Dictionary = sources[status_type]
		by_source.erase(source_id)
		if by_source.is_empty():
			sources.erase(status_type)
		else:
			sources[status_type] = by_source


func clear_all() -> void:
	sources.clear()


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	for status_type in sources.keys():
		var by_source: Dictionary = sources[status_type]
		for source_id in by_source.keys():
			var runtime: Dictionary = by_source[source_id]
			if bool(runtime["persistent"]):
				continue
			runtime["remaining"] = maxf(0.0, float(runtime["remaining"]) - delta)
			if float(runtime["remaining"]) <= 0.0:
				by_source.erase(source_id)
			else:
				by_source[source_id] = runtime
		if by_source.is_empty():
			sources.erase(status_type)
		else:
			sources[status_type] = by_source


func has_status(status_type: int) -> bool:
	return sources.has(status_type) and not (sources[status_type] as Dictionary).is_empty()


func get_strongest(status_type: int) -> float:
	if not sources.has(status_type):
		return 0.0
	var strongest := 0.0
	for runtime in (sources[status_type] as Dictionary).values():
		strongest = maxf(strongest, float(runtime["magnitude"]))
	return strongest


func get_move_speed_multiplier() -> float:
	return maxf(0.05, 1.0 - get_strongest(StatusType.MOVE_SLOW))


func get_attack_speed_multiplier() -> float:
	return maxf(0.05, 1.0 - get_strongest(StatusType.ATTACK_SPEED_SLOW))


func get_outgoing_damage_multiplier(source_type: int, allow_direct_bonus: bool) -> float:
	var multiplier := maxf(0.05, 1.0 - get_strongest(StatusType.WEAKNESS))
	if not allow_direct_bonus:
		return multiplier
	if source_type == DamageContext.SourceType.PLAYER_DIRECT_MELEE:
		multiplier *= 1.0 + get_strongest(StatusType.DIRECT_MELEE_BONUS)
	elif source_type == DamageContext.SourceType.PLAYER_DIRECT_RANGED:
		multiplier *= 1.0 + get_strongest(StatusType.DIRECT_RANGED_BONUS)
	return multiplier


func get_incoming_damage_multiplier(use_vulnerability: bool, use_reduction: bool) -> float:
	var multiplier := 1.0
	if use_vulnerability:
		multiplier *= 1.0 + get_strongest(StatusType.VULNERABILITY)
	if use_reduction:
		multiplier *= maxf(0.05, 1.0 - get_strongest(StatusType.DAMAGE_REDUCTION))
	return multiplier


static func ensure_on(target: Node) -> CombatStatusController:
	if target == null:
		return null
	var existing := target.get_node_or_null("CombatStatusController") as CombatStatusController
	if existing != null:
		return existing
	var controller := CombatStatusController.new()
	controller.name = "CombatStatusController"
	target.add_child(controller)
	return controller

