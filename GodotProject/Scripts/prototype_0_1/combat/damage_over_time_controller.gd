class_name DamageOverTimeController
extends Node

var active_effects: Dictionary = {}
var total_tick_damage: float = 0.0
var total_ticks: int = 0


func _process(delta: float) -> void:
	advance_effects(delta)


func apply_effect(effect: StatusEffectData) -> bool:
	if effect == null or effect.damage_per_tick <= 0.0 or effect.duration <= 0.0:
		return false
	if active_effects.has(effect.effect_type):
		if not effect.refresh_duration:
			return false
		var existing: Dictionary = active_effects[effect.effect_type]
		existing["data"] = effect.copy_effect()
		existing["elapsed"] = 0.0
		existing["next_tick"] = maxf(effect.tick_interval, 0.01)
		active_effects[effect.effect_type] = existing
		return true
	active_effects[effect.effect_type] = {
		"data": effect.copy_effect(),
		"elapsed": 0.0,
		"next_tick": maxf(effect.tick_interval, 0.01),
	}
	return true


func advance_effects(delta: float) -> void:
	for effect_type in active_effects.keys():
		var runtime: Dictionary = active_effects[effect_type]
		var data := runtime["data"] as StatusEffectData
		var elapsed := minf(float(runtime["elapsed"]) + delta, data.duration)
		var next_tick := float(runtime["next_tick"])
		while next_tick <= elapsed + 0.0001:
			_deal_tick(data)
			next_tick += maxf(data.tick_interval, 0.01)
		runtime["elapsed"] = elapsed
		runtime["next_tick"] = next_tick
		if elapsed >= data.duration:
			active_effects.erase(effect_type)
		else:
			active_effects[effect_type] = runtime


func has_effect(effect_type: int) -> bool:
	return active_effects.has(effect_type)


func get_effects_text() -> String:
	if active_effects.is_empty():
		return "无"
	var labels: PackedStringArray = []
	for runtime in active_effects.values():
		labels.append((runtime["data"] as StatusEffectData).get_display_name())
	return "、".join(labels)


func _deal_tick(data: StatusEffectData) -> void:
	var receiver := get_parent()
	if receiver == null or not receiver.has_method("receive_status_damage"):
		return
	receiver.receive_status_damage(data.damage_per_tick, data.source_faction, data.effect_type)
	total_tick_damage += data.damage_per_tick
	total_ticks += 1
