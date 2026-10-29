extends SceneTree

# Evolução em quatro abas (Atributos · Arma · Talentos · Skills): retrato com a arte atual,
# árvore com talentos e passivas no mesmo lugar e rolagem que não volta ao topo ao clicar.
# Rode em janela: godot --path . --resolution 360x800 -s res://tests/evolution_tabs_tests.gd
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(90.0).timeout.connect(func(): push_error("EVO_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("EVO_FAIL: " + message)
	else:
		print("EVO_PASS: " + message)

func frames(count := 4) -> void:
	for _i in range(count): await process_frame

func buttons_in(node: Node, found: Array) -> void:
	for child in node.get_children():
		if child is Button and (child as Button).is_visible_in_tree() and not (child as Button).disabled: found.append(child)
		buttons_in(child, found)

func has_portrait(node: Node) -> bool:
	for child in node.get_children():
		if child is TextureRect and (child as TextureRect).texture is AtlasTexture and ((child as TextureRect).texture as AtlasTexture).atlas == VillageActorArt.PEOPLE: return true
		if has_portrait(child): return true
	return false

func _run() -> void:
	var save_path := "user://evo_tabs_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	preload("res://tests/etapa2_fixtures.gd").unlock(main.progress)
	var hud: GameHUD = main.hud
	var panel: RPGPanel = hud.rpg_panel
	for size in [Vector2i(360,800),Vector2i(640,360)]:
		var label := str(size)
		root.size = size
		root.content_scale_size = size
		hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		hud.size = Vector2(size)
		hud._layout()
		hud.show_character(main.progress)
		panel.allow_respec = true
		await frames()
		check(panel.evo_tabs.get_child_count() == 4 and panel.evo_tabs.visible, "Evolution has exactly four tabs " + label)
		var names: Array = []
		for tab: Button in panel.evo_tabs.get_children(): names.append(tab.text)
		check(names == ["Atributos","Arma","Talentos","Skills"], "tab names are Atributos, Arma, Talentos and Skills " + label)
		panel.evolution_tab = 0
		panel.refresh(main.progress)
		await frames()
		check(has_portrait(panel.content), "character portrait uses the current art " + label)
		# Cada aba monta o que prometeu.
		for index in range(4):
			panel.evolution_tab = index
			panel.refresh(main.progress)
			await frames()
			check(panel.content.get_child_count() > 0, "tab %d renders content %s" % [index,label])
		panel.evolution_tab = 1
		panel.refresh(main.progress)
		await frames()
		check(not panel.mastery_buttons.is_empty() and panel.mastery_buttons.size() == 4, "weapon tab lists the four weapon attributes " + label)
		# Talentos: toda arma tem talentos e passivas na mesma árvore.
		panel.evolution_tab = 2
		for weapon: String in ArsenalRules.CATEGORIES:
			panel.talent_weapon = weapon
			panel.refresh(main.progress)
			await frames()
			var passives: Array = AbilityRules.CATEGORIES[weapon].passives
			if weapon == "espada":
				check(is_instance_valid(panel.sword_tree) and panel.sword_tree.buttons.has("passive:fio_afiado"), "sword tree already holds talents and passives " + label)
			else:
				var expected := AbilityRules.talent_tree(weapon).size() + passives.size()
				check(is_instance_valid(panel.talent_tree) and panel.talent_tree.buttons.size() == expected, "%s tree shows %d talents and passives together %s" % [weapon,expected,label])
		# Varredura: nenhum clique que só atualiza a tela pode devolver ao topo.
		var topo := 0
		for index in range(4):
			for weapon: String in ["espada","arco"]:
				panel.evolution_tab = index
				panel.talent_weapon = weapon
				panel.refresh(main.progress)
				await frames()
				for n in range(8):
					var list: Array = []
					buttons_in(panel.content, list)
					if n >= list.size(): break
					var button: Button = list[n]
					panel.scroll.scroll_vertical = 100000
					await frames(2)
					var low := panel.scroll.scroll_vertical
					if low < 60: break
					var key_before := panel._view_key()
					button.pressed.emit()
					await frames(5)
					if panel._view_key() == key_before and panel.scroll.scroll_vertical <= 5:
						topo += 1
						push_error("EVO_FAIL: scroll returned to top after pressing '%s' on tab %d (%s) %s" % [button.text.replace("
"," "),index,weapon,label])
		check(topo == 0, "no click on a long Evolution page throws the scroll back to the top " + label)
		panel.hide()
		await frames()
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("EVO_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
