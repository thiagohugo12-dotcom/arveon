extends SceneTree

# Captura as páginas novas de Equipamento e Mochila (QA_SIZE escolhe o tamanho).
var output := ""

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _qa_size() -> Vector2i:
	var parts := OS.get_environment("QA_SIZE").split("x")
	return Vector2i(int(parts[0]),int(parts[1])) if parts.size() == 2 else Vector2i(360,800)

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://menu_pages_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	var progress: GameProgress = main.progress
	progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	progress.gold = 12540
	progress.gems = 320
	var first: String = progress._create_weapon("espada","comum")
	progress.weapon_instances[first].level = 5
	progress.equipped_weapon_uid = first
	progress._create_weapon("espada","raro")
	progress._create_weapon("arco","incomum")
	progress.equipment["arco"] = 0
	for item in ["Couro","Seda|raro","Essência|incomum","Presa de Javali","Teia Reforçada","Pepita Dourada","Coração da Mata","Fragmento de Receita","Madeira","Pedras","Ervas"]:
		progress.add_item(item,12 if item == "Presa de Javali" else 3)
	var qa_size := _qa_size()
	root.size = qa_size
	root.content_scale_size = qa_size
	UiScale.update(Vector2(qa_size))
	var hud: GameHUD = main.hud
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(qa_size)
	hud._layout()
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0d1a12")
	backdrop.size = Vector2(qa_size)
	hud.add_child(backdrop)
	backdrop.z_index = 30
	var page := EquipmentPage.build(progress,148,148,func(_id): pass,func(_p): pass)
	page.position = Vector2(4,4)
	page.size = Vector2(qa_size) - Vector2(8,8)
	hud.add_child(page)
	page.z_index = 31
	await capture("pagina-equipamento")
	page.queue_free()
	for tab in ["todos","equipamentos"]:
		var bag := BagPage.build(progress,148,148,tab,func(_t): pass,func(_k,_i): pass,func(_p): pass)
		bag.position = Vector2(4,4)
		bag.size = Vector2(qa_size) - Vector2(8,8)
		hud.add_child(bag)
		bag.z_index = 31
		await capture("pagina-mochila-" + tab)
		bag.queue_free()
		await process_frame
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
