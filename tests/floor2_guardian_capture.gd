extends SceneTree

var output := ""

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _capture(name: String, main: Node2D) -> void:
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	main.hud.minimap.update_player(main.player.position)
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png(output.path_join(name + ".png")) == OK)

func _wave_actors(main: Node2D) -> Array[EnemyActor]:
	var found: Array[EnemyActor] = []
	for node in main.get_children():
		if node is EnemyActor and node.health.is_alive() and node.get_meta("tower_attempt", -1) == main.trial.attempt_id:
			found.append(node)
	return found

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_vale_guardian_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.limit_enabled = false
	main.enemy.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		(actor as EnemyActor).set_physics_process(false)
	main.player.position = Floor2Layout.GUARDIAN_ALTAR
	main._interact()
	var colossus: EnemyActor = main.guardian
	colossus.set_physics_process(false)
	main.player.position = Floor2Layout.GUARDIAN_ALTAR + Vector2(-75, -25)
	main.hud.notice_left = 0.0
	main.hud.loot_label.hide()
	await _capture("colosso-vale", main)
	colossus.view.telegraph_kind = 0
	colossus.view.set_warning(true)
	await _capture("colosso-ataque", main)
	colossus.queue_free()
	await process_frame
	main.player.position = Floor2Layout.TOWER_POSITION + Vector2(0, 44)
	await _capture("torre-vale", main)
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	await _capture("torre-celular-vertical", main)
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	main.progress.ascension.defeats["2"] = 50
	await main._enter_trial()
	main.set_process(false)
	main.player.set_physics_process(false)
	camera.limit_enabled = true
	main.hud.notice_left = 0.0
	main.hud.loot_label.hide()
	await _capture("arena-torre-vale", main)
	for wave in range(1, 4):
		main._process_trial(4.0)
		var actors := _wave_actors(main)
		for actor in actors:
			actor.set_physics_process(false)
		if wave == 1:
			await _capture("horda-vale", main)
		for actor in actors:
			actor.receive_damage(100000)
		await create_timer(0.26).timeout
		for actor in actors:
			if is_instance_valid(actor):
				actor.queue_free()
		await process_frame
	main._process_trial(4.0)
	var boss: TowerGuardian = main.tower_guardian
	boss.set_physics_process(false)
	main.player.position = boss.position + Vector2(45, 130)
	main.hud.notice_left = 0.0
	main.hud.loot_label.hide()
	root.size = Vector2i(960, 720)
	root.content_scale_size = Vector2i(960, 720)
	await _capture("guardiao-torre-vale", main)
	boss._begin_attack()
	await _capture("guardiao-ataque", main)
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	await _capture("guardiao-celular-vertical", main)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("VALE_GUARDIAN_CAPTURE: 9 capturas reais em " + output)
	quit()
