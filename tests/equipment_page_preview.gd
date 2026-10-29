extends SceneTree

var checks := 0
var failures := 0
var progress: GameProgress
var selected_set := 0
var tapped_slot := ""
var page: PanelContainer

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		push_error("EQUIPMENT_PAGE_TIMEOUT")
		quit(1)
	)
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("EQUIPMENT_PAGE_FAIL: " + message)
	else:
		print("EQUIPMENT_PAGE_PASS: " + message)

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(360, 800))
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	UiScale.update(Vector2(360, 800), false)
	progress = GameProgress.new()
	for id: String in ["elmo_mata", "colete_mata", "luvas_mata", "botas_mata", "anel_mata", "colar_mata", "amuleto_mata"]:
		progress.equipment[id] = 0
		progress.equipment_rarities[id] = "comum"
		progress.equip(id)
	var weapon_uid: String = progress._create_weapon("espada", "comum")
	progress.weapon_instances[weapon_uid].level = 0
	progress.equipment.espada = 0
	progress.equip_weapon_instance(weapon_uid)
	progress.save_loadout(0)
	_build()
	for _i in range(8): await process_frame
	for slot: String in RPGRules.SLOTS:
		_check(_find(page, "EquipmentSlot_" + slot) is Button, "slot " + slot + " is rendered")
	_check(_find(page, "EquipmentAttributes") != null, "combat stats panel is rendered")
	_check(_find(page, "Loadout_1") is Button and _find(page, "Loadout_2") is Button and _find(page, "Loadout_3") is Button, "three loadout controls are rendered")
	_check(_find(page, "SaveLoadout") is Button, "save loadout control is rendered")
	_check(_find(page, "OfficialItemSprite") is TextureRect, "official extracted sprites render in equipment slots")
	_check((_find(page, "OfficialItemSprite") as TextureRect).texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "equipment sprites keep nearest-neighbor filtering")
	var ring_frame := _find(_find(page, "EquipmentTile_Anel"), "RarityFrame") as TextureRect
	_check(ring_frame != null and ring_frame.modulate == MenuKit.rarity_color("comum"), "common rarity colors only the slot frame")
	var output := OS.get_environment("QA_RENDER_DIR")
	for _i in range(8): await process_frame
	if output.is_empty():
		_check(false, "QA_RENDER_DIR is configured for the requested capture")
	else:
		DirAccess.make_dir_recursive_absolute(output)
		_check(root.get_texture().get_image().save_png(output.path_join("equipment-screen-360x800.png")) == OK, "360x800 preview image is saved")
	progress.equipment_rarities["anel_mata"] = "mitico"
	_build()
	for _i in range(4): await process_frame
	ring_frame = _find(_find(page, "EquipmentTile_Anel"), "RarityFrame") as TextureRect
	_check(ring_frame != null and ring_frame.modulate == MenuKit.rarity_color("mitico"), "mythic rarity uses the existing red border color")
	progress.equipment_rarities["anel_mata"] = "comum"
	progress.equipment["espada"] = 3
	progress.weapon_instances[weapon_uid].level = 3
	_build()
	for _i in range(4): await process_frame
	_check(_find(_find(page, "EquipmentTile_Arma"), "UpgradeLevel") != null, "weapon upgrade badge reads the actual instance level")
	_check(EquipmentPage.sprite_path_for_item("trama").is_empty() and EquipmentPage.sprite_path_for_item("semente").is_empty(), "unmapped items stay pending instead of using a wrong sprite")
	progress.equipment["espada"] = 0
	progress.weapon_instances[weapon_uid].level = 0
	var slot_button := _find(page, "EquipmentSlot_Anel") as Button
	if slot_button != null:
		slot_button.pressed.emit()
	_check(tapped_slot == "anel_mata", "equipped slot delegates item inspection to the existing callback")
	progress.unequip("Anel")
	_build()
	for _i in range(6): await process_frame
	(_find(page, "Loadout_1") as Button).pressed.emit()
	_check(progress.equipped.Anel == "anel_mata", "saved loadout restores an item using GameProgress")
	(_find(page, "Loadout_2") as Button).pressed.emit()
	(_find(page, "SaveLoadout") as Button).pressed.emit()
	_check(progress.has_loadout(1), "save button stores the selected set using GameProgress")
	print("EQUIPMENT_PAGE_RESULT: %d checks, %d failures" % [checks, failures])
	var result_path := OS.get_environment("QA_RESULT_PATH")
	if not result_path.is_empty():
		var report := FileAccess.open(result_path, FileAccess.WRITE)
		report.store_string("EQUIPMENT_PAGE_RESULT: %d checks, %d failures\n" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _build() -> void:
	if is_instance_valid(page):
		root.remove_child(page)
		page.queue_free()
	page = EquipmentPage.build(
		progress,
		progress.combat_stats().hp,
		progress.combat_stats().hp,
		func(id: String): tapped_slot = id,
		func(_name: String): pass,
		_on_loadout,
		selected_set
	)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(page)

func _on_loadout(action: String, index: int) -> void:
	selected_set = index
	match action:
		"save": progress.save_loadout(index)
		"apply": progress.apply_loadout(index)
	_build()

func _find(node: Node, node_name: String) -> Node:
	if node == null: return null
	if node.name == node_name: return node
	for child in node.get_children():
		var result := _find(child, node_name)
		if result != null: return result
	return null
