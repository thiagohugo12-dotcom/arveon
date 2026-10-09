class_name DashMotor
extends Node

var time_left: float = 0.0
var cooldown_left: float = 0.0
var direction: Vector2 = Vector2.DOWN

func tick(delta: float) -> void:
	time_left = maxf(0.0, time_left - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)

func request(movement: Vector2, last_direction: Vector2, stats: ActorData) -> bool:
	if cooldown_left > 0.0:
		return false
	direction = movement.normalized() if not movement.is_zero_approx() else last_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	time_left = stats.dash_duration
	cooldown_left = stats.dash_cooldown
	return true

func active() -> bool:
	return time_left > 0.0
