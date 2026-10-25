class_name MenuKit
extends RefCounted

# Peças compartilhadas das páginas de menu (Equipamento, Mochila...): faixa de status no topo,
# título em placa, barra de navegação inferior e quadradinhos de item com moldura de raridade.
const PAGES := [["personagem","Personagem","person"],["equipamento","Equipamento","shield"],["mochila","Mochila","bag"],
	["habilidades","Habilidades","bolt"],["missoes","Missões","scroll"],["mapa","Mapa","map"]]

static func rarity_color(rarity: String) -> Color:
	return Color(str(ArsenalRules.RARITIES[rarity].color)) if ArsenalRules.RARITIES.has(rarity) else Color("#5a6a5a")

# Moldura da página: faixa de status, título, o corpo (que cresce) e a barra de navegação.
static func page(title: String, active: String, on_nav: Callable, body: Control, progress: GameProgress, hp: int, hp_max: int) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.set_meta("custom_frame",true)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_theme_stylebox_override("panel",DefeatArt.plate("frame",UiScale.px(6)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	frame.add_child(column)
	column.add_child(status_strip(progress,hp,hp_max))
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_stylebox_override("normal",DefeatArt.plate("title",UiScale.px(6)))
	heading.add_theme_font_override("font",DefeatView.font())
	heading.add_theme_font_size_override("font_size",UiScale.font(26))
	heading.add_theme_color_override("font_color",DefeatView.CREAM)
	heading.add_theme_color_override("font_outline_color",Color("#10261b"))
	heading.add_theme_constant_override("outline_size",3)
	column.add_child(heading)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	column.add_child(nav_bar(active,on_nav))
	return frame

static func status_strip(progress: GameProgress, hp: int, hp_max: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	var left := DefeatView.card("slot",5)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var inside := HBoxContainer.new()
	inside.add_theme_constant_override("separation",8)
	left.add_child(inside)
	var portrait := HeadView.new()
	inside.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation",0)
	inside.add_child(info)
	info.add_child(DefeatView.text("Nv. %d" % progress.level(),16,DefeatView.CREAM))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	bar.max_value = maxi(1,hp_max)
	bar.value = clampi(hp,0,maxi(1,hp_max))
	bar.set_meta("skin_done",true)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#c93a2e")
	var back := StyleBoxFlat.new()
	back.bg_color = Color("#3a1410")
	back.border_color = Color("#1b0f08")
	back.set_border_width_all(1)
	bar.add_theme_stylebox_override("fill",fill)
	bar.add_theme_stylebox_override("background",back)
	info.add_child(bar)
	info.add_child(DefeatView.text("%d/%d" % [hp,hp_max],12,Color("#f4d8d0")))
	var right := DefeatView.card("slot",5)
	row.add_child(right)
	var wallet := VBoxContainer.new()
	wallet.add_theme_constant_override("separation",2)
	right.add_child(wallet)
	wallet.add_child(_currency(DefeatArt.texture("coins",1),progress.gold,ForgeView.GOLD))
	wallet.add_child(_currency(SlotArtHD.texture("gem",18),progress.gems,Color("#9fd6ff")))
	return row

static func _currency(texture: Texture2D, amount: int, color: Color) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation",6)
	line.custom_minimum_size.x = UiScale.px(86)
	var coin := TextureRect.new()
	coin.texture = texture
	coin.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin.custom_minimum_size = Vector2(22,20)
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	line.add_child(coin)
	var value := DefeatView.text(_grouped(amount),16,color)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(value)
	return line

static func _grouped(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	for index in range(text.length()):
		if index > 0 and (text.length() - index) % 3 == 0: out += "."
		out += text[index]
	return out

static func nav_bar(active: String, on_pick: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",1)
	for entry: Array in PAGES:
		var button := Button.new()
		button.name = "Nav_" + str(entry[0])
		button.text = str(entry[1])
		button.custom_minimum_size = Vector2(0,maxi(52,UiScale.px(58)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on: bool = str(entry[0]) == active
		DefeatView.style_button(button,"tab_on" if on else "tab",str(entry[2]),9,2,"tab_on")
		button.icon = nav_icon(str(entry[2]))
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("h_separation",0)
		button.add_theme_constant_override("icon_max_width",26)
		button.add_theme_font_size_override("font_size",9)
		tighten(button)
		button.pressed.connect(on_pick.bind(str(entry[0])))
		row.add_child(button)
	return row

# Quadradinho de item: fundo escuro, moldura na cor da raridade, ícone e um selo no canto.
static func item_tile(item_icon: String, color: Color, badge: String, side: int = 56, muted: bool = false) -> Control:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(side,side)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#16281d")
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	tile.add_theme_stylebox_override("panel",style)
	if item_icon.is_empty(): return tile
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(layer)
	var icon: Control
	if SlotArtHD.has(item_icon):
		var picture := TextureRect.new()
		picture.texture = SlotArtHD.texture(item_icon,64)
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon = picture
	else:
		var item := PixelItemIcon.new(item_icon)
		item.framed = false
		item.smooth = true
		item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon = item
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 3
	icon.offset_right = -4
	icon.offset_bottom = -3
	icon.modulate.a = 0.35 if muted else 1.0
	layer.add_child(icon)
	if not badge.is_empty():
		var label := Label.new()
		label.text = badge
		label.add_theme_font_override("font",DefeatView.font())
		label.add_theme_font_size_override("font_size",14)
		label.add_theme_color_override("font_color",Color.WHITE)
		label.add_theme_color_override("font_outline_color",Color("#10261b"))
		label.add_theme_constant_override("outline_size",4)
		label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		label.offset_left = -side + 8
		label.offset_top = -20
		label.offset_right = -3
		label.offset_bottom = -1
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(label)
	return tile

# Botões de barra: sem margem larga, texto cortado se faltar espaço (a barra nunca estoura a tela).
static func tighten(button: Button) -> void:
	button.clip_text = true
	for state in ["normal","hover","pressed","focus"]:
		var style: StyleBox = button.get_theme_stylebox(state)
		if style != null:
			style = style.duplicate()
			style.content_margin_left = 2
			style.content_margin_right = 2
			style.content_margin_top = 4
			style.content_margin_bottom = 2
			button.add_theme_stylebox_override(state,style)

# Cabeça do personagem com o mesmo ajuste de pupila que o sprite usa no jogo (a pupila direita
# tem 2 px nos dois primeiros quadros); sem isso o olho aparece torto.
class HeadView extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(36,36)
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var k := minf(size.x,size.y) / 16.0
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(Vector2.ZERO,Vector2(16,16) * k),Rect2(8,6,16,16))
		draw_rect(Rect2(Vector2(10,13) * k,Vector2(1,3) * k),Color8(250,190,131))

# Ícones da barra inferior: arte do próprio jogo quando existe, senão os ícones novos.
static func nav_icon(id: String) -> Texture2D:
	match id:
		"person": return SlotArtHD.texture("helmet",26)
		"shield": return DiaryArt.smooth_texture("Armadura",26)
		"bolt": return SlotArtHD.texture("book",26)
		"map": return SlotArtHD.texture("map",26)
	return DefeatArt.texture(id,2)

# Ícones das abas da Mochila (Todos, Equipamentos, Materiais, Consumíveis, Outros).
static func bag_tab_icon(id: String) -> Texture2D:
	match id:
		"bag": return SlotArtHD.texture("grid",22)
		"shield": return DiaryArt.smooth_texture("espada",22)
		"leaf": return DiaryArt.smooth_texture("Ervas",22)
		"heart": return SlotArtHD.texture("flask",22)
	return DefeatArt.texture(id,2)
