class_name FloorConfig
extends RefCounted

const MAX_FLOORS := 5
const REQUIRED_DEFEATS := 50
const DEFAULT_WORLD_SIZE := Vector2(1200, 900)
const ANDAR1_WORLD_SIZE := Vector2(1700, 1350)
const ANDAR2_WORLD_SIZE := Vector2(1700, 1350)
const WORLD_SCENE := "res://scenes/world/andar_1.tscn"
const ANDAR2_WORLD_SCENE := "res://scenes/world/andar_2.tscn"
const ARENA_SCENE := "res://scenes/world/tower_arena.tscn"
const TOWER_SCRIPT := "res://scripts/components/tower_entrance.gd"
const FLOORS := {
	"1": {"difficulty": 1.0, "rewards": 1.0},
	"2": {"difficulty": 1.5, "rewards": 1.1},
	"3": {"difficulty": 1.4, "rewards": 1.2},
	"4": {"difficulty": 1.6, "rewards": 1.3},
	"5": {"difficulty": 1.8, "rewards": 1.4}}
static func valid(id: int) -> bool:
	return FLOORS.has(str(id))
static func difficulty(id: int) -> float:
	return float(FLOORS[str(id)].difficulty) if valid(id) else 1.0
static func reward(amount: int, id: int) -> int:
	return roundi(amount * float(FLOORS[str(id)].rewards)) if valid(id) else 0
static func tower_guardian_name(id: int) -> String:
	return "Guardião de Arenito" if id == 2 else "Guardião da Mata"
static func tower_return_name(id: int) -> String:
	return "Vale" if id == 2 else "Mata"
static func world_size(id: int) -> Vector2:
	return ANDAR1_WORLD_SIZE if id == 1 else ANDAR2_WORLD_SIZE if id == 2 else DEFAULT_WORLD_SIZE
static func world_scene(id: int) -> String:
	return ANDAR2_WORLD_SCENE if id == 2 else WORLD_SCENE
static func configuration(id: int) -> Dictionary:
	if not valid(id):
		return {}
	return {"id": "mata_%d" % id, "number": id, "required_defeats": REQUIRED_DEFEATS,
		"difficulty": difficulty(id), "reward_multiplier": FLOORS[str(id)].rewards,
		"world_scene": world_scene(id), "arena_scene": ARENA_SCENE, "tower_script": TOWER_SCRIPT}
