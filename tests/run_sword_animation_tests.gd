extends "res://tests/local_combat_refinement_tests.gd"
## Bounded live-player tests. No enemy-AI suite or production save.
func run() -> void:
	var save_path := "user://run_sword_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	main = preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in range(4): await process_frame
	main._start_training()
	main.set_process(false)
	player=main.player
	enemy=main.enemy
	player.set_physics_process(false)
	player.view.set_process(false)
	enemy.set_physics_process(false)
	player.input_driver.blocked=false
	player.view.sword_technique.set_process(false)
	enemy.health.changed.connect(func(_hp: int,_max: int): hit_events+=1)
	player.class_combat.technique_impact.connect(func(_id: String,_time: float): impact_events+=1)
	CombatRules.random_roll_source=func(): return 0.99
	var speed := player.stats.move_speed
	var dash_speed := player.stats.dash_speed
	var origin := player.position
	var writes: int = main.progress.disk_writes
	for aim in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT,Vector2(1,1).normalized(),Vector2(-1,-1).normalized(),Vector2(-1,1).normalized(),Vector2(1,-1).normalized()]:
		player.input_driver.touch_direction=aim
		player.attack.cooldown_left=100
		player._physics_process(1.0/60.0)
		check(player.velocity.is_equal_approx(aim*speed),"unchanged cardinal/diagonal velocity")
		check(player.view.walking and player.view._explorer_direction()==SwordActorView.direction_row(aim),"running direction")
		player.view._process(1.0/60.0)
		var phase := player.view.run_distance
		player.view._process(1.0)
		check(is_equal_approx(phase,player.view.run_distance),"stationary transform cannot advance stride")
	player.input_driver.touch_direction=Vector2.ZERO
	player._physics_process(0)
	check(not player.view.walking,"release returns to idle")
	player.input_driver.touch_direction=Vector2(0.5,0)
	player._physics_process(0)
	check(player.view.walking and not player.view.running and is_equal_approx(player.velocity.length(),speed*0.5),"partial analog keeps walk visual and existing speed")
	player.input_driver.touch_direction=Vector2.RIGHT
	player._physics_process(0)
	check(player.view.running and is_equal_approx(player.velocity.length(),speed),"full analog selects run visual")
	player.input_driver.touch_direction=Vector2.RIGHT
	player.input_driver.request_dash()
	player._physics_process(0)
	check(player.dash.active() and is_equal_approx(player.velocity.length(),dash_speed),"dash preserves speed")
	player.dash.time_left=0
	player.input_driver.reset()
	player.position=origin
	for id: String in SwordTechniqueTiming.FRAMES:
		for aim in SwordActorView.DIRECTIONS:
			ready_cast(id)
			player.last_direction=aim
			enemy.position=player.position+aim*65
			await physics_frame
			check(player.use_skill(1),id+" starts")
			player.class_combat.tick(SwordTechniqueTiming.contact(id)-0.001)
			check(hit_events==0,"no damage before contact")
			player.input_driver.blocked=true
			var held := player.class_combat.technique_elapsed
			player._physics_process(0.2)
			check(player.class_combat.technique_elapsed==held and hit_events==0,"menu pauses contact")
			player.input_driver.blocked=false
			player.class_combat.tick(0.001)
			check(hit_events==(4 if id=="danca_laminas" else 1) and impact_events==1,"exact configured hits")
			check(player.view.sword_technique._frame()==SwordTechniqueTiming.CONTACT_FRAME,"pose shares damage clock")
			check(player.view.sword_pose_row==SwordActorView.direction_row(aim),"pose orientation")
			player.class_combat.tick(1)
			check(player.class_combat.technique.is_empty() and impact_events==1,"no duplicate contact")
			player.input_driver.touch_direction=aim
			player._physics_process(0)
			check(player.view.walking,"skill returns to running")
			player.input_driver.reset()
		ready_cast(id)
		player.use_skill(1)
		main.progress.equipped.Arma="arco"
		player.apply_progression(main.progress)
		player.class_combat.tick(1)
		check(hit_events==0 and player.view.sword_technique.remaining==0,"weapon cancels technique")
		main.progress.equipped.Arma="espada"
		ready_cast(id)
		player.use_skill(1)
		player._on_died()
		player.class_combat.tick(1)
		check(hit_events==0 and player.view.sword_technique.remaining==0,"death cancels technique")
	ready_cast("guarda_reativa")
	player.use_skill(1)
	var guard: SwordTechniqueEffect=player.view.sword_technique
	guard._process(0.2)
	check(guard._frame()==2 and guard.counter_elapsed<0,"no counter without received attack")
	var hp := player.health.current
	player.receive_damage(10)
	check(guard.counter_elapsed==0 and player.health.current<hp,"damage triggers block reaction")
	guard._process(0.23)
	check(guard._frame()==2,"counter recovers into guard")
	check(main.progress.disk_writes==writes,"temporary progress never saved")
	check(player.stats.move_speed==speed and player.stats.dash_speed==dash_speed,"unchanged movement statistics")
	preload("res://tests/sword_technique_timing_tests.gd").run(self)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source=Callable()
	print("RUN_SWORD_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
