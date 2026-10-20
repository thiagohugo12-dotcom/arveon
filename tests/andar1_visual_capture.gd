extends SceneTree

var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for _frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _settle()
	var image := root.get_texture().get_image()
	if image.save_png(output.path_join(name + ".png")) != OK:
		push_error("Could not save Andar 1 image: " + name)

func _frame_world(main: Node, center: Vector2, zoom_value: float) -> void:
	main.player.position = center
	main.player.velocity = Vector2.ZERO
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE * zoom_value
	camera.reset_smoothing()
	camera.force_update_scroll()

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		push_error("QA_RENDER_DIR is required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_andar1_visual_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.limit_enabled = false
	main.hud.hide()
	root.size = Vector2i(1200, 900)
	root.content_scale_size = Vector2i(1200, 900)
	main.player.position = Vector2(850, 675)
	_frame_world(main, Vector2(850, 675), 0.25)
	await _capture("overview")
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	for region: Dictionary in [
		{"name":"mata-profunda", "center":Vector2(530, 1130), "zoom":0.8},
		{"name":"ruinas-antigas", "center":Vector2(1445, 250), "zoom":1.2},
		{"name":"regiao-perigosa", "center":Vector2(1490, 640), "zoom":1.2},
		{"name":"bosque-secreto", "center":Vector2(1495, 1160), "zoom":1.2},
		{"name":"torre-ascensao", "center":TowerEntrance.POSITION+Vector2(0,20), "zoom":1.0}
	]:
		_frame_world(main, region.center, region.zoom)
		if region.name == "torre-ascensao":
			camera.position = Vector2(0,-65)
			camera.force_update_scroll()
		await _capture(region.name)
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(540, 960)
	main.hud.show()
	main.player.position = Vector2(760, 1185)
	_frame_world(main, Vector2(760, 1185), 0.85)
	await _capture("mata-profunda-retrato")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("ANDAR1_VISUAL_CAPTURE: saved 7 game frames to " + output)
	quit()
