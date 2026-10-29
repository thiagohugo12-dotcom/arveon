class_name AscensionProgress
extends RefCounted

const FLOORS := FloorConfig.FLOORS
const GUARDIAN_XP := 180
const GUARDIAN_GOLD := 40
var current_floor := 1
var unlocked_floors: Array[int] = [1]
var defeats: Dictionary = {}
var completed_trials: Dictionary = {}
var forest_seal := false
var campaign_completed := false
func _init() -> void:
	for id in range(1, FloorConfig.MAX_FLOORS + 1):
		defeats[str(id)] = 0
		completed_trials[str(id)] = false
func complete_forest_trial() -> bool:
	var key := str(current_floor)
	if not entrance_unlocked() or completed_trials[key]:
		return false
	completed_trials[key] = true
	forest_seal = completed_trials["1"]
	campaign_completed = completed_trials["5"]
	var next := current_floor + 1
	if FloorConfig.valid(next) and not unlocked_floors.has(next):
		unlocked_floors.append(next)
	return true
func can_travel(id: int) -> bool:
	return FloorConfig.valid(id) and unlocked_floors.has(id)
func required_defeats(floor_id: int = 0) -> int:
	return FloorConfig.REQUIRED_DEFEATS if FloorConfig.valid(current_floor if floor_id == 0 else floor_id) else 0
func record_defeat(floor_id: int) -> bool:
	var key := str(floor_id)
	if floor_id != current_floor or not can_travel(floor_id) or int(defeats[key]) >= required_defeats(floor_id):
		return false
	defeats[key] = int(defeats[key]) + 1
	return true
func entrance_unlocked(floor_id: int = 0) -> bool:
	var id := current_floor if floor_id == 0 else floor_id
	return can_travel(id) and int(defeats[str(id)]) >= required_defeats(id)
func summary() -> String:
	return "Torre: %d/%d criaturas" % [defeats[str(current_floor)], required_defeats()]
func to_save() -> Dictionary:
	return {"current_floor": current_floor, "unlocked_floors": unlocked_floors.duplicate(),
		"defeats": defeats.duplicate(), "completed_trials": completed_trials.duplicate(),
		"forest_seal": forest_seal, "campaign_completed": campaign_completed}
static func from_save(value: Variant) -> AscensionProgress:
	if not value is Dictionary or not value.get("current_floor") is float or value.current_floor != floorf(value.current_floor) or not FloorConfig.valid(int(value.current_floor)) or not value.get("unlocked_floors") is Array:
		return null
	if not value.get("defeats") is Dictionary or not value.get("completed_trials") is Dictionary:
		return null
	var legacy: bool = value.defeats.size() == 1 and value.completed_trials.size() == 1
	if not legacy and (value.defeats.size() != 5 or value.completed_trials.size() != 5):
		return null
	if legacy and value.current_floor != 1.0:
		return null
	var result := AscensionProgress.new()
	for id in range(1, 2 if legacy else 6):
		var key := str(id)
		var count: Variant = value.defeats.get(key)
		if not count is float or count < 0 or count != floorf(count) or count > 100000000 or not value.completed_trials.get(key) is bool:
			return null
		result.defeats[key] = mini(int(count), 50)
		result.completed_trials[key] = value.completed_trials[key]
	var expected: Array[int] = [1]
	var previous := true
	for id in range(1,6):
		var done: bool = result.completed_trials[str(id)]
		if (done and (not previous or result.defeats[str(id)] != 50)) or (not expected.has(id) and result.defeats[str(id)] != 0):
			return null
		if done and id < 5:
			expected.append(id + 1)
		previous = done
	if value.unlocked_floors.size() != expected.size() or not expected.has(int(value.current_floor)):
		return null
	for i in range(expected.size()):
		if not value.unlocked_floors[i] is float or value.unlocked_floors[i] != float(expected[i]):
			return null
	var seal: Variant = value.get("forest_seal", false)
	var campaign: Variant = value.get("campaign_completed", false)
	if not seal is bool or seal != result.completed_trials["1"] or not campaign is bool or campaign != result.completed_trials["5"]:
		return null
	result.current_floor = int(value.current_floor)
	result.unlocked_floors.assign(expected)
	result.forest_seal = seal
	result.campaign_completed = campaign
	return result
