class_name CombatVfxBurst
extends Node2D

enum Kind {
	LEFTOVERS_IMPACT,
	CRISPY_BEEF_EXPLOSION,
}

var kind: int = Kind.LEFTOVERS_IMPACT
var effect_radius: float = 32.0
var elapsed: float = 0.0
var lifetime: float = 0.24
var accent := Color.WHITE


func setup(effect_kind: int, world_position: Vector2, radius: float, color: Color = Color.WHITE) -> void:
	kind = effect_kind
	global_position = world_position
	effect_radius = maxf(8.0, radius)
	accent = color
	lifetime = 0.42 if kind == Kind.CRISPY_BEEF_EXPLOSION else 0.24


func _ready() -> void:
	add_to_group("temporary_combat_vfx")
	z_index = 35
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var ratio := clampf(elapsed / maxf(lifetime, 0.01), 0.0, 1.0)
	if kind == Kind.CRISPY_BEEF_EXPLOSION:
		var frame_index := mini(
			CombatArtCatalog.CRISPY_BEEF_EXPLOSION_FRAMES.size() - 1,
			int(floor(ratio * CombatArtCatalog.CRISPY_BEEF_EXPLOSION_FRAMES.size()))
		)
		var texture := CombatArtCatalog.CRISPY_BEEF_EXPLOSION_FRAMES[frame_index]
		var size := Vector2.ONE * effect_radius * 1.45
		draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
		var shock_radius := effect_radius * lerpf(0.22, 1.0, ratio)
		draw_arc(Vector2.ZERO, shock_radius, 0.0, TAU, 48, Color(accent, 0.85 * (1.0 - ratio)), 5.0)
		return
	var impact := CombatArtCatalog.get_texture(&"ranged_leftovers_impact")
	var impact_size := Vector2.ONE * effect_radius * lerpf(0.75, 1.25, ratio)
	draw_texture_rect(impact, Rect2(-impact_size * 0.5, impact_size), false, Color(1.0, 1.0, 1.0, 1.0 - ratio))
	draw_arc(Vector2.ZERO, effect_radius * lerpf(0.35, 1.0, ratio), 0.0, TAU, 28, Color(accent, 0.65 * (1.0 - ratio)), 3.0)

