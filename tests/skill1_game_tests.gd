extends "res://tests/staff_game_tests.gd"
const CATALOGUE := preload("res://scripts/demos/skill1_catalogue.gd")
var releases := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SKILL1_GAME_FAIL: "+message)
func capture(label: String) -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if output.is_empty(): return
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	var save_path := "user://qa_skill1_game_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main = preload("res://scenes/main.tscn").instantiate()
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
	var view := player.view as Skill1GameView
	check(view != null and view.village_scale,"runtime uses approved presentation")
	view.ground_effect.set_process(false)
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
	check(not centre.is_zero_approx(),"clear real-map combat patch")
	player.position = centre
	main.enemy.health.initialize(1000000)
	main.enemy._proficiency_budget = -1
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
	player.skill_used.connect(func(index):
		if index == 0: releases += 1)
	for category: String in CATALOGUE.ORDER:
		main.progress.equipment[category] = 0
		main.progress.equipped.Arma = category
		player.apply_progression(main.progress)
		var rule := CATALOGUE.rule(category)
		for row in range(4):
			view.ground_effect.clear()
			var aim: Vector2 = SwordActorView.DIRECTIONS[row]
			player.position = centre
			player.last_direction = aim
			view.set_facing(aim)
			view.set_moving(false)
			main.enemy.position = centre+aim*75
			main.enemy.health.current = 1000000
			player.progress.abilities.skill1_cooldowns[category] = 0
			player._sync_skill_cooldowns()
			player.attack.cooldown_left = 100
			player.class_combat.use(0)
			for shot in get_nodes_in_group("player_projectiles"):
				shot.set_physics_process(false)
				shot._physics_process(75/shot.speed)
			var expected_damage: int = 1000000-main.enemy.health.current
			main.enemy.health.current = 1000000
			player.progress.abilities.skill1_cooldowns[category] = 0
			player._sync_skill_cooldowns()
			view.clear_skill1()
			main.enemy.view.flash_left = 0
			main.enemy.view.impact_left = 0
			main.enemy.view.damage_left = 0
			main.enemy.view.previous_damage_left = 0
			for child in main.enemy.view.get_children():
				if child.get_script() == preload("res://scripts/presentation/skill1_game_impact.gd"):
					child.remaining = 0
			await frames()
			var hp: int = main.enemy.health.current
			var count := releases
			var casts := view.skill1_casts
			check(player.use_skill(0),"accept startup "+category)
			check(not player.use_skill(0),"reject repeated input "+category)
			check(not player.skill_ready(0) and view.skill1_frame() == 0,"HUD pending and preparation frame "+category)
			check(main.enemy.health.current == hp and get_nodes_in_group("player_projectiles").is_empty() and player.progress.abilities.skill1_cooldowns[category] == 0,"startup has no damage, projectile or persistent cooldown "+category)
			player._tick_skill1(float(view.skill_config.prepare)*0.65)
			check(view.skill1_frame() == 1 and releases == count,"visible preparation before commit "+category)
			await capture("%s_%d_prepare" % [category,row])
			player._tick_skill1(1)
			check(releases == count+1 and view.skill1_casts == casts+1 and view.skill1_frame() == 3 and view.skill1_row == row,"single correctly directed execution "+category)
			check(is_equal_approx(player.progress.abilities.skill1_cooldowns[category],float(rule.cooldown)),"unchanged cooldown starts at release "+category)
			var shots := get_nodes_in_group("player_projectiles")
			if category in ["arco","cajado"]:
				check(shots.size() == 1 and shots[0] is Skill1GameProjectile,"real special projectile factory "+category)
				if shots.size() == 1:
					var shot = shots[0]
					shot.set_physics_process(false)
					check(shot.source == rule.id and shot.direction.dot(aim) > 0.99 and shot.speed == player.attack.weapon.projectile_speed and shot.distance_left == AbilityRules.effect(rule.id).reach,"source, direction, speed and range unchanged "+category)
					check(shot.visual_start == preload("res://scripts/demos/skill1_body_pose.gd").muzzle(category,row),"approved release muzzle "+category)
					await capture("%s_%d_release" % [category,row])
					shot._physics_process(75/shot.speed)
			else:
				check(shots.is_empty(),"melee has no phantom projectiles "+category)
				await capture("%s_%d_release" % [category,row])
			check(hp-main.enemy.health.current == expected_damage and expected_damage > 0,"identical original damage after startup "+category)
			var after_hit: int = main.enemy.health.current
			player._tick_skill1(1)
			check(releases == count+1 and main.enemy.health.current == after_hit,"no duplicate execution or damage "+category)
			view._process(float(view.skill_config.duration)*0.25)
			view.ground_effect._process(float(view.skill_config.duration)*0.25)
			check(view.skill1_frame() == 4,"actual impact atlas frame "+category)
			await capture("%s_%d_impact" % [category,row])
			view._process(1)
			check(view.skill1_phase() == -1,"returns to original idle "+category)
			await frames()
		# Walking remains physical movement, with the approved upper atlas.
		player.progress.abilities.skill1_cooldowns[category] = 0
		player._sync_skill_cooldowns()
		player.use_skill(0)
		main.input_driver.touch_direction = Vector2.RIGHT
		var before := player.position
		player._physics_process(0.02)
		check(player.position.x > before.x and view.walking and player.skill1_pending > 0,"walking throughout startup "+category)
		main.input_driver.touch_direction = Vector2.ZERO
		main.input_driver.blocked = true
		player._physics_process(0)
		check(player.skill1_pending == 0 and view.skill1_phase() == -1 and player.progress.abilities.skill1_cooldowns[category] == 0,"modal cancels without spending cooldown "+category)
		main.input_driver.blocked = false
		player._sync_skill_cooldowns()
		player.use_skill(0)
		player.position = SafeCamp.RESPAWN
		player._tick_skill1(1)
		check(player.skill1_pending == 0 and player.progress.abilities.skill1_cooldowns[category] == 0,"camp cancels startup "+category)
		player.position = centre
		player._sync_skill_cooldowns()
		player.use_skill(0)
		main.progress.equipped.Arma = ""
		player.apply_progression(main.progress)
		check(player.skill1_pending == 0 and view.skill1_phase() == -1,"unequip clears pending cast "+category)
	main.progress.equipped.Arma = "arco"
	player.apply_progression(main.progress)
	player.progress.abilities.skill1_cooldowns.arco = 0
	player._sync_skill_cooldowns()
	player.use_skill(0)
	var blockers: Array[Node] = []
	for i in range(PlayerProjectile.MAX_ACTIVE):
		var shot := PlayerProjectile.new()
		main.add_child(shot)
		shot.set_physics_process(false)
		blockers.append(shot)
	var count := releases
	player._tick_skill1(1)
	check(releases == count and player.progress.abilities.skill1_cooldowns.arco == 0 and view.skill1_phase() == -1,"full projectile budget rejects commit without spending cooldown")
	player._sync_skill_cooldowns()
	check(not player.use_skill(0),"full budget rejects startup")
	for shot in blockers: shot.finish()
	await frames()
	view.village_scale = false
	player._sync_skill_cooldowns()
	check(player.use_skill(0) and player.skill1_pending == 0 and view.skill_left > 0,"legacy retains immediate combat and original skill effect")
	for shot in get_nodes_in_group("player_projectiles"): shot.finish()
	view.village_scale = true
	preload("res://tests/etapa2_fixtures.gd").unlock(main.progress,"arco",8)
	player.apply_progression(main.progress)
	check(player.use_skill(1) and player.skill1_pending == 0,"Skill 2 uses original immediate path")
	for shot in get_nodes_in_group("player_projectiles"): shot.finish()
	check(player.use_skill(2) and player.skill1_pending == 0,"Skill 3 uses original immediate path")
	for shot in get_nodes_in_group("player_projectiles"): shot.finish()
	player.progress.abilities.skill1_cooldowns.arco = 0
	player._sync_skill_cooldowns()
	player.use_skill(0)
	player.health.damage(player.health.maximum)
	check(player.skill1_pending == 0 and view.skill1_phase() == -1,"death cancels startup immediately")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source = Callable()
	print("SKILL1_GAME_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
