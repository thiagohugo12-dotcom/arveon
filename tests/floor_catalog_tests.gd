extends RefCounted

# Paridade exata entre FloorCatalog (Marco 1) e os valores atuais dos Andares 1 e 2.
# Enquanto o jogo ainda lê os valores antigos, qualquer divergência falha aqui.

static func run(suite) -> void:
	# Escala por andar.
	for id in range(1, 6):
		suite.check(is_equal_approx(FloorCatalog.difficulty(id), FloorConfig.difficulty(id)), "catalog difficulty matches FloorConfig floor %d" % id)
		for amount in [1, 2, 5, 10, 35, 80, 180]:
			suite.check(FloorCatalog.reward(amount, id) == FloorConfig.reward(amount, id), "catalog reward matches FloorConfig floor %d amount %d" % [id, amount])
	suite.check(FloorCatalog.difficulty(99) == FloorConfig.difficulty(99) and FloorCatalog.reward(10, 99) == FloorConfig.reward(10, 99), "unknown floors keep the legacy fallback")
	# Drops por tipo continuam na tabela existente.
	for kind in range(0, 8):
		suite.check(FloorCatalog.drops(kind) == EquipmentEconomy.DROP_TABLE.get(kind, []), "catalog drops for kind %d are the existing table" % kind)
	# Nomes, andares e referências de cenário.
	suite.check(FloorCatalog.has_floor(1) and FloorCatalog.has_floor(2) and not FloorCatalog.has_floor(3), "catalog describes exactly Andares 1 and 2 in Marco 1")
	for id in [1, 2]:
		var def := FloorCatalog.floor_def(id)
		suite.check(def.tower_guardian_name == FloorConfig.tower_guardian_name(id) and def.return_name == FloorConfig.tower_return_name(id), "catalog names match FloorConfig floor %d" % id)
		suite.check(def.world_scene == FloorConfig.world_scene(id) and def.world_size == FloorConfig.world_size(id), "catalog scene and size match FloorConfig floor %d" % id)
		suite.check(SafeCamp.area_for_floor(id) != Rect2() and SafeCamp.respawn_for_floor(id) != Vector2.ZERO, "safe camp data exists for floor %d" % id)
		suite.check(TowerEntrance.position_for_floor(id) != TowerEntrance.LEGACY_POSITION, "tower entrance exists for floor %d" % id)
	# Andar 1: posições e ondas.
	var one := FloorCatalog.floor_def(1)
	var legacy_main = load("res://scripts/main.gd")
	suite.check(one.enemy_spawns == legacy_main.ENEMY_POSITIONS + legacy_main.ANDAR1_ENEMY_POSITIONS, "Andar 1 spawn positions match Main in the same order")
	suite.check(one.guardian_altar == legacy_main.GUARDIAN_ALTAR, "Andar 1 guardian altar matches Main")
	suite.check(one.waves == TowerTrial.WAVES, "Andar 1 tower waves match TowerTrial")
	suite.check(int(one.tower_guardian.hp) == TowerGuardian.MAX_HP, "Andar 1 tower guardian HP matches TowerGuardian.MAX_HP")
	# Andar 2: posições, tipos, altar e ondas.
	var two := FloorCatalog.floor_def(2)
	suite.check(two.enemy_spawns == Floor2Layout.ENEMY_SPAWNS and two.enemy_spawn_kinds == Floor2Layout.ENEMY_SPAWN_KINDS, "Andar 2 spawn positions and kinds match Floor2Layout")
	suite.check(two.guardian_altar == Floor2Layout.GUARDIAN_ALTAR, "Andar 2 guardian altar matches Floor2Layout")
	suite.check(two.waves == TowerTrial.VALE_WAVES, "Andar 2 tower waves match TowerTrial")
	# Valores que ainda vivem como literais em Main: o teste lê o código para detectar divergência.
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	suite.check("[12, 10, 16, 35, 80, 10, 16, 20][kind]" in source, "legacy XP table literal is unchanged")
	for kind in range(0, 8):
		suite.check(FloorCatalog.xp_for_kind(kind) == [12, 10, 16, 35, 80, 10, 16, 20][kind], "catalog XP for kind %d matches the legacy table" % kind)
	suite.check("loot_rng.randi_range(2, 5)" in source and FloorCatalog.GOLD_RANGE == Vector2i(2, 5), "legacy gold range literal is unchanged")
	suite.check("guardian.stats.max_hp = 540 if vale else 320" in source and "guardian.stats.move_speed = 38.0 if vale else 45.0" in source, "legacy field guardian literals are unchanged")
	suite.check(int(one.field_guardian.hp) == 320 and int(two.field_guardian.hp) == 540 and is_equal_approx(float(one.field_guardian.speed), 45.0) and is_equal_approx(float(two.field_guardian.speed), 38.0), "catalog field guardian values match the literals")
	suite.check("tower_guardian.stats.max_hp = 520 if trial.floor_id == 2 else TowerGuardian.MAX_HP" in source and "tower_guardian.stats.move_speed = 52.0 if trial.floor_id == 2 else 65.0" in source and "body.radius = 34.0 if trial.floor_id == 2 else 26.0" in source, "legacy tower guardian literals are unchanged")
	suite.check(int(two.tower_guardian.hp) == 520 and is_equal_approx(float(two.tower_guardian.speed), 52.0) and is_equal_approx(float(one.tower_guardian.speed), 65.0) and is_equal_approx(float(one.tower_guardian.radius), 26.0) and is_equal_approx(float(two.tower_guardian.radius), 34.0), "catalog tower guardian values match the literals")
	suite.check(int(FloorCatalog.monster("javali").hp) == (load("res://data/actors/enemy.tres") as ActorData).max_hp and is_equal_approx(float(FloorCatalog.monster("javali").speed), (load("res://data/actors/enemy.tres") as ActorData).move_speed), "base monster matches the shared enemy resource")

static func run_world(suite) -> void:
	# Cada monstro do spawn comum, nos dois andares, deve sair da fábrica atual com os
	# mesmos números que o catálogo calcula.
	var previous_path := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://floor_catalog_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for floor_id in [1, 2]:
		main.progress.ascension.current_floor = floor_id
		for kind in [0, 1, 2, 3, 5, 6, 7]:
			var id := FloorCatalog.monster_id_for_kind(kind)
			var expected := FloorCatalog.scaled(id, floor_id)
			var actor: EnemyActor = main._make_enemy(kind)
			var label := "%s on floor %d" % [id, floor_id]
			suite.check(actor.stats.max_hp == int(expected.hp), "factory HP matches catalog for " + label)
			suite.check(actor.stats.contact_damage == int(expected.contact), "factory contact damage matches catalog for " + label)
			suite.check(is_equal_approx(actor.stats.move_speed, float(expected.speed)), "factory speed matches catalog for " + label)
			suite.check(is_equal_approx(actor.damage_scale, float(expected.damage_scale)) and actor.projectile_damage_override == int(expected.projectile), "factory scaling matches catalog for " + label)
			suite.check(actor.display_name() == str(FloorCatalog.monster(id).name), "display name matches catalog for " + label)
			actor.free()
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH", previous_path)
