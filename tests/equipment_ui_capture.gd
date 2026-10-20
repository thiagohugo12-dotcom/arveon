extends SceneTree

var output := ""

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _settle() -> void:
	for _i in range(8): await process_frame
	await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
	await _settle()
	var image := root.get_texture().get_image()
	if image.save_png(output.path_join(name+".png")) != OK: push_error("Screenshot failed: "+name)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://equipment_ui_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	root.size = Vector2i(390,844)
	root.content_scale_size = Vector2i(390,844)
	var p: GameProgress = main.progress
	p.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	p.gold = 9999
	p.add_item("Madeira",99)
	for material: String in EquipmentEconomy.MATERIALS:
		for rarity: String in EquipmentEconomy.RARITY_ORDER:
			p.add_item(EquipmentEconomy.key(material,rarity),99)
	p.add_item(EquipmentEconomy.SEAL,3)
	var rare := p.craft_weapon("lanca","raro")
	p.equip_weapon_instance(rare)
	var legendary := p.craft_weapon("machado","lendario")
	for i in range(15): p.enhance_weapon(legendary,false,0.0)
	p.choose_weapon_bonus(legendary,5,"impacto")
	p.choose_weapon_bonus(legendary,10,"vigor")
	main.player.apply_progression(p)
	main.hud.show_inventory(p)
	main.hud.inventory_category = 0
	main.hud.refresh_inventory(p)
	await _capture("01-mochila-materiais-mobile")
	main.hud.inventory_category = 1
	main.hud.refresh_inventory(p)
	await _capture("02-mochila-armas-mobile")
	main.hud.close_inventory()
	main.hud.show_station("Ferreiro",p)
	main.hud.smith_tab = 1
	main.hud.smith_craft_category = "arco"
	main.hud.smith_craft_rarity = "raro"
	main.hud.refresh_station(p)
	await _capture("03-ferreiro-fabricar-mobile")
	main.hud.smith_tab = 3
	main.hud.smith_instance_selected = legendary
	main.hud.refresh_station(p)
	await _capture("04-ferreiro-aprimorar-mobile")
	main.hud.smith_tab = 4
	main.hud.refresh_station(p)
	await _capture("05-ferreiro-bonus-mobile")
	root.size = Vector2i(320,640)
	root.content_scale_size = Vector2i(320,640)
	main.hud.smith_tab = 1
	main.hud.refresh_station(p)
	await _capture("06-ferreiro-criar-320x640")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("GRANDE_ARVORE_SAVE_PATH")
	print("EQUIPMENT_UI_CAPTURE: "+output)
	quit()
