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

func _tap(hud: GameHUD, button: Button, index := 27) -> void:
	var press := InputEventScreenTouch.new()
	press.index = index
	press.position = button.get_global_rect().get_center()
	press.pressed = true
	hud._input(press)
	var release := InputEventScreenTouch.new()
	release.index = index
	release.position = press.position
	release.pressed = false
	hud._input(release)

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
	progress.equipment["anel_vale"] = 0
	progress.equipment_rarities["anel_vale"] = "raro"
	progress.bag["Ervas"] = 14
	progress.bag["Madeira"] = 12
	progress.bag["Pedras"] = 9
	main.player.apply_progression(progress)
	var hud: GameHUD = main.hud
	main._toggle_character()
	await _frames()
	_check(hud.rpg_panel.visible and hud.rpg_panel.equipment_open_button != null, "existing character sheet exposes Equipment")
	hud.rpg_panel.equipment_open_button.pressed.emit()
	await _frames(8)
	_check(hud.equipment_screen.visible and main.input_driver.blocked, "approved screen opens as a modal from the real HUD")
	_check(hud.equipment_screen.find_child("CloseDetails", true, false) == null and hud.equipment_screen.bag_scroll.size.y > 300, "details stay hidden until an item is selected")
	var defense_value := hud.equipment_screen.find_child("StatValue_Defesa", true, false) as Label
	var more_button := hud.equipment_screen.find_child("MoreAttributes", true, false) as Button
	_check(defense_value != null and more_button != null and defense_value.get_global_rect().end.x + 4 <= more_button.get_global_rect().position.x, "compact stats do not collide with More")
	_check(root.get_texture().get_image().save_png(output.path_join("equipment-populated-360x800.png")) == OK, "populated screen capture saved")
	for slot: String in RPGRules.SLOTS:
		_check(hud.equipment_screen.find_child("EquipmentSlot_" + slot, true, false) is Button, "slot " + slot + " is interactive")
	var icon := hud.equipment_screen.find_child("OfficialItemSprite_Arma", true, false) as TextureRect
	_check(icon != null and icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "official item art retains nearest sampling and original proportions")
	(hud.equipment_screen.find_child("BagItem_anel_vale", true, false) as Button).pressed.emit()
	await _frames()
	var picture := root.get_texture().get_image()
	_check(picture.get_size() == Vector2i(360, 800), "capture is exactly 360x800")
	_check(picture.save_png(output.path_join("equipment-integrated-360x800.png")) == OK, "real project capture saved")
	_check(picture.save_png(output.path_join("equipment-item-selected-360x800.png")) == OK, "selected item detail capture saved")
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
	_check((hud.equipment_screen.find_child("SaveLoadout", true, false) as Button).text == "Salvar", "loadout save control has a readable label")
	_check((hud.equipment_screen.find_child("Loadout_2", true, false) as Button).tooltip_text.contains("vazio"), "empty loadout has an explicit state")
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
	_check((hud.equipment_screen.find_child("Loadout_2", true, false) as Button).tooltip_text.contains("salvo"), "saved loadout has an explicit state")
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
	hud.equipment_screen.close_requested.emit()
	await _frames()
	_check(not hud.equipment_screen.visible and not hud.rpg_panel.visible, "X closes the combined screen and its underlying panel")
	main._toggle_inventory()
	await _frames()
	_check(hud.equipment_screen.visible and main.input_driver.blocked, "HUD Backpack button opens the combined screen")
	var caption := hud.equipment_screen.find_child("SlotCaption_Anel", true, false) as Label
	var icon_frame := hud.equipment_screen.find_child("RarityFrame_Anel", true, false) as Panel
	var nameplate := hud.equipment_screen.find_child("SlotNameplate_Anel", true, false) as TextureRect
	_check(caption != null and icon_frame != null and nameplate != null and nameplate.position.y >= icon_frame.position.y + icon_frame.size.y, "slot nameplate sits below the frame")
	progress.bag["Ervas"] = 14
	hud.refresh_equipment_screen(progress)
	var badge := hud.equipment_screen.find_child("QuantityBadge_Ervas", true, false) as Panel
	_check(badge != null and badge.position.y + badge.size.y <= 57, "quantity stays within its item square")
	progress.equipment["anel_vale"] = 0
	progress.equipment_rarities["anel_vale"] = "raro"
	hud.refresh_equipment_screen(progress)
	(hud.equipment_screen.find_child("BagItem_anel_vale", true, false) as Button).pressed.emit()
	var equip_button := hud.equipment_screen.find_child("PrimaryAction", true, false) as Button
	_check(equip_button != null and equip_button.text == "Equipar", "Bag detail exposes the real equip action")
	if equip_button != null: equip_button.pressed.emit()
	await _frames()
	_check(progress.equipped.Anel == "anel_vale", "equipping from the combined screen updates GameProgress")
	progress.gold = 10000
	(hud.equipment_screen.find_child("ExpandBag", true, false) as Button).pressed.emit()
	(hud.equipment_screen.find_child("ExpandGold", true, false) as Button).pressed.emit()
	await _frames()
	_check(progress.bag_capacity() == 50 and progress.gold == 9500, "bag expansion uses the existing gold cost")
	hud.equipment_screen.close_requested.emit()
	await _frames()
	_check(not hud.equipment_screen.visible and not main.input_driver.blocked, "X returns control to the game")
	var fresh := GameProgress.new()
	fresh.begin_new_character()
	hud.equipment_screen.active_filter = "Todos"
	hud.equipment_screen.target_slot = ""
	hud.equipment_screen.selected_id = ""
	hud.equipment_screen.selected_kind = ""
	hud.equipment_screen.details_open = true
	hud.equipment_screen.expansion_open = false
	hud.equipment_screen.attributes_open = false
	hud.equipment_screen.present(fresh, 100, 100)
	hud.equipment_screen.show()
	await _frames()
	var empty_hint := hud.equipment_screen.find_child("EmptyBagHint", true, false) as Label
	_check(empty_hint != null and empty_hint.text.contains("Ferreiro"), "new characters see the reason for an empty bag")
	_check(hud.equipment_screen.find_child("CloseDetails", true, false) == null and hud.equipment_screen.bag_scroll.size.y > 300, "new character has no large empty detail panel")
	_check((hud.equipment_screen.find_child("SaveLoadout", true, false) as Button).disabled, "loadout saving is visibly unavailable during introduction")
	_check(root.get_texture().get_image().save_png(output.path_join("equipment-new-character-360x800.png")) == OK, "new character mobile capture saved")
	(hud.equipment_screen.find_child("MoreAttributes", true, false) as Button).pressed.emit()
	await _frames()
	_check(root.get_texture().get_image().save_png(output.path_join("equipment-attributes-360x800.png")) == OK, "attributes mobile capture saved")
	var selected_before := hud.equipment_screen.selected_set
	_tap(hud, hud.equipment_screen.find_child("Loadout_2", true, false) as Button)
	await _frames()
	_check(hud.equipment_screen.attributes_open and hud.equipment_screen.selected_set == selected_before, "mobile touch cannot pass through attributes modal")
	_tap(hud, hud.equipment_screen.find_child("CloseAttributes", true, false) as Button)
	await _frames()
	_check(not hud.equipment_screen.attributes_open, "attributes modal closes by mobile touch")
	for material in GameProgress.ITEMS: progress.bag[material] = 2
	hud.equipment_screen.present(progress, 100, 100)
	await _frames()
	var scroll := hud.equipment_screen.bag_scroll
	var scroll_press := InputEventScreenTouch.new()
	scroll_press.index = 28
	scroll_press.position = scroll.get_global_rect().get_center()
	scroll_press.pressed = true
	hud._input(scroll_press)
	var drag := InputEventScreenDrag.new()
	drag.index = 28
	drag.position = scroll_press.position + Vector2(0, -95)
	drag.relative = Vector2(0, -95)
	hud._input(drag)
	var scroll_release := InputEventScreenTouch.new()
	scroll_release.index = 28
	scroll_release.position = drag.position
	scroll_release.pressed = false
	hud._input(scroll_release)
	await _frames()
	_check(scroll.scroll_vertical > 0, "mobile drag scrolls populated bag without selecting a tile")
	_tap(hud, hud.equipment_screen.find_child("Filter_Materiais", true, false) as Button)
	await _frames()
	_check(hud.equipment_screen.active_filter == "Materiais" and hud.equipment_screen.find_child("BagItem_anel_vale", true, false) == null, "mobile material filter excludes equipment")
	_tap(hud, hud.equipment_screen.find_child("Filter_Todos", true, false) as Button)
	await _frames()
	_tap(hud, hud.equipment_screen.find_child("BagItem_anel_vale", true, false) as Button)
	await _frames()
	_check(hud.equipment_screen.selected_id == "anel_vale" and hud.equipment_screen.find_child("PrimaryAction", true, false) != null, "mobile tile selection opens real item details")
	print("EQUIPMENT_SCREEN_RESULT: failures=", failures, " capture=", output.path_join("equipment-integrated-360x800.png"))
	quit(0 if failures == 0 else 1)
