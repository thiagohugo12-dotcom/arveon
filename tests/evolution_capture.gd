extends SceneTree

# Captures the real unified Evolution screen at 360x800, section by section.
var output := ""

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")

func _qa_size() -> Vector2i:
	# QA_SIZE=640x360 captura em modo horizontal; o padrão é 360x800.
	var parts := OS.get_environment("QA_SIZE").split("x")
	return Vector2i(int(parts[0]),int(parts[1])) if parts.size() == 2 else Vector2i(360,800)

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://evolution_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	main.progress.xp = RPGRules.xp_floor(18)+120
	main.progress.talents.xp.espada = TalentRules.xp_floor(21)+10
	preload("res://tests/etapa2_fixtures.gd").unlock(main.progress,"espada",21)
	main.progress.learn_talent("espada","sequencia_precisa",true)
	main.player.position = SafeCamp.RESPAWN
	var qa_size := _qa_size()
	root.size = qa_size
	root.content_scale_size = qa_size
	var hud: GameHUD = main.hud
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(qa_size)
	hud._layout()
	main._toggle_character()
	await capture("evolucao-1-topo-360x800")
	var panel: RPGPanel = hud.rpg_panel
	var step := int(qa_size.y * 0.8)
	for index in range(2,9):
		panel.scroll.scroll_vertical = step*(index-1)
		await capture("evolucao-%d-360x800" % index)
	panel.scroll.scroll_vertical = int(panel.scroll.get_v_scroll_bar().max_value)
	await capture("evolucao-fim-360x800")
	panel.evolution_tree_expanded = true
	panel.refresh(main.progress)
	panel.scroll.scroll_vertical = 0
	await process_frame
	panel.scroll.scroll_vertical = int(panel.scroll.get_v_scroll_bar().max_value*0.62)
	await capture("evolucao-arvore-360x800")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
