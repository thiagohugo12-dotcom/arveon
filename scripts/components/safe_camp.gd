class_name SafeCamp
extends RefCounted

const AREA := Rect2(470, 355, 180, 200)
const CLEARANCE := 130.0 # Greater than the starter weapon's 120 px reach.
const RESPAWN := Vector2(540, 450)
const INTERACT_RANGE := 56.0
# Original anchors remain valid so saved movement and interaction contracts keep working.
const STATIONS := {"Baú": Vector2(505, 391), "Ferreiro": Vector2(608, 391), "Vendedor": Vector2(608, 514)}
# The refreshed art stays on the original service anchors and gameplay layout.
const DISPLAY_STATIONS := {"Baú": Vector2(505, 391), "Ferreiro": Vector2(608, 391), "Vendedor": Vector2(608, 514)}

static func contains(point: Vector2) -> bool:
	return AREA.has_point(point)

static func in_clearance(point: Vector2) -> bool:
	return AREA.grow(CLEARANCE).has_point(point)

static func nearest_station(point: Vector2) -> String:
	var nearest := ""
	var best := INTERACT_RANGE * INTERACT_RANGE
	for name: String in STATIONS:
		for station: Vector2 in [STATIONS[name], DISPLAY_STATIONS[name]]:
			var distance := point.distance_squared_to(station)
			if distance <= best:
				nearest = name
				best = distance
	return nearest
