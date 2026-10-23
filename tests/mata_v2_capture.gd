extends SceneTree
var output := ""
var checks := 0
var failures := 0
func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("MATA_V2_FAIL: "+message)
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png")) == OK,name)
func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_mata_v2_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	var view: FloorView = main.world.get_node("FloorView")
	var anchors := view.tree_positions()
	var walls: StaticBody2D = main.world.get_node("Walls")
	var shapes := walls.get_child_count()
	var global_items: Dictionary = main.progress.bag.duplicate(true)
	check(view.visual_v2 and main.tower_view.visual_v2 and main.exploration_view.visual_v2,"floor one is V2")
	view.set_visual_v2(false)
	check(not view.visual_v2 and view.tree_positions() == anchors and walls.get_child_count() == shapes,"theme changes no tree/collision")
	view.set_visual_v2(true)
	main.progress.ascension.defeats["1"] = 50
	main.progress.ascension.complete_forest_trial()
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		root.size = resolution
		for place: String in ["acampamento","trilha","torre"]:
			main.player.position = {"acampamento":Vector2(560,445),"trilha":Vector2(870,430),"torre":Vector2(1110,495)}[place]
			main.hud.minimap.player_position = main.player.position
			main.tower_view.set_state(true,place == "torre")
			await capture("mata_v2_%dx%d_%s" % [resolution.x,resolution.y,place])
		await main._travel_floor(2)
		check(not (main.world.get_node("FloorView") as FloorView).visual_v2 and not main.tower_view.visual_v2 and not main.exploration_view.visual_v2,"floor two retains original")
		check((main.world.get_node("Walls") as StaticBody2D).get_child_count() == shapes and main.progress.bag == global_items,"travel preserves geometry and inventory")
		main.player.position = Vector2(870,430)
		for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
		await capture("mata_v2_%dx%d_andar2_original" % [resolution.x,resolution.y])
		await main._travel_floor(1)
		for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
		check((main.world.get_node("FloorView") as FloorView).visual_v2 and (main.world.get_node("FloorView") as FloorView).tree_positions() == anchors,"return restores only floor one theme")
	for floor_id in range(2,5):
		await main._travel_floor(floor_id)
		main.progress.ascension.defeats[str(floor_id)] = 50
		main.progress.ascension.complete_forest_trial()
		await main._travel_floor(floor_id+1)
		check(not (main.world.get_node("FloorView") as FloorView).visual_v2 and not main.tower_view.visual_v2 and not main.exploration_view.visual_v2,"floors three to five unchanged")
	await main._travel_floor(1)
	check((main.world.get_node("FloorView") as FloorView).visual_v2,"floor one restored after all five floors")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("MATA_V2_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
