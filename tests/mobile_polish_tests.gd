extends RefCounted

static func tap(hud: GameHUD, button: Button, index: int = 42) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.pressed = true
	touch.position = button.get_global_rect().get_center()
	hud._input(touch)
	touch.pressed = false
	hud._input(touch)

static func run(suite, main) -> void:
	main.set_process(false)
	var hud: GameHUD = main.hud
	var player: PlayerActor = main.player
	player.set_physics_process(false)
	player.health.initialize(player.stats.max_hp)
	player.position = SafeCamp.RESPAWN
	hud.restart.hide()
	hud.close_inventory()
	hud.close_character()
	hud.close_map()
	hud.close_station()
	main.input_driver.blocked = false
	var discoveries: Dictionary = main.progress.discovered_pois.duplicate()
	var caches: Dictionary = main.progress.opened_caches.duplicate()
	for resolution: Vector2i in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(640, 360), Vector2i(960, 540)]:
		suite.root.size = resolution
		suite.root.content_scale_size = resolution
		await suite.frames()
		hud.size = Vector2(resolution)
		hud._layout()
		await suite.frames()
		var bounds := Rect2(Vector2.ZERO, hud.size)
		var buttons: Array[Control] = [hud.inventory_button, hud.character_button, hud.map_button, hud.actions[0], hud.actions[1], hud.actions[2], hud.dash_button, hud.joystick]
		var valid := true
		for i in range(buttons.size()):
			var rect := buttons[i].get_rect()
			valid = valid and bounds.encloses(rect) and rect.size.x >= 44 and rect.size.y >= 44
			for j in range(i + 1, buttons.size()):
				valid = valid and not rect.intersects(buttons[j].get_rect())
		suite.check(valid, "touch targets within viewport and mutually separated %s" % resolution)
		suite.check(not hud.actions[3].visible and not hud.actions[4].visible and hud.inventory_button.position.y == hud.character_button.position.y and hud.character_button.position.y == hud.map_button.position.y, "four combat buttons and three top menu icons %s" % resolution)
		var passive_safe := true
		for panel in [hud.info_back, hud.mission_back, hud.minimap]:
			for button in buttons:
				passive_safe = passive_safe and not panel.get_rect().intersects(button.get_rect())
		suite.check(passive_safe and hud.info_back.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.mission_back.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HUD avoids control hitboxes and ignores touches %s" % resolution)
		var text_fits := hud.mission_label.get_line_count() * hud.mission_label.get_line_height() <= hud.mission_label.size.y
		suite.check(text_fits and hud.progress_label.get_theme_font("font").get_string_size(hud.progress_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= hud.progress_label.size.x, "mission and XP text fit compact panels %s" % resolution)
		for menu in ["bag", "character", "map"]:
			var button: Button = {"bag": hud.inventory_button, "character": hud.character_button, "map": hud.map_button}[menu]
			tap(hud, button)
			await suite.frames()
			var panel: Control = {"bag": hud.inventory_panel, "character": hud.rpg_panel, "map": hud.map_panel}[menu]
			var close: Button = {"bag": hud.inventory_close, "character": hud.rpg_panel.close_button, "map": hud.map_close}[menu]
			suite.check(panel.visible and main.input_driver.blocked and not hud.joystick.is_processing_input() and not hud.dash_button.enabled, "%s touch menu blocks combat %s" % [menu, resolution])
			suite.check(bounds.encloses(panel.get_rect()) and panel.get_global_rect().encloses(close.get_global_rect()) and close.size.y >= 44, "%s panel and close button fit %s" % [menu, resolution])
			tap(hud, close)
			suite.check(not panel.visible and not main.input_driver.blocked and hud.joystick.is_processing_input() and hud.dash_button.enabled, "%s touch close restores controls %s" % [menu, resolution])
		# Two fingers outside protected camp: movement and independent skill activation.
		player.position = Vector2(100, 100)
		var move := InputEventScreenTouch.new()
		move.index = 50
		move.pressed = true
		move.position = hud.joystick.get_global_rect().get_center() + Vector2(30, 0)
		hud.joystick._input(move)
		suite.check(main.input_driver.touch_direction.x > 0.0, "joystick movement reaches driver %s" % resolution)
		for i in range(3):
			player.charge_left = 0.0
			player.skill_cooldowns[i] = 0.0
			hud.set_rpg_status(main.progress, player)
			var skill := InputEventScreenTouch.new()
			skill.index = 51
			skill.pressed = true
			skill.position = hud.actions[i].get_global_rect().get_center()
			hud.actions[i]._input(skill)
			suite.check(player.skill_cooldowns[i] > 0.0 and hud.actions[i].recharge > 0.0 and hud.actions[i].caption.text.ends_with("s"), "skill %d touch activates with cooldown feedback %s" % [i, resolution])
			skill.pressed = false
			hud.actions[i]._input(skill)
		move.pressed = false
		hud.joystick._input(move)
		suite.check(main.input_driver.touch_direction == Vector2.ZERO, "joystick release stops motion %s" % resolution)
	suite.check(main.progress.discovered_pois == discoveries and main.progress.opened_caches == caches, "map browsing cannot reveal unexplored objects")
	var p := GameProgress.new()
	p.xp = 50
	hud.set_rpg_status(p, player)
	suite.check(hud.character_button.notification, "available attribute points light character notification")
	p.allocate_attribute("Força")
	p.allocate_attribute("Vitalidade")
	hud.set_rpg_status(p, player)
	suite.check(not hud.character_button.notification, "spent attribute points clear character notification")
	for i in range(3):
		player.skill_cooldowns[i] = 0.0
	hud.set_rpg_status(p, player)
	suite.check(hud.actions[0].caption.text.is_empty() and hud.actions[1].caption.text.is_empty() and hud.actions[2].caption.text.is_empty(), "ready touch skills show icons without keyboard numbers")
	main._toggle_map()
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	main._input(escape)
	suite.check(not hud.map_panel.visible and not main.input_driver.blocked, "Escape closes map and releases input")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_M
	main._input(key)
	suite.check(hud.map_panel.visible and main.input_driver.blocked, "M keyboard shortcut opens map")
	main._input(key)
	suite.check(not hud.map_panel.visible and not main.input_driver.blocked, "M keyboard shortcut closes map")
	var path: String = main.progress.save_path + ".v031"
	main.progress.save_path = path
	suite.check(main.progress.save(), "v0.3.0 progress saves with v0.3.1 UI")
	var before := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	var restored := GameProgress.new()
	restored.save_path = path
	suite.check(restored.load_save() and restored.save(), "v0.3.0 save loads and saves without migration loss")
	var after := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	suite.check(before == after and int(after.version) == GameProgress.SAVE_VERSION, "UI roundtrip preserves every current save field")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
