extends SceneTree
const DEMO := preload("res://scenes/demos/sword_attack_demo.tscn")
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
		push_error("SWORD_DEMO_FAIL: "+message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	var atlas := (load("res://assets/art/sword_demo_v1/attack.png") as Texture2D).get_image()
	check(atlas.get_size() == Vector2i(480,320),"six frames and four rows share aligned cells")
	for row in range(4):
		for column in range(6):
			var clear_border := true
			for offset in range(80):
				for edge in [Vector2i(offset,0),Vector2i(offset,79),Vector2i(0,offset),Vector2i(79,offset)]:
					if atlas.get_pixelv(Vector2i(column*80,row*80)+edge).a > 0: clear_border = false
			check(clear_border,"no clipped blade/arm/trail in cell %d,%d" % [row,column])
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var demo := DEMO.instantiate()
	root.add_child(demo)
	await frames(3)
	for player in demo.players: player.set_physics_process(false)
	var before: PlayerActor = demo.players[0]
	var after: PlayerActor = demo.players[1]
	var view = after.view
	check(before.stats.move_speed == after.stats.move_speed,"same movement speed")
	check(before.attack.weapon.reach == after.attack.weapon.reach,"same sword reach")
	check(before.attack.weapon.interval == after.attack.weapon.interval,"same base cadence")
	check(before.attack.damage_base == after.attack.damage_base and before.attack.critical_chance == after.attack.critical_chance,"same damage and crit")
	for index in range(4):
		demo.select_direction(index)
		var start_hits: int = demo.targets[1].hits
		after.attack.cooldown_left = 0.04
		after._physics_process(0.01)
		check(view.phase() == 0,"preparation precedes real hit %d" % index)
		check(demo.targets[1].hits == start_hits,"preparation deals no damage %d" % index)
		for player in demo.players:
			player.attack.cooldown_left = 0
			player.attack.search_left = 0
			player._physics_process(0)
		check(view.sword_row == index and view.phase() == 1,"actual attack starts directed swing %d" % index)
		check(demo.targets[1].hits == start_hits+1,"one immediate damage event %d" % index)
		check(demo.targets[0].total_damage == demo.targets[1].total_damage,"same resolved damage %d" % index)
		view._process(view.sword_duration*0.3)
		check(view.phase() == 2,"impact pose %d" % index)
		view._process(view.sword_duration*0.25)
		check(view.phase() == 3,"recovery pose %d" % index)
		view._process(view.sword_duration)
		check(view.phase() == -1,"returns to approved idle %d" % index)
	# No target -> no attack animation or damage, even when the cooldown is ready.
	demo.targets[1].enabled = false
	after.attack.cooldown_left = 0
	var attack_count: int = view.sword_attacks
	after._physics_process(0.02)
	check(view.sword_attacks == attack_count and not view.preparing,"no phantom attacks without target")
	demo.targets[1].enabled = true
	# Presentation never resets the original distance-based gait.
	view.set_moving(true)
	view.global_position += Vector2(ActorView.WALK_PIXELS_PER_FRAME,0)
	view._process(0.016)
	var stride: int = view.anim_frame
	view.play_sword_attack(Vector2.RIGHT,after.attack.weapon.interval)
	view._process(0.01)
	check(view.anim_frame == stride and view.walking,"attack retains current walking stride")
	view._process(0.5)
	check(view.walking and view.phase() == -1,"recovery returns to walking")
	view.position = Vector2.ZERO
	var base_animation_duration := 0.0
	for dex in [0,20]:
		if demo.dexterity != dex: demo._toggle_dex()
		demo.select_direction(3)
		var interval: float = after.attack.weapon.interval
		check(is_equal_approx(interval,before.attack.weapon.interval),"same modified cadence at Dex %d" % dex)
		if dex == 20: check(interval < 0.72,"Dex really changes original attack interval")
		var nodes := get_node_count()
		var hits: int = demo.targets[1].hits
		var count: int = view.sword_attacks
		for tick in range(600):
			after._physics_process(0.01)
			view._process(0.01)
		check(demo.targets[1].hits-hits == view.sword_attacks-count,"one visual per hit, consecutive Dex %d" % dex)
		check(get_node_count() == nodes,"no nodes allocated per attack at Dex %d" % dex)
		check(view.sword_duration < interval,"recovery ends before next attack at Dex %d" % dex)
		if dex == 0: base_animation_duration = view.sword_duration
		else: check(view.sword_duration < base_animation_duration,"Dex also speeds the animation itself")
	# Real touch analog -> InputDriver -> movement -> same collision body/dash.
	demo.select_direction(3)
	for player in demo.players: player.set_physics_process(true)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = demo.joystick.global_position+Vector2(70,39)
	demo.joystick._input(touch)
	check(demo.drivers[1].movement().x > 0,"real touch joystick drives player")
	await frames(90)
	var travel: float = after.position.x-demo.origins[1].x
	check(travel > 25 and travel <= 77,"original 13px collision stops at arena wall")
	check(absf(travel-(before.position.x-demo.origins[0].x)) < 0.1,"before/after movement and collision match")
	for driver in demo.drivers: driver.request_dash()
	await frames(20)
	check(after.position.x-demo.origins[1].x <= 77,"dash preserves wall collision")
	touch.pressed = false
	demo.joystick._input(touch)
	await frames(4)
	check(demo.drivers[1].touch_direction == Vector2.ZERO,"touch release stops movement")
	var selected: int = demo.direction_index
	touch.position = demo.direction_buttons[0].get_global_rect().get_center()
	touch.pressed = true
	demo._input(touch)
	check(demo.direction_index == 0 and selected != 0,"touch button changes inspection direction")
	for player in demo.players:
		check(player.progress.disk_writes == 0,"demo never writes a save")
		check((player.get_node("Collision").shape as CircleShape2D).radius == 13,"approved physical radius preserved")
	demo.queue_free()
	await process_frame
	CombatRules.random_roll_source = Callable()
	print("SWORD_DEMO_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
