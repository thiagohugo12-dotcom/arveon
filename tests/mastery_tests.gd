extends RefCounted

static func run(suite: SceneTree) -> void:
	var p := GameProgress.new()
	p.xp = RPGRules.xp_floor(40)
	for weapon: String in ArsenalRules.CATEGORIES:
		p.equipment[weapon] = 0
		p.equip(weapon)
		suite.check(p.active_class() == TalentRules.CLASSES[weapon],"dynamic class follows equipped "+weapon)
		p.talents.record_damage(weapon,TalentRules.xp_floor(30)+99999)
		suite.check(p.talents.level(weapon) == 30 and p.talents.mastery_points(weapon) == 29 and p.skill_points() == 39,"proficiency caps independently and grants mastery not talent points "+weapon)
		for i in range(12): suite.check(p.talents.allocate_mastery(weapon,"Dano",i),"mastery basic allocation "+weapon+str(i))
		suite.check(not p.talents.allocate_mastery(weapon,"Dano",12) and not p.talents.allocate_mastery(weapon,"Dano Especial",1),"mastery cap and stale tap rejected "+weapon)
		for i in range(10): p.talents.allocate_mastery(weapon,"Crítico",i)
		for i in range(7): p.talents.allocate_mastery(weapon,"Dano Crítico",i)
		suite.check(p.talents.mastery_points(weapon) == 0 and not p.talents.allocate_mastery(weapon,"Dano Especial",0),"29 point category budget cannot be overspent "+weapon)
		var stats := p.combat_stats()
		suite.check(is_equal_approx(stats.automatic,0.145) and is_equal_approx(stats.basic,0.12) and is_equal_approx(stats.critical_chance,0.15) and is_equal_approx(stats.critical_multiplier,1.71),"category bonuses do not stack with previous categories "+weapon)
		var hit := CombatRules.resolve(stats[stats.damage_type],1.0+stats.automatic+stats.basic,1,stats.critical_chance,stats.critical_multiplier,0)
		var normal := CombatRules.resolve(stats[stats.damage_type],1.0+stats.automatic+stats.basic,1,stats.critical_chance,stats.critical_multiplier,0.99)
		suite.check(hit.critical and hit.damage > normal.damage and not normal.critical,"physical or magical critical resolved once "+weapon)
	var restored := GameProgress.new()
	suite.check(restored.load_text(p.to_json()) and restored.to_json() == p.to_json(),"v9 roundtrip preserves five separate mastery builds")
	var snapshot := restored.to_json()
	for mutation: String in ["negative","fraction","cap","budget","missing","unknown"]:
		var invalid: Dictionary = JSON.parse_string(snapshot)
		match mutation:
			"negative": invalid.talents.mastery.espada["Dano"] = -1
			"fraction": invalid.talents.mastery.espada["Dano"] = 1.5
			"cap": invalid.talents.mastery.espada["Dano"] = 13
			"budget": invalid.talents.mastery.espada["Dano Especial"] = 1
			"missing": invalid.talents.mastery.erase("arco")
			"unknown": invalid.talents.mastery.espada["Inexistente"] = 0
		suite.check(not restored.load_text(JSON.stringify(invalid)) and restored.to_json() == snapshot,"mastery save validation atomic "+mutation)
	for old_version in [7,8]:
		for level in range(1,31):
			var old: Dictionary = JSON.parse_string(p.to_json())
			old.version = old_version
			old.talents.erase("mastery")
			old.talents.erase("damage_remainder")
			for weapon: String in ArsenalRules.CATEGORIES:
				old.talents.xp[weapon] = (level-1)*level*10 + level*10 if level < 30 else 8700
			if old_version == 7: old.rpg.attributes = preload("res://tests/progression_tests.gd").legacy_attributes(p.attributes)
			suite.check(restored.load_text(JSON.stringify(old)) and restored.talents.level("espada") == level and restored.talents.mastery_points("espada") == level-1,"legacy curve preserves level and earned mastery v%d level%d" % [old_version,level])
			if level < 30:
				var fraction := float(int(restored.talents.xp.espada)-TalentRules.xp_floor(level))/(TalentRules.xp_floor(level+1)-TalentRules.xp_floor(level))
				suite.check(is_equal_approx(fraction,0.5),"legacy curve preserves fractional progress v%d level%d" % [old_version,level])
	# Existing temporary tree and legacy ranks survive migration together.
	var old: Dictionary = JSON.parse_string(p.to_json())
	old.version = 7
	old.rpg.attributes = {"Força":3,"Vitalidade":2,"Agilidade":7,"Espírito":4}
	old.rpg.skills["Corte Circular"] = 3
	old.talents.erase("mastery")
	old.talents.erase("damage_remainder")
	old.talents.xp.espada = 3100
	old.talents.learned.espada = ["corte","vigor","guarda","investida","furia","especializacao"]
	# Other categories must also use the old curve.
	for weapon: String in ["machado","lanca","arco","cajado"]: old.talents.xp[weapon] = 8700
	suite.check(restored.load_text(JSON.stringify(old)) and restored.talents.level("espada") == 18 and restored.talents.spent() == 6 and restored.skills["Corte Circular"] == 3 and restored.attribute_points() == 69,"v7 preserves acquired tree ranks and exact Agility refund")
	var raw := JSON.stringify(old)
	var envelope := JSON.stringify({"format":"grande-arvore-rpg-save","archive_version":1,"payload":raw,"sha256":raw.sha256_text()})
	var path := "user://qa_progression_migration_%d.json" % Time.get_ticks_usec()
	restored.save_path = path
	suite.check(restored.import_backup(envelope,true) and restored.save(),"old checksummed backup imports into new schema")
	var imported := GameProgress.new()
	imported.save_path = path
	suite.check(imported.load_save() and imported.to_json() == restored.to_json() and imported.preview_backup(imported.export_backup()) != null,"old import export filesystem reload preserves progression")
	var original := imported.to_json()
	suite.check(imported.import_backup(envelope,true) and imported.to_json() == original,"repeated old import refunds once and never adds rewards")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_effective_damage_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	var enemy: EnemyActor = main.enemy
	enemy.set_physics_process(false)
	enemy.position = Vector2(850,400)
	enemy.awake = true
	enemy.health.initialize(100)
	var event := CombatRules.next_event()
	enemy.receive_damage(25,"espada",event)
	var xp: int = main.progress.talents.xp.espada
	suite.check(xp == 2 and main.progress.talents.damage_remainder.espada == 5 and enemy.health.current == 75,"effective damage creates category XP and carries fractional remainder")
	enemy.receive_damage(25,"espada",event)
	enemy.weapon_hit.emit("espada",25,event)
	suite.check(main.progress.talents.xp.espada == xp and enemy.health.current == 75,"duplicate hit and repeated signal cannot grant damage or XP")
	enemy.invulnerable = true
	enemy.receive_damage(999,"espada")
	enemy.invulnerable = false
	enemy.receive_damage(0,"espada")
	suite.check(main.progress.talents.xp.espada == xp and enemy.health.current == 75,"zero and invulnerable damage grant no XP")
	for i in range(4):
		enemy.health.heal(25)
		enemy.receive_damage(25,"espada")
	suite.check(main.progress.talents.xp.espada == 10 and enemy.health.current == 75,"regeneration cannot replenish the original life XP budget")
	enemy.receive_damage(99999,"espada")
	suite.check(main.progress.talents.xp.espada == 10,"overkill after exhausted budget grants no XP")
	# Fresh registered life: lethal hit is included in the defeat autosave.
	var victim: EnemyActor = (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate()
	victim.position = Vector2(850,400)
	main.add_child(victim)
	main._register_enemy_defeat(victim)
	victim.set_physics_process(false)
	victim.health.initialize(17)
	victim.receive_damage(9000,"arco")
	victim.receive_damage(9000,"arco")
	var loaded := GameProgress.new()
	loaded.save_path = path
	suite.check(main.progress.talents.xp.arco == 1 and loaded.load_save() and loaded.talents.xp.arco == 1 and loaded.talents.damage_remainder.arco == 7,"lethal overkill grants available HP once before autosave; dead hits do nothing")
	main.progress.attributes["Mobilidade"] = 20
	main.progress.attributes["Destreza"] = 20
	main.player.apply_progression(main.progress)
	suite.check(main.player.stats.dash_speed == 620 and main.player.stats.move_speed == 216 and is_equal_approx(main.player.attack.weapon.interval,0.65*0.85),"actual player Mobility and Dexterity never change Dash")
	for actor in suite.get_nodes_in_group("damageable_enemies"): actor.queue_free()
	await suite.frames()
	var target: EnemyActor = main._make_enemy(0)
	target.position = Vector2(870,475)
	main._register_enemy_defeat(target)
	main.add_child(target)
	target.health.initialize(1000)
	target.set_physics_process(false)
	main.player.position = Vector2(810,475)
	main.progress.attributes["Força"] = 3
	main.progress.attributes["Espírito"] = 5
	CombatRules.random_roll_source = func(): return 0.0
	for category: String in ArsenalRules.CATEGORIES:
		main.progress.equipment[category] = 0
		main.progress.equip(category)
		main.player.apply_progression(main.progress)
		var attack: AutoAttack = main.player.attack
		attack.cooldown_left = 0
		attack.search_left = 0
		var before := target.health.current
		var expected := CombatRules.resolve(attack.damage_base,attack.basic_bonus,1,attack.critical_chance,attack.critical_multiplier,0)
		attack.tick(0,main.player)
		for shot: PlayerProjectile in preload("res://tests/arsenal_combat_tests.gd").shots(main):
			suite.check(shot.critical and shot.damage_type == ("magical" if category == "cajado" else "physical"),"projectile snapshots critical and damage type "+category)
			shot._physics_process(0.3)
		suite.check(target.health.current == before-int(expected.damage) and target.view.damage_critical,"actual basic critical damage and feedback "+category)
		await suite.frames()
	CombatRules.random_roll_source = func(): return 0.99
	# Current techniques retain physical scaling, even with the magical staff.
	main.progress.talents.xp.cajado = TalentRules.xp_floor(18)
	main.progress.talents.mastery.cajado["Dano Especial"] = 12
	main.player.apply_progression(main.progress)
	var base_stats: Dictionary = main.progress.combat_stats()
	var hp_before := target.health.current
	main.player.skill_cooldowns[0] = 0
	main.player.use_skill(0)
	var expected_skill := CombatRules.resolve(base_stats.physical,1+base_stats.automatic+base_stats.special,1.4,base_stats.critical_chance,base_stats.critical_multiplier,0.99)
	suite.check(target.health.current == hp_before-int(expected_skill.damage),"staff keeps existing physical technique, with special mastery but no Spirit leakage")
	main.player.skill_cooldowns[2] = 0
	main.player.use_skill(2)
	suite.check(main.player.fury_left == 6 and main.player.attack.damage_scale == 1.3,"special mastery does not increase Fury duration or its buff magnitude")
	main.queue_free()
	await suite.frames()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
