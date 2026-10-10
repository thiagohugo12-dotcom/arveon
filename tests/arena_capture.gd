extends SceneTree

var failures := 0
var output := ""

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("ARENA_QA_FAIL: " + message)

func _frames() -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _frames()
	_check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, name + " saved")

func _actors(main) -> Array[EnemyActor]:
	var result: Array[EnemyActor] = []
	for node in main.get_children():
		if node is EnemyActor and node.health.is_alive() and not node.is_queued_for_deletion() and node.get_meta("tower_attempt", -1) == main.trial.attempt_id:
			result.append(node)
	return result

func _freeze(main) -> void:
	main.player.set_physics_process(false)
	for actor in _actors(main):
		actor.set_physics_process(false)

func _tap(hud: GameHUD, button: Button) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 96
	touch.pressed = true
	touch.position = button.get_global_rect().get_center()
	hud._input(touch)
	touch.pressed = false
	hud._input(touch)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_arena_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	main.enemy.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	await _frames()
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(960, 540)]:
		root.size = resolution
		await _frames()
		main.player.position = TowerEntrance.POSITION + Vector2(0, 35)
		main._interact()
		_tap(main.hud, main.hud.tower_action_button)
		for frame in range(100):
			if not main.transitioning:
				break
			await process_frame
		_check(main.trial.active() and not main.transitioning and not main.input_driver.blocked, "touch enters real arena at " + str(resolution))
		main.hud.notice_left = 0
		main.hud.loot_label.hide()
		main.player.position = TowerTrial.ORIGIN + Vector2(360, 270)
		main._process_trial(0.0)
		var prefix := "arena_%dx%d_" % [resolution.x, resolution.y]
		await _capture(prefix + "preparation")
		for wave in range(1, 4):
			main._process_trial(4.0)
			# Let the reused AI actually approach before freezing the evidence frame.
			for frame in range(66):
				await physics_frame
			_freeze(main)
			var actors := _actors(main)
			_check(actors.size() == [4, 6, 6][wave - 1] and main.trial.wave == wave, "native rendered wave count " + str(wave))
			_check(main.hud.joystick.is_processing_input() and main.hud.dash_button.enabled and not main.input_driver.blocked, "combat controls enabled in wave " + str(wave))
			if wave == 3:
				var elites := 0
				for actor in actors:
					elites += 1 if actor.kind == 3 else 0
				_check(elites == 1, "third wave renders one existing elite")
			main.hud.notice_left = 0
			main.hud.loot_label.hide()
			await _capture(prefix + "wave%d" % wave)
			if wave == 1:
				actors[0].position = main.player.position + Vector2(65, 0)
				main.player.attack.cooldown_left = 0
				main.player.attack.search_left = 0
				main.player.attack.tick(0.1, main.player)
				_check(actors[0].view.damage_left > 0.0, "real arena strike creates damage feedback")
				await _capture(prefix + "damage")
			# The proof cannot manufacture another heal from menu open/close.
			main.player.health.current = 40
			for actor in actors:
				actor.receive_damage(100000)
			await create_timer(0.26).timeout # Finish existing defeat fade before next wave.
			if wave < 3:
				_check(main.trial.phase == TowerTrial.Phase.INTERVAL and main.player.health.current == 55 and _actors(main).is_empty(), "one real 15 percent interval heal with zero active enemies")
				main.hud.set_process(false)
				await _capture(prefix + "interval%d" % wave)
				main.hud.set_process(true)
			else:
				await _frames()
				_check(main.hud.station_panel.visible and main.hud.tower_action_button.text == "Retornar à Mata" and main.input_driver.blocked, "third wave has safe return and no unlock")
				_check(main.hud.station_panel.get_global_rect().encloses(main.hud.tower_action_button.get_global_rect()), "return button fits actual viewport")
				await _capture(prefix + "completed")
		_tap(main.hud, main.hud.tower_action_button)
		for frame in range(100):
			if not main.transitioning:
				break
			await process_frame
		_check(not main.trial.active() and main.player.position == SafeCamp.RESPAWN and main.progress.ascension.unlocked_floors == [1] and not main.progress.ascension.completed_trials["1"], "touch returns to unchanged Mata with no ascension completion")
	# Whole arena evidence through the same native renderer; no annotations or HUD.
	await main._enter_trial()
	main.player.position = TowerTrial.ORIGIN + Vector2(360, 300)
	main._process_trial(4.0)
	_freeze(main)
	root.size_changed.disconnect(main._adapt_orientation)
	root.size = Vector2i(720, 540)
	await _frames()
	root.content_scale_size = Vector2i(720, 540)
	main.hud.hide()
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position = Vector2(0, -30)
	camera.reset_smoothing()
	await _capture("arena_overview")
	for wave in [2, 3]:
		for actor in _actors(main):
			actor.receive_damage(100000)
		await create_timer(0.26).timeout
		main._process_trial(4.0)
		_freeze(main)
		_check(_actors(main).size() == 6 and main.trial.wave == wave, "whole arena evidence shows exact wave " + str(wave))
		await _capture("arena_overview_wave%d" % wave)
	var file := FileAccess.open(output.path_join("arena-result.txt"), FileAccess.WRITE)
	file.store_line("ARENA_QA_RESULT: %d failures" % failures)
	file.close()
	print("ARENA_QA_RESULT: %d failures" % failures)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	quit(1 if failures > 0 else 0)
