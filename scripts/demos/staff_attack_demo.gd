extends "res://scripts/demos/bow_attack_demo.gd"
## Reuse the existing review UI, worlds, training targets and input unchanged.
const STAFF_VIEW := preload("res://scripts/demos/staff_demo_view.gd")
const STAFF_PROJECTILE := preload("res://scripts/demos/staff_demo_projectile.gd")
func _ready() -> void:
	super._ready()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("delete window.BowDemoReady; window.StaffDemoReady=true;")
func _create_panel(updated: bool) -> void:
	super._create_panel(updated)
	var player: PlayerActor = players.back()
	if updated:
		player.get_node("View").set_script(STAFF_VIEW)
		player.view.village_scale = true

		player.health.died.connect(player.view.clear_staff)
		targets.back().get_node("View").set_script(preload("res://scripts/demos/staff_training_view.gd"))
	# Replace only the review's spawn callback, leaving AutoAttack untouched.
	for connection in player.attack.projectile_requested.get_connections():
		player.attack.projectile_requested.disconnect(connection.callable)
	player.attack.projectile_requested.connect(func(shooter: Node2D, selected: Node2D, spec: Dictionary):
		var use_staff: bool = updated and spec.get("category","") == "cajado" and spec.get("source","basic") == "basic" and not spec.get("ultimate",false)
		var orb := STAFF_PROJECTILE.new() if use_staff else PlayerProjectile.new()
		player.get_parent().add_child(orb)
		orb.setup(shooter,selected,spec,Rect2())
	)
	player.progress.equipment.cajado = 0
	player.progress.equipped.Arma = "cajado"
	player.apply_progression(player.progress,true)
func select_direction(index: int) -> void:
	super.select_direction(index)
	for player in players:
		if player.view is STAFF_VIEW: player.view.clear_staff()
func _toggle_attacks() -> void:
	super._toggle_attacks()
	if not attacks_enabled:
		for player in players:
			if player.view is STAFF_VIEW: player.view.cancel_channel()
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	for player in players:
		if not player.view is STAFF_VIEW: continue
		var staff := player.view as STAFF_VIEW
		if not player.health.is_alive() or player.input_driver.blocked or not player.attack.armed or player.attack.weapon.category != "cajado":
			staff.clear_staff()
			continue
		var candidate: Node2D = null
		if player.attack.cooldown_left > 0 and player.attack.cooldown_left <= staff.prepare_time(player.attack.weapon.interval): candidate = player.attack.select_target(player)
		if candidate != null: staff.prepare_staff(candidate.global_position-player.global_position,player.attack.cooldown_left,player.attack.weapon.interval)
		else: staff.cancel_channel()
func _process(delta: float) -> void:
	if players.size() < 2 or status == null: return
	var phase_index: int = players[1].view.phase()
	var description: String = ["Preparação","Canalização","Disparo","Recuperação"][phase_index] if phase_index >= 0 else "Caminhada" if players[1].view.walking else "Repouso"
	status.text = "%s · %s\nIntervalo real: %.3f s · Acertos: %d" % [LABELS[direction_index],description,players[1].attack.weapon.interval,targets[1].hits]
	if OS.has_feature("web"):
		qa_bridge_left -= delta
		if qa_bridge_left <= 0:
			qa_bridge_left = 0.1
			JavaScriptBridge.eval("window.StaffDemoState=%s;" % JSON.stringify({"hits":targets[1].hits,"direction":direction_index,"interval":players[1].attack.weapon.interval,"walking":players[1].view.walking,"writes":players[1].progress.disk_writes,"shots":players[1].view.staff_attacks,"phase":phase_index,"projectiles":get_tree().get_nodes_in_group("player_projectiles").size()}))
func _layout() -> void:
	super._layout()
	if heading != null: heading.text = "CAJADO · PRIMEIRO PASSE"
	for i in range(panels.size()):
		(panels[i].get_child(0) as Label).text = "AGORA · cajado e energia" if i == 1 else "ANTES · orbe atual"
