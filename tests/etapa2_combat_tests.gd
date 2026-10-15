extends RefCounted

static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://qa_etapa2_combat.json")
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
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
		var category_prof := 40 if category == "espada" else 30
		p.talents.xp[category] = TalentRules.xp_floor(category_prof)
		player.apply_progression(p)
		player.class_combat.clear_effects()
		p.abilities.death_reset()
		var before := enemy.health.current
		suite.check(player.use_skill(0),"individual Skill 1 executes "+category)
		preload("res://tests/etapa2_fixtures.gd").finish_skill1(player)
		for shot: PlayerProjectile in preload("res://tests/arsenal_combat_tests.gd").shots(main): shot._physics_process(0.5)
		suite.check(enemy.health.current < before and p.abilities.skill1_cooldowns[category] > 0,"Skill 1 causes real damage and shared timer "+category)
		var after := enemy.health.current
		suite.check(not player.use_skill(0) and enemy.health.current == after,"Skill 1 cannot double-activate "+category)
		for technique: Dictionary in AbilityRules.CATEGORIES[category].normal:
			p.abilities.select_skill(category,0,technique.id,category_prof,true)
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
			p.abilities.select_skill(category,1,technique.id,category_prof,true)
			player.apply_progression(p)
			suite.check(not player.use_skill(2) and p.abilities.cooldowns[category][technique.id] == remaining,"moving a technique preserves its real cooldown "+technique.id)
			p.abilities.select_skill(category,1,"",30,true)
			for grade in range(2,5):
				suite.check(p.abilities.improve(category,technique.id,category_prof,p.skill_points(),true),"grade purchase "+technique.id+str(grade))
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
	# A damage amplifier cannot credit its own added damage to the same bar.
	p.equipped.Arma = "machado"
	p.configure_ability("equip_skill","machado","golpe_devastador",0,true)
	p.configure_ability("equip_skill","machado","furia_machado",1,true)
	p.abilities.death_reset()
	player.apply_progression(p)
	player.class_combat.clear_effects()
	enemy.mark_left = 0.0
	p.abilities.charge.machado = 100
	suite.check(player.use_skill(2),"axe Ultimate amplifier activates for credit accounting regression")
	var unboosted_basic := CombatRules.resolve(player.attack.damage_base,player.attack.basic_bonus,1.0,player.attack.critical_chance,player.attack.critical_multiplier,0.99)
	var unboosted_skill := CombatRules.resolve(player.attack.damage_base,player.special_bonus,1.70,player.attack.critical_chance,player.attack.critical_multiplier,0.99)
	var amplified_before := enemy.health.current
	player.attack.cooldown_left = 0.0
	player.attack.search_left = 0.0
	player.attack.tick(0,player)
	suite.check(player.use_skill(1),"normal technique retains its real axe Ultimate amplification")
	var credited := int(p.abilities.charge.machado)*10+int(p.abilities.charge_remainder.machado)
	suite.check(credited == int(unboosted_basic.damage)+int(unboosted_skill.damage) and amplified_before-enemy.health.current > credited,"Ultimate amplifier bonus is excluded while valid unamplified basics and techniques charge once")
	# Test the actual level-30 mechanic under a non-critical random roll.
	p.equipped.Arma = "espada"
	p.configure_ability("equip_skill","espada","corte_crescente",0,true)
	p.configure_ability("equip_skill","espada","",1,true)
	p.abilities.death_reset()
	player.apply_progression(p)
	player.class_combat.clear_effects()
	for i in range(3):
		player.attack.cooldown_left = 0
		player.attack.search_left = 0
		player.attack.tick(0,player)
	suite.check(player.class_combat.perfect_ready,"three real basics prepare sword Maestria without an equipped Ultimate")
	var hp_before := enemy.health.current
	var normal := CombatRules.resolve(player.attack.damage_base,player.special_bonus,1.45,player.attack.critical_chance,player.attack.critical_multiplier,0.99)
	suite.check(player.use_skill(1) and enemy.view.damage_critical and hp_before-enemy.health.current > int(normal.damage) and not player.class_combat.perfect_ready,"level-30 critical override executes once despite ordinary critical cap")
	suite.check(not CombatRules.resolve(12,1,1,1.0,1.5,0.30).critical and CombatRules.resolve(12,1,1,0.05,1.5,0.30,0.40).critical,"ordinary critical cap preserved while class-specific precision can apply")
	var boss := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	main.add_child(boss)
	boss.position = enemy.position
	boss.kind = 4
	boss.apply_mark("espada",0.15,2.0)
	boss.apply_control(1.0)
	boss.tick_ability_status(2.0)
	suite.check(boss.mark_left == 0 and boss.control_left == 0,"Guardian marks expire and control cannot interrupt boss telegraphs")
	boss.queue_free()
	var occupied: Array[Node2D] = []
	for i in range(PlayerProjectile.MAX_ACTIVE):
		var node := Node2D.new()
		main.add_child(node)
		node.add_to_group("player_projectiles")
		occupied.append(node)
	p.equipped.Arma = "arco"
	player.apply_progression(p)
	p.abilities.death_reset()
	suite.check(not player.use_skill(0) and p.abilities.skill1_cooldowns.arco == 0,"full projectile pool cannot consume a cast or its cooldown")
	for node: Node2D in occupied: node.queue_free()
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
