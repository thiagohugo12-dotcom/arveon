extends "res://tests/staff_game_tests.gd"
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MELEE_GAME_FAIL: "+message)
func run() -> void:
	var save_path := "user://qa_melee_game_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := preload("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	var player: PlayerActor = main.player
	player.set_physics_process(false)
	player.view.set_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"):
		enemy.set_physics_process(false)
		if enemy != main.enemy: enemy.queue_free()
	main.enemy.target = null
	await frames()
	var view := player.view as MeleeActorView
	check(view != null and view.village_scale,"main includes shared approved melee presentation")
	var centre := Vector2.ZERO
	var scenery: FloorView = main.get_node("Andar1/FloorView")
	for y in range(300,760,20):
		for x in range(860,1120,20):
			var point := Vector2(x,y)
			var clear := true
			for direction: Vector2 in SwordActorView.DIRECTIONS:
				var ray := PhysicsRayQueryParameters2D.create(point,point+direction*75,1)
				clear = clear and player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
			for feet: Vector2 in scenery.v2_view.visible_tree_positions():
				clear = clear and not Rect2(feet-Vector2(56,122),Vector2(112,128)).grow(20).has_point(point-Vector2(0,30))
			if clear and centre.is_zero_approx(): centre = point
	check(not centre.is_zero_approx(),"visible combat patch in the actual map")
	player.position = centre
	main.enemy.health.initialize(1000000)
	main.enemy._proficiency_budget = -1 # Fresh training life; enough budget for both categories.
	var output := OS.get_environment("QA_RENDER_DIR")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		var camera := player.get_node("Camera2D") as Camera2D
		camera.position_smoothing_enabled = false
		camera.limit_left = -10000
		camera.limit_top = -10000
		camera.limit_right = 10000
		camera.limit_bottom = 10000
		camera.force_update_scroll()
	main.progress.equipment.machado = 0
	main.progress.equipment.lanca = 0
	for category: String in ["machado","lanca"]:
		var kind := 0 if category == "machado" else 1
		var profile := ArsenalRules.profile(category)
		main.progress.equipment[category] = 0
		main.progress.equipped.Arma = category
		player.apply_progression(main.progress)
		check(view.weapon_kind == kind and player.attack.damage_type == "physical","correct equipped atlas/type "+category)
		check(player.attack.weapon.interval == profile.interval and player.attack.weapon.reach == profile.reach and player.attack.weapon.projectile_kind.is_empty(),"unchanged real melee profile "+category)
		for index in range(4):
			view.clear_melee()
			main.enemy.position = centre+SwordActorView.DIRECTIONS[index]*75
			var hp: int = main.enemy.health.current
			var xp: int = main.progress.talents.xp[category]
			player.attack.cooldown_left = player.attack.weapon.interval*0.1
			player.attack.search_left = 0
			player._physics_process(0)
			check(view.melee_phase() == 0 and main.enemy.health.current == hp,"preparation without damage "+category)
			player.attack.cooldown_left = 0
			var swings := view.swings
			player._physics_process(0)
			check(view.melee_phase() == 1 and view.attack_row == index and view.swings == swings+1,"one correctly directed real strike "+category)
			check(main.enemy.health.current < hp and get_nodes_in_group("player_projectiles").is_empty(),"original immediate damage, no phantom projectile "+category)
			check(main.progress.talents.xp[category] > xp,"real proficiency receipt still credited "+category)
			var after_hit: int = main.enemy.health.current
			player._physics_process(0)
			check(main.enemy.health.current == after_hit and view.swings == swings+1,"cooldown prevents duplicate hit/animation "+category)
			view._process(view.swing_duration*0.25)
			check(view.melee_phase() == 2,"contact pose in actual map "+category)
			if not output.is_empty():
				view.queue_redraw()
				await frames()
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("%s_game_%d.png" % [category,index]))
			view._process(view.swing_duration*0.3)
			check(view.melee_phase() == 3,"recovery in actual map "+category)
			view._process(1)
			check(view.melee_phase() == -1,"returns to original idle "+category)
		view.set_moving(true)
		view.global_position += Vector2(ActorView.WALK_PIXELS_PER_FRAME,0)
		view._process(0.016)
		var stride: int = view.anim_frame
		view.play_melee(Vector2.RIGHT,profile.interval)
		view._process(0.01)
		check(view.walking and view.anim_frame == stride,"original walk stride during attack "+category)
		view._process(1)
		check(view.walking and view.melee_phase() == -1,"recovery resumes original walk "+category)
		view.position = Vector2.ZERO
		# Changing Dex uses the original interval modifier; only the pose duration follows.
		main.progress.attributes.Destreza = 20
		player.apply_progression(main.progress)
		player.attack.cooldown_left = 0
		player.attack.search_left = 0
		player._physics_process(0)
		check(player.attack.weapon.interval < profile.interval and is_equal_approx(view.swing_duration,player.attack.weapon.interval*(0.42 if kind == 0 else 0.34)),"Dex-adjusted real cadence/timing "+category)
		main.progress.attributes.Destreza = 0
		player.apply_progression(main.progress)
		view.play_melee(Vector2.RIGHT,profile.interval)
		main.input_driver.blocked = true
		player._physics_process(0)
		check(view.melee_phase() == -1,"modal clears pose "+category)
		main.input_driver.blocked = false
		view.play_melee(Vector2.RIGHT,profile.interval)
		player.position = SafeCamp.RESPAWN
		player._physics_process(0)
		check(view.melee_phase() == -1,"safe camp clears pose "+category)
		player.position = centre
		view.play_melee(Vector2.RIGHT,profile.interval)
		view.village_scale = false
		view._process(0)
		check(view.melee_phase() == -1,"legacy floors keep original presentation "+category)
		view.village_scale = true
		view.play_melee(Vector2.RIGHT,profile.interval)
		main.progress.equipped.Arma = "lanca" if category == "machado" else "machado"
		player.apply_progression(main.progress)
		check(view.melee_phase() == -1 and view.weapon_kind != kind,"axe/spear switch clears the old pose")
		main.progress.equipped.Arma = category
		player.apply_progression(main.progress)
		view.play_melee(Vector2.RIGHT,profile.interval)
		main.progress.equipped.Arma = ""
		player.apply_progression(main.progress)
		check(view.melee_phase() == -1 and not player.attack.armed,"unequip disables melee "+category)
	# The three previously approved weapons still route to independent states.
	for category: String in ["espada","arco","cajado"]:
		main.progress.equipment[category] = 0
		main.progress.equipped.Arma = category
		player.apply_progression(main.progress)
		player._on_attack(main.enemy)
		check(view.melee_phase() == -1,"approved weapon cannot use axe/spear pose "+category)
		check(view.sword_time > 0 if category == "espada" else view.bow_time > 0 if category == "arco" else view.staff_time > 0,"approved weapon remains active "+category)
	main.progress.equipped.Arma = "machado"
	player.apply_progression(main.progress)
	view.play_melee(Vector2.RIGHT,0.9)
	player.health.damage(player.health.maximum)
	check(view.melee_phase() == -1,"death clears melee immediately")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source = Callable()
	print("MELEE_GAME_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
