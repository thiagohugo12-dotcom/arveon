extends RefCounted

static func run(suite: SceneTree) -> void:
	var p := TrainingLoadout.build()
	suite.check(p.save_blocked and p.disk_writes == 0 and p.save_path == "user://andar1_progress.json", "training never enables campaign persistence")
	suite.check(p.level() == RPGRules.MAX_LEVEL and p.attribute_points() == 0 and p.skill_points() >= 0, "training character has max level and a valid progression point budget")
	suite.check(p.active_category() == "espada" and p.equipped.Arma == "espada", "training starts with a sword")
	for category: String in AbilityRules.CATEGORIES:
		var catalogue: Dictionary = AbilityRules.CATEGORIES[category]
		suite.check(p.talents.level(category) == TalentRules.MAX_PROFICIENCY and p.equipment[category] == 3, "weapon is proficiency 60 and +3 in training: "+category)
		suite.check(p.abilities.loadouts[category].skills[1] == catalogue.ultimate.id, "training defaults to real optional Ultimate: "+category)
		for ability: Dictionary in catalogue.normal:
			suite.check(p.abilities.grades[category][ability.id] == AbilityRules.MAX_NORMAL_GRADE, "normal skill is fully upgraded: "+ability.id)
		for key: String in TalentRules.MASTERY:
			suite.check(p.talents.mastery[category][key] == TalentRules.MASTERY[key].cap, "training unlocks weapon mastery "+category+" / "+key)
	suite.check(not TrainingLoadout.equip(p,"espada","guarda_reativa","guarda_reativa","fio_afiado","ritmo_combate","duelista"), "duplicate ability selections are rejected in training")
	suite.check(not TrainingLoadout.equip(p,"espada","guarda_reativa","danca_laminas","fio_afiado","fio_afiado","duelista"), "duplicate passive selections are rejected")
	suite.check(TrainingLoadout.equip(p,"espada","guarda_reativa","danca_laminas","fio_afiado","ritmo_combate","duelista"), "sword guard + Kamusari can be equipped for rehearsal")
	suite.check(TrainingLoadout.equip(p,"machado","golpe_devastador","furia_machado","golpe_pesado","pele_ferro","berserker"), "training swaps class, weapons and unlocked skills")
	p.abilities.charge.machado = 0
	p.abilities.cooldowns.machado["golpe_devastador"] = 8.0
	p.abilities.global_ultimate_cooldown = 9.0
	TrainingLoadout.refill(p)
	suite.check(p.abilities.charge.machado == 100 and p.abilities.cooldowns.machado.is_empty() and p.abilities.global_ultimate_cooldown == 0.0, "infinite charge and resettable cooldowns are exclusive to sandbox")

static func run_world(suite: SceneTree) -> void:
	var arena = (load("res://scenes/training.tscn") as PackedScene).instantiate()
	suite.root.add_child(arena)
	await suite.frames()
	suite.check(arena.progress.save_blocked and arena.progress.disk_writes == 0, "actual training scene does not load/write campaign data")
	suite.check(arena.targets.size() == 3 and arena.input_driver.blocked, "arena starts with three stationary targets and paused loadout selector")
	suite.check(arena.training_menu.active and arena.training_menu.category_choice.item_count == 5, "in-game menu exposes all five weapon categories")
	arena._equip("espada","guarda_reativa","danca_laminas","fio_afiado","ritmo_combate","duelista")
	suite.check(arena.progress.active_category() == "espada" and not arena.input_driver.blocked, "loadout changes apply to real player combat without reloading saves")
	arena.player.last_direction = Vector2.RIGHT
	arena.player.set_physics_process(false)
	arena._process(0.1)
	suite.check(arena.player.use_skill(1) and arena.player.class_combat.guard_left > 0.0, "training triggers real Guard Reactive effect")
	arena._process(0.1)
	suite.check(arena.player.use_skill(2) and arena.progress.abilities.charge.espada == 0, "training triggers real Kamusari and spends sandbox charge")
	arena._process(0.1)
	suite.check(arena.progress.abilities.charge.espada == 100 and arena.progress.disk_writes == 0, "Ultimate refills without any disk write or original-save change")
	arena.queue_free()
	await suite.frames()
