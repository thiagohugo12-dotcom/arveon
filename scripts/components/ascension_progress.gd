class_name AscensionProgress
extends RefCounted

# Only implemented floors belong here. Future proof completion/unlocks are not
# exposed as actions in v0.5.0; presentation cannot grant an unlocked floor.
const FLOORS := {"1": {"required_defeats": 50, "preview_waves": 3, "guardian": "Guardião da Mata"}}
var current_floor := 1
var unlocked_floors: Array[int] = [1]
var defeats: Dictionary = {"1": 0}
var completed_trials: Dictionary = {"1": false}
var forest_seal := false
const GUARDIAN_XP := 180
const GUARDIAN_GOLD := 40

func complete_forest_trial() -> bool:
	if not entrance_unlocked() or completed_trials["1"]:
		return false
	completed_trials["1"] = true
	forest_seal = true
	unlocked_floors = [1, 2]
	return true

func required_defeats(floor_id: int = 1) -> int:
	return int(FLOORS[str(floor_id)].required_defeats) if FLOORS.has(str(floor_id)) else 0

func record_defeat(floor_id: int) -> bool:
	var key := str(floor_id)
	if not FLOORS.has(key) or not unlocked_floors.has(floor_id) or defeats[key] >= required_defeats(floor_id):
		return false
	defeats[key] = int(defeats[key]) + 1
	return true

func entrance_unlocked(floor_id: int = 1) -> bool:
	return FLOORS.has(str(floor_id)) and unlocked_floors.has(floor_id) and int(defeats[str(floor_id)]) >= required_defeats(floor_id)

func summary() -> String:
	return "Torre: %d/%d criaturas" % [defeats[str(current_floor)], required_defeats(current_floor)]

func to_save() -> Dictionary:
	return {"current_floor": current_floor, "unlocked_floors": unlocked_floors.duplicate(),
		"defeats": defeats.duplicate(), "completed_trials": completed_trials.duplicate(), "forest_seal": forest_seal}

static func from_save(value: Variant) -> AscensionProgress:
	if not value is Dictionary or not value.get("current_floor") is float or value.current_floor != 1.0 or not value.get("unlocked_floors") is Array:
		return null
	if not value.unlocked_floors in [[1.0], [1.0, 2.0]] or not value.get("defeats") is Dictionary or not value.get("completed_trials") is Dictionary:
		return null
	if value.defeats.size() != FLOORS.size() or value.completed_trials.size() != FLOORS.size():
		return null
	var result := AscensionProgress.new()
	for key: String in FLOORS:
		var count: Variant = value.defeats.get(key)
		if not count is float or count < 0 or count != floorf(count) or count > 100000000:
			return null
		if not value.completed_trials.get(key) is bool:
			return null
		result.defeats[key] = mini(int(count), int(FLOORS[key].required_defeats))
	var completed: bool = value.completed_trials["1"]
	var seal: Variant = value.get("forest_seal", false)
	if not seal is bool or seal != completed or (value.unlocked_floors == [1.0, 2.0]) != completed or (completed and result.defeats["1"] != 50):
		return null
	result.completed_trials["1"] = completed
	result.forest_seal = seal
	result.unlocked_floors.assign([1, 2] if completed else [1])
	return result
