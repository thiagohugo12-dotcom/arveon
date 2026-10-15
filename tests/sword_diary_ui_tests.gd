extends SceneTree

var failures := 0
var checks := 0
var output := ""

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("SWORD_DIARY_FAIL: "+message)

func frames() -> void:
	for i in range(8): await process_frame

func capture(file: String) -> void:
	if output.is_empty(): return
	await frames()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(file+".png")) == OK,"capture "+file)

func tap(hud: GameHUD, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 7
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	hud._input(event)
	event.pressed = false
	hud._input(event)

func _run() -> void:
	output = OS.get_environment("QA_SWORD_DIARY_DIR")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	var p := GameProgress.new()
	p.xp = RPGRules.xp_floor(100)
	p.talents.xp.espada = TalentRules.xp_floor(20)
	p.configure_ability("equip_skill","espada","corte_crescente",0,true)
	p.configure_ability("equip_passive","espada","fio_afiado",0,true)
	p.learn_talent("espada","sequencia_precisa",true)
	var saved := p.to_json()
	var backdrop := ColorRect.new()
	backdrop.color = Color("#384b29")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var hud := GameHUD.new()
	root.add_child(hud)
	var panel := hud.rpg_panel
	panel.tab = 2
	panel.talent_weapon = "espada"
	panel.prof_section = 1
	panel.allow_respec = true
	panel.show()
	for resolution: Vector2i in [Vector2i(360,800),Vector2i(390,844),Vector2i(844,390),Vector2i(1366,768)]:
		root.size = resolution
		root.content_scale_size = resolution
		hud.size = Vector2(resolution)
		hud._layout()
		panel.sword_selection = "skill1:talho_agil"
		panel.refresh(p)
		panel.scroll.scroll_vertical = 0
		await frames()
		var prefix := "%dx%d_" % [resolution.x,resolution.y]
		var tree := panel.sword_tree
		check(tree.states["normal:corte_crescente"] == "Equipado" and tree.states["talent:sequencia_precisa"] == "Aprendido","equipped and purchased states are distinct from available "+prefix)
		check(tree.states["supreme:ascensao_lamina"] == "Bloqueado" and tree.buttons["supreme:ascensao_lamina"].has_node("Lock"),"future milestone retains inspectable lock "+prefix)
		for key: String in tree.buttons:
			var button: Button = tree.buttons[key]
			check(button.size.x >= 44 and button.size.y >= 44 and button.has_node("Icon"),"pixel icon and touch target "+key+prefix)
			check(tree.cards[key].get_global_rect().position.x >= panel.scroll.get_global_rect().position.x-1 and tree.cards[key].get_global_rect().end.x <= panel.scroll.get_global_rect().end.x+1,"card stays inside parchment width "+key+prefix)
		await capture(prefix+"arvore")
		panel.scroll.ensure_control_visible(tree.buttons["normal:ruptura_ancestral"])
		await frames()
		await capture(prefix+"marcos")
		var locked: Button = tree.buttons["supreme:ascensao_lamina"]
		panel.scroll.ensure_control_visible(locked)
		await frames()
		await capture(prefix+"maestria")
		tap(hud,locked)
		await frames()
		check(panel.sword_selection == "supreme:ascensao_lamina" and p.to_json() == saved,"touch inspects a locked node without changing save "+prefix)
		var detail_title: Control = panel.sword_detail.get_child(0)
		check(panel.scroll.get_global_rect().has_point(detail_title.get_global_rect().get_center()),"selected detail starts at its title in both orientations "+prefix)
		await capture(prefix+"detalhes")
		var back: Button = panel.find_child("ReturnToSwordNode",true,false)
		check(back != null and back.custom_minimum_size.y >= 44,"details provide accessible return action "+prefix)
		back.pressed.emit()
		await frames()
		var selected: Button = panel.sword_tree.buttons[panel.sword_selection]
		check(panel.scroll.get_global_rect().has_point(selected.get_global_rect().get_center()),"return restores selected milestone into viewport "+prefix)
		# A swipe starting on an icon must scroll without selecting it.
		panel.scroll.ensure_control_visible(panel.sword_tree.buttons["normal:estocada_precisa"])
		await frames()
		var target: Button = panel.sword_tree.buttons["normal:estocada_precisa"]
		var down := InputEventScreenTouch.new()
		down.index = 8
		down.pressed = true
		down.position = target.get_global_rect().get_center()
		hud._input(down)
		var drag := InputEventScreenDrag.new()
		drag.index = 8
		drag.position = down.position+Vector2(0,-40)
		drag.relative = Vector2(0,-40)
		hud._input(drag)
		down.pressed = false
		down.position = drag.position
		hud._input(down)
		check(panel.sword_selection == "supreme:ascensao_lamina" and p.to_json() == saved,"drag over icon does not select or purchase "+prefix)
		check(panel.get_global_rect().end.x <= resolution.x+1 and panel.get_global_rect().end.y <= resolution.y+1 and panel.close_button.size.y >= 44,"journal fits orientation and keeps close accessible "+prefix)
	check(p.to_json() == saved,"presentation and inspection preserve the full v11 snapshot")
	print("SWORD_DIARY_RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
