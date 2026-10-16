extends RefCounted
const TRIAL_TESTS = preload("res://tests/tower_trial_tests.gd")

static func reach_guardian(main) -> void:
	for wave in range(3):
		TRIAL_TESTS._spawn(main)
		TRIAL_TESTS._kill_wave(main)
	main._process_trial(4.0)
	TRIAL_TESTS._freeze(main)

static func run_world(suite) -> void:
	var old_path := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_guardian_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	TRIAL_TESTS._freeze(main)
	main.enemy.set_physics_process(false)
	var p: GameProgress = main.progress
	var player: PlayerActor = main.player
	var hud: GameHUD = main.hud
	main._spawn_tower_guardian()
	suite.check(not is_instance_valid(main.tower_guardian), "Guardian cannot spawn before entering trial")
	p.ascension.defeats["1"] = 50
	await TRIAL_TESTS._enter(suite, main)
	main._spawn_tower_guardian()
	suite.check(not is_instance_valid(main.tower_guardian), "Guardian cannot bypass the three waves")
	for wave in range(3):
		TRIAL_TESTS._spawn(main)
		TRIAL_TESTS._kill_wave(main)
		main._spawn_tower_guardian()
		suite.check(not is_instance_valid(main.tower_guardian), "Guardian waits through wave and presentation " + str(wave + 1))
	main._process_trial(3.9)
	suite.check(not is_instance_valid(main.tower_guardian), "Guardian presentation lasts four seconds without an extra heal")
	main._process_trial(0.2)
	TRIAL_TESTS._freeze(main)
	var boss: TowerGuardian = main.tower_guardian
	var id := boss.get_instance_id()
	main._spawn_tower_guardian()
	main._process_trial(100)
	TRIAL_TESTS._freeze(main)
	suite.check(boss.get_instance_id() == id and TRIAL_TESTS._actors(main).size() == 1 and main.trial.phase == TowerTrial.Phase.GUARDIAN, "Guardian spawns once in existing arena after third wave")
	suite.check(boss.health.maximum == 360 and boss.position.distance_to(player.position) >= 170 and boss.arena_bounds == TowerTrial.BOUNDS, "Guardian stats and separated spawn inside unchanged arena")
	var center := TowerTrial.ORIGIN + Vector2(360, 270)
	boss.position = center
	player.health.initialize(100)
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		boss.position = center
		player.position = center + direction * 65
		boss.action = TowerGuardian.Action.ROOTS
		boss._begin_attack()
		suite.check(boss.view.warning and boss.view.telegraph_direction.is_equal_approx(direction) and boss.action_left == 0.75, "frontal roots warning matches four-direction snapshot " + str(direction))
		suite.check(boss.roots_contains(center + direction * 89) and not boss.roots_contains(center + direction * 91) and not boss.roots_contains(center - direction * 40) and not boss.roots_contains(center + direction.orthogonal() * 50), "roots range front rear and side bounds " + str(direction))
		player.health.initialize(100)
		boss._physics_process(0.8)
		suite.check(player.health.current == 100, "roots telegraph itself causes no damage " + str(direction))
		boss._physics_process(0.02)
		boss._physics_process(0.02)
		suite.check(player.health.current == 82 and boss.attack_hit, "roots hit once across active frames " + str(direction))
	# A physical obstacle blocks root damage and charge movement.
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 90)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = center + Vector2(38, 0)
	main.add_child(wall)
	await suite.frames()
	player.position = center + Vector2(72, 0)
	player.health.initialize(100)
	boss.action = TowerGuardian.Action.ROOTS
	boss._begin_attack()
	boss._physics_process(0.8)
	boss._physics_process(0.02)
	suite.check(player.health.current == 100 and not boss.attack_hit, "root strike cannot cross a real World collision")
	boss.action = TowerGuardian.Action.CHARGE
	boss._begin_attack()
	boss._physics_process(0.8)
	boss._physics_process(0.2)
	suite.check(boss.position.x < wall.position.x and boss.state == TowerGuardian.State.RECOVERY and player.health.current == 100, "charge respects obstacle and opens recovery without through-wall damage")
	wall.queue_free()
	await suite.frames()
	boss.position = center
	player.position = center + Vector2(110, 0)
	player.health.initialize(100)
	boss.action = TowerGuardian.Action.SPIKES
	boss._begin_attack()
	var spikes := boss.spike_points.duplicate()
	suite.check(spikes.size() == 3 and boss.view.warning and boss.action_left == 1.0, "three bounded spike areas have a full second warning")
	boss._physics_process(0.9)
	suite.check(player.health.current == 100, "ground spike warning is harmless")
	boss._physics_process(0.2)
	boss._physics_process(0.01)
	player.position = spikes[1]
	boss._physics_process(0.01)
	suite.check(player.health.current == 84 and boss.attack_hit, "spike burst hits once even crossing another area")
	boss._physics_process(0.5)
	suite.check(boss.spike_points.is_empty() and not boss.view.warning, "temporary spike hazards clear completely after activation")
	# Dodge the original spot; hazards never follow the player.
	player.health.initialize(100)
	boss.action = TowerGuardian.Action.SPIKES
	boss._begin_attack()
	player.position = center + Vector2(-100, 0)
	boss._physics_process(1.0)
	boss._physics_process(0.1)
	suite.check(player.health.current == 100, "moving off telegraphed spikes avoids damage")
	boss.position = center
	player.position = center + Vector2(180, 0)
	boss.action = TowerGuardian.Action.CHARGE
	boss._begin_attack()
	player.position = center + Vector2(0, 180)
	boss._physics_process(0.8)
	boss._physics_process(0.2)
	suite.check(boss.aim == Vector2.RIGHT and boss.position.x > center.x and is_equal_approx(boss.position.y, center.y), "charge uses starting player position rather than homing")
	boss._physics_process(0.5)
	suite.check(not boss.attack_hit and boss.recovery_left == 1.4 and player.health.current == 100, "missed charge leaves a 1.4 second vulnerability window")
	boss.position = center
	player.position = center + Vector2(65, 0)
	boss.action = TowerGuardian.Action.CHARGE
	boss._begin_attack()
	boss._physics_process(0.8)
	boss._physics_process(0.12)
	boss._physics_process(0.12)
	suite.check(player.health.current == 80 and boss.attack_hit, "charge swept movement applies only one hit per execution")
	boss.position = TowerTrial.ORIGIN + Vector2(670, 270)
	player.position = TowerTrial.ORIGIN + Vector2(710, 270)
	boss.action = TowerGuardian.Action.CHARGE
	boss._begin_attack()
	boss._physics_process(0.8)
	boss._physics_process(0.65)
	suite.check(TowerTrial.BOUNDS.grow(-32).has_point(boss.position) and boss.position.x < TowerTrial.BOUNDS.end.x - 32, "Guardian cannot charge outside the arena")
	boss.health.damage(179)
	boss.state = TowerGuardian.State.RECOVERY
	boss._physics_process(0)
	suite.check(not boss.phase_two, "phase one remains above half HP")
	boss.health.damage(1)
	boss._physics_process(0)
	main._process_trial(0)
	TRIAL_TESTS._freeze(main)
	suite.check(boss.phase_two and boss.view.second_phase and hud.boss_bar.value == 180 and hud.boss_bar.max_value == 360 and hud.boss_name.text.contains("Fase 2"), "phase two and boss HUD start exactly at half HP")
	boss.action = TowerGuardian.Action.ROOTS
	boss._finish_attack()
	suite.check(is_equal_approx(boss.recovery_left, 0.8), "phase two moderately shortens normal recovery by twenty percent")
	boss.action = TowerGuardian.Action.CHARGE
	boss.attack_hit = false
	boss._finish_attack()
	suite.check(boss.recovery_left == 1.4, "phase two preserves missed charge vulnerability")
	boss.position = center
	player.position = center + Vector2(65, 0)
	player.health.initialize(100)
	boss.health.initialize(360)
	var health_before := boss.health.current
	player.attack.cooldown_left = 0
	player.attack.search_left = 0
	player.attack.tick(0.1, player)
	suite.check(boss.health.current < health_before and boss.view.damage_left > 0, "automatic attack and v0.4 feedback damage the Guardian")
	preload("res://tests/etapa2_fixtures.gd").unlock(main.progress)
	player.apply_progression(main.progress)
	for index in range(3):
		preload("res://tests/etapa2_fixtures.gd").reset(player)
		player.charge_left = 0
		suite.check(player.use_skill(index), "existing skill works against Guardian " + str(index))
	player.charge_left = 0
	player.fury_left = 0
	# Modal pauses the boss windup and blocks combat commands at every viewport.
	for resolution: Vector2i in [Vector2i(360,640), Vector2i(390,844), Vector2i(640,360), Vector2i(960,540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames(3)
		player.position = TowerTrial.EXIT + Vector2(0,-30)
		main._interact()
		await suite.frames()
		boss.action = TowerGuardian.Action.SPIKES
		boss._begin_attack()
		main._process_trial(10)
		boss._physics_process(0.5) # Modal guards even a physics tick queued before Main pauses it.
		suite.check(not boss.is_physics_processing() and boss.action_left == 1.0 and not player.use_skill(0), "mobile modal pauses hazards and skills " + str(resolution))
		TRIAL_TESTS._tap(hud, hud.station_close_button)
		main._process_trial(0)
		TRIAL_TESTS._freeze(main)
		player.dash.cooldown_left = 0
		TRIAL_TESTS._tap_action(hud.dash_button)
		player._physics_process(0.01)
		suite.check(player.dash.cooldown_left > 0 and hud.boss_bar.visible and hud.mission_back.get_global_rect().encloses(hud.boss_bar.get_global_rect()), "Guardian touch dash and HP fit viewport " + str(resolution))
		player.dash.time_left = 0
	# Death against the boss: no checkpoint, single normal penalty.
	var bag_before := p.bag.duplicate()
	var gold_before := p.gold
	player.receive_damage(100000)
	main._on_player_died()
	await TRIAL_TESTS._transition(suite, main)
	var lost := 0
	for item: String in GameProgress.ITEMS:
		lost += int(bag_before.get(item,0)) - int(p.bag.get(item,0))
	suite.check(lost == 1 and p.gold == gold_before and not p.ascension.completed_trials["1"] and p.ascension.defeats["1"] == 50, "Guardian death applies one normal penalty and retains permanent requirement")
	await TRIAL_TESTS._enter(suite, main)
	suite.check(main.trial.wave == 1 and not is_instance_valid(main.tower_guardian), "death against Guardian restarts at Horda one")
	reach_guardian(main)
	boss = main.tower_guardian
	var xp_before: int = main.earned_xp
	gold_before = main.earned_gold
	main._on_tower_guardian_defeated(4, boss, main.trial.attempt_id)
	suite.check(main.earned_xp == xp_before and not p.ascension.completed_trials["1"], "living Guardian event cannot grant victory")
	boss.receive_damage(100000)
	main._on_tower_guardian_defeated(4, boss, main.trial.attempt_id)
	suite.check(main.earned_xp == xp_before + 180 and main.earned_gold == gold_before + 40 and p.ascension.forest_seal and p.ascension.completed_trials["1"] and p.ascension.unlocked_floors == [1,2] and p.ascension.current_floor == 1, "first true Guardian death grants exact unique rewards seal and data-only floor two")
	suite.check(main.trial.phase == TowerTrial.Phase.VICTORY and hud.station_panel.visible and main.input_driver.blocked and hud.tower_action_button.text == "Retornar à Mata", "Guardian victory opens modal rewards with safe return")
	var archive := p.export_backup()
	DirAccess.make_dir_recursive_absolute("res://build")
	var web_fixture := FileAccess.open("res://build/guardian-save-fixture.json", FileAccess.WRITE)
	web_fixture.store_string(archive)
	web_fixture.close()
	var restored := GameProgress.new()
	restored.save_path = path
	suite.check(restored.load_save() and restored.ascension.forest_seal and restored.ascension.unlocked_floors == [1,2] and restored.xp == main.earned_xp, "victory rewards seal and unlock persist together in save v6")
	var imported: GameProgress = p.preview_backup(archive)
	suite.check(imported != null and imported.ascension.forest_seal and imported.ascension.completed_trials["1"], "victory archive validates version checksum and full ascension state")
	suite.check(not restored.import_backup(archive, false) and restored.import_backup(archive,true) and restored.import_backup(archive,true) and restored.xp == p.xp and restored.gold == p.gold, "confirmed repeated victory import replaces data without adding rewards")
	var old_v6 := JSON.parse_string(GameProgress.new().to_json()) as Dictionary
	old_v6.ascension.erase("forest_seal")
	suite.check(GameProgress.new().load_text(JSON.stringify(old_v6)), "old v6 without seal remains compatible")
	var forged := JSON.parse_string(p.to_json()) as Dictionary
	forged.ascension.forest_seal = false
	suite.check(not GameProgress.new().load_text(JSON.stringify(forged)), "inconsistent claimed victory without seal is rejected")
	for resolution: Vector2i in [Vector2i(360,640), Vector2i(390,844), Vector2i(640,360), Vector2i(960,540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames(3)
		suite.check(hud.station_panel.get_global_rect().encloses(hud.tower_action_button.get_global_rect()) and hud.tower_action_button.size.y >=44 and not player.use_skill(0), "victory touch return fits and combat remains blocked " + str(resolution))
	TRIAL_TESTS._tap(hud,hud.tower_action_button)
	await TRIAL_TESTS._transition(suite,main)
	await TRIAL_TESTS._enter(suite,main)
	reach_guardian(main)
	boss = main.tower_guardian
	xp_before = main.earned_xp
	gold_before = main.earned_gold
	boss.receive_damage(100000)
	suite.check(main.earned_xp == xp_before and main.earned_gold == gold_before and not main.victory_first, "repeated successful challenge cannot farm boss reward")
	await main._return_from_trial(false)
	await TRIAL_TESTS._enter(suite,main)
	reach_guardian(main)
	main._save_progress()
	var saved := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	suite.check(not saved.has("trial") and not saved.has("boss") and saved.ascension.completed_trials["1"], "save during repeated Guardian attempt preserves completion with no checkpoint")
	main.queue_free()
	await suite.frames()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	TRIAL_TESTS._freeze(main)
	main.enemy.set_physics_process(false)
	suite.check(not main.trial.active() and main.player.position == SafeCamp.RESPAWN and main.progress.ascension.forest_seal and main.progress.ascension.unlocked_floors == [1,2] and not is_instance_valid(main.tower_guardian), "reload during boss returns to Mata preserving completion without checkpoint or travel")
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", old_path)
