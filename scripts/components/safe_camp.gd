class_name SafeCamp
extends RefCounted

const AREA := Rect2(470, 355, 180, 200)
const CLEARANCE := 130.0 # Greater than the starter weapon's 120 px reach.
const RESPAWN := Vector2(540, 450)
const INTERACT_RANGE := 56.0
# Legacy floors retain these original service anchors; saves store no NPC positions.
const STATIONS := {"Baú": Vector2(505, 391), "Ferreiro": Vector2(608, 391), "Vendedor": Vector2(608, 514)}
# These are the visible service locations in the expanded village.
const DISPLAY_STATIONS := {"Baú": Vector2(500, 525), "Ferreiro": Vector2(486, 430), "Vendedor": Vector2(680, 622)}
static var active_floor := 1

static func area_for_floor(floor_id: int) -> Rect2:
	return Floor2Layout.CAMP_AREA if floor_id == 2 else AREA

static func respawn_for_floor(floor_id: int) -> Vector2:
	return Floor2Layout.RESPAWN if floor_id == 2 else RESPAWN

static func stations_for_floor(floor_id: int, village: bool = false) -> Dictionary:
	if floor_id == 2:
		return Floor2Layout.STATIONS
	return DISPLAY_STATIONS if village else STATIONS

static func contains(point: Vector2) -> bool:
	return area_for_floor(active_floor).has_point(point)

static func in_clearance(point: Vector2) -> bool:
	return area_for_floor(active_floor).grow(CLEARANCE).has_point(point)

static func nearest_station(point: Vector2, village: bool = false) -> String:
	var nearest := ""
	var best := INTERACT_RANGE * INTERACT_RANGE
	var anchors: Dictionary = stations_for_floor(active_floor,village)
	for name: String in anchors:
		var distance := point.distance_squared_to(anchors[name])
		if distance <= best:
			nearest = name
			best = distance
	return nearest
