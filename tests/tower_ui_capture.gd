extends SceneTree

# Captura a Torre Ancestral real (HUD) no tamanho de QA_SIZE (padrão 360x800) com estados
# vindos de AscensionProgress: Andar 1 concluído, Andar 2 atual e os demais sem conteúdo.
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
	var save_path := "user://tower_ui_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var ascension: AscensionProgress = main.progress.ascension
	ascension.defeats["1"] = 50
	ascension.completed_trials["1"] = true
	ascension.forest_seal = true
	ascension.unlocked_floors = [1,2] as Array[int]
	ascension.current_floor = 2
	ascension.defeats["2"] = 23
	var qa_size := _qa_size()
	root.size = qa_size
	root.content_scale_size = qa_size
	var hud: GameHUD = main.hud
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(qa_size)
	hud._layout()
	hud.show_station(TowerEntrance.NAME,main.progress)
	await capture("torre-andar-atual")
	hud.selected_floor = 1
	hud.refresh_station(main.progress)
	await capture("torre-andar-concluido")
	hud.selected_floor = 5
	hud.refresh_station(main.progress)
	await capture("torre-andar-indisponivel")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
