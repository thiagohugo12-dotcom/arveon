extends RefCounted

const TOUCH = preload("res://tests/tower_trial_tests.gd")

static func run_world(suite) -> void:
	var previous := OS.get_environment("GRANDE_ARVORE_SAVE_PATH")
	var path := "user://qa_arsenal_ui_%d.json" % Time.get_ticks_usec()
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",path)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	suite.root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.enemy.set_physics_process(false)
	var p: GameProgress = main.progress
	for id: String in RPGRules.EQUIPMENT:
		p.equipment[id] = 0
	p.equipment.espada = 1
	var hud: GameHUD = main.hud
	for size: Vector2 in [Vector2(360,640),Vector2(390,844),Vector2(640,360),Vector2(960,540)]:
		hud.size = size
		hud._layout()
		main._toggle_inventory()
		await suite.frames()
		TOUCH._tap(hud,hud.inventory_tabs.get_child(1))
		await suite.frames()
		suite.check(hud.equipment_bag.cards.size() == 9 and main.input_driver.blocked, "compact equipment listing preserves all owned gear and modal input " + str(size))
		suite.check(hud.inventory_panel.get_global_rect().end.y <= size.y and hud.inventory_close.size.y >= 40 and hud.inventory_tabs.get_child(1).size.y >= 44, "fixed header tabs closing fit touch viewport " + str(size))
		var card: Button = hud.equipment_bag.cards.espada
		var touch := InputEventScreenTouch.new()
		touch.index = 20
		touch.position = card.get_global_rect().get_center()
		touch.pressed = true
		hud._input(touch)
		var drag := InputEventScreenDrag.new()
		drag.index = 20
		drag.relative = Vector2(0,-50)
		drag.position = touch.position + drag.relative
		hud._input(drag)
		touch.position = drag.position
		touch.pressed = false
		hud._input(touch)
		await suite.frames()
		suite.check(hud.inventory_selected.is_empty() and hud.inventory_scroll.scroll_vertical > 0, "swiping over an equipment card scrolls without selecting " + str(size))
		for id: String in ArsenalRules.CATEGORIES:
			card = hud.equipment_bag.cards[id]
			hud.inventory_scroll.scroll_vertical += roundi(card.global_position.y - hud.inventory_scroll.global_position.y - 8)
			await suite.frames()
			suite.check(hud.inventory_scroll.get_global_rect().has_point(card.get_global_rect().get_center()), "weapon card touch target visible " + id + str(size))
			TOUCH._tap(hud,card)
			await suite.frames()
			suite.check(hud.inventory_selected == id and hud.equipment_bag.cards.is_empty(), "tap opens only selected equipment details " + id + str(size))
			var before := p.to_json()
			TOUCH._tap(hud,hud.equipment_bag.compare_button)
			await suite.frames()
			suite.check(hud.inventory_compare and hud.equipment_bag.comparison.get_child_count() >= 7 and before == p.to_json(), "touch comparison shows effective deltas without mutating save " + id + str(size))
			var button: Button = hud.equipment_bag.equip_button
			hud.inventory_scroll.scroll_vertical += maxi(0,roundi(button.global_position.y-hud.inventory_scroll.global_position.y-8))
			await suite.frames()
			TOUCH._tap(hud,button)
			await suite.frames()
			if p.equipped.Arma != id:
				TOUCH._tap(hud,hud.equipment_bag.equip_button)
				await suite.frames()
			suite.check(p.equipped.Arma == id and main.player.attack.weapon.category == id and p.equipment.size() == 9, "touch equips functional category without item duplication " + id + str(size))
			var restored := GameProgress.new()
			restored.save_path = path
			suite.check(restored.load_save() and restored.equipped.Arma == id, "equipment touch action autosaves selected weapon " + id + str(size))
			hud.inventory_scroll.scroll_vertical = 0
			await suite.frames()
			TOUCH._tap(hud,hud.equipment_bag.back_button)
			await suite.frames()
		TOUCH._tap(hud,hud.inventory_tabs.get_child(2))
		await suite.frames()
		suite.check(hud.inventory_category == 2 and hud.inventory_selected.is_empty(), "consumption tab resets expanded equipment " + str(size))
		TOUCH._tap(hud,hud.inventory_close)
		suite.check(not hud.inventory_open and not main.input_driver.blocked, "touch closing restores existing controls " + str(size))
	main.queue_free()
	await suite.frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	OS.set_environment("GRANDE_ARVORE_SAVE_PATH",previous)
