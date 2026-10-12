extends SceneTree
const TRIAL_TESTS = preload("res://tests/tower_trial_tests.gd")
const GUARDIAN_TESTS = preload("res://tests/tower_guardian_tests.gd")
var output := ""
var failures := 0
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")
func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame
	await RenderingServer.frame_post_draw
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("GUARDIAN_QA_FAIL: " + message)
func _capture(name: String) -> void:
	await frames(5)
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, name)
func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_guardian_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	TRIAL_TESTS._freeze(main)
	main.enemy.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	main.progress.ascension.defeats["1"] = 50
	for resolution: Vector2i in [Vector2i(360,640), Vector2i(390,844), Vector2i(640,360), Vector2i(960,540)]:
		root.size = resolution
		await frames()
		await main._enter_trial()
		TRIAL_TESTS._freeze(main)
		GUARDIAN_TESTS.reach_guardian(main)
		await create_timer(0.3).timeout
		var boss: TowerGuardian = main.tower_guardian
		main.player.position = TowerTrial.ORIGIN + Vector2(360,350)
		boss.position = TowerTrial.ORIGIN + Vector2(360,270)
		main.player.health.initialize(main.player.health.maximum)
		main.hud.loot_label.hide()
		main.hud.notice_left = 0
		boss.action = TowerGuardian.Action.ROOTS
		boss._begin_attack()
		main._process_trial(0)
		TRIAL_TESTS._freeze(main)
		var prefix := "guardian_%dx%d_" % [resolution.x,resolution.y]
		check(main.hud.boss_bar.visible and main.hud.boss_bar.value == 360 and not main.input_driver.blocked, "actual first phase HUD and combat controls")
		await _capture(prefix + "phase1_roots")
		boss.action = TowerGuardian.Action.SPIKES
		boss._begin_attack()
		boss._physics_process(1)
		boss._physics_process(0.01)
		check(boss.view.hazards_active and main.player.health.current == main.player.health.maximum - 16, "real rendered spikes activate and hit once")
		await _capture(prefix + "spikes")
		boss.action = TowerGuardian.Action.CHARGE
		boss._begin_attack()
		await _capture(prefix + "charge")
		main.player.view.damage_left = 0
		boss.health.damage(180)
		boss.state = TowerGuardian.State.RECOVERY
		boss._physics_process(0)
		boss.action = TowerGuardian.Action.ROOTS
		boss._begin_attack()
		main._process_trial(0)
		TRIAL_TESTS._freeze(main)
		check(boss.phase_two and main.hud.boss_name.text.contains("Fase 2") and main.hud.boss_bar.value == 180, "actual second phase energy and health")
		await _capture(prefix + "phase2_roots")
		boss.receive_damage(100000)
		await frames()
		check(main.trial.phase == TowerTrial.Phase.VICTORY and main.hud.station_panel.visible and main.input_driver.blocked, "real Guardian kill opens victory")
		check(main.hud.station_panel.get_global_rect().encloses(main.hud.tower_action_button.get_global_rect()) and main.hud.tower_action_button.size.y >= 44, "victory touch return fits")
		await _capture(prefix + "victory")
		TRIAL_TESTS._tap(main.hud, main.hud.tower_action_button)
		await TRIAL_TESTS._transition(self, main)
		check(not main.trial.active() and main.player.position == SafeCamp.RESPAWN, "actual touch victory return")
	await main._enter_trial()
	TRIAL_TESTS._freeze(main)
	GUARDIAN_TESTS.reach_guardian(main)
	await create_timer(0.3).timeout
	var boss: TowerGuardian = main.tower_guardian
	main.player.position = TowerTrial.ORIGIN + Vector2(360,350)
	boss.position = TowerTrial.ORIGIN + Vector2(360,270)
	root.size_changed.disconnect(main._adapt_orientation)
	root.size = Vector2i(720,540)
	await frames()
	root.content_scale_size = Vector2i(720,540)
	main.hud.hide()
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position = Vector2(0,-80)
	camera.reset_smoothing()
	boss.action = TowerGuardian.Action.ROOTS
	boss._begin_attack()
	await _capture("guardian_overview_phase1")
	boss.health.damage(180)
	boss._physics_process(0)
	await _capture("guardian_overview_phase2")
	var file := FileAccess.open(output.path_join("guardian-result.txt"), FileAccess.WRITE)
	file.store_line("GUARDIAN_QA_RESULT: %d failures" % failures)
	file.close()
	print("GUARDIAN_QA_RESULT: %d failures" % failures)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	quit(1 if failures > 0 else 0)
