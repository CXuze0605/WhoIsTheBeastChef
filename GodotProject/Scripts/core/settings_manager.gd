class_name GameSettingsManager
extends Node

signal settings_applied
signal settings_save_failed(error: int, path: String)
signal bindings_changed

const CONFIG_VERSION := 1
const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_VOLUME := 100.0
const SILENCE_DB := -80.0

const EDITABLE_ACTIONS: Array[StringName] = [
	&"move_up",
	&"move_down",
	&"move_left",
	&"move_right",
	&"interact_primary",
	&"interact_carry",
	&"interact_cookware",
	&"drop_item",
	&"plate_dish",
	&"dish_attack",
	&"secondary_use",
	&"season_dish",
	&"start_service",
	&"select_hotbar_1",
	&"select_hotbar_2",
	&"select_hotbar_3",
	&"select_hotbar_4",
	&"select_hotbar_5",
	&"toggle_backpack",
	&"rotate_inventory_item",
	&"place_trap",
	&"toggle_pause",
]

const ACTION_LABELS := {
	&"move_up": "向上移动",
	&"move_down": "向下移动",
	&"move_left": "向左移动",
	&"move_right": "向右移动",
	&"interact_primary": "主要交互",
	&"interact_carry": "搬取 / 次级交互",
	&"interact_cookware": "锅具交互",
	&"drop_item": "丢弃物品",
	&"plate_dish": "摆盘",
	&"dish_attack": "料理攻击",
	&"secondary_use": "次要使用",
	&"season_dish": "调味",
	&"start_service": "开始营业",
	&"select_hotbar_1": "快捷栏 1",
	&"select_hotbar_2": "快捷栏 2",
	&"select_hotbar_3": "快捷栏 3",
	&"select_hotbar_4": "快捷栏 4",
	&"select_hotbar_5": "快捷栏 5",
	&"toggle_backpack": "打开背包",
	&"rotate_inventory_item": "旋转背包物品",
	&"place_trap": "放置陷阱",
	&"toggle_pause": "暂停菜单",
}

var master_volume: float = DEFAULT_VOLUME
var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var settings_path_override: String = ""
var _default_bindings: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_capture_project_defaults()
	load_settings()


func get_action_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for action in EDITABLE_ACTIONS:
		definitions.append({
			"action": action,
			"label": String(ACTION_LABELS.get(action, String(action))),
		})
	return definitions


func get_snapshot() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"bindings": _capture_bindings_from_input_map(),
	}


func get_default_snapshot() -> Dictionary:
	return {
		"master_volume": DEFAULT_VOLUME,
		"music_volume": DEFAULT_VOLUME,
		"sfx_volume": DEFAULT_VOLUME,
		"bindings": _duplicate_bindings(_default_bindings),
	}


func preview_volumes(master_value: float, music_value: float, sfx_value: float) -> void:
	_set_bus_percent(&"Master", master_value)
	_set_bus_percent(&"Music", music_value)
	_set_bus_percent(&"SFX", sfx_value)


func restore_applied_volume_preview() -> void:
	preview_volumes(master_volume, music_volume, sfx_volume)


func apply_and_save(snapshot: Dictionary) -> int:
	if not _validate_snapshot(snapshot):
		return ERR_INVALID_DATA
	var previous := get_snapshot()
	_apply_snapshot(snapshot)
	var save_error := save_settings()
	if save_error != OK:
		_apply_snapshot(previous)
		settings_save_failed.emit(save_error, get_settings_path())
		return save_error
	settings_applied.emit()
	return OK


func load_settings() -> int:
	var snapshot := get_default_snapshot()
	var config := ConfigFile.new()
	var path := get_settings_path()
	var error := config.load(path)
	if error == ERR_FILE_NOT_FOUND:
		# InputMap already contains the exact project.godot defaults. Keep those
		# resource events intact instead of erasing/re-adding them during first
		# launch; some special keys (for example Tab) carry engine-side identity
		# information that should not be normalized unless the user saved a
		# replacement binding.
		master_volume = DEFAULT_VOLUME
		music_volume = DEFAULT_VOLUME
		sfx_volume = DEFAULT_VOLUME
		preview_volumes(master_volume, music_volume, sfx_volume)
		return OK
	if error != OK:
		push_warning("设置文件损坏或无法读取，已恢复默认值：%s（错误 %d）" % [path, error])
		_apply_snapshot(snapshot)
		return error

	snapshot.master_volume = clampf(float(config.get_value("audio", "master", DEFAULT_VOLUME)), 0.0, 100.0)
	snapshot.music_volume = clampf(float(config.get_value("audio", "music", DEFAULT_VOLUME)), 0.0, 100.0)
	snapshot.sfx_volume = clampf(float(config.get_value("audio", "sfx", DEFAULT_VOLUME)), 0.0, 100.0)
	var loaded_bindings: Dictionary = snapshot.bindings
	for action in EDITABLE_ACTIONS:
		if not config.has_section_key("bindings", String(action)):
			continue
		var serialized_events: Variant = config.get_value("bindings", String(action), [])
		if not serialized_events is Array:
			continue
		var events: Array[InputEvent] = []
		for serialized in serialized_events:
			var input_event := _deserialize_event(serialized)
			if input_event != null:
				events.append(input_event)
		if not events.is_empty():
			loaded_bindings[action] = events
	snapshot.bindings = loaded_bindings
	_apply_snapshot(snapshot)
	return OK


func save_settings() -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "version", CONFIG_VERSION)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	var bindings := _capture_bindings_from_input_map()
	for action in EDITABLE_ACTIONS:
		var serialized_events: Array[Dictionary] = []
		for event in bindings.get(action, []):
			var serialized := _serialize_event(event)
			if not serialized.is_empty():
				serialized_events.append(serialized)
		config.set_value("bindings", String(action), serialized_events)
	var path := get_settings_path()
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error not in [OK, ERR_ALREADY_EXISTS]:
		push_error("无法创建设置目录：%s（错误 %d）" % [absolute_path.get_base_dir(), directory_error])
		return directory_error
	var error := config.save(path)
	if error != OK:
		push_error("无法保存设置：%s（错误 %d）" % [absolute_path, error])
	return error


func get_settings_path() -> String:
	return settings_path_override if not settings_path_override.is_empty() else SETTINGS_PATH


func set_settings_path_override_for_test(path: String) -> void:
	settings_path_override = path


func replace_action_binding_in_snapshot(snapshot: Dictionary, action: StringName, event: InputEvent) -> void:
	if action not in EDITABLE_ACTIONS or event == null:
		return
	var bindings: Dictionary = snapshot.get("bindings", {})
	bindings[action] = [_duplicate_event(event)]
	snapshot["bindings"] = bindings


func find_binding_conflicts(snapshot: Dictionary, action: StringName, event: InputEvent) -> PackedStringArray:
	var conflicts: PackedStringArray = []
	var bindings: Dictionary = snapshot.get("bindings", {})
	for other_action in EDITABLE_ACTIONS:
		if other_action == action:
			continue
		for other_event in bindings.get(other_action, []):
			if events_equal(event, other_event):
				conflicts.append(String(ACTION_LABELS.get(other_action, String(other_action))))
				break
	return conflicts


func events_equal(first: InputEvent, second: InputEvent) -> bool:
	if first is InputEventKey and second is InputEventKey:
		var first_key := first as InputEventKey
		var second_key := second as InputEventKey
		var first_code := first_key.physical_keycode if first_key.physical_keycode != 0 else first_key.keycode
		var second_code := second_key.physical_keycode if second_key.physical_keycode != 0 else second_key.keycode
		return (
			first_code == second_code
			and first_key.ctrl_pressed == second_key.ctrl_pressed
			and first_key.alt_pressed == second_key.alt_pressed
			and first_key.shift_pressed == second_key.shift_pressed
			and first_key.meta_pressed == second_key.meta_pressed
		)
	if first is InputEventMouseButton and second is InputEventMouseButton:
		return (first as InputEventMouseButton).button_index == (second as InputEventMouseButton).button_index
	return false


func _ensure_audio_buses() -> void:
	for bus_name in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _capture_project_defaults() -> void:
	_default_bindings.clear()
	for action in EDITABLE_ACTIONS:
		var events: Array[InputEvent] = []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey or event is InputEventMouseButton:
					events.append(_duplicate_event(event))
		_default_bindings[action] = events


func _capture_bindings_from_input_map() -> Dictionary:
	var bindings: Dictionary = {}
	for action in EDITABLE_ACTIONS:
		var events: Array[InputEvent] = []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey or event is InputEventMouseButton:
					events.append(_duplicate_event(event))
		bindings[action] = events
	return bindings


func _apply_snapshot(snapshot: Dictionary) -> void:
	master_volume = clampf(float(snapshot.get("master_volume", DEFAULT_VOLUME)), 0.0, 100.0)
	music_volume = clampf(float(snapshot.get("music_volume", DEFAULT_VOLUME)), 0.0, 100.0)
	sfx_volume = clampf(float(snapshot.get("sfx_volume", DEFAULT_VOLUME)), 0.0, 100.0)
	preview_volumes(master_volume, music_volume, sfx_volume)
	var bindings: Dictionary = snapshot.get("bindings", {})
	for action in EDITABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event in bindings.get(action, []):
			InputMap.action_add_event(action, _duplicate_event(event))
	bindings_changed.emit()


func _validate_snapshot(snapshot: Dictionary) -> bool:
	for volume_key in ["master_volume", "music_volume", "sfx_volume"]:
		if not snapshot.has(volume_key):
			return false
		var value := float(snapshot[volume_key])
		if value < 0.0 or value > 100.0:
			return false
	var bindings: Variant = snapshot.get("bindings", null)
	if not bindings is Dictionary:
		return false
	for action in EDITABLE_ACTIONS:
		if not bindings.has(action) or not bindings[action] is Array or bindings[action].is_empty():
			return false
		for event in bindings[action]:
			if not event is InputEventKey and not event is InputEventMouseButton:
				return false
	return true


func _set_bus_percent(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var percent := clampf(value, 0.0, 100.0)
	AudioServer.set_bus_mute(bus_index, percent <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, SILENCE_DB if percent <= 0.0 else linear_to_db(percent / 100.0))


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		return {
			"type": "key",
			"keycode": int(key.keycode),
			"physical_keycode": int(key.physical_keycode),
			"ctrl": key.ctrl_pressed,
			"alt": key.alt_pressed,
			"shift": key.shift_pressed,
			"meta": key.meta_pressed,
		}
	if event is InputEventMouseButton:
		return {
			"type": "mouse",
			"button_index": int((event as InputEventMouseButton).button_index),
		}
	return {}


func _deserialize_event(serialized: Variant) -> InputEvent:
	if not serialized is Dictionary:
		return null
	match String(serialized.get("type", "")):
		"key":
			var key := InputEventKey.new()
			key.keycode = int(serialized.get("keycode", 0))
			key.physical_keycode = int(serialized.get("physical_keycode", 0))
			key.ctrl_pressed = bool(serialized.get("ctrl", false))
			key.alt_pressed = bool(serialized.get("alt", false))
			key.shift_pressed = bool(serialized.get("shift", false))
			key.meta_pressed = bool(serialized.get("meta", false))
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(serialized.get("button_index", MOUSE_BUTTON_LEFT))
			return mouse
	return null


func _duplicate_bindings(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for action in source:
		var events: Array[InputEvent] = []
		for event in source[action]:
			events.append(_duplicate_event(event))
		result[action] = events
	return result


func _duplicate_event(event: InputEvent) -> InputEvent:
	return event.duplicate(true) as InputEvent
