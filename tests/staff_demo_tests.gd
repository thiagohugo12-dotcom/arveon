extends "res://tests/bow_demo_tests.gd"
## Reuse assertion/frame/projectile stepping helpers with a different review scene.
const STAFF_DEMO := preload("res://scenes/demos/staff_attack_demo.tscn")
const DATA := preload("res://scripts/demos/staff_pose_data.gd")
const STAFF_ORB := preload("res://scripts/demos/staff_demo_projectile.gd")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STAFF_DEMO_FAIL: "+message)
func run() -> void:
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var atlas := preload("res://assets/art/staff_demo_v1/attack.png").get_image()
	var people := VillageActorArt.PEOPLE.get_image()
	check(atlas.get_size() == Vector2i(640,320),"eight aligned source-grid poses in four directions")
	for row in range(4):
		for col in range(8):
			var clear := true
			for pixel in range(80):
				for edge: Vector2i in [Vector2i(pixel,0),Vector2i(pixel,79),Vector2i(0,pixel),Vector2i(79,pixel)]:
					clear = clear and atlas.get_pixelv(Vector2i(col*80,row*80)+edge).a == 0
			check(clear,"no clipped staff/gem/arms %d,%d" % [row,col])
			var head_identical := true
			for y in range(24):
				for x in range(32):
					var original := people.get_pixel(x,row*40+y)
					if original.a < 1.0: continue # Only fully opaque pixels can match after alpha compositing.
					var baked := atlas.get_pixel(col*80+24+x,row*80+20+y)
					if absf(original.r-baked.r)+absf(original.g-baked.g)+absf(original.b-baked.b) > 0.015 or baked.a < 0.99: head_identical = false
			check(head_identical,"approved head/hair/face pixels preserved %d,%d" % [row,col])
			var shoulder: Vector2 = DATA.SHOULDERS[row][0]
			var free_shoulder: Vector2 = DATA.SHOULDERS[row][1]
			check(shoulder.distance_to(DATA.HANDS[row][col]) <= 10 and free_shoulder.distance_to(DATA.FREE_HANDS[row][col]) <= 7,"compact arm proportions %d,%d" % [row,col])
	var demo := STAFF_DEMO.instantiate()
	root.add_child(demo)
	demo.set_physics_process(false)
	for p in demo.players:
		p.set_physics_process(false)
		p.view.set_process(false)
	await frames()
	var before: PlayerActor = demo.players[0]
	var after: PlayerActor = demo.players[1]
	var view = after.view
	check(after.attack.weapon.category == "cajado" and after.attack.weapon.interval == 0.95,"real staff profile and cadence")
	check(after.attack.damage_type == "magical" and after.attack.weapon.reach == 260 and after.attack.weapon.projectile_speed == 260,"magical damage, range and speed preserved")
	check(after.attack.damage_base == before.attack.damage_base and after.stats.move_speed == before.stats.move_speed,"before/after same combat and movement stats")
	for index in range(4):
		demo.select_direction(index)
		await frames()
		var hits: int = demo.targets[1].hits
		after.attack.cooldown_left = 0.35
		demo._physics_process(0)
		check(view.phase() == 0 and arrows().is_empty(),"preparation never emits an orb")
		after.attack.cooldown_left = 0.05
		demo._physics_process(0)
		check(view.phase() == 1 and demo.targets[1].hits == hits,"channeling never damages")
		for p in demo.players:
			p.attack.cooldown_left = 0
			p.attack.search_left = 0
			p._physics_process(0)
		check(view.phase() == 2 and view.staff_row == index and arrows().size() == 2,"one simultaneous pose/projectile per actual release")
		for orb in arrows():
			orb.set_physics_process(false)
			check(orb.position == orb.shooter.position and orb.speed == 260 and orb.distance_left == 260 and orb.kind == "orbe" and orb.damage_type == "magical","unchanged physical shot specification")
			if orb.get_script() == STAFF_ORB: check(orb.visual_offset() == DATA.muzzle(index) and view.frame_index() == 4,"visual orb originates at release-pose staff tip")
		check(demo.targets[1].hits == hits,"release adds no immediate or duplicate damage")
		step_arrows(0.1)
		check(demo.targets[1].hits == hits,"orb travels before impact")
		for orb in arrows(): check(is_equal_approx(orb.distance_left,234),"same travelled distance and reach budget")
		view._process(view.staff_duration*0.4)
		check(view.phase() == 3,"recovery follows release")
		for i in range(70): step_arrows(0.01)
		check(demo.targets[1].hits == hits+1 and demo.targets[0].total_damage == demo.targets[1].total_damage,"exactly one equal magical impact per shot")
		view._process(1)
		check(view.phase() == -1,"recovery returns to original idle")
		await frames()
	# Homing remains the original physical path even when the target moves.
	demo.select_direction(3)
	for p in demo.players:
		p.attack.cooldown_left = 0
		p.attack.search_left = 0
		p._physics_process(0)
	for orb in arrows(): orb.set_physics_process(false)
	for target in demo.targets: target.position += Vector2(0,40)
	step_arrows(0.1)
	var active := arrows()
	check(active.size() == 2 and active[0].direction.y > 0 and active[1].direction.y > 0,"both real orbs steer toward a moving target")
	check(active[0].direction.is_equal_approx(active[1].direction),"presentation does not alter homing angle")
	check((active[0].position-demo.origins[0]).is_equal_approx(active[1].position-demo.origins[1]),"same physical homing trajectory")
	for i in range(100): step_arrows(0.01)
	check(demo.targets[0].total_damage == demo.targets[1].total_damage,"moving target receives unchanged damage")
	await frames()
	demo.select_direction(3)
	demo.targets[1].enabled = false
	var shots: int = view.staff_attacks
	after.attack.cooldown_left = 0
	after.attack.search_left = 0
	demo._physics_process(0)
	after._physics_process(0)
	check(view.staff_attacks == shots and not view.channeling and arrows().is_empty(),"no phantom preparation or shot without target")
	demo.targets[1].enabled = true
	demo.targets[1].position = after.position+Vector2(280,0)
	after.attack.search_left = 0
	after._physics_process(0)
	check(view.staff_attacks == shots and arrows().is_empty(),"original range limit retained")
	demo.select_direction(3)
	var blocker := StaticBody2D.new()
	blocker.position = after.position+Vector2(80,0)
	blocker.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8,60)
	shape.shape = rectangle
	blocker.add_child(shape)
	after.get_parent().add_child(blocker)
	await frames()
	after.attack.cooldown_left = 0
	after.attack.search_left = 0
	shots = view.staff_attacks
	after._physics_process(0)
	check(view.staff_attacks == shots and arrows().is_empty(),"wall blocks target selection before release")
	blocker.queue_free()
	await frames()
	after.attack.search_left = 0
	after._physics_process(0)
	var target_hits: int = demo.targets[1].hits
	blocker = StaticBody2D.new()
	blocker.position = after.position+Vector2(80,0)
	blocker.collision_layer = 1
	shape = CollisionShape2D.new()
	shape.shape = rectangle
	blocker.add_child(shape)
	after.get_parent().add_child(blocker)
	for arrow in arrows(): arrow.set_physics_process(false)
	await frames()
	step_arrows(0.4)
	check(arrows().is_empty() and demo.targets[1].hits == target_hits,"actual projectile hits new wall without damaging target")
	blocker.queue_free()
	await frames()
	view.set_moving(true)
	view.global_position += Vector2(ActorView.WALK_PIXELS_PER_FRAME,0)
	view._process(0.016)
	var stride: int = view.anim_frame
	view.play_staff_attack(Vector2.RIGHT,0.95)
	view._process(0.01)
	check(view.walking and view.anim_frame == stride,"casting preserves distance-based leg stride")
	view._process(1)
	check(view.walking and view.phase() == -1,"recovery resumes walking")
	view.position = Vector2.ZERO
	var previous_duration := 0.0
	for dex in [0,20]:
		if demo.dexterity != dex: demo._toggle_dex()
		demo.select_direction(3)
		var hits: int = demo.targets[1].hits
		shots = view.staff_attacks
		var bounded := true
		for i in range(500):
			demo._physics_process(0.01)
			for p in demo.players: p._physics_process(0.01)
			view._process(0.01)
			step_arrows(0.01)
			bounded = bounded and arrows().size() <= PlayerProjectile.MAX_ACTIVE
		for i in range(100): step_arrows(0.01)
		check(bounded,"real projectile count stays bounded")
		check(demo.targets[1].hits-hits == view.staff_attacks-shots,"one hit per consecutive release")
		check(demo.targets[0].total_damage == demo.targets[1].total_damage,"same damage across consecutive Dex shots")
		check(after.attack.weapon.interval == before.attack.weapon.interval and view.staff_duration < after.attack.weapon.interval,"same cadence; recovery completes before next attack")
		if dex == 0: previous_duration = view.staff_duration
		else: check(view.staff_duration < previous_duration and after.attack.weapon.interval < 0.95,"Dex accelerates channel/recovery and actual cadence")
	await frames()
	# The new presentation cannot intercept Skill 1 or an Ultimate projectile.
	for ultimate in [false,true]:
		after.attack.projectile_requested.emit(after,demo.targets[1],{"damage":1,"kind":"orbe","speed":260.0,"reach":260.0,"category":"cajado","source":"orbe_arcano","ultimate":ultimate})
		check(arrows().size() == 1 and arrows()[0].get_script() != STAFF_ORB,"special projectile retains its original view")
		arrows()[0].finish()
	await frames()
	view.play_staff_attack(Vector2.RIGHT,0.95)
	after.input_driver.blocked = true
	demo._physics_process(0)
	check(view.phase() == -1,"blocking controls clears pending staff pose")
	after.input_driver.blocked = false
	view.play_staff_attack(Vector2.RIGHT,0.95)
	after.progress.equipped.Arma = "espada"
	after.apply_progression(after.progress)
	demo._physics_process(0)
	check(view.phase() == -1,"changing weapon clears staff pose")
	after.progress.equipped.Arma = "cajado"
	after.apply_progression(after.progress)
	view.play_staff_attack(Vector2.RIGHT,0.95)
	after.health.damage(after.health.maximum)
	check(view.phase() == -1,"death clears staff pose immediately")
	for p in demo.players:
		check(p.progress.disk_writes == 0 and p.progress.talents.xp.cajado == 0,"no save writes or proficiency credit")
		check((p.get_node("Collision").shape as CircleShape2D).radius == 13,"approved collision body preserved")
	demo.queue_free()
	await process_frame
	CombatRules.random_roll_source = Callable()
	print("STAFF_DEMO_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
