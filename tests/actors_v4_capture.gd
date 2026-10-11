extends SceneTree
var output := ""

func _initialize() -> void:
	create_timer(40).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://actors_v4_capture.json")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	for enemy in get_nodes_in_group("damageable_enemies"): enemy.queue_free()
	await process_frame
	root.size = Vector2i(960,540)
	main._adapt_orientation()
	main.player.position = Vector2(900,710)
	for kind in range(3):
		var actor: EnemyActor = main._make_enemy(kind)
		actor.position = Vector2(820+kind*92,650)
		actor.target = main.player
		main._register_enemy_defeat(actor)
		main.add_child(actor)
		actor.set_physics_process(false)
	await capture("monsters_pickups")
	for frame in range(4):
		for actor in get_nodes_in_group("damageable_enemies"):
			actor.view.set_process(false)
			actor.view.walking = true
			actor.view.anim_frame = frame
			actor.view.queue_redraw()
		main.player.view.set_process(false)
		main.player.view.walking = true
		main.player.view.anim_frame = frame
		main.player.view.queue_redraw()
		await capture("stride_%d" % frame)
	main.player.position = Vector2(710,180)
	await capture("wood_north")
	main.player.position = SafeCamp.RESPAWN
	var floor_view: FloorView = main.world.get_node("FloorView")
	floor_view.set_chest_open(true)
	await create_timer(0.3).timeout
	for npc in floor_view.get_children():
		if npc is CampNpcView:
			npc.set_process(false)
			npc.action_frame = 1
			npc.queue_redraw()
	await capture("npc_actions_open_chest")
	quit()

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
