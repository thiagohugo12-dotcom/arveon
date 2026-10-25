extends SceneTree

# Ajustes de jogo e interface: botão de interação compacto, skills vazias, Baú no kit novo,
# corpo sólido da torre e terreno sem emendas. Rode em janela:
# godot --path . --resolution 360x800 -s res://tests/ui_polish_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("POLISH_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("POLISH_FAIL: " + message)
	else:
		print("POLISH_PASS: " + message)

func frames(count := 4) -> void:
	for _i in range(count): await process_frame

func all_text(node: Node) -> String:
	var result := ""
	if node is Label: result += (node as Label).text + "\n"
	if node is Button: result += (node as Button).text + "\n"
	for child in node.get_children(): result += all_text(child)
	return result

func has_box(walls: Node, rect: Rect2) -> bool:
	for shape: Node in walls.get_children():
		if shape is CollisionShape2D and (shape as CollisionShape2D).shape is RectangleShape2D:
			var box := (shape as CollisionShape2D).shape as RectangleShape2D
			if (shape as CollisionShape2D).position.distance_to(rect.get_center()) < 1.0 and box.size.is_equal_approx(rect.size): return true
	return false

func _run() -> void:
	var save_path := "user://polish_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	var hud: GameHUD = main.hud
	for size in [Vector2i(360,800),Vector2i(640,360)]:
		var label := str(size)
		root.size = size
		root.content_scale_size = size
		hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		hud.size = Vector2(size)
		hud._layout()
		hud.set_nearby_station("Baú")
		await frames()
		var screen := Rect2(Vector2.ZERO,Vector2(size))
		check(hud.interact_button.visible and hud.interact_button.size.y <= 32.0 and hud.interact_button.size.x < 96.0 and screen.encloses(hud.interact_button.get_global_rect()), "interact button is compact and on screen " + label)
		hud.set_nearby_station("Desafiar Guardião (opcional)")
		check(hud.interact_button.size.y <= 44.0 and screen.encloses(hud.interact_button.get_global_rect()), "two-line interact caption stays small and on screen " + label)
		hud.set_nearby_station("")
		hud.set_rpg_status(main.progress,main.player)
		check(not hud.actions[0].empty and hud.actions[1].empty and hud.actions[2].empty, "skill slots without a technique show the empty state " + label)
		check(hud.actions[0].slot_number == 1 and hud.actions[2].slot_number == 3, "skill slots show their numbers " + label)
		main.progress.chest["Seda"] = 2
		hud.show_station("Baú",main.progress)
		await frames()
		var text := all_text(hud.station_panel)
		check(hud.station_panel.visible and screen.encloses(hud.station_panel.get_global_rect()) and text.contains("Mochila") and text.contains("Guardar") and text.contains("Retirar"), "chest panel fits and lists quantities with both actions " + label)
		check(hud.station_close_button.size.y >= 44.0 and screen.encloses(hud.station_close_button.get_global_rect()), "chest close button keeps a 44 px target " + label)
		hud.close_station()
		await frames()
	var world: Node = main.world
	var found := false
	for shape: Node in world.get_node("Walls").get_children():
		if shape is CollisionShape2D and (shape as CollisionShape2D).shape is RectangleShape2D:
			var box := (shape as CollisionShape2D).shape as RectangleShape2D
			if box.size.is_equal_approx(TowerEntrance.ANDAR1_UPPER.size): found = true
	check(found, "Andar 1 tower body above the doorway is solid")
	check(TowerEntrance.ANDAR1_UPPER.end.y <= TowerEntrance.ANDAR1_SIDES[0].position.y and TowerEntrance.ANDAR2_UPPER.end.y <= TowerEntrance.ANDAR2_SIDES[0].position.y + 1.0, "upper tower body sits directly above the door pocket")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("POLISH_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
