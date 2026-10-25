extends RefCounted

# Paridade dos Andares 1 e 2 depois do Marco 2. Os números abaixo são os valores
# ORIGINAIS do jogo, escritos aqui de propósito: o catálogo é a fonte agora, então
# comparar o catálogo com ele mesmo não provaria nada.

const GOLDEN_SCALE := {1: [1.0, 1.0], 2: [1.5, 1.1], 3: [1.4, 1.2], 4: [1.6, 1.3], 5: [1.8, 1.4]}
const GOLDEN_XP := [12, 10, 16, 35, 80, 10, 16, 20]
# kind: [hp, speed, contact_damage, name]
const GOLDEN_MONSTERS := {
	0: [48, 70.0, 8, "Javali"], 1: [36, 92.0, 7, "Aranha"], 2: [64, 48.0, 10, "Mandacaru"], 3: [120, 60.0, 12, "Javali Elite"],
	5: [52, 95.0, 8, "Goblin Garimpeiro"], 6: [108, 54.0, 11, "Tatu Rochoso"], 7: [72, 105.0, 13, "Escorpião da Chapada"]}
const GOLDEN_FLOOR1_SPAWNS := [
	Vector2(850, 400), Vector2(930, 440), Vector2(610, 750), Vector2(180, 460), Vector2(630, 135), Vector2(955, 665),
	Vector2(1350,250), Vector2(1510,260), Vector2(1600,365), Vector2(1335,400), Vector2(1360,560), Vector2(1510,590),
	Vector2(1630,650), Vector2(1530,770), Vector2(1370,760), Vector2(630,1015), Vector2(800,1110), Vector2(980,1045),
	Vector2(1090,1190), Vector2(660,1250), Vector2(1000,1260), Vector2(1640,1310)]
const GOLDEN_FLOOR2_SPAWNS := [Vector2(750, 700), Vector2(945, 930), Vector2(1040, 690), Vector2(1260, 790), Vector2(1390, 1080), Vector2(490, 350), Vector2(1200, 410), Vector2(900, 1120)]
const GOLDEN_FLOOR2_KINDS := [6, 6, 7, 7, 7, 5, 7, 6]

static func run(suite) -> void:
	# Escala por andar, incluindo o fallback de andares desconhecidos.
	for id in GOLDEN_SCALE:
		suite.check(is_equal_approx(FloorConfig.difficulty(id), GOLDEN_SCALE[id][0]) and is_equal_approx(FloorCatalog.difficulty(id), GOLDEN_SCALE[id][0]), "difficulty is unchanged for floor %d" % id)
		for amount in [1, 2, 5, 10, 35, 80, 180]:
			var expected := roundi(amount * float(GOLDEN_SCALE[id][1]))
			suite.check(FloorConfig.reward(amount, id) == expected and FloorCatalog.reward(amount, id) == expected, "reward is unchanged for floor %d amount %d" % [id, amount])
	suite.check(FloorConfig.difficulty(99) == 1.0 and FloorConfig.reward(10, 99) == 0 and not FloorConfig.valid(0) and not FloorConfig.valid(6) and FloorConfig.valid(5), "unknown floors keep the legacy fallback")
	# Nomes, cenas e tamanhos.
	suite.check(FloorConfig.tower_guardian_name(1) == "Guardião da Mata" and FloorConfig.tower_guardian_name(2) == "Guardião de Arenito" and FloorConfig.tower_guardian_name(3) == "Guardião da Mata", "tower guardian names are unchanged")
	suite.check(FloorConfig.tower_return_name(1) == "Mata" and FloorConfig.tower_return_name(2) == "Vale" and FloorConfig.tower_return_name(5) == "Mata", "tower return names are unchanged")
	suite.check(FloorConfig.world_scene(1) == "res://scenes/world/andar_1.tscn" and FloorConfig.world_scene(2) == "res://scenes/world/andar_2.tscn" and FloorConfig.world_scene(4) == "res://scenes/world/andar_1.tscn", "world scenes are unchanged")
	suite.check(FloorConfig.world_size(1) == Vector2(1700, 1350) and FloorConfig.world_size(2) == Vector2(1700, 1350) and FloorConfig.world_size(3) == Vector2(1200, 900), "world sizes are unchanged")
	suite.check(FloorConfig.ANDAR1_WORLD_SIZE == Vector2(1700, 1350) and FloorConfig.WORLD_SCENE == "res://scenes/world/andar_1.tscn" and FloorConfig.ANDAR2_WORLD_SCENE == "res://scenes/world/andar_2.tscn", "legacy FloorConfig constants still resolve")
	suite.check(FloorCatalog.heading(1) == "Mata · Andar 1" and FloorCatalog.heading(2) == "Vale das Pedras · Andar 2" and FloorCatalog.heading(3) == "Mata · Andar 3", "HUD headings are unchanged")
	suite.check(FloorCatalog.map_title(1) == "Mapa · Mata · Andar 1" and FloorCatalog.map_title(2) == "Mapa · Vale · Andar 2" and FloorCatalog.map_title(4) == "Mapa · Mata · Andar 4", "map titles are unchanged")
	suite.check(FloorCatalog.seal_note(1) == " · Selo da Mata" and FloorCatalog.seal_note(2) == "" and FloorCatalog.seal_note(3) == "", "seal note appears only on floor 1")
	# Recursos por andar (antes eram comparações com 1 e 2).
	for id in range(1, 6):
		suite.check(FloorCatalog.feature(id, "mining") == (id == 2) and FloorCatalog.feature(id, "vale_iron") == (id == 2), "mining and Vale iron belong only to floor 2 (floor %d)" % id)
		suite.check(FloorCatalog.feature(id, "village_camp") == (id == 1) and FloorCatalog.feature(id, "expanded_world") == (id == 1), "village camp and expanded world belong only to floor 1 (floor %d)" % id)
		suite.check(FloorCatalog.feature(id, "modern_art") == (id <= 2), "modern art covers floors 1 and 2 only (floor %d)" % id)
	# Spawns e altares.
	suite.check(FloorCatalog.enemy_spawns(1) == GOLDEN_FLOOR1_SPAWNS and FloorCatalog.enemy_spawn_kinds(1).is_empty(), "Andar 1 spawn positions keep their order and cycle rule")
	suite.check(FloorCatalog.enemy_spawns(2) == GOLDEN_FLOOR2_SPAWNS and FloorCatalog.enemy_spawn_kinds(2) == GOLDEN_FLOOR2_KINDS, "Andar 2 spawn positions and kinds are unchanged")
	suite.check(Floor2Layout.ENEMY_SPAWNS == GOLDEN_FLOOR2_SPAWNS and Floor2Layout.ENEMY_SPAWN_KINDS == GOLDEN_FLOOR2_KINDS, "Floor2Layout constants still resolve to the same lists")
	suite.check(FloorCatalog.first_enemy_kind(1) == 0 and FloorCatalog.first_enemy_position(1) == Vector2(850, 400) and FloorCatalog.first_enemy_kind(2) == 6 and FloorCatalog.first_enemy_position(2) == Vector2(750, 700) and FloorCatalog.first_enemy_kind(3) == 0 and FloorCatalog.first_enemy_position(3) == Vector2(850, 400), "first enemy of each floor is unchanged")
	suite.check(FloorCatalog.guardian_altar(1) == Vector2(1060, 155) and FloorCatalog.guardian_altar(2) == Vector2(1380, 1070) and FloorCatalog.guardian_altar(3) == Vector2(1060, 155) and Floor2Layout.GUARDIAN_ALTAR == Vector2(1380, 1070), "guardian altars are unchanged")
	# Torre: ondas e entradas.
	suite.check(TowerTrial.WAVES == [[0, 1, 2, 0], [0, 1, 2, 0, 1, 2], [0, 1, 2, 0, 1, 3]] and TowerTrial.VALE_WAVES == [[5, 6, 7, 5], [5, 6, 7, 5, 6, 7], [5, 6, 7, 5, 6, 7]], "tower waves are unchanged")
	suite.check(TowerEntrance.position_for_floor(1) == Vector2(830, 1290) and TowerEntrance.position_for_floor(2) == Vector2(216, 782) and TowerEntrance.position_for_floor(3) == Vector2(1130, 455), "tower entrance positions are unchanged")
	suite.check(SafeCamp.area_for_floor(1) == Rect2(470, 355, 180, 200) and SafeCamp.area_for_floor(2) == Rect2(190, 715, 350, 300) and SafeCamp.area_for_floor(3) == Rect2(470, 355, 180, 200), "safe camp areas are unchanged")
	suite.check(SafeCamp.respawn_for_floor(1) == Vector2(540, 450) and SafeCamp.respawn_for_floor(2) == Vector2(340, 885) and SafeCamp.respawn_for_floor(5) == Vector2(540, 450), "safe camp respawns are unchanged")
	suite.check(SafeCamp.stations_for_floor(2) == {"Baú": Vector2(282, 940), "Ferreiro": Vector2(285, 855), "Vendedor": Vector2(450, 928)} and SafeCamp.stations_for_floor(1, true) == SafeCamp.DISPLAY_STATIONS and SafeCamp.stations_for_floor(3, false) == SafeCamp.STATIONS, "station anchors are unchanged")
	# Drops continuam na tabela existente; XP, ouro e nomes.
	for kind in range(0, 8):
		suite.check(FloorCatalog.drops(kind) == EquipmentEconomy.DROP_TABLE.get(kind, []), "drops for kind %d are the existing table" % kind)
		suite.check(FloorCatalog.xp_for_kind(kind) == GOLDEN_XP[kind], "XP for kind %d is unchanged" % kind)
	suite.check(FloorCatalog.GOLD_RANGE == Vector2i(2, 5), "gold range is unchanged")
	for kind in GOLDEN_MONSTERS:
		var expected: Array = GOLDEN_MONSTERS[kind]
		var data := FloorCatalog.monster(FloorCatalog.monster_id_for_kind(kind))
		suite.check(int(data.hp) == expected[0] and is_equal_approx(float(data.speed), expected[1]) and int(data.contact) == expected[2] and data.name == expected[3], "base stats are unchanged for kind %d" % kind)
	suite.check(int(FloorCatalog.monster("javali").hp) == (load("res://data/actors/enemy.tres") as ActorData).max_hp and is_equal_approx(float(FloorCatalog.monster("javali").speed), (load("res://data/actors/enemy.tres") as ActorData).move_speed), "base monster matches the shared enemy resource")
	# Chefes (valores base, antes da escala do andar).
	var boss1 := FloorCatalog.floor_def(1)
	var boss2 := FloorCatalog.floor_def(2)
	suite.check(boss1.field_guardian.hp == 320 and boss1.field_guardian.speed == 45.0 and boss2.field_guardian.hp == 540 and boss2.field_guardian.speed == 38.0 and boss2.field_guardian.radius == 34.0, "field guardian base values are unchanged")
	suite.check(boss1.tower_guardian.hp == 360 and boss1.tower_guardian.speed == 65.0 and boss1.tower_guardian.radius == 26.0 and boss2.tower_guardian.hp == 520 and boss2.tower_guardian.speed == 52.0 and boss2.tower_guardian.radius == 34.0 and TowerGuardian.MAX_HP == 360, "tower guardian base values are unchanged")
	suite.check(boss1.guardian_spawn_candidates == [Vector2(360, 245), Vector2(200, 300), Vector2(520, 300), Vector2(360, 350)] and boss2.guardian_spawn_candidates == [Vector2(360, 190), Vector2(200, 260), Vector2(520, 260), Vector2(360, 350)], "tower guardian spawn candidates are unchanged")
	suite.check(boss1.field_guardian.challenge_label == "Desafiar Guardião (opcional)" and boss2.field_guardian.challenge_label == "Desafiar Colosso", "guardian challenge labels are unchanged")
	suite.check(FloorCatalog.def_or_default(4).field_guardian.hp == 320 and FloorCatalog.def_or_default(4).tower_guardian.hp == 360, "floors without a definition still use the Andar 1 guardians")
	# O código não deve mais conter os literais antigos de andar.
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for literal in ["[12, 10, 16, 35, 80, 10, 16, 20]", "540 if vale else 320", "520 if trial.floor_id == 2", "Floor2Layout.ENEMY_SPAWN_KINDS[0]"]:
		suite.check(not (literal in source), "Main no longer carries the literal: " + literal)

static func run_world(suite) -> void:
	var previous_path := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://floor_catalog_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	for floor_id in [1, 2]:
		main.progress.ascension.current_floor = floor_id
		var multiplier: float = GOLDEN_SCALE[floor_id][0]
		# A fábrica de monstros devolve os números originais já escalados pelo andar.
		for kind in GOLDEN_MONSTERS:
			var expected: Array = GOLDEN_MONSTERS[kind]
			var actor: EnemyActor = main._make_enemy(kind)
			var label := "kind %d on floor %d" % [kind, floor_id]
			suite.check(actor.stats.max_hp == roundi(expected[0] * multiplier), "factory HP matches the original for " + label)
			suite.check(actor.stats.contact_damage == roundi(expected[2] * multiplier), "factory contact damage matches the original for " + label)
			suite.check(is_equal_approx(actor.stats.move_speed, expected[1]), "factory speed matches the original for " + label)
			suite.check(is_equal_approx(actor.damage_scale, multiplier) and actor.projectile_damage_override == roundi(maxi(4, expected[2] - 2) * multiplier), "factory scaling matches the original for " + label)
			suite.check(actor.display_name() == expected[3], "display name matches the original for " + label)
			actor.free()
		# Chefe de campo e chefe da Torre, com a escala do andar aplicada depois.
		var field_hp: int = roundi((320 if floor_id == 1 else 540) * multiplier)
		main.guardian = null
		main._start_guardian()
		suite.check(is_instance_valid(main.guardian) and main.guardian.stats.max_hp == field_hp and is_equal_approx(main.guardian.stats.move_speed, 45.0 if floor_id == 1 else 38.0), "field guardian spawns with the original stats on floor %d" % floor_id)
		suite.check(is_instance_valid(main.guardian) and main.guardian.global_position == (Vector2(1060, 155) if floor_id == 1 else Vector2(1380, 1070)) + Vector2(0, 80), "field guardian spawns at the original altar on floor %d" % floor_id)
		if is_instance_valid(main.guardian): main.guardian.free()
		main.guardian = null
		main.trial.floor_id = floor_id
		main.trial.phase = TowerTrial.Phase.GUARDIAN
		main.tower_guardian = null
		main._spawn_tower_guardian()
		var tower_hp: int = roundi((360 if floor_id == 1 else 520) * multiplier)
		suite.check(is_instance_valid(main.tower_guardian) and main.tower_guardian.stats.max_hp == tower_hp and is_equal_approx(main.tower_guardian.stats.move_speed, 65.0 if floor_id == 1 else 52.0), "tower guardian spawns with the original stats on floor %d" % floor_id)
		if is_instance_valid(main.tower_guardian): main.tower_guardian.free()
		main.tower_guardian = null
		main.trial.end()
	# Spawn comum no Andar 2: o tipo vem da tabela original, pelo ponto escolhido.
	main.progress.ascension.current_floor = 2
	SafeCamp.active_floor = 2
	main.player.global_position = Vector2(900, 800)
	for node in main.get_children():
		if node is EnemyActor: node.free()
	main._spawn_enemy()
	var spawned: EnemyActor = null
	for node in main.get_children():
		if node is EnemyActor: spawned = node
	var index := GOLDEN_FLOOR2_SPAWNS.find(spawned.position) if spawned != null else -1
	suite.check(index >= 0 and spawned.kind == GOLDEN_FLOOR2_KINDS[index], "Andar 2 spawn picks the original kind for its point")
	SafeCamp.active_floor = 1
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH", previous_path)
