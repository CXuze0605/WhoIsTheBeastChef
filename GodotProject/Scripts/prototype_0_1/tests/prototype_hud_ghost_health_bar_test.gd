extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_01_ghost_bar_lingers_on_damage()
	await _test_02_ghost_bar_syncs_on_heal()
	if failures.is_empty():
		print("PROTOTYPE_HUD_GHOST_HEALTH_BAR_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_HUD_GHOST_HEALTH_BAR_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_01_ghost_bar_lingers_on_damage() -> void:
	var scene := await _spawn_main_scene(false)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	_expect(hud != null and hud.ghost_health_bar != null, "01: ghost health bar must exist")
	_expect(hud.health_bar.value == 100.0 and hud.ghost_health_bar.value == 100.0, "01: fresh run must start with synced ghost bar")
	player.set_modal_ui_open(false)
	player.receive_combat_hit(50.0, CombatRules.Faction.ENEMY, Vector2.RIGHT, 0.0, false)
	_expect(hud.health_bar.value == 80.0, "01: main health bar must drop immediately")
	_expect(hud.ghost_health_bar.value == 100.0, "01: ghost bar must linger at previous value right after damage")
	await create_timer(1.2).timeout
	_expect(absf(hud.ghost_health_bar.value - 80.0) < 1.0, "01: ghost bar must catch up toward current health immediately")
	await _dispose_scene(scene)


func _test_02_ghost_bar_syncs_on_heal() -> void:
	var scene := await _spawn_main_scene(false)
	var player := scene.get_node("Kitchen/Player") as PrototypePlayer
	var hud := scene.get_node("PlayerHUD") as PlayerHUD
	player.set_modal_ui_open(false)
	player.receive_combat_hit(50.0, CombatRules.Faction.ENEMY, Vector2.RIGHT, 0.0, false)
	await create_timer(0.2).timeout
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.phase = PrototypeWaveManager.Phase.FAILED
	manager.start_game()
	_expect(hud.health_bar.value == 100.0 and hud.ghost_health_bar.value == 100.0, "02: restarting a failed run must sync ghost bar immediately on heal")
	await _dispose_scene(scene)


func _spawn_main_scene(start_game: bool) -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	if packed == null:
		_expect(false, "Unable to load Prototype main scene")
		return null
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	if start_game:
		(scene.get_node("WaveManager") as PrototypeWaveManager).start_game()
		await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)