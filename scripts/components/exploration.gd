class_name Exploration
extends RefCounted

const PICKUP_RANGE := 50.0
const RESOURCE_COOLDOWN := 300 # Seconds in real time; reload cannot reset it.
const RESOURCE_SPOTS := [
	{"id": "herb_west", "item": "Ervas", "position": Vector2(155, 220)},
	{"id": "mushroom_southwest", "item": "Cogumelos", "position": Vector2(230, 700)},
	{"id": "wood_north", "item": "Madeira", "position": Vector2(710, 130)},
	{"id": "stone_northeast", "item": "Pedras", "position": Vector2(935, 175)},
	{"id": "herb_southeast", "item": "Ervas", "position": Vector2(1040, 740)},
	{"id": "mushroom_east", "item": "Cogumelos", "position": Vector2(905, 740)},
	{"id": "wood_southwest", "item": "Madeira", "position": Vector2(120, 735)},
	{"id": "stone_east", "item": "Pedras", "position": Vector2(1080, 335)}
]
const HIDDEN_CHESTS := [
	{"id": "west_roots", "position": Vector2(95, 145), "gold": 6, "item": "Couro"},
	{"id": "east_grove", "position": Vector2(905, 90), "gold": 8, "item": "Seda"},
	{"id": "south_clearing", "position": Vector2(1100, 790), "gold": 10, "item": "Essência"}
]

static func resource_at(point: Vector2, unavailable_until: Dictionary, now: int) -> Dictionary:
	var nearest: Dictionary = {}
	var best := PICKUP_RANGE * PICKUP_RANGE
	for spot: Dictionary in RESOURCE_SPOTS:
		if int(unavailable_until.get(spot.id, 0)) > now:
			continue
		var distance := point.distance_squared_to(spot.position)
		if distance <= best:
			best = distance
			nearest = spot
	return nearest

static func chest_at(point: Vector2, opened: Dictionary) -> Dictionary:
	var nearest: Dictionary = {}
	var best := PICKUP_RANGE * PICKUP_RANGE
	for chest: Dictionary in HIDDEN_CHESTS:
		if opened.has(chest.id):
			continue
		var distance := point.distance_squared_to(chest.position)
		if distance <= best:
			best = distance
			nearest = chest
	return nearest
