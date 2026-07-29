class_name PrototypeToolsOverlay
extends CanvasLayer

signal exit_run_confirmed

enum Mode {
	NONE,
	PAUSE_MENU,
	EXIT_CONFIRMATION,
	PLAYTEST_NOTES,
	SETTINGS,
}

const TEST_VERSION: String = "Prototype 0.5"

var development_tools_enabled: bool = OS.has_feature("editor")
var notes_path_override: String = ""
var mode: int = Mode.NONE
var pause_root: Control
var pause_panel: PanelContainer
var confirmation_panel: PanelContainer
var notes_root: Control
var note_inputs: Array[TextEdit] = []
var notes_status_label: Label
var save_notes_button: Button
var close_notes_button: Button
var continue_button: Button
var settings_button: Button
var settings_panel: SettingsPanel
var previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE
var previous_tree_paused: bool = false
var previous_music_paused: bool = false
var owns_world_pause: bool = false
var notes_return_mode: int = Mode.NONE


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("prototype_tools_overlay")
	_build_pause_ui()
	_build_notes_ui()
	_build_settings_ui()
	_apply_mode_visibility()


func _exit_tree() -> void:
	_restore_world_pause()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if mode == Mode.SETTINGS:
		return
	if event.is_action_pressed("toggle_playtest_notes") and development_tools_enabled:
		if mode in [Mode.NONE, Mode.PAUSE_MENU]:
			open_playtest_notes()
		elif mode == Mode.PLAYTEST_NOTES:
			close_playtest_notes()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("toggle_pause") and not _is_escape_pressed(event):
		return
	match mode:
		Mode.NONE:
			if not _close_active_local_modal():
				open_pause_menu()
		Mode.PAUSE_MENU:
			close_overlay()
		Mode.EXIT_CONFIRMATION:
			show_pause_menu()
		Mode.PLAYTEST_NOTES:
			close_playtest_notes()
	get_viewport().set_input_as_handled()


func open_pause_menu() -> void:
	_begin_world_pause()
	mode = Mode.PAUSE_MENU
	_apply_mode_visibility()
	continue_button.grab_focus()


func open_playtest_notes() -> bool:
	if not development_tools_enabled or mode not in [Mode.NONE, Mode.PAUSE_MENU]:
		return false
	notes_return_mode = Mode.PAUSE_MENU if mode == Mode.PAUSE_MENU else Mode.NONE
	_begin_world_pause()
	mode = Mode.PLAYTEST_NOTES
	notes_status_label.text = "记录将保存到 AI_Context/Playtest_Notes.md"
	_apply_mode_visibility()
	if not note_inputs.is_empty():
		note_inputs[0].grab_focus()
	return true


func show_pause_menu() -> void:
	if mode == Mode.NONE:
		_begin_world_pause()
	mode = Mode.PAUSE_MENU
	_apply_mode_visibility()
	continue_button.grab_focus()


func show_exit_confirmation() -> void:
	if mode != Mode.PAUSE_MENU:
		return
	mode = Mode.EXIT_CONFIRMATION
	_apply_mode_visibility()


func open_settings() -> void:
	if mode != Mode.PAUSE_MENU or settings_panel == null:
		return
	mode = Mode.SETTINGS
	_apply_mode_visibility()
	settings_panel.open_panel("暂停 · 设置")


func close_overlay() -> void:
	if mode == Mode.PLAYTEST_NOTES:
		close_playtest_notes()
		return
	mode = Mode.NONE
	_apply_mode_visibility()
	_restore_world_pause()


func close_playtest_notes() -> void:
	if mode != Mode.PLAYTEST_NOTES:
		return
	if notes_return_mode == Mode.PAUSE_MENU:
		mode = Mode.PAUSE_MENU
		notes_return_mode = Mode.NONE
		_apply_mode_visibility()
		continue_button.grab_focus()
		return
	notes_return_mode = Mode.NONE
	mode = Mode.NONE
	_apply_mode_visibility()
	_restore_world_pause()


func complete_exit_to_lobby() -> void:
	close_overlay()


func confirm_exit_to_lobby() -> void:
	if mode != Mode.EXIT_CONFIRMATION:
		return
	exit_run_confirmed.emit()


func save_playtest_notes() -> bool:
	if not development_tools_enabled:
		return false
	var issues: PackedStringArray = []
	for input in note_inputs:
		var issue := input.text.strip_edges()
		if not issue.is_empty():
			issues.append(issue)
	if issues.is_empty():
		notes_status_label.text = "请至少填写一项问题。"
		return false

	var notes_path := _get_notes_path()
	var absolute_notes_path := ProjectSettings.globalize_path(notes_path)
	var notes_directory := absolute_notes_path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(notes_directory)
	if directory_error not in [OK, ERR_ALREADY_EXISTS]:
		notes_status_label.text = "保存失败：无法创建目录\n%s" % notes_directory
		push_error("Playtest notes directory could not be created: %s (error %d)" % [notes_directory, directory_error])
		return false
	var file_existed := FileAccess.file_exists(notes_path)
	var access_mode := FileAccess.READ_WRITE if file_existed else FileAccess.WRITE
	var file := FileAccess.open(notes_path, access_mode)
	if file == null:
		notes_status_label.text = "保存失败：无法写入\n%s" % absolute_notes_path
		push_error("Playtest notes could not be opened: %s (error %d)" % [notes_path, FileAccess.get_open_error()])
		return false
	if file_existed:
		file.seek_end()
	else:
		file.store_string("# Playtest Notes / 试玩记录\n")

	var lines: PackedStringArray = ["", "## %s — %s" % [_get_timestamp(), TEST_VERSION], "", "发现问题：", ""]
	for index in issues.size():
		var formatted_issue := issues[index].replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\n   ")
		lines.append("%d. %s" % [index + 1, formatted_issue])
	lines.append("")
	file.store_string("\n".join(lines))
	file.close()

	for input in note_inputs:
		input.clear()
	notes_status_label.text = "记录已保存。"
	return true


func is_pause_menu_open() -> bool:
	return mode in [Mode.PAUSE_MENU, Mode.EXIT_CONFIRMATION]


func is_playtest_notes_open() -> bool:
	return mode == Mode.PLAYTEST_NOTES


func is_world_paused_by_overlay() -> bool:
	return owns_world_pause and get_tree().paused


func set_development_tools_enabled(enabled: bool) -> void:
	development_tools_enabled = enabled
	if not enabled and mode == Mode.PLAYTEST_NOTES:
		close_playtest_notes()


func _begin_world_pause() -> void:
	if owns_world_pause:
		return
	previous_tree_paused = get_tree().paused
	previous_mouse_mode = Input.mouse_mode
	var audio := get_node_or_null("/root/AudioManager") as PrototypeAudioManager
	previous_music_paused = audio.is_music_paused() if audio != null else false
	owns_world_pause = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_player_global_modal_visible(true)
	if audio != null:
		audio.set_music_paused(true)


func _restore_world_pause() -> void:
	if not owns_world_pause:
		return
	var audio := get_node_or_null("/root/AudioManager") as PrototypeAudioManager
	if audio != null:
		audio.set_music_paused(previous_music_paused)
	get_tree().paused = previous_tree_paused
	Input.mouse_mode = previous_mouse_mode
	_set_player_global_modal_visible(false)
	owns_world_pause = false


func _apply_mode_visibility() -> void:
	if pause_root != null:
		pause_root.visible = mode in [Mode.PAUSE_MENU, Mode.EXIT_CONFIRMATION]
	if pause_panel != null:
		pause_panel.visible = mode == Mode.PAUSE_MENU
	if confirmation_panel != null:
		confirmation_panel.visible = mode == Mode.EXIT_CONFIRMATION
	if notes_root != null:
		notes_root.visible = mode == Mode.PLAYTEST_NOTES
	if settings_panel != null and mode != Mode.SETTINGS:
		settings_panel.visible = false


func _get_notes_path() -> String:
	if not notes_path_override.is_empty():
		return notes_path_override
	var godot_project_dir := ProjectSettings.globalize_path("res://").simplify_path().trim_suffix("/")
	return godot_project_dir.get_base_dir().path_join("AI_Context").path_join("Playtest_Notes.md")


func _get_timestamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]


func _build_pause_ui() -> void:
	pause_root = Control.new()
	pause_root.name = "PauseRoot"
	pause_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_root)
	_add_fullscreen_dim(pause_root)

	pause_panel = _make_panel(Vector2(430.0, 390.0), Vector2(425.0, 165.0))
	pause_root.add_child(pause_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	pause_panel.add_child(column)
	var title := _make_label("游戏暂停", 38, Color("ffd166"), HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(title)
	var pause_binding := InputPrompt.action_text(&"toggle_pause", "ESC")
	var hint_text := "ESC 可继续游戏" if pause_binding == "Escape" or pause_binding == "ESC" else "ESC / %s 可继续游戏" % pause_binding
	var hint := _make_label(hint_text, 16, Color("d7e3fc"), HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(hint)
	continue_button = _make_button("继续游戏")
	continue_button.pressed.connect(close_overlay)
	column.add_child(continue_button)
	settings_button = _make_button("设置")
	settings_button.name = "PauseSettingsButton"
	settings_button.pressed.connect(open_settings)
	column.add_child(settings_button)
	var exit_button := _make_button("退出本局")
	exit_button.pressed.connect(show_exit_confirmation)
	column.add_child(exit_button)

	confirmation_panel = _make_panel(Vector2(500.0, 286.0), Vector2(390.0, 217.0))
	pause_root.add_child(confirmation_panel)
	var confirmation_column := VBoxContainer.new()
	confirmation_column.add_theme_constant_override("separation", 18)
	confirmation_panel.add_child(confirmation_column)
	confirmation_column.add_child(_make_label("确定退出本局？", 32, Color("ff8fa3"), HORIZONTAL_ALIGNMENT_CENTER))
	confirmation_column.add_child(_make_label("当前战斗进度将被清理，并返回主菜单。", 17, Color("f1f3f5"), HORIZONTAL_ALIGNMENT_CENTER))
	var confirmation_buttons := HBoxContainer.new()
	confirmation_buttons.add_theme_constant_override("separation", 14)
	confirmation_column.add_child(confirmation_buttons)
	var cancel_button := _make_button("取消")
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(show_pause_menu)
	confirmation_buttons.add_child(cancel_button)
	var confirm_button := _make_button("确认退出")
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.pressed.connect(confirm_exit_to_lobby)
	confirmation_buttons.add_child(confirm_button)


func _build_notes_ui() -> void:
	notes_root = Control.new()
	notes_root.name = "PlaytestNotesRoot"
	notes_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notes_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(notes_root)
	_add_fullscreen_dim(notes_root)

	var panel := _make_panel(Vector2(760.0, 660.0), Vector2(260.0, 30.0))
	notes_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	column.add_child(_make_label("试玩记录", 34, Color("ffd166"), HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_make_label("开发工具 · F9 或 ESC 关闭 · 录入期间游戏已暂停", 15, Color("d7e3fc"), HORIZONTAL_ALIGNMENT_CENTER))
	for index in 3:
		column.add_child(_make_label("问题%d：" % [index + 1], 17, Color("f1f3f5")))
		var input := TextEdit.new()
		input.name = "Issue%dInput" % [index + 1]
		input.custom_minimum_size = Vector2(0.0, 88.0)
		input.placeholder_text = "记录本次试玩发现的问题……"
		input.editable = true
		input.focus_mode = Control.FOCUS_ALL
		input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		input.add_theme_font_size_override("font_size", 16)
		column.add_child(input)
		note_inputs.append(input)
	notes_status_label = _make_label("记录将保存到 AI_Context/Playtest_Notes.md", 14, Color("90be6d"), HORIZONTAL_ALIGNMENT_CENTER)
	notes_status_label.custom_minimum_size = Vector2(0.0, 24.0)
	column.add_child(notes_status_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	save_notes_button = _make_button("保存记录")
	save_notes_button.name = "SaveNotesButton"
	save_notes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_notes_button.pressed.connect(save_playtest_notes)
	buttons.add_child(save_notes_button)
	close_notes_button = _make_button("关闭")
	close_notes_button.name = "CloseNotesButton"
	close_notes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_notes_button.pressed.connect(close_playtest_notes)
	buttons.add_child(close_notes_button)


func _build_settings_ui() -> void:
	var scene := load("res://Scenes/menu/settings_panel.tscn") as PackedScene
	if scene == null:
		push_error("Pause overlay could not load the shared settings panel")
		return
	settings_panel = scene.instantiate() as SettingsPanel
	settings_panel.name = "PauseSettingsPanel"
	settings_panel.closed.connect(_on_settings_closed)
	add_child(settings_panel)


func _on_settings_closed() -> void:
	if mode != Mode.SETTINGS:
		return
	mode = Mode.PAUSE_MENU
	_apply_mode_visibility()
	if settings_button != null:
		settings_button.grab_focus()


func _add_fullscreen_dim(parent: Control) -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.02, 0.035, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)


func _make_panel(panel_size: Vector2, panel_position: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20252e")
	style.border_color = Color("ffd166")
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 28.0
	style.content_margin_bottom = 28.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(text: String, font_size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 54.0)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _close_active_local_modal() -> bool:
	for node in get_tree().get_nodes_in_group("prototype_local_modal"):
		if not is_instance_valid(node) or not node.has_method("is_local_modal_open") or not node.has_method("close_local_modal"):
			continue
		if node.is_local_modal_open():
			node.close_local_modal()
			return true
	return false


func _set_player_global_modal_visible(visible: bool) -> void:
	for node in get_tree().get_nodes_in_group("player_target"):
		if is_instance_valid(node) and node.has_method("set_global_modal_overlay_open"):
			node.set_global_modal_overlay_open(visible)


func _is_escape_pressed(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var key := event as InputEventKey
	return key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE)
