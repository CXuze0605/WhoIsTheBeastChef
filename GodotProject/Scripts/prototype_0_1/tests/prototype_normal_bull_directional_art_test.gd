extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_resource_structure()
	await _test_eight_direction_runtime_selection()
	await _test_animation_stability_and_visual_contract()
	await _test_combat_motion_contract()
	if failures.is_empty():
		print("PROTOTYPE_NORMAL_BULL_DIRECTIONAL_ART_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_NORMAL_BULL_DIRECTIONAL_ART_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_resource_structure() -> void:
	var bull := await _spawn_bull(Vector2.RIGHT)
	var animator := bull.visual_animator
	var sprite := animator.sprite if animator != null else null
	var frames := sprite.sprite_frames if sprite != null else null
	_expect(animator != null and sprite != null and frames != null, "Normal bull art: the runtime projectile must expose an AnimatedSprite2D animator")
	if frames != null:
		_expect(
			frames.resource_path == "%s/stir_fry_normal_bull_01_sprite_frames.tres" % NormalBullVisualAnimator.ASSET_ROOT,
			"Normal bull art: the eight-direction animation set must be stored as an editor-visible SpriteFrames resource"
		)
		_expect(frames.get_animation_names().size() == 8, "Normal bull art: exactly eight directional run animations must exist")
		for direction in NormalBullVisualAnimator.DIRECTIONS:
			var animation_name := StringName("run_%s" % direction)
			_expect(frames.has_animation(animation_name), "Normal bull art: missing %s" % animation_name)
			_expect(frames.get_frame_count(animation_name) == 6, "Normal bull art: %s must preserve all six native frames" % animation_name)
			_expect(frames.get_animation_speed(animation_name) == 12.0 and frames.get_animation_loop(animation_name), "Normal bull art: %s must loop at 12 FPS" % animation_name)
	bull.queue_free()
	await process_frame


func _test_eight_direction_runtime_selection() -> void:
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
		var bull := await _spawn_bull(direction)
		var sprite := bull.visual_animator.sprite
		_expect(sprite.animation == StringName("run_%s" % expected), "Normal bull art: %s flight must use its native directional frames" % expected)
		_expect(not sprite.flip_h and is_zero_approx(bull.rotation), "Normal bull art: directional frames must not be mirrored or rotated as a whole")
		bull.queue_free()
		await process_frame


func _test_animation_stability_and_visual_contract() -> void:
	var bull := await _spawn_bull(Vector2.RIGHT)
	var animator := bull.visual_animator
	var sprite := animator.sprite
	sprite.frame = 3
	animator.set_direction(Vector2.RIGHT)
	_expect(sprite.frame == 3, "Normal bull art: repeating the same direction must not restart animation from frame zero")
	_expect(sprite.position == Vector2.ZERO and sprite.scale == Vector2.ONE * 2.0, "Normal bull art: use the retained origin and crisp integer 2x display scale")
	_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Normal bull art: use nearest filtering")
	_expect(bull.visual.art_sprite != null and not bull.visual.art_sprite.visible, "Normal bull art: the old fallback texture must be hidden while the directional animation is active")
	_expect(not bull.visual.title_label.visible and not bull.visual.status_label.visible, "Normal bull art: placeholder labels must not cover the projectile animation")
	_expect(ResourceLoader.exists("res://Assets/Prototype/Static/normal_bull.png"), "Normal bull art: the old static source must remain available for rollback")
	_expect(ResourceLoader.exists("%s/metadata.json" % NormalBullVisualAnimator.ASSET_ROOT), "Normal bull art: PixelLab metadata must remain beside the original frames")
	bull.queue_free()
	await process_frame


func _test_combat_motion_contract() -> void:
	var bull := await _spawn_bull(Vector2(1.0, 1.0))
	var original_direction := bull.direction
	var original_position := bull.global_position
	bull._physics_process(0.02)
	var expected_delta := original_direction * bull.config.normal_bull_speed * 0.02
	_expect(bull.direction == original_direction, "Normal bull art: visual direction selection must not change the locked attack direction")
	_expect(bull.global_position.is_equal_approx(original_position + expected_delta), "Normal bull art: movement must still use the existing speed and direction")
	_expect(
		bull.config.normal_bull_distance == 430.0
		and bull.config.normal_bull_width == 76.0
		and bull.config.normal_bull_knockback == 42.0,
		"Normal bull art: range, hit width, and knockback values must remain unchanged"
	)
	bull.queue_free()
	await process_frame


func _spawn_bull(direction: Vector2) -> NormalBull:
	var bull := NormalBull.new()
	bull.setup(Vector2(400.0, 400.0), direction, 10.0, PrototypeCombatConfig.new())
	root.add_child(bull)
	await process_frame
	return bull


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
