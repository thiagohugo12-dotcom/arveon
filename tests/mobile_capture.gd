extends SceneTree

# Rendered QA, run with a real GL display (Xvfb supported), never headless.
# QA_RENDER_DIR selects an output directory; save uses an isolated temporary path.
var output := ""

func _initialize() -> void:
	create_timer(20.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _frames() -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _frames()
	var result := root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	if result != OK:
		push_error("Screenshot failed: " + name)
		quit(1)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.position = SafeCamp.RESPAWN
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	var p: GameProgress = main.progress
	p.xp = 360
	p.gold = 90
	for item: String in GameProgress.ITEMS:
		p.add_item(item, 12)
	p.forge("machado", -1)
	p.forge("couro", -1)
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(640, 360)]:
		root.size = resolution
		root.content_scale_size = resolution
		await _frames()
		var orientation := "portrait" if resolution.y > resolution.x else "landscape"
		main.hud.set_rpg_status(p, main.player)
		await _capture(orientation + "_world")
		main.hud.show_inventory(p)
		await _capture(orientation + "_materials")
		main.hud.inventory_category = 1
		main.hud.refresh_inventory(p)
		await _capture(orientation + "_equipment")
		main.hud.close_inventory()
		main.hud.show_character(p)
		main.hud.rpg_panel.tab = 0
		main.hud.rpg_panel.refresh(p)
		await _capture(orientation + "_character")
		main.hud.rpg_panel.tab = 1
		main.hud.rpg_panel.refresh(p)
		await _capture(orientation + "_skills")
		main.hud.close_character()
		main.hud.show_station("Ferreiro", p)
		await _capture(orientation + "_smith")
		main.hud.close_station()
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(0)
