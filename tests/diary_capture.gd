extends SceneTree

var output := ""

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://diary_capture_%d.json" % Time.get_ticks_usec())
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for enemy in get_nodes_in_group("damageable_enemies"): enemy.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	main.player.position = Vector2(550,450)
	for id: String in RPGRules.EQUIPMENT: main.progress.equipment[id] = 1
	main.progress.xp = main.progress.xp_for_level(14)
	main.progress.gold = 1367
	main.progress.talents.xp.espada = TalentRules.xp_floor(18)
	main.progress.learn_talent("espada","corte")
	main.progress.bag = {"Madeira":12,"Ervas":5,"Pedras":8,"Seda":3,"Essência":2}
	main.hud.set_rpg_status(main.progress,main.player)
	for resolution: Vector2i in [Vector2i(960,540),Vector2i(390,844),Vector2i(640,360),Vector2i(360,640)]:
		root.size = resolution
		main._adapt_orientation()
		var prefix := "%dx%d_" % [resolution.x,resolution.y]
		await capture(prefix+"hud")
		main._toggle_inventory()
		await capture(prefix+"mochila")
		main.hud.inventory_category = 0
		main.hud.refresh_inventory(main.progress)
		await capture(prefix+"materiais")
		main.hud._open_diary(2)
		await capture(prefix+"habilidades")
		main.hud._open_diary(1)
		await capture(prefix+"proficiencias")
		main.hud.rpg_panel.scroll.scroll_vertical = 230
		await capture(prefix+"arvore-ramos")
		main._toggle_character()
	quit()
