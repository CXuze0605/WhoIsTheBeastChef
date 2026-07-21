class_name PlaceholderVisual
extends Node2D

var body: Polygon2D
var art_sprite: Sprite2D
var title_label: Label
var status_label: Label
var visual_size := Vector2(120.0, 70.0)
var has_art: bool = false


func _ready() -> void:
	body = Polygon2D.new()
	body.name = "Body"
	add_child(body)
	art_sprite = Sprite2D.new()
	art_sprite.name = "PrototypeArt"
	art_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(art_sprite)
	title_label = Label.new()
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color("202027"))
	title_label.add_theme_constant_override("outline_size", 4)
	add_child(title_label)
	status_label = Label.new()
	status_label.name = "Status"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color("fff3ba"))
	status_label.add_theme_color_override("font_outline_color", Color("202027"))
	status_label.add_theme_constant_override("outline_size", 3)
	add_child(status_label)
	_apply_layout()


func configure(size: Vector2, color: Color, title: String, status: String = "") -> void:
	visual_size = size
	if not is_node_ready():
		await ready
	body.color = color
	title_label.text = title
	status_label.text = status
	_apply_layout()


func set_title(value: String) -> void:
	if title_label != null:
		title_label.text = value


func set_status(value: String) -> void:
	if status_label != null:
		status_label.text = value


func set_color(value: Color) -> void:
	if body != null:
		body.color = value


func set_art(texture: Texture2D) -> void:
	if art_sprite == null or body == null:
		return
	art_sprite.texture = texture
	has_art = texture != null
	# The polygon is only a fallback. Keeping it behind finished placeholder art
	# made stations look like they still had the old graybox attached.
	body.visible = not has_art
	_apply_layout()


func get_art_display_size() -> Vector2:
	if art_sprite == null or art_sprite.texture == null:
		return Vector2.ZERO
	return art_sprite.texture.get_size() * art_sprite.scale.abs()


func _apply_layout() -> void:
	if body == null:
		return
	var half := visual_size * 0.5
	body.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	title_label.position = Vector2(-half.x, -half.y)
	title_label.size = visual_size
	status_label.position = Vector2(-half.x, half.y + 4.0)
	status_label.size = Vector2(visual_size.x, 24.0)
	if art_sprite != null:
		art_sprite.position = Vector2.ZERO
		if art_sprite.texture != null:
			var texture_size := art_sprite.texture.get_size()
			var fit_scale := minf(visual_size.x / texture_size.x, visual_size.y / texture_size.y) * 0.92
			art_sprite.scale = Vector2.ONE * fit_scale
	if has_art:
		title_label.position = Vector2(-half.x, half.y * 0.28)
		title_label.size = Vector2(visual_size.x, maxf(24.0, half.y * 0.72))
