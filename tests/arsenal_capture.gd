extends SceneTree

const TOUCH = preload("res://tests/tower_trial_tests.gd")
var output := ""
var failures := 0

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")

func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame
	await RenderingServer.frame_post_draw

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("ARSENAL_QA_FAIL: " + message)

func capture(name: String) -> void:
	await frames(5)
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK,name)

func _run() -> void:
	output = OS.get_environment("QA_RENDER_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var path := "user://qa_arsenal_render_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	main.player.get_node("Camera2D").position_smoothing_enabled = false
	for id: String in RPGRules.EQUIPMENT:
		main.progress.equipment[id] = 0
	main.progress.equipment.espada = 1
	main.progress.gold = 137
	main.progress.bag = {"Madeira":8,"Ervas":5,"Seda":3,"Essência":2}
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
		root.size = resolution
		await frames()
		var hud: GameHUD = main.hud
		var prefix := "arsenal_%dx%d_" % [resolution.x,resolution.y]
		main._toggle_inventory()
		await frames()
		TOUCH._tap(hud,hud.inventory_tabs.get_child(1))
		await frames()
		check(hud.equipment_bag.cards.size() == 9 and hud.inventory_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,"all equipment in vertically scrolling compact list")
		check(hud.inventory_close.get_global_rect().end.y <= resolution.y and hud.inventory_tabs.get_child(1).size.y >= 44,"fixed close and tabs fit viewport")
		await capture(prefix + "mochila")
		hud.inventory_selected = "cajado"
		hud.refresh_inventory(main.progress)
		await frames()
		check(hud.equipment_bag.equip_button.size.y >= 44 and hud.equipment_bag.compare_button.size.y >= 44,"contextual touch actions")
		await capture(prefix + "detalhes")
		hud.inventory_selected = "machado"
		hud.inventory_compare = true
		hud.refresh_inventory(main.progress)
		await frames()
		check(hud.equipment_bag.comparison.get_child_count() == 8,"signed comparison gains and losses")
		hud.inventory_scroll.scroll_vertical = 10000
		await capture(prefix + "comparacao")
		TOUCH._tap(hud,hud.inventory_tabs.get_child(0))
		await capture(prefix + "materiais")
		TOUCH._tap(hud,hud.inventory_close)
		check(not main.input_driver.blocked,"closing resumes controls")
	# Actual live nodes fired by AutoAttack, not an illustrative overlay.
	main.player.position = Vector2(810,475)
	main.enemy.position = Vector2(950,475)
	for id: String in ["arco","cajado"]:
		main.progress.equip(id)
		main.player.apply_progression(main.progress)
		main.player.attack.cooldown_left = 0
		main.player.attack.search_left = 0
		main.player.attack.tick(0,main.player)
		var shots := preload("res://tests/arsenal_combat_tests.gd").shots(main)
		check(shots.size() == 1,"one actual ranged projectile " + id)
		if shots.size() == 1:
			shots[0]._physics_process(0.13)
			await capture("arsenal_960x540_" + id)
			shots[0].finish()
		await frames()
	var file := FileAccess.open(output.path_join("arsenal-result.txt"),FileAccess.WRITE)
	file.store_line("ARSENAL_QA_RESULT: %d failures" % failures)
	file.close()
	print("ARSENAL_QA_RESULT: %d failures" % failures)
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(1 if failures else 0)
