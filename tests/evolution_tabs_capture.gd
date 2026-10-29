extends SceneTree

# Captura a Evolução real em suas quatro abas (QA_SIZE escolhe o tamanho).
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
	var save_path := "user://evolution_tabs_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var qa_size := _qa_size()
	root.size = qa_size
	root.content_scale_size = qa_size
	var hud: GameHUD = main.hud
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(qa_size)
	hud._layout()
	hud.show_character(main.progress)
	for tab_index in range(4):
		hud.rpg_panel.evolution_tab = tab_index
		hud.rpg_panel.refresh(main.progress)
		await capture("evolucao-aba%d" % tab_index)
	hud.rpg_panel.evolution_tab = 2
	hud.rpg_panel.talent_weapon = "arco"
	hud.rpg_panel.refresh(main.progress)
	await capture("evolucao-arco-talentos")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
