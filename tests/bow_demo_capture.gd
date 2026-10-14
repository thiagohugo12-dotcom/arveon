extends SceneTree
## Godot render evidence, including actual timed AutoAttack (not posed GIF frames).
func _initialize() -> void:
	call_deferred("run")

func capture(output: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func run() -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(960,620)
	root.content_scale_size = root.size
	var demo := preload("res://scenes/demos/bow_attack_demo.tscn").instantiate()
	root.add_child(demo)
	for i in range(5): await process_frame
	for player in demo.players: player.set_physics_process(false)
	demo.set_physics_process(false)
	for direction in range(4):
		demo.select_direction(direction)
		var view = demo.players[1].view
		view.set_process(false)
		view.bow_row = direction
		for pose in range(4):
			view.pose_override = pose
			view.queue_redraw()
			await process_frame
			await capture(output,"pose_%d_%d" % [direction,pose])
		view.pose_override = -1
		view.set_process(true)
	for direction in range(4):
		demo.select_direction(direction)
		for player in demo.players: player.set_physics_process(true)
		for frame in range(28):
			await create_timer(0.04).timeout
			await capture(output,"motion_%d_%02d" % [direction,frame])
		for player in demo.players: player.set_physics_process(false)
	# Real walking + attacks and portrait layout.
	demo.select_direction(3)
	demo._toggle_walk()
	demo.set_physics_process(true)
	for player in demo.players: player.set_physics_process(true)
	for frame in range(28):
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
	await contact_sheet(output)
	print("BOW_CAPTURE: four directions, 16 key poses, real stationary/walking attacks, portrait")
	quit(0)

func contact_sheet(output: String) -> void:
	root.size = Vector2i(1000,780)
	root.content_scale_size = root.size
	var sheet := Node2D.new()
	root.add_child(sheet)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1000,0),Vector2(1000,780),Vector2(0,780)])
	background.color = Color("#b7ca64")
	sheet.add_child(background)
	var title := Label.new()
	title.text = "ARCO V1 · EXPLORADOR APROVADO · POSES-CHAVE"
	title.position = Vector2(26,12)
	title.add_theme_color_override("font_color",Color("#283d29"))
	title.add_theme_font_size_override("font_size",24)
	sheet.add_child(title)
	for pose in range(4):
		var label := Label.new()
		label.text = ["Preparação","Tensão","Disparo","Recuperação"][pose]
		label.position = Vector2(130+220*pose,54)
		label.add_theme_color_override("font_color",Color("#283d29"))
		sheet.add_child(label)
		for direction in range(4):
			var view := preload("res://scripts/demos/bow_demo_view.gd").new()
			view.village_scale = true
			view.bow_row = direction
			view.pose_override = pose
			view.position = Vector2(185+220*pose,220+170*direction)
			view.scale = Vector2(2,2)
			sheet.add_child(view)
			view.set_process(false)
	for direction in range(4):
		var label := Label.new()
		label.text = ["Frente","Costas","Esquerda","Direita"][direction]
		label.position = Vector2(14,164+170*direction)
		label.add_theme_color_override("font_color",Color("#283d29"))
		sheet.add_child(label)
	await process_frame
	await capture(output,"poses")
	sheet.queue_free()
	await process_frame
