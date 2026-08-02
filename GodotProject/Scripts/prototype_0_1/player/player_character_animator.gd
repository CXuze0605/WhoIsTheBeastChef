class_name PlayerCharacterAnimator
extends Node

const ASSET_ROOT := "res://Assets/Characters/Player/ChefWuxia01"
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
const IDLE_FPS := 4.0
const WALK_FPS := 6.0
const RUN_FPS := 9.0
const DEFEAT_FPS := 8.0
const SLOWED_WALK_SPEED_SCALE := 0.65
const DISPLAY_SCALE := 2.0
const GROUND_ANCHOR_POSITION := Vector2(0.0, -31.0)

var sprite: AnimatedSprite2D
var current_animation: StringName = &""


func configure(target_sprite: AnimatedSprite2D) -> void:
	sprite = target_sprite
	current_animation = &""
	if sprite == null:
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"idle_south"):
		sprite.sprite_frames = _build_sprite_frames()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The restaurant whitebox is built at the final combat-map scale. Keep the
	# actor crisp at an integer 2x size and grow upward from the old foot point.
	sprite.position = GROUND_ANCHOR_POSITION
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.flip_h = false
	show_idle(Vector2.DOWN)


func update_animation(
	motion: Vector2,
	facing_direction: Vector2,
	is_slowed: bool,
	is_defeated: bool,
	is_sprinting: bool = false
) -> void:
	if sprite == null:
		return
	if is_defeated:
		sprite.speed_scale = 1.0
		_play_if_changed(&"defeat_fall")
		return
	var direction := get_direction_name(facing_direction)
	if motion.is_zero_approx():
		sprite.speed_scale = 1.0
		_play_if_changed(StringName("idle_%s" % direction))
	elif is_sprinting:
		sprite.speed_scale = 1.0
		_play_if_changed(StringName("run_%s" % direction))
	else:
		sprite.speed_scale = SLOWED_WALK_SPEED_SCALE if is_slowed else 1.0
		_play_if_changed(StringName("walk_%s" % direction))


func show_idle(facing_direction: Vector2) -> void:
	if sprite == null:
		return
	_play_if_changed(StringName("idle_%s" % get_direction_name(facing_direction)))


func play_defeat() -> void:
	_play_if_changed(&"defeat_fall")


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


func _play_if_changed(animation_name: StringName) -> void:
	if sprite == null or current_animation == animation_name:
		return
	current_animation = animation_name
	sprite.play(animation_name)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for direction in DIRECTIONS:
		_add_animation(frames, "idle_%s" % direction, "Breathing_Idle", direction, 4, IDLE_FPS, true)
		_add_animation(frames, "walk_%s" % direction, "Walking", direction, 4, WALK_FPS, true)
		_add_animation(frames, "run_%s" % direction, "Running", direction, 4, RUN_FPS, true)
	_add_animation(frames, "defeat_fall", "Falling_Back_Death", "south", 7, DEFEAT_FPS, false)
	return frames


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
			push_error("玩家动画帧加载失败：%s" % path)
			continue
		frames.add_frame(animation_key, texture)
