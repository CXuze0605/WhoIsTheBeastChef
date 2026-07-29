class_name NormalBullVisualAnimator
extends Node

const ASSET_ROOT := "res://Assets/Combat/DishAttacks/StirFryNormalBull01"
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
const RUN_FPS := 12.0
const DISPLAY_SCALE := 2.0

var sprite: AnimatedSprite2D
var current_animation: StringName = &""


func configure(visual: PlaceholderVisual, frames: SpriteFrames = null) -> void:
	if visual == null:
		return
	sprite = AnimatedSprite2D.new()
	sprite.name = "NormalBullArt"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.flip_h = false
	sprite.sprite_frames = frames if frames != null else build_sprite_frames()
	visual.add_child(sprite)
	if visual.art_sprite != null:
		visual.art_sprite.visible = false
	if visual.body != null:
		visual.body.visible = false
	visual.set_text_visible(false)


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
		var animation_name := StringName("run_%s" % direction)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, RUN_FPS)
		frames.set_animation_loop(animation_name, true)
		for frame_index in 6:
			var path := "%s/animations/Run/%s/frame_%03d.png" % [
				ASSET_ROOT,
				direction,
				frame_index,
			]
			var texture := load(path) as Texture2D
			if texture == null:
				push_error("Normal bull animation frame could not be loaded: %s" % path)
				continue
			frames.add_frame(animation_name, texture)
	return frames
