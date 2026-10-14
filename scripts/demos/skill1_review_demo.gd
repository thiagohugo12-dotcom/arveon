extends "res://scripts/demos/bow_attack_demo.gd"
const CATALOGUE := preload("res://scripts/demos/skill1_catalogue.gd")
const SKILL_VIEW := preload("res://scripts/demos/skill1_actor_view.gd")
const GROUND := preload("res://scripts/demos/skill1_ground_effect.gd")
const SKILL_PROJECTILE := preload("res://scripts/demos/skill1_projectile.gd")
var selected_category := "espada"
var category_buttons: Array[Button] = []
var ground_effects: Array[Node2D] = []
var pending_cast := 0.0
var automatic_skills := true
var accepted_casts := 0
func _ready() -> void:
	super._ready()
	for category: String in CATALOGUE.ORDER:
		var button := _button(ArsenalRules.CATEGORIES[category].name,func(): select_category(category))
		button.disabled = not CATALOGUE.supported(category)
		button.add_theme_font_size_override("font_size",12)
		category_buttons.append(button)
	select_category("espada")
	attack_button.text = "Automático: sim"
	subtitle.text = "1–4: direção · R: Skill 1 · C: arma · V: caminhar"
	if OS.has_feature("web"): JavaScriptBridge.eval("delete window.BowDemoReady; window.Skill1DemoReady=true;")
func _create_panel(updated: bool) -> void:
	super._create_panel(updated)
	var player: PlayerActor = players.back()
	player.get_node("View").set_script(SKILL_VIEW if updated else preload("res://scripts/presentation/melee_actor_view.gd"))
	player.view.village_scale = true
	if updated:
		player.view.configure(selected_category)
		player.health.died.connect(player.view.clear_skill1)
	for connection in player.attack.projectile_requested.get_connections(): player.attack.projectile_requested.disconnect(connection.callable)
	player.attack.projectile_requested.connect(func(shooter: Node2D,target: Node2D,spec: Dictionary): _spawn_projectile(player,updated,shooter,target,spec))
	var fx := GROUND.new()
	player.get_parent().add_child(fx)
	ground_effects.append(fx)
	player.skill_used.connect(func(index: int):
		if not updated or index != 0: return
		var bonus := 20.0 if player.class_combat.has_passive("alcance_treinado") else 0.0
		fx.show_cast(player.global_position,player.view.skill1_direction,selected_category,bonus))
	var target: EnemyActor = targets.back()
	target.get_node("View").set_script(preload("res://scripts/demos/skill1_training_view.gd"))
	target.weapon_hit.connect(func(_category: String,_damage: int,event: int):
		var details := target.hit_details(event)
		target.view.skill1_impact = selected_category if details.get("source","") == CATALOGUE.rule(selected_category).id else "")
func _spawn_projectile(player: PlayerActor,updated: bool,shooter: Node2D,target: Node2D,spec: Dictionary) -> void:
	var projectile: PlayerProjectile
	var basic: bool = spec.get("source","basic") == "basic" and not spec.get("ultimate",false)
	if basic and spec.category == "arco": projectile = BowProjectile.new()
	elif basic and spec.category == "cajado": projectile = StaffProjectile.new()
	elif updated and spec.category in ["arco","cajado"] and CATALOGUE.supported(spec.category) and spec.get("source","") == CATALOGUE.rule(spec.category).id and not spec.get("ultimate",false): projectile = SKILL_PROJECTILE.new()
	else: projectile = PlayerProjectile.new()
	if projectile.get_script() == SKILL_PROJECTILE:
		player.view.skill1_direction = player.global_position.direction_to(target.global_position)
	player.get_parent().add_child(projectile)
	projectile.setup(shooter,target,spec,Rect2())
func select_category(category: String) -> void:
	if not CATALOGUE.supported(category): return
	selected_category = category
	pending_cast = 0
	for index in range(players.size()):
		var player := players[index]
		player.progress.equipment[category] = 0
		player.progress.equipped.Arma = category
		player.apply_progression(player.progress,true)
		player.attack.armed = attacks_enabled
		if index == 1: player.view.configure(category)
		ground_effects[index].clear()
	for index in range(category_buttons.size()): category_buttons[index].text = ("• " if CATALOGUE.ORDER[index] == category else "")+ArsenalRules.CATEGORIES[CATALOGUE.ORDER[index]].name
	select_direction(direction_index)
func select_direction(index: int) -> void:
	super.select_direction(index)
	pending_cast = 0
	for i in range(players.size()):
		var player := players[i]
		player.last_direction = DIRECTIONS[index]
		player.view.clear_sword()
		player.view.clear_bow()
		player.view.clear_staff()
		player.view.clear_melee()
		if i == 1: player.view.clear_skill1()
		targets[i].position = origins[i]+DIRECTIONS[index]*(150 if selected_category in ["arco","cajado"] else 80)
		cameras[i].position = origins[i]+Vector2(0,-18)+DIRECTIONS[index]*(65 if selected_category in ["arco","cajado"] else 40)
		if i < ground_effects.size(): ground_effects[i].clear()
func request_skill1() -> bool:
	var player := players[1]
	if pending_cast > 0 or not CATALOGUE.supported(selected_category) or not player.health.is_alive() or player.input_driver.blocked or not player.skill_ready(0): return false
	pending_cast = float(CATALOGUE.CONFIGS[selected_category].prepare)
	player.view.prepare_skill1(DIRECTIONS[direction_index],0)
	return true
func release_skill1() -> bool:
	pending_cast = 0
	var player := players[1]
	player.last_direction = DIRECTIONS[direction_index]
	player.view.skill1_direction = player.last_direction
	var accepted := player.use_skill(0) # The only real execution; no modified cooldown/damage.
	if accepted: accepted_casts += 1
	else: player.view.clear_skill1()
	return accepted
func _repeat() -> void: request_skill1()
func _toggle_attacks() -> void:
	attacks_enabled = not attacks_enabled
	attack_button.text = "Automático: sim" if attacks_enabled else "Automático: não"
	for player in players: player.attack.armed = attacks_enabled and not player.progress.active_category().is_empty()
	if not attacks_enabled:
		pending_cast = 0
		players[1].view.clear_skill1()
func _toggle_dex() -> void:
	super._toggle_dex()
	for player in players: player.attack.armed = attacks_enabled and not player.progress.active_category().is_empty()
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if players.size() < 2: return
	var player := players[1]
	if player.input_driver.blocked or not player.health.is_alive() or player.progress.active_category() != selected_category:
		pending_cast = 0
		player.view.clear_skill1()
		return
	if pending_cast > 0:
		pending_cast = maxf(0,pending_cast-delta)
		player.view.prepare_skill1(DIRECTIONS[direction_index],1-pending_cast/float(CATALOGUE.CONFIGS[selected_category].prepare))
		if pending_cast <= 0: release_skill1()
	elif automatic_skills and attacks_enabled and player.skill_ready(0) and player.view.skill1_phase() < 0:
		request_skill1()
func _process(delta: float) -> void:
	if players.size() < 2 or status == null: return
	var player := players[1]
	var phase: int = player.view.skill1_phase()
	var cooldown: float = player.progress.abilities.skill1_cooldowns[selected_category]
	var description: String = ["Preparação","Execução","Impacto","Recuperação"][phase] if phase >= 0 else "Básico / caminhada"
	status.text = "%s · %s\nRecarga: %.1fs · Acertos: %d" % [LABELS[direction_index],description,cooldown,targets[1].hits]
	buttons[8].text = "Skill 1" if cooldown <= 0 else "%.1fs" % cooldown
	if OS.has_feature("web"):
		qa_bridge_left -= delta
		if qa_bridge_left <= 0:
			qa_bridge_left = 0.1
			JavaScriptBridge.eval("window.Skill1DemoState=%s;" % JSON.stringify({"automatic":attacks_enabled,"category":selected_category,"name":CATALOGUE.rule(selected_category).name,"direction":direction_index,"walking":player.view.walking,"phase":phase,"casts":accepted_casts,"cooldown":cooldown,"hits":targets[1].hits,"basic_hits":targets[0].hits,"writes":player.progress.disk_writes,"projectiles":get_tree().get_nodes_in_group("player_projectiles").size()}))
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_C:
		var next := (CATALOGUE.ORDER.find(selected_category)+1)%5
		for offset in range(5):
			var category: String = CATALOGUE.ORDER[(next+offset)%5]
			if CATALOGUE.supported(category): select_category(category); break
	else: super._unhandled_key_input(event)
func _layout() -> void:
	super._layout()
	if heading == null or panels.size() < 2: return
	var area := size
	var portrait := area.x < 700
	var short_landscape := area.y < 520 and not portrait
	heading.text = "SKILLS 1 · "+CATALOGUE.rule(selected_category).name
	heading.add_theme_font_size_override("font_size",18 if portrait else 23)
	var usable_width := area.x-352 if short_landscape else area.x-32
	for i in range(category_buttons.size()):
		category_buttons[i].position = Vector2(16+i*usable_width/5,72)
		category_buttons[i].size = Vector2(usable_width/5-4,34)
	var available := area.y-220-124
	for i in range(2):
		if portrait:
			panels[i].position = Vector2(16,120+i*(available/2+6))
			panels[i].size = Vector2(area.x-32,available/2-6)
		else:
			panels[i].position.y = 120
			panels[i].size.y = area.y-132 if short_landscape else available
		(panels[i].get_child(0) as Label).text = "SKILL 1 · "+CATALOGUE.rule(selected_category).name if i == 1 else "BÁSICO · "+ArsenalRules.CATEGORIES[selected_category].name
		(panels[i].get_child(0) as Label).add_theme_font_size_override("font_size",13 if short_landscape else 15)
		(panels[i].get_child(1) as SubViewportContainer).size = panels[i].size-Vector2(10,45)
