extends Control
## Offline review; no Main, save journal, network, autosave, or input-driven combat.
const DIRECTIONS := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const PLAYER := preload("res://scenes/actors/player.tscn")
const ENEMY := preload("res://scenes/actors/enemy.tscn")
const SWORD_ATTACKS := ["estocada_precisa","guarda_reativa","danca_laminas","corte_crescente","ruptura_ancestral"]
var actor_kind := 0
var ability := "estocada_precisa"
var direction_index := 3
var time := 0.0
var playing := true
var looping := true
var speed := 1.0
var walk_preview := false
var hitboxes := true
var comparison := true
var duration := 0.335
var contact_time := 0.135
var panels: Array[Dictionary] = []
var actor_choice: OptionButton
var attack_choice: OptionButton
var direction_choice: OptionButton
var comparison_button: CheckButton
var status: Label
var slider: HSlider
var play_button: Button
var panel_row: BoxContainer
var seeking := false
var actual_contact_events := 0
var actual_contact_time := -1.0
var real_damage := 0
var old_view: Skill1GameView
var new_player: PlayerActor
var new_enemy: EnemyActor
var projectiles: Array[EnemyProjectile] = []
var fired := false
var rng_previous: Callable

func _ready() -> void:
	rng_previous = CombatRules.random_roll_source
	CombatRules.random_roll_source = func(): return 0.99
	var background := ColorRect.new()
	background.color = Color("#202b26")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,10)
	add_child(margin)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var title := Label.new()
	title.text = "ARVÉON · Revisão local de combate"
	title.add_theme_font_size_override("font_size",22)
	column.add_child(title)
	var note := Label.new()
	note.text = "Propostas visuais isoladas · Regras reais nos testes de contato · Sem gravação de personagem"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	var controls := HFlowContainer.new()
	column.add_child(controls)
	actor_choice = OptionButton.new()
	for label in ["Explorador","Guardião da Mata","Javali","Aranha","Mandacaru"]: actor_choice.add_item(label)
	actor_choice.item_selected.connect(func(index: int): actor_kind=index; _populate_attacks(); rebuild())
	controls.add_child(actor_choice)
	attack_choice = OptionButton.new()
	controls.add_child(attack_choice)
	attack_choice.item_selected.connect(func(index: int): ability=SWORD_ATTACKS[index] if actor_kind == 0 else ("guardian_idle" if actor_kind == 1 and index == 0 else "roots"); rebuild())
	var directions := OptionButton.new()
	direction_choice=directions
	for label in ["Baixo","Cima","Esquerda","Direita"]: directions.add_item(label)
	directions.select(direction_index)
	directions.item_selected.connect(func(index: int): direction_index=index; rebuild())
	controls.add_child(directions)
	play_button = button(controls,"Pausar",func(): playing=not playing; play_button.text="Pausar" if playing else "Reproduzir")
	button(controls,"Reiniciar",func(): seek(0))
	button(controls,"◀ Quadro",func(): step_frame(-1))
	button(controls,"Quadro ▶",func(): step_frame(1))
	var speeds := OptionButton.new()
	for label in ["0,25×","0,5×","1×","2×"]: speeds.add_item(label)
	speeds.select(2)
	speeds.item_selected.connect(func(index: int): speed=[0.25,0.5,1.0,2.0][index])
	controls.add_child(speeds)
	checkbox(controls,"Loop",true,func(value: bool): looping=value)
	checkbox(controls,"Área real",true,func(value: bool): hitboxes=value; refresh_visuals())
	comparison_button=checkbox(controls,"Comparar",true,func(value: bool): comparison=value; panels[0].box.visible=value)
	checkbox(controls,"Pernas andando",false,func(value: bool): walk_preview=value; refresh_visuals())
	for control in controls.get_children():
		if control is OptionButton: control.custom_minimum_size.y=44
	panel_row = BoxContainer.new()
	panel_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel_row)
	for i in range(2): create_panel(i == 1)
	slider = HSlider.new()
	slider.step = 0.001
	slider.custom_minimum_size.y=44
	slider.value_changed.connect(func(value: float): if not seeking: playing=false; play_button.text="Reproduzir"; seek(value))
	column.add_child(slider)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 62
	column.add_child(status)
	_populate_attacks()
	resized.connect(_layout)
	_layout()
	rebuild()

func _exit_tree() -> void:
	CombatRules.random_roll_source = rng_previous

func button(parent: Node,text: String,action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 44
	b.pressed.connect(action)
	parent.add_child(b)
	return b
func checkbox(parent: Node,text: String,value: bool,action: Callable) -> CheckButton:
	var b := CheckButton.new()
	b.text=text
	b.button_pressed=value
	b.custom_minimum_size.y=44
	b.toggled.connect(action)
	parent.add_child(b)
	return b
func _layout() -> void:
	if is_instance_valid(panel_row): panel_row.vertical = size.x < 750
	if size.x < 750 and is_instance_valid(comparison_button): comparison_button.button_pressed=false
func _populate_attacks() -> void:
	attack_choice.clear()
	var names := ["Estocada Precisa","Guarda Reativa","Kamusari","Corte Crescente","Ruptura Ancestral"] if actor_kind == 0 else (["Repouso","Golpe frontal de raízes"] if actor_kind == 1 else ["Investida"] if actor_kind == 2 else ["Contato"] if actor_kind == 3 else ["Disparo de espinho"])
	for label: String in names: attack_choice.add_item(label)
	ability = "estocada_precisa" if actor_kind == 0 else "roots"
	if actor_kind == 1: attack_choice.select(1)
func create_panel(updated: bool) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.size_flags_vertical=Control.SIZE_EXPAND_FILL
	panel_row.add_child(box)
	var label := Label.new()
	label.text = "PROPOSTA · nova atuação e sincronização" if updated else "ANTES · arte aprovada (comparação visual)"
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	var container := SubViewportContainer.new()
	container.stretch=true
	container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	container.size_flags_vertical=Control.SIZE_EXPAND_FILL
	container.custom_minimum_size=Vector2(180,160)
	box.add_child(container)
	var vp := SubViewport.new()
	vp.size=Vector2i(460,360)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.world_2d=World2D.new()
	container.add_child(vp)
	var world := Node2D.new()
	vp.add_child(world)
	var stage := preload("res://scripts/demos/local_combat_review_stage.gd").new()
	stage.z_index=-100
	world.add_child(stage)
	var camera := Camera2D.new()
	camera.position=Vector2(1100,420)
	camera.zoom=Vector2.ONE*0.70
	world.add_child(camera)
	container.resized.connect(fit_panels)
	panels.append({"box":box,"world":world,"stage":stage,"vp":vp,"updated":updated,"camera":camera,"container":container})

func fit_panels() -> void:
	# Fit the complete legal range, including tall canopy, without clipping tips.
	var extent:=Vector2(400,400) if actor_kind == 0 else Vector2(340,320) if actor_kind == 1 else Vector2(540,540) if actor_kind == 4 else Vector2(240,240)
	if actor_kind == 0 and ability == "ruptura_ancestral": extent=Vector2(500,500)
	for p in panels:
		var room: Vector2=p.container.size
		p.camera.position=Vector2(1100,410 if actor_kind == 1 else 440)
		p.camera.zoom=Vector2.ONE*minf(2.0,minf(room.x/extent.x,room.y/extent.y))

func clear_cast() -> void:
	for p in panels:
		for child in p.world.get_children():
			if child is PlayerActor or child is EnemyActor:
				p.world.remove_child(child)
				child.queue_free()
	for shot in projectiles:
		if is_instance_valid(shot): shot.queue_free()
	projectiles.clear()
	fired=false
	actual_contact_events=0
	actual_contact_time=-1
	real_damage=0

func rebuild() -> void:
	actor_choice.select(actor_kind)
	direction_choice.select(direction_index)
	duration=SwordTechniqueTiming.duration(ability) if actor_kind == 0 and SwordTechniqueTiming.FRAMES.has(ability) else (3.10 if actor_kind == 0 else 1.87 if actor_kind == 1 else 1.65 if actor_kind == 4 else 0.80 if actor_kind == 2 else 0.50)
	if ability == "guardian_idle": duration=1.2
	if actor_kind == 0 and SwordTechniqueEffect.EXTRA_DURATIONS.has(ability): duration=SwordTechniqueEffect.EXTRA_DURATIONS[ability]
	contact_time=SwordTechniqueTiming.contact(ability) if actor_kind == 0 and SwordTechniqueTiming.FRAMES.has(ability) else (0.60 if actor_kind == 0 else 0.75 if actor_kind == 1 else 0.34 if actor_kind == 4 else 0.42 if actor_kind == 2 else 0.12)
	if actor_kind == 0 and SwordTechniqueEffect.EXTRA_DURATIONS.has(ability): contact_time=0
	seeking=true
	slider.max_value=duration
	seeking=false
	seek(0)
	fit_panels()

func setup_cast() -> void:
	clear_cast()
	var aim: Vector2=DIRECTIONS[direction_index]
	for p in panels:
		var world: Node2D=p.world
		var player: PlayerActor=PLAYER.instantiate()
		if p.updated and actor_kind == 0: player.get_node("View").set_script(preload("res://scripts/demos/local_player_review_view.gd"))
		player.get_node("Camera2D").enabled=false
		player.position=Vector2(1100,440)
		world.add_child(player)
		player.set_physics_process(false)
		player.view.set_process(false)
		player.view.village_scale=true
		if not p.updated and actor_kind == 0:
			player.view.remove_child(player.view.sword_technique)
			player.view.sword_technique.queue_free()
			player.view.sword_technique=preload("res://scripts/demos/local_legacy_kamusari_effect.gd").new()
			player.view.add_child(player.view.sword_technique)
			player.view.sword_technique.top_level=true
			player.view.sword_technique.z_as_relative=false
		var driver:=InputDriver.new()
		player.add_child(driver)
		player.input_driver=driver
		var progress:=TrainingMode.create()
		progress.abilities.loadouts.espada.skills=[ability if actor_kind == 0 else "estocada_precisa","danca_laminas"]
		player.apply_progression(progress,true)
		player.last_direction=aim
		player.view.set_facing(aim)
		player.attack.cooldown_left=100
		var enemy: EnemyActor=ENEMY.instantiate()
		var enemy_stats:=enemy.stats.duplicate() as ActorData
		enemy.position=Vector2(1100,440)+aim*65
		if actor_kind == 1:
			enemy.set_script(preload("res://scripts/actors/tower_guardian.gd"))
			enemy.get_node("View").set_script(preload("res://scripts/demos/local_guardian_review_view.gd") if p.updated else preload("res://scripts/presentation/tower_guardian_view.gd"))
			enemy.kind=4
			enemy.arena_bounds=Rect2(500,100,800,700)
		elif actor_kind >= 2:
			enemy.kind=actor_kind-2
			if p.updated: enemy.get_node("View").set_script(preload("res://scripts/demos/local_enemy_review_view.gd"))
		enemy.stats=enemy_stats
		world.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.view.set_process(false)
		enemy.view.village_scale=true
		enemy.target=player
		enemy.chasing=true
		enemy.health.initialize(1000000)
		if actor_kind != 0:
			enemy.position=Vector2(1100,440)
			player.position=enemy.position+aim*(140 if actor_kind == 4 else 60 if actor_kind == 1 else 28)
		p.player=player
		p.enemy=enemy
		p.stage.kind=actor_kind
		p.stage.technique=ability
		p.stage.direction=aim
		p.stage.reach_bonus=20.0 if player.class_combat.has_passive("alcance_treinado") else 0
		if actor_kind == 0:
			if p.updated:
				new_player=player
				new_enemy=enemy
				player.class_combat.technique_impact.connect(func(_id: String,when: float): actual_contact_events+=1; actual_contact_time=when)
				player.use_skill(1)
				if SwordTechniqueEffect.EXTRA_DURATIONS.has(ability):
					actual_contact_events=1
					actual_contact_time=0
			else:
				old_view=player.view
				old_view.play_sword_technique(ability,aim,3.0)
			player.view.sword_technique.set_process(false)
		else:
			if p.updated:
				new_player=player
				new_enemy=enemy
				enemy.projectile_requested.connect(spawn_spine)
			if actor_kind == 1:
				enemy.recovery_left=0
				if ability != "guardian_idle": enemy._begin_attack()
			elif actor_kind == 2: enemy.charge_windup=0.42
			elif actor_kind == 4:
				enemy.special_left=1.65
				enemy.spine_windup=0.34
		p.stage.queue_redraw()

func spawn_spine(origin: Vector2,aim: Vector2,damage: int) -> void:
	var shot:=EnemyProjectile.new()
	panels[1].world.add_child(shot)
	shot.setup(origin,aim,damage,new_player)
	shot.visual_offset=Vector2(0,-18)
	shot.set_physics_process(false)
	projectiles.append(shot)
	fired=true

func seek(value: float) -> void:
	setup_cast()
	time=0
	advance(clampf(value,0,duration))
	refresh_visuals()

func advance(delta: float) -> void:
	var old_time:=time
	time=minf(duration,time+maxf(0,delta))
	if actor_kind == 0:
		new_player.class_combat.tick(time-old_time)
		if ability == "guarda_reativa" and old_time < contact_time and time >= contact_time:
			new_player.receive_damage(8)
			actual_contact_events=1
			actual_contact_time=contact_time
	elif actor_kind == 1:
		# Same boss implementation, deterministic small steps only for offline seek.
		var remaining:=time-old_time
		while remaining > 0.000001 and ability != "guardian_idle":
			var step:=minf(remaining,1.0/240.0)
			new_enemy._physics_process(step)
			remaining-=step
		if new_player.health.current < new_player.health.maximum:
			actual_contact_events=1
			actual_contact_time=contact_time
	elif actor_kind in [2,3]:
		new_enemy.charge_windup=maxf(0,contact_time-time) if actor_kind == 2 else 0.0
		if old_time < contact_time and time >= contact_time:
			new_enemy._try_contact(new_enemy.global_position.distance_to(new_player.global_position))
			actual_contact_events=1 if new_player.health.current < new_player.health.maximum else 0
			actual_contact_time=contact_time if actual_contact_events else -1
	else:
		# Advance the existing cactus/projectile paths, including swept collision.
		var remaining:=time-old_time
		var advanced:=old_time
		while remaining > 0.000001:
			var step:=minf(remaining,1.0/240.0)
			var hp_before:=new_player.health.current
			new_enemy.special_left=maxf(0,new_enemy.special_left-step)
			new_enemy._cactus_behavior(new_player.position-new_enemy.position,140,step)
			for shot in projectiles:
				if is_instance_valid(shot) and not shot.spent: shot._physics_process(step)
			advanced+=step
			if new_player.health.current < hp_before:
				actual_contact_events+=1
				actual_contact_time=advanced
			remaining-=step
	real_damage=new_enemy.health.maximum-new_enemy.health.current if actor_kind == 0 and ability != "guarda_reativa" else new_player.health.maximum-new_player.health.current

func refresh_visuals() -> void:
	var aim: Vector2=DIRECTIONS[direction_index]
	for p in panels:
		p.stage.show_hitbox=hitboxes
		p.stage.queue_redraw()
		var player: PlayerActor=p.player
		var enemy: EnemyActor=p.enemy
		player.view.z_as_relative=false
		player.view.z_index=roundi(player.position.y)+100
		enemy.view.z_as_relative=false
		enemy.view.z_index=roundi(enemy.position.y)+100
		player.view.walking=walk_preview
		player.view.anim_frame=int(time*10)%4
		if actor_kind == 0:
			var fx: SwordTechniqueEffect=player.view.sword_technique
			if fx.kind.is_empty() and time >= duration:
				player.view.queue_redraw()
				continue
			fx.elapsed=time
			fx.remaining=maxf(0,duration-time)
			fx.externally_clocked=true
			if ability == "guarda_reativa": fx.counter_elapsed=time-contact_time if time >= contact_time and time < contact_time+0.22 else -1.0
			fx.queue_redraw()
			var after:=maxf(0,time-contact_time)
			if not p.updated: enemy.view.damage_amount=real_damage
			enemy.view.flash_left=maxf(0,0.14-after) if time >= contact_time else 0
			enemy.view.impact_left=maxf(0,0.12-after) if time >= contact_time else 0
			enemy.view.damage_left=maxf(0,0.85-after) if real_damage > 0 else 0
		else:
			enemy.view.warning=time < contact_time and ability != "guardian_idle"
			enemy.view.attack_left=0.18 if time >= contact_time and time < contact_time+0.12 else 0
			if actor_kind == 1:
				enemy.view.telegraph_kind=0
				enemy.view.telegraph_direction=aim
				if p.updated:
					enemy.view.sample_time=-time-0.001 if ability == "guardian_idle" else time
					enemy.view.sample_direction=aim
			elif p.updated:
				enemy.view.sample_frame=0 if time == 0 else (1 if time < contact_time*0.5 else 2 if time < contact_time else 3 if time < contact_time+0.08 else 4 if time < duration*0.8 else 5)
				enemy.view.sample_direction=aim
		player.view.queue_redraw()
		enemy.view.queue_redraw()
	seeking=true
	slider.value=time
	seeking=false
	var action_name:=attack_choice.get_item_text(attack_choice.selected)
	var event_text:="CONTATO REAL em %.3f s · dano %d · evento %d" % [actual_contact_time,real_damage,actual_contact_events] if actual_contact_events else "Preparação / sem dano aplicado"
	status.text="%s · %.3f / %.3f s · marco %.3f s\n%s\n%s" % [action_name,time,duration,contact_time,event_text,"Mandacaru: marco = disparo; dano depende da colisão do espinho." if actor_kind == 4 else "Antes: reprodução da arte anterior; eventos e HP são medidos no painel PROPOSTA."]
	if ability == "guardian_idle": status.text="Repouso do Guardião · copa e torso · sem ataque ou dano\n%.3f / %.3f s" % [time,duration]

func step_frame(signum: int) -> void:
	playing=false
	play_button.text="Reproduzir"
	var markers: Array=[0.0,contact_time*0.5,contact_time,contact_time+0.08,duration*0.8,duration]
	if actor_kind == 0 and SwordTechniqueTiming.FRAMES.has(ability):
		markers=[0.0]
		var t:=0.0
		for step: float in SwordTechniqueTiming.FRAMES[ability]:
			t+=step
			markers.append(t)
	if signum > 0:
		for marker: float in markers:
			if marker > time+0.00001: seek(marker); return
	else:
		markers.reverse()
		for marker: float in markers:
			if marker < time-0.00001: seek(marker); return

func _process(delta: float) -> void:
	if not playing or panels.is_empty() or not panels[1].has("player"): return
	if time >= duration:
		if looping: seek(0)
		else: playing=false; play_button.text="Reproduzir"
		return
	advance(delta*speed)
	refresh_visuals()
