extends SceneTree

var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _capture(main: Node2D, actor: EnemyActor, position: Vector2, name: String) -> void:
	main.player.position = position + Vector2(-54, 32)
	main.player.velocity = Vector2.ZERO
	actor.position = position
	actor.show()
	actor.view.set_moving(false)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.reset_smoothing()
	camera.force_update_scroll()
	main.hud.minimap.update_player(main.player.position)
	for _frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png(output.path_join(name + ".png")) != OK:
		push_error("Falha na captura real: " + name)
	actor.hide()

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		push_error("QA_RENDER_DIR obrigatório")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_floor2_monster_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	for existing in get_nodes_in_group("damageable_enemies"):
		existing.hide()
		existing.set_physics_process(false)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.limit_enabled = false
	camera.zoom = Vector2.ONE
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	for entry in [
		{"kind": 5, "point": Vector2(490, 350), "name": "goblin-pedreira"},
		{"kind": 6, "point": Vector2(750, 700), "name": "tatu-campos"},
		{"kind": 7, "point": Vector2(1200, 410), "name": "escorpiao-ruinas"}
	]:
		var actor: EnemyActor = main._make_enemy(entry.kind)
		main.add_child(actor)
		actor.set_physics_process(false)
		await _capture(main, actor, entry.point, entry.name)
		actor.queue_free()
		await process_frame
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	var vertical: EnemyActor = main._make_enemy(6)
	main.add_child(vertical)
	vertical.set_physics_process(false)
	await _capture(main, vertical, Vector2(750, 700), "celular-vertical")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("MONSTER GAME CAPTURE: " + output)
	quit()
