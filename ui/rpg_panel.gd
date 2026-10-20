class_name RPGPanel
extends PanelContainer

signal action_requested(action: String, id: String, expected: int)
signal closed
signal bag_requested
var content: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
var header_close: Button
var footer_close: Button
var training_back: Button
var progress: GameProgress
var tab := 0
var tabs: HBoxContainer
var talent_weapon := "espada"
var talent_selection := "corte"
var talent_tree: TalentTree
var talent_detail: Label
var talent_buy: Button
var sword_selection := "skill1:talho_agil"
var sword_detail: VBoxContainer
var sword_tree: SwordEvolutionTree
var prof_section := 1 # Abrir diretamente a árvore visual; Treinamento continua acessível.
var mastery_buttons: Dictionary = {}
var attribute_buttons: Dictionary = {}
var category_buttons: Dictionary = {}
var prof_tabs: Array[Button] = []
var attribute_grid: GridContainer
var mastery_grid: GridContainer
var allow_respec := false
var ability_buttons: Dictionary = {}
var skill_section := 0
var skill_choice := ""
var skill_target_slot := -1
var skill_section_buttons: Array[Button] = []
var skill_catalog_buttons: Dictionary = {}
var skill_detail: VBoxContainer
var skill_catalog: VBoxContainer
var page_title: Label
var diary_return: Button
var skill_slots: Array[Button] = []
var passive_buttons: Dictionary = {}
var specialization_buttons: Dictionary = {}

func _ready() -> void:
	resized.connect(_reflow_stats)
	visible = false
	DiaryArt.skin(self)
	var column := VBoxContainer.new()
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	page_title = DiaryTheme.label("Diário do Explorador",26)
	page_title.add_theme_font_override("font",DiaryTheme.heading_font())
	page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(page_title)
	training_back = Button.new()
	training_back.text = "← Árvore"
	training_back.tooltip_text = "Voltar à árvore de talentos"
	training_back.add_theme_font_size_override("font_size",12)
	training_back.custom_minimum_size = Vector2(92,44)
	training_back.pressed.connect(func():
		tab = 2
		prof_section = 1
		refresh(progress)
		scroll.scroll_vertical = 0
	)
	header.add_child(training_back)
	var exit := Button.new()
	header_close = exit
	exit.text = "×"
	exit.custom_minimum_size = Vector2(44,44)
	exit.pressed.connect(func(): closed.emit())
	header.add_child(exit)
	var navigation := HBoxContainer.new()
	column.add_child(navigation)
	for i in range(3):
		var link := DiaryTab.new()
		link.glyph = ["character","book","fury"][i]
		link.text = ["Ficha","Proficiências","Habilidades"][i]
		link.add_theme_font_size_override("font_size",15)
		link.custom_minimum_size.y = 44
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		link.pressed.connect(func():
			tab = 0 if i == 0 else 2 if i == 1 else 1
			refresh(progress)
			scroll.scroll_vertical = 0
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
	character.text = "Voltar ao diário"
	diary_return = character
	character.custom_minimum_size.y = 44
	character.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character.pressed.connect(func():
		tab = 0
		refresh(progress)
	)
	footer.add_child(character)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(close_button)
	footer_close = close_button

func refresh(value: GameProgress) -> void:
	progress = value
	var focused_page := tab == 1 or tab == 2 and prof_section == 0
	page_title.text = "Habilidades" if tab == 1 else "Treinamento" if tab == 2 and prof_section == 0 else "Ficha do Personagem"
	add_theme_stylebox_override("panel",DiaryTheme.piece("frame",22))
	tabs.visible = not focused_page
	diary_return.visible = tab != 0
	diary_return.text = "Voltar ao diário" if focused_page else "Personagem"
	footer_close.visible = not focused_page
	header_close.visible = focused_page
	training_back.visible = tab == 2 and prof_section == 0
	close_button = header_close if focused_page else footer_close
	skill_slots.clear()
	talent_tree = null
	sword_detail = null
	sword_tree = null
	talent_buy = null
	attribute_grid = null
	mastery_grid = null
	mastery_buttons.clear()
	attribute_buttons.clear()
	category_buttons.clear()
	ability_buttons.clear()
	passive_buttons.clear()
	specialization_buttons.clear()
	skill_section_buttons.clear()
	skill_catalog_buttons.clear()
	skill_detail = null
	skill_catalog = null
	prof_tabs.clear()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if tab == 0:
		var lvl := progress.level()
		_heading("%s · NÍVEL %d" % [progress.active_class().to_upper(),lvl])
		_label("XP %d / %d  ·  total %d" % [progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl), progress.xp] if lvl < RPGRules.MAX_LEVEL else "Nível máximo  ·  XP total %d" % progress.xp)
		_profile_summary()
		_profile_equipment()
		_profile_materials()
		_heading("ATRIBUTOS  ·  %d PONTOS" % progress.attribute_points())
		_label("Use os pontos para definir sua ficha. A classe acompanha a arma equipada.")
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
			button.disabled = not allow_respec or progress.attribute_points() < 1 or int(progress.attributes[name]) >= 198
			button.pressed.connect(func(): action_requested.emit("attribute", name, 0))
			row.add_child(button)
			attribute_buttons[name] = button
			_label(RPGRules.ATTRIBUTE_HELP[name],card)
		_heading("MODO TREINO")
		if progress.training_mode:
			_label("Sessão temporária · nada daqui é salvo. Troque de arma na Mochila e configure skills livremente.")
			if progress.ascension.current_floor == 2:
				_training_button("Restaurar depósitos", "training_mining_reset")
				_training_button("+5 minérios comuns", "training_mining_common")
				_training_button("+5 minérios raros", "training_mining_rare")
			_training_button("Abrir Ferreiro de treino", "training_smith")
			_training_button("Recarregar skills e Ultimates", "training_refill")
			_training_button("Encerrar treino · voltar ao personagem", "training_exit")
		else:
			_label("Experimente as cinco armas, habilidades e talentos sem alterar seu save.")
			_training_button("Entrar no modo treino", "training_start")
	elif tab == 1:
		_skills_page()
	else:
		_talent_page()
	for i in range(tabs.get_child_count()): DiaryTheme.select(tabs.get_child(i),(tab == 2 and i == 1) or (tab == 1 and i == 2))

func _talent_page() -> void:
	var compact := true
	_category_selector(compact)
	var level := progress.talents.level(talent_weapon)
	_heading("%s · PROFICIÊNCIA %d / %d" % [ArsenalRules.category_name(talent_weapon).to_upper(),level,TalentRules.MAX_PROFICIENCY])
	if not compact:
		_label("%s%s" % [TalentRules.CLASSES[talent_weapon]," · classe ativa" if progress.active_category() == talent_weapon else " · bônus guardados até equipar"])
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 8
	bar.show_percentage = false
	bar.max_value = TalentRules.xp_floor(level+1)-TalentRules.xp_floor(level) if level < TalentRules.MAX_PROFICIENCY else 1
	bar.value = int(progress.talents.xp[talent_weapon])-TalentRules.xp_floor(level) if level < TalentRules.MAX_PROFICIENCY else 1
	content.add_child(bar)
	var xp_text := "XP %d / %d · +%.1f%% dano da categoria" % [int(progress.talents.xp[talent_weapon])-TalentRules.xp_floor(level),TalentRules.xp_floor(level+1)-TalentRules.xp_floor(level),(level-1)*0.5] if level < TalentRules.MAX_PROFICIENCY else "Proficiência máxima · +29,5% dano da categoria"
	bar.tooltip_text = xp_text
	if not compact: _label(xp_text)
	var sections := HBoxContainer.new()
	content.add_child(sections)
	sections.visible = prof_section != 0
	for i in range(2):
		var button := Button.new()
		button.text = ["Treinar arma","Árvore de talentos"][i]
		button.add_theme_font_size_override("font_size",14)
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
	if talent_weapon == "espada":
		_sword_evolution_page()
		return
	_heading("ÁRVORE · %d PONTOS DE TALENTO" % progress.skill_points())
	_label("Nível do personagem dá pontos. Proficiência abre os caminhos.")
	var rules := AbilityRules.talent_tree(talent_weapon)
	if not rules.has(talent_selection): talent_selection = rules.keys()[0]
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
	reset.text = "Redistribuir talentos e graus\nGrátis na área segura"
	reset.custom_minimum_size.y = 52
	reset.disabled = not allow_respec or progress.abilities.talents[talent_weapon].is_empty() and progress.abilities.grades[talent_weapon].is_empty()
	reset.pressed.connect(func(): action_requested.emit("reset_tree",talent_weapon,0))
	content.add_child(reset)
	_label("Verde: aprendido · claro: disponível · apagado: bloqueado.\nTalentos custam pontos de talento. Passivas, especialização e Maestria são gratuitas. Valores provisórios.")
	_talent_description()


func _sword_evolution_page() -> void:
	var prof := progress.talents.level("espada")
	_label("Pontos de talento disponíveis: %d" % progress.skill_points())
	var tree := SwordEvolutionTree.new(progress,sword_selection)
	tree.node_selected.connect(func(kind: String, id: String):
		sword_selection = kind+":"+id
		refresh(progress)
		if sword_detail != null:
			_show_sword_detail.call_deferred()
	)
	content.add_child(tree)
	sword_tree = tree
	if size.x > size.y:
		_show_sword_node.call_deferred()
	sword_detail = _card()
	var pair := sword_selection.split(":")
	var kind := pair[0] if pair.size() == 2 else "skill1"
	var id := pair[1] if pair.size() == 2 else "talho_agil"
	var rule: Dictionary = {}
	var desc := ""
	var title := ""
	match kind:
		"skill1":
			rule = AbilityRules.CATEGORIES.espada.skill1
			title = rule.name+" · SKILL 1"
			desc = "Técnica inicial fixa. Recarga %.0fs. Não ocupa os dois espaços configuráveis." % rule.cooldown
		"normal", "ultimate":
			rule = AbilityRules.active_skill("espada",id)
			if not rule.is_empty():
				title = rule.name+(" · ULTIMATE" if kind == "ultimate" else " · TÉCNICA ATIVA")
				desc = "Requer proficiência %d." % int(rule.prof)
				if kind == "ultimate":
					desc += " Carregue causando dano. Quando chegar a 100%, ela aparece em um botão próprio no HUD."
				else:
					desc += " Recarga %.0fs · Grau %d/4." % [rule.cooldown,int(progress.abilities.grades.espada.get(id,1))]
		"passive":
			rule = AbilityRules.passive("espada",id)
			if not rule.is_empty():
				title = rule.name+" · PASSIVA EQUIPÁVEL"
				desc = AbilityRules.DESCRIPTIONS[id]
		"talent":
			rule = AbilityRules.talent("espada",id)
			if not rule.is_empty():
				title = AbilityRules.TALENT_NAMES[id]+" · TALENTO"
				desc = AbilityRules.DESCRIPTIONS[id]
				if not rule.parent.is_empty():
					desc += "\nRequer também: "+AbilityRules.TALENT_NAMES[rule.parent]
		"specialization":
			title = "ESPECIALIZAÇÃO"
			desc = "Escolha entre Duelista e Guardião da Lâmina. Pode alterar gratuitamente na área segura."
		"mastery":
			title = "LÂMINA PERFEITA · MAESTRIA 30"
			desc = AbilityRules.MASTERY_HELP.espada+"\nAutomática. Não exige equipar a Ultimate."
		"supreme":
			title = "ASCENSÃO DA LÂMINA · MAESTRIA SUPREMA 60"
			desc = "Automática: a Ultimate Dança das Lâminas causa 20% mais dano a partir da proficiência 60."
	if title.is_empty():
		title = "Escolha um marco da árvore"
	_label(title,sword_detail,true)
	_label(desc,sword_detail)
	var required := int(rule.get("prof",1))
	if kind == "specialization": required = 18
	if kind == "mastery": required = 30
	if kind == "supreme": required = 60
	if prof < required:
		_label("Bloqueado · alcance proficiência %d." % required,sword_detail)
	if not allow_respec:
		_label("Somente consulta fora da área segura.",sword_detail)
	var loadout: Dictionary = progress.abilities.loadouts.espada
	if kind in ["normal","ultimate"] and not rule.is_empty():
		if kind == "ultimate":
			var ultimate_button := Button.new()
			ultimate_button.text = "Ultimate equipada" if loadout.ultimate == id else "Equipar Ultimate"
			ultimate_button.custom_minimum_size.y = 44
			ultimate_button.disabled = not allow_respec or prof < required or loadout.ultimate == id
			ultimate_button.pressed.connect(func(): action_requested.emit("equip_ultimate","espada:"+id,0))
			sword_detail.add_child(ultimate_button)
			return
		for slot in range(2):
			var button := Button.new()
			button.text = ("Equipada na " if loadout.skills[slot] == id else "Equipar na ")+"Skill %d" % (slot+2)
			button.custom_minimum_size.y = 44
			button.disabled = not allow_respec or prof < required or loadout.skills[slot] == id
			button.pressed.connect(func(): action_requested.emit("equip_skill","espada:"+id,slot))
			sword_detail.add_child(button)
		if kind == "normal":
			var grade: int = progress.abilities.grades.espada.get(id,1)
			var improve := Button.new()
			improve.text = "Melhorar · 1 ponto de talento" if grade < 4 else "Grau máximo"
			improve.add_theme_font_size_override("font_size",14)
			improve.custom_minimum_size.y = 44
			improve.disabled = not allow_respec or prof < required or grade >= 4 or progress.skill_points() < 1
			improve.pressed.connect(func(): action_requested.emit("skill","espada:"+id,grade))
			sword_detail.add_child(improve)
	elif kind == "passive" and not rule.is_empty():
		for slot in range(2):
			var button := Button.new()
			button.text = ("Equipada na " if loadout.passives[slot] == id else "Equipar na ")+"Passiva %d" % (slot+1)
			button.custom_minimum_size.y = 44
			button.disabled = not allow_respec or prof < required or loadout.passives[slot] == id
			button.pressed.connect(func(): action_requested.emit("equip_passive","espada:"+id,slot))
			sword_detail.add_child(button)
	elif kind == "talent" and not rule.is_empty():
		var learned: bool = progress.abilities.talents.espada.has(id)
		var ready: bool = rule.parent.is_empty() or progress.abilities.talents.espada.has(rule.parent)
		var buy := Button.new()
		buy.text = "Aprendido" if learned else "Aprender · 1 ponto de talento"
		buy.custom_minimum_size.y = 44
		buy.disabled = not allow_respec or learned or not ready or prof < required or progress.skill_points() < 1
		buy.pressed.connect(func(): action_requested.emit("talent","espada:"+id,0))
		sword_detail.add_child(buy)
		talent_buy = buy
	elif kind == "specialization":
		for style: String in AbilityRules.CATEGORIES.espada.specializations:
			var item: Dictionary = AbilityRules.SPECIALIZATIONS[style]
			_label(item.name+" · "+item.description,sword_detail)
			var button := Button.new()
			button.text = "Escolhido" if loadout.specialization == style else "Escolher "+item.name
			button.custom_minimum_size.y = 44
			button.disabled = not allow_respec or prof < 18 or loadout.specialization == style
			button.pressed.connect(func(): action_requested.emit("specialization","espada:"+style,0))
			sword_detail.add_child(button)
	var back := Button.new()
	back.name = "ReturnToSwordNode"
	back.text = "Voltar ao nó selecionado"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func():
		if is_instance_valid(sword_tree) and sword_tree.buttons.has(sword_selection):
			scroll.ensure_control_visible(sword_tree.buttons[sword_selection])
	)
	content.add_child(back)
	var reset := Button.new()
	reset.text = "Redistribuir talentos e graus\nGrátis no acampamento"
	reset.custom_minimum_size.y = 52
	reset.disabled = not allow_respec or (progress.abilities.talents.espada.is_empty() and progress.abilities.grades.espada.is_empty())
	reset.pressed.connect(func(): action_requested.emit("reset_tree","espada",0))
	content.add_child(reset)
	_label("Skill 1 fixa · Skill 2 e 3 configuráveis · 2 passivas equipáveis · Maestrias automáticas.")

func _show_sword_detail() -> void:
	# Layout must finish before resolving the card position in content coordinates.
	await get_tree().process_frame
	if is_instance_valid(sword_detail):
		var card: Control = sword_detail.get_parent()
		scroll.scroll_vertical = roundi(card.position.y)

func _show_sword_node() -> void:
	await get_tree().process_frame
	if is_instance_valid(sword_tree) and sword_tree.buttons.has(sword_selection):
		scroll.ensure_control_visible(sword_tree.buttons[sword_selection])

func _mastery_page() -> void:
	var points := _card()
	points.get_parent().add_theme_stylebox_override("panel",DiaryTheme.box(Color("#d9e4bb"),DiaryTheme.GREEN,8,1))
	_label("%d pontos desta arma disponíveis" % progress.talents.mastery_points(talent_weapon),points,true)
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
		var icon := PixelItemIcon.new({"Dano":talent_weapon,"Dano Especial":"Essência","Crítico":"Acessório","Dano Crítico":"maestria"}[stat])
		icon.framed = false
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var names := {"Dano":"Ataque básico","Dano Especial":"Dano de técnicas","Crítico":"Chance crítica","Dano Crítico":"Dano crítico"}
		_label(names[stat],text,true)
		var base := 5.0 if stat == "Crítico" else 150.0 if stat == "Dano Crítico" else 0.0
		var current := base+invested*float(rule.step)*100
		var next := base+mini(invested+1,int(rule.cap))*float(rule.step)*100
		_label("%s%% → %s%%" % [String.num(current,2).replace(".",","),String.num(next,2).replace(".",",")],text)
		_label("%d / %d pontos" % [invested,rule.cap],text)
		var button := Button.new()
		button.text = "+1"
		button.custom_minimum_size = Vector2(44,48)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.disabled = not allow_respec or progress.talents.mastery_points(talent_weapon) < 1 or invested >= int(rule.cap)
		button.pressed.connect(func(): action_requested.emit("mastery",talent_weapon+":"+stat,invested))
		DiaryTheme.primary(button)
		row.add_child(button)
		mastery_buttons[stat] = button
	_label("Cada +1 usa um ponto desta arma.\nAlterações gratuitas na área segura." if allow_respec else "Somente consulta · volte ao acampamento para treinar.")
	var refund := Button.new()
	refund.name = "ResetMastery"
	refund.text = "Redistribuir pontos"
	refund.custom_minimum_size.y = 44
	refund.disabled = not allow_respec or progress.talents.mastery_points(talent_weapon) >= progress.talents.level(talent_weapon)-1
	refund.pressed.connect(func(): action_requested.emit("reset_mastery",talent_weapon,0))
	content.add_child(refund)
	var tree := Button.new()
	tree.text = "Árvore de talentos"
	tree.custom_minimum_size.y = 44
	tree.pressed.connect(func(): prof_section = 1; refresh(progress); scroll.scroll_vertical = 0)
	content.add_child(tree)

func _focus_training() -> void:
	await get_tree().process_frame
	if mastery_buttons.has("Dano") and is_instance_valid(mastery_buttons.Dano):
		scroll.ensure_control_visible(mastery_buttons.Dano)

func _reflow_stats() -> void:
	for slot: Button in skill_slots:
		if is_instance_valid(slot): slot.custom_minimum_size.y = 100 if size.x < 340 else 90
	if is_instance_valid(attribute_grid): attribute_grid.columns = 2 if size.x >= 620 else 1
	if is_instance_valid(mastery_grid): mastery_grid.columns = 2 if size.x >= 620 else 1

func _talent_description() -> void:
	var rule: Dictionary = AbilityRules.talent_tree(talent_weapon)[talent_selection]
	var learned: bool = progress.abilities.talents[talent_weapon].has(talent_selection)
	var requirement := "Proficiência %d" % rule.prof
	if not rule.parent.is_empty(): requirement += " + "+AbilityRules.TALENT_NAMES[rule.parent]
	talent_detail.text = "%s · %s\n%s\nRequer %s · custo 1 ponto" % [rule.name,rule.kind,rule.description,requirement]
	talent_buy.text = "Aprendido" if learned else "Aprender · 1 ponto"
	talent_buy.disabled = not allow_respec or learned or progress.skill_points() < 1 or progress.talents.level(talent_weapon) < int(rule.prof) or (not rule.parent.is_empty() and not progress.abilities.talents[talent_weapon].has(rule.parent))

func _profile_summary() -> void:
	var values := progress.combat_stats()
	_heading("RESUMO DE COMBATE")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",5)
	content.add_child(grid)
	_profile_stat(grid,"Ataque",str(values.damage),"Físico %d · Mágico %d" % [values.physical,values.magical],progress.active_category() if not progress.active_category().is_empty() else "Arma")
	_profile_stat(grid,"HP",str(values.hp),"Armadura %d · Resistência %.1f%%" % [values.armor,values.resistance*100],"heart")
	_profile_stat(grid,"Crítico","%.1f%%" % (values.critical_chance*100),"Dano crítico %.0f%%" % (values.critical_multiplier*100),"maestria")
	_profile_stat(grid,"Movimento","%.0f" % values.speed,"Intervalo −%.1f%%" % ((1.0-values.basic_interval_factor)*100),"dash")

func _profile_stat(destination: Container, title: String, value: String, detail: String, icon_id: String) -> void:
	var card := _card(destination)
	var row := HBoxContainer.new()
	card.add_child(row)
	var icon := PixelItemIcon.new(icon_id)
	icon.framed = false
	icon.custom_minimum_size = Vector2(28,28)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_label(title+" · "+value,text,true)
	_label(detail,text)

func _profile_equipment() -> void:
	_heading("EQUIPAMENTO")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	content.add_child(grid)
	for slot: String in RPGRules.SLOTS:
		var id: String = str(progress.equipped.get(slot,""))
		var card := _card(grid)
		var icon := PixelItemIcon.new(ArsenalRules.metadata(id).icon if not id.is_empty() else slot)
		icon.framed = false
		icon.custom_minimum_size = Vector2(34,34)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.add_child(icon)
		var name: String = str(RPGRules.EQUIPMENT[id].name) if not id.is_empty() else "Vazio"
		_label(slot,card,true)
		var upgrade := int(progress.equipment.get(id,0)) if not id.is_empty() else 0
		_label(name+("  +%d" % upgrade if not id.is_empty() else ""),card)
	var manage := Button.new()
	manage.text = "Gerenciar equipamentos"
	manage.custom_minimum_size.y = 44
	manage.pressed.connect(func(): bag_requested.emit())
	content.add_child(manage)

func _profile_materials() -> void:
	_heading("MOCHILA")
	var grid := GridContainer.new()
	grid.columns = 3 if size.x >= 480 else 2
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	content.add_child(grid)
	var found := false
	for item: String in GameProgress.ITEMS:
		var amount := int(progress.bag.get(item,0))
		if amount <= 0:
			continue
		found = true
		var card := _card(grid)
		var row := HBoxContainer.new()
		card.add_child(row)
		var icon := PixelItemIcon.new(item)
		icon.framed = false
		icon.custom_minimum_size = Vector2(26,26)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var label := DiaryTheme.label("%s\n× %d" % [item,amount],11)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
	if not found:
		_label("Nenhum material na mochila.")

func _heading(text: String) -> void:
	_label(text, content, true)

func _card(destination: Container = null) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := DiaryTheme.box(Color("#e6d1a3"),Color("#bea16a"),10,1)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(destination if destination != null else content).add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
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

func _category_selector(compact: bool = true) -> void:
	if not compact: _heading("PROFICIÊNCIAS DAS ARMAS")
	var weapons := HBoxContainer.new()
	weapons.add_theme_constant_override("separation",4)
	content.add_child(weapons)
	for id: String in ArsenalRules.CATEGORIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(44,44 if compact else 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = ArsenalRules.category_name(id)
		button.pressed.connect(func():
			talent_weapon = id
			refresh(progress)
		)
		weapons.add_child(button)
		category_buttons[id] = button
		var icon := PixelItemIcon.new(id)
		icon.framed = false
		icon.position = Vector2(7,7)
		button.add_child(icon)
		var number := DiaryTheme.label("%d · +%d" % [progress.talents.level(id),progress.talents.mastery_points(id)],10)
		number.position = Vector2(3,37)
		number.size = Vector2(44,14)
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.add_theme_color_override("font_color",Color("#fff0cf") if id == talent_weapon else DiaryTheme.INK)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if compact:
			number.free()
		else:
			button.add_child(number)
		DiaryTheme.select(button,id == talent_weapon)

func _skills_page() -> void:
	_category_selector()
	var category := talent_weapon
	var catalog: Dictionary = AbilityRules.CATEGORIES[category]
	var prof := progress.talents.level(category)
	var build: Dictionary = progress.abilities.loadouts[category]
	_heading("%s · PROFICIÊNCIA %d / %d" % [TalentRules.CLASSES[category],prof,TalentRules.MAX_PROFICIENCY])
	if not allow_respec: _label("Somente consulta · alterações no acampamento.")
	_label("As três Skills são técnicas normais. A Ultimate tem espaço próprio e aparece no HUD somente com carga completa.")
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation",4)
	content.add_child(slots)
	for index in range(3):
		var id: String = catalog.skill1.id if index == 0 else build.skills[index-1]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0,100 if size.x < 340 else 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Skill 1 fixa" if index == 0 else "Selecione uma técnica para este espaço"
		button.pressed.connect(func():
			if index == 0: return
			skill_section = 0
			skill_target_slot = index-1
			if not id.is_empty(): skill_choice = id
			refresh(progress)
			_focus_skill_catalog.call_deferred())
		DiaryTheme.select(button,index-1 == skill_target_slot)
		slots.add_child(button)
		skill_slots.append(button)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 5
		box.offset_right = -5
		box.offset_top = 5
		box.offset_bottom = -5
		box.add_theme_constant_override("separation",2)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(box)
		var label := DiaryTheme.label("Skill %d%s" % [index+1," · fixa" if index == 0 else ""],12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(label)
		var icon := PixelItemIcon.new(_ability_icon(id,category))
		icon.custom_minimum_size = Vector2(30,30)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.visible = not id.is_empty()
		box.add_child(icon)
		var name_label := DiaryTheme.label(catalog.skill1.name if index == 0 else _skill_name(category,id) if not id.is_empty() else "Vazia",12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_label)
		if index-1 == skill_target_slot:
			label.add_theme_color_override("font_color",Color("#fff7dc"))
			name_label.add_theme_color_override("font_color",Color("#fff7dc"))
	var sections := HBoxContainer.new()
	content.add_child(sections)
	for index in range(3):
		var button := Button.new()
		button.text = ["Técnicas","Passivas","Estilo"][index]
		button.add_theme_font_size_override("font_size",14)
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		DiaryTheme.select(button,skill_section == index)
		button.pressed.connect(func():
			skill_section = index
			skill_choice = ""
			skill_target_slot = -1
			refresh(progress)
			scroll.scroll_vertical = 0)
		sections.add_child(button)
		skill_section_buttons.append(button)
	var entries: Array = catalog.normal+[catalog.ultimate] if skill_section == 0 else catalog.passives if skill_section == 1 else []
	if skill_section == 2:
		for id: String in catalog.specializations:
			entries.append({"id":id,"name":AbilityRules.SPECIALIZATIONS[id].name,"prof":18})
	if entries.filter(func(rule: Dictionary): return rule.id == skill_choice).is_empty(): skill_choice = entries[0].id
	for rule: Dictionary in entries:
		if rule.id == skill_choice:
			_skill_details(category,rule,prof,build)
	var browse := Button.new()
	browse.text = "Ver catálogo de "+["técnicas","passivas","estilos"][skill_section]
	browse.custom_minimum_size.y = 44
	browse.pressed.connect(func(): _focus_skill_catalog.call_deferred())
	content.add_child(browse)
	_heading("CATÁLOGO")
	skill_catalog = VBoxContainer.new()
	skill_catalog.add_theme_constant_override("separation",4)
	content.add_child(skill_catalog)
	for rule: Dictionary in entries:
		var button := Button.new()
		var is_ultimate: bool = skill_section == 0 and str(rule.id) == str(catalog.ultimate.id)
		var equipped: bool = build.ultimate == rule.id if is_ultimate else build.skills.has(rule.id) if skill_section == 0 else build.passives.has(rule.id) if skill_section == 1 else build.specialization == rule.id
		var state := "Bloqueada · prof. %d" % rule.prof if prof < int(rule.prof) else "Equipada" if equipped else "Disponível · prof. %d" % rule.prof
		button.text = "%s\n%s" % [rule.name,state]
		for style_name: String in ["normal","hover","pressed","disabled"]:
			var style := DiaryTheme.piece("wood" if style_name == "pressed" else "green" if skill_choice == rule.id and style_name in ["normal","hover"] else "paper",6)
			style.content_margin_left = 42
			button.add_theme_stylebox_override(style_name,style)
		button.add_theme_color_override("font_color",Color("#fff0ce") if skill_choice == rule.id else DiaryTheme.INK)
		button.add_theme_color_override("font_hover_color",Color("#fff0ce") if skill_choice == rule.id else DiaryTheme.INK)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var icon := PixelItemIcon.new(_ability_icon(rule.id,category))
		icon.custom_minimum_size = Vector2(26,26)
		icon.size = Vector2(26,26)
		icon.position = Vector2(8,9)
		button.add_child(icon)
		button.add_theme_font_size_override("font_size",13)
		button.custom_minimum_size.y = 44
		button.pressed.connect(func():
			skill_choice = rule.id
			refresh(progress)
			_focus_skill_detail.call_deferred())
		skill_catalog.add_child(button)
		skill_catalog_buttons[rule.id] = button


func _focus_skill_catalog() -> void:
	await get_tree().process_frame
	if skill_catalog_buttons.has(skill_choice) and is_instance_valid(skill_catalog_buttons[skill_choice]):
		scroll.ensure_control_visible(skill_catalog_buttons[skill_choice])

func _focus_skill_detail() -> void:
	await get_tree().process_frame
	if is_instance_valid(skill_detail):
		var card: Control = skill_detail.get_parent()
		scroll.scroll_vertical = roundi(card.position.y)

func _skill_details(category: String, rule: Dictionary, prof: int, build: Dictionary) -> void:
	skill_detail = _card()
	var ultimate: bool = rule.id == AbilityRules.CATEGORIES[category].ultimate.id
	var grade: int = progress.abilities.grades[category].get(rule.id,1)
	_label(rule.name,skill_detail,true)
	if skill_section != 0: _label("Proficiência %d · %s" % [rule.prof,"disponível" if prof >= int(rule.prof) else "bloqueada"],skill_detail)
	if skill_section == 0:
		_label("Ultimate · carga %d / 100. Aparece no HUD quando estiver pronta." % progress.abilities.charge[category] if ultimate else "Prof. %d · Grau %d/4 · Recarga %.0fs" % [rule.prof,grade,rule.cooldown],skill_detail)
		if not ultimate:
			var effect := AbilityRules.effect(rule.id,grade)
			_label("Defesa temporária · duração %.1fs" % float(effect.get("duration",0)) if rule.type == "defense" else "%s · %s× · alcance %.0f px" % ["Mágico" if rule.type == "magical" else "Físico",String.num(rule.power,2).replace(".",","),float(effect.get("reach",0))],skill_detail)
		if ultimate:
			var ultimate_button := Button.new()
			ultimate_button.text = "Ultimate equipada" if build.ultimate == rule.id else "Equipar Ultimate"
			ultimate_button.custom_minimum_size.y = 44
			ultimate_button.disabled = not allow_respec or prof < int(rule.prof) or build.ultimate == rule.id
			ultimate_button.pressed.connect(func(): action_requested.emit("equip_ultimate",category+":"+rule.id,0))
			DiaryTheme.primary(ultimate_button)
			skill_detail.add_child(ultimate_button)
			ability_buttons[rule.id+":ultimate"] = ultimate_button
		else:
			var preferred := skill_target_slot if skill_target_slot >= 0 else 1 if not str(build.skills[0]).is_empty() and str(build.skills[1]).is_empty() else 0
			for slot: int in [preferred,1-preferred]:
				var button := Button.new()
				button.text = ("Equipada na " if build.skills[slot] == rule.id else "Equipar na ")+"Skill %d" % (slot+2)
				button.custom_minimum_size.y = 44
				button.disabled = not allow_respec or prof < int(rule.prof) or build.skills[slot] == rule.id
				button.pressed.connect(func(): action_requested.emit("equip_skill",category+":"+rule.id,slot))
				if slot == preferred: DiaryTheme.primary(button)
				skill_detail.add_child(button)
				ability_buttons[rule.id+":"+str(slot)] = button
	elif skill_section == 1:
		_label(AbilityRules.DESCRIPTIONS[rule.id],skill_detail)
		for slot in range(2):
			var button := Button.new()
			button.text = ("Equipada na " if build.passives[slot] == rule.id else "Equipar na ")+"Passiva %d" % (slot+1)
			button.custom_minimum_size.y = 44
			button.disabled = not allow_respec or prof < int(rule.prof) or build.passives[slot] == rule.id
			button.pressed.connect(func(): action_requested.emit("equip_passive",category+":"+rule.id,slot))
			skill_detail.add_child(button)
			passive_buttons[rule.id+":"+str(slot)] = button
		_label("Equipadas: %s / %s" % [_passive_name(category,build.passives[0]),_passive_name(category,build.passives[1])],skill_detail)
	else:
		_label(AbilityRules.SPECIALIZATIONS[rule.id].description,skill_detail)
		var button := Button.new()
		button.text = "Estilo ativo" if build.specialization == rule.id else "Escolher estilo · grátis"
		button.custom_minimum_size.y = 44
		button.disabled = not allow_respec or prof < 18 or build.specialization == rule.id
		button.pressed.connect(func(): action_requested.emit("specialization",category+":"+rule.id,0))
		skill_detail.add_child(button)
		specialization_buttons[rule.id] = button
		var catalog: Dictionary = AbilityRules.CATEGORIES[category]
		_label("Maestria: "+catalog.mastery,skill_detail,true)
		_label(("Automática · " if prof >= 30 else "Proficiência 30 · ")+AbilityRules.MASTERY_HELP[category],skill_detail)
	var options := VBoxContainer.new()
	options.visible = false
	var more := Button.new()
	more.name = "SkillOptions"
	more.text = "Melhorar / mais opções"
	more.custom_minimum_size.y = 44
	more.add_theme_font_size_override("font_size",14)
	more.pressed.connect(func(): options.visible = not options.visible)
	skill_detail.add_child(more)
	skill_detail.add_child(options)
	if skill_section == 0 and not ultimate:
		var improve := Button.new()
		improve.text = "Melhorar · 1 ponto de talento" if grade < 4 else "Grau máximo"
		improve.add_theme_font_size_override("font_size",14)
		improve.custom_minimum_size.y = 44
		improve.disabled = not allow_respec or prof < int(rule.prof) or grade >= 4 or progress.skill_points() < 1
		improve.pressed.connect(func(): action_requested.emit("skill",category+":"+rule.id,grade))
		options.add_child(improve)
		ability_buttons[rule.id+":grade"] = improve
	_label("Pontos de talento disponíveis: %d" % progress.skill_points(),options)
	if skill_section < 2 and not (skill_section == 0 and ultimate):
		for slot in range(2):
			var clear := Button.new()
			clear.text = "Limpar Skill %d" % (slot+2) if skill_section == 0 else "Limpar Passiva %d" % (slot+1)
			clear.custom_minimum_size.y = 44
			clear.disabled = not allow_respec
			clear.pressed.connect(func(): action_requested.emit("equip_skill" if skill_section == 0 else "equip_passive",category+":",slot))
			options.add_child(clear)
	if skill_section == 0 and ultimate:
			var clear_ultimate := Button.new()
			clear_ultimate.text = "Remover Ultimate equipada"
			clear_ultimate.custom_minimum_size.y = 44
			clear_ultimate.disabled = not allow_respec or build.ultimate.is_empty()
			clear_ultimate.pressed.connect(func(): action_requested.emit("equip_ultimate",category+":",0))
			options.add_child(clear_ultimate)
	var refund := Button.new()
	refund.text = "Redistribuir talentos e graus\nGrátis no acampamento"
	refund.custom_minimum_size.y = 52
	refund.disabled = not allow_respec
	refund.pressed.connect(func(): action_requested.emit("reset_tree",category,0))
	options.add_child(refund)

func _skill_name(category: String, id: String) -> String:
	return AbilityRules.active_skill(category,id).get("name","Vazia · escolha uma técnica")

func _passive_name(category: String, id: String) -> String:
	return AbilityRules.passive(category,id).get("name","Vazia")


func _ability_icon(id: String, category: String) -> String:
	if "guarda" in id or "postura" in id or "defesa" in id: return "Armadura"
	if "ancestral" in id: return "maestria"
	return category

func _training_button(caption: String, action: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.pressed.connect(func(): action_requested.emit(action,"",0))
	content.add_child(button)
