class_name SettingsPanel
extends Control

signal closed

var manager: GameSettingsManager
var panel_title: Label
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var master_value: Label
var music_value: Label
var sfx_value: Label
var binding_buttons: Dictionary = {}
var status_label: Label
var conflict_dialog: ConfirmationDialog
var defaults_dialog: ConfirmationDialog
var _original_snapshot: Dictionary = {}
var _working_snapshot: Dictionary = {}
var _capturing_action: StringName = &""
var _pending_conflict_action: StringName = &""
var _pending_conflict_event: InputEvent


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	manager = get_node_or_null("/root/SettingsManager") as GameSettingsManager
	_build_ui()
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _capturing_action != &"":
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if not key_event.pressed or key_event.echo:
				return
			if _is_escape_key(key_event):
				_cancel_capture("已取消键位修改。")
				get_viewport().set_input_as_handled()
				return
			if _event_uses_f8(key_event):
				status_label.text = "F8 是 Godot 停止运行键，不能绑定。"
				get_viewport().set_input_as_handled()
				return
			_accept_captured_event(key_event)
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			if not mouse_event.pressed:
				return
			_accept_captured_event(mouse_event)
			get_viewport().set_input_as_handled()
			return
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and _is_escape_key(key_event):
			if conflict_dialog.visible:
				conflict_dialog.hide()
				_clear_pending_conflict()
			elif defaults_dialog.visible:
				defaults_dialog.hide()
			else:
				cancel_and_close()
			get_viewport().set_input_as_handled()


func open_panel(title: String = "设置") -> void:
	if manager == null:
		manager = get_node_or_null("/root/SettingsManager") as GameSettingsManager
	if manager == null:
		push_error("SettingsPanel cannot find SettingsManager")
		return
	panel_title.text = title
	_original_snapshot = manager.get_snapshot()
	_working_snapshot = manager.get_snapshot()
	_capturing_action = &""
	_clear_pending_conflict()
	_refresh_controls()
	status_label.text = "调整音量可实时试听；点击“应用”后保存。"
	visible = true
	master_slider.grab_focus()


func cancel_and_close() -> void:
	if manager != null:
		manager.restore_applied_volume_preview()
	_capturing_action = &""
	_clear_pending_conflict()
	visible = false
	closed.emit()


func is_capturing_binding() -> bool:
	return _capturing_action != &""


func get_working_snapshot_for_test() -> Dictionary:
	return _working_snapshot


func begin_capture_for_test(action: StringName) -> void:
	_begin_capture(action)


func _on_volume_changed(_value: float) -> void:
	if _working_snapshot.is_empty():
		return
	_working_snapshot.master_volume = master_slider.value
	_working_snapshot.music_volume = music_slider.value
	_working_snapshot.sfx_volume = sfx_slider.value
	_refresh_volume_labels()
	manager.preview_volumes(master_slider.value, music_slider.value, sfx_slider.value)


func _on_apply_pressed() -> void:
	if _capturing_action != &"":
		_cancel_capture("请先完成或取消当前键位捕获。")
	var error := manager.apply_and_save(_working_snapshot)
	if error != OK:
		status_label.text = "保存失败：%s（错误 %d）" % [ProjectSettings.globalize_path(manager.get_settings_path()), error]
		return
	_original_snapshot = manager.get_snapshot()
	_working_snapshot = manager.get_snapshot()
	_refresh_controls()
	status_label.text = "设置已保存。"


func _on_defaults_pressed() -> void:
	defaults_dialog.dialog_text = "恢复项目默认键位和 100% 音量？\n仍需点击“应用”才会写入设置文件。"
	defaults_dialog.popup_centered(Vector2i(520, 220))


func _on_defaults_confirmed() -> void:
	defaults_dialog.hide()
	_working_snapshot = manager.get_default_snapshot()
	_refresh_controls()
	manager.preview_volumes(master_slider.value, music_slider.value, sfx_slider.value)
	status_label.text = "已载入默认值；点击“应用”后保存。"


func _begin_capture(action: StringName) -> void:
	if action not in GameSettingsManager.EDITABLE_ACTIONS:
		return
	_capturing_action = action
	var button := binding_buttons.get(action) as Button
	if button != null:
		button.text = "请按下新按键…"
	status_label.text = "正在修改“%s”：ESC 取消，F8 不可绑定。" % GameSettingsManager.ACTION_LABELS.get(action, String(action))


func _cancel_capture(message: String) -> void:
	var previous_action := _capturing_action
	_capturing_action = &""
	if previous_action != &"":
		_refresh_binding_button(previous_action)
	status_label.text = message


func _accept_captured_event(event: InputEvent) -> void:
	var captured := event.duplicate(true) as InputEvent
	if captured is InputEventKey:
		(captured as InputEventKey).pressed = false
		(captured as InputEventKey).echo = false
	elif captured is InputEventMouseButton:
		(captured as InputEventMouseButton).pressed = false
	var conflicts := manager.find_binding_conflicts(_working_snapshot, _capturing_action, captured)
	if not conflicts.is_empty():
		_pending_conflict_action = _capturing_action
		_pending_conflict_event = captured
		conflict_dialog.dialog_text = "“%s”已用于：%s\n是否仍要重复使用？不会删除原绑定。" % [
			InputPrompt.event_text(captured),
			"、".join(conflicts),
		]
		conflict_dialog.popup_centered(Vector2i(560, 240))
		return
	_commit_captured_event(_capturing_action, captured)


func _confirm_conflict_binding() -> void:
	if _pending_conflict_action == &"" or _pending_conflict_event == null:
		return
	conflict_dialog.hide()
	_commit_captured_event(_pending_conflict_action, _pending_conflict_event)
	_clear_pending_conflict()


func _cancel_conflict_binding() -> void:
	conflict_dialog.hide()
	_clear_pending_conflict()
	_cancel_capture("保留原键位。")


func _commit_captured_event(action: StringName, event: InputEvent) -> void:
	manager.replace_action_binding_in_snapshot(_working_snapshot, action, event)
	_capturing_action = &""
	_refresh_binding_button(action)
	status_label.text = "“%s”暂改为 %s；点击“应用”后保存。" % [
		GameSettingsManager.ACTION_LABELS.get(action, String(action)),
		InputPrompt.event_text(event),
	]


func _clear_pending_conflict() -> void:
	_pending_conflict_action = &""
	_pending_conflict_event = null


func _refresh_controls() -> void:
	if _working_snapshot.is_empty():
		return
	master_slider.set_value_no_signal(float(_working_snapshot.get("master_volume", 100.0)))
	music_slider.set_value_no_signal(float(_working_snapshot.get("music_volume", 100.0)))
	sfx_slider.set_value_no_signal(float(_working_snapshot.get("sfx_volume", 100.0)))
	_refresh_volume_labels()
	for action in binding_buttons:
		_refresh_binding_button(action)


func _refresh_volume_labels() -> void:
	master_value.text = "%d" % roundi(master_slider.value)
	music_value.text = "%d" % roundi(music_slider.value)
	sfx_value.text = "%d" % roundi(sfx_slider.value)


func _refresh_binding_button(action: StringName) -> void:
	var button := binding_buttons.get(action) as Button
	if button == null:
		return
	var bindings: Dictionary = _working_snapshot.get("bindings", {})
	var events: Array = bindings.get(action, [])
	button.text = InputPrompt.event_text(events[0]) if not events.is_empty() else "未绑定"


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "SettingsDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.02, 0.035, 0.92)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.name = "SettingsMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.name = "SettingsPanelBody"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("20252e")
	panel_style.border_color = Color("ffd166")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 28.0
	panel_style.content_margin_right = 28.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)
	margin.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	panel_title = _make_label("设置", 34, Color("ffd166"), HORIZONTAL_ALIGNMENT_CENTER)
	panel_title.name = "SettingsTitle"
	column.add_child(panel_title)
	column.add_child(_make_label("音量", 22, Color("8ecae6")))
	column.add_child(_make_volume_row("总音量", "MasterVolumeSlider"))
	column.add_child(_make_volume_row("背景音乐音量", "MusicVolumeSlider"))
	column.add_child(_make_volume_row("音效音量", "SFXVolumeSlider"))
	column.add_child(_make_label("键位", 22, Color("8ecae6")))

	var scroll := ScrollContainer.new()
	scroll.name = "BindingsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var bindings_column := VBoxContainer.new()
	bindings_column.name = "BindingsList"
	bindings_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bindings_column.add_theme_constant_override("separation", 4)
	scroll.add_child(bindings_column)
	for definition in manager.get_action_definitions():
		var action: StringName = definition.action
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 38.0)
		var label := _make_label(String(definition.label), 16, Color("f1f3f5"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := Button.new()
		button.name = "Bind_%s" % action
		button.custom_minimum_size = Vector2(250.0, 34.0)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_begin_capture.bind(action))
		row.add_child(button)
		binding_buttons[action] = button
		bindings_column.add_child(row)

	status_label = _make_label("", 14, Color("90be6d"), HORIZONTAL_ALIGNMENT_CENTER)
	status_label.name = "SettingsStatus"
	status_label.custom_minimum_size = Vector2(0.0, 26.0)
	column.add_child(status_label)
	var buttons := HBoxContainer.new()
	buttons.name = "SettingsButtons"
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	var apply_button := _make_button("应用", "ApplyButton")
	apply_button.pressed.connect(_on_apply_pressed)
	buttons.add_child(apply_button)
	var cancel_button := _make_button("取消", "CancelButton")
	cancel_button.pressed.connect(cancel_and_close)
	buttons.add_child(cancel_button)
	var defaults_button := _make_button("恢复默认", "RestoreDefaultsButton")
	defaults_button.pressed.connect(_on_defaults_pressed)
	buttons.add_child(defaults_button)
	var back_button := _make_button("返回", "BackButton")
	back_button.pressed.connect(cancel_and_close)
	buttons.add_child(back_button)

	conflict_dialog = ConfirmationDialog.new()
	conflict_dialog.name = "BindingConflictDialog"
	conflict_dialog.title = "键位冲突"
	conflict_dialog.ok_button_text = "仍然使用"
	conflict_dialog.cancel_button_text = "取消修改"
	conflict_dialog.confirmed.connect(_confirm_conflict_binding)
	conflict_dialog.canceled.connect(_cancel_conflict_binding)
	add_child(conflict_dialog)
	defaults_dialog = ConfirmationDialog.new()
	defaults_dialog.name = "RestoreDefaultsDialog"
	defaults_dialog.title = "恢复默认"
	defaults_dialog.ok_button_text = "恢复默认"
	defaults_dialog.cancel_button_text = "取消"
	defaults_dialog.confirmed.connect(_on_defaults_confirmed)
	add_child(defaults_dialog)


func _make_volume_row(label_text: String, slider_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 34.0)
	var label := _make_label(label_text, 16, Color("f1f3f5"))
	label.custom_minimum_size = Vector2(180.0, 0.0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = slider_name
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_volume_changed)
	row.add_child(slider)
	var value_label := _make_label("100", 16, Color("ffd166"), HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(48.0, 0.0)
	row.add_child(value_label)
	match slider_name:
		"MasterVolumeSlider":
			master_slider = slider
			master_value = value_label
		"MusicVolumeSlider":
			music_slider = slider
			music_value = value_label
		"SFXVolumeSlider":
			sfx_slider = slider
			sfx_value = value_label
	return row


func _make_label(text: String, font_size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	return button


func _is_escape_key(event: InputEventKey) -> bool:
	return event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE


func _event_uses_f8(event: InputEventKey) -> bool:
	return event.keycode == KEY_F8 or event.physical_keycode == KEY_F8
