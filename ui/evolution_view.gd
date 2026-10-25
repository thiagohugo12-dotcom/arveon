class_name EvolutionView
extends RefCounted

# Presentation-only components for the unified Evolution screen. Every value
# is read from GameProgress, RPGRules, TalentRules and AbilityRules by the caller.
const ATTRIBUTE_ICONS := {"Força":"swords","Vitalidade":"heart","Resistência":"shield","Mobilidade":"boot","Destreza":"target","Espírito":"flame"}
const EXPLORER := preload("res://assets/art/explorer_atlas.png")
const SECTION_ICONS := {"PERSONAGEM":"person","ATRIBUTOS":"chart","HABILIDADES":"swords","TALENTOS":"star","ÁRVORE":"tree","EQUIPAMENTO":"shield","MODO":"scroll","CATÁLOGO":"scroll"}

static func section_icon(caption: String) -> String:
	for key: String in SECTION_ICONS:
		if caption.begins_with(key): return SECTION_ICONS[key]
	return "star"

static func bar(value: float, max_value: float, height: int = 12, color: Color = Color("#4cc26a")) -> ProgressBar:
	var node := ProgressBar.new()
	node.custom_minimum_size.y = height
	node.max_value = maxf(1.0,max_value)
	node.value = value
	node.show_percentage = false
	node.set_meta("skin_done",true)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#b3a57e")
	back.border_color = Color("#3a2416")
	back.set_border_width_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.border_color = Color("#2b7a43")
	fill.set_border_width_all(1)
	node.add_theme_stylebox_override("background",back)
	node.add_theme_stylebox_override("fill",fill)
	return node

static func portrait() -> Control:
	var atlas := AtlasTexture.new()
	atlas.atlas = EXPLORER
	atlas.region = Rect2(8,2,32,44)
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(UiScale.px(80),UiScale.px(110))
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func character(progress: GameProgress, on_manage: Callable) -> Control:
	var plate := DefeatView.card("item",8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	top.add_child(portrait())
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation",2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(info)
	info.add_child(DefeatView.text(progress.active_class(),24,DefeatView.INK))
	var level := progress.level()
	info.add_child(DefeatView.text("Nv. %d" % level,20,DefeatView.INK))
	info.add_child(DefeatView.divider())
	if level < RPGRules.MAX_LEVEL:
		var xp_now := progress.xp-RPGRules.xp_floor(level)
		var xp_needed := RPGRules.cost_to_level(level)
		info.add_child(DefeatView.text("XP %d/%d" % [xp_now,xp_needed],16,DefeatView.INK))
		info.add_child(bar(xp_now,xp_needed))
		info.add_child(DefeatView.text("Total %d" % progress.xp,13,DefeatView.MUTED))
	else:
		info.add_child(DefeatView.text("Nível máximo · XP total %d" % progress.xp,15,DefeatView.INK))
	if not UiScale.compact: column.add_child(DefeatView.divider())
	var weapon := HBoxContainer.new()
	weapon.add_theme_constant_override("separation",10)
	weapon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Horizontal: retrato, personagem e arma na mesma linha.
	(top if UiScale.compact else column).add_child(weapon)
	var id := str(progress.equipped.get("Arma",""))
	var art := PixelItemIcon.new(ArsenalRules.metadata(id).icon if not id.is_empty() else "Arma")
	art.framed = false
	art.smooth = true
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.custom_minimum_size = Vector2(UiScale.px(36),UiScale.px(36))
	weapon.add_child(DefeatView.slot(art))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override("separation",0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon.add_child(text)
	var category := progress.active_category()
	text.add_child(DefeatView.text(("%s +%d" % [RPGRules.EQUIPMENT[id].name,int(progress.equipment.get(id,0))]) if not id.is_empty() else "Sem arma equipada",18,DefeatView.INK))
	if not category.is_empty():
		var prof := progress.talents.level(category)
		text.add_child(DefeatView.text("Proficiência da %s %d/%d" % [ArsenalRules.category_name(category),prof,TalentRules.MAX_PROFICIENCY],14,DefeatView.INK))
		if prof < TalentRules.MAX_PROFICIENCY:
			var prof_xp := int(progress.talents.xp[category])-TalentRules.xp_floor(prof)
			var prof_next := TalentRules.xp_floor(prof+1)-TalentRules.xp_floor(prof)
			text.add_child(bar(prof_xp,prof_next,10))
			text.add_child(DefeatView.text("XP de proficiência %d/%d" % [prof_xp,prof_next],12,DefeatView.MUTED))
		else:
			text.add_child(DefeatView.text("Proficiência máxima",13,DefeatView.MUTED))
	var manage := Button.new()
	manage.text = "Gerenciar equipamentos"
	manage.custom_minimum_size = Vector2(0,40 if UiScale.compact else 44)
	DefeatView.style_button(manage,"ghost","shield",16,1)
	manage.pressed.connect(on_manage)
	(text if UiScale.compact else column).add_child(manage)
	return plate

static func attribute_row(name: String, help: String, value: int, enabled: bool, on_plus: Callable) -> Array:
	var plate := DefeatView.card("item",6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	row.add_child(DefeatView.slot(DefeatView.picture(ATTRIBUTE_ICONS.get(name,"star"),2)))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override("separation",-3)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(DefeatView.text(name,18,DefeatView.INK))
	text.add_child(DefeatView.text(help,12,DefeatView.MUTED))
	row.add_child(text)
	var amount := DefeatView.text(str(value),26,DefeatView.INK)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.size_flags_horizontal = Control.SIZE_SHRINK_END
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(amount)
	var plus := Button.new()
	plus.text = "+1"
	plus.custom_minimum_size = Vector2(46,44)
	plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plus.disabled = not enabled
	DefeatView.style_button(plus,"button","plus",1,2)
	plus.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",8))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
		plus.add_theme_color_override(state,Color.TRANSPARENT)
	plus.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.pressed.connect(on_plus)
	row.add_child(plus)
	return [plate,plus]

static func info_card(title: String, caption: String, body: String, active: bool = true) -> Control:
	var plate := DefeatView.card("item_on" if active else "item",8)
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(column)
	column.add_child(DefeatView.text(title,18,DefeatView.INK))
	if not caption.is_empty(): column.add_child(DefeatView.text(caption,13,DefeatView.RED if not active else Color("#24502f")))
	column.add_child(DefeatView.text(body,14,DefeatView.MUTED))
	return plate

static func tree_summary(nodes: Array, current: int, next_title: String, next_detail: String, next_text: String) -> Control:
	var plate := DefeatView.card("slot",8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		var cell := DefeatView.card("skill_on" if index == current else "skill_off",4)
		cell.custom_minimum_size = Vector2(60,60)
		var art: Control
		if bool(node.get("unknown",false)):
			art = DefeatView.text("?",30,Color("#9a9a8a"))
			art.autowrap_mode = TextServer.AUTOWRAP_OFF
			art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			var icon := PixelItemIcon.new(str(node.icon))
			icon.framed = false
			icon.custom_minimum_size = Vector2(38,38)
			icon.modulate = Color.WHITE if index <= current else Color(0.6,0.6,0.55,0.85)
			art = icon
			art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(art)
		row.add_child(cell)
	var next := VBoxContainer.new()
	next.add_theme_constant_override("separation",0)
	next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(next)
	next.add_child(DefeatView.text("Próximo desbloqueio",14,Color("#c9b88a")))
	next.add_child(DefeatView.text(next_title,18,DefeatView.CREAM))
	next.add_child(DefeatView.text(next_detail,13,ForgeView.GOLD))
	next.add_child(DefeatView.text(next_text,13,Color("#d8c9a0")))
	return plate

# Cabeçalho de seção que abre e fecha (Evolução): o título inteiro é um botão e a seta
# mostra o estado. O estado vive em quem chama; aqui só o toque e o desenho.
static func accordion_header(icon_id: String, caption: String, trailing: String, opened: bool, on_toggle: Callable) -> Control:
	var plate: PanelContainer = DefeatView.section(icon_id,caption,1,trailing)
	var row: HBoxContainer = plate.get_child(0)
	row.remove_child(row.get_child(row.get_child_count()-1))
	var arrow := DefeatView.picture("chev_down" if opened else "chev_right",2)
	row.add_child(arrow)
	var button := Button.new()
	button.name = "Toggle"
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("skin_done",true)
	for state in ["normal","hover","pressed","focus","disabled"]: button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	button.tooltip_text = "Abrir ou fechar a seção"
	var open_now := [opened]
	button.pressed.connect(func():
		open_now[0] = not open_now[0]
		arrow.texture = DefeatArt.texture("chev_down" if open_now[0] else "chev_right",UiScale.icon_scale(2))
		on_toggle.call(open_now[0]))
	plate.add_child(button)
	return plate

# Re-skins widgets built by the shared legacy helpers so the whole page uses the
# approved kit. Behaviour, signals and disabled states are left untouched.
static func reskin(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Button and not child.has_meta("skin_done"): _reskin_button(child)
		elif child is Label and not child.has_meta("skin_done") and not (child.get_parent() is Button): _reskin_label(child)
		elif child is ProgressBar and not child.has_meta("skin_done"): _reskin_bar(child)
		elif child is PanelContainer and not child.has_meta("skin_done") and child.has_theme_stylebox_override("panel"):
			var style: StyleBox = child.get_theme_stylebox("panel")
			if style is StyleBoxFlat and (style as StyleBoxFlat).bg_color.get_luminance() > 0.6: child.add_theme_stylebox_override("panel",DefeatArt.plate("item",8))
		reskin(child)

static func _reskin_label(label: Label) -> void:
	label.set_meta("skin_done",true)
	if not label.has_theme_font_override("font"): label.add_theme_font_override("font",DefeatView.font())
	var size := label.get_theme_font_size("font_size")
	if size < 15: label.add_theme_font_size_override("font_size",size+2)
	var color := label.get_theme_color("font_color")
	if label.has_theme_color_override("font_color") and color.is_equal_approx(DiaryTheme.GREEN): label.add_theme_color_override("font_color",Color("#24502f"))

static func _reskin_bar(node: ProgressBar) -> void:
	node.set_meta("skin_done",true)
	var fresh := bar(node.value,node.max_value,int(maxf(node.custom_minimum_size.y,8)))
	node.add_theme_stylebox_override("background",fresh.get_theme_stylebox("background"))
	node.add_theme_stylebox_override("fill",fresh.get_theme_stylebox("fill"))

static func _reskin_button(button: Button) -> void:
	button.set_meta("skin_done",true)
	var normal := button.get_theme_stylebox("normal")
	var margin := normal.content_margin_left if normal.content_margin_left >= 0.0 else 8.0
	var kind := "chip"
	if normal is StyleBoxTexture:
		var texture: Texture2D = (normal as StyleBoxTexture).texture
		if texture == DiaryTheme.FRAMES["green"]: kind = "chip_on"
		elif texture == DiaryTheme.FRAMES["wood"]: kind = "tab_on"
	var selected := kind == "chip_on"
	for state in ["normal","hover","focus"]:
		var plate := DefeatArt.plate(kind,6)
		plate.content_margin_left = maxf(margin,6.0)
		button.add_theme_stylebox_override(state,plate)
	button.add_theme_stylebox_override("pressed",DefeatArt.plate("chip_on",6))
	button.add_theme_stylebox_override("disabled",DefeatArt.plate("dim",6))
	button.add_theme_font_override("font",DefeatView.font())
	button.add_theme_font_size_override("font_size",maxi(15,button.get_theme_font_size("font_size")+1))
	var ink := DefeatView.CREAM if selected else DefeatView.INK
	for state in ["font_color","font_hover_color","font_focus_color"]: button.add_theme_color_override(state,ink)
	button.add_theme_color_override("font_pressed_color",DefeatView.CREAM)
	button.add_theme_color_override("font_disabled_color",Color("#b8b8a8"))
