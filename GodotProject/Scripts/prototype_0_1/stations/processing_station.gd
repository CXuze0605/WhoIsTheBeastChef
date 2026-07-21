class_name ProcessingStation
extends Interactable

@export var prototype_processing_time: float = 1.0

var hold_progress := HoldProgress.new()


func cancel_processing(player: Node, message: String) -> void:
	if hold_progress.active:
		hold_progress.cancel()
		player.notify_feedback(message)


func get_progress_ratio() -> float:
	return hold_progress.get_ratio()
