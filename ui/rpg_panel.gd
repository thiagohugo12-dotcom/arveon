class_name RPGPanel
extends PanelContainer

signal action_requested(action: String, id: String, expected: int)
signal closed
var content: VBoxContainer
var scroll: ScrollContainer
var close_button: Button
var progress: GameProgress
var tab := 0

func _ready() -> void:
	visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#172920")
	style.set_border_width_all(4)
	style.border_color = Color("#bd9b5d")
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	add_child(column)
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	for i in range(2):
		var button := Button.new()
		button.text = ["Personagem", "Habilidades"][i]
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func():
			tab = i
			refresh(progress)
		)
		tabs.add_child(button)
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
	column.add_child(close_button)

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
	else:
		_heading("HABILIDADES  ·  %d PONTOS" % progress.skill_points())
		var descriptions := ["Ao redor: raio 90 · 5s. Grau aumenta dano.", "Avanço ofensivo · 8s. Grau aumenta dano.", "Dano e resistência por 6–8s · 35s. Grau aumenta o buff."]
		for i in range(3):
			var name: String = RPGRules.SKILLS[i]
			var card := _card()
			_label("%s  ·  GRAU %d / 3" % [name.to_upper(), progress.skills[name]], card, true)
			_label(descriptions[i], card)
			var button := Button.new()
			button.text = "Melhorar  ·  1 ponto"
			button.custom_minimum_size.y = 44
			button.disabled = progress.skill_points() < 1 or int(progress.skills[name]) >= 3
			button.pressed.connect(func(): action_requested.emit("skill", name, 0))
			card.add_child(button)
		_label("PC: 1 Corte  ·  2 Investida  ·  3 Fúria\nDireção: joystick/WASD ou última direção.\nIndisponível em menus e na área segura.")

func _heading(text: String) -> void:
	_label(text, content, true)

func _card() -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#244135")
	style.border_color = Color("#647952")
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
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
		label.add_theme_color_override("font_color", Color("#edcb84"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(destination if destination != null else content).add_child(label)
