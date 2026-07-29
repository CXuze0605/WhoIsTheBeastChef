class_name PrototypeWaveManager
extends Node2D

signal wave_stats_changed
signal early_service_recorded(seconds_early: float)
signal run_finished(success: bool)

enum Phase {
	FREE_PREPARATION,
	PREPARATION,
	GLOBAL_WARNING,
	LOCAL_WARNING,
	SPAWNING,
	WAVE_ACTIVE,
	INTERMISSION,
	RUN_COMPLETE,
	FAILED,
	# Legacy names are kept only so older debug helpers fail safely while the
	# Prototype flow is migrated. Runtime never enters these states.
	WAITING_TO_START,
	WAVE_COMPLETE,
}

const RESOURCE_OIL: StringName = &"oil"
const RESOURCE_GREENS: StringName = &"greens"
const RESOURCE_SALT: StringName = &"salt"
const RESOURCE_MARINADE: StringName = &"marinade"
const RESOURCE_RICE: StringName = &"rice"
const RESOURCE_CHILI: StringName = &"chili"
const RESOURCE_MUSTARD: StringName = &"mustard"
const RESOURCE_BEEF: StringName = &"beef"

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
var run_stats: RunStats
var freshness_manager: FreshnessManager
var loot_settled_enemy_ids: Dictionary = {}
var shortage_elapsed: Dictionary = {}
var shortage_scan_accumulator: float = 0.0
var rice_drop_cooldown_left: float = 0.0
var supply_cache: Dictionary = {}
var shortage_supply_override_for_test: Dictionary = {}


func _ready() -> void:
	add_to_group("prototype_wave_manager")
	player = get_node(player_path) as PrototypePlayer
	navigation = get_node(navigation_path) as KitchenNavigationGrid
	run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	freshness_manager = get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
	random.randomize()
	if player != null:
		player.configure_wave_health(
			config.player_max_health,
			config.player_hit_protection_time,
			config.player_max_shield,
			config.player_shield_regen_delay,
			config.player_shield_regen_per_second
		)
		player.player_defeated.connect(_on_player_defeated)
	_initialize_new_run()
	wave_stats_changed.emit()


func _process(delta: float) -> void:
	if phase in [Phase.SPAWNING, Phase.WAVE_ACTIVE]:
		_update_shortage_compensation(delta)
	match phase:
		Phase.FREE_PREPARATION:
			pass
		Phase.PREPARATION:
			preparation_left = maxf(0.0, preparation_left - delta)
			if preparation_left <= 0.0:
				_begin_global_warning()
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
		_begin_global_warning()
	else:
		_begin_initial_preparation()
	return true


func start_game() -> bool:
	if phase not in [Phase.FAILED, Phase.RUN_COMPLETE, Phase.WAVE_COMPLETE, Phase.WAITING_TO_START]:
		return false
	return_to_lobby()
	return true


func return_to_lobby() -> void:
	_initialize_new_run()
	wave_stats_changed.emit()


func start_same_wave_preparation() -> void:
	if phase not in [Phase.WAVE_COMPLETE, Phase.RUN_COMPLETE]:
		return
	return_to_lobby()


func force_begin_wave_for_test() -> void:
	if phase == Phase.FREE_PREPARATION:
		start_service_early()
	if phase == Phase.PREPARATION:
		force_advance_phase_for_test(preparation_left + 0.01)


func force_advance_phase_for_test(delta: float) -> void:
	_process(delta)


func spawn_enemy_for_test(position: Vector2) -> BasicTasteEnemy:
	return _spawn_enemy_at(position)


func spawn_heavy_enemy_for_test(position: Vector2) -> HeavyTasteEnemy:
	return _spawn_heavy_enemy_at(position)


func spawn_fast_enemy_for_test(position: Vector2) -> FastTasteEnemy:
	return _spawn_fast_enemy_at(position)


func spawn_ranged_enemy_for_test(position: Vector2) -> RangedTasteEnemy:
	return _spawn_ranged_enemy_at(position)


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
		"大厅" if phase == Phase.FREE_PREPARATION else "%.1fs" % preparation_left,
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


func _begin_initial_preparation() -> void:
	# The free lobby is an isolated practice space. Reuse the one complete
	# new-run reset before formal preparation so no lobby items, cookware state,
	# attacks, traps or statistics leak into the run.
	_reset_scene_for_new_game()
	if freshness_manager == null:
		freshness_manager = get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
	if freshness_manager != null:
		freshness_manager.begin_formal_run()
	phase = Phase.PREPARATION
	preparation_left = maxf(config.preparation_time, 30.0)
	phase_time_left = 0.0
	early_started = false
	early_seconds = 0.0
	current_edge_label = ""
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.begin_run()
	_set_test_dummies_active(false)
	var combat := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat != null:
		combat.clear_active_attacks()
	wave_stats_changed.emit()


func _initialize_new_run() -> void:
	if freshness_manager == null:
		freshness_manager = get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
	if freshness_manager != null:
		freshness_manager.stop_for_lobby()
	_reset_scene_for_new_game()
	phase = Phase.FREE_PREPARATION
	preparation_left = 0.0
	var cabinet := get_tree().get_first_node_in_group("ingredient_cabinet") as IngredientCabinet
	if cabinet != null:
		cabinet.configure_lobby_unlimited_catalog()
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.reset_for_lobby()
	_set_test_dummies_active(true)
	if player != null:
		player.set_modal_ui_open(false)
	wave_stats_changed.emit()


func _begin_local_warning() -> void:
	pending_spawn_point = choose_legal_spawn_point()
	if pending_spawn_point == null:
		current_edge_label = "无合法生成点"
		_finish_run(false)
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
		var normal_count := config.get_normal_per_batch(current_wave, current_batch)
		var heavy_count := config.get_heavy_per_batch(current_wave, current_batch)
		var fast_count := config.get_fast_per_batch(current_wave, current_batch)
		if spawned_in_current_batch < normal_count:
			_spawn_enemy_at(pending_spawn_point.global_position + offset)
		elif spawned_in_current_batch < normal_count + heavy_count:
			_spawn_heavy_enemy_at(pending_spawn_point.global_position + offset)
		elif spawned_in_current_batch < normal_count + heavy_count + fast_count:
			if get_tree().get_nodes_in_group("fast_taste_enemy").size() >= config.fast_concurrent_limit:
				phase_time_left = 0.25
				return
			_spawn_fast_enemy_at(pending_spawn_point.global_position + offset)
		else:
			if get_tree().get_nodes_in_group("ranged_taste_enemy").size() >= config.ranged_concurrent_limit:
				phase_time_left = 0.25
				return
			_spawn_ranged_enemy_at(pending_spawn_point.global_position + offset)
	spawned_in_current_batch += 1
	if spawned_in_current_batch < config.get_enemies_in_batch(current_wave, current_batch):
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
	_apply_waste_scaling(enemy)
	enemy.set_chase_slot(spawned_total)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position
	enemy.reflavor_completed.connect(_on_enemy_reflavored)
	live_enemies.append(enemy)
	spawned_total += 1
	active_enemy_count += 1
	_record_enemy_spawned(&"basic")
	wave_stats_changed.emit()
	return enemy


func _spawn_heavy_enemy_at(position: Vector2) -> HeavyTasteEnemy:
	var enemy := HeavyTasteEnemy.new()
	enemy.name = "HeavyTasteEnemy_%d" % (spawned_total + 1)
	enemy.setup(config, player, navigation)
	_apply_waste_scaling(enemy)
	enemy.set_chase_slot(spawned_total)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position
	enemy.reflavor_completed.connect(_on_enemy_reflavored)
	live_enemies.append(enemy)
	spawned_total += 1
	active_enemy_count += 1
	_record_enemy_spawned(&"heavy")
	wave_stats_changed.emit()
	return enemy


func _spawn_fast_enemy_at(position: Vector2) -> FastTasteEnemy:
	var enemy := FastTasteEnemy.new()
	enemy.name = "FastTasteEnemy_%d" % (spawned_total + 1)
	enemy.setup(config, player, navigation)
	_apply_waste_scaling(enemy)
	enemy.set_chase_slot(spawned_total)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position
	enemy.reflavor_completed.connect(_on_enemy_reflavored)
	live_enemies.append(enemy)
	spawned_total += 1
	active_enemy_count += 1
	_record_enemy_spawned(&"fast")
	wave_stats_changed.emit()
	return enemy


func _spawn_ranged_enemy_at(position: Vector2) -> RangedTasteEnemy:
	var enemy := RangedTasteEnemy.new()
	enemy.name = "RangedTasteEnemy_%d" % (spawned_total + 1)
	enemy.setup(config, player, navigation)
	_apply_waste_scaling(enemy)
	enemy.set_chase_slot(spawned_total)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position
	enemy.reflavor_completed.connect(_on_enemy_reflavored)
	live_enemies.append(enemy)
	spawned_total += 1
	active_enemy_count += 1
	_record_enemy_spawned(&"ranged")
	wave_stats_changed.emit()
	return enemy


func _on_enemy_reflavored(enemy: BasicTasteEnemy) -> void:
	_settle_enemy_loot(enemy)
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.record_enemy_reflavor_completed(enemy.get_enemy_archetype_key(), enemy.get_enemy_rank_key())
	if enemy in live_enemies:
		live_enemies.erase(enemy)
		active_enemy_count = maxi(0, active_enemy_count - 1)
		reflavored_total += 1
	_check_wave_complete()
	wave_stats_changed.emit()


func settle_enemy_loot_for_test(enemy: BasicTasteEnemy) -> CarryableItem:
	return _settle_enemy_loot(enemy, true)


func _settle_enemy_loot(enemy: BasicTasteEnemy, force_normal_drop: bool = false) -> CarryableItem:
	if enemy == null or not is_instance_valid(enemy):
		return null
	var enemy_id := enemy.get_instance_id()
	if loot_settled_enemy_ids.has(enemy_id):
		return null
	loot_settled_enemy_ids[enemy_id] = true
	var enemy_type := enemy.get_enemy_archetype_key()
	var item_type := -1
	var compensated_resource: StringName = &""
	if enemy is HeavyTasteEnemy:
		item_type = ItemData.ItemType.RAW_STEAK
	else:
		var entries := _get_enemy_loot_entries(enemy_type)
		compensated_resource = _get_most_urgent_eligible_shortage(entries)
		var multiplier := _get_shortage_multiplier(compensated_resource)
		var chance := minf(1.0, _get_enemy_loot_chance(enemy_type) * multiplier)
		if force_normal_drop or random.randf() <= chance:
			item_type = _pick_weighted_loot_type(entries, compensated_resource, multiplier)
	if item_type < 0:
		return null
	var loot := _spawn_loot_item(item_type, enemy.global_position, compensated_resource)
	if loot != null:
		loot.set_meta("source_enemy_type", enemy_type)
	return loot


func _get_enemy_loot_chance(enemy_type: StringName) -> float:
	match enemy_type:
		&"fast":
			return config.fast_loot_chance
		&"ranged":
			return config.ranged_loot_chance
	return config.basic_loot_chance


func _get_enemy_loot_entries(enemy_type: StringName) -> Array:
	match enemy_type:
		&"fast":
			return [
				[ItemData.ItemType.WHOLE_GREENS, config.fast_loot_whole_greens_weight],
				[ItemData.ItemType.CHILI_SEGMENTS, config.fast_loot_chili_weight],
				[ItemData.ItemType.COOKING_OIL, config.fast_loot_oil_weight],
				[ItemData.ItemType.MARINADE, config.fast_loot_marinade_weight],
				[ItemData.ItemType.SALT, config.fast_loot_salt_weight],
			]
		&"ranged":
			return [
				[ItemData.ItemType.SALT, config.ranged_loot_salt_weight],
				[ItemData.ItemType.MARINADE, config.ranged_loot_marinade_weight],
				[ItemData.ItemType.MUSTARD, config.ranged_loot_mustard_weight],
				[ItemData.ItemType.SMALL_RICE_BAG, config.ranged_loot_small_rice_bag_weight],
				[ItemData.ItemType.CHILI_SEGMENTS, config.ranged_loot_chili_weight],
			]
	return [
		[ItemData.ItemType.COOKING_OIL, config.basic_loot_oil_weight],
		[ItemData.ItemType.SALT, config.basic_loot_salt_weight],
		[ItemData.ItemType.WHOLE_GREENS, config.basic_loot_whole_greens_weight],
		[ItemData.ItemType.CHILI_SEGMENTS, config.basic_loot_chili_weight],
		[ItemData.ItemType.MARINADE, config.basic_loot_marinade_weight],
	]


func _pick_weighted_loot_type(entries: Array, compensated_resource: StringName = &"", multiplier: float = 1.0) -> int:
	var total_weight := 0.0
	for entry in entries:
		var weight := maxf(0.0, float(entry[1]))
		if _resource_key_for_item_type(int(entry[0])) == compensated_resource:
			weight *= multiplier
		total_weight += weight
	if total_weight <= 0.0:
		return ItemData.ItemType.SALT
	var roll := random.randf_range(0.0, total_weight)
	for entry in entries:
		var weight := maxf(0.0, float(entry[1]))
		if _resource_key_for_item_type(int(entry[0])) == compensated_resource:
			weight *= multiplier
		roll -= weight
		if roll <= 0.0:
			return int(entry[0])
	return ItemData.ItemType.SALT


func _spawn_loot_item(item_type: int, position: Vector2, compensated_resource: StringName = &"") -> CarryableItem:
	var data := _create_loot_item_data(item_type)
	var loot := ItemFactory.create_carryable(data)
	get_tree().current_scene.add_child(loot)
	var offset := Vector2.RIGHT.rotated(random.randf_range(0.0, TAU)) * random.randf_range(8.0, config.loot_spawn_radius)
	loot.release_to_world(get_tree().current_scene, position + offset)
	loot.mark_as_loot_drop()
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.record_loot_spawned(data)
		if item_type == ItemData.ItemType.SMALL_RICE_BAG:
			run_stats.record_small_rice_bag_potential_healing(
				float(data.remaining_portions) * config.small_rice_bag_potential_healing_per_rice
			)
	var resource_key := _resource_key_for_item_type(item_type)
	if resource_key != &"":
		shortage_elapsed[resource_key] = 0.0
		if resource_key == RESOURCE_RICE:
			rice_drop_cooldown_left = config.shortage_rice_drop_cooldown
	if compensated_resource != &"" and resource_key == compensated_resource and run_stats != null:
		run_stats.record_compensation_spawn(data)
	return loot


func _create_loot_item_data(item_type: int) -> ItemData:
	var data := ItemCatalog.create(item_type)
	match item_type:
		ItemData.ItemType.COOKING_OIL:
			data.remaining_portions = PrototypeWaveConfig.DROP_OIL_BOTTLE_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.DROP_OIL_BOTTLE_PORTIONS
		ItemData.ItemType.SALT:
			data.remaining_portions = PrototypeWaveConfig.DROP_SALT_BOTTLE_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.DROP_SALT_BOTTLE_PORTIONS
		ItemData.ItemType.SMALL_RICE_BAG:
			data.remaining_portions = PrototypeWaveConfig.DROP_SMALL_RICE_BAG_PORTIONS
			data.max_remaining_portions = PrototypeWaveConfig.DROP_SMALL_RICE_BAG_PORTIONS
	return data


func _update_shortage_compensation(delta: float) -> void:
	rice_drop_cooldown_left = maxf(0.0, rice_drop_cooldown_left - delta)
	shortage_scan_accumulator += delta
	if shortage_scan_accumulator < config.shortage_scan_interval:
		return
	var elapsed := shortage_scan_accumulator
	shortage_scan_accumulator = 0.0
	supply_cache = (
		shortage_supply_override_for_test.duplicate(true)
		if not shortage_supply_override_for_test.is_empty()
		else _collect_team_resource_supply()
	)
	for resource_key in _all_resource_keys():
		var safe_amount := _get_resource_safe_amount(resource_key)
		if float(supply_cache.get(resource_key, 0.0)) < safe_amount:
			shortage_elapsed[resource_key] = float(shortage_elapsed.get(resource_key, 0.0)) + elapsed
			if run_stats != null:
				run_stats.add_shortage_time(resource_key, elapsed)
		else:
			shortage_elapsed[resource_key] = 0.0


func _get_most_urgent_eligible_shortage(entries: Array) -> StringName:
	if supply_cache.is_empty():
		supply_cache = (
			shortage_supply_override_for_test.duplicate(true)
			if not shortage_supply_override_for_test.is_empty()
			else _collect_team_resource_supply()
		)
	var best_key: StringName = &""
	var best_urgency := 0.0
	for entry in entries:
		var resource_key := _resource_key_for_item_type(int(entry[0]))
		if resource_key == &"" or resource_key == RESOURCE_MUSTARD:
			continue
		if resource_key == RESOURCE_RICE and rice_drop_cooldown_left > 0.0:
			continue
		if float(supply_cache.get(resource_key, 0.0)) >= _get_resource_safe_amount(resource_key):
			continue
		var delay := _get_shortage_delay(resource_key)
		var elapsed := float(shortage_elapsed.get(resource_key, 0.0))
		if elapsed <= delay:
			continue
		var urgency := (elapsed - delay) / maxf(1.0, delay)
		if urgency > best_urgency:
			best_urgency = urgency
			best_key = resource_key
	return best_key


func _get_shortage_multiplier(resource_key: StringName) -> float:
	if resource_key == &"":
		return 1.0
	var elapsed := float(shortage_elapsed.get(resource_key, 0.0))
	var delay := _get_shortage_delay(resource_key)
	if elapsed <= delay:
		return 1.0
	return minf(
		_get_shortage_max_multiplier(resource_key),
		1.0 + (elapsed - delay) / maxf(1.0, config.shortage_growth_seconds)
	)


func _get_shortage_delay(resource_key: StringName) -> float:
	match resource_key:
		RESOURCE_OIL:
			return config.shortage_oil_delay
		RESOURCE_GREENS:
			return config.shortage_greens_delay
		RESOURCE_SALT:
			return config.shortage_salt_delay
		RESOURCE_MARINADE:
			return config.shortage_marinade_delay
		RESOURCE_RICE:
			return config.shortage_rice_delay
		RESOURCE_CHILI:
			return config.shortage_chili_delay
	return INF


func _get_shortage_max_multiplier(resource_key: StringName) -> float:
	match resource_key:
		RESOURCE_OIL:
			return config.shortage_oil_max_multiplier
		RESOURCE_GREENS:
			return config.shortage_greens_max_multiplier
		RESOURCE_SALT:
			return config.shortage_salt_max_multiplier
		RESOURCE_MARINADE:
			return config.shortage_marinade_max_multiplier
		RESOURCE_RICE:
			return config.shortage_rice_max_multiplier
		RESOURCE_CHILI:
			return config.shortage_chili_max_multiplier
	return 1.0


func _get_resource_safe_amount(resource_key: StringName) -> float:
	match resource_key:
		RESOURCE_OIL:
			return config.shortage_oil_safe_portions
		RESOURCE_GREENS:
			return config.shortage_greens_safe_leaves
		RESOURCE_SALT:
			return config.shortage_salt_safe_portions
		RESOURCE_MARINADE:
			return config.shortage_marinade_safe_units
		RESOURCE_RICE:
			return config.shortage_rice_safe_equivalents
		RESOURCE_CHILI:
			return config.shortage_chili_safe_units
		RESOURCE_BEEF:
			return config.shortage_beef_safe_units
	return 0.0


func _all_resource_keys() -> Array[StringName]:
	return [
		RESOURCE_OIL,
		RESOURCE_GREENS,
		RESOURCE_SALT,
		RESOURCE_MARINADE,
		RESOURCE_RICE,
		RESOURCE_CHILI,
		RESOURCE_MUSTARD,
		RESOURCE_BEEF,
	]


func _collect_team_resource_supply() -> Dictionary:
	var supply := {}
	for resource_key in _all_resource_keys():
		supply[resource_key] = 0.0
	var seen_ids := {}
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is CarryableItem) or not is_instance_valid(node):
			continue
		var item := node as CarryableItem
		var instance_id := item.get_instance_id()
		if seen_ids.has(instance_id):
			continue
		seen_ids[instance_id] = true
		_add_item_supply(supply, item.data)
	for node in get_tree().get_nodes_in_group("stove_station"):
		if not (node is WokStation):
			continue
		var stove := node as WokStation
		if stove.cookware_item is WokItem and (stove.cookware_item as WokItem).has_oil():
			supply[RESOURCE_OIL] = float(supply[RESOURCE_OIL]) + 1.0
		elif stove.cookware_item is PanItem and (stove.cookware_item as PanItem).has_oil():
			supply[RESOURCE_OIL] = float(supply[RESOURCE_OIL]) + 1.0
		var content: ItemData = null
		if stove.cookware_item is WokItem:
			content = (stove.cookware_item as WokItem).content_data
		elif stove.cookware_item is PanItem:
			content = (stove.cookware_item as PanItem).content_data
		elif stove.cookware_item is SoupPotItem:
			content = (stove.cookware_item as SoupPotItem).content_data
		_add_item_supply(supply, content)
	return supply


func _add_item_supply(supply: Dictionary, data: ItemData) -> void:
	if data == null:
		return
	var freshness_value := FreshnessCatalog.freshness_supply_multiplier(data)
	if freshness_value <= 0.0:
		return
	match data.item_type:
		ItemData.ItemType.COOKING_OIL:
			supply[RESOURCE_OIL] = float(supply[RESOURCE_OIL]) + data.remaining_portions
		ItemData.ItemType.SALT:
			supply[RESOURCE_SALT] = float(supply[RESOURCE_SALT]) + data.remaining_portions
		ItemData.ItemType.MARINADE:
			supply[RESOURCE_MARINADE] = float(supply[RESOURCE_MARINADE]) + data.stack_count
		ItemData.ItemType.CHILI_SEGMENTS:
			supply[RESOURCE_CHILI] = float(supply[RESOURCE_CHILI]) + data.stack_count
		ItemData.ItemType.MUSTARD:
			supply[RESOURCE_MUSTARD] = float(supply[RESOURCE_MUSTARD]) + data.stack_count
		ItemData.ItemType.WHOLE_GREENS:
			supply[RESOURCE_GREENS] = float(supply[RESOURCE_GREENS]) + 5.0 * freshness_value
		ItemData.ItemType.GREENS_LEAF:
			supply[RESOURCE_GREENS] = float(supply[RESOURCE_GREENS]) + maxi(data.leaf_count, data.stack_count) * freshness_value
		ItemData.ItemType.RICE_BAG, ItemData.ItemType.SMALL_RICE_BAG:
			supply[RESOURCE_RICE] = float(supply[RESOURCE_RICE]) + data.remaining_portions
		ItemData.ItemType.RAW_RICE:
			supply[RESOURCE_RICE] = float(supply[RESOURCE_RICE]) + data.stack_count
		ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE, \
		ItemData.ItemType.UNPLATED_RICE_PORRIDGE, ItemData.ItemType.PLATED_RICE_PORRIDGE, \
		ItemData.ItemType.UNPLATED_GREENS_PORRIDGE, ItemData.ItemType.PLATED_GREENS_PORRIDGE, \
		ItemData.ItemType.UNPLATED_BEEF_PORRIDGE, ItemData.ItemType.PLATED_BEEF_PORRIDGE, \
		ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE, ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE, \
		ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE, \
		ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE, ItemData.ItemType.PLATED_GREENS_FRIED_RICE, \
		ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_BEEF_FRIED_RICE, \
		ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_MIXED_FRIED_RICE, \
		ItemData.ItemType.UNPLATED_VEGETABLE_RICE, ItemData.ItemType.PLATED_VEGETABLE_RICE, \
		ItemData.ItemType.UNPLATED_SOAKED_RICE, ItemData.ItemType.PLATED_SOAKED_RICE, \
		ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_SOAKED_RICE, \
		ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL:
			supply[RESOURCE_RICE] = float(supply[RESOURCE_RICE]) + freshness_value
		ItemData.ItemType.RAW_BEEF_CHUNK:
			supply[RESOURCE_BEEF] = float(supply[RESOURCE_BEEF]) + 3.0 * freshness_value
		ItemData.ItemType.RAW_STEAK, ItemData.ItemType.RAW_BEEF_SLICES, \
		ItemData.ItemType.MARINATED_BEEF_SLICES, ItemData.ItemType.RAW_BEEF_DICE, \
		ItemData.ItemType.MARINATED_BEEF_DICE, ItemData.ItemType.TOMAHAWK_STEAK, \
		ItemData.ItemType.PLATED_TOMAHAWK_STEAK, ItemData.ItemType.UNPLATED_STIR_FRY_BEEF, \
		ItemData.ItemType.PLATED_STIR_FRY_BEEF:
			supply[RESOURCE_BEEF] = float(supply[RESOURCE_BEEF]) + freshness_value


func _resource_key_for_item_type(item_type: int) -> StringName:
	match item_type:
		ItemData.ItemType.COOKING_OIL:
			return RESOURCE_OIL
		ItemData.ItemType.WHOLE_GREENS:
			return RESOURCE_GREENS
		ItemData.ItemType.SALT:
			return RESOURCE_SALT
		ItemData.ItemType.MARINADE:
			return RESOURCE_MARINADE
		ItemData.ItemType.RICE_BAG, ItemData.ItemType.SMALL_RICE_BAG, ItemData.ItemType.RAW_RICE:
			return RESOURCE_RICE
		ItemData.ItemType.CHILI_SEGMENTS:
			return RESOURCE_CHILI
		ItemData.ItemType.MUSTARD:
			return RESOURCE_MUSTARD
		ItemData.ItemType.RAW_BEEF_CHUNK, ItemData.ItemType.RAW_STEAK:
			return RESOURCE_BEEF
	return &""


func _record_enemy_spawned(enemy_type: StringName) -> void:
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		run_stats.record_enemy_spawned(enemy_type, &"ordinary")


func set_shortage_supply_override_for_test(supply: Dictionary) -> void:
	shortage_supply_override_for_test = supply.duplicate(true)
	supply_cache = shortage_supply_override_for_test.duplicate(true)


func clear_shortage_supply_override_for_test() -> void:
	shortage_supply_override_for_test.clear()
	supply_cache.clear()


func force_shortage_update_for_test(delta: float) -> void:
	_update_shortage_compensation(delta)


func get_team_supply_snapshot() -> Dictionary:
	return _collect_team_resource_supply()


func get_shortage_multiplier_for_test(resource_key: StringName) -> float:
	return _get_shortage_multiplier(resource_key)


func _check_wave_complete() -> void:
	var planned_total := config.get_planned_enemy_total(current_wave)
	if current_batch >= config.get_total_batches(current_wave) and spawned_total >= planned_total and active_enemy_count == 0 and reflavored_total >= planned_total:
		next_batch_left = 0.0
		current_edge_label = ""
		completed_waves = current_wave
		if current_wave >= config.run_total_waves:
			_finish_run(true)
		else:
			current_wave += 1
			phase = Phase.INTERMISSION
			preparation_left = config.intermission_time
			if player != null:
				player.restore_shield_for_wave()
			_reset_wave_counters_only()
		wave_stats_changed.emit()


func _on_player_defeated() -> void:
	if phase in [Phase.RUN_COMPLETE, Phase.FAILED]:
		return
	if phase == Phase.FREE_PREPARATION:
		player.reset_wave_health()
		player.notify_feedback("自由大厅测试倒地：已恢复生命")
		return
	_finish_run(false)


func _finish_run(success: bool) -> void:
	phase = Phase.RUN_COMPLETE if success else Phase.FAILED
	if freshness_manager != null:
		# Flush the final authoritative freshness interval while RunStats is
		# still accepting events, then freeze the run clock for settlement.
		freshness_manager.finish_formal_run()
	if run_stats == null:
		run_stats = get_tree().get_first_node_in_group("run_stats") as RunStats
	if run_stats != null:
		var leftovers := _collect_world_loot_snapshot()
		run_stats.capture_resource_end_state(
			_collect_team_resource_supply(),
			leftovers["items"],
			leftovers["portions"]
		)
		run_stats.finish_run()
	if player != null:
		player.set_modal_ui_open(true)
	if not success:
		for enemy in live_enemies:
			if is_instance_valid(enemy):
				enemy.disable_for_failed_wave()
	run_finished.emit(success)
	wave_stats_changed.emit()


func _set_test_dummies_active(active: bool) -> void:
	for node in get_tree().get_nodes_in_group("debug_combat_target"):
		if node is DebugCombatTarget:
			(node as DebugCombatTarget).set_lobby_active(active)


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
			ItemData.ItemType.RICE_BAG: config.rice_bag_stock,
			ItemData.ItemType.WHOLE_GREENS: config.whole_greens_stock,
		})
	var pile := get_tree().get_first_node_in_group("clean_plate_pile") as CleanPlatePile
	if pile != null:
		pile.configure_initial_stock(config.clean_plate_stock)
	var cutting_board := get_tree().get_first_node_in_group("cutting_board") as CuttingBoard
	if cutting_board != null:
		cutting_board.prototype_first_cut_time = config.first_cut_time
		cutting_board.prototype_second_cut_time = config.second_cut_time
		cutting_board.prototype_dice_cut_time = config.dice_cut_time
	var marinating_station := get_tree().get_first_node_in_group("marinating_station") as MarinatingStation
	if marinating_station != null:
		marinating_station.prototype_marinating_time = config.marinating_time


func _reset_scene_for_new_game() -> void:
	loot_settled_enemy_ids.clear()
	shortage_elapsed.clear()
	for resource_key in _all_resource_keys():
		shortage_elapsed[resource_key] = 0.0
	shortage_scan_accumulator = 0.0
	rice_drop_cooldown_left = 0.0
	supply_cache.clear()
	shortage_supply_override_for_test.clear()
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
		player.reset_for_new_game(
			config.player_max_health,
			config.player_hit_protection_time,
			config.player_max_shield,
			config.player_shield_regen_delay,
			config.player_shield_regen_per_second
		)
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


func _apply_waste_scaling(enemy: BasicTasteEnemy) -> void:
	if enemy == null:
		return
	if freshness_manager == null:
		freshness_manager = get_tree().get_first_node_in_group("freshness_manager") as FreshnessManager
	var health_multiplier := freshness_manager.get_enemy_health_multiplier() if freshness_manager != null else 1.0
	var damage_multiplier := freshness_manager.get_enemy_damage_multiplier() if freshness_manager != null else 1.0
	enemy.apply_spawn_waste_multipliers(health_multiplier, damage_multiplier)


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


func _collect_world_loot_snapshot() -> Dictionary:
	var items := {}
	var portions := {}
	for node in get_tree().get_nodes_in_group("loot_drop"):
		if not (node is CarryableItem) or not is_instance_valid(node):
			continue
		var item := node as CarryableItem
		if item.data == null:
			continue
		var keys := ItemData.ItemType.keys()
		var key := StringName(str(keys[item.data.item_type]).to_lower())
		items[key] = int(items.get(key, 0)) + 1
		var amount := item.data.remaining_portions if item.data.is_reusable_resource_container() else maxi(1, item.data.stack_count)
		portions[key] = int(portions.get(key, 0)) + amount
	return {"items": items, "portions": portions}
