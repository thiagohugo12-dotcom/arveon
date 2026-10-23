extends SceneTree

var checks := 0
var failures := 0
var capture_dir := ""

func _initialize() -> void:
	create_timer(50.0).timeout.connect(func(): push_error("Interface 2.0 test timeout"); quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("INTERFACE2_FAIL: "+message)
	else:
		print("INTERFACE2_PASS: "+message)

func frames(count := 6) -> void:
	for _i in range(count): await process_frame

func tap(hud: GameHUD, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 78
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	event.pressed = false
	hud._input(event)

func capture(name: String) -> void:
	if capture_dir.is_empty(): return
	await frames()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(capture_dir.path_join(name+".png")) == OK,"capture "+name)

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix): return node
	for child in node.get_children():
		var found := find_button(child,prefix)
		if found != null: return found
	return null

func contains_text(node: Node, value: String) -> bool:
	if node is Label and value in (node as Label).text: return true
	for child in node.get_children():
		if contains_text(child,value): return true
	return false

func _run() -> void:
	capture_dir = OS.get_environment("QA_INTERFACE2_DIR")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	var old_save := OS.get_environment("ARVEON_SAVE_PATH")
	var save_path := "user://interface2_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	for actor in get_nodes_in_group("damageable_enemies"): actor.set_physics_process(false)
	main.progress.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	main.progress.xp = RPGRules.xp_floor(8)
	main.earned_xp = main.progress.xp
	main.progress.gold = 3000
	main.progress.add_item("Madeira",40)
	main.progress.add_item("Couro|raro",40)
	main.progress.add_item("Essência|raro",40)
	main.progress.add_item("Couro|epico",40)
	main.progress.add_item("Essência|epico",40)
	main.player.position = SafeCamp.RESPAWN
	var hud: GameHUD = main.hud
	var evolution: RPGPanel = hud.rpg_panel
	root.size = Vector2i(360,800)
	root.content_scale_size = Vector2i(360,800)
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hud.size = Vector2(360,800)
	hud._layout()
	main._toggle_character()
	await frames()
	check(evolution.visible and evolution.page_title.text == "Evolução" and evolution.tabs.get_child_count() == 1,"one Evolution page replaces separate character/proficiency/skill navigation")
	check(evolution.attribute_buttons.size() == 6 and evolution.category_buttons.size() == 5 and evolution.skill_slots.size() == 4 and evolution.sword_tree != null,"existing six attributes, five weapon proficiencies, four equipped skills and weapon tree are present")
	check(evolution.get_global_rect().position.x >= 0 and evolution.get_global_rect().end.x <= 360 and evolution.close_button.size.y >= 44,"Evolution fits 360x800 with a touch-sized close action")
	await capture("evolution-360x800")
	var available: int = main.progress.attribute_points()
	var points_before: int = int(main.progress.attributes["Força"])
	var strength: Button = evolution.attribute_buttons["Força"]
	evolution.scroll.ensure_control_visible(strength)
	await frames()
	tap(hud,strength)
	await frames()
	check(main.progress.attribute_points() == available-1 and main.progress.attributes["Força"] == points_before+1,"attribute touch applies one current rule and refreshes Evolution")
	var reloaded := GameProgress.new()
	reloaded.save_path = save_path
	check(reloaded.load_save() and reloaded.attributes["Força"] == points_before+1,"attribute change persists through existing save format")
	var price_before: int = main.progress.gold
	main.player.position = SafeCamp.DISPLAY_STATIONS["Ferreiro"]
	var smith := find_button(hud.station_content,"Forjar")
	hud.show_station("Ferreiro",main.progress)
	await frames()
	smith = find_button(hud.station_content,"Forjar")
	check(hud.station_panel.visible and smith != null and find_button(hud.station_content,"Aprimorar") != null and find_button(hud.station_content,"Evoluir") != null,"Blacksmith exposes exactly the three requested tabs")
	await capture("blacksmith-forjar-360x800")
	hud.smith_craft_category = "espada"
	hud.smith_craft_rarity = "raro"
	hud.refresh_station(main.progress)
	var action := find_button(hud.station_content,"Selecionar · Fabricar")
	if action != null: action.pressed.emit()
	var confirm := find_button(hud.station_content,"Confirmar · Fabricar")
	if confirm != null: confirm.pressed.emit()
	await frames()
	var uid := hud.smith_instance_selected
	check(not uid.is_empty() and main.progress.weapon(uid).rarity == "raro" and main.progress.gold < price_before,"existing craft action creates the chosen real recipe and updates gold")
	hud.smith_tab = 1
	hud.refresh_station(main.progress)
	await capture("blacksmith-aprimorar-360x800")
	action = find_button(hud.station_content,"Selecionar · Tentar aprimorar")
	if action != null: action.pressed.emit()
	confirm = find_button(hud.station_content,"Confirmar · Tentar aprimorar")
	if confirm != null: confirm.pressed.emit()
	await frames()
	check(int(main.progress.weapon(uid).level) == 1,"enhance action advances the selected weapon instance via existing success rule")
	hud.smith_tab = 2
	hud.smith_confirm = false
	hud.refresh_station(main.progress)
	await capture("blacksmith-evoluir-360x800")
	action = find_button(hud.station_content,"Selecionar · Evoluir raridade")
	if action != null: action.pressed.emit()
	confirm = find_button(hud.station_content,"Confirmar · Evoluir raridade")
	if confirm != null: confirm.pressed.emit()
	await frames()
	check(main.progress.weapon(uid).rarity == "epico" and int(main.progress.weapon(uid).level) == 0,"rarity evolution follows current rule and resets only that copy's enhancement")
	hud.close_station()
	var gold_at_death: int = main.progress.gold
	var xp_at_death: int = main.progress.xp
	var expected_lost := ""
	for item: String in GameProgress.ITEMS:
		if int(main.progress.bag.get(item,0)) > 0:
			expected_lost = item
			break
	main.player.last_damage_source = "Tatu Rochoso"
	main.player.last_damage_time_msec = Time.get_ticks_msec()
	main.player.health.damage(100000)
	await frames()
	check(hud.death_panel.visible and not hud.restart.visible,"death opens the result panel and hides the legacy restart button")
	check(main.progress.gold == gold_at_death and main.progress.xp == xp_at_death,"death applies no gold or XP penalty when the existing rules report none")
	check(contains_text(hud.death_body,"Derrotado por: Tatu Rochoso") and (contains_text(hud.death_body,"Item perdido: "+expected_lost+" × 1") if not expected_lost.is_empty() else contains_text(hud.death_body,"Nenhum item perdido")),"death panel presents attacker and the exact material returned by the existing penalty")
	check(contains_text(hud.death_body,"Ouro perdido: 0") and contains_text(hud.death_body,"XP perdido: 0"),"zero losses are explicitly shown rather than recalculated in the interface")
	await capture("death-360x800")
	check(hud.death_panel.position.y >= 0 and hud.death_panel.position.y+hud.death_panel.size.y <= 800,"death panel fits the vertical viewport")
	main.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.set_environment("ARVEON_SAVE_PATH",old_save)
	print("INTERFACE2_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
