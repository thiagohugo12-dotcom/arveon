class_name TowerTrial
extends RefCounted

# Attempt state never enters GameProgress or the save. Only the entrance is permanent.
enum Phase { IDLE, PREPARING, FIGHTING, INTERVAL, AWAITING_GUARDIAN, GUARDIAN, VICTORY }
const WAVES := [[0, 1, 2, 0], [0, 1, 2, 0, 1, 2], [0, 1, 2, 0, 1, 3]]
const VALE_WAVES := [[5, 6, 7, 5], [5, 6, 7, 5, 6, 7], [5, 6, 7, 5, 6, 7]]
const PREPARATION_SECONDS := 4.0
const ORIGIN := Vector2(1600, 0)
const SIZE := Vector2(720, 540)
const BOUNDS := Rect2(ORIGIN, SIZE)
const ENTRY := ORIGIN + Vector2(360, 420)
const EXIT := ORIGIN + Vector2(360, 484)
const SPAWN_POINTS := [Vector2(100, 100), Vector2(260, 100), Vector2(460, 100),
	Vector2(620, 100), Vector2(100, 270), Vector2(620, 270), Vector2(100, 440),
	Vector2(260, 440), Vector2(460, 440), Vector2(620, 440), Vector2(360, 270)]
var phase := Phase.IDLE
var floor_id := 1
var wave := 0
var attempt_id := 0
var preparation_left := 0.0
var pending: Dictionary = {}
var cleared_waves := 0

func active() -> bool:
	return phase != Phase.IDLE

func wave_kinds() -> Array:
	return (VALE_WAVES if floor_id == 2 else WAVES)[wave - 1] if wave >= 1 and wave <= WAVES.size() else []

func start(id: int = 1) -> bool:
	if active() or not FloorConfig.valid(id):
		return false
	floor_id = id
	attempt_id += 1
	wave = 1
	cleared_waves = 0
	pending.clear()
	phase = Phase.PREPARING
	preparation_left = PREPARATION_SECONDS
	return true

func tick(delta: float) -> bool:
	if phase == Phase.AWAITING_GUARDIAN:
		preparation_left = maxf(0.0, preparation_left - maxf(0.0, delta))
		if preparation_left > 0.0:
			return false
		phase = Phase.GUARDIAN
		return true
	if phase != Phase.PREPARING and phase != Phase.INTERVAL:
		return false
	preparation_left = maxf(0.0, preparation_left - maxf(0.0, delta))
	if preparation_left > 0.0:
		return false
	if phase == Phase.INTERVAL:
		wave += 1
	phase = Phase.FIGHTING
	return true # Only this transition may spawn a wave.

func register(actor_id: int) -> void:
	if phase == Phase.FIGHTING:
		pending[actor_id] = true

func record_defeat(actor_id: int, dead: bool, token: int) -> bool:
	if phase != Phase.FIGHTING or not dead or token != attempt_id or not pending.has(actor_id):
		return false
	pending.erase(actor_id)
	if not pending.is_empty():
		return false
	cleared_waves += 1
	phase = Phase.AWAITING_GUARDIAN if wave == WAVES.size() else Phase.INTERVAL
	preparation_left = PREPARATION_SECONDS if phase == Phase.INTERVAL else PREPARATION_SECONDS
	return true # One completion notification and at most one heal per interval.

func end() -> void:
	phase = Phase.IDLE
	pending.clear()
	preparation_left = 0.0
	wave = 0
	cleared_waves = 0

func spawn_positions(player_position: Vector2, count: int) -> Array[Vector2]:
	var selected: Array[Vector2] = []
	for local_point: Vector2 in SPAWN_POINTS:
		var point := ORIGIN + local_point
		if point.distance_squared_to(player_position) < 170.0 * 170.0:
			continue
		selected.append(point)
		if selected.size() == count:
			break
	return selected

func guardian_spawn_position(player_position: Vector2) -> Vector2:
	if floor_id != 1 and floor_id != 2:
		return spawn_positions(player_position, 1)[0]
	var candidates: Array[Vector2] = [Vector2(360, 245), Vector2(200, 300), Vector2(520, 300), Vector2(360, 350)]
	if floor_id == 2:
		candidates = [Vector2(360, 190), Vector2(200, 260), Vector2(520, 260), Vector2(360, 350)]
	for local_point: Vector2 in candidates:
		var point := ORIGIN + local_point
		if point.distance_squared_to(player_position) >= 170.0 * 170.0:
			return point
	return ORIGIN + Vector2(360, 190)

func summary() -> String:
	if phase == Phase.AWAITING_GUARDIAN:
		return "Três hordas superadas\nGuardião em %ds" % ceili(preparation_left)
	if phase == Phase.GUARDIAN:
		return "%s\nDesvie dos ataques avisados" % FloorConfig.tower_guardian_name(floor_id)
	if phase == Phase.VICTORY:
		return "Ascensão conquistada\nAndar %d" % floor_id
	var name: String = ["Iniciação", "Resistência", "Sobrevivência"][maxi(0, wave - 1)]
	if phase == Phase.PREPARING or phase == Phase.INTERVAL:
		return "Horda %d/3 · Preparação %ds\nPróxima: %s" % [wave + (1 if phase == Phase.INTERVAL else 0), ceili(preparation_left), ["Iniciação", "Resistência", "Sobrevivência"][mini(2, wave if phase == Phase.INTERVAL else wave - 1)]]
	return "Horda %d/3 · %s\nRestam %d criaturas" % [wave, name, pending.size()]
