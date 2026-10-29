extends "res://tests/bow_demo_capture.gd"
## Share the existing render/screenshot helper; only the reviewed scene changes.
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	var kind := OS.get_environment("SKILL1_CATEGORY")
	if kind.is_empty(): kind = "espada"
	await capture_weapon(kind)
	quit(0)
func capture_weapon(kind: String) -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var demo := preload("res://scenes/demos/skill1_review.tscn").instantiate()
	root.add_child(demo)
	demo.select_category(kind)
	for i in range(4): await process_frame
	demo.set_physics_process(false)
	for player in demo.players: player.set_physics_process(false)
	var view = demo.players[1].view
	view.set_process(false)
	for row in range(4):
		demo.select_direction(row)
		view.skill1_row = row
		for pose in range(4):
			view.skill1_pose_override = pose
			view.queue_redraw()
			await process_frame
			await capture(output,"pose_%d_%d" % [row,pose])
	view.skill1_pose_override = -1
	view.set_process(true)
	demo.set_physics_process(true)
	for row in range(4):
		demo.select_direction(row)
		for player in demo.players:
			player.progress.abilities.skill1_cooldowns[kind] = 0 # Fresh capture fixture only.
			player._sync_skill_cooldowns()
			player.set_physics_process(true)
		for frame in range(40):
			await create_timer(0.04).timeout
			await capture(output,"motion_%d_%02d" % [row,frame])
		for player in demo.players: player.set_physics_process(false)
	demo.select_direction(3)
	demo._toggle_walk()
	for player in demo.players:
		player.progress.abilities.skill1_cooldowns[kind] = 0
		player._sync_skill_cooldowns()
		player.set_physics_process(true)
	for frame in range(40):
		await create_timer(0.04).timeout
		await capture(output,"walking_%02d" % frame)
	root.size = Vector2i(390,844)
	root.content_scale_size = root.size
	demo._layout()
	for i in range(5): await process_frame
	await capture(output,"mobile")
	root.size = Vector2i(844,390)
	root.content_scale_size = root.size
	demo._layout()
	for i in range(5): await process_frame
	await capture(output,"landscape")
	demo.queue_free()
	await process_frame
	print("SKILL1_CAPTURE: four directions, 16 key poses, real Skill 1 executions, walking, mobile")
	quit(0)
