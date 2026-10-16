extends SceneTree
var output := ""
var failures := 0

func _initialize() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	call_deferred("_run")

func frames(count := 3) -> void:
	for i in range(count):
		await process_frame
		await physics_frame

func capture(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func _run() -> void:
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", "user://qa_save_capture_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.set_process(false)
	await frames()
	for viewport: Vector2i in [Vector2i(360,640), Vector2i(390,844), Vector2i(640,360), Vector2i(960,540)]:
		root.size = viewport
		await frames()
		main._open_record()
		await capture("save_%dx%d_record" % [viewport.x, viewport.y])
		main._preview_import(main.progress.export_backup())
		await capture("save_%dx%d_confirm" % [viewport.x, viewport.y])
		for button: Button in [main.hud.save_panel.confirm_button, main.hud.save_panel.cancel_button, main.hud.save_panel.close_button]:
			if button.size.y < 44 or not main.hud.save_panel.get_global_rect().encloses(button.get_global_rect()):
				failures += 1
		main._save_action("cancel")
		main._preview_import("invalid")
		await capture("save_%dx%d_invalid" % [viewport.x, viewport.y])
		main.progress.save_status = "Save inválido ou incompatível; original preservado. Importe um backup para recuperar."
		main.hud.save_panel.open(main.progress)
		await capture("save_%dx%d_protected" % [viewport.x, viewport.y])
		main._save_action("close")
	main.queue_free()
	await frames()
	var file := FileAccess.open(output.path_join("save-result.txt"), FileAccess.WRITE)
	file.store_string("SAVE_QA_RESULT: %d failures\n" % failures)
	file.close()
	print("SAVE_QA_RESULT: %d failures" % failures)
	quit(1 if failures else 0)
