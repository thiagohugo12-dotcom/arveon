extends SceneTree
## Reproducible code-native bake from approved art. No original pixels edited.
## Rasterize at one source pixel in an 80x80 cell; runtime scales 2x with NEAREST.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var atlas := Image.create(480,320,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(80,80)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var rig := preload("res://tools/sword_pose_rig.gd").new()
	rig.village_scale = true
	rig.position = Vector2(40,52)
	rig.scale = Vector2(0.5,0.5)
	viewport.add_child(rig)
	rig.set_process(false)
	for row in range(4):
		rig.sword_row = row
		for frame in range(6):
			rig.pose_override = mini(frame,3)
			if frame >= 3: rig.bake_release = [0.25,0.65,1.0][frame-3]
			rig.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var cell := viewport.get_texture().get_image()
			cell.convert(Image.FORMAT_RGBA8)
			atlas.blit_rect(cell,Rect2i(0,0,80,80),Vector2i(frame*80,row*80))
	var output := ProjectSettings.globalize_path("res://assets/art/sword_demo_v1")
	DirAccess.make_dir_recursive_absolute(output)
	var error := atlas.save_png(output.path_join("attack.png"))
	viewport.queue_free()
	await process_frame
	print("SWORD_BAKE: 6 aligned frames x 4 directions; 80x80 cells; feet (40,52); result ",error)
	quit(0 if error == OK else 1)
