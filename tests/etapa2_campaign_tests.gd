extends RefCounted
static func run_world(suite: SceneTree) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://qa_etapa2_campaign.json")
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in suite.get_nodes_in_group("damageable_enemies"): actor.queue_free()
	await suite.frames()
	var p: GameProgress = main.progress
	p.xp = RPGRules.xp_floor(100)
	main.earned_xp = p.xp
	for floor_id in range(1,6):
		p.switch_floor(floor_id)
		p.ascension.defeats[str(floor_id)] = 50
		p.ascension.complete_forest_trial()
	var player: PlayerActor = main.player
	player.position = Vector2(850,750)
	player.last_direction = Vector2.RIGHT
	main.input_driver.blocked = false
	CombatRules.random_roll_source = func(): return 0.99
	for floor_id in range(1,6):
		p.switch_floor(floor_id)
		for category: String in AbilityRules.CATEGORIES:
			var catalog: Dictionary = AbilityRules.CATEGORIES[category]
			p.equipment[category] = 0
			p.equipped.Arma = category
			p.talents.xp[category] = TalentRules.xp_floor(30)
			p.configure_ability("equip_skill",category,catalog.normal[0].id,0,true)
			p.configure_ability("equip_skill",category,catalog.ultimate.id,1,true)
			player.apply_progression(p)
			player.class_combat.clear_effects()
			p.abilities.death_reset()
			var enemy: EnemyActor = main._make_enemy(3)
			enemy.position = player.position+Vector2(50,0)
			main._register_enemy_defeat(enemy)
			main.add_child(enemy)
			enemy.set_physics_process(false)
			enemy.health.initialize(2000)
			var original := enemy.health.current
			suite.check(player.use_skill(0),"class Skill 1 executes in floor matrix "+category+str(floor_id))
			preload("res://tests/etapa2_fixtures.gd").finish_skill1(player)
			for shot: PlayerProjectile in preload("res://tests/arsenal_combat_tests.gd").shots(main): shot._physics_process(0.5)
			suite.check(player.use_skill(1) and enemy.health.current < original,"normal technique damages scaled elite "+category+str(floor_id))
			player.attack.cooldown_left = 0
			player.attack.search_left = 0
			player.attack.tick(0,player)
			for shot: PlayerProjectile in preload("res://tests/arsenal_combat_tests.gd").shots(main): shot._physics_process(0.5)
			suite.check(p.abilities.charge[category] > 0,"valid floor receipts charge correct class Ultimate "+category+str(floor_id))
			p.abilities.charge[category] = 100
			suite.check(player.use_skill(2) and p.abilities.charge[category] == 0,"Ultimate consumes once in every floor "+category+str(floor_id))
			enemy.queue_free()
			await suite.frames()
	var restored := GameProgress.new()
	suite.check(restored.load_text(p.to_json()) and restored.ascension.campaign_completed and restored.floor_states.size() == 5 and not restored.ascension.unlocked_floors.has(6),"25 class/floor combinations preserve exact five-floor campaign format")
	main.queue_free()
	await suite.frames()
	CombatRules.random_roll_source = Callable()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
