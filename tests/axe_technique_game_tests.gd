extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	CombatRules.random_roll_source = func(): return 0.99
	create_timer(60.0).timeout.connect(func(): quit(1))
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("AXE_TECHNIQUE_FAIL: "+message)

func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func run() -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_axe_techniques_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	var player: PlayerActor = main.player
	var enemy: EnemyActor = main.enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	for candidate in get_nodes_in_group("damageable_enemies"):
		if candidate != enemy: candidate.queue_free()
	await frames()
	var progress: GameProgress = main.progress
	progress.equipment.machado = 0
	progress.equip("machado")
	progress.talents.xp.machado = TalentRules.xp_floor(60)
	progress.abilities.loadouts.machado.ultimate = "furia_machado"
	player.apply_progression(progress)
	player.position = Vector2(810,475)
	player.last_direction = Vector2.RIGHT
	enemy.position = player.position+Vector2(80,0)
	enemy.health.initialize(2000)
	check(player.view is Skill1GameView and player.view.skill_category == "machado","real player uses axe view")
	for id in ["golpe_devastador","quebra_guarda","impacto_brutal"]:
		progress.abilities.loadouts.machado.skills[0] = id
		player.apply_progression(progress)
		var before := enemy.health.current
		check(player.use_skill(1),id+" accepted with original rule")
		check(player.class_combat.technique.id == id and player.view.axe_technique.active,id+" animation and combat share cast")
		check(enemy.health.current == before,id+" preparation has no early damage")
		var contact: float = AxeTechniqueEffect.TIMINGS[id].contact
		player.class_combat._tick_technique(contact-0.01)
		check(enemy.health.current == before,id+" no early contact")
		player.class_combat._tick_technique(0.02)
		check(enemy.health.current < before,id+" real contact lands once")
		if id == "quebra_guarda": check(enemy.mark_category == "machado" and enemy.mark_left > 0,"guard break applies existing mark")
		if id == "impacto_brutal": check(enemy.control_left > 0,"brutal impact applies existing control")
		var after := enemy.health.current
		player.class_combat._tick_technique(0.01)
		check(enemy.health.current == after,id+" no duplicate contact")
		player.class_combat.cancel_technique()
		check(not player.view.axe_technique.active,id+" effect clears")
	progress.abilities.charge.machado = 100
	player.apply_progression(progress)
	var before_fury := enemy.health.current
	check(player.use_skill(3),"fury accepted")
	check(player.class_combat.technique.is_empty() and player.class_combat.fury_left >= 7.9,"fury retains original immediate eight-second buff")
	check(player.view.axe_fury.active and enemy.health.current == before_fury,"fury visuals add no damage")
	player.class_combat.tick(1.0)
	player.view._process(0.0)
	check(player.view.axe_fury.active and player.view.axe_fury.elapsed > 0.0,"fury visual follows actual timer")
	player.class_combat.tick(10.0)
	player.view._process(0.0)
	check(not player.view.axe_fury.active and player.class_combat.fury_left == 0.0,"fury visual ends with buff")
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
	CombatRules.random_roll_source = Callable()
	print("AXE_TECHNIQUE_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
