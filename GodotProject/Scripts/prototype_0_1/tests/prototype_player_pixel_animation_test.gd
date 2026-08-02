extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://Scenes/prototype_0_1/player.tscn") as PackedScene
	var player := packed.instantiate() as PrototypePlayer
	root.add_child(player)
	await process_frame
	_test_resource_structure(player)
	_test_eight_direction_mapping(player)
	await _test_walking_sprinting_and_stamina(player)
	_test_animation_stability_and_defeat(player)
	_test_scene_contracts(player)
	player.queue_free()
	await process_frame
	if failures.is_empty():
		print("PROTOTYPE_PLAYER_PIXEL_ANIMATION_TEST: PASS (5/5 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_PLAYER_PIXEL_ANIMATION_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_resource_structure(player: PrototypePlayer) -> void:
	var sprite := player.get_node("PlayerArt") as AnimatedSprite2D
	var frames := sprite.sprite_frames
	_expect(sprite != null and frames != null, "Player art: PlayerArt must remain available as AnimatedSprite2D")
	_expect(
		frames.resource_path == "%s/chef_wuxia_01_sprite_frames.tres" % PlayerCharacterAnimator.ASSET_ROOT,
		"Player art: the complete animation set must be stored as an editor-visible SpriteFrames resource"
	)
	_expect(frames.get_animation_names().size() == 25, "Player art: 8 idle + 8 walk + 8 run + defeat_fall animations must exist")
	for direction in PlayerCharacterAnimator.DIRECTIONS:
		for prefix in ["idle", "walk", "run"]:
			var animation_name := StringName("%s_%s" % [prefix, direction])
			_expect(frames.has_animation(animation_name), "Player art: missing %s" % animation_name)
			_expect(frames.get_frame_count(animation_name) == 4, "Player art: %s must preserve all four 108x108 frames" % animation_name)
	_expect(frames.get_animation_speed(&"idle_south") == 4.0, "Player art: idle playback must use 4 FPS")
	_expect(frames.get_animation_speed(&"walk_south") == 6.0, "Player art: ordinary walking must use 6 FPS")
	_expect(frames.get_animation_speed(&"run_south") == 9.0, "Player art: sprinting must use 9 FPS")
	_expect(frames.get_frame_count(&"defeat_fall") == 7 and not frames.get_animation_loop(&"defeat_fall"), "Player art: defeat_fall must preserve seven south frames and play once")


func _test_eight_direction_mapping(player: PrototypePlayer) -> void:
	var animator := player.walk_animator
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
		animator.update_animation(direction, direction.normalized(), false, false)
		_expect(animator.sprite.animation == StringName("walk_%s" % expected), "Player art: moving %s must use its native walk direction" % expected)
		animator.update_animation(Vector2.ZERO, direction.normalized(), false, false)
		_expect(animator.sprite.animation == StringName("idle_%s" % expected), "Player art: stopping after %s must keep the last facing" % expected)
		_expect(not animator.sprite.flip_h, "Player art: native eight-direction frames must never use horizontal mirroring")


func _test_walking_sprinting_and_stamina(player: PrototypePlayer) -> void:
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	_expect(
		player.walk_animator.sprite.animation == &"walk_east" and is_equal_approx(player.velocity.x, 240.0),
		"Player sprint: ordinary movement must use Walking at the unchanged base speed"
	)
	Input.action_press("sprint")
	await physics_frame
	await physics_frame
	_expect(player.walk_animator.sprite.animation == &"run_east", "Player sprint: active sprint must use Running")
	_expect(player.velocity.x > 470.0 and player.current_stamina < player.prototype_max_stamina, "Player sprint: Shift must double travel speed and drain stamina")
	Input.action_release("sprint")
	await physics_frame
	_expect(player.walk_animator.sprite.animation == &"walk_east", "Player sprint: releasing sprint must return to Walking")
	player.combat_statuses.apply_status(CombatStatusController.StatusType.MOVE_SLOW, &"animation_test", 0.35, 10.0, true)
	await physics_frame
	await physics_frame
	_expect(player.walk_animator.sprite.animation == &"walk_east" and is_equal_approx(player.walk_animator.sprite.speed_scale, PlayerCharacterAnimator.SLOWED_WALK_SPEED_SCALE), "Player art: slowed movement must keep Walking but lower its playback speed")
	Input.action_release("move_right")
	await physics_frame
	await physics_frame
	_expect(player.walk_animator.sprite.animation == &"idle_east", "Player art: releasing movement while slowed must return to the last-direction idle")
	player.combat_statuses.remove_source(&"animation_test")

	player.current_stamina = 10.0
	player.stamina_regen_delay_left = player.prototype_stamina_regen_delay
	player._update_stamina(0.79, false, false)
	_expect(is_equal_approx(player.current_stamina, 10.0), "Player stamina: recovery must wait for the 0.8 second delay")
	player._update_stamina(0.02, false, false)
	_expect(player.current_stamina > 10.0, "Player stamina: delayed recovery must restore stamina at 25 per second")
	player.consume_stamina(999.0)
	_expect(player.current_stamina == 0.0 and player.sprint_exhausted, "Player stamina: exhaustion must clamp at zero")
	_expect(not player._update_stamina(0.1, true, true), "Player stamina: holding Shift after exhaustion must not cause stuttering micro-sprints")
	player._update_stamina(0.1, false, false)
	_expect(not player.sprint_exhausted, "Player stamina: releasing Shift must re-arm sprint without adding a punishment state")


func _test_animation_stability_and_defeat(player: PrototypePlayer) -> void:
	var animator := player.walk_animator
	animator.update_animation(Vector2.RIGHT, Vector2.RIGHT, false, false, true)
	animator.sprite.frame = 2
	animator.update_animation(Vector2.RIGHT, Vector2.RIGHT, false, false, true)
	_expect(animator.sprite.frame == 2, "Player art: unchanged animation and direction must not restart from frame zero")
	animator.update_animation(Vector2.ZERO, Vector2.RIGHT, false, false)
	animator.sprite.frame = 3
	animator.update_animation(Vector2.ZERO, Vector2.RIGHT, false, false)
	_expect(animator.sprite.frame == 3, "Player art: repeated idle updates must not restart breathing")
	animator.update_animation(Vector2.ZERO, Vector2.RIGHT, false, true)
	_expect(animator.sprite.animation == &"defeat_fall", "Player art: defeat must override normal idle and running")
	animator.sprite.frame = 4
	animator.update_animation(Vector2.RIGHT, Vector2.RIGHT, false, true)
	_expect(animator.sprite.frame == 4 and animator.sprite.animation == &"defeat_fall", "Player art: ordinary movement updates must not restart or replace defeat_fall")


func _test_scene_contracts(player: PrototypePlayer) -> void:
	var sprite := player.get_node("PlayerArt") as AnimatedSprite2D
	var collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var shape := collision.shape as RectangleShape2D
	_expect(sprite.position == PlayerCharacterAnimator.GROUND_ANCHOR_POSITION and sprite.scale == Vector2.ONE * PlayerCharacterAnimator.DISPLAY_SCALE, "Player art: use the restaurant-scale integer 2x presentation while retaining its foot point")
	_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Player art: use nearest filtering")
	_expect(shape.size == Vector2(34.0, 34.0), "Player art: visual replacement must not change the player collision shape")
	_expect(player.prototype_move_speed == 240.0 and player.prototype_sprint_speed_multiplier == 2.0 and player.prototype_interaction_distance == 108.0, "Player sprint: base speed and interaction distance stay unchanged while sprint is exactly 2x")
	_expect(player.prototype_max_stamina == 100.0 and player.prototype_sprint_drain_per_second == 30.0 and player.prototype_stamina_regen_per_second == 25.0, "Player stamina: Prototype values must remain centralized at 100 / 30 drain / 25 regen")
	_expect(is_equal_approx(player.get_node("HeldAnchor").position.length(), 34.0), "Player art: visual replacement must preserve the held-item anchor radius")
	_expect(ResourceLoader.exists("res://Assets/Prototype/Static/player_chef.png"), "Player art: the previous player_chef.png must remain available for rollback")
	_expect(ResourceLoader.exists("%s/metadata.json" % PlayerCharacterAnimator.ASSET_ROOT), "Player art: PixelLab metadata must be preserved beside the source frames")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
