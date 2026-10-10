extends RefCounted

static func run_state(suite) -> void:
	var progress := GameProgress.new()
	var state := progress.ascension
	suite.check(state.summary() == "Torre: 0/50 criaturas" and not state.entrance_unlocked(), "new save starts with locked tower at 0/50")
	suite.check(state.current_floor == 1 and state.unlocked_floors == [1] and not state.completed_trials["1"], "only Mata unlocked and trial incomplete")
	suite.check(not state.record_defeat(2) and not state.record_defeat(0) and state.defeats["1"] == 0, "other floors cannot advance Mata requirement")
	state.record_defeat(1)
	suite.check(state.defeats["1"] == 1 and progress.xp == 0 and progress.gold == 0, "tower count changes without XP or gold rewards")
	for i in range(48):
		state.record_defeat(1)
	suite.check(state.defeats["1"] == 49 and not state.entrance_unlocked(), "tower remains locked at 49")
	suite.check(state.record_defeat(1) and state.entrance_unlocked() and state.defeats["1"] == 50, "exactly 50 defeats unlock entrance")
	suite.check(not state.record_defeat(1) and state.defeats["1"] == 50 and state.unlocked_floors == [1], "counter capped and no second floor unlocked")
	progress.save_path = "user://qa_tower_state_%d.json" % Time.get_ticks_usec()
	progress.add_item("Couro")
	progress.death_loss()
	suite.check(state.defeats["1"] == 50 and progress.bag.is_empty(), "death material loss preserves tower count")
	progress.gold = 17
	progress.kills = 23
	suite.check(progress.save(), "tower state saves in v6")
	var saved := JSON.parse_string(FileAccess.get_file_as_string(progress.save_path)) as Dictionary
	var loaded := GameProgress.new()
	loaded.save_path = progress.save_path
	suite.check(loaded.load_save() and loaded.ascension.to_save() == state.to_save() and loaded.gold == 17, "v6 tower state roundtrips with existing economy")
	for version in range(1, 6):
		var legacy := saved.duplicate(true)
		legacy.version = version
		legacy.erase("ascension")
		if version == 4:
			legacy.attributes = progress.attributes.duplicate()
		_write(progress.save_path, legacy)
		suite.check(loaded.load_save() and loaded.ascension.defeats["1"] == 23 and loaded.gold == 17 and loaded.kills == 23, "v%d migration credits previous real Mata kills without changing rewards" % version)
	var old_many := saved.duplicate(true)
	old_many.version = 5
	old_many.kills = 99
	old_many.erase("ascension")
	_write(progress.save_path, old_many)
	suite.check(loaded.load_save() and loaded.ascension.defeats["1"] == 50 and loaded.kills == 99, "legacy tower count clamps without limiting lifetime kills")
	for invalid_field: String in ["missing", "fraction", "negative", "floor", "unlock", "trial"]:
		var invalid := saved.duplicate(true)
		match invalid_field:
			"missing": invalid.erase("ascension")
			"fraction": invalid.ascension.defeats["1"] = 23.5
			"negative": invalid.ascension.defeats["1"] = -1
			"floor": invalid.ascension.current_floor = 2
			"unlock": invalid.ascension.unlocked_floors = [1, 2]
			"trial": invalid.ascension.completed_trials["1"] = true
		_write(progress.save_path, invalid)
		var before := loaded.ascension.to_save()
		suite.check(not loaded.load_save() and loaded.ascension.to_save() == before and loaded.gold == 17, "invalid %s tower state rejected atomically" % invalid_field)
	var over_cap := saved.duplicate(true)
	over_cap.ascension.defeats["1"] = 100
	_write(progress.save_path, over_cap)
	suite.check(loaded.load_save() and loaded.ascension.defeats["1"] == 50, "v6 input above threshold normalizes to 50")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress.save_path))

static func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
