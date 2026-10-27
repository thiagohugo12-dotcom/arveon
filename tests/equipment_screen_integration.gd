extends SceneTree

var failures := 0
var output := ""

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func(): push_error("EQUIPMENT_SCREEN_TIMEOUT"); quit(1))
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("EQUIPMENT_SCREEN_FAIL: " + description)
	else:
		print("EQUIPMENT_SCREEN_PASS: " + description)

func _frames(count := 4) -> void:
	for _index in range(count):
		await process_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(360, 800))
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	OS.set_environment("ARVEON_SAVE_PATH", "user://qa_equipment_screen_%d.json" % Time.get_ticks_usec())
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	var progress: GameProgress = main.progress
	for id: String in ["elmo_mata", "colete_mata", "luvas_mata", "botas_mata", "anel_mata", "colar_mata", "amuleto_mata"]:
		progress.equipment[id] = 0
		progress.equipment_rarities[id] = "comum"
		progress.equip(id)
	var weapon_uid := progress._create_weapon("espada", "comum")
	progress.equipment["espada"] = 0
	progress.equip_weapon_instance(weapon_uid)
	main.player.apply_progression(progress)
	var hud: GameHUD = main.hud
	main._toggle_character()
	await _frames()
	_check(hud.rpg_panel.visible and hud.rpg_panel.equipment_open_button != null, "existing character sheet exposes Equipment")
	hud.rpg_panel.equipment_open_button.pressed.emit()
	await _frames(8)
	_check(hud.equipment_screen.visible and main.input_driver.blocked, "approved screen opens as a modal from the real HUD")
	for slot: String in RPGRules.SLOTS:
		_check(hud.equipment_screen.find_child("EquipmentSlot_" + slot, true, false) is Button, "slot " + slot + " is interactive")
	var icon := hud.equipment_screen.find_child("OfficialItemSprite_Arma", true, false) as TextureRect
	_check(icon != null and icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "official item art retains nearest sampling and original proportions")
	var picture := root.get_texture().get_image()
	_check(picture.get_size() == Vector2i(360, 800), "capture is exactly 360x800")
	_check(picture.save_png(output.path_join("equipment-integrated-360x800.png")) == OK, "real project capture saved")
	progress.equipment_rarities["anel_mata"] = "mitico"
	hud.refresh_equipment_screen(progress)
	await _frames()
	var frame := hud.equipment_screen.find_child("RarityFrame_Anel", true, false) as Panel
	_check(frame != null and (frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color == MenuKit.rarity_color("mitico"), "mythic rarity is represented by the red slot border")
	progress.equipment_rarities["anel_mata"] = "comum"
	var save := hud.equipment_screen.find_child("SaveLoadout", true, false) as Button
	save.pressed.emit()
	await _frames()
	_check(progress.has_loadout(0), "SaveLoadout uses existing GameProgress storage")
	var saved_equipment := progress.equipment.duplicate(true)
	progress.unequip("Anel")
	hud.refresh_equipment_screen(progress)
	var apply := hud.equipment_screen.find_child("Loadout_1", true, false) as Button
	apply.pressed.emit()
	await _frames()
	_check(progress.equipped.Anel == "anel_mata" and progress.equipment == saved_equipment, "applying a loadout restores gear without duplicating items")
	var restored := GameProgress.new()
	restored.save_path = progress.save_path
	_check(restored.load_save() and restored.has_loadout(0), "saved loadout persists through the existing save format")
	var second := hud.equipment_screen.find_child("Loadout_2", true, false) as Button
	second.pressed.emit()
	await _frames()
	_check(hud.equipment_selected_set == 1, "second loadout can be selected")
	(hud.equipment_screen.find_child("SaveLoadout", true, false) as Button).pressed.emit()
	await _frames()
	_check(progress.has_loadout(1), "second loadout can be saved")
	var third := hud.equipment_screen.find_child("Loadout_3", true, false) as Button
	var touch := InputEventScreenTouch.new()
	touch.index = 22
	touch.position = third.get_global_rect().get_center()
	touch.pressed = true
	hud._input(touch)
	await _frames()
	_check(hud.equipment_selected_set == 2, "third loadout responds to a mobile screen touch")
	(hud.equipment_screen.find_child("SaveLoadout", true, false) as Button).pressed.emit()
	await _frames()
	_check(progress.has_loadout(2), "third loadout can be saved")
	hud.equipment_screen.navigation_requested.emit("personagem")
	await _frames()
	_check(not hud.equipment_screen.visible and hud.rpg_panel.visible and hud.rpg_panel.tab == 0, "Personagem returns to the existing character sheet")
	hud.rpg_panel.equipment_open_button.pressed.emit()
	await _frames()
	var slot_button := hud.equipment_screen.find_child("EquipmentSlot_Anel", true, false) as Button
	slot_button.pressed.emit()
	await _frames()
	_check(hud.inventory_open and not hud.equipment_screen.visible and hud.inventory_selected == "anel_mata", "slot opens the existing Backpack item details")
	var diary_equipment := hud.diary_navigation.get_child(1) as Button
	var open_touch := InputEventScreenTouch.new()
	open_touch.index = 23
	open_touch.position = diary_equipment.get_global_rect().get_center()
	open_touch.pressed = true
	hud._input(open_touch)
	await _frames()
	_check(hud.equipment_screen.visible and hud.inventory_open, "Diário opens the approved Equipment screen by mobile touch")
	hud.equipment_screen.navigation_requested.emit("mochila")
	await _frames()
	_check(hud.inventory_open and not hud.equipment_screen.visible, "Equipment returns to the existing Backpack")
	diary_equipment.pressed.emit()
	await _frames()
	hud.equipment_screen.navigation_requested.emit("habilidades")
	await _frames()
	_check(not hud.inventory_open and hud.rpg_panel.visible and hud.rpg_panel.tab == 3, "Equipment opens the existing abilities page")
	print("EQUIPMENT_SCREEN_RESULT: failures=", failures, " capture=", output.path_join("equipment-integrated-360x800.png"))
	quit(0 if failures == 0 else 1)
