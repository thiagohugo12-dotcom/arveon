class_name EquipmentPage
extends RefCounted

# Página "Equipamento": personagem no centro, espaços de equipamento ao redor, atributos reais e
# conjuntos. Só os espaços Arma, Armadura e Acessório existem hoje; os demais aparecem apagados
# ("Em breve") e não recebem item nem número inventado.
const LEFT := [["Arma",true],["Armadura",true],["Luvas",false],["Anel",false]]
const RIGHT := [["Capacete",false],["Acessório",true],["Botas",false],["Amuleto",false]]

static func build(progress: GameProgress, hp: int, hp_max: int, on_slot: Callable, on_nav: Callable) -> PanelContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",6)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(_stage(progress,on_slot))
	body.add_child(_attributes(progress))
	body.add_child(_sets())
	return MenuKit.page("Equipamento","equipamento",on_nav,scroll,progress,hp,hp_max)

static func _stage(progress: GameProgress, on_slot: Callable) -> Control:
	var stage := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1b3a29")
	style.border_color = Color("#10261b")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	stage.add_theme_stylebox_override("panel",style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",4)
	stage.add_child(row)
	row.add_child(_column(LEFT,progress,on_slot))
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(center)
	var figure := CharacterStage.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	figure.custom_minimum_size = Vector2(0,UiScale.px(250))
	center.add_child(figure)
	var visual := Button.new()
	visual.text = "Alterar Visual"
	visual.disabled = true
	visual.tooltip_text = "Em breve"
	visual.custom_minimum_size.y = 40
	DefeatView.style_button(visual,"ghost","star",14,1)
	visual.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",6))
	visual.add_theme_color_override("font_disabled_color",Color("#b8b8a8"))
	center.add_child(visual)
	row.add_child(_column(RIGHT,progress,on_slot))
	return stage

static func _column(slots: Array, progress: GameProgress, on_slot: Callable) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	column.custom_minimum_size.x = UiScale.px(72)
	for entry: Array in slots:
		column.add_child(_slot(str(entry[0]),bool(entry[1]),progress,on_slot))
	return column

static func _slot(slot: String, real: bool, progress: GameProgress, on_slot: Callable) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation",0)
	var id := str(progress.equipped.get(slot,"")) if real else ""
	var tile: Control
	var caption := slot
	if real and not id.is_empty():
		var icon_id: String = ArsenalRules.metadata(id).icon
		var rarity: String = ArsenalRules.metadata(id).rarity
		var level := int(progress.equipment.get(id,0))
		if slot == "Arma" and progress.weapon_instances.has(progress.equipped_weapon_uid):
			var data := progress.weapon(progress.equipped_weapon_uid)
			icon_id = data.category
			rarity = data.rarity
			level = int(data.level)
		tile = MenuKit.item_tile(icon_id,MenuKit.rarity_color(rarity),"+%d" % level if level > 0 else "",UiScale.px(62))
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for state in ["normal","hover","pressed","focus"]: button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		button.set_meta("skin_done",true)
		button.tooltip_text = "%s · toque para ver na Mochila" % slot
		button.pressed.connect(on_slot.bind(id))
		tile.add_child(button)
	else:
		var ghost: String = slot if real else {"Luvas":"gloves","Anel":"ring","Capacete":"helmet","Botas":"boots","Amuleto":"amulet"}[slot]
		tile = MenuKit.item_tile(ghost,Color("#3a4a3d" if not real else "#6a5a2a"),"",UiScale.px(62),true)
		if not real: tile.tooltip_text = "%s · em breve" % slot
	cell.add_child(tile)
	var name := DefeatView.text(caption,13,DefeatView.CREAM if real else Color("#8a9a8c"))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	cell.add_child(name)
	return cell

static func _attributes(progress: GameProgress) -> Control:
	var card := DefeatView.card("paper",8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	card.add_child(column)
	var title := DefeatView.text("Atributos",19,DefeatView.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var stats := progress.combat_stats()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",3)
	column.add_child(grid)
	var rows := [["heart","Vida",str(stats.hp)],["boot","Velocidade","%.0f" % stats.speed],
		["swords","Ataque",str(stats.damage)],["target","Crítico","%.1f%%" % (stats.critical_chance * 100.0)],
		["shield","Defesa",str(stats.armor)],["flame","Dano crítico","%.0f%%" % (stats.critical_multiplier * 100.0)],
		["shield","Resistência","%.1f%%" % (stats.resistance * 100.0)],["bolt","Intervalo","−%.1f%%" % ((1.0 - stats.basic_interval_factor) * 100.0)]]
	for entry: Array in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation",6)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(DefeatView.picture(str(entry[0]),1))
		var name := DefeatView.text(str(entry[1]),15,DefeatView.INK)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(name)
		var value := DefeatView.text(str(entry[2]),15,DefeatView.INK)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(value)
		grid.add_child(line)
	return card

static func _sets() -> Control:
	var card := DefeatView.card("paper",8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	card.add_child(column)
	column.add_child(DefeatView.text("Conjuntos · em breve",17,DefeatView.INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	column.add_child(row)
	for index in range(3):
		var chip := Button.new()
		chip.text = str(index + 1)
		chip.disabled = true
		chip.custom_minimum_size = Vector2(44,40)
		DefeatView.style_button(chip,"chip","star",14,1,"chip_on")
		chip.icon = null
		chip.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",6))
		chip.add_theme_color_override("font_disabled_color",Color("#b8b8a8"))
		row.add_child(chip)
	var save := Button.new()
	save.text = "Salvar conjunto"
	save.disabled = true
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 40
	DefeatView.style_button(save,"chip","star",14,1,"chip_on")
	save.icon = null
	save.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",6))
	save.add_theme_color_override("font_disabled_color",Color("#b8b8a8"))
	row.add_child(save)
	return card

# Cenário do personagem: fundo de mata escura, círculo de pedra e o sprite atual ampliado.
class CharacterStage extends Control:
	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Céu da mata em degradê, duas fileiras de árvores, raios de luz e um círculo de pedra.
		var bands := 14
		for band in range(bands):
			var t := float(band) / float(bands - 1)
			draw_rect(Rect2(0,floorf(size.y * t * 0.8),size.x,ceilf(size.y * 0.8 / bands) + 1),Color("#10261b").lerp(Color("#2c5a3c"),t))
		draw_rect(Rect2(0,size.y * 0.8,size.x,size.y * 0.2),Color("#1f4a30"))
		for row in range(2):
			for index in range(8):
				var x := floorf(size.x * (0.02 + 0.14 * index + (0.05 if row == 1 else 0.0)))
				var base := size.y * (0.52 if row == 0 else 0.64)
				var height := (46.0 if row == 0 else 64.0) + float((index * 37 + row * 11) % 30)
				var dark := Color("#0e2216") if row == 0 else Color("#143222")
				var leaf := Color("#1c4630") if row == 0 else Color("#2a6040")
				draw_rect(Rect2(x - 4,base - height,8,height),dark)
				draw_circle(Vector2(x,base - height),16.0 + float((index * 13) % 8) + (4.0 if row == 1 else 0.0),leaf)
				draw_circle(Vector2(x - 6,base - height - 6),9.0,leaf.lightened(0.12))
		for ray in range(3):
			var from := Vector2(size.x * (0.2 + 0.25 * ray),0)
			draw_colored_polygon(PackedVector2Array([from,from + Vector2(26,0),from + Vector2(70,size.y * 0.7),from + Vector2(20,size.y * 0.7)]),Color(1.0,0.95,0.6,0.07))
		var feet := Vector2(floorf(size.x * 0.5),size.y - 38.0)
		for ring in range(3):
			var grow := float(ring) * 9.0
			draw_rect(Rect2(feet + Vector2(-58 + grow,-12 + grow * 0.3),Vector2(116 - grow * 2.0,26 - grow * 0.6)),[Color("#3c4c40"),Color("#58695b"),Color("#74867a")][ring])
		for mark in range(6):
			draw_rect(Rect2(feet + Vector2(-48 + mark * 17,-4),Vector2(2,10)),Color("#2c3a30"))
		for spark in range(7):
			var at := Vector2(size.x * (0.12 + 0.13 * spark),size.y * (0.3 + 0.07 * float((spark * 5) % 6)))
			draw_rect(Rect2(at,Vector2(2,2)),Color(1.0,0.93,0.55,0.8))
		var scale := minf(5.0,(size.y - 36.0) / 40.0)
		draw_set_transform(feet + Vector2(0,10),0,Vector2.ONE * (scale / 2.0))
		VillageActorArt.person(self,0,0,Vector2.ZERO)
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		for tuft in range(5):
			var x := size.x * (0.06 + 0.2 * tuft)
			draw_rect(Rect2(x,size.y - 14,2,10),Color("#3f7a45"))
			draw_rect(Rect2(x + 3,size.y - 18,2,14),Color("#4f9a52"))
			draw_rect(Rect2(x + 6,size.y - 12,2,8),Color("#3f7a45"))
