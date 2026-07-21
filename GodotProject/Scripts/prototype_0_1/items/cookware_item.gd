class_name CookwareItem
extends CarryableItem

enum CookwareKind { WOK, PAN, SOUP_POT }

var cookware_kind: int = CookwareKind.WOK
var origin_station_id: StringName


func is_stuck() -> bool:
	return false


func clean_after_washing() -> void:
	pass


func interrupt_current_stage() -> void:
	pass


func get_cookware_name() -> String:
	match cookware_kind:
		CookwareKind.WOK:
			return "炒锅"
		CookwareKind.PAN:
			return "煎锅"
		CookwareKind.SOUP_POT:
			return "汤锅"
	return "锅具"
