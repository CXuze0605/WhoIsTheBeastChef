class_name DirectionalWalkAnimator
extends Node

var sprite: Sprite2D
var frame_columns: int = 4
var frame_rows: int = 3
var playback_fps: float = 8.0
var source_faces_right: bool = true
var last_faces_right: bool = true
var follow_parent_velocity: bool = true
var elapsed: float = 0.0


func configure(
	target_sprite: Sprite2D,
	sprite_sheet: Texture2D,
	display_size: Vector2,
	fps: float,
	faces_right_in_source: bool,
	initially_faces_right: bool,
	auto_follow_parent_velocity: bool = true
) -> void:
	sprite = target_sprite
	frame_columns = 4
	frame_rows = 3
	playback_fps = maxf(0.1, fps)
	source_faces_right = faces_right_in_source
	last_faces_right = initially_faces_right
	follow_parent_velocity = auto_follow_parent_velocity
	elapsed = 0.0
	if sprite == null:
		return
	sprite.texture = sprite_sheet
	sprite.hframes = frame_columns
	sprite.vframes = frame_rows
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame_size := sprite_sheet.get_size() / Vector2(frame_columns, frame_rows)
	var fit_scale := minf(display_size.x / frame_size.x, display_size.y / frame_size.y) * 0.92
	sprite.scale = Vector2.ONE * fit_scale
	_apply_facing()
	set_process(follow_parent_velocity)


func _process(delta: float) -> void:
	if not follow_parent_velocity:
		return
	var body := get_parent() as CharacterBody2D
	update_animation(delta, body.velocity if body != null else Vector2.ZERO)


func update_animation(delta: float, motion: Vector2) -> void:
	if sprite == null:
		return
	if absf(motion.x) > 0.01:
		last_faces_right = motion.x > 0.0
	_apply_facing()
	if motion.length_squared() <= 0.0001:
		elapsed = 0.0
		sprite.frame = 0
		return
	elapsed += maxf(0.0, delta)
	var frame_count := frame_columns * frame_rows
	sprite.frame = int(floor(elapsed * playback_fps)) % frame_count


func _apply_facing() -> void:
	if sprite != null:
		sprite.flip_h = source_faces_right != last_faces_right
