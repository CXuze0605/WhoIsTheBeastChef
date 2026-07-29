class_name RangedEnemyCharacterAnimator
extends Node


const ASSET_ROOT := "res://Assets/Characters/Enemies/RangedTasteEnemy01"
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
const WALK_FPS := 9.0
const ATTACK_FPS := 4.4
const DEFEAT_FPS := 15.0

var sprite: AnimatedSprite2D
var current_animation: StringName = &""
var last_direction := Vector2.DOWN


func configure(visual: PlaceholderVisual, frames: SpriteFrames = null) -> void:
	if visual == null:
		return
	sprite = AnimatedSprite2D.new()
	sprite.name = "RangedTasteEnemyArt"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = frames if frames != null else build_sprite_frames()
	visual.add_child(sprite)
	if visual.art_sprite != null:
		visual.art_sprite.visible = false
	if visual.body != null:
		visual.body.visible = false
	show_idle()


func update_state(
	state: int,
	motion: Vector2,
	attack_target_position: Vector2,
	is_flashing: bool
) -> void:
	if sprite == null:
		return
	sprite.modulate = Color("ffadad") if is_flashing else Color.WHITE
	if state == BasicTasteEnemy.State.REFLAVORING:
		# Project-wide production rule: ordinary enemy defeat art uses one
		# south-facing animation unless a later design explicitly requires more.
		_play_if_changed(&"defeat_south")
		return
	if state in [
		RangedTasteEnemy.STATE_EATING,
		RangedTasteEnemy.STATE_RETCH_WINDUP,
		RangedTasteEnemy.STATE_VOLLEY,
		RangedTasteEnemy.STATE_SHOOT_RECOVERY,
	]:
		var enemy := get_parent() as Node2D
		if enemy != null:
			var attack_direction := enemy.global_position.direction_to(attack_target_position)
			if not attack_direction.is_zero_approx():
				last_direction = attack_direction
		_play_if_changed(StringName("attack_%s" % get_direction_name(last_direction)))
		return
	if state in [RangedTasteEnemy.STATE_SHOVE_WINDUP, RangedTasteEnemy.STATE_SHOVE_RECOVERY]:
		_play_if_changed(StringName("attack_%s" % get_direction_name(last_direction)))
		return
	if not motion.is_zero_approx():
		last_direction = motion.normalized()
		_play_if_changed(StringName("walk_%s" % get_direction_name(last_direction)))
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
		# Frame zero duplicates the reference pose. Looping 1..8 avoids a hitch.
		_add_animation(frames, "walk_%s" % direction, "Walking_8dir_v2", direction, 1, 8, WALK_FPS, true)
		_add_animation(frames, "attack_%s" % direction, "Retch_Volley_8dir", direction, 0, 11, ATTACK_FPS, false)
	_add_animation(frames, "defeat_south", "Death_8dir", "south", 0, 7, DEFEAT_FPS, false)
	return frames


func _play_if_changed(animation_name: StringName) -> void:
	if sprite == null or current_animation == animation_name:
		return
	current_animation = animation_name
	sprite.play(animation_name)


func _add_rotation_idle(frames: SpriteFrames, direction: String) -> void:
	var key := StringName("idle_%s" % direction)
	frames.add_animation(key)
	frames.set_animation_speed(key, 1.0)
	frames.set_animation_loop(key, true)
	var texture := load("%s/rotations/%s.png" % [ASSET_ROOT, direction]) as Texture2D
	if texture == null:
		push_error("远程味真族方向基准加载失败：%s" % direction)
		return
	frames.add_frame(key, texture)


func _add_animation(
	frames: SpriteFrames,
	animation_name: String,
	folder_name: String,
	direction: String,
	first_frame: int,
	frame_count: int,
	fps: float,
	loops: bool
) -> void:
	var key := StringName(animation_name)
	frames.add_animation(key)
	frames.set_animation_speed(key, fps)
	frames.set_animation_loop(key, loops)
	for frame_index in range(first_frame, first_frame + frame_count):
		var path := "%s/animations/%s/%s/frame_%03d.png" % [
			ASSET_ROOT,
			folder_name,
			direction,
			frame_index,
		]
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("远程味真族动画帧加载失败：%s" % path)
			continue
		frames.add_frame(key, texture)

