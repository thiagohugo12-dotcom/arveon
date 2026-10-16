extends SceneTree
const DEMO := preload("res://scenes/demos/bow_attack_demo.tscn")
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
		push_error("BOW_DEMO_FAIL: "+message)
func frames() -> void:
	for i in range(3):
		await physics_frame
		await process_frame
func arrows() -> Array[Node]: return get_nodes_in_group("player_projectiles")
func step_arrows(delta: float) -> void:
	for arrow in arrows():
		arrow.set_physics_process(false)
		arrow._physics_process(delta)
func run() -> void:
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var image := preload("res://assets/art/bow_demo_v1/attack.png").get_image()
	check(image.get_size() == Vector2i(640,320),"eight aligned frames in four rows")
	for row in range(4):
		for col in range(8):
			var clear := true
			for pixel in range(80):
				for edge in [Vector2i(pixel,0),Vector2i(pixel,79),Vector2i(0,pixel),Vector2i(79,pixel)]:
					clear = clear and image.get_pixelv(Vector2i(col*80,row*80)+edge).a == 0
			check(clear,"no clipped bow/arms in cell %d,%d" % [row,col])
	var demo := DEMO.instantiate()
	root.add_child(demo)
	for p in demo.players: p.set_physics_process(false)
	await frames()
	var before: PlayerActor = demo.players[0]
	var after: PlayerActor = demo.players[1]
	var view = after.view
	check(after.attack.weapon.category == "arco" and after.attack.weapon.interval == 0.8,"real equipped bow profile")
	check(after.attack.weapon.reach == 300 and after.attack.weapon.projectile_speed == 440,"original range and speed")
	check(before.stats.move_speed == after.stats.move_speed and before.attack.damage_base == after.attack.damage_base,"same movement and damage")
	for index in range(4):
		demo.select_direction(index)
		await frames()
		var hits: int = demo.targets[1].hits
		after.attack.cooldown_left = 0.30
		after._physics_process(0.0)
		check(view.phase() == 0 and arrows().is_empty(),"preparation without phantom arrow %d" % index)
		after.attack.cooldown_left = 0.08
		after._physics_process(0.0)
		check(view.phase() == 1 and demo.targets[1].hits == hits,"tension never damages %d" % index)
		for p in demo.players:
			p.attack.cooldown_left = 0
			p.attack.search_left = 0
			p._physics_process(0.0)
		check(view.phase() == 2 and view.bow_row == index,"release frame starts on real shot %d" % index)
		check(arrows().size() == 2 and demo.targets[1].hits == hits,"one projectile each; no immediate damage %d" % index)
		for arrow in arrows():
			arrow.set_physics_process(false)
			check(arrow.position == arrow.shooter.position and arrow.speed == 440 and arrow.distance_left == 300,"physical origin/budget unchanged")
			if arrow.get_script() == preload("res://scripts/demos/bow_demo_projectile.gd"):
				check(arrow.visual_offset() == view.MUZZLES[index],"arrow drawing starts at bow muzzle")
		step_arrows(0.1)
		check(demo.targets[1].hits == hits,"arrow must travel before impact %d" % index)
		for arrow in arrows(): check(is_equal_approx(arrow.distance_left,256),"unchanged physical travel")
		view._process(view.bow_duration*0.4)
		check(view.phase() == 3,"recovery follows release %d" % index)
		for i in range(15): step_arrows(0.02)
		check(demo.targets[1].hits == hits+1 and demo.targets[0].total_damage == demo.targets[1].total_damage,"exactly one identical impact %d" % index)
		view._process(1.0)
		check(view.phase() == -1,"returns to idle %d" % index)
		await frames()
	demo.targets[1].enabled = false
	var shots: int = view.bow_attacks
	after.attack.cooldown_left = 0
	after.attack.search_left = 0
	after._physics_process(0)
	check(view.bow_attacks == shots and not view.preparing and arrows().is_empty(),"no target means no draw or shot")
	demo.targets[1].enabled = true
	demo.targets[1].position = after.position+Vector2.RIGHT*350
	after.attack.search_left = 0
	after._physics_process(0)
	check(view.bow_attacks == shots and arrows().is_empty(),"out of range preserves original rule")
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
	shots = view.bow_attacks
	after._physics_process(0)
	check(view.bow_attacks == shots and arrows().is_empty(),"wall blocks target selection before release")
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
	view.play_bow_attack(Vector2.RIGHT,0.8)
	view._process(0.01)
	check(view.anim_frame == stride and view.walking,"arms do not reset planted leg stride")
	view._process(1.0)
	check(view.walking and view.phase() == -1,"recovery resumes walking")
	view.position = Vector2.ZERO
	var previous_duration := 0.0
	for dex in [0,20]:
		if demo.dexterity != dex: demo._toggle_dex()
		demo.select_direction(3)
		var interval: float = after.attack.weapon.interval
		check(is_equal_approx(interval,before.attack.weapon.interval),"same actual Dex interval")
		var hits: int = demo.targets[1].hits
		shots = view.bow_attacks
		for i in range(400):
			for p in demo.players: p._physics_process(0.01)
			view._process(0.01)
			step_arrows(0.01)
			check(arrows().size() <= PlayerProjectile.MAX_ACTIVE,"bounded actual projectiles")
		# Drain shots already in flight; no extra attack ticks.
		for i in range(50): step_arrows(0.01)
		check(demo.targets[1].hits-hits == view.bow_attacks-shots,"one impact per consecutive visual release")
		check(demo.targets[0].total_damage == demo.targets[1].total_damage,"before/after damage remains equal")
		check(view.bow_duration < interval,"recovery fits real cooldown")
		if dex == 0: previous_duration = view.bow_duration
		else: check(view.bow_duration < previous_duration and interval < 0.8,"Dex accelerates both poses and actual cadence")
	await frames()
	demo.select_direction(3)
	for i in range(2):
		demo.targets[i].position = demo.origins[i]+Vector2(130,-100)
		demo.players[i].attack.cooldown_left = 0
		demo.players[i].attack.search_left = 0
		demo.players[i]._physics_process(0)
	for arrow in arrows():
		arrow.set_physics_process(false)
		check(arrow.direction.dot(Vector2(130,-100).normalized()) > 0.999,"diagonal shots keep actual target direction")
		if arrow.get_script() == preload("res://scripts/demos/bow_demo_projectile.gd"):
			check(arrow.visual_direction.dot((arrow.target.position+arrow.visual_end-arrow.shooter.position-arrow.visual_start).normalized()) > 0.999,"visual arrow points from bow to target")
	for i in range(60): step_arrows(0.01)
	check(demo.targets[0].total_damage == demo.targets[1].total_damage,"diagonal impact matches original projectile")
	await frames()
	after.attack.cooldown_left = 0.1
	after._physics_process(0)
	after.input_driver.blocked = true
	after._physics_process(0)
	check(view.phase() == -1,"blocked controls cancel pending draw")
	after.input_driver.blocked = false
	var old_direction: int = demo.direction_index
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_1
	demo._unhandled_key_input(key)
	check(demo.direction_index == 0 and old_direction != 0,"keyboard selects direction")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = demo.direction_buttons[2].get_global_rect().get_center()
	demo._input(touch)
	check(demo.direction_index == 2,"touch selects direction")
	demo._toggle_attacks()
	demo._repeat()
	check(demo.attacks_enabled and after.attack.cooldown_left == after.attack.weapon.interval,"repeat restarts a full anticipated cycle")
	for p in demo.players:
		check(p.progress.disk_writes == 0 and p.progress.talents.xp.arco == 0,"no saves or proficiency progression")
		check((p.get_node("Collision").shape as CircleShape2D).radius == 13,"same collision radius")
	demo.queue_free()
	await process_frame
	CombatRules.random_roll_source = Callable()
	print("BOW_DEMO_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
