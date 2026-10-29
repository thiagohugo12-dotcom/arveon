extends RefCounted
const TRIAL = preload("res://tests/tower_trial_tests.gd")

static func freeze(main) -> void:
	TRIAL._freeze(main)
	for actor in main.get_children():
		if actor is EnemyActor:
			actor.set_physics_process(false)

static func run_world(suite) -> void:
	var old_path := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://qa_campaign_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	freeze(main)
	await suite.frames()
	var p: GameProgress = main.progress
	p.bag["Madeira"] = 4
	p.chest["Ervas"] = 3
	p.equipment.espada = 2
	main._save_progress()
	var equipment := p.equipment.duplicate()
	main.player.health.damage(7)
	var hp_before: int = main.player.health.current
	main._travel_floor(2)
	suite.check(not main.transitioning and p.ascension.current_floor == 1, "locked floor cannot be accessed by direct travel")
	for id in range(1, 6):
		if id > 1:
			var before := [p.xp, p.gold, p.bag.duplicate(), p.equipment.duplicate(), main.player.health.current]
			await main._travel_floor(id)
			freeze(main)
			suite.check(p.ascension.current_floor == id and [p.xp, p.gold, p.bag, p.equipment, main.player.health.current] == before, "travel preserves all global player state to floor " + str(id))
			suite.check(main.player.position == SafeCamp.respawn_for_floor(id) and not main.player.test_move(main.player.transform, Vector2(1,0)), "safe unblocked arrival on floor " + str(id))
		suite.check(main.world.scene_file_path == FloorConfig.world_scene(id) and main.tower_view.position == TowerEntrance.position_for_floor(id) and TowerEntrance.POSITION == Vector2(830,1290) and TowerEntrance.LEGACY_POSITION == Vector2(1130,455), "each floor places its Tower inside its own map " + str(id))
		var expected_heading := "Vale das Pedras · Andar 2" if id == 2 else "Mata · Andar %d" % id
		var initial_hp := 108 if id == 2 else 48
		suite.check(main.enemy.health.maximum == roundi(initial_hp * FloorConfig.difficulty(id)) and main.hud.heading.text == expected_heading, "active floor initial enemy and HUD use actual configuration " + str(id))
		main.player.position = TowerEntrance.position_for_floor(id) + Vector2(0,35)
		main._interact()
		await suite.frames()
		suite.check(main.hud.station_panel.visible and main.hud.floor_buttons.size() == 10 and main.hud.tower_action_button.disabled, "travel panel remains accessible before floor requirement " + str(id))
		main.hud.close_station()
		main._enter_trial()
		suite.check(not main.trial.active() and not main.transitioning, "trial blocked independently at zero on floor " + str(id))
		p.ascension.defeats[str(id)] = 49
		var actor: EnemyActor = main.enemy
		actor.receive_damage(100000)
		main._on_enemy_defeated(0, actor)
		suite.check(p.ascension.defeats[str(id)] == 50 and p.ascension.entrance_unlocked(), "one actual death reaches cap once in current floor " + str(id))
		for previous in range(1,id):
			suite.check(p.ascension.defeats[str(previous)] == 50 and p.ascension.completed_trials[str(previous)], "later defeat preserves earlier conquest %d/%d" % [id,previous])
		await TRIAL._enter(suite,main)
		suite.check(main.trial.floor_id == id and main.trial.wave == 1 and main.hud.heading.text == "Torre · Andar %d" % id, "trial captures current floor and begins at first wave " + str(id))
		main._travel_floor(1 if id > 1 else 2)
		suite.check(not main.transitioning and p.ascension.current_floor == id, "travel cannot interrupt combat attempt " + str(id))
		for wave in range(3):
			TRIAL._spawn(main)
			var actors := TRIAL._actors(main)
			suite.check(actors.size() == [4,6,6][wave], "correct reused wave population floor %d wave %d" % [id,wave+1])
			var elite := 0
			for mob in actors:
				elite += 1 if mob.kind == 3 else 0
				var base_hp: int = {0:48,1:36,2:64,3:120,5:52,6:108,7:72}[mob.kind]
				suite.check(mob.stats.max_hp == roundi(base_hp * FloorConfig.difficulty(id)) and mob.position.distance_to(main.player.position) >= 170, "scaled wave member spawns safely floor %d wave %d" % [id,wave+1])
			var expected_elite := 0 if id == 2 else 1 if wave == 2 else 0
			suite.check(elite == expected_elite, "elite only in third wave floor " + str(id))
			main._process_trial(20)
			freeze(main)
			suite.check(TRIAL._actors(main).size() == actors.size(), "no duplicate wave spawn floor %d wave %d" % [id,wave+1])
			main.player.health.damage(main.player.health.current - 20)
			var before_hp: int = main.player.health.current
			TRIAL._kill_wave(main)
			var healed: int = main.player.health.current
			suite.check(healed == mini(main.player.health.maximum, before_hp + ceili(main.player.health.maximum * 0.15)) if wave < 2 else healed == before_hp, "one 15 percent heal only between waves floor %d wave %d" % [id,wave+1])
			for mob in actors:
				main._on_enemy_defeated(mob.kind, mob)
			suite.check(main.player.health.current == healed and p.ascension.defeats[str(id)] == 50, "duplicate deaths do not heal or increment cap floor %d wave %d" % [id,wave+1])
		main._process_trial(4)
		freeze(main)
		var boss: TowerGuardian = main.tower_guardian
		var guardian_base_hp := 520 if id == 2 else 360
		suite.check(boss.health.maximum == roundi(guardian_base_hp * FloorConfig.difficulty(id)) and boss.damage_scale == FloorConfig.difficulty(id), "same Guardian scales HP and attacks on floor " + str(id))
		boss.health.damage(ceili(boss.health.maximum * 0.5))
		boss._physics_process(0)
		suite.check(boss.phase_two, "existing phase two activates at half health on floor " + str(id))
		boss._physics_process(1.05)
		boss._physics_process(0.0)
		var xp_before: int = main.earned_xp
		var gold_before: int = main.earned_gold
		boss.receive_damage(100000)
		main._on_tower_guardian_defeated(4,boss,main.trial.attempt_id)
		suite.check(main.earned_xp == xp_before + FloorConfig.reward(180,id) and main.earned_gold == gold_before + FloorConfig.reward(40,id) and p.ascension.completed_trials[str(id)], "Guardian grants configured unique reward once on floor " + str(id))
		suite.check(p.ascension.unlocked_floors.size() == mini(5,id+1) and not p.ascension.can_travel(6), "sequential permanent unlock never creates floor six " + str(id))
		var restored := GameProgress.new()
		restored.save_path = path
		suite.check(restored.load_save() and restored.ascension.current_floor == id and restored.ascension.completed_trials[str(id)] and restored.xp == p.xp, "each conquest persists atomically on floor " + str(id))
		await main._return_from_trial(false)
		freeze(main)
	suite.check(p.ascension.campaign_completed and p.equipment == equipment and p.chest.Ervas == 3 and hp_before > 0, "fifth conquest records initial campaign while global equipment and chest survive")
	p.discovered_pois[Exploration.RESOURCE_SPOTS[0].id] = true
	main._save_progress()
	var archive := p.export_backup()
	var imported: GameProgress = p.preview_backup(archive)
	suite.check(imported != null and imported.ascension.campaign_completed and imported.ascension.current_floor == 5 and imported.discovered_pois == p.discovered_pois, "full five-floor backup validates and preserves active exploration")
	var fixture := FileAccess.open("res://build/campaign-save-fixture.json", FileAccess.WRITE)
	fixture.store_string(archive)
	fixture.close()
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		main.player.position = TowerEntrance.position_for_floor(p.ascension.current_floor) + Vector2(0,35)
		main._interact()
		await suite.frames(3)
		suite.check(main.hud.station_panel.get_global_rect().encloses(main.hud.travel_button.get_global_rect()) and main.hud.travel_button.size.y >= 44 and main.input_driver.blocked, "floor selection touch footer and modal fit " + str(resolution))
		main.hud.station_scroll.scroll_vertical = 10000
		await suite.frames(3)
		var button: Button = main.hud.floor_buttons[4]
		TRIAL._tap(main.hud,button)
		await suite.frames()
		suite.check(main.hud.selected_floor == 5 and main.hud.travel_button.disabled, "scrolled touch selects current floor without duplicate travel " + str(resolution))
		TRIAL._tap(main.hud, main.hud.station_close_button)
		suite.check(not main.input_driver.blocked and not main.hud.station_panel.visible, "selection closes without joystick conflict " + str(resolution))
	await main._travel_floor(1)
	freeze(main)
	suite.check(p.ascension.current_floor == 1 and p.discovered_pois.is_empty() and p.floor_states["5"].discovered_pois.size() == 1, "return to conquered floor restores independent exploration")
	await main._travel_floor(5)
	freeze(main)
	await TRIAL._enter(suite,main)
	TRIAL._spawn(main)
	main._save_progress()
	main.queue_free()
	await suite.frames()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	freeze(main)
	suite.check(main.progress.ascension.current_floor == 5 and main.progress.ascension.campaign_completed and not main.trial.active() and main.player.position == SafeCamp.RESPAWN, "reload during floor five trial restores safe Mata five without checkpoint")
	await TRIAL._enter(suite,main)
	TRIAL._spawn(main)
	main.progress.bag["Couro"] = 3
	var bag_before: Dictionary = main.progress.bag.duplicate()
	main.player.health.damage(100000)
	await TRIAL._transition(suite,main)
	var lost := 0
	for item: String in GameProgress.ITEMS:
		lost += int(bag_before.get(item,0)) - int(main.progress.bag.get(item,0))
	suite.check(lost == 1 and not main.trial.active() and main.progress.ascension.current_floor == 5 and main.progress.ascension.defeats["5"] == 50, "floor five death applies normal penalty once and retains conquest")
	await TRIAL._enter(suite,main)
	suite.check(main.trial.wave == 1, "floor five death restarts first wave without checkpoint")
	var gold_before: int = main.earned_gold
	bag_before = main.progress.bag.duplicate()
	await main._return_from_trial(false)
	suite.check(main.earned_gold == gold_before and main.progress.bag == bag_before and main.player.position == SafeCamp.RESPAWN, "floor five abandonment returns safely without death penalty")
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH",old_path)
