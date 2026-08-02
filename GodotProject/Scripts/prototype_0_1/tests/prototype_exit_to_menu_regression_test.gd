extends SceneTree

const MENU_SCENE := "res://Scenes/menu/main_menu.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _run() -> void:
	await _test_lobby_fill_then_exit_to_menu_survives()
	if failures.is_empty():
		print("PROTOTYPE_EXIT_TO_MENU_REGRESSION_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_EXIT_TO_MENU_REGRESSION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_lobby_fill_then_exit_to_menu_survives() -> void:
	# 复现“退出测试大厅返回主菜单”的时序竞争：return_to_lobby() 会启动延迟
	# 2 帧的大厅柜填充协程；若在协程恢复前切走场景，协程不得对已离开场景
	# 树的节点产生空实例错误，游戏必须仍能回到主菜单。
	var menu := await _spawn_scene(MENU_SCENE)
	_expect(menu != null, "exit: main menu must spawn")
	await _wait_frames(3)
	var th := menu.find_child("TestHallButton", true, false) as Button
	_expect(th != null, "exit: TestHallButton must exist")
	if th == null:
		return
	th.pressed.emit()
	for i in range(300):
		await process_frame
		if current_scene != menu:
			break
	var gameplay := current_scene
	_expect(gameplay != null and gameplay.name == "Prototype01Main", "exit: must enter test hall")
	await _wait_frames(3)
	var wm := gameplay.get_node_or_null("WaveManager")
	_expect(wm != null, "exit: WaveManager must exist")
	if wm == null:
		return
	# 同帧触发延迟填充 + 切场景，构造协程恢复时节点已离树的竞争窗口。
	wm.call("return_to_lobby")
	var err := change_scene_to_file(MENU_SCENE)
	_expect(err == OK, "exit: change scene to menu must return OK")
	await _wait_frames(8)
	_expect(current_scene != null and current_scene.name == "MainMenu", "exit: must arrive at main menu alive")


func _spawn_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	var scene := packed.instantiate() as Node
	root.add_child(scene)
	current_scene = scene
	await process_frame
	return scene


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
