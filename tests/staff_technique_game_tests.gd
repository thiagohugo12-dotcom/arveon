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
		push_error("STAFF_TECHNIQUE_FAIL: "+message)

func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func run() -> void:
	var previous := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://qa_staff_techniques_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",path)
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
	progress.equipment.cajado = 0
	progress.equip("cajado")
	progress.talents.xp.cajado = TalentRules.xp_floor(60)
	progress.abilities.loadouts.cajado.ultimate = "tempestade_arcana"
	player.apply_progression(progress)
	player.position = Vector2(810,475)
	player.last_direction = Vector2.RIGHT
	enemy.position = player.position+Vector2(80,0)
	enemy.health.initialize(2000)
	check(player.view is Skill1GameView and player.view.skill_category == "cajado","real player uses approved staff view")
	for id in ["onda_arcana","selo_mistico","tempestade_arcana"]:
		progress.abilities.loadouts.cajado.skills[0] = id if id != "tempestade_arcana" else ""
		if id == "tempestade_arcana": progress.abilities.charge.cajado = 100
		player.apply_progression(progress)
		var before := enemy.health.current
		check(player.use_skill(3 if id == "tempestade_arcana" else 1),id+" accepted with original rule")
		check(player.class_combat.technique.id == id and player.view.staff_technique.active,id+" animation and combat share cast")
		check(enemy.health.current == before,id+" preparation has no early damage")
		var contact: float = StaffTechniqueEffect.TIMINGS[id].contact
		if id == "onda_arcana":
			var clock_before := player.class_combat.technique_elapsed
			main.input_driver.blocked = true
			player.class_combat._tick_technique(0.5)
			check(player.class_combat.technique_elapsed == clock_before and enemy.health.current == before,"modal pauses staff contact")
			main.input_driver.blocked = false
		player.class_combat._tick_technique(contact-0.01)
		check(enemy.health.current == before,id+" no early contact")
		player.class_combat._tick_technique(0.02)
		check(enemy.health.current < before,id+" real contact lands once")
		if id == "selo_mistico": check(enemy.mark_category == "cajado" and enemy.mark_left > 0,"seal applies the existing mark")
		var after := enemy.health.current
		player.class_combat._tick_technique(0.01)
		check(enemy.health.current == after,id+" no duplicate contact")
		player.class_combat.cancel_technique()
		check(not player.view.staff_technique.active,id+" offensive effect clears")
	progress.abilities.loadouts.cajado.skills[0] = "barreira_espiritual"
	player.apply_progression(progress)
	var before_guard := enemy.health.current
	check(player.use_skill(1),"spiritual barrier accepted")
	check(player.class_combat.technique.is_empty() and player.class_combat.guard_left >= 5.0 and player.class_combat.barrier > 0,"barrier keeps original immediate protection")
	check(player.view.staff_guard.active and enemy.health.current == before_guard,"barrier visuals add no damage")
	player.class_combat.tick(1.0)
	player.view._process(0.0)
	check(player.view.staff_guard.active and player.view.staff_guard.elapsed > 0.0,"barrier visual follows actual guard timer")
	player.class_combat.tick(10.0)
	player.view._process(0.0)
	check(not player.view.staff_guard.active and player.class_combat.guard_left == 0.0,"barrier visual ends with protection")
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH",previous)
	CombatRules.random_roll_source = Callable()
	print("STAFF_TECHNIQUE_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
