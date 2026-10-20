class_name TowerEntrance
extends RefCounted

# The expanded first floor places its destination beyond the southern woods.
# Later floors retain their original 1200x900 entrance until they are authored.
const POSITION := Vector2(830, 1290)
const LEGACY_POSITION := Vector2(1130, 455)
const ANDAR2_POSITION := Vector2(216, 782)
const INTERACT_RANGE := 58.0
const BODY := Rect2(POSITION + Vector2(-42, -67), Vector2(84, 48))
const LEGACY_BODY := Rect2(LEGACY_POSITION + Vector2(-32, -76), Vector2(64, 58))
const NAME := "Torre de Ascensão"

static func position_for_floor(floor_id: int) -> Vector2:
	return POSITION if floor_id == 1 else ANDAR2_POSITION if floor_id == 2 else LEGACY_POSITION

static func is_near(point: Vector2, floor_id: int = 1) -> bool:
	return point.distance_squared_to(position_for_floor(floor_id)) <= INTERACT_RANGE * INTERACT_RANGE
