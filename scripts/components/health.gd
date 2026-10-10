class_name Health
extends Node

signal changed(current: int, maximum: int)
signal died
var current: int = 1
var maximum: int = 1

func initialize(value: int) -> void:
	maximum = maxi(value, 1)
	current = maximum
	changed.emit(current, maximum)

func is_alive() -> bool:
	return current > 0

func damage(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	current = maxi(0, current - amount)
	changed.emit(current, maximum)
	if current == 0:
		died.emit()

func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var restored := mini(amount, maximum - current)
	current += restored
	if restored > 0:
		changed.emit(current, maximum)
	return restored
