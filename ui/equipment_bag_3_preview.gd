class_name EquipmentBag3Preview
extends Control

# A apresentação é instanciada pelo HUD; transações continuam em GameProgress/Main.
signal close_requested
signal action_requested(action: String, item_id: String)
signal loadout_requested(action: String, index: int)
signal expansion_requested(with_gems: bool)

const FRAME := preload("res://assets/art/diary_v3/frame.png")
const STAGE := preload("res://assets/art/equipment_screen/courtyard-3-preview.png")
const HERO := preload("res://assets/art/equipment_screen/actual-explorer-art-preview.png")
const UI_FRAME := preload("res://assets/art/equipment_screen/ui-frame.png")
const SLOT_NAMEPLATE := Rect2(22, 391, 206, 63)
const COIN := preload("res://assets/art/equipment_screen/icons/coin-source.png")
const GEM := preload("res://assets/art/equipment_screen/icons/gem-source.png")
const HEART := preload("res://assets/art/equipment_screen/icons/heart.png")
const SWORDS := preload("res://assets/art/equipment_screen/icons/swords.png")
const SHIELD := preload("res://assets/art/equipment_screen/icons/shield.png")
const FONT := preload("res://assets/fonts/CormorantGaramond.ttf")
const SLOT_LEFT := ["Arma", "Armadura", "Luvas", "Anel"]
const SLOT_RIGHT := ["Capacete", "Acessório", "Botas", "Amuleto"]
const FILTERS := ["Todos", "Equipamentos", "Materiais", "Consumíveis", "Outros"]
const DARK := Color("#382314")
const GREEN := Color("#174a33")
const CREAM := Color("#fff0cc")

var progress: GameProgress
var selected_set := 0
var selected_id := ""
var selected_kind := ""
var target_slot := ""
var active_filter := "Todos"
var details_open := false
var attributes_open := false
var expansion_open := false
var hp := 1
var hp_max := 1
var bag_scroll: ScrollContainer

func _ready() -> void:
	size = Vector2(360, 800)
	custom_minimum_size = size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func present(value: GameProgress, current_hp: int, maximum_hp: int, set_index := 0) -> void:
	progress = value
	hp = current_hp
	hp_max = maxi(1, maximum_hp)
	selected_set = clampi(set_index, 0, 2)
	_rebuild()

func _rebuild() -> void:
	var scroll_position := bag_scroll.scroll_vertical if is_instance_valid(bag_scroll) else 0
	if selected_id.is_empty(): details_open = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if progress == null: return
	# Componentes independentes: o cenário e o herói não contêm textos ou controles.
	_image(STAGE, Rect2(0, 0, 360, 366))
	_panel(Rect2(2, 39, 356, 331), Color("#ead9ae"), Color("#8c5d2d"), 2)
	_image(STAGE, Rect2(9, 78, 342, 259), Color(1, 1, 1, 0.85))
	var hero_node := _image(HERO, Rect2(108, 103, 144, 229))
	hero_node.name = "PreviewHero"
	_panel(Rect2(0, 0, 360, 42), Color("#261911"), Color("#bd8642"), 2)
	_label("ARVÉON", Rect2(10, 1, 113, 26), 24, CREAM, true)
	_label("ASCENSÃO ANCESTRAL", Rect2(12, 25, 110, 11), 8, Color("#dabb79"))
	_image(COIN, Rect2(145, 9, 20, 23))
	_label(_grouped(progress.gold), Rect2(166, 8, 60, 25), 17, CREAM, true)
	_image(GEM, Rect2(238, 8, 21, 24))
	_label(str(progress.gems), Rect2(260, 8, 52, 25), 17, CREAM, true)
	var title_texture := AtlasTexture.new()
	title_texture.atlas = UI_FRAME
	title_texture.region = Rect2(0, 160, 941, 100)
	var title_node := _image(title_texture, Rect2(12, 42, 336, 36))
	title_node.name = "PreviewTitle"
	# A faixa central da própria arte cobre as estrelas que competiam com o título longo.
	var title_center := AtlasTexture.new()
	title_center.atlas = UI_FRAME
	title_center.region = Rect2(270, 181, 400, 56)
	_image(title_center, Rect2(63, 49, 234, 21))
	_label("Equipamento & Mochila", Rect2(40, 46, 280, 29), 21, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)
	_button("Fechar", Rect2(321, 43, 27, 32), "X", Color("#912b23"), func(): close_requested.emit())
	for i in range(4):
		_slot(SLOT_LEFT[i], 16, 80 + i * 62)
		_slot(SLOT_RIGHT[i], 250, 80 + i * 62)
	_loadouts()
	_stats()
	_bag()
	bag_scroll.set_deferred("scroll_vertical", scroll_position)
	if details_open: _details()
	if attributes_open: _attributes_overlay()
	if expansion_open: _expansion_overlay()

func _slot(slot: String, x: int, y: int) -> void:
	var item_id := str(progress.equipped.get(slot, ""))
	var rarity := progress.equipment_rarity(item_id) if not item_id.is_empty() else ""
	if slot == "Arma" and progress.weapon_instances.has(progress.equipped_weapon_uid):
		rarity = str(progress.weapon(progress.equipped_weapon_uid).rarity)
	var border := MenuKit.rarity_color(rarity) if not rarity.is_empty() else Color("#8b7559")
	var icon_frame := Rect2(x + 4, y, 47, 43)
	var frame := _panel(icon_frame, Color("#19221c"), border, 3)
	frame.name = "RarityFrame_" + slot
	if not item_id.is_empty():
		var path := EquipmentPage.sprite_path_for_item(item_id)
		if not path.is_empty():
			var sprite := _image(load(path) as Texture2D, Rect2(x + 9, y + 4, 37, 35), Color.WHITE, null, true)
			sprite.name = "OfficialItemSprite_" + slot
		var level := int(progress.equipment.get(item_id, 0))
		if slot == "Arma" and progress.weapon_instances.has(progress.equipped_weapon_uid):
			level = int(progress.weapon(progress.equipped_weapon_uid).level)
		if level > 0:
			_panel(Rect2(x + 29, y + 27, 22, 14), Color("#281c16"), Color("#a57a42"), 1)
			_label("+%d" % level, Rect2(x + 29, y + 27, 22, 14), 12, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)
	# As plaquetas ficam inteiras antes da coluna dos conjuntos (x=324).
	var caption := Rect2(235 if x > 180 else 6, y + 44, 78 if x > 180 else 84, 17)
	var caption_texture := AtlasTexture.new()
	caption_texture.atlas = UI_FRAME
	caption_texture.region = SLOT_NAMEPLATE
	var nameplate := _image(caption_texture, caption)
	nameplate.name = "SlotNameplate_" + slot
	var caption_label := _label(slot, Rect2(caption.position.x + 3, caption.position.y - 3, caption.size.x - 6, caption.size.y), 12 if slot.length() >= 8 else 13, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER)
	caption_label.name = "SlotCaption_" + slot
	_button("EquipmentSlot_" + slot, Rect2(caption.position.x, y, caption.size.x, 61), "", Color.TRANSPARENT, func(): _select_slot(slot))

func _select_slot(slot: String) -> void:
	if is_instance_valid(bag_scroll): bag_scroll.scroll_vertical = 0
	active_filter = "Equipamentos"
	target_slot = slot
	selected_id = str(progress.equipped.get(slot, ""))
	selected_kind = "equipment" if not selected_id.is_empty() else ""
	details_open = not selected_id.is_empty()
	_rebuild()

func _loadouts() -> void:
	_panel(Rect2(315, 97, 43, 219), Color("#ecd5a0"), Color("#977046"), 1)
	for index in range(3):
		var y := 126 + index * 38
		var saved := progress.has_loadout(index)
		var set_color := Color("#a3742d") if index == selected_set else GREEN if saved else Color("#4f4136")
		var set_button := _button("Loadout_%d" % (index + 1), Rect2(319, y, 36, 33), str(index + 1), set_color, _loadout.bind(index))
		set_button.add_theme_font_size_override("font_size", 16)
		set_button.tooltip_text = "Conjunto %d: %s" % [index + 1, "salvo" if saved else "vazio"]
		if saved: _panel(Rect2(349, y + 26, 4, 4), GREEN if index == selected_set else Color("#dfba70"), Color.TRANSPARENT, 0)
	var save_button := _button("SaveLoadout", Rect2(317, 245, 39, 58), "Salvar", GREEN if not progress.introduction_active() and not progress.save_blocked else Color("#665b49"), func(): loadout_requested.emit("save", selected_set))
	save_button.tooltip_text = "Salvar conjunto selecionado"
	save_button.add_theme_font_size_override("font_size", 11)
	save_button.disabled = progress.introduction_active() or progress.save_blocked
	_label("Conj.", Rect2(317, 105, 39, 17), 10, DARK, true, HORIZONTAL_ALIGNMENT_CENTER)

func _loadout(index: int) -> void:
	selected_set = index
	loadout_requested.emit("apply" if progress.has_loadout(index) else "select", index)
	_rebuild()

func _stats() -> void:
	_panel(Rect2(10, 333, 340, 34), Color("#f4e2b7"), Color("#a4753d"), 2)
	var stats := progress.combat_stats()
	_stat_cell("Vida", int(stats.hp), HEART, 16, 33, 31, 64, 31)
	_stat_cell("Ataque", int(stats.damage), SWORDS, 104, 121, 42, 163, 33)
	_stat_cell("Defesa", int(stats.armor), SHIELD, 204, 221, 42, 263, 32)
	_button("MoreAttributes", Rect2(300, 337, 45, 27), "Mais", Color("#cda96f"), func(): expansion_open = false; attributes_open = true; _rebuild())

func _stat_cell(stat_name: String, value: int, icon: Texture2D, icon_x: int, name_x: int, name_width: int, value_x: int, value_width: int) -> void:
	_image(icon, Rect2(icon_x, 342, 14, 16))
	var title := _label(stat_name, Rect2(name_x, 337, name_width, 24), 13, DARK, true)
	title.name = "StatName_" + stat_name
	var number := _label(str(value), Rect2(value_x, 337, value_width, 24), 13 if str(value).length() <= 3 else 11, DARK, true, HORIZONTAL_ALIGNMENT_RIGHT)
	number.name = "StatValue_" + stat_name

func _bag() -> void:
	_panel(Rect2(0, 370, 360, 430), Color("#e8d4a6"), Color("#865529"), 3)
	for index in range(FILTERS.size()):
		var filter_name: String = FILTERS[index]
		var x := index * 72 + 4
		var filter_button := _button("Filter_" + filter_name, Rect2(x, 376, 70, 32), "Equip." if index == 1 else "Consum." if index == 3 else filter_name, GREEN if active_filter == filter_name else Color("#463020"), func(): active_filter = filter_name; target_slot = ""; bag_scroll.scroll_vertical = 0; _rebuild())
		filter_button.add_theme_font_size_override("font_size", 13)
	_label("Mochila  %d/%d" % [progress.used_slots(), progress.bag_capacity()], Rect2(18, 412, 164, 25), 18, DARK, true)
	_button("ExpandBag", Rect2(252, 413, 99, 24), "+ Espaços", Color("#b88947"), func(): attributes_open = false; expansion_open = true; _rebuild())
	bag_scroll = ScrollContainer.new()
	bag_scroll.name = "BagScroll"
	bag_scroll.position = Vector2(10, 440)
	bag_scroll.size = Vector2(340, 343 if not details_open else 218)
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(bag_scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	bag_scroll.add_child(grid)
	var visible_entries := 0
	for entry in _entries():
		if not _matches(entry): continue
		visible_entries += 1
		var id := str(entry.id)
		var kind := str(entry.kind)
		var tile := Control.new()
		tile.custom_minimum_size = Vector2(62, 62)
		grid.add_child(tile)
		var color: Color = entry.color
		_decorate_tile(tile, color, id == selected_id)
		var path := str(entry.path)
		if not path.is_empty(): _image(load(path) as Texture2D, Rect2(9, 8, 44, 44), Color.WHITE, tile, true)
		else:
			var icon := PixelItemIcon.new(str(entry.icon))
			icon.framed = false
			icon.position = Vector2(9, 8)
			icon.size = Vector2(44, 44)
			tile.add_child(icon)
		if int(entry.quantity) > 1:
			var count_back := Panel.new()
			count_back.position = Vector2(32, 39)
			count_back.size = Vector2(25, 15)
			count_back.name = "QuantityBadge_" + id
			count_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			count_back.add_theme_stylebox_override("panel", _style(Color("#281c16"), Color("#a57a42"), 1))
			tile.add_child(count_back)
			_label(str(entry.quantity), Rect2(33, 39, 22, 15), 13, CREAM, true, HORIZONTAL_ALIGNMENT_CENTER, tile)
		var hit := Button.new()
		hit.name = "BagItem_" + id
		hit.flat = true
		hit.position = Vector2.ZERO
		hit.size = Vector2(62, 62)
		hit.tooltip_text = str(entry.name)
		hit.pressed.connect(func(): selected_id = id; selected_kind = kind; details_open = true; _rebuild())
		tile.add_child(hit)
	if visible_entries == 0:
		var empty_message := "Mochila vazia. Escolha sua\nprimeira arma no Ferreiro." if progress.introduction_active() else "Nenhum item nesta categoria."
		var empty_label := _label(empty_message, Rect2(28, 568 if not details_open else 505, 304, 60), 17, DARK, true, HORIZONTAL_ALIGNMENT_CENTER)
		empty_label.name = "EmptyBagHint"
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for uid: String in progress.weapon_instances:
		var weapon := progress.weapon(uid)
		var category := str(weapon.category)
		result.append({"id":uid,"kind":"equipment","name":str(RPGRules.EQUIPMENT[category].name),"path":EquipmentPage.sprite_path_for_item(category),"icon":category,"color":MenuKit.rarity_color(str(weapon.rarity)),"rarity":str(weapon.rarity),"quantity":1,"category":category})
	for id: String in progress.equipment:
		if ArsenalRules.CATEGORIES.has(id) and not progress.weapon_instances.is_empty(): continue
		if not RPGRules.EQUIPMENT.has(id): continue
		var rarity := progress.equipment_rarity(id)
		result.append({"id":id,"kind":"equipment","name":str(RPGRules.EQUIPMENT[id].name),"path":EquipmentPage.sprite_path_for_item(id),"icon":id,"color":MenuKit.rarity_color(rarity),"rarity":rarity,"quantity":1,"category":id})
	for key: String in progress.bag:
		var amount := int(progress.bag[key])
		if amount <= 0: continue
		var split := EquipmentEconomy.split_key(key)
		var rarity := str(split.rarity)
		var kind := "other" if LootRules.is_named(key) or key == EquipmentEconomy.SEAL else "material"
		result.append({"id":key,"kind":kind,"name":str(split.item),"path":"","icon":str(split.item),"color":MenuKit.rarity_color(rarity) if EquipmentEconomy.MATERIALS.has(split.item) else Color("#8c724c"),"rarity":rarity,"quantity":amount,"category":""})
	return result

func _matches(entry: Dictionary) -> bool:
	if not target_slot.is_empty() and (entry.kind != "equipment" or str(RPGRules.EQUIPMENT[str(entry.category)].slot) != target_slot): return false
	match active_filter:
		"Equipamentos": return entry.kind == "equipment"
		"Materiais": return entry.kind == "material"
		"Consumíveis": return entry.kind == "consumable"
		"Outros": return entry.kind == "other"
	return true

func _details() -> void:
	_panel(Rect2(10, 668, 340, 122), Color("#f5dfae"), Color("#9d6632"), 3)
	if selected_id.is_empty():
		_label("Toque em um slot ou item\nda Mochila.", Rect2(38, 701, 284, 52), 17, DARK, true, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var item: Dictionary = {}
	for entry in _entries():
		if str(entry.id) == selected_id: item = entry; break
	if item.is_empty():
		_label("Espaço vazio. Escolha um item\nda Mochila.", Rect2(38, 701, 284, 52), 17, DARK, true, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var path := str(item.path)
	_panel(Rect2(19, 681, 75, 75), Color("#242a27"), item.color, 3)
	if not path.is_empty(): _image(load(path) as Texture2D, Rect2(27, 689, 59, 59), Color.WHITE, null, true)
	else:
		var icon := PixelItemIcon.new(str(item.icon))
		icon.framed = false
		icon.position = Vector2(27, 690)
		icon.size = Vector2(58, 58)
		add_child(icon)
	_label(str(item.name), Rect2(101, 687, 240, 22), 18, DARK, true)
	_label((str(item.rarity).capitalize() + " · " if item.kind == "equipment" or item.kind == "material" else "") + ("Equipamento" if item.kind == "equipment" else "Material" if item.kind == "material" else "Outro"), Rect2(102, 705, 238, 17), 14, DARK, true)
	if item.kind == "equipment":
		var id := str(item.category)
		var upgrade := int(progress.weapon(selected_id).level) if progress.weapon_instances.has(selected_id) else int(progress.equipment.get(id, 0))
		_label(_bonus_summary(id, upgrade), Rect2(102, 720, 238, 16), 13, DARK, true)
		_label(_comparison(id, selected_id), Rect2(102, 736, 238, 16), 13, DARK, true)
		var worn: bool = selected_id == progress.equipped_weapon_uid if progress.weapon_instances.has(selected_id) else str(progress.equipped.get(str(RPGRules.EQUIPMENT[id].slot), "")) == id
		_button("PrimaryAction", Rect2(185, 761, 156, 23), "Desequipar" if worn else "Equipar", GREEN, func(): action_requested.emit("unequip" if worn else "equip", str(RPGRules.EQUIPMENT[id].slot) if worn else selected_id))
	else:
		_label("Quantidade: %d" % int(item.quantity), Rect2(102, 729, 238, 18), 14, DARK, true)
	_button("CloseDetails", Rect2(19, 761, 90, 22), "Recolher", Color("#785b39"), func(): details_open = false; _rebuild())

func _bonus_summary(category: String, upgrade: int) -> String:
	var bonus := RPGRules.bonuses(category, upgrade)
	var parts: Array[String] = []
	if int(bonus.damage) != 0: parts.append("Ataque %+d" % int(bonus.damage))
	if int(bonus.hp) != 0: parts.append("Vida %+d" % int(bonus.hp))
	if int(bonus.armor) != 0: parts.append("Defesa %+d" % int(bonus.armor))
	if int(bonus.speed) != 0: parts.append("Velocidade %+d" % int(bonus.speed))
	if float(bonus.crit) != 0.0: parts.append("Crítico %+.1f%%" % (float(bonus.crit) * 100.0))
	if float(bonus.crit_damage) != 0.0: parts.append("Dano crít. %+.0f%%" % (float(bonus.crit_damage) * 100.0))
	if float(bonus.resist) != 0.0: parts.append("Resist. %+.1f%%" % (float(bonus.resist) * 100.0))
	if int(bonus.spirit) != 0: parts.append("Espírito %+d" % int(bonus.spirit))
	return "Bônus: " + (" · ".join(parts.slice(0, 2)) if not parts.is_empty() else "nenhum")

func _comparison(category: String, item_id: String) -> String:
	var candidate := GameProgress.new()
	candidate.xp = progress.xp
	candidate.attributes = progress.attributes.duplicate(true)
	candidate.equipment = progress.equipment.duplicate(true)
	candidate.equipment_rarities = progress.equipment_rarities.duplicate(true)
	candidate.equipped = progress.equipped.duplicate(true)
	candidate.weapon_instances = progress.weapon_instances.duplicate(true)
	candidate.equipped_weapon_uid = progress.equipped_weapon_uid
	candidate.talents = progress.talents
	candidate.etapa2_enabled = progress.etapa2_enabled
	var accepted: bool = candidate.equip_weapon_instance(item_id) if candidate.weapon_instances.has(item_id) else candidate.equip(category)
	if not accepted: return "Equipado ou nível insuficiente"
	var before := progress.combat_stats()
	var after := candidate.combat_stats()
	var differences: Array[String] = []
	if int(after.damage) != int(before.damage): differences.append("Ataque %+d" % int(after.damage - before.damage))
	if int(after.hp) != int(before.hp): differences.append("Vida %+d" % int(after.hp - before.hp))
	if int(after.armor) != int(before.armor): differences.append("Defesa %+d" % int(after.armor - before.armor))
	if absf(after.critical_chance - before.critical_chance) > 0.0001: differences.append("Crítico %+.1f%%" % ((after.critical_chance - before.critical_chance) * 100.0))
	if absf(after.critical_multiplier - before.critical_multiplier) > 0.0001: differences.append("Dano crít. %+.0f%%" % ((after.critical_multiplier - before.critical_multiplier) * 100.0))
	if absf(after.resistance - before.resistance) > 0.0001: differences.append("Resist. %+.1f%%" % ((after.resistance - before.resistance) * 100.0))
	return "Dif.: " + (" · ".join(differences.slice(0, 2)) if not differences.is_empty() else "sem mudança")

func _attributes_overlay() -> void:
	_modal_blocker("AttributesModalBlocker")
	_panel(Rect2(35, 258, 290, 207), Color("#f2ddb2"), Color("#8c5d2d"), 3)
	var stats := progress.combat_stats()
	_label("Todos os atributos", Rect2(47, 272, 257, 27), 20, DARK, true, HORIZONTAL_ALIGNMENT_CENTER)
	var names_left := ["Vida", "Ataque", "Defesa", "Velocidade"]
	var values_left := [str(int(stats.hp)), str(int(stats.damage)), str(int(stats.armor)), "%.0f" % stats.speed]
	var names_right := ["Crítico", "Dano crítico", "Resistência", "Intervalo"]
	var values_right := ["%.1f%%" % (stats.critical_chance * 100.0), "%.0f%%" % (stats.critical_multiplier * 100.0), "%.1f%%" % (stats.resistance * 100.0), "%.1f%%" % ((1.0 - stats.basic_interval_factor) * 100.0)]
	for i in range(4):
		var y := 309 + i * 29
		_label(names_left[i], Rect2(54, y, 75, 23), 15, DARK, true)
		_label(values_left[i], Rect2(132, y, 42, 23), 15, DARK, true, HORIZONTAL_ALIGNMENT_RIGHT)
		_label(names_right[i], Rect2(181, y, 89, 23), 14, DARK, true)
		_label(values_right[i], Rect2(268, y, 39, 23), 14, DARK, true, HORIZONTAL_ALIGNMENT_RIGHT)
	var close_button := _button("CloseAttributes", Rect2(218, 430, 91, 29), "Fechar", Color("#773f2e"), func(): attributes_open = false; _rebuild())
	close_button.add_theme_font_size_override("font_size", 15)

func _expansion_overlay() -> void:
	_modal_blocker("ExpansionModalBlocker")
	_panel(Rect2(35, 416, 290, 152), Color("#f2ddb2"), Color("#8c5d2d"), 3)
	_label("Expandir Mochila", Rect2(50, 422, 260, 32), 23, DARK, true, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(2):
		var gems := i == 1
		var cost := progress.expansion_cost(gems)
		var title := "Máximo: 80" if cost < 0 else "%d %s" % [cost, "gemas" if gems else "ouro"]
		_button("ExpandGems" if gems else "ExpandGold", Rect2(51 + i * 132, 472, 125, 50), title, GREEN if progress.can_expand_bag(gems) else Color("#695a47"), func(): expansion_requested.emit(gems))
	_button("CloseExpansion", Rect2(241, 535, 67, 25), "Fechar", Color("#773f2e"), func(): expansion_open = false; _rebuild())

func _modal_blocker(node_name: String) -> void:
	var blocker := ColorRect.new()
	blocker.name = node_name
	blocker.position = Vector2.ZERO
	blocker.size = Vector2(360, 800)
	blocker.color = Color(0.05, 0.04, 0.02, 0.18)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

func _decorate_tile(tile: Control, color: Color, selected: bool) -> void:
	var panel := Panel.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(62, 62)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color("#292925"), Color("#9ad4ff") if selected else color, 3))
	tile.add_child(panel)

func _panel(rect: Rect2, fill: Color, edge: Color, width: int) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, edge, width))
	add_child(panel)
	if fill.r > 0.8 and fill.g > 0.7:
		var ornament := NinePatchRect.new()
		ornament.texture = FRAME
		ornament.patch_margin_left = 12
		ornament.patch_margin_top = 12
		ornament.patch_margin_right = 12
		ornament.patch_margin_bottom = 12
		ornament.position = rect.position
		ornament.size = rect.size
		ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ornament)
	return panel

func _style(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	return style

func _image(texture: Texture2D, rect: Rect2, tint := Color.WHITE, parent: Control = null, keep_aspect := false) -> TextureRect:
	var image_node := TextureRect.new()
	image_node.texture = texture
	image_node.modulate = tint
	image_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	image_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else self).add_child(image_node)
	image_node.position = rect.position
	image_node.size = rect.size
	return image_node

func _label(value: String, rect: Rect2, font_size: int, color: Color, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT, parent: Control = null) -> Label:
	var node := Label.new()
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.clip_text = true
	node.add_theme_font_override("font", DiaryTheme.heading_font() if bold else FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else self).add_child(node)
	return node

func _button(node_name: String, rect: Rect2, value: String, fill: Color, action: Callable) -> Button:
	var node := Button.new()
	node.name = node_name
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		node.add_theme_stylebox_override(state, _style(fill, Color("#d2a462") if fill != Color.TRANSPARENT else Color.TRANSPARENT, 2 if fill != Color.TRANSPARENT else 0))
	node.add_theme_font_override("font", DiaryTheme.heading_font())
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_color_override("font_color", CREAM)
	node.pressed.connect(action)
	add_child(node)
	return node

func _grouped(value: int) -> String:
	var text_value := str(value)
	var result := ""
	for index in range(text_value.length()):
		if index > 0 and (text_value.length() - index) % 3 == 0: result += "."
		result += text_value[index]
	return result
