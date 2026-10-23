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
		push_error("Falha ao salvar captura do Andar 2: " + name)

func _frame(main: Node2D, center: Vector2, zoom_value: float) -> void:
	main.player.position = center
	main.player.velocity = Vector2.ZERO
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE * zoom_value
	camera.reset_smoothing()
	camera.force_update_scroll()
	main.hud.minimap.update_player(center)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		push_error("QA_RENDER_DIR é obrigatório")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://qa_andar2_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	await main._travel_floor(2)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.hide()
		actor.set_physics_process(false)
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled = false
	camera.limit_enabled = false
	main.hud.hide()
	root.size = Vector2i(1200, 900)
	root.content_scale_size = Vector2i(1200, 900)
	_frame(main, Vector2(850, 675), 0.34)
	await _capture("visao-geral")
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	for area: Dictionary in [
		{"name": "area-segura", "center": Vector2(360, 860), "zoom": 1.0},
		{"name": "pedreira-dourada", "center": Vector2(510, 325), "zoom": 1.0},
		{"name": "ruinas-da-chapada", "center": Vector2(1210, 345), "zoom": 1.0},
		{"name": "campos-e-perigo", "center": Vector2(1050, 740), "zoom": 0.9},
		{"name": "arena-do-colosso", "center": Vector2(1380, 1070), "zoom": 1.0},
		{"name": "passagem-discreta", "center": Vector2(1540, 800), "zoom": 1.0}
	]:
		_frame(main, area.center, area.zoom)
		await _capture(area.name)
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	main.hud.show()
	_frame(main, Vector2(350, 910), 0.9)
	await _capture("acampamento-celular-vertical")
	_frame(main, Vector2(760, 720), 0.9)
	await _capture("celular-vertical")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("ANDAR2_CAPTURE: 9 capturas reais em " + output)
	quit()
