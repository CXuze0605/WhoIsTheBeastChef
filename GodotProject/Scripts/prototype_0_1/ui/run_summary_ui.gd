class_name RunSummaryUI
extends CanvasLayer

var manager: PrototypeWaveManager
var stats: RunStats
var root_control: Control
var title_label: Label
var stats_label: Label
var end_button: Button


func _ready() -> void:
	layer = 100
	manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	_build_ui()


func _process(_delta: float) -> void:
	if manager == null:
		manager = get_tree().get_first_node_in_group("prototype_wave_manager") as PrototypeWaveManager
	if stats == null:
		stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	var should_show := manager != null and manager.phase in [PrototypeWaveManager.Phase.RUN_COMPLETE, PrototypeWaveManager.Phase.FAILED]
	root_control.visible = should_show
	if should_show:
		_refresh_summary()


func _on_end_run_pressed() -> void:
	if manager != null:
		manager.return_to_lobby()


func _refresh_summary_legacy() -> void:
	title_label.text = "成功防守" if manager.phase == PrototypeWaveManager.Phase.RUN_COMPLETE else "厨房失守"
	title_label.add_theme_color_override("font_color", Color("90be6d") if manager.phase == PrototypeWaveManager.Phase.RUN_COMPLETE else Color("ff6b6b"))
	var snapshot := stats.get_snapshot() if stats != null else {}
	stats_label.text = "制作料理数量：%d\n本局造成总伤害：%.0f\n击败普通味真族数量：%d\n击败特殊味真族数量：%d\n造成友军伤害：%.0f\n击倒队友次数：%d" % [
		int(snapshot.get("dishes_created", 0)),
		float(snapshot.get("total_damage_dealt", 0.0)),
		int(snapshot.get("basic_enemies_defeated", 0)),
		int(snapshot.get("special_enemies_defeated", 0)),
		float(snapshot.get("friendly_fire_damage", 0.0)),
		int(snapshot.get("teammates_knocked_down", 0)),
	]


func _refresh_summary() -> void:
	title_label.text = "成功防守" if manager.phase == PrototypeWaveManager.Phase.RUN_COMPLETE else "厨房失守"
	title_label.add_theme_color_override("font_color", Color("90be6d") if manager.phase == PrototypeWaveManager.Phase.RUN_COMPLETE else Color("ff6b6b"))
	var snapshot := stats.get_snapshot() if stats != null else {}
	stats_label.text = "制作料理数量：%d\n本局造成总伤害：%.0f\n击败普通味真族：%d\n击败特殊味真族：%d\n造成友军伤害：%.0f\n击倒队友次数：%d\n战利品生成：%d\n战利品拾取：%d" % [
		int(snapshot.get("dishes_created", 0)),
		float(snapshot.get("total_damage_dealt", 0.0)),
		int(snapshot.get("basic_enemies_defeated", 0)),
		int(snapshot.get("special_enemies_defeated", 0)),
		float(snapshot.get("friendly_fire_damage", 0.0)),
		int(snapshot.get("teammates_knocked_down", 0)),
		int(snapshot.get("loot_spawned", 0)),
		int(snapshot.get("loot_picked_up", 0)),
	]


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "RunSummaryRoot"
	root_control.size = Vector2(1280.0, 720.0)
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)

	var dim := ColorRect.new()
	dim.size = Vector2(1280.0, 720.0)
	dim.color = Color(0.02, 0.025, 0.04, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(350.0, 86.0)
	panel.size = Vector2(580.0, 548.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("20252e")
	style.border_color = Color("ffd166")
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	style.content_margin_left = 42.0
	style.content_margin_right = 42.0
	style.content_margin_top = 30.0
	style.content_margin_bottom = 30.0
	panel.add_theme_stylebox_override("panel", style)
	root_control.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	title_label = Label.new()
	title_label.name = "ResultTitle"
	title_label.text = "成功防守"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 44)
	column.add_child(title_label)
	var divider := HSeparator.new()
	column.add_child(divider)
	stats_label = Label.new()
	stats_label.name = "RunStatsLabel"
	stats_label.custom_minimum_size = Vector2(0.0, 300.0)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 19)
	stats_label.add_theme_color_override("font_color", Color("f1f3f5"))
	stats_label.add_theme_constant_override("line_spacing", 8)
	column.add_child(stats_label)
	end_button = Button.new()
	end_button.name = "EndRunButton"
	end_button.text = "结束本局"
	end_button.custom_minimum_size = Vector2(0.0, 56.0)
	end_button.add_theme_font_size_override("font_size", 22)
	end_button.pressed.connect(_on_end_run_pressed)
	column.add_child(end_button)
	root_control.visible = false
