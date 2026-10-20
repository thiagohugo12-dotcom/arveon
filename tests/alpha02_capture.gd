extends SceneTree

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _capture(path: String) -> void:
	for _i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Falha na captura: " + path)
		quit(1)

func _run() -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", "user://qa_alpha02_capture_%d.json" % Time.get_ticks_usec())
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	var title := (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _capture(output.path_join("alpha02-abertura-390x844.png"))
	title._start_game(true)
	await _capture(output.path_join("alpha02-andar1-390x844.png"))
	quit()
