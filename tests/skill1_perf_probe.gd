extends SceneTree
func _initialize() -> void:
	create_timer(45).timeout.connect(func(): quit(1))
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(390,844)
	root.content_scale_size = root.size
	var demo := preload("res://scenes/demos/skill1_review.tscn").instantiate()
	root.add_child(demo)
	demo.set_inspection_mode(false)
	var maximum_projectiles := 0
	var maximum_growth := 0
	var draw_calls := 0
	var total_process := 0.0
	var sampled := 0
	for category: String in preload("res://scripts/demos/skill1_catalogue.gd").ORDER:
		demo.select_category(category)
		var baseline_nodes := get_node_count()
		for frame in range(120):
			await process_frame
			maximum_projectiles = maxi(maximum_projectiles,get_nodes_in_group("player_projectiles").size())
			maximum_growth = maxi(maximum_growth,get_node_count()-baseline_nodes)
			draw_calls = maxi(draw_calls,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
			total_process += Performance.get_monitor(Performance.TIME_PROCESS)*1000
			sampled += 1
	var failures := 0 if maximum_projectiles <= PlayerProjectile.MAX_ACTIVE and maximum_growth <= PlayerProjectile.MAX_ACTIVE else 1
	print("SKILL1_PERF_RESULT: %d frames, max_projectiles %d, node_growth %d, peak_draw_calls %d, avg_process_ms %.3f, %d failures" % [sampled,maximum_projectiles,maximum_growth,draw_calls,total_process/maxi(1,sampled),failures])
	demo.queue_free()
	await process_frame
	quit(failures)
