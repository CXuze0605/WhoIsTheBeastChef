extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_resource_structure()
	await _test_eight_direction_runtime_selection()
	await _test_reflection_and_random_turn_refresh()
	await _test_visual_and_combat_contracts()
	if failures.is_empty():
		print("PROTOTYPE_RAGING_BULL_DIRECTIONAL_ART_TEST: PASS (4/4 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_RAGING_BULL_DIRECTIONAL_ART_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_resource_structure() -> void:
	var bull := await _spawn_bull(Vector2.RIGHT)
	var animator := bull.visual_animator
	var sprite := animator.sprite if animator != null else null
	var frames := sprite.sprite_frames if sprite != null else null
	_expect(animator != null and sprite != null and frames != null, "Raging bull art: the perfect finisher must expose an AnimatedSprite2D animator")
	if frames != null:
		_expect(
			frames.resource_path == "%s/stir_fry_raging_bull_01_sprite_frames.tres" % RagingBullVisualAnimator.ASSET_ROOT,
			"Raging bull art: the directional animation set must be stored as an editor-visible SpriteFrames resource"
		)
		_expect(frames.get_animation_names().size() == 9, "Raging bull art: eight active directions plus the preserved north variant must exist")
		for direction in RagingBullVisualAnimator.DIRECTIONS:
			var animation_name := StringName("run_%s" % direction)
			_expect(frames.has_animation(animation_name), "Raging bull art: missing %s" % animation_name)
			_expect(frames.get_frame_count(animation_name) == 8, "Raging bull art: %s must preserve all eight native frames" % animation_name)
			_expect(frames.get_animation_speed(animation_name) == 10.0 and frames.get_animation_loop(animation_name), "Raging bull art: %s must loop at 10 FPS" % animation_name)
		_expect(frames.get_frame_count(&"run_north_variant") == 8, "Raging bull art: the second north take must be preserved")
		var active_north := frames.get_frame_texture(&"run_north", 0)
		_expect(
			active_north != null and active_north.resource_path.contains("north-b6f811d6"),
			"Raging bull art: the north take matching the rotation reference must be the active direction"
		)
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
		_expect(sprite.animation == StringName("run_%s" % expected), "Raging bull art: %s travel must use its native directional animation" % expected)
		_expect(not sprite.flip_h and is_zero_approx(bull.rotation), "Raging bull art: native directions must not mirror or rotate the whole node")
		bull.queue_free()
		await process_frame


func _test_reflection_and_random_turn_refresh() -> void:
	var reflected := await _spawn_bull(Vector2.RIGHT)
	var bounds := reflected.config.combat_bounds
	reflected.global_position = Vector2(
		bounds.end.x - reflected.config.raging_bull_radius - 2.0,
		bounds.get_center().y
	)
	reflected._move_and_reflect(0.2)
	_expect(reflected.reflection_count >= 1 and reflected.direction.x < 0.0, "Raging bull art: wall reflection must retain the established direction change")
	_expect(reflected.visual_animator.sprite.animation == &"run_west", "Raging bull art: wall reflection must immediately select the reflected native direction")
	reflected.queue_free()
	await process_frame

	var turned := await _spawn_bull(Vector2.RIGHT)
	turned.force_random_turn_warning_for_test(Vector2.UP)
	_expect(turned.visual.status_label.text == "转向预警！", "Raging bull art: the existing random-turn warning must remain visible")
	turned._update_random_turn(turned.config.random_turn_warning_time + 0.01)
	_expect(turned.direction == Vector2.UP, "Raging bull art: warning completion must retain the established locked random turn")
	_expect(turned.visual_animator.sprite.animation == &"run_north", "Raging bull art: completed random turn must immediately select its new native direction")
	turned.queue_free()
	await process_frame


func _test_visual_and_combat_contracts() -> void:
	var bull := await _spawn_bull(Vector2.RIGHT)
	var animator := bull.visual_animator
	var sprite := animator.sprite
	sprite.frame = 4
	animator.set_direction(Vector2.RIGHT)
	_expect(sprite.frame == 4, "Raging bull art: unchanged direction must not restart animation from frame zero")
	_expect(sprite.position == Vector2.ZERO and sprite.scale == Vector2.ONE * 2.0, "Raging bull art: use the retained origin and crisp integer 2x scale")
	_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Raging bull art: use nearest filtering")
	_expect(bull.visual.art_sprite != null and not bull.visual.art_sprite.visible, "Raging bull art: hide the old fallback while keeping it available")
	_expect(not bull.visual.title_label.visible and bull.visual.status_label.visible, "Raging bull art: hide the overlapping title but retain friendly-fire and turn warnings")
	_expect(
		bull.config.raging_bull_speed == 800.0
		and bull.config.raging_bull_duration == 24.0
		and bull.config.raging_bull_radius == 65.0
		and bull.config.raging_bull_damage == 48.0
		and bull.config.raging_bull_friendly_fire_damage == 18.0,
		"Raging bull art: speed, lifetime, radius, enemy damage, and friendly-fire damage must remain unchanged"
	)
	_expect(ResourceLoader.exists("res://Assets/Prototype/Static/raging_bull.png"), "Raging bull art: the old static source must remain available for rollback")
	_expect(ResourceLoader.exists("%s/metadata.json" % RagingBullVisualAnimator.ASSET_ROOT), "Raging bull art: PixelLab metadata must remain beside the source frames")
	bull.queue_free()
	await process_frame


func _spawn_bull(direction: Vector2) -> RagingBull:
	var bull := RagingBull.new()
	bull.setup(Vector2(600.0, 500.0), direction, PrototypeCombatConfig.new())
	root.add_child(bull)
	await process_frame
	return bull


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
