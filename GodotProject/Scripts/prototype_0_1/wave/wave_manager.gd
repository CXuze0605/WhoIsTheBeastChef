class_name PrototypeWaveManager
extends Node2D

signal wave_stats_changed
signal early_service_recorded(seconds_early: float)

enum Phase {
	FREE_PREPARATION,
	GLOBAL_WARNING,
	LOCAL_WARNING,
	SPAWNING,
	WAVE_ACTIVE,
	INTERMISSION,
	RUN_COMPLETE,
	FAILED,
	# Legacy names are kept only so older debug helpers fail safely while the
	# Prototype 0.4 flow is migrated. Runtime never enters these states.
	WAITING_TO_START,
	PREPARATION,
	WAVE_COMPLETE,
}

@export var player_path: NodePath
@export var navigation_path: NodePath

var config := PrototypeWaveConfig.new()
var phase: int = Phase.FREE_PREPARATION
var preparation_left: float = 0.0
var phase_time_left: float = 0.0
var next_batch_left: float = 0.0
var current_batch: int = 0
var spawned_in_current_batch: int = 0
var spawned_total: int = 0
var reflavored_total: int = 0
var active_enemy_count: int = 0
var early_started: bool = false
var early_seconds: float = 0.0
var current_edge_label: String = ""
var pending_spawn_point: WaveSpawnPoint
var player: PrototypePlayer
var navigation: KitchenNavigationGrid
var random := RandomNumberGenerator.new()
var live_enemies: Array[BasicTasteEnemy] = []
var current_wave: int = 1
var completed_waves: int = 0


func _ready() -> void:
	add_to_group("prototype_wave_manager")
	player = get_node(player_path) as PrototypePlayer
	navigation = get_node(navigation_path) as KitchenNavigationGrid
	random.randomize()
	if player != null:
		player.configure_wave_health(config.player_max_health, config.player_hit_protection_time)
		player.player_defeated.connect(_on_player_defeated)
	_initialize_new_run()
	wave_stats_changed.emit()


func _process(delta: float) -> void:
	match phase:
		Phase.FREE_PREPARATION:
			pass
		Phase.GLOBAL_WARNING:
			phase_time_left -= delta
			if phase_time_left <= 0.0:
				_begin_local_warning()
		Phase.LOCAL_WARNING:
			phase_time_left -= delta
			if phase_time_left <= 0.0:
				_begin_spawning_batch()
		Phase.SPAWNING:
			phase_time_left -= delta
			if phase_time_left <= 0.0:
				_spawn_next_in_batch()
		Phase.WAVE_ACTIVE:
			if current_batch < config.get_total_batches(current_wave):
				next_batch_left = maxf(0.0, next_batch_left - delta)
				if next_batch_left <= 0.0:
					_begin_local_warning()
			else:
				_check_wave_complete()
		Phase.INTERMISSION:
			preparation_left = maxf(0.0, preparation_left - delta)
			if preparation_left <= 0.0:
				early_started = false
				early_seconds = 0.0
				_begin_global_warning()
	wave_stats_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_service"):
		if phase in [Phase.FREE_PREPARATION, Phase.INTERMISSION]:
			start_service_early()


func start_service_early() -> bool:
	if phase not in [Phase.FREE_PREPARATION, Phase.INTERMISSION]:
		return false
	if phase == Phase.INTERMISSION:
		early_started = preparation_left > 0.0
		early_seconds = preparation_left
		early_service_recorded.emit(early_seconds)
	else:
		# The first wave has free preparation with no countdown.
		early_started = false
		early_seconds = 0.0
	_begin_global_warning()
	return true


func start_game() -> bool:
	if phase not in [Phase.FAILED, Phase.RUN_COMPLETE, Phase.WAVE_COMPLETE, Phase.WAITING_TO_START]:
		return false
	_initialize_new_run()
	wave_stats_changed.emit()
	return true


func start_same_wave_preparation() -> void:
	if phase not in [Phase.WAVE_COMPLETE, Phase.RUN_COMPLETE]:
		return
	phase = Phase.FREE_PREPARATION
	preparation_left = 0.0
	phase_time_left = 0.0
	next_batch_left = 0.0
	current_batch = 0
	spawned_in_current_batch = 0
	spawned_total = 0
	reflavored_total = 0
	active_enemy_count = 0
	early_started = false
	early_seconds = 0.0
	current_edge_label = ""
	wave_stats_changed.emit()


func force_begin_wave_for_test() -> void:
	if phase == Phase.FREE_PREPARATION:
		start_service_early()


func force_advance_phase_for_test(delta: float) -> void:
	_process(delta)


func spawn_enemy_for_test(position: Vector2) -> BasicTasteEnemy:
	return _spawn_enemy_at(position)


func spawn_heavy_enemy_for_test(position: Vector2) -> HeavyTasteEnemy:
	return _spawn_heavy_enemy_at(position)


func choose_legal_spawn_point() -> WaveSpawnPoint:
	var legal: Array[WaveSpawnPoint] = []
	for node in get_tree().get_nodes_in_group("enemy_spawn_point"):
		var point := node as WaveSpawnPoint
		if point != null and _is_spawn_point_legal(point):
			legal.append(point)
	if legal.is_empty():
		return null
	return legal[random.randi_range(0, legal.size() - 1)]


func get_legal_spawn_points() -> Array[WaveSpawnPoint]:
	var legal: Array[WaveSpawnPoint] = []
	for node in get_tree().get_nodes_in_group("enemy_spawn_point"):
		var point := node as WaveSpawnPoint
		if point != null and _is_spawn_point_legal(point):
			legal.append(point)
	return legal


func get_phase_text() -> String:
	return {
		Phase.FREE_PREPARATION: "自由准备",
		Phase.WAITING_TO_START: "等待开始",
		Phase.PREPARATION: "准备",
		Phase.GLOBAL_WARNING: "全局预警",
		Phase.LOCAL_WARNING: "局部预警",
		Phase.SPAWNING: "刷怪",
		Phase.WAVE_ACTIVE: "波次进行",
		Phase.INTERMISSION: "波间准备",
		Phase.RUN_COMPLETE: "三波测试完成",
		Phase.WAVE_COMPLETE: "旧波次完成状态",
		Phase.FAILED: "失败",
	}.get(phase, "未知")


func get_debug_summary() -> String:
	return "阶段：%s\n波次：%d / %d\n准备倒计时：%s\n提前营业：%s / 提前 %.1fs\n批次：%d / %d\n场上味真族：%d\n已生成：%d / 已复味：%d\n下一批：%.1fs\n局部方向：%s" % [
		get_phase_text(), current_wave, config.run_total_waves,
		"自由" if phase == Phase.FREE_PREPARATION else "%.1fs" % preparation_left,
		"是" if early_started else "否", early_seconds,
		current_batch, config.get_total_batches(current_wave), active_enemy_count, spawned_total, reflavored_total,
		next_batch_left if phase == Phase.WAVE_ACTIVE else phase_time_left,
		current_edge_label if not current_edge_label.is_empty() else "无",
	]


func _begin_global_warning() -> void:
	phase = Phase.GLOBAL_WARNING
	preparation_left = 0.0
	phase_time_left = config.global_warning_time
	current_edge_label = ""
	wave_stats_changed.emit()


func _initialize_new_run() -> void:
	_reset_scene_for_new_game()
	phase = Phase.FREE_PREPARATION
	preparation_left = 0.0
	if player != null:
		player.set_modal_ui_open(false)
	wave_stats_changed.emit()


func _begin_local_warning() -> void:
	pending_spawn_point = choose_legal_spawn_point()
	if pending_spawn_point == null:
		phase = Phase.FAILED
		current_edge_label = "无合法生成点"
		return
	phase = Phase.LOCAL_WARNING
	phase_time_left = config.local_warning_time
	current_edge_label = pending_spawn_point.edge_label
	wave_stats_changed.emit()


func _begin_spawning_batch() -> void:
	phase = Phase.SPAWNING
	current_batch += 1
	spawned_in_current_batch = 0
	phase_time_left = 0.0


func _spawn_next_in_batch() -> void:
	if pending_spawn_point == null or not _is_spawn_point_legal(pending_spawn_point):
		pending_spawn_point = choose_legal_spawn_point()
	if pending_spawn_point != null:
		var offset := Vector2.RIGHT.rotated(random.randf_range(-PI, PI)) * random.randf_range(0.0, 22.0)
		var normal_count := config.get_normal_per_batch(current_wave)
		if spawned_in_current_batch < normal_count:
			_spawn_enemy_at(pending_spawn_point.global_position + offset)
		else:
			_spawn_heavy_enemy_at(pending_spawn_point.global_position + offset)
	spawned_in_current_batch += 1
	if spawned_in_current_batch < config.get_enemies_in_batch(current_wave):
		phase_time_left = config.same_batch_spawn_interval
	else:
		phase = Phase.WAVE_ACTIVE
		next_batch_left = config.batch_interval
		current_edge_label = ""
		_check_wave_complete()


func _spawn_enemy_at(position: Vector2) -> BasicTasteEnemy:
	var enemy := BasicTasteEnemy.new()
	enemy.name = "BasicTasteEnemy_%d" % (spawned_total + 1)
	enemy.setup(config, player, navigation)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position
	enemy.reflavor_completed.connect(_on_enemy_reflavored)
	live_enemies.append(enemy)
	spawned_total += 1
	active_enemy_count += 1
	wave_stats_changed.emit()
	return enemy


func _spawn_heavy_enemy_at(position: Vector2) -> HeavyTasteEnemy:
	var enemy := HeavyTasteEnemy.new()
	enemy.name = "HeavyTasteEnemy_%d" % (spawned_total + 1)
	enemy.setup(config, player, navigation)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position
	enemy.reflavor_completed.connect(_on_enemy_reflavored)
	live_enemies.append(enemy)
	spawned_total += 1
	active_enemy_count += 1
	wave_stats_changed.emit()
	return enemy


func _on_enemy_reflavored(enemy: BasicTasteEnemy) -> void:
	if enemy in live_enemies:
		live_enemies.erase(enemy)
		active_enemy_count = maxi(0, active_enemy_count - 1)
		reflavored_total += 1
	_check_wave_complete()
	wave_stats_changed.emit()


func _check_wave_complete() -> void:
	var planned_total := config.get_planned_enemy_total(current_wave)
	if current_batch >= config.get_total_batches(current_wave) and spawned_total >= planned_total and active_enemy_count == 0 and reflavored_total >= planned_total:
		next_batch_left = 0.0
		current_edge_label = ""
		completed_waves = current_wave
		if current_wave >= config.run_total_waves:
			phase = Phase.RUN_COMPLETE
		else:
			current_wave += 1
			phase = Phase.INTERMISSION
			preparation_left = config.intermission_time
			_reset_wave_counters_only()
		wave_stats_changed.emit()


func _on_player_defeated() -> void:
	if phase in [Phase.RUN_COMPLETE, Phase.FAILED]:
		return
	phase = Phase.FAILED
	for enemy in live_enemies:
		if is_instance_valid(enemy):
			enemy.disable_for_failed_wave()
	wave_stats_changed.emit()


func _is_spawn_point_legal(point: WaveSpawnPoint) -> bool:
	if player == null or navigation == null:
		return false
	if point.global_position.distance_to(player.global_position) < config.minimum_spawn_distance:
		return false
	if not navigation.is_position_walkable(point.global_position):
		return false
	if navigation.find_path(point.global_position, player.global_position).is_empty():
		return false
	for enemy in live_enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(point.global_position) < config.spawn_clearance:
			return false
	return true


func _apply_shared_prototype_config() -> void:
	var cabinet := get_tree().get_first_node_in_group("ingredient_cabinet") as IngredientCabinet
	if cabinet != null:
		cabinet.configure_prototype_stock({
			ItemData.ItemType.RAW_BEEF_CHUNK: config.raw_beef_stock,
			ItemData.ItemType.MARINADE: config.marinade_stock,
			ItemData.ItemType.CHILI_SEGMENTS: config.chili_stock,
			ItemData.ItemType.COOKING_OIL: config.cooking_oil_stock,
			ItemData.ItemType.SALT: config.salt_stock,
			ItemData.ItemType.MUSTARD: config.mustard_stock,
		})
	var pile := get_tree().get_first_node_in_group("clean_plate_pile") as CleanPlatePile
	if pile != null:
		pile.configure_initial_stock(config.clean_plate_stock)
	var cutting_board := get_tree().get_first_node_in_group("cutting_board") as CuttingBoard
	if cutting_board != null:
		cutting_board.prototype_first_cut_time = config.first_cut_time
		cutting_board.prototype_second_cut_time = config.second_cut_time
	var marinating_station := get_tree().get_first_node_in_group("marinating_station") as MarinatingStation
	if marinating_station != null:
		marinating_station.prototype_marinating_time = config.marinating_time


func _reset_scene_for_new_game() -> void:
	for enemy in get_tree().get_nodes_in_group("basic_taste_enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	live_enemies.clear()
	for trap in get_tree().get_nodes_in_group("shabu_trap"):
		if is_instance_valid(trap):
			trap.queue_free()
	current_wave = 1
	completed_waves = 0
	current_batch = 0
	spawned_in_current_batch = 0
	spawned_total = 0
	reflavored_total = 0
	active_enemy_count = 0
	early_started = false
	early_seconds = 0.0
	current_edge_label = ""
	pending_spawn_point = null
	phase_time_left = 0.0
	next_batch_left = 0.0

	var cabinet_ui := get_tree().get_first_node_in_group("ingredient_cabinet_ui") as IngredientCabinetUI
	if cabinet_ui != null and cabinet_ui.is_open():
		cabinet_ui.close_cabinet()
	var plating := get_tree().get_first_node_in_group("plating_controller") as PlatingController
	if plating != null:
		plating.reset_for_new_game()
	var combat := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat != null:
		combat.reset_for_new_game()
	# Clear every carryable from the previous run, including items dropped in the
	# world. Station and inventory reset methods below also clear their references.
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is CarryableItem and is_instance_valid(node):
			node.queue_free()

	if player != null:
		player.reset_for_new_game(config.player_max_health, config.player_hit_protection_time)
	var cutting_board := get_tree().get_first_node_in_group("cutting_board") as CuttingBoard
	if cutting_board != null:
		cutting_board.reset_for_new_game()
	var marinating_station := get_tree().get_first_node_in_group("marinating_station") as MarinatingStation
	if marinating_station != null:
		marinating_station.reset_for_new_game()
	var stove_stations: Array[WokStation] = []
	for node in get_tree().get_nodes_in_group("stove_station"):
		if node is WokStation:
			stove_stations.append(node as WokStation)
	for stove in stove_stations:
		stove.reset_for_new_game()
	var cookware_rack := get_tree().get_first_node_in_group("cookware_rack") as CookwareRack
	if cookware_rack != null:
		cookware_rack.reset_for_new_game()
	var sink: SinkStation
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is SinkStation:
			sink = node as SinkStation
			break
	if sink != null:
		sink.reset_for_new_game()
	var pile := get_tree().get_first_node_in_group("clean_plate_pile") as CleanPlatePile
	if pile != null:
		pile.reset_for_new_game(config.clean_plate_stock)
	for node in get_tree().get_nodes_in_group("debug_combat_target"):
		if node is DebugCombatTarget:
			(node as DebugCombatTarget).reset_target()
	_apply_shared_prototype_config()
	for stove in stove_stations:
		stove.set_session_active(true)


func _reset_wave_counters_only() -> void:
	live_enemies.clear()
	current_batch = 0
	spawned_in_current_batch = 0
	spawned_total = 0
	reflavored_total = 0
	active_enemy_count = 0
	current_edge_label = ""
	pending_spawn_point = null
	phase_time_left = 0.0
	next_batch_left = 0.0
	early_started = false
	early_seconds = 0.0
