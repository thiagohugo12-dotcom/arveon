extends SceneTree

var checks := 0
var failures := 0
var rendered := 0

func _initialize() -> void:
	CombatRules.random_roll_source = func():return 0.99
	create_timer(60).timeout.connect(func():quit(1))
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FIRST_WEAPON_FAIL: "+message)
	else: print("FIRST_WEAPON_PASS: "+message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await process_frame
		await physics_frame

func capture(name: String) -> void:
	var output := OS.get_environment("QA_RENDER_DIR")
	if output.is_empty(): return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png")) == OK,"render "+name)
	rendered += 1

func run() -> void:
	var old := GameProgress.new()
	old.xp = RPGRules.xp_floor(20)
	old.gold = 47
	old.equipment.cajado = 2
	old.equipped.Arma = "cajado"
	old.talents.xp.cajado = TalentRules.xp_floor(18)
	old.abilities.charge.cajado = 42
	old.mission_index = 1
	old.mission_progress = 3
	var snapshot: Dictionary = JSON.parse_string(old.to_json())
	snapshot.version = 10
	snapshot.erase("introduction")
	var migrated := GameProgress.new()
	check(migrated.load_text(JSON.stringify(snapshot)) and not migrated.introduction_active() and migrated.introduction.status == "legacy","v10 character exempt from introduction")
	check(migrated.equipped == old.equipped and migrated.equipment == old.equipment and migrated.xp == old.xp and migrated.gold == old.gold and migrated.abilities.to_save() == old.abilities.to_save() and migrated.talents.to_save() == old.talents.to_save() and migrated.mission_index == 1 and migrated.mission_progress == 3,"v10 gear progression and missions preserved exactly")
	check(not migrated.claim_first_weapon("espada",true),"legacy character cannot claim extra gift")
	var mission := CommonMission.new()
	mission.enabled = false
	for i in range(9):mission.record_defeat()
	check(mission.completed_count == 0 and mission.progress == 0,"normal mission paused throughout introduction")
	mission.enabled = true
	for i in range(8):mission.record_defeat()
	check(mission.completed_count == 1,"normal mission resumes with existing rules")
	var broken := GameProgress.new()
	broken.begin_new_character()
	broken.meet_smith()
	broken.save_path = "user://missing_first_weapon_dir/blocked.json"
	check(not broken.claim_first_weapon("espada",true) and broken.equipment.is_empty() and broken.introduction_active() and broken.equipped.Arma == "","failed disk write rolls back whole reward")
	for id: String in ArsenalRules.CATEGORIES:
		var path := "user://first_weapon_%s_%d.json" % [id,Time.get_ticks_usec()]
		var p := GameProgress.new()
		p.save_path = path
		p.begin_new_character()
		check(p.equipment.is_empty() and p.active_category().is_empty() and p.save(),"new unarmed snapshot saves "+id)
		check(not p.can_forge("espada") and not p.claim_first_weapon(id,true),"cannot bypass visit or introduction through forging "+id)
		check(p.meet_smith() and not p.meet_smith(),"visit is idempotent "+id)
		check(p.save(),"save pending choice "+id)
		var interrupted := GameProgress.new()
		interrupted.save_path = path
		check(interrupted.load_save() and interrupted.introduction_active() and interrupted.equipment.is_empty() and interrupted.introduction.met_smith,"interrupted choice reloads without gift "+id)
		check(not interrupted.claim_first_weapon(id,false) and not interrupted.claim_first_weapon("invalid",true),"wrong station and invalid ID rejected "+id)
		check(interrupted.claim_first_weapon(id,true),"durable claim succeeds "+id)
		check(interrupted.equipment == {id:0} and interrupted.equipped.Arma == id and interrupted.active_class() == TalentRules.CLASSES[id],"exactly one weapon equipped with matching class "+id)
		check(interrupted.gold == 0 and interrupted.xp == 0 and interrupted.bag.is_empty() and interrupted.talents.level(id) == 1,"gift gives no XP gold materials or proficiency "+id)
		var loaded := GameProgress.new()
		loaded.save_path = path
		check(loaded.load_save() and loaded.introduction.status == "complete" and loaded.equipped.Arma == id,"completed introduction survives reload "+id)
		for other: String in ArsenalRules.CATEGORIES:
			check(not loaded.claim_first_weapon(other,true),"second gift rejected "+id+"/"+other)
		var other := "arco" if id != "arco" else "espada"
		var cost := RPGRules.recipe(other,false,0)
		loaded.gold = int(cost.gold)
		loaded.bag = cost.materials.duplicate()
		check(loaded.forge(other,-1) and loaded.equip(other) and loaded.active_category() == other and loaded.equipment.has(id),"later class acquired with actual recipe "+id)
		check(loaded.gold == 0 and loaded.bag.is_empty() and not loaded.forge(other,-1),"purchase spends exact price and materials only once "+id)
		var valid := loaded.to_json()
		var malformed: Dictionary = JSON.parse_string(valid)
		malformed.introduction.weapon = "invalid"
		check(not loaded.load_text(JSON.stringify(malformed)) and loaded.to_json() == valid,"invalid reward state rejected atomically "+id)
		var shop_target := ""
		for category: String in ArsenalRules.CATEGORIES:
			if category != id and category != other:
				shop_target = category
				break
		var shop_price := GameProgress.starter_weapon_price(shop_target)
		check(shop_price > 0 and shop_price == int(RPGRules.EQUIPMENT[shop_target].gold),"shop prices come from approved equipment data "+id)
		check(not loaded.can_buy_starter_weapon(shop_target) and not loaded.purchase_starter_weapon(shop_target,true),"gold-only shop rejects insufficient funds "+id)
		loaded.gold = shop_price
		var old_weapon: String = loaded.equipped.Arma
		check(not loaded.purchase_starter_weapon(shop_target,false) and loaded.gold == shop_price and loaded.equipped.Arma == old_weapon,"shop rejects away-from-smith request "+id)
		var before_bag := loaded.bag.duplicate(true)
		check(loaded.can_buy_starter_weapon(shop_target) and loaded.purchase_starter_weapon(shop_target,true),"gold-only purchase accepts exact gold without any materials "+id)
		check(loaded.gold == 0 and loaded.bag == before_bag and loaded.equipment[shop_target] == 0 and loaded.equipped.Arma == shop_target,"purchase spends only gold and equips starter +0 "+id)
		check(not loaded.purchase_starter_weapon(shop_target,true) and loaded.gold == 0,"shop cannot charge twice for owned weapon "+id)
		var shop_reloaded := GameProgress.new()
		shop_reloaded.save_path = path
		check(shop_reloaded.load_save() and shop_reloaded.gold == 0 and shop_reloaded.equipped.Arma == shop_target and shop_reloaded.equipment.has(id) and shop_reloaded.equipment.has(other),"v11 store transaction persists gold weapon and class together "+id)
		var failed_shop := GameProgress.new()
		failed_shop.save_path = "user://missing_shop_dir/blocked.json"
		failed_shop.equipment = {id:0}
		failed_shop.equipped.Arma = id
		failed_shop.introduction = {"status":"complete","met_smith":true,"weapon":id}
		failed_shop.gold = shop_price
		check(not failed_shop.purchase_starter_weapon(shop_target,true) and failed_shop.gold == shop_price and failed_shop.equipped.Arma == id and not failed_shop.equipment.has(shop_target),"failed shop save rolls back gold equipment and class "+id)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var output := OS.get_environment("QA_RENDER_DIR")
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	if "--state-only" in OS.get_cmdline_user_args():
		print("FIRST_WEAPON_RESULT: %d checks, %d failures" % [checks,failures])
		call_deferred("_finish")
		return
	for id: String in ArsenalRules.CATEGORIES:
		OS.set_environment("GRANDE_ARVORE_SAVE_PATH","user://first_weapon_world_%s_%d.json" % [id,Time.get_ticks_usec()])
		var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(main)
		main.set_process(false)
		main.player.set_physics_process(false)
		for actor in get_nodes_in_group("damageable_enemies"):actor.set_physics_process(false)
		await frames()
		var p: GameProgress = main.progress
		var hud: GameHUD = main.hud
		var player: PlayerActor = main.player
		check(p.introduction_active() and p.equipment.is_empty() and player.position == SafeCamp.RESPAWN and not main.mission.enabled,"actual fresh runtime starts introduction in camp "+id)
		player.position = Vector2(850,750)
		main.enemy.position = player.position+Vector2(20,0)
		var hp: int = main.enemy.health.current
		player.attack.tick(1,player)
		check(main.enemy.health.current == hp and not player.attack.armed and player.attack.select_target(player) == null,"unarmed actor never attacks or animates "+id)
		check(not player.use_skill(0) and not player.use_skill(1) and not player.use_skill(2) and p.talents.level(id) == 1,"unarmed skill and proficiency gates "+id)
		player.position = SafeCamp.RESPAWN
		hp = player.health.current
		player.receive_damage(90)
		check(player.health.current == hp,"safe camp protects new character "+id)
		player.position = SafeCamp.DISPLAY_STATIONS.Ferreiro
		main._interact()
		check(hud.station_panel.visible and main.input_driver.blocked and p.introduction.met_smith,"actual smith visit opens mission option "+id)
		for size: Vector2i in [Vector2i(360,640),Vector2i(390,844),Vector2i(640,360),Vector2i(960,540)]:
			root.size = size
			root.content_scale_size = size
			await frames()
			hud.size = size
			hud._layout()
			hud.first_weapon_page = 1
			hud.refresh_station(p)
			await frames()
			var bounds := Rect2(Vector2.ZERO,Vector2(size))
			check(bounds.encloses(hud.station_panel.get_global_rect()) and bounds.encloses(hud.station_close_button.get_global_rect()),"smith modal and fixed close fit "+id+str(size))
			check(hud.first_weapon_buttons.size() == 6 and hud.first_weapon_buttons[id].size.y >= 48 and hud.station_scroll.get_global_rect().size.y > 100,"five choices and accessible scrolling "+id+str(size))
			if id == "espada":await capture("first_weapon_list_%dx%d" % [size.x,size.y])
			hud.station_scroll.ensure_control_visible(hud.first_weapon_buttons[id])
			await frames()
			preload("res://tests/mobile_polish_tests.gd").tap(hud,hud.first_weapon_buttons[id])
			await frames()
			check(hud.first_weapon_page == 2 and p.equipment.is_empty(),"touch selects without granting reward "+id+str(size))
			if id == "espada":await capture("first_weapon_confirm_%dx%d" % [size.x,size.y])
			preload("res://tests/mobile_polish_tests.gd").tap(hud,hud.first_weapon_buttons.back)
			await frames()
			check(hud.first_weapon_page == 1 and p.introduction_active(),"back preserves comparison and pending mission "+id+str(size))
			hud.close_station()
			main._interact()
			check(hud.first_weapon_page == 0 and p.equipment.is_empty(),"reopening smith does not grant weapon "+id+str(size))
			hud.first_weapon_page = 1
			hud.refresh_station(p)
			hud.first_weapon_buttons[id].pressed.emit()
			await frames()
		# Last orientation confirms through touch; prior ones compare and cancel.
		preload("res://tests/mobile_polish_tests.gd").tap(hud,hud.first_weapon_buttons.confirm)
		await frames()
		check(p.introduction.status == "complete" and p.equipped.Arma == id and player.attack.armed and main.mission.enabled,"touch commits chosen weapon and unlocks missions "+id)
		main._station_action("first_weapon",id)
		check(p.equipment.size() == 1 and p.gold == 0 and p.xp == 0,"duplicate UI action grants nothing "+id)
		check(hud.first_weapon_buttons.is_empty(),"permanent smith replaces reward interface "+id)
		hud.close_station()
		main.input_driver.blocked = false
		player.position = Vector2(850,750)
		main.enemy.position = player.position+Vector2(30,0)
		main.enemy.stats.max_hp = 500
		main.enemy.health.initialize(500)
		main.enemy.invulnerable = false
		main.enemy.awake = true
		player.last_direction = Vector2.RIGHT
		player.attack.cooldown_left = 0
		player.attack.search_left = 0
		player.attack.tick(0,player)
		for shot in get_nodes_in_group("player_projectiles"):
			for i in range(15):
				if is_instance_valid(shot) and not shot.is_queued_for_deletion():shot._physics_process(0.01)
		check(main.enemy.health.current < 500,"chosen weapon basic deals actual damage "+id)
		check(player.use_skill(0),"chosen weapon Skill 1 activates "+id)
		for shot in get_nodes_in_group("player_projectiles"):
			for i in range(15):
				if is_instance_valid(shot) and not shot.is_queued_for_deletion():shot._physics_process(0.01)
		check(int(p.talents.xp[id]) > 0,"chosen category earns proficiency from damage "+id)
		main._save_progress()
		var reloaded := GameProgress.new()
		reloaded.save_path = p.save_path
		check(reloaded.load_save() and not reloaded.introduction_active() and reloaded.equipped.Arma == id,"actual completed runtime persists "+id)
		var next_weapon := "arco" if id != "arco" else "cajado"
		var shop_cost := GameProgress.starter_weapon_price(next_weapon)
		p.gold = shop_cost
		main.earned_gold = shop_cost
		p.bag.clear()
		main._save_progress()
		player.position = SafeCamp.DISPLAY_STATIONS.Ferreiro
		main._interact()
		check(hud.station_panel.visible and hud.smith_tab == 0 and hud.smith_shop_buttons.size() == 5 and hud.smith_shop_buttons[id].disabled,"shop displays five starter categories and marks owned "+id)
		check(not hud.smith_shop_buttons[next_weapon].disabled and "Comprar" in hud.smith_shop_buttons[next_weapon].text,"gold-only shop enables affordable second class "+id)
		await frames() # Let the rebuilt shop finish container layout before scrolling.
		hud.station_scroll.ensure_control_visible(hud.smith_shop_buttons[next_weapon])
		await frames()
		preload("res://tests/mobile_polish_tests.gd").tap(hud,hud.smith_shop_buttons[next_weapon])
		await frames()
		check(hud.smith_shop_selected == next_weapon and p.gold == shop_cost and not p.equipment.has(next_weapon),"touch enters confirmation without spending "+id)
		var confirm_btn: Button = hud.smith_shop_buttons["confirm"]
		check(hud.station_scroll.get_global_rect().encloses(confirm_btn.get_global_rect()) and not confirm_btn.disabled,"shop confirmation fits inside visible mobile scroll "+id)
		preload("res://tests/mobile_polish_tests.gd").tap(hud,confirm_btn)
		await frames()
		check(p.gold == 0 and p.equipment.has(next_weapon) and p.equipped.Arma == next_weapon and player.attack.weapon.category == next_weapon,"touch purchase spends gold and equips class "+id)
		main._station_action("buy_starter",next_weapon)
		check(p.gold == 0 and p.equipment.size() == 2,"repeated shop action cannot duplicate item or charge gold "+id)
		var saved_shop := GameProgress.new()
		saved_shop.save_path = p.save_path
		check(saved_shop.load_save() and saved_shop.equipment.has(id) and saved_shop.equipment.has(next_weapon) and saved_shop.equipped.Arma == next_weapon and saved_shop.gold == 0,"actual smith shop saves equipped weapon and gold "+id)
		main.queue_free()
		await frames()
	print("FIRST_WEAPON_RESULT: %d checks, %d failures" % [checks,failures])
	if not output.is_empty():print("FIRST_WEAPON_RENDERED: %d" % rendered)
	call_deferred("_finish")

func _finish() -> void:
	CombatRules.random_roll_source = Callable()
	quit(1 if failures else 0)

