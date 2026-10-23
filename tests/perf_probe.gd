extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _count(node: Node, counts: Dictionary) -> void:
	counts.nodes += 1
	if node is CollisionShape2D:
		counts.colliders += 1
	for child in node.get_children():
		_count(child, counts)

func _run() -> void:
	OS.set_environment("ARVEON_SAVE_PATH", "user://perf_probe.json")
	var start := Time.get_ticks_usec()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in range(5):
		await process_frame
	var counts := {"nodes": 0, "colliders": 0}
	_count(main, counts)
	print("PERF_PROBE: startup_ms=%.2f nodes=%d colliders=%d static_kib=%.1f" % [float(Time.get_ticks_usec() - start) / 1000.0, counts.nodes, counts.colliders, Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0])
	main.queue_free()
	await process_frame
	quit(0)
