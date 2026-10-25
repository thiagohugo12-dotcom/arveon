class_name PixelItemIcon
extends Control

var slot := "Arma"
var frame_color := Color("#67805b")
var framed := true
var smooth := false

# Peças de equipamento sem arte no Diário usam os ícones em alta definição (SlotArtHD).
const HD_SLOTS := {"Capacete":"helmet","Luvas":"gloves","Botas":"boots","Anel":"ring","Amuleto":"amulet"}

static func hd_name(value: String) -> String:
	var key := value
	if RPGRules.EQUIPMENT.has(key) and not ArsenalRules.CATEGORIES.has(key): key = str(RPGRules.EQUIPMENT[key].slot)
	return str(HD_SLOTS.get(key,""))

func _init(value: String = "Arma", color: Color = Color("#67805b")) -> void:
	slot = value
	frame_color = color
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if not hd_name(value).is_empty() else CanvasItem.TEXTURE_FILTER_NEAREST

func _art_name() -> String:
	if RPGRules.EQUIPMENT.has(slot) and not ArsenalRules.CATEGORIES.has(slot): return str(RPGRules.EQUIPMENT[slot].slot)
	return slot

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/30.0)
	if framed:
		draw_style_box(DiaryTheme.piece("slot",0),Rect2(0,0,30,30))
	var hd := hd_name(slot)
	if not hd.is_empty():
		var target := Rect2(2,2,26,26) if framed else Rect2(0,0,30,30)
		draw_texture_rect(SlotArtHD.texture(hd,48),target,false)
		return
	if smooth and not framed:
		var texture := DiaryArt.smooth_texture(_art_name(),roundi(minf(size.x,size.y)))
		if texture != null:
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			draw_texture(texture,Vector2((size.x-texture.get_width())*0.5,(size.y-texture.get_height())*0.5).floor())
			return
	if DiaryArt.icon(self,_art_name(),Rect2(2,2,26,26) if framed else Rect2(0,0,30,30)): return
	var gold := Color("#697f78")
	match slot:
		"Ouro":
			draw_circle(Vector2(15,15),10,Color("#8e6330"))
			draw_circle(Vector2(15,15),7,Color("#e5b953"))
			draw_circle(Vector2(13,12),2,Color("#fff0ab"))
		"Madeira":
			draw_rect(Rect2(5,11,20,12),Color("#89552f"))
			draw_rect(Rect2(5,11,6,12),Color("#d5a454"))
			draw_rect(Rect2(13,13,11,3),Color("#b58042"))
		"Cogumelo", "Cogumelos":
			draw_rect(Rect2(12,16,7,10),Color("#fff1c9"))
			draw_rect(Rect2(5,9,21,9),Color("#bd5237"))
			draw_rect(Rect2(9,5,13,5),Color("#d76642"))
			draw_rect(Rect2(10,10,4,3),Color("#fff1c9"))
		"Pedra", "Pedras":
			draw_rect(Rect2(6,13,20,10),Color("#7c827b"))
			draw_rect(Rect2(10,8,12,10),Color("#b1b2a0"))
		"Minério de Ferro":
			draw_colored_polygon(PackedVector2Array([Vector2(4,21),Vector2(7,12),Vector2(14,7),Vector2(23,10),Vector2(27,19),Vector2(20,25),Vector2(9,25)]),Color("#555d5c"))
			draw_rect(Rect2(10,11,9,5),Color("#9da69a"))
			draw_rect(Rect2(16,17,7,4),frame_color)
		"Erva", "Ervas":
			draw_rect(Rect2(14,6,3,20),Color("#4c7339"))
			draw_rect(Rect2(6,10,8,7),Color("#68963d"))
			draw_rect(Rect2(17,6,7,8),Color("#82a743"))
		"Arma", "espada":
			for i in range(10):
				draw_rect(Rect2(7 + i, 17 - i, 3, 3), gold)
			draw_rect(Rect2(7, 18, 10, 3), Color("#97704b"))
			draw_rect(Rect2(5, 20, 5, 5), Color("#b78c58"))
		"machado":
			for i in range(14):
				draw_rect(Rect2(6+i,23-i,2,2),Color("#ae7848"))
			draw_rect(Rect2(15,5,9,9),Color("#7d8f88"))
			draw_rect(Rect2(22,6,3,9),Color("#d4ded8"))
			draw_rect(Rect2(13,7,4,5),gold)
		"lanca":
			for i in range(17):
				draw_rect(Rect2(5+i,24-i,2,2),Color("#ae7848"))
			draw_rect(Rect2(21,4,4,6),Color("#d4ded8"))
			draw_rect(Rect2(23,3,2,3),Color("#eef2cf"))
		"arco":
			for y in range(6,25):
				var x := 9 + absi(y-15)/3
				draw_rect(Rect2(x,y,3,2),Color("#b58a51"))
			draw_rect(Rect2(18,6,1,19),Color("#d5d3b7"))
			draw_rect(Rect2(8,15,15,1),Color("#c4ae7c"))
			draw_rect(Rect2(22,14,3,3),Color("#d9e0d2"))
		"cajado":
			for i in range(14):
				draw_rect(Rect2(6+i,24-i,3,2),Color("#ae7848"))
			draw_rect(Rect2(16,4,9,9),Color("#3a7259"))
			draw_rect(Rect2(18,5,6,7),Color("#8edb8b"))
			draw_rect(Rect2(19,5,3,3),Color("#ebf0b4"))
		"Presa de Javali":
			draw_colored_polygon(PackedVector2Array([Vector2(8,24),Vector2(10,12),Vector2(17,6),Vector2(23,6),Vector2(19,10),Vector2(17,17),Vector2(13,24)]),Color("#f0e6c4"))
			draw_colored_polygon(PackedVector2Array([Vector2(10,14),Vector2(17,8),Vector2(19,9),Vector2(14,16)]),Color("#fffbe8"))
		"Teia Reforçada":
			for angle in range(6):
				var direction := Vector2.from_angle(angle * PI / 3.0) * 11.0
				draw_line(Vector2(15,15),Vector2(15,15) + direction,Color("#e9efe6"),1.5)
			draw_arc(Vector2(15,15),5.0,0.0,TAU,16,Color("#cfd9d2"),1.5)
			draw_arc(Vector2(15,15),9.0,0.0,TAU,20,Color("#cfd9d2"),1.5)
		"Espinho Seco":
			draw_colored_polygon(PackedVector2Array([Vector2(13,25),Vector2(14,6),Vector2(17,25)]),Color("#d8c27a"))
			draw_rect(Rect2(9,22,12,3),Color("#7c8f4a"))
		"Pepita Dourada":
			draw_colored_polygon(PackedVector2Array([Vector2(6,20),Vector2(9,11),Vector2(17,8),Vector2(24,13),Vector2(23,21),Vector2(14,24)]),Color("#d9a73a"))
			draw_rect(Rect2(11,12,6,3),Color("#ffe58a"))
		"Placa de Tatu":
			draw_rect(Rect2(6,9,18,14),Color("#8a7a63"))
			for column in range(3):
				draw_rect(Rect2(8 + column * 6,11,4,10),Color("#b7a58b"))
		"Ferrão da Chapada":
			draw_colored_polygon(PackedVector2Array([Vector2(8,23),Vector2(14,10),Vector2(20,5),Vector2(18,13),Vector2(13,23)]),Color("#6a4b8f"))
			draw_rect(Rect2(7,22,8,3),Color("#4a3566"))
		"Coração da Mata":
			draw_circle(Vector2(11,13),5.0,Color("#4f9a52"))
			draw_circle(Vector2(19,13),5.0,Color("#4f9a52"))
			draw_colored_polygon(PackedVector2Array([Vector2(6,15),Vector2(24,15),Vector2(15,26)]),Color("#3f8248"))
			draw_rect(Rect2(13,11,4,4),Color("#bfe38f"))
		"Núcleo de Arenito":
			draw_colored_polygon(PackedVector2Array([Vector2(15,4),Vector2(25,15),Vector2(15,26),Vector2(5,15)]),Color("#d09a55"))
			draw_colored_polygon(PackedVector2Array([Vector2(15,8),Vector2(21,15),Vector2(15,22),Vector2(9,15)]),Color("#f2cf8b"))
		"Fragmento de Receita":
			draw_rect(Rect2(7,6,16,19),Color("#e8d6a0"))
			draw_rect(Rect2(10,10,10,2),Color("#8a6a3a"))
			draw_rect(Rect2(10,14,10,2),Color("#8a6a3a"))
			draw_rect(Rect2(10,18,6,2),Color("#8a6a3a"))
		"Armadura":
			draw_colored_polygon(PackedVector2Array([Vector2(8, 7), Vector2(15, 10), Vector2(22, 7), Vector2(21, 20), Vector2(15, 25), Vector2(9, 20)]), Color("#a3b2a2"))
			draw_rect(Rect2(14, 12, 3, 9), gold)
		_:
			draw_rect(Rect2(11, 7, 8, 3), gold)
			draw_rect(Rect2(8, 11, 3, 9), gold)
			draw_rect(Rect2(19, 11, 3, 9), gold)
			draw_rect(Rect2(11, 20, 8, 3), gold)
			draw_rect(Rect2(13, 13, 4, 5), Color("#6aa797"))
