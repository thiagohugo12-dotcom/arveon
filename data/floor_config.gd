class_name FloorConfig
extends RefCounted

# Fachada estável sobre FloorCatalog (Marco 2): os valores vivem no catálogo.
const MAX_FLOORS := 5
const REQUIRED_DEFEATS := 50
const DEFAULT_WORLD_SIZE := Vector2(1200, 900)
const ANDAR1_WORLD_SIZE: Vector2 = FloorCatalog.FLOORS[1]["world_size"]
const ANDAR2_WORLD_SIZE: Vector2 = FloorCatalog.FLOORS[2]["world_size"]
const WORLD_SCENE: String = FloorCatalog.FLOORS[1]["world_scene"]
const ANDAR2_WORLD_SCENE: String = FloorCatalog.FLOORS[2]["world_scene"]
const ARENA_SCENE := "res://scenes/world/tower_arena.tscn"
const TOWER_SCRIPT := "res://scripts/components/tower_entrance.gd"
const FLOORS := FloorCatalog.SCALE
static func valid(id: int) -> bool:
	return FloorCatalog.valid_scale(id)
static func difficulty(id: int) -> float:
	return FloorCatalog.difficulty(id)
static func reward(amount: int, id: int) -> int:
	return FloorCatalog.reward(amount, id)
static func tower_guardian_name(id: int) -> String:
	return FloorCatalog.tower_guardian_name(id)
static func tower_return_name(id: int) -> String:
	return FloorCatalog.return_name(id)
static func world_size(id: int) -> Vector2:
	return FloorCatalog.world_size(id, DEFAULT_WORLD_SIZE)
static func world_scene(id: int) -> String:
	return FloorCatalog.world_scene(id, WORLD_SCENE)
static func configuration(id: int) -> Dictionary:
	if not valid(id):
		return {}
	return {"id": "mata_%d" % id, "number": id, "required_defeats": REQUIRED_DEFEATS,
		"difficulty": difficulty(id), "reward_multiplier": FLOORS[str(id)].rewards,
		"world_scene": world_scene(id), "arena_scene": ARENA_SCENE, "tower_script": TOWER_SCRIPT}
