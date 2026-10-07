class_name InputDriver
extends Node

var touch_direction := Vector2.ZERO
var dash_requested: bool = false

func movement() -> Vector2:
	var keys := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return touch_direction.limit_length() if not touch_direction.is_zero_approx() else keys

func set_touch_direction(value: Vector2) -> void:
	touch_direction = value.limit_length()

func request_dash() -> void:
	dash_requested = true

func consume_dash() -> bool:
	var requested := dash_requested or Input.is_action_just_pressed("dash")
	dash_requested = false
	return requested

func reset() -> void:
	touch_direction = Vector2.ZERO
	dash_requested = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()
