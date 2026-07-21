class_name ItemData
extends Resource

enum ItemType {
	RAW_BEEF_CHUNK,
	RAW_STEAK,
	RAW_BEEF_SLICES,
	MARINATED_BEEF_SLICES,
	MARINADE,
	CHILI_SEGMENTS,
	COOKING_OIL,
	UNPLATED_STIR_FRY_BEEF,
	CHARCOAL,
	WOK,
	CLEAN_PLATE,
	DIRTY_PLATE,
	PLATED_STIR_FRY_BEEF,
	SALT,
	MUSTARD,
	PAN,
	SOUP_POT,
	TOMAHAWK_STEAK,
	PLATED_TOMAHAWK_STEAK,
	BIG_BONE,
	SHABU_BEEF,
	MUSHY_BOILED_BEEF,
}

enum ProcessingState {
	RAW,
	CUT_ONCE,
	SLICED,
	MARINATED,
	AUXILIARY,
	STIR_FRY_STAGE_ONE,
	READY_TO_PLATE,
	OVERCOOKED,
	CHARCOAL,
	WOK_CLEAN,
	WOK_OILED,
	WOK_STUCK,
	PLATED,
	PAN_CLEAN,
	PAN_OILED,
	PAN_STUCK,
	PAN_FIRST_SIDE,
	PAN_FLIP_WINDOW,
	PAN_SECOND_SIDE,
	SOUP_POT_EMPTY,
	SOUP_POT_WATER,
	SOUP_POT_BOILING,
	SOUP_COOKING,
	SOUP_READY,
}

enum PlateState {
	NONE,
	CLEAN,
	DIRTY,
}

enum StationType {
	CUTTING_BOARD,
	MARINATING,
	WOK,
	SINK,
	STOVE,
}

enum FailureTag {
	UNMARINATED,
	CHILI_TOO_EARLY,
	BURNT,
	FLIPPED_LATE,
	COLD_WATER_ENTRY,
	OVERBOILED,
}

enum ComponentType {
	CHILI_SEGMENTS,
}

enum ActiveModifier {
	SALTED,
	MUSTARD,
}

enum Quality {
	PERFECT,
	NORMAL,
	FLAWED,
	BAD,
}

enum AttackForm {
	NONE,
	MELEE,
	PROJECTILE,
	TRAP,
	DAMAGE_OVER_TIME,
}

enum CookingMethod {
	NONE,
	STIR_FRY,
	PAN_FRY,
	BOIL,
	DEEP_FRY,
}

var item_type: int = ItemType.RAW_BEEF_CHUNK
var display_name: String = ""
var processing_state: int = ProcessingState.RAW
var is_ingredient: bool = false
var is_auxiliary: bool = false
var is_cookware: bool = false
var allowed_stations: Array[int] = []
var failure_tags: Array[int] = []
var components: Array[int] = []
var active_modifiers: Array[int] = []
var quality: int = Quality.NORMAL
var is_stackable: bool = false
var stack_count: int = 1
var max_stack_count: int = 1
var can_be_plated: bool = false
var is_combat_dish: bool = false
var current_durability: int = 0
var max_durability: int = 0
var base_damage: float = 0.0
var actual_damage: float = 0.0
var has_perfect_finisher: bool = false
var carried_plate_state: int = PlateState.NONE
var poison_damage: float = 0.0
var poison_interval: float = 0.0
var poison_duration: float = 0.0
var poison_refresh_duration: bool = true
var has_been_used: bool = false
var remaining_portions: int = 1
var attack_count: int = 0
var next_sneeze_attack: int = 0
var bone_thrown: bool = false
var attack_form: int = AttackForm.NONE
var cooking_method: int = CookingMethod.NONE
var stagger_power: float = 0.0


func can_process_at(station_type: int) -> bool:
	return station_type in allowed_stations


func add_failure_tag(tag: int) -> void:
	if tag not in failure_tags:
		failure_tags.append(tag)
	recalculate_quality()


func has_failure_tag(tag: int) -> bool:
	return tag in failure_tags


func add_component(component: int) -> void:
	if component not in components:
		components.append(component)


func has_component(component: int) -> bool:
	return component in components


func add_active_modifier(modifier: int) -> void:
	if modifier not in active_modifiers:
		active_modifiers.append(modifier)


func has_active_modifier(modifier: int) -> bool:
	return modifier in active_modifiers


func is_weird_dish() -> bool:
	return has_active_modifier(ActiveModifier.MUSTARD)


func get_active_modifiers_text() -> String:
	if active_modifiers.is_empty():
		return "无"
	var labels: PackedStringArray = []
	for modifier in active_modifiers:
		labels.append(get_active_modifier_text(modifier))
	return "、".join(labels)


func recalculate_quality() -> void:
	if failure_tags.is_empty():
		quality = Quality.NORMAL
	elif failure_tags.size() == 1:
		quality = Quality.FLAWED
	else:
		quality = Quality.BAD


func can_stack_with(other: ItemData) -> bool:
	return (
		other != null
		and is_stackable
		and other.is_stackable
		and item_type == other.item_type
		and failure_tags == other.failure_tags
		and active_modifiers == other.active_modifiers
		and quality == other.quality
		and stack_count < max_stack_count
	)


func is_eligible_for_plating() -> bool:
	return can_be_plated and not has_been_used and max_durability > 0 and current_durability == max_durability


func mark_used() -> void:
	has_been_used = true


func add_to_stack(amount: int) -> int:
	if not is_stackable or amount <= 0:
		return 0
	var accepted := mini(amount, max_stack_count - stack_count)
	stack_count += accepted
	return accepted


func consume_stack_unit() -> bool:
	if stack_count <= 0:
		return false
	stack_count -= 1
	return true


func get_failure_tags_text() -> String:
	if failure_tags.is_empty():
		return "无"
	var labels: PackedStringArray = []
	for tag in failure_tags:
		labels.append(get_failure_tag_text(tag))
	return " ".join(labels)


func get_quality_text() -> String:
	match quality:
		Quality.PERFECT:
			return "完美"
		Quality.NORMAL:
			return "正常"
		Quality.FLAWED:
			return "瑕疵"
		Quality.BAD:
			return "糟糕"
	return "未知"


static func get_failure_tag_text(tag: int) -> String:
	match tag:
		FailureTag.UNMARINATED:
			return "【未腌制·临时标签】"
		FailureTag.CHILI_TOO_EARLY:
			return "【辣椒过早·临时标签】"
		FailureTag.BURNT:
			return "【焦糊】"
		FailureTag.FLIPPED_LATE:
			return "【翻面过晚】"
		FailureTag.COLD_WATER_ENTRY:
			return "【冷水下锅】"
		FailureTag.OVERBOILED:
			return "【煮老】"
	return "【未知标签】"


static func get_active_modifier_text(modifier: int) -> String:
	match modifier:
		ActiveModifier.SALTED:
			return "盐"
		ActiveModifier.MUSTARD:
			return "芥末"
	return "未知改造"
