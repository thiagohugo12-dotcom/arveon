extends SceneTree

# Run with a real GL display. Exercises PlayerActor and existing input/physics,
# then freezes effects for readable captures; saves use an isolated QA path.
var output := ""
var failures := 0

func _initialize() -> void:
	# These captures assert ordinary hit amounts; criticals have dedicated tests.
	CombatRules.random_roll_source = func(): return 0.99
	create_timer(45.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("COMBAT_QA_PASS: " + message)

func _frames() -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _frames()
	var image := root.get_texture().get_image()
	_check(image.save_png(output.path_join(name + ".png")) == OK, name + " rendered")
	if name == "combat_390x844_right" or name == "combat_960x540_left" or name == "combat_360x640_blocked":
		print("COMBAT_REVIEW_%s=%s" % [name, Marshalls.raw_to_base64(image.save_jpg_to_buffer(0.85))])

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_combat_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", save_path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.view.set_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
		actor.view.set_process(false)
		if actor != main.enemy:
			actor.queue_free()
	main.enemy.target = null
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	await _frames()
	# Find an actual four-way open patch on the unchanged map, using World rays.
	var centre := Vector2.ZERO
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	for y in range(320, 620, 20):
		for x in range(860, 1060, 20):
			var point := Vector2(x, y)
			var clear := true
			for direction: Vector2 in directions:
				var query := PhysicsRayQueryParameters2D.create(point, point + direction * 75.0, 1)
				clear = clear and main.player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
			if clear and centre.is_zero_approx():
				centre = point
	_check(not centre.is_zero_approx(), "real map contains a clear four-direction combat patch")
	if centre.is_zero_approx():
		quit(1)
		return
	var tree := Vector2.ZERO
	for foot: Vector2 in main.get_node("Andar1/FloorView").tree_positions():
		if foot.x > 850 and foot.x < 1100 and foot.y > 200 and foot.y < 750:
			tree = foot
			break
	_check(not tree.is_zero_approx(), "tree obstacle available for real blocked-hit capture")
	for resolution: Vector2i in [Vector2i(360,640), Vector2i(390,844), Vector2i(640,360), Vector2i(960,540)]:
		root.size = resolution
		root.content_scale_size = resolution
		await _frames()
		main.hud.set_rpg_status(main.progress, main.player)
		for index in range(4):
			main.input_driver.reset()
			main.player.position = centre
			main.player.view.set_moving(false)
			main.player.last_direction = Vector2(1, 1).normalized()
			main.enemy.position = centre + directions[index] * 75.0
			main.enemy.health.initialize(48)
			main.enemy.view.damage_left = 0.0
			main.enemy.view.previous_damage_left = 0.0
			main.player.attack.cooldown_left = 0.0
			main.player.attack.search_left = 0.0
			await _frames()
			var move := InputEventScreenTouch.new()
			move.index = 72
			move.pressed = true
			move.position = main.hud.joystick.get_global_rect().get_center() + -directions[index] * 45.0
			var key: String = ["move_up", "move_down", "move_right", "move_left"][index]
			if resolution.x == 960:
				Input.action_press(key)
			else:
				main.hud.joystick._input(move)
			main.player._physics_process(1.0 / 60.0)
			_check(main.enemy.health.current == 36, "real basic hit once (%s/%d)" % [resolution, index])
			_check(main.player.view.attack_direction.is_equal_approx(directions[index]), "strike aims against locomotion (%s/%d)" % [resolution, index])
			_check(main.player.last_direction.is_equal_approx(-directions[index]), "keyboard/joystick reaches PlayerActor (%s/%d)" % [resolution, index])
			Input.action_release(key)
			move.pressed = false
			main.hud.joystick._input(move)
			main.input_driver.reset()
			main.player.view._process(0.055)
			main.enemy.view._process(0.055)
			main.player.get_node("Camera2D").reset_smoothing()
			await _capture("combat_%dx%d_%s" % [resolution.x, resolution.y, ["down", "up", "left", "right"][index]])
		# Existing skill button and basic attack remain distinct intentional hits.
		main.player.position = centre
		main.enemy.position = centre + Vector2(-75, 0)
		main.enemy.health.initialize(48)
		main.enemy.view.damage_left = 0.0
		main.enemy.view.previous_damage_left = 0.0
		main.player.attack.cooldown_left = 0.0
		main.player.attack.search_left = 0.0
		main.player.skill_cooldowns[0] = 0.0
		main.hud.set_rpg_status(main.progress, main.player)
		await _frames()
		main.player._physics_process(0.0)
		var skill := InputEventScreenTouch.new()
		skill.index = 73
		skill.pressed = true
		skill.position = main.hud.actions[0].get_global_rect().get_center()
		main.hud.actions[0]._input(skill)
		main.hud.actions[0]._input(skill)
		_check(main.enemy.health.current == 19 and main.player.skill_cooldowns[0] > 0.0, "touch skill responds once alongside separate basic hit %s" % resolution)
		_check(main.enemy.view.damage_amount == 17 and main.enemy.view.previous_damage_amount == 12, "two rapid intentional hits retain distinct labels %s" % resolution)
		skill.pressed = false
		main.hud.actions[0]._input(skill)
		main.enemy.view._process(0.055)
		main.player.view._process(0.055)
		await _capture("combat_%dx%d_combo" % [resolution.x, resolution.y])
		main.player.position = centre
		main.enemy.position = centre + Vector2(140, 0)
		main.enemy.health.initialize(48)
		main.enemy.view._process(1.0)
		main.player.view._process(1.0)
		main.player.attack.cooldown_left = 0.0
		main.player.attack.search_left = 0.0
		await _frames()
		main.player._physics_process(0.0)
		_check(main.enemy.health.current == 48 and main.player.view.attack_left == 0.0, "out-of-range miss has no hit feedback %s" % resolution)
		await _capture("combat_%dx%d_miss" % [resolution.x, resolution.y])
		main.player.position = tree + Vector2(-40, 1)
		main.enemy.position = tree + Vector2(40, 1)
		main.player.attack.search_left = 0.0
		await _frames()
		main.player._physics_process(0.0)
		_check(main.enemy.health.current == 48 and main.player.view.attack_left == 0.0, "tree blocks real hit and effect %s" % resolution)
		main.player.get_node("Camera2D").reset_smoothing()
		await _capture("combat_%dx%d_blocked" % [resolution.x, resolution.y])
	var result := "COMBAT_QA_RESULT: %d failures" % failures
	var report := FileAccess.open(output.path_join("combat-result.txt"), FileAccess.WRITE)
	report.store_line(result)
	report.flush()
	report.close()
	print(result)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CombatRules.random_roll_source = Callable()
	quit(1 if failures > 0 else 0)
