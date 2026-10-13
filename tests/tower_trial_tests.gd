extends RefCounted

static func _actors(main) -> Array[EnemyActor]:
	var result: Array[EnemyActor] = []
	for node in main.get_children():
		if node is EnemyActor and node.health.is_alive() and not node.is_queued_for_deletion() and node.get_meta("tower_attempt", -1) == main.trial.attempt_id:
			result.append(node)
	return result

static func _freeze(main) -> void:
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in _actors(main):
		actor.set_physics_process(false)

static func _transition(suite, main) -> void:
	for i in range(90):
		if not main.transitioning:
			return
		await suite.frames(1)
	suite.check(false, "trial transition finished in bounded time")

static func _tap(hud: GameHUD, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 94
	event.pressed = true
	event.position = button.get_global_rect().get_center()
	hud._input(event)
	event.pressed = false
	hud._input(event)

static func _tap_action(button: TouchActionButton) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 95
	touch.pressed = true
	touch.position = button.get_global_rect().get_center()
	button._input(touch)
	touch.pressed = false
	button._input(touch)

static func _enter(suite, main) -> void:
	main.player.position = TowerEntrance.POSITION + Vector2(0, 35)
	main._interact()
	_tap(main.hud, main.hud.tower_action_button)
	await _transition(suite, main)
	_freeze(main)

static func _spawn(main) -> void:
	main._process_trial(TowerTrial.PREPARATION_SECONDS)
	_freeze(main)

static func _kill_wave(main) -> void:
	for actor in _actors(main):
		actor.receive_damage(100000)

static func run_world(suite) -> void:
	var old_path := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_tower_trial_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	await suite.frames()
	var p: GameProgress = main.progress
	var player: PlayerActor = main.player
	var hud: GameHUD = main.hud
	player.position = TowerEntrance.POSITION + Vector2(0, 35)
	main._enter_trial()
	suite.check(not main.transitioning and not main.trial.active(), "direct and interacted entry remain blocked before 50")
	p.ascension.defeats["1"] = 50
	main.earned_xp = 300
	main.earned_gold = 17
	main.defeated_count = 50
	p.xp = 300
	p.attributes["Força"] = 2
	p.attributes["Vitalidade"] = 2
	p.equipment.espada = 1
	p.bag["Couro"] = 3
	p.chest["Couro"] = 5
	main._save_progress()
	player.health.damage(player.health.current - 53)
	var before_hp := player.health.current
	var before_stats := p.combat_stats()
	var before_bag := p.bag.duplicate()
	var before_chest := p.chest.duplicate()
	main._interact()
	_tap(hud, hud.tower_action_button)
	main._station_action("Entrar", "")
	suite.check(main.transitioning and main.input_driver.blocked and hud.transition_active and main.enemy.is_physics_processing() == false, "entry starts one guarded fade and pauses combat immediately")
	await _transition(suite, main)
	_freeze(main)
	suite.check(main.trial.active() and main.trial.wave == 1 and is_instance_valid(main.arena) and main.world.get_parent() == null and player.position == TowerTrial.ENTRY, "entry teleports same player to exclusive arena and detaches Mata physics")
	suite.check(main.arena.get_index() < player.get_index(), "arena floor renders behind approved Explorer")
	suite.check(player.health.current == before_hp and p.combat_stats() == before_stats and p.xp == 300 and p.gold == 17 and p.bag == before_bag and p.chest == before_chest, "entry preserves HP level attributes equipment gold inventory and chest")
	suite.check(hud.minimap.arena_bounds == TowerTrial.BOUNDS and (player.get_node("Camera2D") as Camera2D).limit_left == 1600 and not SafeCamp.in_clearance(player.position), "arena camera and map are separate and no Mata safe zone leaks into combat")
	var previous_spawns: int = main.spawn_count
	main._spawn_enemy()
	suite.check(main.spawn_count == previous_spawns and _actors(main).is_empty(), "Mata spawn loop cannot populate arena during preparation")
	_spawn(main)
	var members := _actors(main)
	suite.check(members.size() == 4 and main.trial.pending.size() == 4, "first playable wave contains four common creatures")
	main._spawn_trial_wave()
	suite.check(_actors(main).size() == 4, "duplicate wave spawn request is ignored")
	var xp_before: int = main.earned_xp
	main._on_enemy_defeated(members[0].kind, members[0])
	members[0].receive_damage(1)
	suite.check(main.trial.pending.size() == 4 and main.earned_xp == xp_before, "damage and premature signal do not advance or reward a trial defeat")
	for actor in members:
		actor.update_activity(Vector2(-20000, -20000))
		suite.check(actor.awake and actor.is_targetable() and actor.position.distance_to(player.position) >= 170, "arena creature remains active without overlapping player spawn")
	# Real automatic hit and directional feedback in the actual arena space.
	members[0].position = player.position + Vector2(65, 0)
	await suite.frames()
	var enemy_hp := members[0].health.current
	player.attack.cooldown_left = 0.0
	player.attack.search_left = 0.0
	player.attack.tick(0.1, player)
	suite.check(members[0].health.current < enemy_hp and members[0].view.damage_left > 0.0, "existing basic attack and damage numbers work inside arena")
	# Real controls in the arena, with creatures beyond skill range during input QA.
	for actor in members:
		actor.position = actor.home_position
	player.attack.cooldown_left = 100.0
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(960, 540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames(3)
		player.position = TowerTrial.ENTRY
		var touch := InputEventScreenTouch.new()
		touch.index = 97
		touch.pressed = true
		touch.position = hud.joystick.get_global_rect().get_center() + Vector2(45, 0)
		hud.joystick._input(touch)
		player.set_physics_process(true)
		await suite.frames(5)
		player.set_physics_process(false)
		touch.pressed = false
		hud.joystick._input(touch)
		suite.check(player.position.x > TowerTrial.ENTRY.x + 5 and main.input_driver.touch_direction.is_zero_approx(), "arena touch joystick moves and releases in combat " + str(resolution))
		player.dash.cooldown_left = 0
		_tap_action(hud.dash_button)
		player._physics_process(0.02)
		suite.check(player.dash.cooldown_left > 0 and not main.input_driver.dash_requested, "arena touch dash responds once " + str(resolution))
		preload("res://tests/etapa2_fixtures.gd").unlock(p)
		player.apply_progression(p)
		player.charge_left = 0
		player.dash.time_left = 0
		for i in range(3):
			preload("res://tests/etapa2_fixtures.gd").reset(player)
			hud.set_rpg_status(p, player)
			_tap_action(hud.actions[i])
			suite.check(player.skill_cooldowns[i] > 0, "arena touch skill %d responds in combat %s" % [i, resolution])
			player.charge_left = 0
		player.fury_left = 0
	# Four walls stop ordinary movement and dash rather than teleporting actors.
	for pair: Array in [[Vector2(1660, 220), Vector2(-100, 0)], [Vector2(2260, 220), Vector2(100, 0)], [Vector2(1960, 60), Vector2(0, -100)], [Vector2(1960, 480), Vector2(0, 100)]]:
		player.position = pair[0]
		var hit := player.move_and_collide(pair[1])
		suite.check(hit != null and TowerTrial.BOUNDS.grow(-32).has_point(player.position), "arena wall physically blocks player " + str(pair[1]))
		members[0].position = pair[0]
		hit = members[0].move_and_collide(pair[1])
		suite.check(hit != null and TowerTrial.BOUNDS.grow(-32).has_point(members[0].position), "arena wall physically contains creature " + str(pair[1]))
	player.position = TowerTrial.ENTRY
	player.health.current = 30
	var heal := ceili(player.health.maximum * 0.15)
	main._on_enemy_projectile(TowerTrial.ORIGIN + Vector2(400, 200), Vector2.DOWN, 6)
	var remaining_projectile: EnemyProjectile
	for node in main.get_children():
		if node is EnemyProjectile:
			remaining_projectile = node
	for i in range(3):
		members[i].receive_damage(100000)
	suite.check(main.trial.phase == TowerTrial.Phase.FIGHTING and player.health.current == 30, "partial wave cannot advance or restore health")
	members[3].receive_damage(100000)
	suite.check(main.trial.phase == TowerTrial.Phase.INTERVAL and player.health.current == 30 + heal and _actors(main).is_empty(), "last first-wave death restores exactly one 15 percent heal with no early next spawns")
	suite.check(is_instance_valid(remaining_projectile) and remaining_projectile.is_queued_for_deletion() and not remaining_projectile.is_physics_processing(), "last wave death clears pending projectiles before interval healing")
	var hp_once := player.health.current
	main._on_enemy_defeated(members[3].kind, members[3])
	main._save_progress()
	main._save_progress()
	suite.check(player.health.current == hp_once and main.trial.cleared_waves == 1, "duplicate death and repeated saves cannot repeat interval heal")
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(960, 540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames(3)
		player.position = TowerTrial.EXIT + Vector2(0, -30)
		main._interact()
		await suite.frames()
		var panel := hud.station_panel.get_global_rect()
		suite.check(hud.tower_action_button.text == "Abandonar Prova" and panel.encloses(hud.tower_action_button.get_global_rect()) and hud.tower_action_button.size.y >= 44 and Rect2(Vector2.ZERO, hud.size).encloses(panel), "mobile/desktop abandonment and close stay inside modal " + str(resolution))
		var preparation: float = main.trial.preparation_left
		main._process_trial(10.0)
		var location := player.position
		main.input_driver.set_touch_direction(Vector2.RIGHT)
		player._physics_process(0.02)
		suite.check(player.position == location and main.trial.preparation_left == preparation and not player.use_skill(0) and _actors(main).is_empty(), "modal blocks movement skills and pending wave countdown " + str(resolution))
		_tap(hud, hud.station_close_button)
		suite.check(not main.input_driver.blocked and not hud.station_panel.visible and player.health.current == hp_once, "touch close resumes controls without repeat healing " + str(resolution))
	player.position = TowerTrial.ENTRY
	main.input_driver.set_touch_direction(Vector2.LEFT)
	player.set_physics_process(true)
	await suite.frames(8)
	player.set_physics_process(false)
	main.input_driver.reset()
	suite.check(player.position.x < TowerTrial.ENTRY.x - 5 and _actors(main).is_empty(), "movement remains available during preparation interval")
	main._toggle_map()
	suite.check(hud.expanded_map.arena_bounds == TowerTrial.BOUNDS and hud.map_title.text.contains("Arena") and main.input_driver.blocked, "expanded map uses arena dimensions and modal lock")
	main._toggle_map()
	_spawn(main)
	suite.check(main.trial.wave == 2 and _actors(main).size() == 6, "second wave contains six common creatures")
	_kill_wave(main)
	suite.check(player.health.current == hp_once + heal and main.trial.phase == TowerTrial.Phase.INTERVAL and main.trial.cleared_waves == 2, "second-wave completion grants only the second interval heal")
	_spawn(main)
	members = _actors(main)
	var elite_count := 0
	for actor in members:
		if actor.kind == 3:
			elite_count += 1
			suite.check(actor.health.maximum == 120 and actor.stats.contact_damage == 12 and actor.view.elite, "third-wave elite reuses approved stats and appearance")
	suite.check(main.trial.wave == 3 and members.size() == 6 and elite_count == 1, "third wave contains five common creatures and exactly one elite")
	var third_hp := player.health.current
	_kill_wave(main)
	suite.check(main.trial.phase == TowerTrial.Phase.AWAITING_GUARDIAN and player.health.current == third_hp and not hud.station_panel.visible and not main.input_driver.blocked, "third-wave completion starts Guardian presentation without extra heal or early spawn")
	suite.check(p.ascension.completed_trials["1"] == false and p.ascension.unlocked_floors == [1] and p.ascension.defeats["1"] == 50 and not is_instance_valid(main.guardian), "three hordes cannot complete ascension unlock floor 2 or spawn Guardian")
	main.hud.show_station(TowerEntrance.NAME, p)
	var bag_after := p.bag.duplicate()
	var gold_after := p.gold
	_tap(hud, hud.tower_action_button)
	main._station_action("Retornar", "")
	await _transition(suite, main)
	suite.check(not main.trial.active() and player.position == SafeCamp.RESPAWN and main.world.get_parent() == main and player.health.current == third_hp and p.bag == bag_after and p.gold == gold_after, "safe return restores Mata without changing HP or applying death penalty")
	suite.check((player.get_node("Camera2D") as Camera2D).limit_right == 1200 and hud.minimap.arena_bounds == Rect2() and TowerEntrance.POSITION == Vector2(1130, 455), "return restores exact original map camera and unchanged eastern Tower")
	await _enter(suite, main)
	suite.check(main.trial.wave == 1 and main.trial.cleared_waves == 0, "reentry after three waves always starts first wave")
	_spawn(main)
	members = _actors(main)
	members[0].queue_free()
	await suite.frames()
	_kill_wave(main)
	suite.check(main.trial.phase == TowerTrial.Phase.FIGHTING and main.trial.pending.size() == 1, "removal without real death never counts or advances a wave")
	var bag_before_abandon := p.bag.duplicate()
	var abandon_hp := player.health.current
	await main._return_from_trial(false)
	suite.check(not main.trial.active() and p.bag == bag_before_abandon and player.health.current == abandon_hp, "abandoning even an incomplete wave has no death penalty or healing")
	await _enter(suite, main)
	_spawn(main)
	_kill_wave(main)
	_spawn(main)
	suite.check(main.trial.wave == 2, "death scenario reaches second wave without a checkpoint")
	var death_bag := p.bag.duplicate()
	var death_chest := p.chest.duplicate()
	var death_gold := p.gold
	var death_xp := p.xp
	player.receive_damage(100000)
	main._on_player_died()
	await _transition(suite, main)
	var lost_items := 0
	for item: String in GameProgress.ITEMS:
		lost_items += int(death_bag.get(item, 0)) - int(p.bag.get(item, 0))
	suite.check(lost_items == 1 and p.chest == death_chest and p.gold == death_gold and p.xp == death_xp, "arena death applies exactly normal single material loss and protects chest XP gold")
	suite.check(player.health.is_alive() and player.position == SafeCamp.RESPAWN and not main.trial.active() and not hud.restart.visible and p.ascension.defeats["1"] == 50, "arena death returns alive to safe camp and preserves permanent entrance")
	await _enter(suite, main)
	suite.check(main.trial.wave == 1 and main.trial.cleared_waves == 0, "death leaves no checkpoint when entering again")
	_spawn(main)
	_kill_wave(main)
	main._save_progress()
	var saved := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	var saved_xp := p.xp
	var saved_gold := p.gold
	var saved_bag := p.bag.duplicate()
	suite.check(not saved.has("trial") and not saved.ascension.completed_trials["1"] and saved.ascension.unlocked_floors == [1.0], "saving during proof serializes permanent state and never a wave checkpoint")
	main.queue_free()
	await suite.frames()
	var reload := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(reload)
	reload.set_process(false)
	reload.player.set_physics_process(false)
	reload.enemy.set_physics_process(false)
	await suite.frames()
	suite.check(not reload.trial.active() and not is_instance_valid(reload.arena) and reload.player.position == SafeCamp.RESPAWN and reload.progress.xp == saved_xp and reload.progress.gold == saved_gold and reload.progress.bag == saved_bag and reload.progress.ascension.defeats["1"] == 50, "reload during proof closes attempt and restores permanent progression at camp")
	reload.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", old_path)
