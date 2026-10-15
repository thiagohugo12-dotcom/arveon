extends RefCounted

static func _button_with_text(root: Node, prefix: String) -> Button:
	if root is Button and (root as Button).text.begins_with(prefix):
		return root as Button
	for child in root.get_children():
		var found := _button_with_text(child, prefix)
		if found != null:
			return found
	return null

static func run(suite, main) -> void:
	var p := GameProgress.new()
	suite.check(p.level() == 1 and p.attribute_points() == 0 and p.skill_points() == 0, "RPG starts at level one without free points")
	p.xp = 49
	suite.check(p.level() == 1, "level requires full XP threshold")
	p.xp = 50
	suite.check(p.level() == 2 and p.attribute_points() == 2 and p.skill_points() == 1, "level two grants two attributes and one skill point")
	suite.check(p.allocate_attribute("Força") and p.allocate_attribute("Vitalidade") and not p.allocate_attribute("Agilidade"), "attribute spending cannot exceed earned points")
	suite.check(not p.allocate_attribute("Inexistente") and p.combat_stats().damage == 14 and p.combat_stats().hp == 108, "attributes affect existing combat values")
	p.talents.xp.arco = TalentRules.xp_floor(3)
	suite.check(p.improve_skill("arco:rajada_flechas",true) and not p.improve_skill("arco:tiro_marcado",true), "skill improvement consumes bounded points")
	p.xp = 150
	suite.check(p.level() == 3 and p.attribute_points() == 2 and p.skill_points() == 1, "XP curve increases transition cost")
	p.xp = 100000000
	for i in range(196):
		p.allocate_attribute("Destreza")
	suite.check(p.level() == 100 and not p.allocate_attribute("Destreza") and is_equal_approx(float(p.combat_stats().basic_interval_factor), 0.85), "level attribute and dexterity interval caps hold with huge XP")
	for i in range(5):
		p.improve_skill("arco:rajada_flechas",true)
	suite.check(p.abilities.grades.arco.rajada_flechas == 4 and not p.improve_skill("arco:rajada_flechas",true), "normal grades capped at four")
	var before := p.bag.duplicate()
	suite.check(not p.forge("machado", -1) and p.bag == before and p.gold == 0, "insufficient forging is atomic")
	p.gold = 1000
	for item: String in GameProgress.ITEMS:
		p.add_item(item, 30)
	var start_gold := p.gold
	suite.check(p.forge("machado", -1) and p.equipment.machado == 0 and p.gold == start_gold - 35 and p.bag.Madeira == 27 and p.bag.Pedras == 26, "smith uses existing gold and gathered materials")
	var crafted_gold := p.gold
	suite.check(not p.forge("machado", -1) and p.gold == crafted_gold and p.equipment.size() == 2, "duplicate craft tap cannot clone equipment or spend twice")
	suite.check(p.forge("machado", 0) and not p.forge("machado", 0) and p.equipment.machado == 1, "stale upgrade tap rejected")
	suite.check(p.forge("machado", 1) and p.forge("machado", 2) and not p.forge("machado", 3), "equipment enhancement stops at plus three")
	for id: String in RPGRules.EQUIPMENT:
		if not p.equipment.has(id):
			p.forge(id, -1)
	suite.check(p.equipment.size() == 9, "five weapons two armors and two accessories have actual recipes")
	suite.check(p.equip("machado") and p.equip("couro") and p.equip("semente") and not p.equip("machado"), "each slot equips one owned item and repeat equip is inert")
	suite.check(p.equipment.has("espada") and p.equipment.size() == 9 and p.combat_stats().damage == 21, "old weapon stays owned and equipment bonuses apply")
	suite.check(not p.equip("inexistente") and p.unequip("Arma") and p.equipment.has("machado") and not p.unequip("Arma"), "unequip retains inventory and rejects empty slot")
	p.equip("machado")
	var path := "user://qa_rpg_%d.json" % Time.get_ticks_usec()
	p.save_path = path
	suite.check(p.save(), "RPG save writes successfully")
	var loaded := GameProgress.new()
	loaded.save_path = path
	suite.check(loaded.load_save() and loaded.attributes == p.attributes and loaded.skills == p.skills and loaded.equipment == p.equipment and loaded.equipped == p.equipped, "RPG save roundtrip preserves builds equipment and upgrades")
	var saved := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	for version in [1, 2, 3]:
		var old := saved.duplicate(true)
		old.version = version
		old.rpg.skills = preload("res://tests/etapa2_fixtures.gd").legacy_skills(p)
		old.xp = 500
		old.erase("rpg")
		if version < 3:
			old.erase("discovered_pois")
		if version < 2:
			old.erase("harvested_until")
			old.erase("opened_caches")
		_write(path, old)
		var legacy := GameProgress.new()
		legacy.save_path = path
		suite.check(legacy.load_save() and legacy.xp == 500 and legacy.level() == 5 and legacy.attribute_points() == 8 and legacy.bag == p.bag and legacy.chest == p.chest and legacy.gold == p.gold and legacy.equipment == {"espada": 0}, "save v%d safely migrates XP wallet inventory and earned points" % version)
		legacy.save()
		var migrated := GameProgress.new()
		migrated.save_path = path
		suite.check(migrated.load_save() and migrated.attribute_points() == 8 and migrated.equipment.size() == 1, "migrated v%d reload cannot duplicate points or starter gear" % version)
	var v4 := saved.duplicate(true)
	v4.version = 4
	v4.attributes = preload("res://tests/progression_tests.gd").legacy_attributes(p.attributes)
	v4.erase("rpg")
	_write(path, v4)
	var v4_loaded := GameProgress.new()
	v4_loaded.save_path = path
	suite.check(v4_loaded.load_save() and v4_loaded.attributes["Força"] == p.attributes["Força"] and v4_loaded.attributes["Destreza"] == 0 and v4_loaded.attribute_points() == 196 and v4_loaded.xp == p.xp, "existing b14b641 v4 preserves attributes XP and refunds Agility")
	var invalid := saved.duplicate(true)
	invalid.xp = 80
	invalid.rpg.level = 2
	_write(path, invalid)
	var protected := GameProgress.new()
	protected.save_path = path
	protected.gold = 123
	suite.check(not protected.load_save() and protected.gold == 123 and protected.attributes["Força"] == 0, "overspent saved build rejected without partial mutation")
	invalid = saved.duplicate(true)
	invalid.rpg.equipped.Arma = "couro"
	_write(path, invalid)
	suite.check(not protected.load_save(), "wrong-slot equipment save rejected")
	invalid = saved.duplicate(true)
	invalid.rpg.skills["Investida"] = 4
	_write(path, invalid)
	suite.check(not protected.load_save(), "out-of-range saved skills rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await _gameplay(suite, main)

static func _write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

static func _gameplay(suite, main) -> void:
	main.set_process(false)
	var player: PlayerActor = main.player
	var driver: InputDriver = main.input_driver
	var hud: GameHUD = main.hud
	for actor in suite.get_nodes_in_group("damageable_enemies"):
		actor.queue_free()
	await suite.frames()
	var p := GameProgress.new()
	p.save_path = main.progress.save_path
	main.progress = p
	main.earned_xp = 0
	main.earned_gold = 0
	main.known_level = 1
	player.health.initialize(100)
	preload("res://tests/etapa2_fixtures.gd").unlock(p)
	player.last_direction = Vector2.RIGHT
	player.apply_progression(p, true)
	player.position = Vector2(930, 750)
	player.set_physics_process(false)
	driver.blocked = false
	driver.reset()
	hud.close_inventory()
	hud.close_character()
	hud.restart.hide()
	var target := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as EnemyActor
	main.add_child(target)
	target.position = player.position + Vector2(35, 0)
	target.home_position = target.position
	target.set_physics_process(false)
	await suite.frames()
	var accepted := player.use_skill(0)
	preload("res://tests/etapa2_fixtures.gd").finish_skill1(player)
	suite.check(accepted and target.health.current == 31 and (player.view as Skill1GameView).skill1_phase() >= 1, "Talho Agil deals original physical damage after approved startup")
	var enemy_hp := target.health.current
	suite.check(not player.use_skill(0) and target.health.current == enemy_hp and player.skill_cooldowns[0] == 6.0, "unavailable skill cannot damage or reset cooldown")
	preload("res://tests/etapa2_fixtures.gd").reset(player)
	driver.blocked = true
	suite.check(not player.use_skill(0) and player.skill_cooldowns[0] == 0.0, "menus reject skills without consuming cooldown")
	driver.blocked = false
	player.position = SafeCamp.RESPAWN
	suite.check(not player.use_skill(0) and not player.use_skill(1) and not player.use_skill(2), "safe perimeter blocks every offensive skill")
	player.position = Vector2(930, 750)
	target.update_activity(target.position + Vector2(650, 0))
	player.use_skill(0)
	preload("res://tests/etapa2_fixtures.gd").finish_skill1(player)
	suite.check(target.health.current == enemy_hp, "suspended monsters immune to area farming")
	target.update_activity(target.position)
	target.set_physics_process(false)
	player.last_direction = Vector2.RIGHT
	player.attack.cooldown_left = 100.0
	preload("res://tests/etapa2_fixtures.gd").reset(player)
	target.position = player.position+Vector2(50,0)
	target.health.initialize(100)
	var before_technique := target.health.current
	suite.check(player.use_skill(1) and target.health.current < before_technique and player.skill_cooldowns[1] == 7.0,"Corte Crescente uses directional damage and independent identifier timer")
	var after_technique := target.health.current
	suite.check(not player.use_skill(1) and target.health.current == after_technique,"technique cannot reactivate during its cooldown")
	player.health.initialize(100)
	suite.check(player.use_skill(2) and player.class_combat.guard_left == 3.0,"Guarda Reativa replaces old Fury with a category defense technique")
	player.receive_damage(8)
	suite.check(player.health.current == 94,"reactive guard grants bounded damage resistance without healing")
	driver.blocked = true
	player._physics_process(7.0)
	suite.check(player.class_combat.guard_left == 0.0 and player.skill_cooldowns[2] > 0.0,"guard expires while its identifier cooldown remains")
	driver.blocked = false
	player.receive_damage(10)
	var old_hp := player.health.current
	p.equipment.couro = 0
	p.equip("couro")
	player.apply_progression(p)
	p.unequip("Armadura")
	player.apply_progression(p)
	p.equip("couro")
	player.apply_progression(p)
	suite.check(player.health.current == old_hp and player.health.maximum == 112, "equipment swaps cannot heal or restore lost HP")
	main.earned_xp = 80
	main._save_progress()
	suite.check(p.level() == 2 and hud.loot_label.text.contains("Level Up") and hud.notice_left > 0.0, "existing XP rewards produce transient level up feedback")
	preload("res://tests/etapa2_fixtures.gd").reset(player)
	var key := InputEventAction.new()
	key.action = "skill_1"
	key.pressed = true
	main._input(key)
	suite.check(player.skill_cooldowns[0] > 0.0, "keyboard skill action reaches actual player ability")
	await _interface(suite, main)

static func _interface(suite, main) -> void:
	var hud: GameHUD = main.hud
	var player: PlayerActor = main.player
	var driver: InputDriver = main.input_driver
	var p: GameProgress = main.progress
	suite.check(hud.inventory_panel.z_index > hud.actions[0].z_index and hud.station_panel.z_index > hud.actions[0].z_index and hud.rpg_panel.z_index > hud.actions[0].z_index, "modal panels render above combat controls")
	for size: Vector2 in [Vector2(360, 640), Vector2(640, 360)]:
		player.position = SafeCamp.RESPAWN
		hud.size = size
		hud._layout()
		main._toggle_character()
		await suite.frames()
		suite.check(hud.rpg_panel.visible and driver.blocked and hud.rpg_panel.get_rect().end.y <= hud.size.y, "character screen fits mobile %s and blocks combat · panel %s" % [size,hud.rpg_panel.get_rect()])
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.index = 12
		var button := _button_with_text(hud.rpg_panel.content, "+1")
		touch.position = button.global_position + button.size * 0.5
		var before := p.attribute_points()
		preload("res://tests/mobile_polish_tests.gd").tap(hud,button)
		suite.check(p.attribute_points() == before - 1, "touch allocates real attribute within available budget %s" % size)
		await suite.frames()
		touch.position = hud.rpg_panel.close_button.global_position + hud.rpg_panel.close_button.size * 0.5
		hud._input(touch)
		suite.check(not hud.rpg_panel.visible and not driver.blocked, "touch closes character and resumes controls %s" % size)
		main._toggle_inventory()
		await suite.frames()
		var tab := hud.inventory_tabs.get_child(1) as Button
		touch.position = tab.global_position + tab.size * 0.5
		hud._input(touch)
		await suite.frames()
		suite.check(hud.inventory_category == 1 and hud.equipment_bag.cards.size() == 2, "touch backpack equipment category displays owned gear %s" % size)
		var card: Button = hud.equipment_bag.cards.espada
		hud.inventory_scroll.scroll_vertical += maxi(0,roundi(card.global_position.y-hud.inventory_scroll.global_position.y-4))
		await suite.frames()
		touch.position = card.get_global_rect().get_center()
		hud._input(touch)
		touch.pressed = false
		hud._input(touch)
		touch.pressed = true
		await suite.frames()
		var equip_button: Button = hud.equipment_bag.equip_button
		hud.inventory_scroll.scroll_vertical += maxi(0, roundi(equip_button.global_position.y - hud.inventory_scroll.global_position.y - 32))
		await suite.frames()
		touch.position = equip_button.global_position + equip_button.size * 0.5
		hud._input(touch)
		suite.check(p.equipped.Arma == "", "touch unequips owned starter weapon %s" % size)
		p.equip("espada")
		player.apply_progression(p)
		hud.refresh_inventory(p)
		await suite.frames()
		touch.position = hud.inventory_close.global_position + hud.inventory_close.size * 0.5
		hud._input(touch)
		suite.check(not hud.inventory_open and not driver.blocked, "equipment bag close reachable %s" % size)
		player.position = Vector2(930,750)
		preload("res://tests/etapa2_fixtures.gd").reset(player)
		hud.set_rpg_status(p, player)
		var skill_touch := InputEventScreenTouch.new()
		skill_touch.pressed = true
		skill_touch.index = 13
		skill_touch.position = hud.actions[0].global_position + Vector2(28, 28)
		hud.actions[0]._input(skill_touch)
		suite.check(player.skill_cooldowns[0] > 0.0 and not hud.actions[0].enabled, "touch skill activates and exposes cooldown %s" % size)
		skill_touch.pressed = false
		hud.actions[0]._input(skill_touch)
		suite.check(not hud.character_button.get_rect().intersects(hud.joystick.get_rect()) and not hud.actions[0].get_rect().intersects(hud.minimap.get_rect()), "RPG controls avoid joystick and minimap %s" % size)
	# Real raw ScreenDrag must scroll when mouse-from-touch emulation is disabled.
	for item: String in GameProgress.ITEMS:
		p.add_item(item)
	main._toggle_inventory()
	await suite.frames()
	var swipe := InputEventScreenTouch.new()
	swipe.index = 14
	swipe.pressed = true
	swipe.position = hud.inventory_scroll.global_position + Vector2(25, 25)
	hud._input(swipe)
	var drag := InputEventScreenDrag.new()
	drag.index = 14
	drag.relative = Vector2(0, -80)
	hud._input(drag)
	suite.check(hud.inventory_scroll.scroll_vertical > 0, "raw mobile swipe scrolls backpack without mouse emulation")
	swipe.pressed = false
	hud._input(swipe)
	suite.check(hud.scroll_touch == -1, "scroll gesture releases touch ownership")
	main._toggle_inventory()
	player.position = SafeCamp.DISPLAY_STATIONS["Ferreiro"]
	p.gold = 100
	main.earned_gold = 100
	p.add_item("Madeira", 3)
	p.add_item("Pedras", 4)
	main._interact()
	await suite.frames()
	# Ferreiro now opens the gold-only Loja; switch to Forja for the legacy recipe regression.
	var forge_tab := hud.station_content.get_child(0).get_child(1) as Button
	forge_tab.pressed.emit()
	await suite.frames()
	var forge_box := hud.station_content.get_child(3).get_child(0) as VBoxContainer
	suite.check((forge_box.get_child(2) as Label).text.contains("35 ouro") and (forge_box.get_child(1) as Label).text.contains("Atual:"), "smith shows actual price and equipment comparison before craft action")
	var forge_button := forge_box.get_child(3) as Button
	hud.station_scroll.scroll_vertical += maxi(0, roundi(forge_button.global_position.y - hud.station_scroll.global_position.y - 32))
	await suite.frames()
	var forge_touch := InputEventScreenTouch.new()
	forge_touch.index = 15
	forge_touch.pressed = true
	forge_touch.position = forge_button.global_position + forge_button.size * 0.5
	forge_touch.pressed = true
	hud._input(forge_touch)
	forge_touch.pressed = false
	hud._input(forge_touch)
	suite.check(p.equipment.has("machado") and p.gold == 80 and p.adventures.forjar == 1, "mobile smith button crafts through existing wallet and inventory")
	hud.close_station()
	player.position = SafeCamp.RESPAWN
	hud.rpg_panel.tab = 1
	main._toggle_character()
	await suite.frames()
	var improvement := _button_with_text(hud.rpg_panel.content, "Melhorar")
	hud.rpg_panel.scroll.scroll_vertical += maxi(0,roundi(improvement.global_position.y-hud.rpg_panel.scroll.global_position.y-4))
	await suite.frames()
	forge_touch.position = improvement.global_position + improvement.size * 0.5
	forge_touch.pressed = true
	hud._input(forge_touch)
	forge_touch.pressed = false
	hud._input(forge_touch)
	suite.check(p.abilities.grades.espada.corte_crescente == 2 and p.skill_points() == 0 and player.skill_ranks[1] == 2, "touch skill screen spends one earned point and applies upgraded rank")
	preload("res://tests/etapa2_fixtures.gd").reset(player)
	main._use_skill(0)
	suite.check(player.skill_cooldowns[0] == 0.0, "character skill menu cannot activate combat abilities")
	main._toggle_character()
	var reload := GameProgress.new()
	reload.save_path = p.save_path
	main._save_progress()
	suite.check(reload.load_save() and reload.attributes == p.attributes and reload.equipment == p.equipment, "touch build and equipment survive full save reload")

