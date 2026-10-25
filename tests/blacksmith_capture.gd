extends SceneTree

# Captures the real blacksmith HUD at 360x800 for the three tabs. The game state
# comes from the Etapa 2 fixture; only the screens are driven, never the rules.
var output := ""

func _initialize() -> void:
	create_timer(80).timeout.connect(func(): quit(1))
	call_deferred("_run")

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://blacksmith_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	main.progress.xp = RPGRules.xp_floor(8)
	main.progress.gold = 3000
	for item: String in ["Madeira","Couro","Seda","Essência"]: main.progress.add_item(item,60)
	main.progress.add_item("Couro|raro",40)
	main.progress.add_item("Essência|raro",40)
	main.progress.add_item("Couro|epico",40)
	main.progress.add_item("Essência|epico",40)
	main.progress.add_item(EquipmentEconomy.SEAL,2)
	for pair: Array in [["espada","raro",7],["arco","comum",3],["machado","incomum",12],["cajado","raro",0]]:
		var uid: String = main.progress.craft_weapon(pair[0],"comum") if main.progress.can_craft_weapon(pair[0],"comum") else ""
		if uid.is_empty(): continue
		main.progress.weapon_instances[uid].rarity = pair[1]
		main.progress.weapon_instances[uid].level = pair[2]
	root.size = Vector2i(360,800)
	root.content_scale_size = Vector2i(360,800)
	var hud: GameHUD = main.hud
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(360,800)
	hud._layout()
	hud.show_station("Ferreiro",main.progress)
	hud.smith_tab = 0
	hud.refresh_station(main.progress)
	await capture("forge-forjar-360x800")
	hud.smith_tab = 1
	hud.smith_instance_selected = ""
	hud.refresh_station(main.progress)
	await capture("forge-aprimorar-360x800")
	hud.station_scroll.scroll_vertical = 600
	await capture("forge-aprimorar-baixo-360x800")
	for uid: String in main.progress.weapon_instances:
		if main.progress.weapon(uid).category == "machado": hud.smith_instance_selected = uid
	hud.smith_use_seal = true
	hud.smith_tab = 1
	hud.station_scroll.scroll_vertical = 0
	hud.refresh_station(main.progress)
	await capture("forge-aprimorar-selo-360x800")
	hud.station_scroll.scroll_vertical = 700
	await capture("forge-aprimorar-selo-baixo-360x800")
	hud.smith_use_seal = false
	hud.station_scroll.scroll_vertical = 0
	hud.smith_tab = 2
	hud.refresh_station(main.progress)
	await capture("forge-evoluir-360x800")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
