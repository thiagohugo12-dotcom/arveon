extends "res://tests/bow_demo_tests.gd"
const SCENES := [preload("res://scenes/demos/axe_attack_demo.tscn"),preload("res://scenes/demos/spear_attack_demo.tscn")]
const DATA := preload("res://scripts/demos/melee_pose_data.gd")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MELEE_DEMO_FAIL: "+message)
func run() -> void:
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var people := VillageActorArt.PEOPLE.get_image()
	for kind in range(2):
		var category: String = ["machado","lanca"][kind]
		var atlas: Image = preload("res://scripts/demos/melee_review_view.gd").ATLASES[kind].get_image()
		check(atlas.get_size() == Vector2i(640,320),category+" eight poses, four directions")
		for row in range(4):
			for column in range(8):
				var border_clear := true
				for pixel in range(80):
					for edge: Vector2i in [Vector2i(pixel,0),Vector2i(pixel,79),Vector2i(0,pixel),Vector2i(79,pixel)]:
						border_clear = border_clear and atlas.get_pixelv(Vector2i(column*80,row*80)+edge).a == 0
				check(border_clear,"no clipping "+category+" %d,%d" % [row,column])
				var head_preserved := true
				for y in range(24):
					for x in range(32):
						var original := people.get_pixel(x,row*40+y)
						if original.a < 1: continue
						var baked: Color = atlas.get_pixel(column*80+24+x,row*80+20+y)
						if absf(original.r-baked.r)+absf(original.g-baked.g)+absf(original.b-baked.b) > 0.015 or baked.a < 0.99: head_preserved = false
				check(head_preserved,"approved opaque head/face/hair "+category)
				check(DATA.SHOULDERS[row][0].distance_to(DATA.hand(kind,row,column)) <= 12,"compact shoulder-to-hand span "+category)
		var demo = SCENES[kind].instantiate()
		root.add_child(demo)
		demo.set_physics_process(false)
		for player in demo.players:
			player.set_physics_process(false)
			player.view.set_process(false)
		await frames()
		var before: PlayerActor = demo.players[0]
		var after: PlayerActor = demo.players[1]
		var view = after.view
		var profile := ArsenalRules.profile(category)
		check(after.attack.weapon.category == category and after.attack.weapon.interval == profile.interval and after.attack.weapon.reach == profile.reach,"real profile "+category)
		check(after.attack.weapon.projectile_kind.is_empty() and after.attack.damage_type == "physical","original melee type "+category)
		check(before.attack.damage_base == after.attack.damage_base and before.stats.move_speed == after.stats.move_speed,"equal before/after stats "+category)
		for direction in range(4):
			demo.select_direction(direction)
			after.attack.cooldown_left = after.attack.weapon.interval*0.1
			demo._physics_process(0)
			var hits: int = demo.targets[1].hits
			check(view.phase() == 0,"preparation without a hit "+category)
			for player in demo.players:
				player.attack.cooldown_left = 0
				player.attack.search_left = 0
				player._physics_process(0)
			check(view.phase() == 1 and view.attack_row == direction,"directed real swing "+category)
			check(demo.targets[1].hits == hits+1 and demo.targets[0].total_damage == demo.targets[1].total_damage,"one immediate equal damage, no animation delay "+category)
			view._process(view.swing_duration*0.25)
			check(view.phase() == 2,"contact pose "+category)
			view._process(view.swing_duration*0.3)
			check(view.phase() == 3,"recovery pose "+category)
			view._process(1)
			check(view.phase() == -1 and arrows().is_empty(),"idle, never projectile "+category)
		# Weapon-specific silhouette/motion, rather than a reskinned sword swing.
		check(not DATA.AXE_HANDS[3][1].is_equal_approx(DATA.hand(1,3,1)),"different preparation grips")
		check(DATA.axis(1,3,1).is_equal_approx(DATA.axis(1,3,4)) and not DATA.axis(0,3,1).is_equal_approx(DATA.axis(0,3,4)),"linear spear versus angular axe")
		demo.select_direction(3)
		demo.targets[1].enabled = false
		var swings: int = view.swings
		after.attack.cooldown_left = 0
		after.attack.search_left = 0
		demo._physics_process(0)
		after._physics_process(0)
		check(view.swings == swings and not view.melee_preparing,"no phantom hit without target "+category)
		demo.targets[1].enabled = true
		demo.targets[1].position = after.position+Vector2.RIGHT*(profile.reach+30)
		after.attack.search_left = 0
		after._physics_process(0)
		check(view.swings == swings,"original range limit "+category)
		demo.select_direction(3)
		var blocker := StaticBody2D.new()
		blocker.position = after.position+Vector2(30,0)
		blocker.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(6,60)
		shape.shape = rectangle
		blocker.add_child(shape)
		after.get_parent().add_child(blocker)
		await frames()
		after.attack.cooldown_left = 0
		after.attack.search_left = 0
		after._physics_process(0)
		check(view.swings == swings,"wall prevents melee through scenery "+category)
		blocker.queue_free()
		await frames()
		view.set_moving(true)
		view.global_position += Vector2(ActorView.WALK_PIXELS_PER_FRAME,0)
		view._process(0.016)
		var stride: int = view.anim_frame
		view.play_melee(Vector2.RIGHT,profile.interval)
		view._process(0.01)
		check(view.walking and view.anim_frame == stride,"original gait retained "+category)
		view._process(1)
		check(view.walking and view.phase() == -1,"returns to walking "+category)
		view.position = Vector2.ZERO
		var base_duration := 0.0
		for dex in [0,20]:
			if demo.dexterity != dex: demo._toggle_dex()
			demo.select_direction(3)
			var hits: int = demo.targets[1].hits
			swings = view.swings
			for tick in range(500):
				demo._physics_process(0.01)
				for player in demo.players: player._physics_process(0.01)
				view._process(0.01)
			check(demo.targets[1].hits-hits == view.swings-swings,"consecutive hits occur once per actual swing "+category)
			check(demo.targets[0].total_damage == demo.targets[1].total_damage,"same consecutive damage "+category)
			check(view.swing_duration < after.attack.weapon.interval and before.attack.weapon.interval == after.attack.weapon.interval,"recovery fits actual cadence "+category)
			if dex == 0: base_duration = view.swing_duration
			else: check(view.swing_duration < base_duration,"Dex scales animation with combat "+category)
		view.play_melee(Vector2.RIGHT,profile.interval)
		after.input_driver.blocked = true
		demo._physics_process(0)
		check(view.phase() == -1,"modal clears pending pose "+category)
		after.input_driver.blocked = false
		view.play_melee(Vector2.RIGHT,profile.interval)
		after.progress.equipped.Arma = "espada"
		after.apply_progression(after.progress)
		demo._physics_process(0)
		check(view.phase() == -1,"weapon change clears pose "+category)
		view.play_melee(Vector2.RIGHT,profile.interval)
		after.health.damage(after.health.maximum)
		check(view.phase() == -1,"death clears pose "+category)
		for player in demo.players:
			check(player.progress.disk_writes == 0 and player.progress.talents.xp[category] == 0,"no save writes or proficiency receipt "+category)
			check((player.get_node("Collision").shape as CircleShape2D).radius == 13,"original collision "+category)
		demo.queue_free()
		await frames()
	CombatRules.random_roll_source = Callable()
	print("MELEE_DEMO_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
