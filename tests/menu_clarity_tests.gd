extends SceneTree

var failures := 0
var checks := 0
var output := ""
var requests: Array = []

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MENU_CLARITY_FAIL: "+message)

func frames() -> void:
	for i in range(8): await process_frame

func capture(name: String) -> void:
	if output.is_empty(): return
	await frames()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png")) == OK,"capture "+name)

func tap(hud: GameHUD, button: Button, scroll: ScrollContainer) -> void:
	scroll.ensure_control_visible(button)
	await frames()
	check(scroll.get_global_rect().has_point(button.get_global_rect().get_center()),"target is visible before touch")
	var event := InputEventScreenTouch.new()
	event.index = 23
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	event.pressed = false
	hud._input(event)
	await frames()

func tap_navigation(hud: GameHUD, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 25
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	event.pressed = false
	hud._input(event)
	await frames()

func swipe(hud: GameHUD, button: Button, scroll: ScrollContainer) -> void:
	scroll.ensure_control_visible(button)
	await frames()
	var event := InputEventScreenTouch.new()
	event.index = 24
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	var drag := InputEventScreenDrag.new()
	drag.index = 24
	drag.position = event.position+Vector2(0,-45)
	drag.relative = Vector2(0,-45)
	hud._input(drag)
	event.position = drag.position
	event.pressed = false
	hud._input(event)
	await frames()

func _run() -> void:
	output = OS.get_environment("QA_MENU_CLARITY_DIR")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	var p := GameProgress.new()
	p.gold = 564
	p.xp = RPGRules.xp_floor(9)
	p.talents.xp.espada = TalentRules.xp_floor(12)
	p.bag = {"Ervas":1,"Cogumelos":1,"Madeira":2}
	p.configure_ability("equip_skill","espada","corte_crescente",0,true)
	var snapshot := p.to_json()
	var hud := GameHUD.new()
	root.add_child(hud)
	hud.station_action.connect(func(action: String,item: String): requests.append([action,item]))
	hud.rpg_action.connect(func(action: String,id: String,value: int): requests.append([action,id,value]))
	for resolution: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(844,390),Vector2i(1366,768)]:
		root.size = resolution
		root.content_scale_size = resolution
		hud.size = Vector2(resolution)
		hud._layout()
		var prefix := "%dx%d_" % [resolution.x,resolution.y]
		hud.show_station("Ferreiro",p)
		await frames()
		check(hud.station_panel.size.y > 320 or resolution.y < 400,"service uses available screen height "+prefix)
		check(hud.smith_shop_buttons.size() == 5 and hud.smith_shop_buttons.espada.disabled,"five categories and owned-state survive compact shop "+prefix)
		if resolution.y > resolution.x:
			for button: Button in hud.smith_shop_buttons.values():
				check(hud.station_scroll.get_global_rect().encloses(button.get_global_rect()),"all five shop actions fit in portrait "+prefix)
		await capture(prefix+"ferreiro")
		await tap(hud,hud.smith_shop_buttons.arco,hud.station_scroll)
		check(hud.smith_shop_selected == "arco" and p.to_json() == snapshot,"selecting weapon never spends gold "+prefix)
		check(hud.smith_shop_buttons.has("purchase") and not hud.smith_shop_buttons.has("confirm"),"selection opens comparison before confirmation "+prefix)
		await capture(prefix+"comparacao")
		await tap(hud,hud.smith_shop_buttons.purchase,hud.station_scroll)
		await capture(prefix+"compra")
		requests.clear()
		await tap(hud,hud.smith_shop_buttons.confirm,hud.station_scroll)
		check(requests == [["buy_starter","arco"]],"confirmation emits one original purchase transaction "+prefix)
		hud.close_station()
		hud.show_station("Vendedor",p)
		await frames()
		check(hud.vendor_buttons.has("Vender:Ervas") and not hud.vendor_buttons.has("Comprar:Ervas"),"gathered resources have sell action without impossible purchase "+prefix)
		check(str(GameProgress.SELL_PRICE) in hud.vendor_buttons["Vender:Ervas"].text,"sale button states actual gold price "+prefix)
		check(hud.vendor_tabs.size() == 2 and hud.vendor_tab == 0,"vendor separates buying and selling "+prefix)
		await capture(prefix+"vendedor")
		requests.clear()
		await swipe(hud,hud.vendor_buttons["Vender:Ervas"],hud.station_scroll)
		check(requests.is_empty(),"swiping over sale does not emit a transaction "+prefix)
		await tap(hud,hud.vendor_buttons["Vender:Ervas"],hud.station_scroll)
		check(requests == [["Vender","Ervas"]],"sell request keeps existing action and item "+prefix+str(requests))
		check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(hud.station_panel.get_global_rect()) and hud.station_close_button.size.y >= 44,"service and fixed close fit viewport "+prefix)
		hud.close_station()
		var panel := hud.rpg_panel
		panel.tab = 1
		panel.skill_section = 0
		panel.skill_choice = "corte_crescente"
		panel.allow_respec = true
		hud.show_character(p)
		panel.scroll.scroll_vertical = 0
		await frames()
		check(panel.tabs.visible and panel.page_title.text == "Habilidades","skills keep the main tabs visible "+prefix)
		check(panel.close_button.visible and panel.close_button.size.y >= 44,"skills keep a reachable close button "+prefix)
		check(panel.skill_catalog_buttons.size() == AbilityRules.CATEGORIES.espada.normal.size()+1 and panel.ability_buttons.size() == 3 and panel.skill_slots.size() == 3,"all sword techniques remain in selectable catalogue "+prefix)
		await tap(hud,panel.skill_slots[2],panel.scroll)
		check(panel.skill_target_slot == 1 and panel.ability_buttons[panel.skill_choice+":1"].text.begins_with("Equipar"),"choosing Skill 3 keeps it as the direct equipment target "+prefix)
		await capture(prefix+"habilidades")
		await tap(hud,panel.skill_catalog_buttons.guarda_reativa,panel.scroll)
		check(panel.skill_choice == "guarda_reativa" and panel.ability_buttons.has("guarda_reativa:0"),"selecting entry opens its actual slot actions "+prefix)
		await capture(prefix+"tecnica")
		requests.clear()
		await tap(hud,panel.ability_buttons["guarda_reativa:1"],panel.scroll)
		check(requests == [["equip_skill","espada:guarda_reativa",1]],"selected technique keeps slot transaction "+prefix)
		await tap(hud,panel.skill_section_buttons[1],panel.scroll)
		check(panel.skill_catalog_buttons.size() == 5 and panel.passive_buttons.size() == 2,"all passives remain selectable with two slots "+prefix)
		await capture(prefix+"passivas")
		await tap(hud,panel.skill_section_buttons[2],panel.scroll)
		check(panel.skill_catalog_buttons.size() == 2 and panel.specialization_buttons.size() == 1,"both specialization choices are retained "+prefix)
		await capture(prefix+"estilo")
		panel.allow_respec = false
		panel.refresh(p)
		check(panel.specialization_buttons[panel.skill_choice].disabled,"outside-camp style changes stay disabled "+prefix)
		panel.tab = 2
		panel.prof_section = 0
		panel.allow_respec = true
		panel.refresh(p)
		panel.scroll.scroll_vertical = 0
		await frames()
		check(panel.mastery_buttons.size() == 4 and panel.category_buttons.size() == 5,"four training attributes and five categories stay available "+prefix)
		check(panel.training_back.visible and panel.training_back.size.y >= 44,"training keeps a fixed return to the talent tree "+prefix)
		await capture(prefix+"treinamento")
		requests.clear()
		await tap(hud,panel.mastery_buttons.Dano,panel.scroll)
		check(requests == [["mastery","espada:Dano",0]],"training still sends expected investment guard "+prefix)
		panel.training_back.pressed.emit()
		await frames()
		check(panel.tab == 2 and panel.prof_section == 1,"fixed training return restores the talent tree "+prefix)
		check(panel.tabs.visible and panel.page_title.text == "Proficiências" and panel.close_button.visible,"talent tree keeps named navigation and close action "+prefix)
		await tap_navigation(hud,panel.tabs.get_child(2))
		check(panel.tab == 1 and panel.page_title.text == "Habilidades","touch switches from proficiency to skills "+prefix)
		await tap_navigation(hud,panel.tabs.get_child(0))
		check(panel.tab == 0 and panel.page_title.text == "Ficha do Personagem","touch returns to character sheet "+prefix)
		hud.close_character()
		check(p.to_json() == snapshot,"all reading and selection preserve v11 snapshot "+prefix)
	print("MENU_CLARITY_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)

