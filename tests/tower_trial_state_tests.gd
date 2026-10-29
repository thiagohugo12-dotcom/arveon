extends RefCounted

static func run(suite) -> void:
	var trial := TowerTrial.new()
	suite.check(not trial.active() and trial.pending.is_empty(), "trial starts without a checkpoint")
	suite.check(TowerTrial.WAVES == [[0, 1, 2, 0], [0, 1, 2, 0, 1, 2], [0, 1, 2, 0, 1, 3]], "three exact wave rosters use existing common kinds and one elite")
	suite.check(trial.start() and not trial.start() and trial.wave == 1, "duplicate entry cannot create another attempt")
	suite.check(not trial.tick(3.9) and trial.tick(0.2) and not trial.tick(100.0), "four second preparation spawns once")
	for id in range(1, 5):
		trial.register(id)
	trial.register(1)
	suite.check(trial.pending.size() == 4 and not trial.record_defeat(1, false, trial.attempt_id), "registration duplicates and damage cannot complete wave")
	suite.check(not trial.record_defeat(1, true, trial.attempt_id - 1) and trial.pending.size() == 4, "late callback from old attempt rejected")
	for id in range(1, 4):
		suite.check(not trial.record_defeat(id, true, trial.attempt_id), "wave waits for all real deaths " + str(id))
	suite.check(trial.record_defeat(4, true, trial.attempt_id) and trial.phase == TowerTrial.Phase.INTERVAL and trial.cleared_waves == 1, "last real death completes first wave once")
	suite.check(not trial.record_defeat(4, true, trial.attempt_id) and not trial.tick(0.0), "duplicate death cannot heal or bypass preparation")
	suite.check(trial.tick(4.0) and trial.wave == 2 and not trial.tick(4.0), "second wave starts once after interval")
	var token := trial.attempt_id
	trial.end()
	suite.check(trial.start() and trial.wave == 1 and trial.attempt_id > token and trial.cleared_waves == 0, "abandon or death discards every checkpoint and renews token")
	for x in range(45, 676, 90):
		for y in range(45, 496, 90):
			var player := TowerTrial.ORIGIN + Vector2(x, y)
			var points := trial.spawn_positions(player, 6)
			var valid := points.size() == 6
			for i in range(points.size()):
				valid = valid and TowerTrial.BOUNDS.grow(-45).has_point(points[i]) and points[i].distance_to(player) >= 170.0
				for j in range(i):
					valid = valid and points[i].distance_to(points[j]) >= 90.0
			suite.check(valid, "six separated valid spawns across arena player grid (%d,%d)" % [x, y])
	var health := Health.new()
	suite.root.add_child(health)
	health.initialize(100)
	health.damage(10)
	suite.check(health.heal(15) == 10 and health.current == 100 and health.heal(15) == 0, "interval healing clamps to maximum")
	health.damage(100)
	suite.check(health.heal(15) == 0 and health.current == 0, "interval healing cannot revive a dead player")
	health.queue_free()

