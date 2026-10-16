extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
	CombatRules.random_roll_source = func(): return 0.99
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BOW_GAME_FAIL: "+message)
func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame
func run() -> void:
	var save_path := "user://qa_bow_game_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",save_path)
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
	var view := player.view as BowActorView
	check(view != null and view.village_scale,"main scene includes bow presentation")
	main.progress.equipment.arco = 0
	main.progress.equipped.Arma = "arco"
	player.apply_progression(main.progress)
	check(player.attack.weapon.interval == 0.8 and player.attack.weapon.projectile_speed == 440 and player.attack.weapon.reach == 300,"actual bow stats preserved")
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
	check(not centre.is_zero_approx(),"real map has a visible combat patch")
	player.position = centre
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
	for index in range(4):
		view.clear_bow()
		main.enemy.position = centre+SwordActorView.DIRECTIONS[index]*75
		main.enemy.health.initialize(48)
		player.attack.cooldown_left = 0.3
		player.attack.search_left = 0
		player._physics_process(0)
		check(view.bow_phase() == 0 and get_nodes_in_group("player_projectiles").is_empty(),"actual anticipation does not launch arrow")
		player.attack.cooldown_left = 0.08
		player._physics_process(0)
		check(view.bow_phase() == 1 and main.enemy.health.current == 48,"tension before damage")
		player.attack.cooldown_left = 0
		player._physics_process(0)
		var arrows := get_nodes_in_group("player_projectiles")
		check(arrows.size() == 1 and view.bow_phase() == 2 and view.bow_row == index,"one directed release in actual main")
		var arrow := arrows[0] as BowProjectile
		arrow.set_physics_process(false)
		check(arrow != null and arrow.global_position == player.global_position and arrow.visual_offset() == BowActorView.MUZZLES[index],"main uses attached drawing with unchanged physical origin")
		var damage := arrow.damage
		check(main.enemy.health.current == 48,"release does not duplicate immediate damage")
		if not output.is_empty():
			view.queue_redraw()
			await frames()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("bow_game_%d.png" % index))
		arrow._physics_process(0.2)
		check(main.enemy.health.current == 48-damage and arrow.spent,"one real projectile impact")
		arrow._physics_process(0.2)
		check(main.enemy.health.current == 48-damage,"spent projectile cannot hit again")
		view._process(1)
		check(view.bow_phase() == -1,"returns to original idle")
		await frames()
	# Skill/Ultimate projectiles keep their original drawing class.
	for ultimate in [false,true]:
		main._on_player_projectile(player,main.enemy,{"damage":1,"kind":"flecha","speed":440.0,"reach":300.0,"category":"arco","source":"technique","ultimate":ultimate})
		var arrow: PlayerProjectile = get_nodes_in_group("player_projectiles")[0]
		check(not arrow is BowProjectile,"special projectile presentation unchanged")
		arrow.finish()
	await frames()
	view.play_bow_attack(Vector2.RIGHT,0.8)
	main.progress.equipped.Arma = "espada"
	player.apply_progression(main.progress)
	check(view.bow_phase() == -1,"equip sword cancels bow")
	player._on_attack(main.enemy)
	check(view.phase() == 1 and view.sword_time > 0 and view.bow_phase() == -1,"approved sword still independent")
	main.progress.equipped.Arma = "arco"
	player.apply_progression(main.progress)
	check(view.sword_time == 0,"equip bow cancels old sword")
	view.play_bow_attack(Vector2.RIGHT,0.8)
	main.input_driver.blocked = true
	player._physics_process(0)
	check(view.bow_phase() == -1,"modal clears bow")
	main.input_driver.blocked = false
	view.play_bow_attack(Vector2.RIGHT,0.8)
	player.position = SafeCamp.RESPAWN
	player._physics_process(0)
	check(view.bow_phase() == -1,"safe zone clears bow")
	player.position = centre
	view.play_bow_attack(Vector2.RIGHT,0.8)
	view.village_scale = false
	view._process(0)
	check(view.bow_phase() == -1,"legacy floor clears bow")
	view.village_scale = true
	view.play_bow_attack(Vector2.RIGHT,0.8)
	main.progress.equipped.Arma = ""
	player.apply_progression(main.progress)
	check(not player.attack.armed and view.bow_phase() == -1,"unequip disables attack and bow")
	view.play_bow_attack(Vector2.RIGHT,0.8)
	player.health.damage(player.health.maximum)
	check(view.bow_phase() == -1,"death clears bow")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source = Callable()
	print("BOW_GAME_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
