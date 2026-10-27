extends SceneTree

var failures := 0

func _initialize() -> void:
	create_timer(45.0).timeout.connect(func(): push_error("MOBILE_LAYOUT_TIMEOUT"); quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MOBILE_LAYOUT_FAIL: " + message)
	else:
		print("MOBILE_LAYOUT_PASS: " + message)

func _frames() -> void:
	for _index in range(6):
		await process_frame
	await RenderingServer.frame_post_draw

func _inside_x(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 1.0 and inner.end.x <= outer.end.x + 1.0

func _run() -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	var progress := GameProgress.new()
	progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var hud := GameHUD.new()
	root.add_child(hud)
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(360, 800), Vector2i(390, 844), Vector2i(844, 390)]:
		root.size = resolution
		root.content_scale_size = resolution
		hud.size = Vector2(resolution)
		hud._layout()
		var bounds := Rect2(Vector2.ZERO, Vector2(resolution))
		var prefix := "%dx%d" % [resolution.x, resolution.y]
		hud.show_inventory(progress)
		await _frames()
		_check(bounds.encloses(hud.inventory_panel.get_global_rect()), "Diário cabe em " + prefix)
		var equipment_entry := hud.diary_navigation.get_child(1) as Button
		_check(equipment_entry.text == "Equipamento" and _inside_x(hud.inventory_panel.get_global_rect(), equipment_entry.get_global_rect()), "entrada de Equipamento visível em " + prefix)
		var touch := InputEventScreenTouch.new()
		touch.index = 17
		touch.position = equipment_entry.get_global_rect().get_center()
		touch.pressed = true
		hud._input(touch)
		await _frames()
		_check(hud.equipment_screen.visible and bounds.encloses(hud.equipment_screen.get_global_rect()), "toque abre tela nova inteira em " + prefix)
		if not output.is_empty() and resolution == Vector2i(360, 640):
			_check(root.get_texture().get_image().save_png(output.path_join("equipamento-mobile-360x640.png")) == OK, "captura mobile real")
		hud._equipment_navigation("mochila")
		_check(hud.inventory_open and hud.inventory_panel.visible, "retorno à Mochila em " + prefix)
		hud.close_inventory()
		hud.show_station("Ferreiro", progress)
		await _frames()
		_check(bounds.encloses(hud.station_panel.get_global_rect()), "Ferreiro cabe em " + prefix)
		for tab in hud.station_tab_host.get_children():
			_check(_inside_x(hud.station_panel.get_global_rect(), (tab as Control).get_global_rect()), "aba do Ferreiro visível em " + prefix)
		for button in hud.smith_pick_buttons.values():
			_check(_inside_x(hud.station_scroll.get_global_rect(), (button as Control).get_global_rect()), "arma/receita sem corte lateral em " + prefix)
		if not output.is_empty() and resolution == Vector2i(360, 640):
			_check(root.get_texture().get_image().save_png(output.path_join("ferreiro-mobile-360x640.png")) == OK, "captura do Ferreiro")
		hud.close_station()
		hud.show_station("Vendedor", progress)
		await _frames()
		_check(bounds.encloses(hud.station_panel.get_global_rect()), "Vendedor cabe em " + prefix)
		hud.close_station()
		hud.show_station("Baú", progress)
		await _frames()
		_check(bounds.encloses(hud.station_panel.get_global_rect()), "Baú cabe em " + prefix)
		hud.close_station()
		hud.rpg_panel.tab = 3
		hud.rpg_panel.show()
		hud.rpg_panel.refresh(progress)
		hud._layout()
		await _frames()
		_check(bounds.encloses(hud.rpg_panel.get_global_rect()), "Evolução cabe em " + prefix)
		_check(_inside_x(hud.rpg_panel.get_global_rect(), hud.rpg_panel.equipment_open_button.get_global_rect()), "atalho de Equipamento cabe em Evolução " + prefix)
		hud.rpg_panel.hide()
	print("MOBILE_LAYOUT_RESULT: failures=", failures)
	quit(1 if failures > 0 else 0)
