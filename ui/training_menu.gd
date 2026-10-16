class_name TrainingMenu
extends Control

signal loadout_requested(category: String, skill2: String, skill3: String, passive1: String, passive2: String, specialization: String)
signal refill_requested
signal exit_requested
signal menu_toggled(opened: bool)

var source: GameProgress
var launcher: Button
var dimmer: ColorRect
var panel: PanelContainer
var scroll: ScrollContainer
var warning: Label
var category_choice: OptionButton
var selectors: Array[OptionButton] = []
var active := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	dimmer = ColorRect.new()
	dimmer.color = Color(0.06, 0.08, 0.06, 0.79)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", DiaryTheme.box(Color("#e6d1a3"), Color("#a27848"), 7, 2))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = "ARENA DE TREINAMENTO"
	heading.add_theme_color_override("font_color", DiaryTheme.GREEN)
	heading.add_theme_font_size_override("font_size", 17)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(44,44)
	close.pressed.connect(func(): show_menu(false))
	header.add_child(close)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", 4)
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(fields)
	var help := Label.new()
	help.text = "Nv 100 · Proficiência 60 em todas as armas · equipamentos +3.
Habilidades, talentos, passivas e Maestrias liberados."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 12)
	fields.add_child(help)
	category_choice = _add_choice(fields, "Arma")
	for category: String in AbilityRules.CATEGORIES:
		category_choice.add_item(ArsenalRules.CATEGORIES[category].name)
		category_choice.set_item_metadata(category_choice.item_count-1,category)
	category_choice.item_selected.connect(func(_index: int): _populate())
	for label: String in ["Habilidade 2","Habilidade 3 / Ultimate","Passiva 1","Passiva 2","Especialização"]:
		selectors.append(_add_choice(fields,label))
	warning = Label.new()
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_font_size_override("font_size", 12)
	warning.text = "Alvos imóveis e sem dano · carga e recargas infinitas.
O treino NÃO altera a campanha nem o save."
	fields.add_child(warning)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	var equip := Button.new()
	equip.text = "Equipar e jogar"
	equip.custom_minimum_size.y = 48
	equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip.pressed.connect(_submit)
	controls.add_child(equip)
	var reset := Button.new()
	reset.text = "Reiniciar"
	reset.custom_minimum_size.y = 48
	reset.pressed.connect(func(): refill_requested.emit())
	controls.add_child(reset)
	var leave := Button.new()
	leave.text = "Sair do treino · voltar ao save"
	leave.custom_minimum_size.y = 48
	leave.pressed.connect(func(): exit_requested.emit())
	column.add_child(leave)
	launcher = Button.new()
	launcher.text = "⚔ TREINO"
	launcher.custom_minimum_size = Vector2(100, 44)
	launcher.pressed.connect(func(): show_menu(true))
	add_child(launcher)
	resized.connect(_layout)
	call_deferred("_layout")

func _add_choice(fields: VBoxContainer, name: String) -> OptionButton:
	var caption := Label.new()
	caption.text = name
	caption.add_theme_font_size_override("font_size", 12)
	fields.add_child(caption)
	var choice := OptionButton.new()
	choice.custom_minimum_size.y = 44
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_child(choice)
	return choice

func initialize(value: GameProgress) -> void:
	source = value
	if category_choice == null:
		call_deferred("initialize",value)
		return
	category_choice.select(0)
	_populate()
	show_menu(true)

func _selected(chooser: OptionButton) -> String:
	var index := chooser.selected
	if index < 0 or index >= chooser.item_count: return ""
	return str(chooser.get_item_metadata(index))

func _fill(chooser: OptionButton, entries: Array, current: String) -> void:
	chooser.clear()
	var chosen := 0
	for entry: Dictionary in entries:
		chooser.add_item(str(entry.name))
		chooser.set_item_metadata(chooser.item_count-1,entry.id)
		if entry.id == current: chosen = chooser.item_count-1
	if chooser.item_count > 0: chooser.select(chosen)

func _populate() -> void:
	if source == null: return
	var category := _selected(category_choice)
	if not AbilityRules.CATEGORIES.has(category): return
	var rules: Dictionary = AbilityRules.CATEGORIES[category]
	var loadout: Dictionary = source.abilities.loadouts[category]
	var skills: Array = rules.normal.duplicate(true)
	skills.append(rules.ultimate)
	for i in range(2):
		_fill(selectors[i],skills,loadout.skills[i])
	for i in range(2):
		_fill(selectors[i+2],rules.passives,loadout.passives[i])
	var styles: Array = []
	for id: String in rules.specializations:
		styles.append({"id":id,"name":id.replace("_"," ").capitalize()})
	_fill(selectors[4],styles,loadout.specialization)
	warning.text = "Treino sem gravação · habilidades e Ultimates sem espera.
Selecione duas técnicas e duas passivas diferentes."

func _submit() -> void:
	var category := _selected(category_choice)
	var skill2 := _selected(selectors[0])
	var skill3 := _selected(selectors[1])
	var passive1 := _selected(selectors[2])
	var passive2 := _selected(selectors[3])
	if skill2 == skill3 or passive1 == passive2:
		warning.text = "Escolha duas técnicas diferentes e duas passivas diferentes."
		return
	loadout_requested.emit(category,skill2,skill3,passive1,passive2,_selected(selectors[4]))

func show_menu(opened: bool) -> void:
	active = opened
	dimmer.visible = opened
	panel.visible = opened
	launcher.visible = not opened
	menu_toggled.emit(opened)
	_layout()

func _layout() -> void:
	if not is_instance_valid(panel): return
	var w := maxf(300.0, size.x)
	var h := maxf(260.0, size.y)
	panel.size = Vector2(minf(350.0,w-16.0), minf(580.0,h-16.0))
	panel.position = Vector2((w-panel.size.x)/2.0,(h-panel.size.y)/2.0)
	launcher.position = Vector2((w-launcher.custom_minimum_size.x)/2.0, 5.0)
	launcher.size = launcher.custom_minimum_size
