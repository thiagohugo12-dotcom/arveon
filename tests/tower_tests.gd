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
		legacy.rpg.skills = preload("res://tests/etapa2_fixtures.gd").legacy_skills(progress)
		legacy.rpg.attributes = preload("res://tests/progression_tests.gd").legacy_attributes(progress.attributes)
		legacy.erase("ascension")
		if version == 4:
			legacy.attributes = preload("res://tests/progression_tests.gd").legacy_attributes(progress.attributes)
		_write(progress.save_path, legacy)
		suite.check(loaded.load_save() and loaded.ascension.defeats["1"] == 23 and loaded.gold == 17 and loaded.kills == 23, "v%d migration credits previous real Mata kills without changing rewards" % version)
	var old_many := saved.duplicate(true)
	old_many.version = 5
	old_many.rpg.skills = preload("res://tests/etapa2_fixtures.gd").legacy_skills(progress)
	old_many.rpg.attributes = preload("res://tests/progression_tests.gd").legacy_attributes(progress.attributes)
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

static func run_world(suite) -> void:
	var old_path := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://qa_tower_world_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	main.enemy.target = null
	await suite.frames()
	var p: GameProgress = main.progress
	var hud: GameHUD = main.hud
	var player: PlayerActor = main.player
	var enemy: EnemyActor = main.enemy
	suite.check(p.ascension.defeats["1"] == 0, "new world begins with tower count zero")
	enemy.receive_damage(12)
	main._on_enemy_defeated(enemy.kind, enemy)
	suite.check(p.ascension.defeats["1"] == 0 and main.defeated_count == 0, "damage and premature defeat event cannot grant tower progress or rewards")
	enemy.update_activity(Vector2(-2000, -2000))
	suite.check(not enemy.awake and p.ascension.defeats["1"] == 0, "sleep or fleeing does not count as a defeat")
	enemy.update_activity(enemy.global_position)
	enemy.set_physics_process(false)
	enemy.receive_damage(1000)
	suite.check(p.ascension.defeats["1"] == 1 and main.defeated_count == 1 and main.earned_xp == 12, "real enemy death counts exactly once with original XP reward")
	var earned_gold: int = main.earned_gold
	var earned_xp: int = main.earned_xp
	enemy.receive_damage(1000)
	enemy.defeated.emit(enemy.kind)
	main._on_enemy_defeated(enemy.kind, enemy)
	suite.check(p.ascension.defeats["1"] == 1 and main.defeated_count == 1 and main.earned_gold == earned_gold and main.earned_xp == earned_xp, "repeated death, signal and callback cannot duplicate count or rewards")
	var restored := GameProgress.new()
	restored.save_path = path
	suite.check(restored.load_save() and restored.ascension.defeats["1"] == 1, "real defeat persists through existing save callback")
	# Only actors registered in this world can supply a Mata defeat.
	var outsider := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	suite.root.add_child(outsider)
	outsider.position = Vector2(1000, 500)
	outsider.set_physics_process(false)
	outsider.health.current = 0
	main._on_enemy_defeated(outsider.kind, outsider)
	suite.check(p.ascension.defeats["1"] == 1 and main.defeated_count == 1, "foreign dead actor cannot report a defeat to Mata")
	outsider.queue_free()
	main._spawn_enemy()
	var other: EnemyActor = suite.get_nodes_in_group("damageable_enemies")[0]
	other.set_physics_process(false)
	other.set_meta("floor_id", 2)
	other.receive_damage(1000)
	suite.check(p.ascension.defeats["1"] == 1, "a defeat tagged to another floor does not count for Mata")
	other.queue_free()
	await suite.frames()
	p.ascension.defeats["1"] = 49
	main._spawn_enemy()
	var fiftieth: EnemyActor = suite.get_nodes_in_group("damageable_enemies")[0]
	fiftieth.set_physics_process(false)
	fiftieth.receive_damage(1000)
	suite.check(p.ascension.defeats["1"] == 50 and p.ascension.entrance_unlocked(), "fiftieth real creature death unlocks tower through gameplay")
	fiftieth.queue_free()
	await suite.frames()
	earned_xp = main.earned_xp
	main._spawn_enemy()
	var later: EnemyActor = suite.get_nodes_in_group("damageable_enemies")[0]
	later.set_physics_process(false)
	later.receive_damage(1000)
	suite.check(p.ascension.defeats["1"] == 50 and main.earned_xp == earned_xp + 12 and p.ascension.unlocked_floors == [1], "later real kills retain original rewards without raising tower count or unlocking floor 2")
	later.queue_free()
	await suite.frames()
	# Follow the camp-to-south route in small walking-sized collision steps.
	player.position = SafeCamp.RESPAWN
	var route_clear := true
	var approach := TowerEntrance.POSITION + Vector2(0,28)
	for waypoint: Vector2 in [Vector2(570,480),Vector2(570,690),Vector2(560,860),Vector2(620,960),
		Vector2(720,1035),Vector2(760,1185),Vector2(635,1260),Vector2(680,1308),approach]:
		for step in range(250):
			var offset := waypoint - player.position
			if offset.length() < 0.5:
				break
			if player.move_and_collide(offset.limit_length(3.0)) != null:
				route_clear = false
				break
	suite.check(route_clear and player.position.distance_to(approach) < 0.5, "ordinary walking route reaches southern tower from camp without dash or teleport")
	suite.check(TowerEntrance.POSITION.distance_to(SafeCamp.RESPAWN) > 3.0 * Vector2(600, 280).distance_to(SafeCamp.RESPAWN), "tower is over three times farther from camp than previous location")
	suite.check(not SafeCamp.AREA.grow(SafeCamp.CLEARANCE).has_point(TowerEntrance.POSITION), "tower stands outside camp and safe clearance")
	var tower_footprint: Rect2 = TowerEntrance.ANDAR1_SIDES[0].merge(TowerEntrance.ANDAR1_SIDES[1])
	suite.check(Rect2(16, 16, 1668, 1318).encloses(tower_footprint.grow(12)), "tower footprint remains inside expanded map walls")
	var walls := main.get_node("Andar1/Walls")
	suite.check(walls.get_node("Top").position == Vector2(850, 0) and walls.get_node("Bottom").position == Vector2(850, 1350) and walls.get_node("Left").position == Vector2(0, 675) and walls.get_node("Right").position == Vector2(1700, 675), "Andar 1 boundaries surround the expanded world")
	var camera := player.get_node("Camera2D") as Camera2D
	suite.check(camera.limit_left == 0 and camera.limit_top == 0 and camera.limit_right == 1700 and camera.limit_bottom == 1350 and MiniMap.WORLD_SIZE == Vector2(1200, 900), "camera and minimap use the expanded Andar 1 size while the legacy default remains available")
	suite.check(FloorConfig.world_size(2) == Floor2Layout.WORLD_SIZE and FloorConfig.world_size(3) == FloorConfig.DEFAULT_WORLD_SIZE, "Vale bounds are configured without changing later floors")
	for spawn: Vector2 in main.ENEMY_POSITIONS:
		suite.check(spawn.distance_to(TowerEntrance.POSITION) > 150.0, "existing enemy spawn remains away from tower entrance " + str(spawn))
	# Actual movement uses the unchanged joystick InputDriver and PlayerActor.
	main.input_driver.set_touch_direction(Vector2.LEFT)
	player.set_physics_process(true)
	await suite.frames(8)
	player.set_physics_process(false)
	main.input_driver.set_touch_direction(Vector2.ZERO)
	suite.check(player.position.x < TowerEntrance.POSITION.x - 5 and TowerEntrance.is_near(player.position), "touch movement works on southern tower apron")
	main.activity_remaining = 0.0
	main._process(0.0)
	suite.check(hud.minimap.player_position.distance_to(player.position) < 4.0 and hud.minimap._map_point(player.position).y > hud.minimap.size.y * 0.80, "minimap follows player at the southern Tower on the expanded Andar 1 map")
	player.position = TowerEntrance.POSITION + Vector2(0, 35)
	var hit := player.move_and_collide(Vector2(0, -75))
	suite.check(hit != null and player.position.y >= TowerEntrance.POSITION.y - 8, "tower wall is solid while front interaction remains accessible")
	for spot: Dictionary in Exploration.RESOURCE_SPOTS:
		suite.check(spot.position.distance_to(TowerEntrance.POSITION) > TowerEntrance.INTERACT_RANGE + Exploration.PICKUP_RANGE, "tower does not steal resource interaction " + spot.id)
	for floor_count in [0, 23, 49]:
		p.ascension.defeats["1"] = floor_count
		player.position = TowerEntrance.POSITION + Vector2(-30, 15)
		main._interact()
		suite.check(hud.station_panel.visible and main.input_driver.blocked and hud.tower_action_button.disabled and hud.loot_label.text.contains("Progresso: %d/50." % floor_count), "trial blocked while travel panel shows truthful progress at %d defeats" % floor_count)
		hud.close_station()
	p.ascension.defeats["1"] = 50
	var checks_before: int = suite.checks
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(960, 540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames(3)
		player.position = TowerEntrance.POSITION + Vector2(-30, 15)
		main.input_driver.set_touch_direction(Vector2.RIGHT)
		main.input_driver.request_dash()
		hud.set_nearby_station(main._interaction_target().label)
		var touch := InputEventScreenTouch.new()
		touch.index = 81
		touch.pressed = true
		touch.position = hud.interact_button.get_global_rect().get_center()
		hud.interact_button._input(touch)
		touch.pressed = false
		hud.interact_button._input(touch)
		await suite.frames()
		suite.check(hud.station_panel.visible and hud.station_title.text == "Torre · Andar 1" and main.input_driver.blocked, "touch opens unlocked tower menu %s" % resolution)
		suite.check(main.input_driver.touch_direction.is_zero_approx() and not main.input_driver.dash_requested and not hud.joystick.is_processing_input(), "tower resets held joystick/dash %s" % resolution)
		var panel_rect := hud.station_panel.get_global_rect()
		suite.check(Rect2(Vector2.ZERO, hud.size).encloses(panel_rect) and panel_rect.encloses(hud.station_close_button.get_global_rect()) and hud.station_close_button.size.y >= 44, "tower panel and 44px close fit viewport %s" % resolution)
		var texts := ""
		for node in hud.station_content.get_children():
			if node is Label:
				texts += node.text + "\n"
		suite.check(texts.contains("três hordas") and texts.contains("Guardião da Mata") and texts.contains("Se morrer, a prova recomeça da primeira horda.") and texts.contains("Sem checkpoints") and hud.tower_action_button.text == "Entrar na Prova" and hud.tower_action_button.is_visible_in_tree(), "tower offers real entry and describes remaining Guardian truthfully %s" % resolution)
		var before := player.position
		var cd := player.attack.cooldown_left
		player._physics_process(0.02)
		suite.check(player.position == before and player.attack.cooldown_left == cd and not player.use_skill(0) and not player.use_skill(1) and not player.use_skill(2), "tower blocks movement auto attack and abilities %s" % resolution)
		main._toggle_inventory()
		main._toggle_character()
		main._toggle_map()
		suite.check(not hud.inventory_open and not hud.rpg_panel.visible and not hud.map_panel.visible, "tower cannot overlap other menus %s" % resolution)
		touch.pressed = true
		touch.position = hud.station_close_button.get_global_rect().get_center()
		hud._input(touch)
		touch.pressed = false
		hud._input(touch)
		suite.check(not hud.station_panel.visible and not main.input_driver.blocked and hud.joystick.is_processing_input(), "touch closes tower and resumes controls %s" % resolution)
	suite.check(suite.checks > checks_before and p.ascension.unlocked_floors == [1] and not p.ascension.completed_trials["1"] and not is_instance_valid(main.guardian), "opening preview never starts a trial or unlocks floor 2")
	# Player death saves this field without a reset; reload the resulting file.
	player.position = Vector2(900, 500)
	player.receive_damage(100000)
	suite.check(not player.health.is_alive() and p.ascension.defeats["1"] == 50 and restored.load_save() and restored.ascension.defeats["1"] == 50, "actual player death and reload preserve tower entrance unlock")
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH", old_path)
