extends RefCounted
static func run(suite) -> void:
	var p := GameProgress.new()
	p.gold = 77
	p.bag["Couro"] = 3
	p.chest["Seda"] = 2
	var spot: Dictionary = Exploration.RESOURCE_SPOTS[0]
	p.harvested_until[spot.id] = 123
	p.discovered_pois[spot.id] = true
	for id in range(1,6):
		var config := FloorConfig.configuration(id)
		suite.check(config.number == id and config.world_scene == FloorConfig.world_scene(id) and config.arena_scene == FloorConfig.ARENA_SCENE and is_equal_approx(config.difficulty, [1.0, 1.5, 2.1, 2.8, 3.6][id-1]), "central reusable floor configuration " + str(id))
		suite.check(p.ascension.defeats[str(id)] == 0 and not p.ascension.completed_trials[str(id)], "independent new floor requirement " + str(id))
		suite.check(p.switch_floor(id) and not p.switch_floor(6) and not p.ascension.complete_forest_trial(), "only unlocked floor accepts travel and no premature victory " + str(id))
		if id > 1:
			suite.check(p.harvested_until.is_empty() and p.discovered_pois.is_empty() and p.bag["Couro"] == 3 and p.gold == 77, "fresh exploration with global inventory and gold " + str(id))
		for i in range(49):
			p.ascension.record_defeat(id)
		suite.check(not p.ascension.entrance_unlocked() and not p.ascension.record_defeat(6) and not p.ascension.record_defeat(1 if id>1 else 2), "own floor only and exactly fifty kills required " + str(id))
		p.ascension.record_defeat(id)
		suite.check(p.ascension.entrance_unlocked() and not p.ascension.record_defeat(id) and p.ascension.complete_forest_trial() and not p.ascension.complete_forest_trial(), "one real ascension claim after fifty " + str(id))
		var restored := GameProgress.new()
		suite.check(restored.load_text(p.to_json()) and restored.ascension.to_save() == p.ascension.to_save(), "per floor completion roundtrip " + str(id))
	suite.check(p.ascension.campaign_completed and p.ascension.unlocked_floors == [1,2,3,4,5] and not p.ascension.can_travel(6), "fifth victory completes initial campaign without a sixth floor")
	p.switch_floor(1)
	suite.check(p.harvested_until[spot.id] == 123 and p.discovered_pois[spot.id] and p.chest["Seda"] == 2, "return preserves old floor exploration and shared service chest")
	var old := JSON.parse_string(p.to_json()) as Dictionary
	old.erase("floor_states")
	old.ascension = {"current_floor":1,"unlocked_floors":[1,2],"defeats":{"1":50},"completed_trials":{"1":true},"forest_seal":true}
	var migrated := GameProgress.new()
	suite.check(migrated.load_text(JSON.stringify(old)) and migrated.ascension.unlocked_floors == [1,2] and migrated.ascension.forest_seal and migrated.harvested_until[spot.id] == 123 and not migrated.ascension.completed_trials["2"], "v0.5.2 migration preserves first victory seal valid second unlock and exploration")
	var valid := p.to_json()
	for problem in ["skip", "current", "count", "campaign", "seal", "extra", "duplicates", "exploration"]:
		var bad := JSON.parse_string(valid) as Dictionary
		match problem:
			"skip": bad.ascension.completed_trials["2"] = false
			"current": bad.ascension.current_floor = 6
			"count": bad.ascension.defeats["4"] = 12
			"campaign": bad.ascension.campaign_completed = false
			"seal": bad.ascension.forest_seal = false
			"extra": bad.ascension.defeats["6"] = 0
			"duplicates": bad.ascension.unlocked_floors = [1,2,3,4,4]
			"exploration": bad.floor_states["2"].opened_caches["nonexistent"] = true
		suite.check(not migrated.load_text(JSON.stringify(bad)) and migrated.ascension.unlocked_floors == [1,2], "invalid campaign state rejected transactionally " + problem)
