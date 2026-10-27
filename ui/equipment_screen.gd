class_name EquipmentScreen
extends Control

# Full-screen equipment presentation approved at 360x800. Art layers contain
# no text, stats or equipment. Gameplay state remains in GameProgress.
signal slot_requested(item_id: String)
signal navigation_requested(page: String)
signal loadout_requested(action: String, index: int)

const FRAME := preload("res://assets/art/equipment_screen/ui-frame.png")
const FOREST := preload("res://assets/art/equipment_screen/forest-background.png")
const CHARACTER := preload("res://assets/art/equipment_screen/reference-character.png")
const FONT := preload("res://assets/fonts/CormorantGaramond.ttf")
const ART := "res://assets/art/equipment_screen/icons/"
const SLOT_LAYOUT := [
	["Arma", 14, 131], ["Armadura", 14, 216], ["Luvas", 14, 301], ["Anel", 14, 386],
	["Capacete", 268, 131], ["Acessório", 268, 216], ["Botas", 268, 301], ["Amuleto", 268, 386]
]
const NAV := ["Personagem", "Equipamento", "Mochila", "Habilidades", "Missões", "Mapa"]
const NAV_ICONS := ["person-nav", "equipment-nav", "bag-nav", "ability-nav", "missions-nav", "map-nav"]

var progress: GameProgress
var selected_set := 0
var hp := 1
var hp_max := 1

func _ready() -> void:
	custom_minimum_size = Vector2(360, 713)
	size = Vector2(360, 713)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	hide()

func present(value: GameProgress, current_hp: int, maximum_hp: int, set_index: int) -> void:
	progress = value
	hp = current_hp
	hp_max = maxi(1, maximum_hp)
	selected_set = clampi(set_index, 0, 2)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()
	show()

func _build() -> void:
	var forest := AtlasTexture.new()
	forest.atlas = FOREST
	forest.region = Rect2(0, 260, 941, 1250)
	_image(forest, Rect2(0, 125, 360, 350))
	_color(Rect2(0, 125, 360, 350), Color(0.02, 0.11, 0.08, 0.08))
	_piece(Rect2(0, 0, 941, 160), Rect2(0, 0, 360, 77))
	_piece(Rect2(0, 160, 941, 100), Rect2(0, 77, 360, 49))
	_piece(Rect2(0, 1028, 941, 246), Rect2(0, 469, 360, 142))
	_piece(Rect2(0, 1274, 941, 218), Rect2(0, 611, 360, 102))
	var figure := AtlasTexture.new()
	figure.atlas = CHARACTER
	figure.region = Rect2(329, 115, 587, 1049)
	_image(figure, Rect2(145, 241, 70, 125))
	var head := AtlasTexture.new()
	head.atlas = CHARACTER
	head.region = Rect2(329, 115, 587, 608)
	_image(head, Rect2(12, 8, 38, 59))
	_status()
	_label("Equipamento", Rect2(45, 82, 270, 37), 29, Color("#fff1d4"), HORIZONTAL_ALIGNMENT_CENTER, true)
	for entry in SLOT_LAYOUT:
		_slot(str(entry[0]), int(entry[1]), int(entry[2]))
	_attributes()
	_loadouts()
	_button(Rect2(7, 5, 47, 64), "Voltar ao jogo", func(): navigation_requested.emit("close"))

func _piece(region: Rect2, place: Rect2) -> void:
	var piece := AtlasTexture.new()
	piece.atlas = FRAME
	piece.region = region
	_image(piece, place)

func _image(texture: Texture2D, place: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.position = place.position
	node.size = place.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _color(place: Rect2, tint: Color) -> void:
	var node := ColorRect.new()
	node.position = place.position
	node.size = place.size
	node.color = tint
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)

func _label(value: String, place: Rect2, font_size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, bold := false) -> Label:
	var node := Label.new()
	node.text = value
	node.position = place.position
	node.size = place.size
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.clip_text = true
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.add_theme_font_override("font", DiaryTheme.heading_font() if bold else FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color("#24170d"))
	node.add_theme_constant_override("outline_size", 1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _button(place: Rect2, hint: String, action: Callable) -> Button:
	var button := Button.new()
	button.position = place.position
	button.size = place.size
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = hint
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(action)
	add_child(button)
	return button

func _icon(id: String, place: Rect2) -> void:
	var texture := load(ART + id + ".png") as Texture2D
	if texture != null:
		_image(texture, place)

func _status() -> void:
	_label("Nv. %d" % progress.level(), Rect2(59, 9, 184, 26), 22, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_LEFT, true)
	_color(Rect2(62, 38, 181, 11), Color("#3a1511"))
	_color(Rect2(64, 40, 177.0 * clampf(float(hp) / hp_max, 0.0, 1.0), 7), Color("#d43c32"))
	_label("%d/%d" % [hp, hp_max], Rect2(61, 50, 110, 18), 13, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_LEFT, true)
	_icon("coin-source", Rect2(267, 12, 25, 25))
	_icon("gem-source", Rect2(267, 42, 25, 25))
	_label(_grouped(progress.gold), Rect2(291, 12, 55, 26), 18, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_RIGHT, true)
	_label(str(progress.gems), Rect2(291, 42, 55, 26), 18, Color("#88d8ff"), HORIZONTAL_ALIGNMENT_RIGHT, true)

func _slot(title: String, x: int, y: int) -> void:
	var id := str(progress.equipped.get(title, ""))
	var rarity := ""
	var upgrade := 0
	var visual_id := id
	if not id.is_empty():
		if title == "Arma" and progress.weapon_instances.has(progress.equipped_weapon_uid):
			var weapon := progress.weapon(progress.equipped_weapon_uid)
			visual_id = str(weapon.category)
			rarity = str(weapon.rarity)
			upgrade = int(weapon.level)
		else:
			rarity = progress.equipment_rarity(id)
			upgrade = int(progress.equipment.get(id, 0))
	_piece(Rect2(23, 260, 206, 198), Rect2(x - 2, y - 2, 89, 86))
	var border := Panel.new()
	border.name = "RarityFrame_" + title
	border.position = Vector2(x + 8, y + 5)
	border.size = Vector2(68, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = MenuKit.rarity_color(rarity) if not id.is_empty() else Color("#77776b")
	style.set_border_width_all(3)
	style.set_corner_radius_all(1)
	border.add_theme_stylebox_override("panel", style)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	var sprite_path := EquipmentPage.sprite_path_for_item(visual_id)
	if not sprite_path.is_empty():
		var sprite := load(sprite_path) as Texture2D
		var icon := _image(sprite, Rect2(x + 21, y + 12, 42, 45))
		icon.name = "OfficialItemSprite_" + title
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	elif not id.is_empty():
		_label("Arte\npendente", Rect2(x + 16, y + 14, 52, 42), 9, Color("#dfd5bc"), HORIZONTAL_ALIGNMENT_CENTER)
	if upgrade > 0:
		_label("+%d" % upgrade, Rect2(x + 43, y + 41, 31, 20), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, true)
	var caption_size := 17 if title.length() <= 6 else 15 if title.length() <= 9 else 13
	_label(title, Rect2(x + 2, y + 59, 80, 18), caption_size, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_CENTER, true)
	var item_name := str(RPGRules.EQUIPMENT[id].name) if RPGRules.EQUIPMENT.has(id) else "Vazio"
	var button := _button(Rect2(x + 6, y + 4, 72, 76), title + ": " + item_name, func(): slot_requested.emit(id))
	button.name = "EquipmentSlot_" + title

func _attributes() -> void:
	var stats := progress.combat_stats()
	_label("Atributos", Rect2(80, 470, 200, 28), 23, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_CENTER, true)
	var rows := [
		["heart", "Vida", str(stats.hp), "boot", "Velocidade", "%.0f" % stats.speed],
		["swords", "Ataque", str(stats.damage), "target", "Crítico", "%.1f%%" % (stats.critical_chance * 100.0)],
		["shield", "Defesa", str(stats.armor), "diamond", "Dano Crítico", "%.0f%%" % (stats.critical_multiplier * 100.0)],
		["shield", "Resistência", "%.1f%%" % (stats.resistance * 100.0), "bolt", "Intervalo", "%.1f%%" % ((1.0 - stats.basic_interval_factor) * 100.0)]
	]
	_color(Rect2(180, 508, 1, 82), Color("#d1ad75"))
	for index in range(4):
		var entry: Array = rows[index]
		var y := 511 + index * 21
		_icon(str(entry[0]), Rect2(23, y, 17, 17))
		_icon(str(entry[3]), Rect2(194, y, 17, 17))
		_label(str(entry[1]), Rect2(42, y - 1, 94, 19), 17, Color("#2b1c11"), HORIZONTAL_ALIGNMENT_LEFT, true)
		_label(str(entry[2]), Rect2(135, y - 1, 31, 19), 17, Color("#2b1c11"), HORIZONTAL_ALIGNMENT_RIGHT, true)
		_label(str(entry[4]), Rect2(213, y - 1, 83, 19), 16, Color("#2b1c11"), HORIZONTAL_ALIGNMENT_LEFT, true)
		_label(str(entry[5]), Rect2(298, y - 1, 40, 19), 16, Color("#2b1c11"), HORIZONTAL_ALIGNMENT_RIGHT, true)

func _loadouts() -> void:
	_label("Conjuntos de Equipamento", Rect2(53, 613, 254, 25), 18, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_CENTER, true)
	for index in range(3):
		var x := 24 + index * 50
		if index == selected_set:
			_color(Rect2(x + 5, 652, 39, 41), Color("#176247"))
		_label(str(index + 1), Rect2(x, 651, 50, 43), 24, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_CENTER, true)
		var action := "apply" if progress.has_loadout(index) else "select"
		var choose := _button(Rect2(x, 649, 48, 48), "Aplicar conjunto %d" % (index + 1) if action == "apply" else "Selecionar conjunto %d" % (index + 1), func(): loadout_requested.emit(action, index))
		choose.name = "Loadout_%d" % (index + 1)
	_label("Salvar conjunto", Rect2(197, 652, 137, 42), 17, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_CENTER, true)
	var save := _button(Rect2(191, 648, 149, 49), "Salvar no conjunto %d" % (selected_set + 1), func(): loadout_requested.emit("save", selected_set))
	save.name = "SaveLoadout"

func _navigation() -> void:
	for index in range(NAV.size()):
		var x := index * 60
		_icon(NAV_ICONS[index], Rect2(x + 14, 723, 32, 38))
		_label(NAV[index], Rect2(x + 4, 765, 52, 20), 9, Color("#fff0d1"), HORIZONTAL_ALIGNMENT_CENTER, true)
		var page: String = ["personagem", "equipamento", "mochila", "habilidades", "missoes", "mapa"][index]
		_button(Rect2(x, 714, 60, 84), NAV[index], func(): navigation_requested.emit(page))

func _grouped(number: int) -> String:
	var raw := str(number)
	var result := ""
	for index in range(raw.length()):
		if index > 0 and (raw.length() - index) % 3 == 0:
			result += "."
		result += raw[index]
	return result
