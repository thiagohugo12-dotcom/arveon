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
		push_error("SPEAR_TECHNIQUE_FAIL: "+message)

func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func run() -> void:
	var previous := OS.get_environment("ARVEON_SAVE_PATH")
	var path := "user://qa_spear_techniques_%d.json" % Time.get_ticks_usec()
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
	progress.equipment.lanca = 0
	progress.equip("lanca")
	progress.talents.xp.lanca = TalentRules.xp_floor(60)
	progress.abilities.loadouts.lanca.ultimate = "muralha_lancas"
	player.apply_progression(progress)
	player.position = Vector2(810,475)
	player.last_direction = Vector2.RIGHT
	enemy.position = player.position+Vector2(80,0)
	enemy.health.initialize(2500)
	check(player.view is Skill1GameView and player.view.skill_category == "lanca","real player uses spear view")
	for id in ["estocada_longa","varredura","marca_caca","muralha_lancas"]:
		progress.abilities.loadouts.lanca.skills[0] = id if id != "muralha_lancas" else ""
		if id == "muralha_lancas": progress.abilities.charge.lanca = 100
		player.apply_progression(progress)
		var before := enemy.health.current
		check(player.use_skill(3 if id == "muralha_lancas" else 1),id+" accepted with original rule")
		check(player.class_combat.technique.id == id and player.view.spear_technique.active,id+" animation and combat share cast")
		check(enemy.health.current == before,id+" preparation has no early damage")
		var contact: float = SpearTechniqueEffect.TIMINGS[id].contact
		player.class_combat._tick_technique(contact-0.01)
		check(enemy.health.current == before,id+" no early contact")
		player.class_combat._tick_technique(0.02)
		check(enemy.health.current < before,id+" real contact lands once")
		if id == "marca_caca": check(enemy.mark_category == "lanca" and enemy.mark_left > 0,"hunting mark uses original mark")
		if id == "varredura" or id == "muralha_lancas": check(enemy.control_left > 0,id+" uses original control")
		var after := enemy.health.current
		player.class_combat._tick_technique(0.01)
		check(enemy.health.current == after,id+" no duplicate contact")
		player.class_combat.cancel_technique()
		check(not player.view.spear_technique.active,id+" effect clears")
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("ARVEON_SAVE_PATH",previous)
	CombatRules.random_roll_source = Callable()
	print("SPEAR_TECHNIQUE_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
