class_name HoldProgress
extends RefCounted

var duration: float = 1.0
var elapsed: float = 0.0
var active: bool = false


func begin(new_duration: float) -> void:
	duration = maxf(new_duration, 0.01)
	elapsed = 0.0
	active = true


func advance(delta: float) -> bool:
	if not active:
		return false
	elapsed += delta
	if elapsed >= duration:
		active = false
		elapsed = 0.0
		return true
	return false


func cancel() -> void:
	active = false
	elapsed = 0.0


func get_ratio() -> float:
	if not active:
		return 0.0
	return clampf(elapsed / duration, 0.0, 1.0)
