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
var prof_section := 0 # Domain / existing tree.
var mastery_buttons: Dictionary = {}
var attribute_buttons: Dictionary = {}
var category_buttons: Dictionary = {}
var prof_tabs: Array[Button] = []
var attribute_grid: GridContainer
var mastery_grid: GridContainer
var allow_respec := false

func _ready() -> void:
	resized.connect(_reflow_stats)
	visible = false
	DiaryArt.skin(self)
	var column := VBoxContainer.new()
	add_child(column)
	var title := DiaryTheme.label("Diário do Explorador",26)
	title.add_theme_font_override("font",DiaryTheme.heading_font())
	column.add_child(title)
	var navigation := HBoxContainer.new()
	column.add_child(navigation)
	for i in range(3):
		var link := DiaryTab.new()
		link.glyph = ["bag","book","fury"][i]
		link.text = ["Mochila","Proficiências","Habilidades"][i]
		link.add_theme_font_size_override("font_size",15)
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
	talent_tree = null
	attribute_grid = null
	mastery_grid = null
	mastery_buttons.clear()
	attribute_buttons.clear()
	category_buttons.clear()
	prof_tabs.clear()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if tab == 0:
		var lvl := progress.level()
		_heading("%s · NÍVEL %d" % [progress.active_class().to_upper(),lvl])
		_label("XP %d / %d  ·  total %d" % [progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl), progress.xp] if lvl < RPGRules.MAX_LEVEL else "Nível máximo  ·  XP total %d" % progress.xp)
		_heading("ATRIBUTOS  ·  %d PONTOS" % progress.attribute_points())
		_label("+2 atributos e +1 talento por nível. A classe acompanha a arma.")
		attribute_grid = GridContainer.new()
		attribute_grid.columns = 2 if size.x >= 620 else 1
		attribute_grid.add_theme_constant_override("h_separation",8)
		attribute_grid.add_theme_constant_override("v_separation",6)
		content.add_child(attribute_grid)
		for name: String in RPGRules.ATTRIBUTES:
			var card := _card(attribute_grid)
			var row := HBoxContainer.new()
			card.add_child(row)
			var label := Label.new()
			label.text = "%s · %d" % [name, progress.attributes[name]]
			label.add_theme_font_size_override("font_size", 13)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var button := Button.new()
			button.text = "+1"
			button.custom_minimum_size = Vector2(52, 44)
			button.disabled = progress.attribute_points() < 1 or int(progress.attributes[name]) >= 198
			button.pressed.connect(func(): action_requested.emit("attribute", name, 0))
			row.add_child(button)
			attribute_buttons[name] = button
			_label(RPGRules.ATTRIBUTE_HELP[name],card)
		var values := progress.combat_stats()
		_heading("COMBATE")
		_label("Base física %d · Base mágica %d\nAtaque básico %d · Crítico %.1f%%\nHP %d · Movimento %.1f · Armadura %d\nResistência %.1f%% · Intervalo −%.1f%%" % [values.physical,values.magical,values.damage,values.critical_chance*100,values.hp,values.speed,values.armor,values.resistance*100,(1.0-values.basic_interval_factor)*100], _card())
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
	_heading("PROFICIÊNCIAS DAS ARMAS")
	var weapons := HBoxContainer.new()
	weapons.add_theme_constant_override("separation",4)
	content.add_child(weapons)
	for id: String in ArsenalRules.CATEGORIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(44,56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = ArsenalRules.category_name(id)
		button.pressed.connect(func():
			talent_weapon = id
			refresh(progress)
		)
		weapons.add_child(button)
		category_buttons[id] = button
		var icon := PixelItemIcon.new(id)
		icon.position = Vector2(7,7)
		button.add_child(icon)
		var number := DiaryTheme.label("%d · +%d" % [progress.talents.level(id),progress.talents.mastery_points(id)],10)
		number.position = Vector2(3,37)
		number.size = Vector2(44,14)
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.add_theme_color_override("font_color",Color("#fff0cf") if id == talent_weapon else DiaryTheme.INK)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(number)
		DiaryTheme.select(button,id == talent_weapon)
	var level := progress.talents.level(talent_weapon)
	_heading("%s · PROFICIÊNCIA %d / 30" % [ArsenalRules.category_name(talent_weapon).to_upper(),level])
	_label("%s%s" % [TalentRules.CLASSES[talent_weapon]," · classe ativa" if progress.active_category() == talent_weapon else " · bônus guardados até equipar"])
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.show_percentage = false
	bar.max_value = TalentRules.xp_floor(level+1)-TalentRules.xp_floor(level) if level < 30 else 1
	bar.value = int(progress.talents.xp[talent_weapon])-TalentRules.xp_floor(level) if level < 30 else 1
	content.add_child(bar)
	_label("XP %d / %d · +%.1f%% dano da categoria" % [int(progress.talents.xp[talent_weapon])-TalentRules.xp_floor(level),TalentRules.xp_floor(level+1)-TalentRules.xp_floor(level),(level-1)*0.5] if level < 30 else "Proficiência máxima · +14,5% dano da categoria")
	var sections := HBoxContainer.new()
	content.add_child(sections)
	for i in range(2):
		var button := Button.new()
		button.text = ["Domínio · %d" % progress.talents.mastery_points(talent_weapon),"Talentos · %d" % progress.skill_points()][i]
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func():
			prof_section = i
			refresh(progress)
			scroll.scroll_vertical = 0
		)
		sections.add_child(button)
		prof_tabs.append(button)
		DiaryTheme.select(button,prof_section == i)
	if prof_section == 0:
		_mastery_page()
		return
	_heading("ÁRVORE · %d PONTOS DE TALENTO" % progress.skill_points())
	_label("Nível do personagem dá pontos. Proficiência abre os caminhos.")
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
	var reset := Button.new()
	reset.name = "ResetTree"
	reset.text = "Redistribuir talentos\nGrátis na área segura"
	reset.custom_minimum_size.y = 52
	reset.disabled = not allow_respec or progress.talents.learned[talent_weapon].is_empty()
	reset.pressed.connect(func(): action_requested.emit("reset_tree",talent_weapon,0))
	content.add_child(reset)
	_label("Verde: aprendido · claro: disponível · apagado: bloqueado.\nValores iniciais de teste. Técnicas já adquiridas estão preservadas; novas técnicas e escolha de slots virão em outra etapa.")
	_talent_description()

func _mastery_page() -> void:
	_heading("DOMÍNIO · %d PONTOS DISPONÍVEIS" % progress.talents.mastery_points(talent_weapon))
	_label("+1 ponto por nível de proficiência. Cada categoria tem seu próprio saldo.")
	mastery_grid = GridContainer.new()
	mastery_grid.columns = 2 if size.x >= 620 else 1
	mastery_grid.add_theme_constant_override("h_separation",8)
	mastery_grid.add_theme_constant_override("v_separation",6)
	content.add_child(mastery_grid)
	for stat: String in TalentRules.MASTERY:
		var rule: Dictionary = TalentRules.MASTERY[stat]
		var invested := int(progress.talents.mastery[talent_weapon][stat])
		var card := _card(mastery_grid)
		var row := HBoxContainer.new()
		card.add_child(row)
		var name_label := DiaryTheme.label("%s · %d/%d" % [stat,invested,rule.cap],13)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(name_label)
		var button := Button.new()
		button.text = "+1"
		button.custom_minimum_size = Vector2(52,44)
		button.disabled = progress.talents.mastery_points(talent_weapon) < 1 or invested >= int(rule.cap)
		button.pressed.connect(func(): action_requested.emit("mastery",talent_weapon+":"+stat,invested))
		row.add_child(button)
		mastery_buttons[stat] = button
		var descriptions := {"Dano":"+1% por ponto · somente ataques básicos.","Dano Especial":"+1,25% por ponto · somente dano de técnicas.","Crítico":"+1% por ponto · chance base 5%.","Dano Crítico":"+3% por ponto · multiplicador base 150%."}
		_label(descriptions[stat],card)
	var refund := Button.new()
	refund.name = "ResetMastery"
	refund.text = "Redistribuir Domínio\nGrátis na área segura"
	refund.custom_minimum_size.y = 52
	refund.disabled = not allow_respec or progress.talents.mastery_points(talent_weapon) >= progress.talents.level(talent_weapon)-1
	refund.pressed.connect(func(): action_requested.emit("reset_mastery",talent_weapon,0))
	content.add_child(refund)
	var bonus := progress.talents.mastery_bonuses(talent_weapon)
	_label("Básicos +%.1f%% · Técnicas +%.1f%%\nCrítico %.1f%% · Dano crítico %.0f%%" % [(bonus.automatic+bonus.basic)*100,(bonus.automatic+bonus.special)*100,bonus.critical_chance*100,bonus.critical_multiplier*100],_card())
	_label("Dano real evolui a arma: 1 XP a cada 10 HP removidos. Frações são guardadas. Valores de teste.")

func _reflow_stats() -> void:
	if is_instance_valid(attribute_grid): attribute_grid.columns = 2 if size.x >= 620 else 1
	if is_instance_valid(mastery_grid): mastery_grid.columns = 2 if size.x >= 620 else 1

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

func _card(destination: Container = null) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := DiaryTheme.box(Color("#e6d1a3"),Color("#bea16a"),8,1)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(destination if destination != null else content).add_child(panel)
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
