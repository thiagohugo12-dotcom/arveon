extends RefCounted

static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://qa_etapa2_combat.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in suite.get_nodes_in_group("damageable_enemies"): actor.queue_free()
	await suite.frames()
	var p: GameProgress = main.progress
	p.etapa2_enabled = true
	p.xp = RPGRules.xp_floor(100)
	main.earned_xp = p.xp
	var player: PlayerActor = main.player
	player.position = Vector2(850,750)
	player.last_direction = Vector2.RIGHT
	main.input_driver.blocked = false
	var enemy: EnemyActor = main._make_enemy(0)
	enemy.position = player.position+Vector2(40,0)
	main._register_enemy_defeat(enemy)
	main.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.health.initialize(100000)
	CombatRules.random_roll_source = func(): return 0.99
	for category: String in AbilityRules.CATEGORIES:
		p.equipment[category] = 3
		p.equipped.Arma = category
		p.talents.xp[category] = TalentRules.xp_floor(30)
		player.apply_progression(p)
		player.class_combat.clear_effects()
		p.abilities.death_reset()
		var before := enemy.health.current
		suite.check(player.use_skill(0),"individual Skill 1 executes "+category)
		for shot: PlayerProjectile in preload("res://tests/arsenal_combat_tests.gd").shots(main): shot._physics_process(0.5)
		suite.check(enemy.health.current < before and p.abilities.skill1_cooldowns[category] > 0,"Skill 1 causes real damage and shared timer "+category)
		var after := enemy.health.current
		suite.check(not player.use_skill(0) and enemy.health.current == after,"Skill 1 cannot double-activate "+category)
		for technique: Dictionary in AbilityRules.CATEGORIES[category].normal:
			p.abilities.select_skill(category,0,technique.id,30,true)
			p.abilities.death_reset()
			player.class_combat.clear_effects()
			before = enemy.health.current
			player.health.current = 70
			suite.check(player.use_skill(1),"normal technique executes "+technique.id)
			if technique.type == "defense":
				suite.check(player.class_combat.guard_left > 0 and player.health.current == 70,"defense provides a temporary effect without healing "+technique.id)
			else:
				suite.check(enemy.health.current < before,"normal technique deals actual category damage "+technique.id)
			var remaining := float(p.abilities.cooldowns[category][technique.id])
			p.abilities.select_skill(category,0,"",30,true)
			p.abilities.select_skill(category,1,technique.id,30,true)
			player.apply_progression(p)
			suite.check(not player.use_skill(2) and p.abilities.cooldowns[category][technique.id] == remaining,"moving a technique preserves its real cooldown "+technique.id)
			p.abilities.select_skill(category,1,"",30,true)
			for grade in range(2,5):
				suite.check(p.abilities.improve(category,technique.id,30,p.skill_points(),true),"grade purchase "+technique.id+str(grade))
			suite.check(not p.abilities.improve(category,technique.id,30,p.skill_points(),true),"normal technique caps at grade four "+technique.id)
		var ultimate: Dictionary = AbilityRules.CATEGORIES[category].ultimate
		p.abilities.select_skill(category,0,ultimate.id,30,true)
		p.abilities.death_reset()
		p.abilities.charge[category] = 100
		before = enemy.health.current
		suite.check(player.use_skill(1) and p.abilities.charge[category] == 0,"Ultimate executes and consumes independent bar "+category)
		suite.check(p.abilities.charge[category] == 0 and not player.use_skill(1),"Ultimate own damage cannot recharge or reactivate "+category)
		if ultimate.type == "buff": suite.check(player.class_combat.fury_left == 8,"axe Ultimate uses timed heavy-combat buff")
		else: suite.check(enemy.health.current < before,"Ultimate deals real damage "+category)
		p.abilities.death_reset()
		player.class_combat.clear_effects()
		player.attack.cooldown_left = 0
		player.attack.search_left = 0
		before = enemy.health.current
		player.attack.tick(0,player)
		for shot: PlayerProjectile in preload("res://tests/arsenal_combat_tests.gd").shots(main): shot._physics_process(0.5)
		suite.check(p.abilities.charge[category] > 0 and enemy.health.current < before,"valid basic damage charges only equipped active Ultimate "+category)
		var saved := p.to_json()
		var restored := GameProgress.new()
		suite.check(restored.load_text(saved) and restored.abilities.to_save() == p.abilities.to_save(),"live combat state roundtrip has no offline advance "+category)
		var hp := player.health.current
		p.abilities.refund(category,true)
		player.apply_progression(p)
		suite.check(player.health.current == hp,"combat respec cannot heal "+category)
	main.input_driver.blocked = true
	var snapshot := p.abilities.to_save()
	suite.check(not player.use_skill(0) and p.abilities.to_save() == snapshot,"blocked controls cannot consume cooldowns")
	main.input_driver.blocked = false
	player.position = SafeCamp.RESPAWN
	suite.check(not player.use_skill(0),"new class attacks respect safe camp")
	player.position = Vector2(850,750)
	player.health.damage(player.health.current)
	suite.check(p.abilities.charge.values().all(func(value):return value == 0) and p.abilities.skill1_cooldowns.values().all(func(value):return value == 0),"real death clears all five charges and normal timers")
	CombatRules.random_roll_source = Callable()
	main.queue_free()
	await suite.frames()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
