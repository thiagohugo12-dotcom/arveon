extends SceneTree
func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	var category := OS.get_environment("SKILL1_CATEGORY")
	if category.is_empty(): category = "espada"
	var script_path := "res://tools/skill1_%s_rig.gd" % {"espada":"sword","machado":"axe","lanca":"spear","arco":"bow","cajado":"staff"}[category]
	var rig: Node2D = load(script_path).new()
	rig.category = category
	var viewport := SubViewport.new()
	var cell_size := 112 if category=="lanca" else 80
	var anchor := Vector2(56,64) if category=="lanca" else Vector2(40,52)
	viewport.size = Vector2i(cell_size,cell_size)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	rig.position = anchor
	viewport.add_child(rig)
	var error := OK
	for upper_only in [false,true]:
		rig.include_legs = not upper_only
		var atlas := Image.create(cell_size*8,cell_size*4,false,Image.FORMAT_RGBA8)
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
				atlas.blit_rect(cell,Rect2i(0,0,cell_size,cell_size),Vector2i(frame*cell_size,row*cell_size))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/skills1_v1"))
		error = atlas.save_png("res://assets/art/skills1_v1/"+category+("_upper" if upper_only else "")+".png")
		print("SKILL1_BAKE: ",category," upper=",upper_only," result ",error," max arm span ",rig.max_arm_span)
	viewport.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
