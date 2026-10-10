class_name TowerEntrance
extends RefCounted

# Eastern end of the existing main trail, inside the unchanged 1200x900 map.
const POSITION := Vector2(1130, 455)
const INTERACT_RANGE := 58.0
const BODY := Rect2(POSITION + Vector2(-32, -76), Vector2(64, 58))
const NAME := "Torre de Ascensão"

static func is_near(point: Vector2) -> bool:
	return point.distance_squared_to(POSITION) <= INTERACT_RANGE * INTERACT_RANGE
