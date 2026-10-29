class_name MiningRules
extends RefCounted

# Valores provisórios. A raridade é sorteada somente após um drop válido.
const RANGE := 76.0
const DURATION := 0.48
const DEPOSIT_TEMPLATE := {
	"item": "Minério de Ferro", "chance": 0.75,
	"rarities": {"comum": 0.90, "raro": 0.10},
	"uses": 3, "respawn_seconds": 300, "requirement": ""
}
const FLOOR_DEPOSITS := {
	2: [
		{"id":"vale_ferro_1", "position":Vector2(310,246)},
		{"id":"vale_ferro_2", "position":Vector2(616,220)},
		{"id":"vale_ferro_3", "position":Vector2(358,426)},
		{"id":"vale_ferro_4", "position":Vector2(674,422)}
	]
}

static func deposits(floor_id: int) -> Array:
	return FLOOR_DEPOSITS.get(floor_id, [])

static func definition(floor_id: int, id: String) -> Dictionary:
	for source: Dictionary in deposits(floor_id):
		if source.id == id:
			return DEPOSIT_TEMPLATE.merged(source, true)
	return {}

static func near(floor_id: int, point: Vector2) -> Dictionary:
	var nearest := {}
	var best := RANGE * RANGE
	for source: Dictionary in deposits(floor_id):
		var distance := point.distance_squared_to(source.position)
		if distance <= best:
			best = distance
			nearest = definition(floor_id, source.id)
	return nearest

static func roll(config: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var occurrence := rng.randf()
	if occurrence >= float(config.chance):
		return {}
	return EquipmentEconomy.roll_entry(config, occurrence, rng.randf())
