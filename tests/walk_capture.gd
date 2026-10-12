extends SceneTree

# Real PlayerActor + InputDriver + physics + ActorView. No assigned walk frames.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_walk_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", save_path)
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"):
		enemy.set_physics_process(false)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	var starts := [Vector2(550, 400), Vector2(550, 530), Vector2(610, 455), Vector2(500, 455)]
	for index in range(4):
		main.input_driver.reset()
		main.player.position = starts[index]
		main.player.view.set_moving(false)
		main.player.view.last_visual_position = main.player.global_position
		main.player.view.set_facing(directions[index])
		camera.reset_smoothing()
		for settle in range(6):
			await process_frame
		main.input_driver.set_touch_direction(directions[index])
		for frame in range(18):
			for tick in range(3):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("walk_%d_%02d.png" % [index, frame]))
		main.input_driver.reset()
		for tick in range(6):
			await process_frame
		print("WALK_CAPTURE: direction=%d travel=%.1f frame=%d" % [index, main.player.position.distance_to(starts[index]), main.player.view.anim_frame])
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
