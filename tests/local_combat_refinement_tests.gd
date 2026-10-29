extends SceneTree
var checks := 0
var failures := 0
var hit_events := 0
var impact_events := 0
var main: Node2D
var player: PlayerActor
var enemy: EnemyActor
func _initialize() -> void:
	create_timer(40).timeout.connect(func(): push_error("REFINEMENT_TIMEOUT"); quit(1))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ",message)
func ready_cast(id: String) -> void:
	player.class_combat.clear_effects()
	TrainingMode.refill(main.progress)
	main.progress.abilities.loadouts.espada.skills = [id,"guarda_reativa"]
	player.apply_progression(main.progress)
	player.attack.cooldown_left = 100
	enemy.health.initialize(1000000)
	hit_events = 0
	impact_events = 0
func run() -> void:
	OS.set_environment("ARVEON_SAVE_PATH","user://local_refine_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in range(4): await process_frame
	main._start_training()
	main.set_process(false)
	player = main.player
	enemy = main.enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.input_driver.blocked = false
	enemy.health.changed.connect(func(_hp: int,_maximum: int): hit_events += 1)
	player.class_combat.technique_impact.connect(func(_id: String,_time: float): impact_events += 1)
	CombatRules.random_roll_source = func(): return 0.99
	for id: String in SwordTechniqueTiming.FRAMES:
		for direction in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
			for delta in [1.0/120.0,1.0/30.0,0.25]:
				ready_cast(id)
				player.last_direction = direction
				enemy.position = player.position+direction*65
				await physics_frame
				check(player.use_skill(1),id+" accepted")
				check(hit_events == 0,"no damage before animation "+id)
				check(not player.use_skill(1),"no overlapping/double activation")
				var elapsed := 0.0
				while elapsed < SwordTechniqueTiming.duration(id)+0.3:
					player.class_combat.tick(delta)
					elapsed += delta
					if elapsed < SwordTechniqueTiming.contact(id)-0.000001: check(hit_events == 0,"precontact no damage")
				check(hit_events == (4 if id == "danca_laminas" else 1),"exact configured hit count "+id+" dt="+str(delta))
				check(impact_events == 1,"one contact event after skipped frames")
				check(player.class_combat.technique.is_empty(),"recovery clears state")
		# Precisely straddle the shared contact boundary, pause, and lock aim.
		ready_cast(id)
		player.last_direction = Vector2.RIGHT
		enemy.position = player.position+Vector2(65,0)
		await physics_frame
		player.use_skill(1)
		player.class_combat.tick(SwordTechniqueTiming.contact(id)-0.001)
		check(hit_events == 0,"one ms before contact")
		player.input_driver.blocked = true
		var held := player.class_combat.technique_elapsed
		player.class_combat.tick(1.0)
		check(hit_events == 0 and player.class_combat.technique_elapsed == held,"modal pauses both clocks")
		player._physics_process(0.5)
		check(player.view.sword_technique.kind == id and player.class_combat.technique_elapsed == held,"real PlayerActor menu path retains the paused technique pose")
		player.input_driver.blocked = false
		player.last_direction = Vector2.LEFT
		player.class_combat.tick(0.001)
		check(hit_events > 0,"contact uses original aim")
		check(player.view.sword_technique._frame() == SwordTechniqueTiming.CONTACT_FRAME,"render uses exact damage frame")
		var dealt := hit_events
		player.class_combat.tick(1.0)
		check(hit_events == dealt,"no second hit after recovery")
		# Cancellation on death and category/equipment change.
		ready_cast(id)
		player.use_skill(1)
		player._on_died()
		player.class_combat.tick(1.0)
		check(hit_events == 0 and player.class_combat.technique.is_empty(),"death cancels queued contact")
		ready_cast(id)
		player.use_skill(1)
		main.progress.equipped.Arma = "arco"
		player.apply_progression(main.progress)
		player.class_combat.tick(1.0)
		check(hit_events == 0,"weapon change cancels queued contact")
		main.progress.equipped.Arma = "espada"
		# Original hit area must still reject out-of-range / out-of-line targets.
		ready_cast(id)
		player.last_direction = Vector2.RIGHT
		enemy.position = player.position+Vector2(190,0)
		await physics_frame
		player.use_skill(1)
		player.class_combat.tick(SwordTechniqueTiming.contact(id))
		check(hit_events == 0,"outside unchanged reach")
		ready_cast(id)
		player.last_direction = Vector2.RIGHT
		enemy.position = player.position+Vector2(-65,0)
		await physics_frame
		player.use_skill(1)
		player.class_combat.tick(SwordTechniqueTiming.contact(id))
		check((hit_events == 4) if id == "danca_laminas" else (hit_events == 0),"circular versus frontal hit area")
		# A new defense may take over recovery without adding a global cooldown.
		check(player.use_skill(2),"another technique can replace recovery after contact")
	CombatRules.random_roll_source = Callable()
	await preload("res://tests/local_enemy_feedback_tests.gd").run(self)
	main.queue_free()
	await process_frame
	print("LOCAL_REFINEMENT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
