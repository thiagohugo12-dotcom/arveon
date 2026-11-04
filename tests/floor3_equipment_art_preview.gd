extends SceneTree

# Verifica a arte integrada na tela real de Equipamento & Mochila, sem tocar no save.
var failures := 0

func _initialize() -> void:
	create_timer(40.0).timeout.connect(func(): push_error("FLOOR3_ART_TIMEOUT"); quit(1))
	call_deferred("_run")

func _check(ok: bool, note: String) -> void:
	if not ok:
		failures += 1
		push_error("FLOOR3_ART_FAIL: " + note)
	else:
		print("FLOOR3_ART_PASS: " + note)

func _run() -> void:
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	var progress := GameProgress.new()
	progress.xp = 10000
	progress.gold = 360
	for id: String in ["elmo_brejo", "manto_raizes_mortas", "luvas_brejo", "botas_brejo", "anel_brejo", "colar_brejo", "amuleto_brejo"]:
		progress.equipment[id] = 0
		progress.equipment_rarities[id] = "raro"
		_check(progress.equip(id), "equipa " + id)
	var sword_uid := progress._create_weapon("espada", "raro", "lamina_brejo")
	_check(progress.equip_weapon_instance(sword_uid), "equipa Lâmina do Brejo")
	var preview := EquipmentBag3Preview.new()
	root.add_child(preview)
	preview.present(progress, 100, 100)
	for slot: String in RPGRules.SLOTS:
		var sprite := preview.find_child("OfficialItemSprite_" + slot, true, false) as TextureRect
		_check(sprite != null and sprite.texture != null, "sprite original no slot " + slot)
		var frame := preview.find_child("RarityFrame_" + slot, true, false) as Panel
		_check(frame != null and (frame.get_theme_stylebox("panel") as StyleBoxFlat).border_color == MenuKit.rarity_color("raro"), "borda rara no slot " + slot)
	var bag_item := preview.find_child("BagItem_" + sword_uid, true, false) as Button
	_check(bag_item != null, "Lâmina aparece como modelo próprio na Mochila")
	var output := OS.get_environment("QA_RENDER_DIR")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		for _i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(output.path_join("andar3-equipamento-360x800.png")) == OK, "captura 360x800 gravada")
	print("FLOOR3_ART_RESULT: ", failures, " failures")
	quit(1 if failures > 0 else 0)
