class_name EquipmentPage
extends RefCounted

const LEFT := ["Arma", "Armadura", "Luvas", "Anel"]
const RIGHT := ["Capacete", "Acessório", "Botas", "Amuleto"]
const SLOT_FRAME := preload("res://assets/art/equipment_reference/ui/equipment_slot_frame.png")
const ITEM_SPRITES := {
	# Starter equipment with an explicitly approved match in the source sheet.
	"espada": "equipment/weapons/sword_01.png",
	"machado": "equipment/weapons/axe_01.png",
	"lanca": "equipment/weapons/spear_01.png",
	"arco": "equipment/weapons/bow_01.png",
	"cajado": "equipment/weapons/staff_blue.png",
	"couro": "equipment/chest_armor/chest_01.png",
	"pedra": "equipment/necklaces/necklace_01.png",
	# Kit 1 is shared by floors 1 and 2. Remaining pieces use the approved Mata/Vale mapping.
	"elmo_mata": "equipment/helmets/helmet_01.png",
	"elmo_vale": "equipment/helmets/helmet_01.png",
	"colete_mata": "equipment/chest_armor/chest_01.png",
	"colete_vale": "equipment/chest_armor/chest_01.png",
	"luvas_mata": "equipment/gloves/gloves_05.png",
	"luvas_vale": "equipment/gloves/gloves_06.png",
	"botas_mata": "equipment/boots/boots_03.png",
	"botas_vale": "equipment/boots/boots_02.png",
	"anel_mata": "equipment/rings/ring_03.png",
	"anel_vale": "equipment/rings/ring_04.png",
	"colar_mata": "equipment/necklaces/necklace_01.png",
	"colar_vale": "equipment/necklaces/necklace_03.png",
	"amuleto_mata": "equipment/necklaces/necklace_05.png",
	"amuleto_vale": "equipment/necklaces/necklace_04.png"
}
const SLOT_TITLES := {}

static func sprite_path_for_item(item_id: String) -> String:
	var relative: String = ITEM_SPRITES.get(item_id, "")
	return "res://assets/art/equipment_reference/%s" % relative if not relative.is_empty() else ""

static func build(progress: GameProgress, hp: int, hp_max: int, on_slot: Callable, on_nav: Callable,
		on_loadout: Callable = Callable(), selected_set: int = 0) -> PanelContainer:
	UiScale.update(Vector2(DisplayServer.window_get_size()), false)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_stage(progress, on_slot))
	body.add_child(_attributes(progress))
	body.add_child(_sets(progress, on_loadout, selected_set))
	var page := MenuKit.page("Equipamento", "equipamento", on_nav, body, progress, hp, hp_max)
	_decorate_page(page)
	return page

static func _decorate_page(page: PanelContainer) -> void:
	page.add_theme_stylebox_override("panel", DiaryTheme.piece("frame", UiScale.px(14)))
	if page.get_child_count() == 0: return
	var column := page.get_child(0) as VBoxContainer
	if column == null or column.get_child_count() < 4: return
	var heading := column.get_child(1) as Label
	if heading != null:
		heading.add_theme_stylebox_override("normal", DiaryTheme.piece("green", UiScale.px(8)))
		heading.add_theme_font_override("font", DiaryTheme.heading_font())
	var nav := column.get_child(3)
	for button: Node in nav.get_children():
		if button is Button:
			_style_textured_button(button, button.name == "Nav_equipamento", UiScale.font(9))

static func _style_textured_button(button: Button, active: bool, font_size: int) -> void:
	var piece := DiaryTheme.piece("green" if active else "wood", UiScale.px(4))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, piece)
	button.add_theme_color_override("font_color", Color("#fff0ce"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("#fff0ce"))
	button.add_theme_font_override("font", DiaryTheme.heading_font())
	button.add_theme_font_size_override("font_size", font_size)

static func _stage(progress: GameProgress, on_slot: Callable) -> Control:
	var stage := PanelContainer.new()
	stage.name = "EquipmentStage"
	stage.custom_minimum_size.y = UiScale.px(328)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	stage.add_theme_stylebox_override("panel", DefeatArt.plate("section", 4))
	var backdrop := ForestRuinsBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(backdrop)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	stage.add_child(row)
	row.add_child(_slot_column(LEFT, progress, on_slot))
	var center := Control.new()
	center.name = "ExplorerStage"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(center)
	var portrait := EquipmentExplorerPortrait.new()
	portrait.name = "CurrentExplorer"
	portrait.custom_minimum_size = Vector2(UiScale.px(118), UiScale.px(170))
	portrait.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	portrait.position = Vector2(-portrait.custom_minimum_size.x * 0.5, -portrait.custom_minimum_size.y * 0.5)
	center.add_child(portrait)
	row.add_child(_slot_column(RIGHT, progress, on_slot))
	return stage

static func _slot_column(slots: Array, progress: GameProgress, on_slot: Callable) -> Control:
	var column := VBoxContainer.new()
	column.name = "EquipmentSlots" + str(slots[0])
	column.custom_minimum_size.x = UiScale.px(72)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	for slot: String in slots:
		column.add_child(_slot(slot, progress, on_slot))
	return column

static func _slot(slot: String, progress: GameProgress, on_slot: Callable) -> Control:
	var cell := VBoxContainer.new()
	cell.name = "SlotCell_" + slot
	cell.add_theme_constant_override("separation", 0)
	var id := str(progress.equipped.get(slot, ""))
	var visual_id := id
	var rarity := ""
	var badge := ""
	var title: String = str(SLOT_TITLES.get(slot, slot))
	if not id.is_empty():
		rarity = progress.equipment_rarity(id) if progress.equipment.has(id) else str(ArsenalRules.metadata(id).get("rarity", "comum"))
		var level := int(progress.equipment.get(id, 0))
		if slot == "Arma" and progress.weapon_instances.has(progress.equipped_weapon_uid):
			var weapon := progress.weapon(progress.equipped_weapon_uid)
			visual_id = str(weapon.category)
			rarity = str(weapon.rarity)
			level = int(weapon.level)
		if level > 0:
			badge = "+%d" % level
	var sprite_path := sprite_path_for_item(visual_id)
	var tile := _equipment_tile(sprite_path, rarity, badge, id.is_empty())
	tile.name = "EquipmentTile_" + slot
	var button := Button.new()
	button.name = "EquipmentSlot_" + slot
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.tooltip_text = title + (": " + str(RPGRules.EQUIPMENT[id].name) if not id.is_empty() else ": vazio")
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.set_meta("skin_done", true)
	button.pressed.connect(on_slot.bind(id if not id.is_empty() else slot))
	tile.add_child(button)
	cell.add_child(tile)
	var caption := DefeatView.text(str(title), 12, DefeatView.CREAM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	cell.add_child(caption)
	return cell

static func _equipment_tile(sprite_path: String, rarity: String, badge: String, empty: bool) -> Control:
	var tile := Control.new()
	tile.custom_minimum_size = Vector2(UiScale.px(56), UiScale.px(64))
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frame := TextureRect.new()
	frame.name = "RarityFrame"
	frame.texture = SLOT_FRAME
	frame.modulate = MenuKit.rarity_color(rarity) if not empty else Color("#77776b")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tile.add_child(frame)
	# The source frame includes a sample sword in its center. Cover only that inner
	# field so the original rarity-tinted border remains and each official sprite
	# is rendered untouched above it.
	var inner := ColorRect.new()
	inner.name = "SlotInterior"
	inner.color = Color("#192820")
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = UiScale.px(5)
	inner.offset_top = UiScale.px(5)
	inner.offset_right = -UiScale.px(5)
	inner.offset_bottom = -UiScale.px(5)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(inner)
	if not sprite_path.is_empty():
		var icon := TextureRect.new()
		icon.name = "OfficialItemSprite"
		icon.texture = load(sprite_path) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		icon.size = Vector2(UiScale.px(43), UiScale.px(50))
		icon.position = -icon.size * 0.5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
	else:
		var note := DefeatView.text("Arte\npendente" if not empty else "Vazio", 9, Color("#d6c7a4"))
		note.name = "SpriteStatus"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(note)
	if not badge.is_empty():
		var level_badge := DefeatView.text(badge, 11, Color.WHITE)
		level_badge.name = "UpgradeLevel"
		level_badge.add_theme_color_override("font_color", Color.WHITE)
		level_badge.add_theme_color_override("font_outline_color", Color("#1b0f08"))
		level_badge.add_theme_constant_override("outline_size", 3)
		level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		level_badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		level_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		level_badge.offset_right = -UiScale.px(5)
		level_badge.offset_bottom = -UiScale.px(4)
		level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(level_badge)
	return tile

static func _attributes(progress: GameProgress) -> Control:
	var card := DefeatView.card("paper", 8)
	card.name = "EquipmentAttributes"
	card.add_theme_stylebox_override("panel", DiaryTheme.piece("paper", UiScale.px(9)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	card.add_child(column)
	var title := DefeatView.text("Atributos", 19, DefeatView.CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_stylebox_override("normal", DiaryTheme.piece("wood", UiScale.px(5)))
	title.add_theme_font_override("font", DiaryTheme.heading_font())
	column.add_child(title)
	var stats := progress.combat_stats()
	var interval_reduction := maxf(0.0, (1.0 - stats.basic_interval_factor) * 100.0)
	var interval_text := "−%.1f%%" % interval_reduction if interval_reduction > 0.05 else "0.0%"
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 1)
	column.add_child(grid)
	var rows := [
		["heart", "Vida", str(stats.hp)],
		["swords", "Ataque", str(stats.damage)],
		["shield", "Defesa", str(stats.armor)],
		["shield", "Resistência", "%.1f%%" % (stats.resistance * 100.0)],
		["boot", "Velocidade", "%.0f" % stats.speed],
		["target", "Crítico", "%.1f%%" % (stats.critical_chance * 100.0)],
		["diamond", "Dano Crítico", "%.0f%%" % (stats.critical_multiplier * 100.0)],
		["bolt", "Intervalo", interval_text]
	]
	for entry: Array in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(DefeatView.picture(str(entry[0]), 1))
		var name := DefeatView.text(str(entry[1]), 14, DefeatView.INK)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(name)
		var value := DefeatView.text(str(entry[2]), 14, DefeatView.INK)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(value)
		grid.add_child(line)
	return card

static func _sets(progress: GameProgress, on_loadout: Callable, selected_set: int) -> Control:
	var card := DefeatView.card("paper", 8)
	card.name = "EquipmentLoadouts"
	card.add_theme_stylebox_override("panel", DiaryTheme.piece("paper", UiScale.px(9)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var heading := DefeatView.text("Conjuntos de Equipamento", 16, DefeatView.CREAM)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_stylebox_override("normal", DiaryTheme.piece("wood", UiScale.px(5)))
	heading.add_theme_font_override("font", DiaryTheme.heading_font())
	column.add_child(heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	column.add_child(row)
	for index in range(3):
		var button := Button.new()
		button.name = "Loadout_%d" % (index + 1)
		button.text = str(index + 1)
		button.custom_minimum_size = Vector2(UiScale.px(42), UiScale.px(42))
		button.tooltip_text = "Aplicar conjunto %d" % (index + 1) if progress.has_loadout(index) else "Selecionar conjunto %d" % (index + 1)
		_style_textured_button(button, index == selected_set, UiScale.font(17))
		button.icon = null
		button.pressed.connect(_request_loadout.bind(on_loadout, progress, index, selected_set))
		row.add_child(button)
	var save := Button.new()
	save.name = "SaveLoadout"
	save.text = "Salvar conjunto"
	save.custom_minimum_size.y = UiScale.px(42)
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.tooltip_text = "Salvar o equipamento atual no conjunto %d" % (selected_set + 1)
	_style_textured_button(save, true, UiScale.font(13))
	row.add_child(save)
	save.pressed.connect(_request_save.bind(on_loadout, selected_set))
	return card

static func _request_loadout(on_loadout: Callable, progress: GameProgress, index: int, selected_set: int) -> void:
	if on_loadout.is_valid():
		on_loadout.call("apply" if progress.has_loadout(index) else "select", index)

static func _request_save(on_loadout: Callable, selected_set: int) -> void:
	if on_loadout.is_valid():
		on_loadout.call("save", selected_set)

class ForestRuinsBackdrop extends Control:
	const CAMP_ART := preload("res://assets/art/mata_v2/camp.png")
	const ARCH_REGION := Rect2(96, 96, 72, 96)
	const LANTERN_REGION := Rect2(32, 64, 32, 56)
	const NATURE_ART := preload("res://assets/art/mata_v2/nature.png")
	const GREEN_TREE_REGION := Rect2(0, 0, 96, 96)
	const FLOOR_ART := preload("res://assets/art/mata_v2/ancient_ruins_kit.png")
	const STONE_REGION := Rect2(256, 128, 128, 128)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		for band in range(10):
			var t := float(band) / 9.0
			var y := floorf(size.y * t / 10.0)
			draw_rect(Rect2(0, y, size.x, ceilf(size.y / 10.0) + 1), Color("#10261b").lerp(Color("#315c3c"), t))
		var opening := Rect2(size.x * 0.31, size.y * 0.13, size.x * 0.38, size.y * 0.59)
		for band in range(8):
			var t := float(band) / 7.0
			var y := opening.position.y + opening.size.y * t / 8.0
			draw_rect(Rect2(opening.position.x, y, opening.size.x, ceilf(opening.size.y / 8.0) + 1),
				Color("#173326").lerp(Color("#397248"), t))
		var tree_width := UiScale.px(106)
		var tree_height := UiScale.px(146)
		draw_texture_rect_region(NATURE_ART, Rect2(-tree_width * 0.2, UiScale.px(8), tree_width, tree_height), GREEN_TREE_REGION)
		draw_set_transform(Vector2(size.x, 0), 0, Vector2(-1, 1))
		draw_texture_rect_region(NATURE_ART, Rect2(0, UiScale.px(8), tree_width, tree_height), GREEN_TREE_REGION)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var arch_width := minf(size.x * 0.72, UiScale.px(178))
		var arch_height := minf(size.y * 0.88, UiScale.px(284))
		draw_texture_rect_region(CAMP_ART, Rect2((size.x - arch_width) * 0.5, 2, arch_width, arch_height), ARCH_REGION)
		var lamp_size := Vector2(UiScale.px(20), UiScale.px(34))
		draw_texture_rect_region(CAMP_ART, Rect2(size.x * 0.74, size.y * 0.4, lamp_size.x, lamp_size.y), LANTERN_REGION)
		var stone_width := UiScale.px(188)
		var stone_height := UiScale.px(76)
		draw_texture_rect_region(FLOOR_ART, Rect2((size.x - stone_width) * 0.5, size.y - stone_height, stone_width, stone_height), STONE_REGION)
		draw_rect(Rect2(0, size.y - UiScale.px(18), size.x, UiScale.px(18)), Color("#33562b"))
		for i in range(10):
			var x := float(i) * size.x / 9.0
			draw_rect(Rect2(x, size.y - UiScale.px(22 + (i % 3) * 3), UiScale.px(2), UiScale.px(8 + (i % 4) * 2)), Color("#648a3d"))

class EquipmentExplorerPortrait extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		var feet := Vector2(floorf(size.x * 0.5), size.y - UiScale.px(26))
		draw_rect(Rect2(feet + Vector2(-UiScale.px(30), UiScale.px(4)), Vector2(UiScale.px(60), UiScale.px(5))), Color("#d1b681"))
		draw_rect(Rect2(feet + Vector2(-UiScale.px(20), UiScale.px(9)), Vector2(UiScale.px(40), UiScale.px(3))), Color("#dcc393"))
		draw_set_transform(feet, 0, Vector2(2.0, 2.0))
		VillageActorArt.person(self, 0, 0, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
