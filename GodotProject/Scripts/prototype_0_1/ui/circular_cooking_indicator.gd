class_name CircularCookingIndicator
extends Node2D

enum Symbol { NONE, WAIT, DONE, BURNT, CHARCOAL, OFF, STUCK, FIRE }

var progress_ratio: float = 0.0
var indicator_color := Color.WHITE
var symbol: int = Symbol.NONE
var timed: bool = false
var flashing: bool = false
var state_key: String = "hidden"
var ring_radius: float = 22.0
var ring_width: float = 6.0


func _ready() -> void:
	z_index = 30


func _process(_delta: float) -> void:
	if flashing and visible:
		queue_redraw()


func set_indicator(key: String, ratio: float, color: Color, new_symbol: int, is_timed: bool, should_flash: bool = false) -> void:
	state_key = key
	progress_ratio = clampf(ratio, 0.0, 1.0)
	indicator_color = color
	symbol = new_symbol
	timed = is_timed
	flashing = should_flash
	visible = true
	queue_redraw()


func hide_indicator() -> void:
	state_key = "hidden"
	visible = false
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var alpha := 0.62 + sin(Time.get_ticks_msec() * 0.018) * 0.28 if flashing else 1.0
	var color := Color(indicator_color, alpha)
	draw_circle(Vector2.ZERO, ring_radius + 5.0, Color(0.04, 0.05, 0.07, 0.82))
	draw_arc(Vector2.ZERO, ring_radius, -PI * 0.5, PI * 1.5, 48, Color(0.30, 0.33, 0.38, 0.9), ring_width, true)
	var arc_ratio := progress_ratio if timed else 1.0
	if arc_ratio > 0.0:
		draw_arc(Vector2.ZERO, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * arc_ratio, 48, color, ring_width, true)
	_draw_symbol(color)


func _draw_symbol(color: Color) -> void:
	match symbol:
		Symbol.WAIT:
			draw_line(Vector2(-7.0, -5.0), Vector2(-7.0, 7.0), color, 3.0)
			draw_line(Vector2(7.0, -5.0), Vector2(7.0, 7.0), color, 3.0)
		Symbol.DONE:
			draw_polyline(PackedVector2Array([Vector2(-9.0, 0.0), Vector2(-2.0, 7.0), Vector2(10.0, -8.0)]), color, 4.0)
		Symbol.BURNT:
			draw_line(Vector2(0.0, -9.0), Vector2(0.0, 4.0), color, 4.0)
			draw_circle(Vector2(0.0, 10.0), 2.5, color)
		Symbol.CHARCOAL:
			draw_circle(Vector2.ZERO, 9.0, Color("222228"))
		Symbol.OFF:
			draw_line(Vector2(-9.0, 9.0), Vector2(9.0, -9.0), color, 4.0)
		Symbol.STUCK:
			draw_line(Vector2(-8.0, -8.0), Vector2(8.0, 8.0), color, 4.0)
			draw_line(Vector2(-8.0, 8.0), Vector2(8.0, -8.0), color, 4.0)
		Symbol.FIRE:
			draw_colored_polygon(PackedVector2Array([Vector2(0.0, -10.0), Vector2(8.0, 8.0), Vector2(0.0, 5.0), Vector2(-8.0, 8.0)]), color)
