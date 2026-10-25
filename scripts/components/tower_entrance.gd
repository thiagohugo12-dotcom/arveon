class_name TowerEntrance
extends RefCounted

# The expanded first floor places its destination beyond the southern woods.
# Later floors retain their original 1200x900 entrance until they are authored.
const POSITION: Vector2 = FloorCatalog.FLOORS[1]["tower_position"]
const LEGACY_POSITION := Vector2(1130, 455)
const ANDAR2_POSITION: Vector2 = FloorCatalog.FLOORS[2]["tower_position"]
const INTERACT_RANGE := 58.0
# The visible stone feet flank a walkable doorway. The player is 26 px wide.
const ANDAR1_SIDES := [Rect2(POSITION + Vector2(-69, -39), Vector2(47, 40)), Rect2(POSITION + Vector2(22, -39), Vector2(47, 40))]
const ANDAR2_SIDES := [Rect2(ANDAR2_POSITION + Vector2(-57, -35), Vector2(39, 36)), Rect2(ANDAR2_POSITION + Vector2(18, -35), Vector2(39, 36))]
# O corpo da torre acima do vão da porta também é sólido: não dá para andar por cima do sprite.
const ANDAR1_UPPER := Rect2(POSITION + Vector2(-46, -205), Vector2(92, 166))
const ANDAR2_UPPER := Rect2(ANDAR2_POSITION + Vector2(-48, -142), Vector2(96, 107))
const LEGACY_BODY := Rect2(LEGACY_POSITION + Vector2(-32, -76), Vector2(64, 58))
const NAME := "Torre de Ascensão"

static func position_for_floor(floor_id: int) -> Vector2:
	return FloorCatalog.tower_position(floor_id, LEGACY_POSITION)

static func is_near(point: Vector2, floor_id: int = 1) -> bool:
	return point.distance_squared_to(position_for_floor(floor_id)) <= INTERACT_RANGE * INTERACT_RANGE
