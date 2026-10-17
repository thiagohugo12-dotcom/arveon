extends SceneTree
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	var output := ProjectSettings.globalize_path("res://assets/art/local_combat_review")
	DirAccess.make_dir_recursive_absolute(output)
	var vp := SubViewport.new()
	vp.size = Vector2i(80,80)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(vp)
	for id in ["estocada_precisa","guarda_reativa","danca_laminas","guardiao"]:
		var boss: bool = id == "guardiao"
		var rig: Node2D = preload("res://tools/local_guardian_pose_rig.gd").new() if boss else preload("res://tools/local_technique_pose_rig.gd").new()
		if not boss:
			rig.position = Vector2(40,52)
			rig.technique_id = id
		vp.add_child(rig)
		rig.set_process(false)
		var count := 8 if boss else 6
		var atlas := Image.create(count*80,320,false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for row in range(4):
			rig.row = row
			for frame in range(count):
				rig.frame = frame
				rig.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var cell := vp.get_texture().get_image()
				cell.convert(Image.FORMAT_RGBA8)
				atlas.blit_rect(cell,Rect2i(0,0,80,80),Vector2i(frame*80,row*80))
		var error := atlas.save_png(output.path_join(id+".png"))
		print("LOCAL_REVIEW_BAKE: ",id," ",count,"x4 frames error=",error)
		rig.queue_free()
		await process_frame
	# Enemy attack sheets preserve source pixels, with new head/leg/arm poses.
	vp.size = Vector2i(48,48)
	var enemy_rig := preload("res://tools/local_enemy_pose_rig.gd").new()
	enemy_rig.position = Vector2(24,32)
	vp.add_child(enemy_rig)
	var enemies := Image.create(288,576,false,Image.FORMAT_RGBA8)
	enemies.fill(Color.TRANSPARENT)
	for kind in range(3):
		enemy_rig.kind = kind
		for row in range(4):
			enemy_rig.row = row
			for frame in range(6):
				enemy_rig.frame = frame
				enemy_rig.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var cell := vp.get_texture().get_image()
				cell.convert(Image.FORMAT_RGBA8)
				enemies.blit_rect(cell,Rect2i(0,0,48,48),Vector2i(frame*48,(kind*4+row)*48))
	print("LOCAL_REVIEW_BAKE: enemy attacks result=",enemies.save_png(output.path_join("enemy_attacks.png")))
	vp.queue_free()
	await process_frame
	quit()
