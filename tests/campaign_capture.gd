extends SceneTree
const TRIAL = preload("res://tests/tower_trial_tests.gd")
const GUARDIAN = preload("res://tests/tower_guardian_tests.gd")
var output := ""
var failures := 0
func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")
func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame
	await RenderingServer.frame_post_draw
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("CAMPAIGN_QA_FAIL: " + message)
func capture(name: String) -> void:
	await frames(5)
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, name)
func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_campaign_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	for id in range(1,5):
		main.progress.ascension.defeats[str(id)] = 50
		main.progress.ascension.complete_forest_trial()
		main.progress.switch_floor(id+1)
	await main._travel_floor(1)
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		root.size = resolution
		await frames()
		var prefix := "campaign_%dx%d_" % [resolution.x,resolution.y]
		await main._travel_floor(1)
		main.enemy.set_physics_process(false)
		main.player.position = TowerEntrance.POSITION + Vector2(0,35)
		main._interact()
		await frames()
		main.hud.selected_floor = 2
		main.hud.refresh_station(main.progress)
		await frames()
		main.hud.station_scroll.scroll_vertical = 10000
		await frames()
		check(main.hud.floor_buttons.size() == 5 and not main.hud.travel_button.disabled and main.hud.travel_button.size.y >= 44, "five floor selection and enabled travel fit")
		await capture(prefix + "selection")
		TRIAL._tap(main.hud,main.hud.travel_button)
		await TRIAL._transition(self,main)
		main.enemy.set_physics_process(false)
		check(main.progress.ascension.current_floor == 2 and main.player.position == SafeCamp.RESPAWN and main.hud.heading.text == "Mata · Andar 2", "touch travels to safe reused floor two")
		await capture(prefix + "floor2")
		await main._travel_floor(5)
		main.progress.ascension.defeats["5"] = 50
		await main._enter_trial()
		TRIAL._freeze(main)
		GUARDIAN.reach_guardian(main)
		await create_timer(0.3).timeout
		var boss: TowerGuardian = main.tower_guardian
		main.player.position = TowerTrial.ORIGIN + Vector2(360,350)
		boss.position = TowerTrial.ORIGIN + Vector2(360,270)
		boss.health.damage(324)
		boss._physics_process(0)
		boss.action = TowerGuardian.Action.ROOTS
		boss._begin_attack()
		main._process_trial(0)
		TRIAL._freeze(main)
		check(boss.health.maximum == 648 and boss.phase_two and main.hud.boss_bar.value == 324, "existing Guardian phase two scales on floor five")
		await capture(prefix + "floor5_guardian")
		boss.receive_damage(100000)
		await frames()
		check(main.progress.ascension.campaign_completed and main.progress.ascension.unlocked_floors == [1,2,3,4,5] and main.hud.station_panel.visible, "campaign victory and no floor six")
		await capture(prefix + "campaign_victory")
		TRIAL._tap(main.hud,main.hud.tower_action_button)
		await TRIAL._transition(self,main)
	var file := FileAccess.open(output.path_join("campaign-result.txt"),FileAccess.WRITE)
	file.store_line("CAMPAIGN_QA_RESULT: %d failures" % failures)
	file.close()
	print("CAMPAIGN_QA_RESULT: %d failures" % failures)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	quit(1 if failures > 0 else 0)
