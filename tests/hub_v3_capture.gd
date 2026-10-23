extends SceneTree
var output := ""
func _initialize() -> void:
	create_timer(40).timeout.connect(func(): quit(1))
	call_deferred("_run")
func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("ARVEON_SAVE_PATH","user://hub_v3_capture.json")
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"): enemy.set_physics_process(false)
	var camera: Camera2D = main.player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	main.player.position = Vector2(550,450)
	for size: Vector2i in [Vector2i(960,540),Vector2i(390,844),Vector2i(389,1732)]:
		root.size = size
		main._adapt_orientation()
		await capture("hub_%dx%d" % [size.x,size.y])
	# Actual renderer at a fixed overview scale, for comparing composition.
	root.size = Vector2i(1200,900)
	root.content_scale_size = Vector2i(1200,900)
	camera.zoom = Vector2.ONE
	main.player.position = Vector2(600,450)
	main.hud.hide()
	await capture("hub_overview")
	quit()
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
