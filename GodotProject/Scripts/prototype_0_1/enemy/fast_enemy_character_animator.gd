class_name FastEnemyCharacterAnimator
extends Node

enum ActionPhase {
	NONE,
	CHARGING,
	POUNCING,
	RECOVERY,
}

const ASSET_ROOT := "res://Assets/Characters/Enemies/FastTasteEnemy01"
const DIRECTIONS: PackedStringArray = [
	"south",
	"south-east",
	"east",
	"north-east",
	"north",
	"north-west",
	"west",
	"south-west",
]
const RUN_FPS := 11.0
const SLOWED_RUN_FPS := 7.0
# Five crouch frames cover the existing 0.60 second charge without changing it.
const CROUCH_FPS := 8.333333
# Eight pounce frames cover the existing 0.36 second straight dash.
const POUNCE_FPS := 22.222222
const DEFEAT_FPS := 15.0

var sprite: AnimatedSprite2D
var current_animation: StringName = &""
var last_direction := Vector2.DOWN


func configure(visual: PlaceholderVisual, frames: SpriteFrames = null) -> void:
	if visual == null:
		return
	sprite = AnimatedSprite2D.new()
	sprite.name = "FastTasteEnemyArt"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE
	sprite.flip_h = false
	sprite.sprite_frames = frames if frames != null else build_sprite_frames()
	visual.add_child(sprite)
	if visual.art_sprite != null:
		visual.art_sprite.visible = false
	if visual.body != null:
		visual.body.visible = false
	show_idle()


func update_animation(
	action_phase: int,
	motion: Vector2,
	dash_direction: Vector2,
	is_slowed: bool,
	is_defeated: bool,
	is_flashing: bool = false
) -> void:
	if sprite == null:
		return
	sprite.modulate = Color("ffadad") if is_flashing else Color.WHITE
	if is_defeated:
		_play_if_changed(&"defeat_fall")
		return
	if action_phase == ActionPhase.CHARGING:
		_set_dash_direction(dash_direction)
		_play_if_changed(StringName("crouch_%s" % get_direction_name(last_direction)))
		return
	if action_phase in [ActionPhase.POUNCING, ActionPhase.RECOVERY]:
		_set_dash_direction(dash_direction)
		# Recovery intentionally keeps the same non-looping pounce animation.
		# It therefore finishes the leap and holds its landing frame instead of
		# restarting or snapping to idle as soon as the hit/miss is resolved.
		_play_if_changed(StringName("pounce_%s" % get_direction_name(last_direction)))
		return
	if not motion.is_zero_approx():
		last_direction = motion.normalized()
		var prefix := "slow_run" if is_slowed else "run"
		_play_if_changed(StringName("%s_%s" % [prefix, get_direction_name(last_direction)]))
		return
	show_idle()


func show_idle() -> void:
	if sprite != null:
		_play_if_changed(StringName("idle_%s" % get_direction_name(last_direction)))


func get_direction_name(direction: Vector2) -> String:
	if direction.is_zero_approx():
		return "south"
	var degrees := rad_to_deg(atan2(direction.y, direction.x))
	var sector := wrapi(int(floor((degrees + 22.5) / 45.0)), 0, 8)
	match sector:
		0:
			return "east"
		1:
			return "south-east"
		2:
			return "south"
		3:
			return "south-west"
		4:
			return "west"
		5:
			return "north-west"
		6:
			return "north"
		_:
			return "north-east"


func build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for direction in DIRECTIONS:
		_add_rotation_idle(frames, direction)
		_add_animation(frames, "run_%s" % direction, "Running", direction, 6, RUN_FPS, true)
		_add_animation(frames, "slow_run_%s" % direction, "Running", direction, 6, SLOWED_RUN_FPS, true)
		_add_animation(frames, "crouch_%s" % direction, "Crouching", direction, 5, CROUCH_FPS, false)
		_add_animation(frames, "pounce_%s" % direction, "feipu", direction, 8, POUNCE_FPS, false)
	_add_animation(frames, "defeat_fall", "Falling_Back_Death", "south", 7, DEFEAT_FPS, false)
	return frames


func _set_dash_direction(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		last_direction = direction.normalized()


func _play_if_changed(animation_name: StringName) -> void:
	if sprite == null or current_animation == animation_name:
		return
	current_animation = animation_name
	sprite.play(animation_name)


func _add_rotation_idle(frames: SpriteFrames, direction: String) -> void:
	var animation_key := StringName("idle_%s" % direction)
	frames.add_animation(animation_key)
	frames.set_animation_speed(animation_key, 1.0)
	frames.set_animation_loop(animation_key, true)
	var texture := load("%s/rotations/%s.png" % [ASSET_ROOT, direction]) as Texture2D
	if texture == null:
		push_error("速度型味真族方向基准加载失败：%s" % direction)
		return
	frames.add_frame(animation_key, texture)


func _add_animation(
	frames: SpriteFrames,
	animation_name: String,
	folder_name: String,
	direction: String,
	frame_count: int,
	fps: float,
	loops: bool
) -> void:
	var animation_key := StringName(animation_name)
	frames.add_animation(animation_key)
	frames.set_animation_speed(animation_key, fps)
	frames.set_animation_loop(animation_key, loops)
	for frame_index in frame_count:
		var path := "%s/animations/%s/%s/frame_%03d.png" % [
			ASSET_ROOT,
			folder_name,
			direction,
			frame_index,
		]
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("速度型味真族动画帧加载失败：%s" % path)
			continue
		frames.add_frame(animation_key, texture)
