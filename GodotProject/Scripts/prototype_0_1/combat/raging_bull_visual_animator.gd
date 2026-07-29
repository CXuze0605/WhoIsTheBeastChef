class_name RagingBullVisualAnimator
extends Node

const ASSET_ROOT := "res://Assets/Combat/DishAttacks/StirFryRagingBull01"
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
const RUN_FPS := 10.0
const DISPLAY_SCALE := 2.0

var sprite: AnimatedSprite2D
var current_animation: StringName = &""


func configure(visual: PlaceholderVisual, frames: SpriteFrames = null) -> void:
	if visual == null:
		return
	sprite = AnimatedSprite2D.new()
	sprite.name = "RagingBullArt"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.flip_h = false
	sprite.sprite_frames = frames if frames != null else build_sprite_frames()
	visual.add_child(sprite)
	if visual.art_sprite != null:
		visual.art_sprite.visible = false
	if visual.body != null:
		visual.body.visible = false
	# Keep the status line because it carries the existing friendly-fire and
	# random-turn warning. The old centered title would cover the new body art.
	if visual.title_label != null:
		visual.title_label.visible = false


func set_direction(direction: Vector2) -> void:
	if sprite == null:
		return
	var animation_name := StringName("run_%s" % get_direction_name(direction))
	if current_animation == animation_name:
		return
	current_animation = animation_name
	sprite.play(animation_name)


func get_direction_name(direction: Vector2) -> String:
	if direction.is_zero_approx():
		return "east"
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


static func build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for direction in DIRECTIONS:
		var source_direction := "north-b6f811d6" if direction == "north" else direction
		_add_animation(frames, "run_%s" % direction, source_direction)
	# PixelLab exported two north takes. Preserve the unused take until the
	# project owner selects a final animation direction.
	_add_animation(frames, "run_north_variant", "north-0941c069")
	return frames


static func _add_animation(frames: SpriteFrames, animation_name: String, source_direction: String) -> void:
	var animation_key := StringName(animation_name)
	frames.add_animation(animation_key)
	frames.set_animation_speed(animation_key, RUN_FPS)
	frames.set_animation_loop(animation_key, true)
	for frame_index in 8:
		var path := "%s/animations/Run/%s/frame_%03d.png" % [
			ASSET_ROOT,
			source_direction,
			frame_index,
		]
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("Raging bull animation frame could not be loaded: %s" % path)
			continue
		frames.add_frame(animation_key, texture)
