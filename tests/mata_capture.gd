extends SceneTree

var output := ""
var failures := 0

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")

func frames() -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await frames()
	if root.get_texture().get_image().save_png(output.path_join(name+".png")) != OK:
		failures += 1
		push_error("MATA_QA_FAIL: " + name)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_mata_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	main.progress.ascension.defeats["1"] = 50
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		root.size = resolution
		root.content_scale_size = resolution
		for place: String in ["trilha","norte","torre"]:
			main.player.position = {"trilha":Vector2(870,430),"norte":Vector2(650,240),"torre":Vector2(1110,495)}[place]
			main.hud.minimap.player_position = main.player.position
			(main.get_node("Andar1/TowerView") as TowerView).set_state(true,place == "torre")
			main.hud.set_nearby_station("Torre de Ascensão" if place == "torre" else "")
			await capture("mata_%dx%d_%s" % [resolution.x,resolution.y,place])
	root.size_changed.disconnect(main._adapt_orientation)
	root.size = Vector2i(1200,900)
	root.content_scale_size = Vector2i(1200,900)
	await frames()
	# _adapt_orientation uses the game's normal viewport; overview only overrides QA.
	root.content_scale_size = Vector2i(1200,900)
	main.hud.hide()
	var camera: Camera2D = main.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE
	main.player.position = Vector2(600,450)
	await capture("mata_overview")
	var file := FileAccess.open(output.path_join("mata-result.txt"),FileAccess.WRITE)
	file.store_line("MATA_QA_RESULT: %d failures" % failures)
	file.close()
	print("MATA_QA_RESULT: %d failures" % failures)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(1 if failures else 0)
