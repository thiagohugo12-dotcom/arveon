extends RefCounted

static func run(suite: SceneTree, scene: PackedScene, path: String) -> void:
	var main = scene.instantiate()
	suite.root.add_child(main)
	await suite.frames()
	var before := FileAccess.get_file_as_string(path)
	var disk_writes: int = main.progress.disk_writes
	main._start_training()
	var practice: GameProgress = main.progress
	suite.check(practice.training_mode and practice != null and practice.save_path == "user://andar1_progress.json", "training swaps to a separate in-memory build")
	suite.check(practice.level() == RPGRules.MAX_LEVEL and practice.equipment.size() == RPGRules.EQUIPMENT.size() and practice.active_category() == "espada", "training unlocks all weapons and the maximum character level")
	for category: String in AbilityRules.CATEGORIES:
		suite.check(practice.talents.level(category) == TalentRules.MAX_PROFICIENCY and practice.abilities.charge[category] == 100 and practice.abilities.loadouts[category].ultimate == AbilityRules.CATEGORIES[category].ultimate.id, "training unlocks proficiency and ultimate "+category)
	suite.check(main.enemy.is_targetable() and main.enemy.health.maximum == 1000000 and not main.enemy.is_physics_processing(), "stationary durable target receives real combat damage")
	var hp: int = main.enemy.health.current
	practice.abilities.loadouts.espada.skills[0] = "estocada_precisa"
	main.player.apply_progression(practice)
	suite.check(main.player.use_skill(1) and main.enemy.health.current == hp and (main.player.view as Skill1GameView).sword_technique.kind == "estocada_precisa", "training starts the technique without premature damage")
	preload("res://tests/etapa2_fixtures.gd").finish_technique(main.player)
	suite.check(main.enemy.health.current < hp,"training technique damages at the shared contact event")
	practice.abilities.cooldowns.espada.estocada_precisa = 5.0
	practice.abilities.charge.espada = 0
	TrainingMode.refill(practice)
	main.player._sync_skill_cooldowns()
	suite.check(practice.abilities.cooldowns.espada.is_empty() and practice.abilities.charge.espada == 100 and main.player.skill_ready(1), "training refill resets skill timers and ultimate charge")
	main._save_progress()
	suite.check(practice.disk_writes == 0 and FileAccess.get_file_as_string(path) == before and disk_writes >= 0, "combat and autosave attempts cannot change real save")
	main.queue_free()
	await suite.frames()
	var restored := GameProgress.new()
	restored.save_path = path
	suite.check(restored.load_save() and not restored.training_mode and restored.equipment != practice.equipment, "reloading preserves the original character instead of the training build")
