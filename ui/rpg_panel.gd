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
	style.bg_color = Color("#1b2f27")
	style.set_border_width_all(3)
	style.border_color = Color("#d0b878")
	style.set_content_margin_all(10)
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
		_label("Aventureiro · Nível %d" % lvl)
		_label("XP %d / %d · total %d" % [progress.xp - RPGRules.xp_floor(lvl), RPGRules.cost_to_level(lvl), progress.xp] if lvl < RPGRules.MAX_LEVEL else "Nível máximo · XP total %d" % progress.xp)
		_label("Pontos de atributo: %d · custo: 1" % progress.attribute_points())
		for name: String in RPGRules.ATTRIBUTES:
			var row := HBoxContainer.new()
			content.add_child(row)
			var label := Label.new()
			label.text = "%s: %d / 198" % [name, progress.attributes[name]]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var button := Button.new()
			button.text = "+1"
			button.custom_minimum_size = Vector2(52, 44)
			button.disabled = progress.attribute_points() < 1 or int(progress.attributes[name]) >= 198
			button.pressed.connect(func(): action_requested.emit("attribute", name, 0))
			row.add_child(button)
		var values := progress.combat_stats()
		_label("Dano %d · HP %d · Vel %d\nEspírito %d · Defesa %d" % [values.damage, values.hp, values.speed, values.spirit, values.armor])
		_label("Força: +2 dano · Vitalidade: +8 HP\nAgilidade: movimento e cooldown (até −20%)\nEspírito: +1 dano, +2 HP e habilidades")
	else:
		_label("Pontos de habilidade: %d · custo: 1" % progress.skill_points())
		var descriptions := ["Ao redor: raio 90 · 5s. Grau aumenta dano.", "Avanço ofensivo · 8s. Grau aumenta dano.", "Dano e resistência por 6–8s · 35s. Grau aumenta o buff."]
		for i in range(3):
			var name: String = RPGRules.SKILLS[i]
			_label("%s · grau %d / 3" % [name, progress.skills[name]])
			_label(descriptions[i])
			var button := Button.new()
			button.text = "Melhorar · 1 ponto"
			button.custom_minimum_size.y = 44
			button.disabled = progress.skill_points() < 1 or int(progress.skills[name]) >= 3
			button.pressed.connect(func(): action_requested.emit("skill", name, 0))
			content.add_child(button)
		_label("Teclado: 1 Corte · 2 Investida · 3 Fúria.\nDireção: joystick/WASD ou última direção.\nSem uso em menus ou no perímetro seguro.")

func _label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)
