extends SceneTree
func _initialize() -> void:
	create_timer(20).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	var atlas := Image.create(640,320,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(80,80)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var rig := preload("res://tools/melee_pose_rig.gd").new()
	rig.position = Vector2(40,52)
	viewport.add_child(rig)
	for kind in range(2):
		rig.weapon_kind = kind
		atlas.fill(Color.TRANSPARENT)
		for row in range(4):
			rig.row = row
			for frame in range(8):
				rig.frame = frame
				rig.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var cell := viewport.get_texture().get_image()
				cell.convert(Image.FORMAT_RGBA8)
				atlas.blit_rect(cell,Rect2i(0,0,80,80),Vector2i(frame*80,row*80))
		var folder := "axe_demo_v1" if kind == 0 else "spear_demo_v1"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/"+folder))
		var error := atlas.save_png("res://assets/art/"+folder+"/attack.png")
		print("MELEE_BAKE: ",folder," 8 x 4 poses; result ",error)
		if error != OK: quit(1); return
	viewport.queue_free()
	await process_frame
	quit(0)
