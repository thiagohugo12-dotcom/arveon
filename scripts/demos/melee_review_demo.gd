extends "res://scripts/demos/bow_attack_demo.gd"
## Shared review controls/worlds; the two weapons retain their real melee rules.
const REVIEW_VIEW := preload("res://scripts/demos/melee_review_view.gd")
@export_enum("Machado","Lança") var weapon_kind := 0
func category() -> String: return "machado" if weapon_kind == 0 else "lanca"
func _ready() -> void:
	super._ready()
	if OS.has_feature("web"): JavaScriptBridge.eval("delete window.BowDemoReady; window.MeleeDemoReady=true;")
func _create_panel(updated: bool) -> void:
	super._create_panel(updated)
	var player: PlayerActor = players.back()
	if updated:
		player.get_node("View").set_script(REVIEW_VIEW)
		player.view.weapon_kind = weapon_kind
		player.view.village_scale = true
		player.attack.attacked.connect(func(target: Node2D):
			if player.attack.weapon.category == category() and player.attack.armed:
				player.view.play_melee(target.global_position-player.global_position,player.attack.weapon.interval))
		player.health.died.connect(player.view.clear_melee)
	player.progress.equipment[category()] = 0
	player.progress.equipped.Arma = category()
	player.apply_progression(player.progress,true)
func select_direction(index: int) -> void:
	super.select_direction(index)
	for i in range(players.size()):
		targets[i].position = origins[i]+DIRECTIONS[index]*minf(90,players[i].attack.weapon.reach*0.65)
		cameras[i].position = origins[i]+Vector2(0,-18)+DIRECTIONS[index]*35
		if players[i].view is REVIEW_VIEW: players[i].view.clear_melee()
func _toggle_attacks() -> void:
	super._toggle_attacks()
	if not attacks_enabled:
		for player in players:
			if player.view is REVIEW_VIEW: player.view.cancel_preparation()
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	for player in players:
		if not player.view is REVIEW_VIEW: continue
		var view := player.view as REVIEW_VIEW
		if not player.health.is_alive() or player.input_driver.blocked or not player.attack.armed or player.attack.weapon.category != category():
			view.clear_melee()
			continue
		var target: Node2D = null
		if player.attack.cooldown_left > 0 and player.attack.cooldown_left <= REVIEW_VIEW.prepare_time(player.attack.weapon.interval): target = player.attack.select_target(player)
		if target != null: view.prepare_melee(target.global_position-player.global_position,player.attack.cooldown_left,player.attack.weapon.interval)
		else: view.cancel_preparation()
func _process(delta: float) -> void:
	if players.size() < 2 or status == null: return
	var pose: int = players[1].view.phase()
	var names := ["Preparação","Golpe amplo" if weapon_kind == 0 else "Estocada","Contato","Recuperação"]
	status.text = "%s · %s\nIntervalo real: %.3f s · Acertos: %d" % [LABELS[direction_index],names[pose] if pose >= 0 else "Caminhada" if players[1].view.walking else "Repouso",players[1].attack.weapon.interval,targets[1].hits]
	if OS.has_feature("web"):
		qa_bridge_left -= delta
		if qa_bridge_left <= 0:
			qa_bridge_left = 0.1
			JavaScriptBridge.eval("window.MeleeDemoState=%s;" % JSON.stringify({"category":category(),"hits":targets[1].hits,"direction":direction_index,"interval":players[1].attack.weapon.interval,"walking":players[1].view.walking,"writes":players[1].progress.disk_writes,"shots":players[1].view.swings,"phase":pose,"projectiles":get_tree().get_nodes_in_group("player_projectiles").size()}))
func _layout() -> void:
	super._layout()
	if heading != null: heading.text = ("MACHADO" if weapon_kind == 0 else "LANÇA")+" · PRIMEIRO PASSE"
	for i in range(panels.size()): (panels[i].get_child(0) as Label).text = "AGORA · golpe amplo" if i == 1 and weapon_kind == 0 else "AGORA · estocada" if i == 1 else "ANTES · ataque atual"
