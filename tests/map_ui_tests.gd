extends SceneTree

# Mapa expandido estilizado: dados reais, legenda, encaixe em tela e minimapa pequeno intacto.
# Rode em janela: godot --path . --resolution 360x800 -s res://tests/map_ui_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("MAP_UI_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MAP_UI_FAIL: " + message)
	else:
		print("MAP_UI_PASS: " + message)

func frames(count := 4) -> void:
	for _i in range(count): await process_frame

func resize(main: Node, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	main.hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main.hud.size = Vector2(size)
	main.hud._layout()

func all_text(node: Node) -> String:
	var result := ""
	if node is Label: result += (node as Label).text + "\n"
	for child in node.get_children(): result += all_text(child)
	return result

func _run() -> void:
	var save_path := "user://map_ui_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var hud: GameHUD = main.hud
	check(not hud.minimap.styled and hud.expanded_map.styled, "only the expanded map uses the styled drawing")
	for size in [Vector2i(360,800),Vector2i(640,360)]:
		var label := str(size)
		resize(main, size)
		hud.show_map(main.progress)
		var hidden_until_fit := hud.map_panel.modulate.a == 0.0
		await frames()
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		check(hidden_until_fit and screen.encloses(hud.map_panel.get_global_rect()), "map panel fits the screen and stays invisible until fitted " + label)
		check(hud.map_title.text.contains("Andar 1") and hud.map_title.text.begins_with("Mapa"), "title names the real floor " + label)
		check(hud.map_legend_grid.get_child_count() == 4, "legend has four entries " + label)
		var text := all_text(hud.map_panel)
		check(text.contains("Você") and text.contains("Acampamento") and text.contains("Baú descoberto") and text.contains("Coleta descoberta") and text.contains("somente os descobertos"), "legend texts match the approved art " + label)
		check(screen.encloses(hud.map_close.get_global_rect()) and hud.map_close.size.y >= 44, "close button stays inside with a 44 px target " + label)
		check(hud.expanded_map.size.x >= 200.0 and hud.expanded_map.size.y >= 150.0, "map keeps a readable size " + label)
		hud.map_panel.hide()
		await frames()
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("MAP_UI_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
