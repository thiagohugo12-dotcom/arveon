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
		push_error("BOW_TECHNIQUE_FAIL: "+message)

func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func run() -> void:
	var previous := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://qa_bow_techniques_%d.json" % Time.get_ticks_usec()
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
	progress.equipment.arco = 0
	progress.equip("arco")
	progress.talents.xp.arco = TalentRules.xp_floor(60)
	progress.abilities.loadouts.arco.ultimate = "chuva_flechas"
	player.apply_progression(progress)
	player.position = Vector2(810,475)
	player.last_direction = Vector2.RIGHT
	enemy.position = player.position+Vector2(80,0)
	enemy.health.initialize(1000)
	check(player.view is Skill1GameView and player.view.skill_category == "arco","real player uses approved bow view")
	check(BowTechniqueEffect.ARROW_SPEED > player.attack.weapon.projectile_speed and BowTechniqueEffect.ARROW_SPEED <= player.attack.weapon.projectile_speed*1.3,"technique arrows travel only slightly faster than the basic arrow")
	for id in BowTechniqueEffect.ARROW_SHAFT:
		check(float(BowTechniqueEffect.ARROW_SHAFT[id]) <= 21.0,"technique arrow stays near basic arrow size "+id)
	for id in ["rajada_flechas","tiro_marcado","flecha_perfurante","chuva_flechas"]:
		progress.abilities.loadouts.arco.skills[0] = id if id != "chuva_flechas" else ""
		if id == "chuva_flechas": progress.abilities.charge.arco = 100
		player.apply_progression(progress)
		var before := enemy.health.current
		check(player.use_skill(3 if id == "chuva_flechas" else 1),id+" accepted with original rules")
		check(player.class_combat.technique.id == id and player.view.bow_technique.active and player.view.bow_technique.kind == id,id+" visual and combat share cast")
		if id == "tiro_marcado": check(player.view.bow_technique.marked_target == enemy,"marked shot highlights the real target")
		check(enemy.health.current == before,id+" no damage during preparation")
		var contact: float = BowTechniqueEffect.contact_time(id,float(player.class_combat.technique.reach))
		player.class_combat._tick_technique(contact-0.01)
		check(enemy.health.current == before,id+" no early contact")
		player.class_combat._tick_technique(0.02)
		check(enemy.health.current < before,id+" real contact lands once")
		var after := enemy.health.current
		player.class_combat._tick_technique(0.01)
		check(enemy.health.current == after,id+" no duplicate contact")
		player.class_combat.cancel_technique()
		check(not player.view.bow_technique.active,id+" effect clears")
	var rain := BowTechniqueEffect.rain_arrow_points(Vector2(41,72),0.5)
	check(is_equal_approx(rain[0].x,rain[1].x) and rain[1].y > rain[0].y,"rain arrows point vertically down")
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH",previous)
	CombatRules.random_roll_source = Callable()
	print("BOW_TECHNIQUE_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
