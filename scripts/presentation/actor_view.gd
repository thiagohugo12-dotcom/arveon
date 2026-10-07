class_name ActorView
extends Node2D

@export var tint := Color(0.25, 0.7, 1.0)
var facing := Vector2.DOWN
var hp_ratio: float = 1.0
var flash_left: float = 0.0

func set_facing(value: Vector2) -> void:
	if not value.is_zero_approx() and not facing.is_equal_approx(value):
		facing = value.normalized()
		queue_redraw()

func set_health(current: int, maximum: int) -> void:
	hp_ratio = float(current) / maximum
	queue_redraw()

func flash() -> void:
	flash_left = 0.12
	queue_redraw()

func _process(delta: float) -> void:
	if flash_left > 0.0:
		flash_left = maxf(0.0, flash_left - delta)
		if flash_left == 0.0:
			queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, 5), 15, Color(0, 0, 0, 0.25))
	draw_circle(Vector2.ZERO, 13, Color.WHITE if flash_left > 0.0 else tint)
	draw_line(facing * 5, facing * 21, Color(0.95, 0.95, 0.75), 4)
	draw_rect(Rect2(-18, -27, 36, 4), Color(0.12, 0.12, 0.12))
	draw_rect(Rect2(-18, -27, 36 * hp_ratio, 4), Color(0.3, 0.9, 0.45))
