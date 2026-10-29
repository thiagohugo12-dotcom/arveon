extends SceneTree
var failures := 0
var checks := 0
var output := ""
func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("SAMPLE_FAIL: " + message)
func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var demo := (load("res://scenes/demos/mata_art_sample.tscn") as PackedScene).instantiate()
	root.add_child(demo)
	await process_frame
	check(demo.player.view.appearance == 0,"existing Explorer")
	var original := FloorView.new()
	var anchors := original.tree_positions()
	original.free()
	check(demo.TREE_FEET.all(func(point: Vector2): return anchors.has(point)),"existing tree anchors")
	check(demo.AREA.end.x <= 1200 and demo.AREA.end.y <= 900,"inside actual map")
	check(not root.has_node("Main"),"isolated from saves and Main")
	var start: Vector2 = demo.player.position
	demo.driver.set_touch_direction(Vector2.RIGHT)
	for i in range(12): await physics_frame
	demo.driver.reset()
	check(demo.player.position.x > start.x+15,"same movement driver")
	demo.player.position = Vector2(811,396)
	demo.driver.set_touch_direction(Vector2.UP)
	for i in range(20): await physics_frame
	demo.driver.reset()
	check(demo.player.position.y >= 384,"existing trunk footprint blocks walking")
	demo.player.position = start
	demo.dash_button.activated.emit()
	await physics_frame
	await physics_frame
	check(demo.player.dash.active(),"existing touch Dash")
	demo.driver.reset()
	demo.player.dash.time_left = 0
	demo.player.set_physics_process(false)
	demo.player.position = start
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		root.size = resolution
		root.content_scale_size = resolution
		for i in range(5): await process_frame
		check(demo.joystick.get_global_rect().end.y <= resolution.y,"joystick on screen")
		check(demo.dash_button.get_global_rect().end.x <= resolution.x,"dash on screen")
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(output.path_join("sample_%dx%d.png" % [resolution.x,resolution.y])) == OK,"real capture")
	demo.queue_free()
	await process_frame
	print("SAMPLE_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
