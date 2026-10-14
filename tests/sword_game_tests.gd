extends SceneTree
## Integration against the actual main scene, isolated from the player's save.
var checks := 0
var failures := 0

func _initialize() -> void:
	CombatRules.random_roll_source = func(): return 0.99
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("SWORD_GAME_FAIL: "+message)

func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame

func run() -> void:
	var save_path := "user://qa_sword_game_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	var player: PlayerActor = main.player
	player.set_physics_process(false)
	player.view.set_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
		if actor != main.enemy: actor.queue_free()
	main.enemy.target = null
	await frames()
	check(player.view is SwordActorView and player.view.village_scale,"main scene uses approved sword presentation")
	var view := player.view as SwordActorView
	var output := OS.get_environment("QA_RENDER_DIR")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	player.get_node("Camera2D").position_smoothing_enabled = false
	var scenery: FloorView = main.get_node("Andar1/FloorView")
	var centre := Vector2.ZERO
	for y in range(300,760,20):
		for x in range(860,1120,20):
			var point := Vector2(x,y)
			var clear := true
			for direction: Vector2 in SwordActorView.DIRECTIONS:
				var ray := PhysicsRayQueryParameters2D.create(point,point+direction*75.0,1)
				clear = clear and player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
			for feet: Vector2 in scenery.v2_view.visible_tree_positions():
				var canopy := Rect2(feet-Vector2(56,122),Vector2(112,128)).grow(20.0)
				clear = clear and not canopy.has_point(point-Vector2(0,30))
			if clear and centre.is_zero_approx(): centre = point
	check(not centre.is_zero_approx(),"real map has unobstructed combat patch")
	var writes: int = main.progress.disk_writes
	player.position = centre
	if not output.is_empty():
		# Inspection camera only: center the eastern map-edge patch clear of the HUD.
		var camera := player.get_node("Camera2D") as Camera2D
		camera.limit_left = -10000
		camera.limit_top = -10000
		camera.limit_right = 10000
		camera.limit_bottom = 10000
		camera.force_update_scroll()
	for index in range(4):
		view.clear_sword()
		main.enemy.position = centre+SwordActorView.DIRECTIONS[index]*75.0
		main.enemy.health.initialize(48)
		player.attack.cooldown_left = 0.04
		player.attack.search_left = 0.0
		player._physics_process(0.01)
		check(view.preparing and main.enemy.health.current == 48,"preparation does not alter real damage %d" % index)
		player.attack.cooldown_left = 0.0
		player._physics_process(0.0)
		check(view.sword_row == index and view.phase() == 1,"real attack chooses direction %d" % index)
		check(main.enemy.health.current == 36,"real sword applies exactly one unchanged hit %d" % index)
		check(view.attack_left == 0.0,"no duplicate generic slash %d" % index)
		if not output.is_empty():
			view._process(0.08)
			view.queue_redraw()
			await frames()
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(output.path_join("sword_game_%d.png" % index)) == OK,"real gameplay frame rendered")
		view._process(1.0)
		check(view.phase() == -1,"recovery returns to normal body %d" % index)
	# Actual skill alongside sword: shared ActorView overlays must remain active.
	preload("res://tests/etapa2_fixtures.gd").reset(player)
	main.enemy.health.initialize(48)
	player.attack.cooldown_left = 0.0
	player._physics_process(0.0)
	check(player.use_skill(0),"class skill remains usable during sword swing")
	check(view.sword_time > 0.0 and view.skill_left > 0.0,"sword and skill presentation coexist")
	view.flash()
	view.set_fury(true)
	view.queue_redraw()
	await frames()
	check(view.flash_left > 0.0 and view.fury,"hit flash and fury coexist with sword")
	for category: String in ["machado","lanca","arco","cajado"]:
		view.play_sword_attack(Vector2.DOWN,0.65)
		main.progress.equipment[category] = 0
		main.progress.equipped.Arma = category
		player.apply_progression(main.progress)
		check(view.phase() == -1,"equip cancels stale sword for "+category)
		var swings := view.sword_attacks
		player._on_attack(main.enemy)
		if category == "arco" and view is BowActorView:
			check(view.sword_attacks == swings and (view as BowActorView).bow_phase() == 2,"bow animation stays independent of sword")
		elif category == "cajado" and view is StaffActorView:
			check(view.sword_attacks == swings and (view as StaffActorView).staff_phase() == 2,"staff animation stays independent of sword")
		elif category in ["machado","lanca"] and view is MeleeActorView:
			check(view.sword_attacks == swings and (view as MeleeActorView).melee_phase() == 1,"approved melee animation stays independent of sword "+category)
		else:
			check(view.sword_attacks == swings and view.attack_left > 0.0,"other weapon retains original visual "+category)
	main.progress.equipped.Arma = ""
	player.apply_progression(main.progress)
	check(not player.attack.armed and view.phase() == -1 and view.attack_left == 0.0,"unequip clears sword and disables combat")
	main.progress.equipped.Arma = "espada"
	player.apply_progression(main.progress)
	view.play_sword_attack(Vector2.DOWN,0.65)
	main.input_driver.blocked = true
	player._physics_process(0.0)
	check(view.phase() == -1,"modal cancels sword")
	main.input_driver.blocked = false
	view.play_sword_attack(Vector2.DOWN,0.65)
	player.position = SafeCamp.RESPAWN
	player._physics_process(0.0)
	check(view.phase() == -1,"safe camp cancels sword")
	player.position = centre
	view.play_sword_attack(Vector2.DOWN,0.65)
	view.village_scale = false
	view._process(0.0)
	check(view.phase() == -1,"legacy floor clears village sword")
	player._on_attack(main.enemy)
	check(view.phase() == -1 and view.attack_left > 0.0,"legacy explorer keeps original strike")
	view.village_scale = true
	view.play_sword_attack(Vector2.DOWN,0.65)
	player.health.damage(player.health.maximum)
	check(view.phase() == -1,"death clears pending sword pose")
	# The normal main death handler may save; presentation itself never does.
	check(main.progress.disk_writes == writes+1,"only existing death save writes, animation never persists")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source = Callable()
	print("SWORD_GAME_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
