extends RefCounted

static func run(suite) -> void:
	var p := GameProgress.new()
	p.save_path = "user://qa_record_%d.json" % Time.get_ticks_usec()
	suite.check(not p.load_save() and not p.save_blocked and p.ascension.defeats["1"] == 0, "new record starts empty and writable")
	suite.check(p.save() and p.disk_writes == 1, "new record writes a valid v6 snapshot")
	for i in range(10):
		p.save()
	suite.check(p.disk_writes == 1, "unchanged autosave performs no additional disk writes")
	p.xp = 500
	p.gold = 75
	p.kills = 51
	p.bag = {"Couro": 7, "Madeira": 2}
	p.chest = {"Essência": 3}
	p.attributes["Vitalidade"] = 2
	p.skills["Corte Circular"] = 2
	p.equipment["espada"] = 3
	p.ascension.defeats["1"] = 50
	p.adventures["elite"] = 1
	p.opened_caches["west_roots"] = true
	p.harvested_until["herb_west"] = 1800000000
	p.discovered_pois["herb_west"] = true
	p.mission_index = 1
	p.mission_progress = 2
	p.mission_completed = 3
	suite.check(p.save() and p.disk_writes == 2 and FileAccess.file_exists(p.save_path + ".bak"), "important change saves and retains previous valid snapshot")
	var loaded := GameProgress.new()
	loaded.save_path = p.save_path
	suite.check(loaded.load_save() and loaded.to_json() == p.to_json(), "fresh process-style load restores all permanent fields and smith +3")
	var backup := p.export_backup()
	var candidate = p.preview_backup(backup)
	suite.check(candidate != null and candidate.to_json() == p.to_json(), "export archive validates checksum and complete v6 payload")
	var broken := backup.replace('"sha256":"', '"sha256":"0')
	suite.check(p.preview_backup(broken) == null, "altered checksum rejects archive")
	var envelope := JSON.parse_string(backup) as Dictionary
	envelope.payload = envelope.payload.replace('"gold":75', '"gold":76')
	suite.check(p.preview_backup(JSON.stringify(envelope)) == null, "altered payload rejects archive before any mutation")
	envelope = JSON.parse_string(backup)
	envelope.archive_version = 2
	suite.check(p.preview_backup(JSON.stringify(envelope)) == null, "unknown archive version rejected")
	suite.check(p.preview_backup("not JSON") == null and p.preview_backup("x".repeat(GameProgress.MAX_SAVE_BYTES + 1)) == null, "malformed and oversized imports rejected quietly")
	var payload := JSON.parse_string(p.to_json()) as Dictionary
	payload.version = 7
	suite.check(p.preview_backup(JSON.stringify(payload)) == null, "future save version rejected")
	payload = JSON.parse_string(p.to_json())
	payload.ascension.unlocked_floors = [1, 2]
	suite.check(p.preview_backup(JSON.stringify(payload)) == null, "import cannot unlock unimplemented floor 2")
	payload = JSON.parse_string(p.to_json())
	payload.ascension.completed_trials["1"] = true
	suite.check(p.preview_backup(JSON.stringify(payload)) == null, "import cannot complete unavailable ascension")
	var before := FileAccess.get_file_as_string(p.save_path)
	suite.check(not p.import_backup(backup, false) and FileAccess.get_file_as_string(p.save_path) == before, "preview without confirmation never replaces save")
	suite.check(not p.import_backup(broken, true) and FileAccess.get_file_as_string(p.save_path) == before, "confirmation cannot bypass integrity validation")
	p.gold = 99
	p.save()
	suite.check(p.import_backup(backup, true) and p.gold == 75, "confirmed import replaces rather than adds rewards")
	var after_import := p.to_json()
	suite.check(p.import_backup(backup, true) and p.to_json() == after_import, "repeated import cannot duplicate rewards")
	var restored := GameProgress.new()
	restored.save_path = p.save_path
	suite.check(restored.load_save() and restored.to_json() == after_import, "confirmed import survives reload")
	_write(p.save_path, "{truncated")
	var recovered := GameProgress.new()
	recovered.save_path = p.save_path
	suite.check(recovered.load_save() and recovered.save_blocked and recovered.gold == 75, "truncated primary recovers previous valid copy read-only")
	suite.check(not recovered.save() and FileAccess.get_file_as_string(p.save_path) == "{truncated", "recovery never overwrites corrupt original without confirmation")
	suite.check(recovered.import_backup(backup, true) and not recovered.save_blocked, "explicit import unlocks protected recovery")
	var legacy := JSON.parse_string(p.to_json()) as Dictionary
	legacy.version = 1
	legacy.erase("rpg")
	legacy.erase("ascension")
	_write(p.save_path, JSON.stringify(legacy))
	var migrant := GameProgress.new()
	migrant.save_path = p.save_path
	suite.check(migrant.load_save() and migrant.ascension.entrance_unlocked() and migrant.gold == 75, "legacy migration retains permanent entrance and economy")
	var original := FileAccess.get_file_as_string(p.save_path)
	suite.check(migrant.save() and FileAccess.get_file_as_string(p.save_path + ".v1.original") == original, "migration preserves original before writing upgraded schema")
	payload = JSON.parse_string(p.to_json())
	payload.version = 99
	_write(p.save_path, JSON.stringify(payload))
	var future := GameProgress.new()
	future.save_path = p.save_path
	suite.check(not future.load_save() and future.save_blocked and not future.save(), "future saves remain untouched even with valid older backup")
	suite.check(p.preview_backup(original) != null, "raw legacy JSON can be schema-validated for explicit import")
	# Current fixture is also used for actual exported Web browser reload tests.
	DirAccess.make_dir_recursive_absolute("res://build")
	_write("res://build/web-save-fixture.json", backup)

static func run_world(suite, game) -> void:
	for viewport: Vector2i in [Vector2i(360,640), Vector2i(390,844), Vector2i(640,360), Vector2i(960,540)]:
		game.get_window().size = viewport
		await suite.frames(3)
		game._open_record()
		await suite.frames(2)
		var panel: SavePanel = game.hud.save_panel
		suite.check(panel.visible and game.input_driver.blocked and not game.hud.dash_button.enabled, "record modal blocks combat %s" % viewport)
		for button in [panel.export_button, panel.import_button, panel.close_button]:
			suite.check(button.size.y >= 44 and panel.get_global_rect().encloses(button.get_global_rect()), "record touch target fits %s" % viewport)
		var invalid_before: String = game.progress.to_json()
		game._preview_import("bad")
		suite.check(game.pending_import.is_empty() and not panel.confirm_button.visible and game.progress.to_json() == invalid_before, "invalid UI import preserves current progress %s" % viewport)
		game._preview_import(game.progress.export_backup())
		await suite.frames(2)
		suite.check(panel.confirm_button.visible and panel.cancel_button.visible and game.input_driver.blocked, "valid UI import requires explicit confirmation %s" % viewport)
		var event := InputEventScreenTouch.new()
		event.position = panel.cancel_button.get_global_rect().get_center()
		event.pressed = true
		game.hud._input(event)
		suite.check(game.pending_import.is_empty() and not panel.confirm_button.visible and panel.visible, "touch cancellation leaves progress and modal intact %s" % viewport)
		event.position = panel.close_button.get_global_rect().get_center()
		game.hud._input(event)
		suite.check(not panel.visible and not game.input_driver.blocked, "touch close restores controls %s" % viewport)
	var writes: int = game.progress.disk_writes
	game.autosave_left = 0.0
	game._process(0.01)
	suite.check(game.progress.disk_writes == writes, "periodic exploration autosave skips unchanged state")

static func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
