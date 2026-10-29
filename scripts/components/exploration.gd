class_name Exploration
extends RefCounted

const PICKUP_RANGE := 50.0
const RESOURCE_COOLDOWN := 300 # Seconds in real time; reload cannot reset it.
const BASE_RESOURCE_SPOTS := [
	{"id": "herb_west", "item": "Ervas", "position": Vector2(155, 220)},
	{"id": "mushroom_southwest", "item": "Cogumelos", "position": Vector2(230, 700)},
	{"id": "wood_north", "item": "Madeira", "position": Vector2(710, 130)},
	{"id": "stone_northeast", "item": "Pedras", "position": Vector2(935, 175)},
	{"id": "herb_southeast", "item": "Ervas", "position": Vector2(1040, 740)},
	{"id": "mushroom_east", "item": "Cogumelos", "position": Vector2(905, 740)},
	{"id": "wood_southwest", "item": "Madeira", "position": Vector2(120, 735)},
	{"id": "stone_east", "item": "Pedras", "position": Vector2(1080, 335)}
]
const ANDAR1_EXTRA_RESOURCE_SPOTS := [
	{"id": "ruins_herb_east", "item": "Ervas", "position": Vector2(1430, 392)},
	{"id": "danger_stone_east", "item": "Pedras", "position": Vector2(1585, 610)},
	{"id": "deepwood_mushroom_south", "item": "Cogumelos", "position": Vector2(690, 1155)},
	{"id": "secretwood_wood_southeast", "item": "Madeira", "position": Vector2(1280, 1108)}
]
const ANDAR2_RESOURCE_SPOTS := [
	{"id": "vale_stone_quarry_west", "item": "Pedras", "position": Vector2(350, 335)},
	{"id": "vale_stone_quarry_east", "item": "Pedras", "position": Vector2(650, 315)},
	{"id": "vale_herb_fields", "item": "Ervas", "position": Vector2(920, 700)},
	{"id": "vale_wood_fields", "item": "Madeira", "position": Vector2(760, 945)},
	{"id": "vale_herb_ruins", "item": "Ervas", "position": Vector2(1110, 275)},
	{"id": "vale_stone_danger", "item": "Pedras", "position": Vector2(1440, 800)},
	{"id": "vale_wood_south", "item": "Madeira", "position": Vector2(905, 1080)},
	{"id": "vale_herb_east", "item": "Ervas", "position": Vector2(1550, 865)}
]
const RESOURCE_SPOTS := [
	{"id": "herb_west", "item": "Ervas", "position": Vector2(155, 220)},
	{"id": "mushroom_southwest", "item": "Cogumelos", "position": Vector2(230, 700)},
	{"id": "wood_north", "item": "Madeira", "position": Vector2(710, 130)},
	{"id": "stone_northeast", "item": "Pedras", "position": Vector2(935, 175)},
	{"id": "herb_southeast", "item": "Ervas", "position": Vector2(1040, 740)},
	{"id": "mushroom_east", "item": "Cogumelos", "position": Vector2(905, 740)},
	{"id": "wood_southwest", "item": "Madeira", "position": Vector2(120, 735)},
	{"id": "stone_east", "item": "Pedras", "position": Vector2(1080, 335)},
	{"id": "ruins_herb_east", "item": "Ervas", "position": Vector2(1430, 392)},
	{"id": "danger_stone_east", "item": "Pedras", "position": Vector2(1585, 610)},
	{"id": "deepwood_mushroom_south", "item": "Cogumelos", "position": Vector2(690, 1155)},
	{"id": "secretwood_wood_southeast", "item": "Madeira", "position": Vector2(1280, 1108)}
]
const BASE_HIDDEN_CHESTS := [
	{"id": "west_roots", "position": Vector2(95, 145), "gold": 6, "item": "Couro"},
	{"id": "east_grove", "position": Vector2(905, 90), "gold": 8, "item": "Seda"},
	{"id": "south_clearing", "position": Vector2(1100, 790), "gold": 10, "item": "Essência"}
]
const ANDAR1_EXTRA_HIDDEN_CHESTS := [
	{"id": "ruins_cache_east", "position": Vector2(1605, 278), "gold": 12, "item": "Essência"},
	{"id": "secretwood_cache_southeast", "position": Vector2(1645, 1215), "gold": 14, "item": "Couro"}
]
const ANDAR2_HIDDEN_CHESTS := [
	{"id": "vale_quarry_cache", "position": Vector2(650, 440), "gold": 8, "item": "Pedras"},
	{"id": "vale_fields_cache", "position": Vector2(890, 1040), "gold": 10, "item": "Madeira"},
	{"id": "vale_danger_cache", "position": Vector2(1490, 910), "gold": 12, "item": "Essência"}
]
const HIDDEN_CHESTS := [
	{"id": "west_roots", "position": Vector2(95, 145), "gold": 6, "item": "Couro"},
	{"id": "east_grove", "position": Vector2(905, 90), "gold": 8, "item": "Seda"},
	{"id": "south_clearing", "position": Vector2(1100, 790), "gold": 10, "item": "Essência"},
	{"id": "ruins_cache_east", "position": Vector2(1605, 278), "gold": 12, "item": "Essência"},
	{"id": "secretwood_cache_southeast", "position": Vector2(1645, 1215), "gold": 14, "item": "Couro"}
]

static func resources_for_floor(floor_id: int) -> Array:
	return RESOURCE_SPOTS if floor_id == 1 else ANDAR2_RESOURCE_SPOTS if floor_id == 2 else [] if floor_id == 3 else BASE_RESOURCE_SPOTS

static func chests_for_floor(floor_id: int) -> Array:
	return HIDDEN_CHESTS if floor_id == 1 else ANDAR2_HIDDEN_CHESTS if floor_id == 2 else [] if floor_id == 3 else BASE_HIDDEN_CHESTS

static func known_resources() -> Array:
	return RESOURCE_SPOTS + ANDAR2_RESOURCE_SPOTS

static func known_chests() -> Array:
	return HIDDEN_CHESTS + ANDAR2_HIDDEN_CHESTS

static func discoveries_for_floor(floor_id: int) -> Array:
	return Floor3Layout.REGION_MARKERS if floor_id == 3 else resources_for_floor(floor_id)

static func known_discoveries() -> Array:
	return known_resources() + Floor3Layout.REGION_MARKERS

static func resource_at(point: Vector2, unavailable_until: Dictionary, now: int, floor_id: int = 1) -> Dictionary:
	var nearest: Dictionary = {}
	var best := PICKUP_RANGE * PICKUP_RANGE
	for spot: Dictionary in resources_for_floor(floor_id):
		if int(unavailable_until.get(spot.id, 0)) > now:
			continue
		var distance := point.distance_squared_to(spot.position)
		if distance <= best:
			best = distance
			nearest = spot
	return nearest

static func chest_at(point: Vector2, opened: Dictionary, floor_id: int = 1) -> Dictionary:
	var nearest: Dictionary = {}
	var best := PICKUP_RANGE * PICKUP_RANGE
	for chest: Dictionary in chests_for_floor(floor_id):
		if opened.has(chest.id):
			continue
		var distance := point.distance_squared_to(chest.position)
		if distance <= best:
			best = distance
			nearest = chest
	return nearest
