class_name TowerEntrance
extends RefCounted

# Beside the north trail; doorway remains reachable from its southern apron.
const POSITION := Vector2(600, 280)
const INTERACT_RANGE := 58.0
const BODY := Rect2(568, 204, 64, 58)
const NAME := "Torre de Ascensão"

static func is_near(point: Vector2) -> bool:
	return point.distance_squared_to(POSITION) <= INTERACT_RANGE * INTERACT_RANGE
