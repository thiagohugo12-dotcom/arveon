class_name RPGPanel
extends PanelContainer

signal action_requested(action: String, id: String, expected: int)
signal closed
signal bag_requested
var content: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
var progress: GameProgress
var tab := 0
var tabs: HBoxContainer
var talent_weapon := "espada"
var talent_selection := "corte"
var talent_tree: TalentTree
var talent_detail: Label
var talent_buy: Button

func _ready() -> void:
	visible = false
	DiaryArt.skin(self)
	var column := VBoxContainer.new()
	add_child(column)
	column.add_child(DiaryTheme.label("Diário do Explorador",18))
	var navigation := HBoxContainer.new()
	column.add_child(navigation)
	for i in range(3):
		var link := Button.new()
		link.text = ["Mochila","Proficiências","Habilidades"][i]
		link.add_theme_font_size_override("font_size",11)
		link.custom_minimum_size.y = 44
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		link.pressed.connect(func():
			if i == 0: bag_requested.emit()
			else:
				tab = 2 if i == 1 else 1
				refresh(progress)
		)
		navigation.add_child(link)
	tabs = navigation
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.custom_minimum_size.x = 240
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	close_button = Button.new()
	close_button.text = "Fechar · C / Esc"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(func(): closed.emit())
	var footer := HBoxContainer.new()
	column.add_child(footer)
	var character := Button.new()
	character.text = "Personagem"
	character.custom_minimum_size.y = 44
	character.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character.pressed.connect(func():
		tab = 0
		refresh(progress)
	)
	footer.add_child(character)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(close_button)

func refresh(value: GameProgress) -> void:
	progress = value
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if tab == 0:
		var lvl := progress.level()
		_heading("AVENTUREIRO  ·  NÍVEL %d" % lvl)
		_label("XP %d / %d  ·  total %d" % [progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl), progress.xp] if lvl < RPGRules.MAX_LEVEL else "Nível máximo  ·  XP total %d" % progress.xp)
		_heading("ATRIBUTOS  ·  %d PONTOS" % progress.attribute_points())
		for name: String in RPGRules.ATTRIBUTES:
			var card := _card()
			var row := HBoxContainer.new()
			card.add_child(row)
			var label := Label.new()
			label.text = "%s\n%d / 198" % [name, progress.attributes[name]]
			label.add_theme_font_size_override("font_size", 13)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var button := Button.new()
			button.text = "+1"
			button.custom_minimum_size = Vector2(52, 44)
			button.disabled = progress.attribute_points() < 1 or int(progress.attributes[name]) >= 198
			button.pressed.connect(func(): action_requested.emit("attribute", name, 0))
			row.add_child(button)
		var values := progress.combat_stats()
		_heading("COMBATE")
		_label("Dano %d  ·  HP %d  ·  Vel %d\nEspírito %d  ·  Defesa %d" % [values.damage, values.hp, values.speed, values.spirit, values.armor], _card())
		_label("Força +2 dano  ·  Vitalidade +8 HP\nAgilidade: movimento e recarga (até −20%)\nEspírito: dano, HP e habilidades")
	elif tab == 1:
		_heading("SUA CONFIGURAÇÃO DE COMBATE")
		_label("Dash fixo + 3 habilidades. Ataque básico automático conforme a arma.")
		_label("Personalização de técnicas · Em desenvolvimento")
		_heading("HABILIDADES  ·  %d PONTOS" % progress.skill_points())
		var descriptions := ["Ao redor: raio 90 · 5s. Grau aumenta dano.", "Avanço ofensivo · 8s. Grau aumenta dano.", "Dano e resistência por 6–8s · 35s. Grau aumenta o buff."]
		for i in range(3):
			var name: String = RPGRules.SKILLS[i]
			var card := _card()
			var row := HBoxContainer.new()
			card.add_child(row)
			row.add_child(PixelItemIcon.new(["espada","lanca","cajado"][i]))
			row.add_child(DiaryTheme.label("Espaço %d · %s" % [i+1,["Corte","Investida","Fúria"][i]],14))
			_label("%s  ·  GRAU %d · BASE %d / 3" % [name.to_upper(), progress.skill_rank(i),progress.skills[name]], card, true)
			_label(descriptions[i], card)
			var button := Button.new()
			button.text = "Melhorar  ·  1 ponto"
			button.custom_minimum_size.y = 44
			button.disabled = progress.skill_points() < 1 or int(progress.skills[name]) >= 3
			button.pressed.connect(func(): action_requested.emit("skill", name, 0))
			card.add_child(button)
		_label("PC: 1 Corte  ·  2 Investida  ·  3 Fúria\nDireção: joystick/WASD ou última direção.\nIndisponível em menus e na área segura.")
	else:
		_talent_page()
	for i in range(tabs.get_child_count()): DiaryTheme.select(tabs.get_child(i),(tab == 2 and i == 1) or (tab == 1 and i == 2))

func _talent_page() -> void:
	_heading("ÁRVORE DE TALENTOS · %d PONTOS" % progress.skill_points())
	var weapons := HBoxContainer.new()
	weapons.add_theme_constant_override("separation",4)
	content.add_child(weapons)
	for id: String in ArsenalRules.CATEGORIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(44,44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = ArsenalRules.category_name(id)
		button.pressed.connect(func():
			talent_weapon = id
			refresh(progress)
		)
		weapons.add_child(button)
		var icon := PixelItemIcon.new(id)
		icon.position = Vector2(7,7)
		button.add_child(icon)
		DiaryTheme.select(button,id == talent_weapon)
	var level := progress.talents.level(talent_weapon)
	_heading("%s · PROFICIÊNCIA %d / 30" % [ArsenalRules.category_name(talent_weapon).to_upper(),level])
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.show_percentage = false
	bar.max_value = TalentRules.xp_floor(level+1)-TalentRules.xp_floor(level) if level < 30 else 1
	bar.value = int(progress.talents.xp[talent_weapon])-TalentRules.xp_floor(level) if level < 30 else 1
	content.add_child(bar)
	_label("Acertos evoluem a arma · 1 ponto por nível do personagem.")
	talent_tree = TalentTree.new(progress,talent_weapon,talent_selection)
	talent_tree.selected.connect(func(id: String):
		talent_selection = id
		_talent_description()
		scroll.ensure_control_visible(talent_buy)
	)
	content.add_child(talent_tree)
	talent_detail = DiaryTheme.label("",12)
	content.add_child(talent_detail)
	talent_buy = Button.new()
	talent_buy.custom_minimum_size.y = 44
	talent_buy.pressed.connect(func(): action_requested.emit("talent",talent_weapon+":"+talent_selection,0))
	content.add_child(talent_buy)
	var return_to_tree := Button.new()
	return_to_tree.text = "Voltar à árvore"
	return_to_tree.custom_minimum_size.y = 44
	return_to_tree.pressed.connect(func(): scroll.ensure_control_visible(talent_tree.buttons[talent_selection]))
	content.add_child(return_to_tree)
	_label("Verde: aprendido · claro: disponível · apagado: bloqueado.\nValores iniciais de teste. Técnicas já adquiridas estão preservadas; novas técnicas e escolha de slots virão em outra etapa.")
	_talent_description()

func _talent_description() -> void:
	var rule: Dictionary = TalentRules.NODES[talent_selection]
	var learned := progress.talents.owns(talent_weapon,talent_selection)
	var requirement := "Proficiência %d" % rule.prof
	if not rule.parent.is_empty(): requirement += " + "+TalentRules.NODES[rule.parent].name
	talent_detail.text = "%s · %s\n%s\nRequer %s · custo 1 ponto" % [rule.name,rule.kind,rule.description,requirement]
	talent_buy.text = "Aprendido" if learned else "Aprender · 1 ponto"
	talent_buy.disabled = not progress.talents.available(talent_weapon,talent_selection,progress.skill_points())

func _heading(text: String) -> void:
	_label(text, content, true)

func _card() -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := DiaryTheme.box(Color("#e6d1a3"),Color("#bea16a"),8,1)
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	panel.add_child(body)
	return body

func _label(text: String, destination: Container = null, heading: bool = false) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13 if not heading else 14)
	if heading:
		label.add_theme_color_override("font_color", DiaryTheme.GREEN)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(destination if destination != null else content).add_child(label)
