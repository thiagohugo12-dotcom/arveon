extends SceneTree

var output := ""

func _initialize() -> void:
	create_timer(50.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _capture(name: String, main: Node2D) -> void:
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK)

func _wave_actors(main: Node2D) -> Array[EnemyActor]:
	var actors: Array[EnemyActor] = []
	for node in main.get_children():
		if node is EnemyActor and node.health.is_alive() and node.get_meta("tower_attempt", -1) == main.trial.attempt_id:
			actors.append(node)
	return actors

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_forest_guardian_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(960, 720)
	root.content_scale_size = root.size
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	await main._enter_trial()
	main.set_process(false)
	main.player.set_physics_process(false)
	for wave in range(3):
		main._process_trial(4.0)
		var actors := _wave_actors(main)
		for actor in actors:
			actor.set_physics_process(false)
			actor.receive_damage(100000)
		await create_timer(0.26).timeout
		for actor in actors:
			if is_instance_valid(actor):
				actor.queue_free()
		await process_frame
	main._process_trial(4.0)
	var boss: TowerGuardian = main.tower_guardian
	assert(is_instance_valid(boss) and boss.view is TowerGuardianView)
	boss.set_physics_process(false)
	await _capture("guardiao-mata-surgimento", main)
	boss.position = TowerTrial.ORIGIN + Vector2(360, 315)
	main.player.position = boss.position + Vector2(40, 140)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	main.hud.notice_left = 0.0
	main.hud.loot_label.hide()
	await _capture("guardiao-mata-repouso", main)
	boss.action = TowerGuardian.Action.ROOTS
	boss._begin_attack()
	await _capture("guardiao-mata-preparo", main)
	boss._physics_process(float(TowerGuardian.WINDUPS[boss.action]))
	await _capture("guardiao-mata-golpe", main)
	boss._finish_attack()
	boss.action = TowerGuardian.Action.SPIKES
	boss._begin_attack()
	boss._physics_process(float(TowerGuardian.WINDUPS[boss.action]))
	await _capture("guardiao-mata-impacto", main)
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	await _capture("guardiao-mata-celular", main)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("FOREST_GUARDIAN_CAPTURE: 6 capturas reais em " + output)
	quit()
