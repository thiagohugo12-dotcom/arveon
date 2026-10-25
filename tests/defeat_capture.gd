extends SceneTree

# Captures the real HUD defeat panel at 360x800. The first shot goes through the
# real player death; the second passes explicit loss values straight to
# GameHUD.show_death to preview non-zero amounts (presentation only, no save).
var output := ""

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")

func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var save_path := "user://defeat_capture_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	root.size = Vector2i(360,800)
	root.content_scale_size = Vector2i(360,800)
	var hud: GameHUD = main.hud
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(360,800)
	hud._layout()
	main.player.last_damage_source = "Tatu Rochoso"
	main.player.last_damage_time_msec = Time.get_ticks_msec()
	main.player.health.damage(100000)
	await capture("defeat-real-death-360x800")
	hud.show_death({"enemy":"Tatu Rochoso","gold_lost":120,"xp_lost":85,"item_lost":"Minério de Ferro|raro","item_count":1,"equipment_lost":[],"floor":2})
	await capture("defeat-sample-values-360x800")
	hud.show_death({"enemy":"Tatu Rochoso","gold_lost":120,"xp_lost":85,"item_lost":"Minério de Ferro|raro","item_count":1,"equipment_lost":["Armadura"],"floor":2})
	await capture("defeat-sample-equipment-360x800")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0)
