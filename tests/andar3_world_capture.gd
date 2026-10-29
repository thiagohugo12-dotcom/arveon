extends SceneTree

# Capturas reais do cenário do Andar 3 (só o mundo, sem HUD): visão geral reduzida
# e quadros 360x800 nas quatro regiões. Uso: QA_RENDER_DIR=<pasta> godot --path . -s res://tests/andar3_world_capture.gd
const SHOTS := {
	"visao-geral": [Vector2(1086, 813), 0.3],
	"entrada-encharcada": [Vector2(300, 1200), 1.0],
	"lodacal-nebuloso": [Vector2(1150, 900), 1.0],
	"bosque-afundado": [Vector2(380, 360), 1.0],
	"santuario-lunar": [Vector2(1858, 290), 1.0]}

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func():
		push_error("ANDAR3_WORLD_CAPTURE_TIMEOUT")
		quit(1))
	call_deferred("_run")

func _run() -> void:
	var out := OS.get_environment("QA_RENDER_DIR")
	var only := OS.get_environment("QA_ONLY")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var world := (load("res://scenes/world/andar_3.tscn") as PackedScene).instantiate()
	root.add_child(world)
	var camera := Camera2D.new()
	world.add_child(camera)
	camera.make_current()
	for name: String in SHOTS:
		if not only.is_empty() and only != name: continue
		var shot: Array = SHOTS[name]
		var zoom: float = shot[1]
		root.size = Vector2i(1448, 1084) if zoom < 1.0 else Vector2i(360, 800)
		camera.zoom = Vector2(zoom * (1448.0 / 2172.0) / 0.3, zoom * (1448.0 / 2172.0) / 0.3) if zoom < 1.0 else Vector2.ONE
		camera.position = shot[0]
		for _i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("andar3-%s.png" % name))
		print("SHOT ", name)
	quit(0)
