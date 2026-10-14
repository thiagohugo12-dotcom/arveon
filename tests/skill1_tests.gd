extends "res://tests/bow_demo_tests.gd"
const CATALOGUE := preload("res://scripts/demos/skill1_catalogue.gd")
const SKILL_DEMO := preload("res://scenes/demos/skill1_review.tscn")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SKILL1_FAIL: "+message)
func new_target(player: PlayerActor,offset: Vector2) -> EnemyActor:
	var actor := preload("res://scenes/actors/enemy.tscn").instantiate() as EnemyActor
	actor.set_script(preload("res://scripts/demos/bow_training_target.gd"))
	actor.stats = preload("res://data/actors/player.tres")
	actor.get_node("View").set_script(preload("res://scripts/demos/bow_training_view.gd"))
	actor.position = player.position+offset
	player.get_parent().add_child(actor)
	return actor
func run() -> void:
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var demo = SKILL_DEMO.instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	demo.automatic_skills = false
	for player in demo.players:
		player.set_physics_process(false)
		player.view.set_process(false)
	for fx in demo.ground_effects: fx.set_process(false)
	await frames()
	var before: PlayerActor = demo.players[0]
	var after: PlayerActor = demo.players[1]
	var view = after.view
	var people := VillageActorArt.PEOPLE.get_image()
	for category: String in CATALOGUE.CONFIGS:
		demo.select_category(category)
		for player in demo.players: player.attack.armed = false # Test isolation: no automatic basics.
		var rule := CATALOGUE.rule(category)
		var config: Dictionary = CATALOGUE.CONFIGS[category]
		var atlas: Image = view.skill_texture.get_image()
		check(atlas.get_size() == Vector2i(640,320),category+" 8 frames x 4 directions")
		for row in range(4):
			for col in range(8):
				var clear := true
				for pixel in range(80):
					for edge: Vector2i in [Vector2i(pixel,0),Vector2i(pixel,79),Vector2i(0,pixel),Vector2i(79,pixel)]:
						clear = clear and atlas.get_pixelv(Vector2i(col*80,row*80)+edge).a == 0
				check(clear,"no clipped weapon/trail "+category)
				var head_ok := true
				for y in range(24):
					for x in range(32):
						var original := people.get_pixel(x,row*40+y)
						if original.a < 1: continue
						var baked := atlas.get_pixel(col*80+24+x,row*80+20+y)
						if absf(original.r-baked.r)+absf(original.g-baked.g)+absf(original.b-baked.b) > 0.015 or baked.a < 0.99: head_ok = false
				check(head_ok,"approved head/hair/face "+category)
		check(before.attack.damage_base == after.attack.damage_base and before.attack.weapon.interval == after.attack.weapon.interval,"same real weapon stats "+category)
		for row in range(4):
			demo.select_direction(row)
			for player in demo.players:
				player.attack.armed = false
				player.progress.abilities.skill1_cooldowns[category] = 0 # Fresh controlled fixture.
				player._sync_skill_cooldowns()
				player.last_direction = SwordActorView.DIRECTIONS[row]
			var hp: int = demo.targets[1].health.current
			var before_hp: int = demo.targets[0].health.current
			var casts: int = view.skill1_casts
			check(demo.request_skill1() and view.skill1_phase() == 0,"visual preparation "+category)
			check(after.progress.abilities.skill1_cooldowns[category] == 0 and demo.targets[1].health.current == hp and arrows().is_empty(),"preparation spends/deals/spawns nothing "+category)
			var position_before := after.global_position
			check(before.use_skill(0) and demo.release_skill1(),"original Skill 1 succeeds "+category)
			check(after.global_position == position_before,"Skill 1 never adds artificial movement "+category)
			check(view.skill1_phase() == 1 and view.skill1_row == row and view.skill1_casts == casts+1,"execution uses correct direction "+category)
			check(after.progress.abilities.skill1_cooldowns[category] == float(rule.cooldown),"unmodified real cooldown "+category)
			var projectiles := arrows()
			if AbilityRules.effect(rule.id).shape == "projectile":
				check(projectiles.size() == 2 and demo.targets[1].health.current == hp,"real projectile before delayed impact "+category)
				for shot in projectiles:
					shot.set_physics_process(false)
					check(shot.source == rule.id and shot.category == category and shot.speed == after.attack.weapon.projectile_speed and shot.distance_left == AbilityRules.effect(rule.id).reach,"real projectile specification "+category)
				for shot in projectiles:
					check(shot.global_position == shot.shooter.global_position,"original physical projectile origin "+category)
					if shot.shooter == after:
						check(shot.get_script() == preload("res://scripts/demos/skill1_projectile.gd") and view.skill1_frame() == 3,"special projectile released on execution frame "+category)
				step_arrows(0.05)
				check((projectiles[0].global_position-projectiles[0].shooter.global_position).is_equal_approx(projectiles[1].global_position-projectiles[1].shooter.global_position),"identical actual trajectory "+category)
				for shot in projectiles: check(is_equal_approx(shot.distance_left,float(AbilityRules.effect(rule.id).reach)-shot.speed*0.05),"same real range budget "+category)
				for tick in range(100): step_arrows(0.01)
			else:
				check(demo.targets[1].health.current < hp and projectiles.is_empty(),"original immediate melee damage "+category)
			if category == "machado": check(is_equal_approx(demo.targets[1].control_left,0.25),"original Racha-Chao control duration")
			check(before_hp-demo.targets[0].health.current == hp-demo.targets[1].health.current,"equal resolved damage with/without new presentation "+category)
			var damaged: int = demo.targets[1].health.current
			check(not after.use_skill(0) and view.skill1_casts == casts+1 and demo.targets[1].health.current == damaged,"cooldown prevents duplicate cast/damage "+category)
			view._process(float(config.duration)*0.3)
			check(view.skill1_phase() == 2,"impact phase "+category)
			view._process(float(config.duration)*0.3)
			check(view.skill1_phase() == 3,"recovery phase "+category)
			view._process(1)
			check(view.skill1_phase() == -1,"returns to original idle "+category)
			await frames()
		# Exact existing area inclusion, including the axe's rear-facing disk.
		if AbilityRules.effect(rule.id).shape != "projectile":
			demo.select_direction(3)
			var rear := new_target(after,Vector2(-80,0))
			var side := new_target(after,Vector2(80,40))
			var outside := new_target(after,Vector2(float(AbilityRules.effect(rule.id).reach)+20,0))
			after.progress.abilities.skill1_cooldowns[category] = 0
			after._sync_skill_cooldowns()
			after.last_direction = Vector2.RIGHT
			view.skill1_direction = Vector2.RIGHT
			check(after.use_skill(0),"shape test executes existing rule "+category)
			check(rear.hits == (1 if category == "machado" else 0),"rear inclusion follows original shape "+category)
			check(side.hits == (0 if category == "lanca" else 1),"side inclusion follows original shape "+category)
			check(outside.hits == 0,"original range limit "+category)
			check(demo.ground_effects[1].geometry.shape == AbilityRules.effect(rule.id).shape and demo.ground_effects[1].geometry.reach == AbilityRules.effect(rule.id).reach,"visual geometry uses real rule "+category)
			if category == "lanca":
				var inside := new_target(after,Vector2(80,27))
				var beyond := new_target(after,Vector2(80,29))
				after.progress.abilities.skill1_cooldowns[category] = 0
				after._sync_skill_cooldowns()
				check(after.use_skill(0) and inside.hits == 1 and beyond.hits == 0,"original 28px half-width boundary")
				inside.queue_free()
				beyond.queue_free()
			for actor in [rear,side,outside]: actor.queue_free()
			await frames()
		if category in ["arco","cajado"]:
			# No other skill, Ultimate or basic may be intercepted by Skill 1 art.
			for source: String in ["basic",AbilityRules.CATEGORIES[category].normal[0].id,rule.id]:
				after.attack.projectile_requested.emit(after,demo.targets[1],{"damage":1,"kind":"flecha" if category == "arco" else "orbe","speed":after.attack.weapon.projectile_speed,"reach":100.0,"category":category,"source":source,"ultimate":source==rule.id})
				var shot: PlayerProjectile = arrows()[0]
				check(shot.get_script() != preload("res://scripts/demos/skill1_projectile.gd"),"basic/Skill 2/3/Ultimate retains original drawing "+category)
				shot.finish()
			await frames()
		view.clear_skill1()
		view.set_moving(true)
		view.global_position += Vector2(ActorView.WALK_PIXELS_PER_FRAME,0)
		view._process(0.016)
		var stride: int = view.anim_frame
		after.progress.abilities.skill1_cooldowns[category] = 0
		after._sync_skill_cooldowns()
		view.skill1_direction = Vector2.RIGHT
		check(after.use_skill(0),"casting while walking "+category)
		view._process(0.01)
		check(view.walking and view.anim_frame == stride,"original leg stride preserved "+category)
		view._process(1)
		check(view.walking and view.skill1_phase() == -1,"returns to original walking "+category)
		view.position = Vector2.ZERO
		for index in [1,2]:
			var skill_casts: int = view.skill1_casts
			view.play_skill(index)
			check(view.skill1_casts == skill_casts and view.skill_left > 0,"Skill 2/3/Ultimate generic path unchanged "+category)
		view.clear_skill1()
		after.progress.abilities.skill1_cooldowns[category] = 0
		after._sync_skill_cooldowns()
		demo.request_skill1()
		after.input_driver.blocked = true
		demo._physics_process(0)
		check(view.skill1_phase() == -1 and not after.use_skill(0),"blocked controls cancel pending cast "+category)
		after.input_driver.blocked = false
		for shot in arrows(): shot.finish()
		await frames()
		for player in demo.players:
			check(player.progress.disk_writes == 0 and player.progress.talents.xp[category] == 0,"no saves or proficiency mutations "+category)
		print("SKILL1_CATEGORY_PASS: ",category)
	demo.queue_free()
	await frames()
	CombatRules.random_roll_source = Callable()
	print("SKILL1_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
