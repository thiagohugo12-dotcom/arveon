extends SceneTree

# Captura trechos reais do mundo (sem HUD) para revisar o terreno. QA_FLOOR escolhe o andar.
var output := ""

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")

func capture(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://world_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.queue_free()
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	main.hud.hide()
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.limit_left = -5000
	camera.limit_top = -5000
	camera.limit_right = 5000
	camera.limit_bottom = 5000
	var spots := {"atras": Vector2(840,1225), "lado": Vector2(900,1280), "frente": Vector2(830,1325)}
	for key in spots:
		main.player.position = spots[key]
		await capture("mundo-" + key)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
