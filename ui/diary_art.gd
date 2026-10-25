class_name DiaryArt
extends RefCounted

const BOOK := preload("res://assets/art/diary_v2/book_skin.png")
const ITEMS := preload("res://assets/art/diary_v2/items_skin.png")
const ICONS := ["espada","machado","lanca","arco","cajado","Armadura","Acessório","Broto Ancestral","Madeira","Cogumelos","Ervas","Pedras","Couro","Seda","Essência","maestria"]

static func icon(canvas: CanvasItem, name: String, rect: Rect2) -> bool:
	var index := ICONS.find("espada" if name == "Arma" else name)
	if index < 0: return false
	var cell := ITEMS.get_size()/4.0
	canvas.draw_texture_rect_region(ITEMS,rect,Rect2(Vector2(index%4,index/4)*cell,cell))
	return true

static func book_style(single: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = BOOK
	style.region_rect = Rect2(192,14,184,228) if single else Rect2(8,14,368,228)
	style.texture_margin_left = 16
	style.texture_margin_top = 16
	style.texture_margin_right = 16
	style.texture_margin_bottom = 20
	style.draw_center = false
	style.set_content_margin_all(22)
	return style

static func skin(panel: PanelContainer) -> void:
	var single := panel.size.x < 600 or panel is RPGPanel
	if panel.has_meta("diary_single") and panel.get_meta("diary_single") == single: return
	panel.set_meta("diary_single",single)
	panel.set_meta("diary_spread",false)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if panel.has_meta("custom_frame"): return
	panel.add_theme_stylebox_override("panel",DiaryTheme.piece("frame",22))
