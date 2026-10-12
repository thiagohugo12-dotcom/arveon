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

func _ready() -> void:
	visible = false
	add_theme_stylebox_override("panel",DiaryTheme.box(DiaryTheme.PAPER,DiaryTheme.WOOD,12,3))
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
			_label("%s  ·  GRAU %d / 3" % [name.to_upper(), progress.skills[name]], card, true)
			_label(descriptions[i], card)
			var button := Button.new()
			button.text = "Melhorar  ·  1 ponto"
			button.custom_minimum_size.y = 44
			button.disabled = progress.skill_points() < 1 or int(progress.skills[name]) >= 3
			button.pressed.connect(func(): action_requested.emit("skill", name, 0))
			card.add_child(button)
		_label("PC: 1 Corte  ·  2 Investida  ·  3 Fúria\nDireção: joystick/WASD ou última direção.\nIndisponível em menus e na área segura.")
	else:
		_heading("DOMÍNIO DAS ARMAS")
		_label("Evolução pelo uso de cada arma · Em desenvolvimento")
		for id: String in ArsenalRules.CATEGORIES:
			var card := _card()
			var row := HBoxContainer.new()
			card.add_child(row)
			row.add_child(PixelItemIcon.new(ArsenalRules.metadata(id).icon))
			row.add_child(DiaryTheme.label(ArsenalRules.category_name(id),15))
			_label("Técnicas · Especialização · Maestria",card)
		_heading("MARCOS PLANEJADOS")
		_label("Nv. 3 / 8 / 15 / 25 · Habilidades\nNv. 5 / 12 · Passivas\nNv. 10 / 20 · Marcos de Ultimate\nNv. 18 · Especialização\nNv. 30 · Maestria")
		_label("Efeitos e funcionamento da Ultimate ainda serão definidos para os três espaços de habilidade.")
	for i in range(tabs.get_child_count()): DiaryTheme.select(tabs.get_child(i),(tab == 2 and i == 1) or (tab == 1 and i == 2))

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
