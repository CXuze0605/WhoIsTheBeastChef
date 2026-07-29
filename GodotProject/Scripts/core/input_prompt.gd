class_name InputPrompt
extends RefCounted


static func action_text(action: StringName, fallback: String = "未绑定") -> String:
	if not InputMap.has_action(action):
		return fallback
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return fallback
	return event_text(events[0], fallback)


static func action_token(action: StringName, fallback: String = "未绑定") -> String:
	return "[%s]" % action_text(action, fallback)


static func event_text(event: InputEvent, fallback: String = "未绑定") -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		var text := OS.get_keycode_string(code)
		if text.is_empty():
			text = key_event.as_text()
		var modifiers: PackedStringArray = []
		if key_event.ctrl_pressed:
			modifiers.append("Ctrl")
		if key_event.alt_pressed:
			modifiers.append("Alt")
		if key_event.shift_pressed:
			modifiers.append("Shift")
		if key_event.meta_pressed:
			modifiers.append("Meta")
		modifiers.append(text)
		return "+".join(modifiers)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return {
			MOUSE_BUTTON_LEFT: "Mouse Left",
			MOUSE_BUTTON_RIGHT: "Mouse Right",
			MOUSE_BUTTON_MIDDLE: "Mouse Middle",
			MOUSE_BUTTON_WHEEL_UP: "Mouse Wheel Up",
			MOUSE_BUTTON_WHEEL_DOWN: "Mouse Wheel Down",
			MOUSE_BUTTON_XBUTTON1: "Mouse Button 4",
			MOUSE_BUTTON_XBUTTON2: "Mouse Button 5",
		}.get(mouse_event.button_index, "Mouse Button %d" % mouse_event.button_index)
	return event.as_text() if event != null else fallback
