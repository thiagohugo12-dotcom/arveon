extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func(): push_error("Equipment playthrough timed out"); quit(1))
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _button(parent: Node, start: String) -> Button:
	if parent is Button and (parent as Button).text.begins_with(start): return parent
	for child in parent.get_children():
		var found := _button(child,start)
		if found != null: return found
	return null

func _run() -> void:
	var save_path := "user://equipment_playthrough_%d.json" % Time.get_ticks_usec()
	OS.set_environment("ARVEON_SAVE_PATH",save_path)
	preload("res://tests/etapa2_fixtures.gd").seed_existing()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.set_process(false)
	main.player.set_physics_process(false)
	main.player.position = SafeCamp.DISPLAY_STATIONS["Ferreiro"]
	var p: GameProgress = main.progress
	p.introduction = {"status":"legacy","met_smith":false,"weapon":""}
	p.gold = 2000
	main.earned_gold = 2000
	for material: String in ["Madeira","Couro|raro","Essência|raro","Essência|epico","Couro|epico"]: p.add_item(material,30)
	main.hud.show_station("Ferreiro",p)
	main.hud.smith_tab = 1
	main.hud.smith_craft_category = "espada"
	main.hud.smith_craft_rarity = "raro"
	main.hud.refresh_station(p)
	var select := _button(main.hud.station_content,"Selecionar · Fabricar")
	_check(select != null and not select.disabled,"rare crafting action is available in the live Smith panel")
	if select != null: select.pressed.emit()
	var confirm := _button(main.hud.station_content,"Confirmar · Fabricar")
	_check(confirm != null and not confirm.disabled,"rare crafting requires a separate confirmation")
	if confirm != null: confirm.pressed.emit()
	var uid: String = main.hud.smith_instance_selected
	_check(uid != "" and p.weapon(uid).get("rarity") == "raro" and p.weapon(uid).get("level") == 0,"live Smith action creates a rare +0 weapon")
	_check(p.gold == 1930 and int(p.bag.get("Madeira",0)) == 27 and int(p.bag.get("Couro|raro",0)) == 26,"live crafting pays the displayed gold and materials")
	main.hud.smith_tab = 3
	main.hud.refresh_station(p)
	select = _button(main.hud.station_content,"Selecionar · Tentar aprimorar")
	if select != null: select.pressed.emit()
	confirm = _button(main.hud.station_content,"Confirmar · Tentar aprimorar")
	if confirm != null: confirm.pressed.emit()
	_check(p.weapon(uid).get("level") == 1,"live Smith enhancement reaches +1")
	for _i in range(4): p.enhance_weapon(uid,false,0.0)
	main.hud.smith_tab = 4
	main.hud.refresh_station(p)
	select = _button(main.hud.station_content,"Selecionar · Dano físico")
	if select != null: select.pressed.emit()
	confirm = _button(main.hud.station_content,"Confirmar · Dano físico")
	if confirm != null: confirm.pressed.emit()
	_check(p.weapon(uid).choices.get("5") == "corte","live bonus panel stores the final +5 choice")
	main.hud.smith_tab = 2
	main.hud.refresh_station(p)
	select = _button(main.hud.station_content,"Selecionar · Evoluir")
	if select != null: select.pressed.emit()
	confirm = _button(main.hud.station_content,"Confirmar · Evoluir")
	if confirm != null: confirm.pressed.emit()
	_check(p.weapon(uid).rarity == "epico" and p.weapon(uid).level == 0 and p.weapon(uid).choices.is_empty(),"live rarity evolution resets enhancement and bonus")
	main.hud.close_station()
	main.hud.show_inventory(p)
	main.hud.inventory_category = 1
	main.hud.refresh_inventory(p)
	main._rpg_action("equip_instance",uid,0)
	_check(p.equipped_weapon_uid == uid and p.equipped.Arma == "espada","backpack equips the exact evolved copy")
	var restored := GameProgress.new()
	restored.save_path = save_path
	_check(restored.load_save() and restored.weapon(uid).rarity == "epico" and restored.equipped_weapon_uid == uid,"reopening the journal retains weapon rarity and equipped identity")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	OS.unset_environment("ARVEON_SAVE_PATH")
	print("EQUIPMENT_PLAYTHROUGH: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
