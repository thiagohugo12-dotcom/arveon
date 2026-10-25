extends SceneTree

# Modo compacto (celular na horizontal): Ferreiro, Evolução e Derrota precisam caber
# com pouca rolagem, e na vertical nada muda. Rode com o jogo aberto em janela
# (--resolution 640x360), como as outras capturas.
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(60.0).timeout.connect(func(): push_error("COMPACT_FAIL: timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMPACT_FAIL: " + message)
	else:
		print("COMPACT_PASS: " + message)

func frames(count := 6) -> void:
	for _i in range(count): await process_frame

func tap(hud: GameHUD, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 91
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	event.pressed = false
	hud._input(event)

func resize(main: Node, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	main.hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main.hud.size = Vector2(size)
	main.hud._layout()

func _run() -> void:
	var save_path := "user://compact_ui_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH", save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	main.progress.gold = 3000
	for item: String in ["Madeira","Couro","Seda","Essência"]: main.progress.add_item(item,60)
	main.progress.add_item("Essência|raro",40)
	var uid: String = main.progress.craft_weapon("espada","comum")
	main.progress.weapon_instances[uid].rarity = "raro"
	for pair: Array in [["arco","comum",3],["machado","incomum",12],["cajado","raro",0]]:
		var extra: String = main.progress.craft_weapon(pair[0],"comum")
		if extra.is_empty(): continue
		main.progress.weapon_instances[extra].rarity = pair[1]
		main.progress.weapon_instances[extra].level = pair[2]
	main.progress.weapon_instances[uid].level = 7
	var hud: GameHUD = main.hud
	# Vertical: continua exatamente como aprovado.
	resize(main, Vector2i(360, 800))
	hud.show_station("Ferreiro", main.progress)
	hud.smith_tab = 1
	hud.refresh_station(main.progress)
	await frames()
	check(not UiScale.compact and hud.station_tab_host.get_parent() == hud.station_column and hud.station_footer.get_child_count() == 1, "portrait keeps the tabs under the title and pins the action")
	var portrait_range: float = hud.station_scroll.get_v_scroll_bar().max_value - hud.station_scroll.get_v_scroll_bar().page
	check(portrait_range <= 8.0, "portrait Enhance page fits without scrolling (%.0f px)" % portrait_range)
	hud.close_station()
	# Horizontal: Ferreiro.
	for size in [Vector2i(640, 360), Vector2i(960, 540)]:
		resize(main, size)
		hud.show_station("Ferreiro", main.progress)
		hud.smith_tab = 1
		hud.smith_instance_selected = ""
		hud.refresh_station(main.progress)
		await frames()
		var label := str(size)
		check(UiScale.compact and hud.station_tab_host.get_parent() == hud.station_header, "landscape moves the tabs into the title row " + label)
		check(hud.station_header.get_global_rect().size.y <= 56.0, "landscape header takes one slim row " + label)
		check(hud.station_scroll.get_global_rect().size.y >= size.y * 0.52, "blacksmith keeps most of the screen for content " + label)
		var action: Button = hud.smith_action_buttons.get(uid)
		check(action != null and action.get_parent() == hud.station_footer and hud.station_panel.get_global_rect().encloses(action.get_global_rect()), "primary action is pinned and always visible " + label)
		check(Rect2(Vector2.ZERO, Vector2(size)).encloses(hud.station_panel.get_global_rect()), "blacksmith panel fits the landscape viewport " + label)
		check(hud.station_panel.get_combined_minimum_size().x <= hud.station_panel.size.x + 1.0, "blacksmith content does not force the panel wider (%.0f of %.0f) %s" % [hud.station_panel.get_combined_minimum_size().x, hud.station_panel.size.x, label])
		var before: int = main.progress.weapon(uid).level
		tap(hud, action)
		await frames()
		check(hud.smith_confirm and hud.smith_action_buttons.get(uid).text.begins_with("Confirmar"), "pinned action keeps the two-step confirmation " + label)
		hud.smith_confirm = false
		check(int(main.progress.weapon(uid).level) == before, "selecting the pinned action spends nothing " + label)
		hud.close_station()
	# Vertical: a Evolução mostra todos os títulos de seção em pouco mais de uma tela.
	resize(main, Vector2i(360, 800))
	main._toggle_character()
	await frames()
	var portrait_panel: RPGPanel = hud.rpg_panel
	var evolution_range: float = portrait_panel.scroll.get_v_scroll_bar().max_value - portrait_panel.scroll.get_v_scroll_bar().page
	check(evolution_range <= 420.0 and portrait_panel.open_sections.size() >= 2, "portrait Evolution keeps its page short with collapsible sections (%.0f px)" % evolution_range)
	main._toggle_character()
	await frames()
	# Horizontal: Evolução.
	resize(main, Vector2i(640, 360))
	main._toggle_character()
	await frames()
	var panel: RPGPanel = hud.rpg_panel
	check(panel.scroll.get_global_rect().size.y >= 360.0 * 0.62, "Evolution keeps most of the screen for content")
	var xs := {}
	for button: Button in panel.attribute_buttons.values(): xs[roundi(button.get_global_rect().position.x)] = true
	check(xs.size() == 2 and panel.attribute_buttons.size() == 6, "attributes use two columns in landscape")
	check(Rect2(Vector2.ZERO, Vector2(640, 360)).encloses(panel.get_global_rect()), "Evolution fits the landscape viewport")
	main._toggle_character()
	await frames()
	# Horizontal: Derrota.
	main.player.last_damage_source = "Tatu Rochoso"
	main.player.last_damage_time_msec = Time.get_ticks_msec()
	main.player.health.damage(100000)
	await frames()
	check(hud.death_panel.visible and Rect2(Vector2.ZERO, Vector2(640, 360)).encloses(hud.death_panel.get_global_rect()), "defeat panel fits the landscape viewport")
	var scroll_range: float = hud.death_scroll.get_v_scroll_bar().max_value - hud.death_scroll.get_v_scroll_bar().page
	check(scroll_range <= 8.0, "defeat report needs no scrolling in landscape (%.0f px)" % scroll_range)
	var back: Button = hud.death_return_button
	check(back.get_global_rect().size.y >= 44.0 and hud.death_panel.get_global_rect().encloses(back.get_global_rect()), "defeat return button stays visible and touch sized")
	# Vertical de novo: o painel volta ao layout aprovado.
	resize(main, Vector2i(360, 800))
	hud.show_death({"enemy":"Tatu Rochoso","gold_lost":0,"xp_lost":0,"item_lost":"","item_count":0,"equipment_lost":[],"floor":1})
	await frames()
	check(not UiScale.compact and hud.death_buttons.vertical and hud.death_panel.get_global_rect().size.y > 700.0, "defeat panel returns to the portrait layout")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("COMPACT_RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
