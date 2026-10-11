class_name SafeCamp
extends RefCounted

const AREA := Rect2(470, 355, 180, 200)
const CLEARANCE := 130.0 # Greater than the starter weapon's 120 px reach.
const RESPAWN := Vector2(540, 450)
const INTERACT_RANGE := 56.0
# Legacy floors retain these original service anchors; saves store no NPC positions.
const STATIONS := {"Baú": Vector2(505, 391), "Ferreiro": Vector2(608, 391), "Vendedor": Vector2(608, 514)}
# These are the visible service locations in the expanded village.
const DISPLAY_STATIONS := {"Baú": Vector2(500, 556), "Ferreiro": Vector2(486, 430), "Vendedor": Vector2(680, 622)}

static func contains(point: Vector2) -> bool:
	return AREA.has_point(point)

static func in_clearance(point: Vector2) -> bool:
	return AREA.grow(CLEARANCE).has_point(point)

static func nearest_station(point: Vector2, village: bool = false) -> String:
	var nearest := ""
	var best := INTERACT_RANGE * INTERACT_RANGE
	var anchors: Dictionary = DISPLAY_STATIONS if village else STATIONS
	for name: String in anchors:
		var distance := point.distance_squared_to(anchors[name])
		if distance <= best:
			nearest = name
			best = distance
	return nearest
