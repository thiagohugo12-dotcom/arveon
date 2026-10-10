extends SceneTree

var output := ""
var failures := 0

class MapEvidence extends Node2D:
	func _draw() -> void:
		var gold := Color("#ffe09a")
		var font := ThemeDB.fallback_font
		draw_polyline(PackedVector2Array([SafeCamp.RESPAWN, Vector2(720, 445), Vector2(880, 485), TowerEntrance.POSITION]), gold, 3.0)
		draw_circle(SafeCamp.RESPAWN, 12, gold, false, 3.0)
		draw_circle(TowerEntrance.POSITION, 13, gold, false, 3.0)
		draw_circle(Vector2(600, 280), 10, Color("#c7d4cb"), false, 2.0)
		draw_string(font, Vector2(620, 285), "Posição anterior", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e2e9e2"))
		draw_string(font, Vector2(490, 585), "Vila / acampamento", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, gold)
		draw_string(font, Vector2(925, 338), "Torre — extremidade leste", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, gold)
		draw_rect(Rect2(270, 810, 660, 64), Color("#162b25"))
		draw_string(font, Vector2(290, 835), "Mapa original: 1200 × 900 — linha amarela: trilha existente", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, gold)
		draw_string(font, Vector2(290, 860), "Distância direta à vila: antes 180 px / depois 590 px", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, gold)

func _initialize() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("TOWER_QA_FAIL: " + message)

func _frames() -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _frames()
	var frame := root.get_texture().get_image()
	_check(frame.save_png(output.path_join(name + ".png")) == OK, name + " screenshot saved")
	if name == "tower_390x844_unlocked" or name == "tower_640x360_unlocked" or name == "tower_390x844_locked23":
		print("TOWER_REVIEW_%s=%s" % [name, Marshalls.raw_to_base64(frame.save_jpg_to_buffer(0.8))])

func _tap(button: TouchActionButton) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 92
	touch.pressed = true
	touch.position = button.get_global_rect().get_center()
	button._input(touch)
	touch.pressed = false
	button._input(touch)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_tower_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH", path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	for enemy in get_nodes_in_group("damageable_enemies"):
		enemy.queue_free()
	await _frames()
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(960, 540)]:
		root.size = resolution
		await _frames()
		main.player.position = TowerEntrance.POSITION + Vector2(-30, 30)
		main.hud.loot_label.hide()
		main.hud.notice_left = 0.0
		var prefix := "tower_%dx%d_" % [resolution.x, resolution.y]
		main.progress.ascension.defeats["1"] = 0
		main._process(0.0)
		_check(main.hud.interact_button.enabled and main.hud.interact_button.caption.text.contains("0/50"), "contextual progress and interaction appear near tower")
		await _capture(prefix + "new")
		for count in [23, 49]:
			main.progress.ascension.defeats["1"] = count
			main._process(0.0)
			_tap(main.hud.interact_button)
			_check(not main.hud.station_panel.visible and main.hud.loot_label.text.contains("%d/50" % count), "locked touch shows current progress")
			# Keep transient notice visible only for evidence capture.
			main.hud.set_process(false)
			await _capture(prefix + "locked%d" % count)
			main.hud.set_process(true)
		main.progress.ascension.defeats["1"] = 50
		main._process(0.0)
		main.hud.loot_label.hide()
		_tap(main.hud.interact_button)
		await _frames()
		_check(main.hud.station_panel.visible and main.input_driver.blocked, "touch opens unlocked tower")
		_check(main.hud.station_content.get_child_count() == 5, "preview contains information only")
		_check(main.hud.station_scroll.get_v_scroll_bar().max_value <= main.hud.station_scroll.size.y + 1.0, "preview content fits without scrolling at " + str(resolution))
		_check(main.hud.station_panel.get_global_rect().encloses(main.hud.station_close_button.get_global_rect()), "close target stays inside panel")
		await _capture(prefix + "unlocked")
		var touch := InputEventScreenTouch.new()
		touch.index = 93
		touch.pressed = true
		touch.position = main.hud.station_close_button.get_global_rect().get_center()
		main.hud._input(touch)
		touch.pressed = false
		main.hud._input(touch)
		main._process(0.0)
		_check(not main.hud.station_panel.visible and not main.input_driver.blocked and main.hud.dash_button.enabled, "close resumes existing controls")
		await _capture(prefix + "closed")
		if resolution == Vector2i(390, 844):
			main._toggle_map()
			_check(main.hud.map_panel.visible and main.input_driver.blocked, "touch map retains eastern player location and menu input lock")
			await _capture(prefix + "map")
			main._toggle_map()
	# QA-only overview: native scene with annotations, never included in gameplay.
	root.size_changed.disconnect(main._adapt_orientation)
	root.size = Vector2i(1200, 900)
	await _frames()
	root.content_scale_size = Vector2i(1200, 900)
	main.hud.hide()
	main.player.position = SafeCamp.RESPAWN
	var camera := main.player.get_node("Camera2D") as Camera2D
	camera.zoom = Vector2.ONE
	camera.position = Vector2(600, 450) - main.player.position
	camera.reset_smoothing()
	var evidence := MapEvidence.new()
	main.add_child(evidence)
	await _capture("tower_overview")
	_check(root.content_scale_size == Vector2i(1200, 900), "overview shows entire original map at one pixel per world unit")
	var file := FileAccess.open(output.path_join("tower-result.txt"), FileAccess.WRITE)
	file.store_line("TOWER_QA_RESULT: %d failures" % failures)
	file.close()
	print("TOWER_QA_RESULT: %d failures" % failures)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	quit(1 if failures > 0 else 0)
