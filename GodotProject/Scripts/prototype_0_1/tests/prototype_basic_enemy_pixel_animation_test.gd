extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var enemy := manager.spawn_enemy_for_test(Vector2(900.0, 700.0))
	enemy.set_physics_process(false)
	_test_resource_structure(enemy)
	_test_eight_direction_mapping(enemy)
	_test_slow_attack_and_stability(enemy)
	_test_defeat_and_scene_contracts(enemy)
	_test_other_enemy_art_isolation(manager)
	await _dispose_scene(scene)
	if failures.is_empty():
		print("PROTOTYPE_BASIC_ENEMY_PIXEL_ANIMATION_TEST: PASS (5/5 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_BASIC_ENEMY_PIXEL_ANIMATION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_resource_structure(enemy: BasicTasteEnemy) -> void:
	var animator := enemy.character_animator
	var sprite := animator.sprite if animator != null else null
	var frames := sprite.sprite_frames if sprite != null else null
	_expect(animator != null and sprite != null and frames != null, "Basic enemy art: ordinary Taste Enemy must expose an AnimatedSprite2D animator")
	if frames == null:
		return
	_expect(
		frames.resource_path == "%s/basic_taste_enemy_01_sprite_frames.tres" % BasicEnemyCharacterAnimator.ASSET_ROOT,
		"Basic enemy art: the animation set must be stored as an editor-visible SpriteFrames resource"
	)
	_expect(frames.get_animation_names().size() == 30, "Basic enemy art: 8 idle + 8 run + 8 slow run + 4 attacks + defeat + preserved SE variant must exist")
	for direction in BasicEnemyCharacterAnimator.DIRECTIONS:
		var idle_name := StringName("idle_%s" % direction)
		var run_name := StringName("run_%s" % direction)
		var slow_name := StringName("slow_run_%s" % direction)
		_expect(frames.get_frame_count(idle_name) == 1, "Basic enemy art: %s must preserve its rotation reference" % idle_name)
		_expect(frames.get_frame_count(run_name) == 6, "Basic enemy art: %s must preserve all six native run frames" % run_name)
		_expect(frames.get_frame_count(slow_name) == 6, "Basic enemy art: %s must preserve all six slowed run frames" % slow_name)
	for direction in ["south", "east", "north", "west"]:
		var attack_name := StringName("attack_%s" % direction)
		_expect(frames.get_frame_count(attack_name) == 3 and not frames.get_animation_loop(attack_name), "Basic enemy art: %s must preserve three non-looping jab frames" % attack_name)
	_expect(frames.get_animation_speed(&"run_south") == 8.0, "Basic enemy art: normal run must use 8 FPS")
	_expect(frames.get_animation_speed(&"slow_run_south") == 5.0, "Basic enemy art: slowed movement must use the 5 FPS run fallback")
	_expect(frames.get_animation_speed(&"attack_south") == 8.0, "Basic enemy art: jab playback must use 8 FPS")
	_expect(frames.get_frame_count(&"defeat_fall") == 7 and not frames.get_animation_loop(&"defeat_fall"), "Basic enemy art: defeat_fall must preserve seven south frames and play once")


func _test_eight_direction_mapping(enemy: BasicTasteEnemy) -> void:
	var animator := enemy.character_animator
	var cases := [
		[Vector2.DOWN, "south"],
		[Vector2(1.0, 1.0), "south-east"],
		[Vector2.RIGHT, "east"],
		[Vector2(1.0, -1.0), "north-east"],
		[Vector2.UP, "north"],
		[Vector2(-1.0, -1.0), "north-west"],
		[Vector2.LEFT, "west"],
		[Vector2(-1.0, 1.0), "south-west"],
	]
	for entry in cases:
		var direction: Vector2 = entry[0]
		var expected: String = entry[1]
		animator.update_animation(direction, false, false, false)
		_expect(animator.sprite.animation == StringName("run_%s" % expected), "Basic enemy art: moving %s must use its native run direction" % expected)
		animator.update_animation(Vector2.ZERO, false, false, false)
		_expect(animator.sprite.animation == StringName("idle_%s" % expected), "Basic enemy art: stopping after %s must keep the last direction" % expected)
		_expect(not animator.sprite.flip_h, "Basic enemy art: native directions must never use horizontal mirroring")


func _test_slow_attack_and_stability(enemy: BasicTasteEnemy) -> void:
	var animator := enemy.character_animator
	animator.update_animation(Vector2.RIGHT, true, false, false)
	_expect(animator.sprite.animation == &"slow_run_east", "Basic enemy art: slowed movement must select the slow run playback")
	animator.sprite.frame = 3
	animator.update_animation(Vector2.RIGHT, true, false, false)
	_expect(animator.sprite.frame == 3, "Basic enemy art: an unchanged movement animation must not restart from frame zero")
	animator.update_animation(Vector2.ZERO, false, true, false, Vector2(1.0, 1.0))
	_expect(animator.sprite.animation == &"attack_east", "Basic enemy art: a diagonal jab must map to the nearest available cardinal take")
	animator.sprite.frame = 2
	animator.update_animation(Vector2.ZERO, false, true, false, Vector2(1.0, 1.0))
	_expect(animator.sprite.frame == 2, "Basic enemy art: repeated windup/attack refreshes must not restart the jab")


func _test_defeat_and_scene_contracts(enemy: BasicTasteEnemy) -> void:
	enemy.state = BasicTasteEnemy.State.REFLAVORING
	enemy._refresh_visual()
	var animator := enemy.character_animator
	_expect(animator.sprite.animation == &"defeat_fall", "Basic enemy art: reflavor exit must play the one-shot south defeat fallback")
	animator.sprite.frame = 4
	enemy._refresh_visual()
	_expect(animator.sprite.frame == 4 and animator.sprite.animation == &"defeat_fall", "Basic enemy art: state refresh must not restart defeat_fall")
	var collision: CollisionShape2D
	for child in enemy.get_children():
		if child is CollisionShape2D:
			collision = child as CollisionShape2D
			break
	var shape := collision.shape as CircleShape2D if collision != null else null
	_expect(animator.sprite.position == Vector2.ZERO and animator.sprite.scale == Vector2.ONE, "Basic enemy art: use native 1x scale at the retained visual origin")
	_expect(animator.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Basic enemy art: use nearest filtering")
	_expect(shape != null and shape.radius == 14.0, "Basic enemy art: visual replacement must not change the ordinary enemy collision radius")
	_expect(enemy.move_speed_value == enemy.config.enemy_move_speed, "Basic enemy art: visual replacement must not change movement speed")
	_expect(ResourceLoader.exists("res://Assets/Prototype/Static/basic_taste_enemy.png"), "Basic enemy art: the previous static source must remain available for rollback")
	_expect(ResourceLoader.exists("res://Assets/Prototype/Animation/Characters/basic_taste_enemy_walk_sheet.png"), "Basic enemy art: the previous walk sheet must remain available for rollback")
	_expect(ResourceLoader.exists("%s/metadata.json" % BasicEnemyCharacterAnimator.ASSET_ROOT), "Basic enemy art: PixelLab metadata must remain beside the source frames")


func _test_other_enemy_art_isolation(manager: PrototypeWaveManager) -> void:
	var heavy := manager.spawn_heavy_enemy_for_test(Vector2(980.0, 700.0))
	heavy.set_physics_process(false)
	_expect(heavy.character_animator == null and heavy.walk_animator != null, "Basic enemy art: heavy Taste Enemy must retain its dedicated existing art")
	var fast := manager.spawn_fast_enemy_for_test(Vector2(1060.0, 700.0))
	fast.set_physics_process(false)
	_expect(
		fast.character_animator == null
		and fast.walk_animator == null
		and fast.fast_character_animator != null,
		"Basic enemy art: fast Taste Enemy must remain isolated on its dedicated candidate animation path"
	)
	var ranged := manager.spawn_ranged_enemy_for_test(Vector2(1140.0, 700.0))
	ranged.set_physics_process(false)
	_expect(ranged.character_animator == null and ranged.walk_animator != null, "Basic enemy art: ranged Taste Enemy must remain outside the ordinary-enemy replacement")


func _spawn_main_scene() -> Node:
	var packed := load("res://Scenes/prototype_0_1/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _dispose_scene(scene: Node) -> void:
	if paused:
		paused = false
	if current_scene == scene:
		current_scene = null
	scene.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
