extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := await _spawn_main_scene()
	var manager := scene.get_node("WaveManager") as PrototypeWaveManager
	manager.set_process(false)
	var enemy := manager.spawn_fast_enemy_for_test(Vector2(900.0, 700.0))
	enemy.set_physics_process(false)
	_test_resource_structure(enemy)
	_test_eight_direction_mapping(enemy)
	_test_crouch_and_pounce_are_one_attack(enemy)
	_test_visual_and_combat_contracts(enemy)
	await _dispose_scene(scene)
	if failures.is_empty():
		print("PROTOTYPE_FAST_ENEMY_PIXEL_ANIMATION_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_FAST_ENEMY_PIXEL_ANIMATION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_resource_structure(enemy: FastTasteEnemy) -> void:
	var animator := enemy.fast_character_animator
	var sprite := animator.sprite if animator != null else null
	var frames := sprite.sprite_frames if sprite != null else null
	_expect(animator != null and sprite != null and frames != null, "Fast enemy art: speed-type enemy must expose its dedicated AnimatedSprite2D animator")
	if frames == null:
		return
	_expect(
		frames.resource_path == "%s/fast_taste_enemy_01_sprite_frames.tres" % FastEnemyCharacterAnimator.ASSET_ROOT,
		"Fast enemy art: the animation set must be stored as an editor-visible SpriteFrames resource"
	)
	_expect(frames.get_animation_names().size() == 41, "Fast enemy art: 8 idle + 8 run + 8 slow run + 8 crouch + 8 pounce + defeat must exist")
	for direction in FastEnemyCharacterAnimator.DIRECTIONS:
		_expect(frames.get_frame_count(StringName("idle_%s" % direction)) == 1, "Fast enemy art: idle_%s must preserve its rotation reference" % direction)
		_expect(frames.get_frame_count(StringName("run_%s" % direction)) == 6, "Fast enemy art: run_%s must preserve all six frames" % direction)
		_expect(frames.get_frame_count(StringName("crouch_%s" % direction)) == 5, "Fast enemy art: crouch_%s must preserve all five charge frames" % direction)
		_expect(frames.get_frame_count(StringName("pounce_%s" % direction)) == 8, "Fast enemy art: pounce_%s must preserve all eight attack frames" % direction)
		_expect(not frames.get_animation_loop(StringName("crouch_%s" % direction)), "Fast enemy art: crouch_%s must be a one-shot charge" % direction)
		_expect(not frames.get_animation_loop(StringName("pounce_%s" % direction)), "Fast enemy art: pounce_%s must be a one-shot leap" % direction)
	_expect(is_equal_approx(frames.get_animation_speed(&"crouch_south"), FastEnemyCharacterAnimator.CROUCH_FPS), "Fast enemy art: crouch playback must cover the existing 0.60 second charge")
	_expect(is_equal_approx(frames.get_animation_speed(&"pounce_south"), FastEnemyCharacterAnimator.POUNCE_FPS), "Fast enemy art: pounce playback must cover the existing 0.36 second dash")
	_expect(frames.get_frame_count(&"defeat_fall") == 7 and not frames.get_animation_loop(&"defeat_fall"), "Fast enemy art: defeat_fall must preserve seven south frames and play once")


func _test_eight_direction_mapping(enemy: FastTasteEnemy) -> void:
	var animator := enemy.fast_character_animator
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
		animator.update_animation(FastEnemyCharacterAnimator.ActionPhase.NONE, direction, direction, false, false)
		_expect(animator.sprite.animation == StringName("run_%s" % expected), "Fast enemy art: chase toward %s must use its native run" % expected)
		animator.update_animation(FastEnemyCharacterAnimator.ActionPhase.NONE, Vector2.ZERO, direction, false, false)
		_expect(animator.sprite.animation == StringName("idle_%s" % expected), "Fast enemy art: stopping after %s must keep that direction" % expected)
		animator.update_animation(FastEnemyCharacterAnimator.ActionPhase.CHARGING, Vector2.ZERO, direction, false, false)
		_expect(animator.sprite.animation == StringName("crouch_%s" % expected), "Fast enemy art: charge toward %s must use its native crouch" % expected)
		animator.update_animation(FastEnemyCharacterAnimator.ActionPhase.POUNCING, direction, direction, false, false)
		_expect(animator.sprite.animation == StringName("pounce_%s" % expected), "Fast enemy art: dash toward %s must use its native pounce" % expected)
		_expect(not animator.sprite.flip_h, "Fast enemy art: native directions must never use mirroring")


func _test_crouch_and_pounce_are_one_attack(enemy: FastTasteEnemy) -> void:
	var animator := enemy.fast_character_animator
	enemy.dash_direction = Vector2.RIGHT
	enemy.state = FastTasteEnemy.STATE_CHARGING
	enemy._refresh_visual()
	_expect(animator.sprite.animation == &"crouch_east", "Fast enemy art: existing charge state must begin the crouching phase")
	animator.sprite.frame = 3
	enemy._refresh_visual()
	_expect(animator.sprite.frame == 3, "Fast enemy art: charge refresh must not restart crouching from frame zero")
	enemy.state = FastTasteEnemy.STATE_DASHING
	enemy._refresh_visual()
	_expect(animator.sprite.animation == &"pounce_east" and animator.sprite.frame == 0, "Fast enemy art: the same attack must transition from crouch to pounce")
	animator.sprite.frame = 5
	enemy.state = FastTasteEnemy.STATE_DASH_RECOVERY
	enemy._refresh_visual()
	_expect(animator.sprite.animation == &"pounce_east" and animator.sprite.frame == 5, "Fast enemy art: recovery must finish/hold the pounce instead of restarting it")
	enemy._update_dash_pose()
	_expect(enemy.placeholder.scale == Vector2.ONE, "Fast enemy art: native crouch frames must replace the old whole-node squash")


func _test_visual_and_combat_contracts(enemy: FastTasteEnemy) -> void:
	var animator := enemy.fast_character_animator
	var collision: CollisionShape2D
	for child in enemy.get_children():
		if child is CollisionShape2D:
			collision = child as CollisionShape2D
			break
	var shape := collision.shape as CircleShape2D if collision != null else null
	_expect(animator.sprite.position == FastEnemyCharacterAnimator.GROUND_ANCHOR_POSITION and animator.sprite.scale == Vector2.ONE * FastEnemyCharacterAnimator.DISPLAY_SCALE, "Fast enemy art: use the restaurant-scale integer 2x presentation while retaining its foot point")
	_expect(animator.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Fast enemy art: use nearest filtering")
	_expect(enemy.walk_animator == null and enemy.placeholder.art_sprite != null and not enemy.placeholder.art_sprite.visible, "Fast enemy art: old sheet must remain only as a hidden rollback fallback")
	_expect(shape != null and shape.radius == 13.0, "Fast enemy art: visual replacement must not change the speed enemy collision radius")
	_expect(enemy.move_speed_value == enemy.config.enemy_move_speed * enemy.config.fast_move_speed_multiplier, "Fast enemy art: visual replacement must not change chase speed")
	_expect(enemy.config.fast_dash_damage == 18.0 and enemy.config.fast_charge_windup_time == 0.60 and enemy.config.fast_dash_time == 0.36, "Fast enemy art: charge/dash combat values must remain unchanged")
	_expect(ResourceLoader.exists("res://Assets/Prototype/Animation/Characters/fast_taste_enemy_walk_sheet.png"), "Fast enemy art: previous walk sheet must remain available for rollback")
	_expect(ResourceLoader.exists("%s/metadata.json" % FastEnemyCharacterAnimator.ASSET_ROOT), "Fast enemy art: PixelLab metadata must remain beside the source frames")
	enemy.state = BasicTasteEnemy.State.REFLAVORING
	enemy._refresh_visual()
	_expect(animator.sprite.animation == &"defeat_fall", "Fast enemy art: reflavor exit must play the one-shot south defeat fallback")


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
