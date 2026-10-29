extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("ALPHA FIX OK: " + message)
	else:
		failures += 1
		push_error("ALPHA FIX FAIL: " + message)

func tap(hud: GameHUD, button: Button, index: int) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.pressed = true
	touch.position = button.get_global_rect().get_center()
	hud._input(touch)
	touch.pressed = false
	hud._input(touch)

func _run() -> void:
	var save_path := "user://qa_alpha_fixes_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	for actor in get_nodes_in_group("damageable_enemies"):
		actor.set_physics_process(false)
	main.player.set_physics_process(false)

	# The approved Floor 1 renderer must exist before its first visible draw.
	var floor_view := main.world.get_node("FloorView") as FloorView
	check(floor_view.visual_v2 and floor_view.v2_view != null, "Andar 1 inicia diretamente no visual aprovado")
	check(floor_view.atlas != null, "recursos do cenário já estão disponíveis na primeira cena")

	# Real touch coordinates at the priority mobile resolution close both panels.
	root.size = Vector2i(390, 844)
	main.hud.size = Vector2(390, 844)
	main.hud._layout()
	await process_frame
	main._toggle_inventory()
	await process_frame
	check(main.hud.inventory_panel.visible and main.input_driver.blocked, "mochila abre e bloqueia o combate")
	tap(main.hud, main.hud.inventory_close, 81)
	check(not main.hud.inventory_panel.visible and not main.input_driver.blocked, "X fecha a mochila por toque e restaura controles")
	main.hud.rpg_panel.tab = 2
	main.hud.rpg_panel.prof_section = 1
	main._toggle_character()
	await process_frame
	check(main.hud.rpg_panel.visible and main.hud.rpg_panel.close_button.is_visible_in_tree(), "proficiências exibem um botão de fechar acessível")
	tap(main.hud, main.hud.rpg_panel.close_button, 82)
	check(not main.hud.rpg_panel.visible and not main.input_driver.blocked, "X fecha proficiências por toque e restaura controles")

	# Weapon identities remain distinct at the data actually used by combat.
	var expected := {
		"espada": [75.0, 0.72], "machado": [80.0, 0.90],
		"lanca": [115.0, 0.75], "arco": [250.0, 0.80],
		"cajado": [220.0, 0.95]}
	for category: String in expected:
		var profile := ArsenalRules.profile(category)
		check(is_equal_approx(float(profile.reach), expected[category][0]) and is_equal_approx(float(profile.interval), expected[category][1]), "alcance e cadência preservam identidade de " + category)

	# Agile enemies now announce a close strike and can hit or be dodged.
	main.progress.ascension.current_floor = 1
	var agile: EnemyActor = main._make_enemy(1)
	main.add_child(agile)
	agile.target = main.player
	agile.global_position = Vector2(120, 100)
	agile.home_position = agile.global_position
	main.player.global_position = Vector2(164, 100)
	agile.chasing = true
	var hp_before: int = main.player.health.current
	agile._physics_process(0.01)
	check(agile.melee_windup > 0.0 and agile.view.warning, "inimigo ágil anuncia o golpe antes do dano")
	main.player.global_position = Vector2(240, 100)
	agile._physics_process(0.40)
	check(main.player.health.current == hp_before, "sair do alcance durante o aviso evita o golpe")
	main.player.global_position = Vector2(164, 100)
	agile.contact_left = 0.0
	agile._physics_process(0.01)
	agile._physics_process(0.40)
	check(main.player.health.current == hp_before - 7, "permanecer no alcance recebe o novo dano do Andar 1")
	check(agile.stats.max_hp == 36 and agile.stats.contact_damage == 7, "inimigo ágil do Andar 1 usa resistência moderada")
	agile.queue_free()
	await process_frame

	main.progress.ascension.current_floor = 2
	var expected_floor2 := {5: [78,12], 6: [162,17], 7: [108,20]}
	for kind: int in expected_floor2:
		var monster: EnemyActor = main._make_enemy(kind)
		check(monster.stats.max_hp == expected_floor2[kind][0] and monster.stats.contact_damage == expected_floor2[kind][1], "espécie %d aplica identidade e escala do Andar 2" % kind)
		monster.free()

	# Every used animation frame has transparent padding on all four sides.
	for texture: Texture2D in Floor2MonsterView.SHEETS:
		var image := texture.get_image()
		check(image.get_width() == 432 and image.get_height() == 320, "spritesheet do Andar 2 usa grade completa 6x5")
		for state: String in Floor2MonsterView.ROWS:
			var row: int = Floor2MonsterView.ROWS[state]
			var count: int = Floor2MonsterView.COUNTS[state]
			for frame in range(count):
				var cell := image.get_region(Rect2i(frame * 72, row * 64, 72, 64))
				var used := cell.get_used_rect()
				check(used.position.x > 0 and used.position.y > 0 and used.end.x < 72 and used.end.y < 64, "frame %s/%d mantém margem sem recorte" % [state, frame])

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("ALPHA FIX RESULT: %d falhas" % failures)
	quit(1 if failures > 0 else 0)
