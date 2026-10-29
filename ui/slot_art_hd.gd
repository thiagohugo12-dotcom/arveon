class_name SlotArtHD
extends RefCounted

# Ícones de equipamento em 48x48 com sombreado em faixas (pixel art), luz vinda de cima à
# esquerda, brilho nas bordas voltadas para a luz e contorno azul-escuro.
const N := 48
const STEEL := ["#f4f8fc","#d0dae6","#a9b8cb","#7f8fa6","#58667c","#38425a"]
const LINE := Color("#1a2033")
static var _cache: Dictionary = {}

const IDS := ["helmet","gloves","boots","ring","amulet","book","flask","map","gem","grid"]

static func has(id: String) -> bool:
	return IDS.has(id)

static func texture(id: String, size: int) -> ImageTexture:
	var key := "%s@%d" % [id,size]
	if not _cache.has(key):
		var image := Image.create(N,N,false,Image.FORMAT_RGBA8)
		match id:
			"helmet": _helmet(image)
			"gloves": _gloves(image)
			"boots": _boots(image)
			"ring": _ring(image)
			"amulet": _amulet(image)
			"book": _book(image)
			"flask": _flask(image)
			"map": _map(image)
			"gem": _gem(image)
			"grid": _grid(image)
		_rim(image)
		_outline(image)
		if size != N: image.resize(size,size,Image.INTERPOLATE_LANCZOS)
		_cache[key] = ImageTexture.create_from_image(image)
	return _cache[key]

static func _inside(point: Vector2, polygon: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(point,polygon)

static func _poly(points: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point: Vector2 in points: polygon.append(point)
	return polygon

static func _fill(image: Image, polygon: PackedVector2Array, color: Color) -> void:
	for y in range(N):
		for x in range(N):
			if _inside(Vector2(x + 0.5,y + 0.5),polygon): image.set_pixel(x,y,color)

static func _disc(image: Image, cx: float, cy: float, radius: float, color: Color) -> void:
	for y in range(N):
		for x in range(N):
			if Vector2(x + 0.5,y + 0.5).distance_to(Vector2(cx,cy)) <= radius: image.set_pixel(x,y,color)

static func _steel(light: float) -> Color:
	return Color(STEEL[clampi(int((1.0 - clampf(light,0.0,1.0)) * 5.99),0,5)])

# Realce nas bordas voltadas para a luz (esquerda e topo) e sombra nas opostas.
static func _rim(image: Image) -> void:
	var source := image.duplicate() as Image
	for y in range(N):
		for x in range(N):
			var pixel := source.get_pixel(x,y)
			if pixel.a < 0.5: continue
			var left_empty := x == 0 or source.get_pixel(x - 1,y).a < 0.5
			var top_empty := y == 0 or source.get_pixel(x,y - 1).a < 0.5
			var right_empty := x == N - 1 or source.get_pixel(x + 1,y).a < 0.5
			var bottom_empty := y == N - 1 or source.get_pixel(x,y + 1).a < 0.5
			if (left_empty or top_empty) and pixel.get_luminance() > 0.3: image.set_pixel(x,y,pixel.lightened(0.35))
			elif right_empty or bottom_empty: image.set_pixel(x,y,pixel.darkened(0.3))

static func _outline(image: Image) -> void:
	var source := image.duplicate() as Image
	for y in range(N):
		for x in range(N):
			if source.get_pixel(x,y).a > 0.5: continue
			for offset: Vector2i in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				var at := Vector2i(x,y) + offset
				if at.x >= 0 and at.y >= 0 and at.x < N and at.y < N and source.get_pixel(at.x,at.y).a > 0.5:
					image.set_pixel(x,y,LINE)
					break

static func _helmet(image: Image) -> void:
	# Penacho vermelho varrido para trás, em três faixas de cor.
	var plume := _poly([Vector2(22,8),Vector2(19,4),Vector2(24,1),Vector2(32,1),Vector2(40,5),Vector2(44,12),Vector2(40,11),Vector2(35,9),Vector2(29,8),Vector2(25,9)])
	for y in range(N):
		for x in range(N):
			if _inside(Vector2(x + 0.5,y + 0.5),plume):
				var t := float(y - 1) / 9.0
				image.set_pixel(x,y,Color("#ee6d52") if t < 0.25 else Color("#c93f2d") if t < 0.6 else Color("#8a2418"))
	for strand in range(5):
		for step in range(7): image.set_pixel(clampi(25 + strand * 3 + step,0,N - 1),clampi(3 + strand + step / 2,0,N - 1),Color("#7a1c14"))
	# Casco: calota, viseira e guardas de bochecha com abertura central.
	var shell := _poly([Vector2(8,24),Vector2(9,15),Vector2(14,9),Vector2(24,6),Vector2(34,9),Vector2(39,15),Vector2(40,24),Vector2(40,37),Vector2(35,42),Vector2(30,42),Vector2(29,37),Vector2(19,37),Vector2(18,42),Vector2(13,42),Vector2(8,37)])
	for y in range(N):
		for x in range(N):
			var point := Vector2(x + 0.5,y + 0.5)
			if not _inside(point,shell): continue
			var light := 0.62 - 0.42 * (float(x) - 24.0) / 16.0 - 0.22 * float(y - 6) / 36.0
			light += 0.34 * exp(-(pow(float(x) - 17.0,2.0) + pow(float(y) - 13.0,2.0)) / 34.0)
			if y > 36: light -= 0.12
			image.set_pixel(x,y,_steel(light))
	# Crista central e faixa da testa.
	for y in range(8,19):
		image.set_pixel(24,y,Color(STEEL[1]))
		image.set_pixel(25,y,Color(STEEL[4]))
	for x in range(11,38):
		image.set_pixel(x,18,Color(STEEL[1]))
		image.set_pixel(x,19,Color(STEEL[3]))
	# Viseira escura com a barra do nariz por cima.
	var visor := _poly([Vector2(11,20),Vector2(37,20),Vector2(36,28),Vector2(32,31),Vector2(16,31),Vector2(12,28)])
	_fill(image,visor,Color("#0e1220"))
	for x in range(13,36): image.set_pixel(x,21,Color("#232c44"))
	for y in range(18,37):
		image.set_pixel(22,y,Color(STEEL[1]))
		image.set_pixel(23,y,Color(STEEL[2]))
		image.set_pixel(24,y,Color(STEEL[2]))
		image.set_pixel(25,y,Color(STEEL[3]))
		image.set_pixel(26,y,Color(STEEL[4]))
	for x in range(12,37): image.set_pixel(x,32,Color(STEEL[4]))
	# Respiros nas bochechas.
	for row in range(3):
		for x in [11,12,13]: image.set_pixel(x,34 + row * 2,Color("#1a2033"))
		for x in [34,35,36]: image.set_pixel(x,34 + row * 2,Color("#1a2033"))
	# Frisos dourados na borda da viseira e no suporte do penacho.
	for x in range(12,37):
		if x < 22 or x > 26: image.set_pixel(x,17,Color("#f4c542"))
	for x in range(12,22): image.set_pixel(x,16,Color("#fff08a"))
	_disc(image,24,8,2.6,Color("#f4c542"))
	image.set_pixel(23,7,Color("#fff08a"))
	# Rebites com brilho.
	for point: Vector2 in [Vector2(12,13),Vector2(36,13),Vector2(12,25),Vector2(36,25),Vector2(24,13)]:
		_disc(image,point.x,point.y,1.6,Color(STEEL[3]))
		image.set_pixel(int(point.x) - 1,int(point.y) - 1,Color(STEEL[0]))
	# Reflexo longo na calota.
	for step in range(7): image.set_pixel(13 + step,11 + step / 2,Color(STEEL[0]))

# ── Rampas de cor (do claro ao escuro) e preenchimento sombreado ──────────────────────────
const LEATHER := ["#e0a468","#c08048","#9a5f33","#744423","#522d17","#35200f"]
const GOLD := ["#fff6b0","#ffe066","#f4c542","#d49b22","#a8741a","#6e4a10"]
const BLUE := ["#e0f4ff","#a8dcff","#5aa8f0","#3f78d6","#2c52a8","#1c3374"]
const PURPLE := ["#d8c2f5","#b392e6","#8a62c8","#6a44a8","#4a2f80","#2f1c58"]
const PARCH := ["#fff6dc","#f1e2bd","#d5c59a","#b3a075","#8a7850","#5a4d30"]
const GREEN := ["#c8f0a0","#8fd870","#5cb85c","#3f8f48","#2c6a38","#1c4626"]
const RED := ["#ff9a80","#ee6d52","#c93f2d","#a02c20","#7a1f18","#4a120e"]

static func _pick(ramp: Array, light: float) -> Color:
	return Color(ramp[clampi(int((1.0 - clampf(light,0.0,1.0)) * 5.99),0,5)])

# Luz de cima à esquerda para um corpo centrado em (cx, cy) com raios (rx, ry).
static func _light(x: float, y: float, cx: float, cy: float, rx: float, ry: float, base: float = 0.6) -> float:
	var value := base - 0.4 * (x - cx) / rx - 0.3 * (y - cy) / ry
	value += 0.3 * exp(-(pow(x - (cx - rx * 0.4),2.0) + pow(y - (cy - ry * 0.45),2.0)) / (0.18 * rx * ry + 4.0))
	return value

static func _shade_poly(image: Image, points: Array, ramp: Array, cx: float, cy: float, rx: float, ry: float, base: float = 0.6) -> void:
	var polygon := _poly(points)
	for y in range(N):
		for x in range(N):
			if _inside(Vector2(x + 0.5,y + 0.5),polygon): image.set_pixel(x,y,_pick(ramp,_light(x + 0.5,y + 0.5,cx,cy,rx,ry,base)))

static func _shade_rect(image: Image, x0: int, y0: int, w: int, h: int, ramp: Array, base: float = 0.6) -> void:
	_shade_poly(image,[Vector2(x0,y0),Vector2(x0 + w,y0),Vector2(x0 + w,y0 + h),Vector2(x0,y0 + h)],ramp,x0 + w * 0.5,y0 + h * 0.5,w * 0.5,h * 0.5,base)

static func _shade_disc(image: Image, cx: float, cy: float, radius: float, ramp: Array, base: float = 0.6) -> void:
	for y in range(N):
		for x in range(N):
			if Vector2(x + 0.5,y + 0.5).distance_to(Vector2(cx,cy)) <= radius: image.set_pixel(x,y,_pick(ramp,_light(x + 0.5,y + 0.5,cx,cy,radius,radius,base)))

static func _erase_disc(image: Image, cx: float, cy: float, radius: float) -> void:
	for y in range(N):
		for x in range(N):
			if Vector2(x + 0.5,y + 0.5).distance_to(Vector2(cx,cy)) <= radius: image.set_pixel(x,y,Color(0,0,0,0))

static func _dot(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < N and y < N: image.set_pixel(x,y,color)

static func _line(image: Image, from: Vector2, to: Vector2, color: Color) -> void:
	var steps := int(maxf(absf(to.x - from.x),absf(to.y - from.y)))
	for step in range(steps + 1):
		var at := from.lerp(to,float(step) / float(maxi(1,steps)))
		_dot(image,roundi(at.x),roundi(at.y),color)

static func _gloves(image: Image) -> void:
	var tops := [9,5,7,12]
	for finger in range(4):
		var x0 := 10 + finger * 7
		var top: int = tops[finger]
		_shade_rect(image,x0,top,6,28 - top,STEEL,0.62)
		for joint in range(top + 7,26,7):
			for x in range(x0,x0 + 6): _dot(image,x,joint,Color(STEEL[5]))
			for x in range(x0,x0 + 5): _dot(image,x,joint - 1,Color(STEEL[1]))
		for x in range(x0 + 1,x0 + 4): _dot(image,x,top,Color(STEEL[0]))
	_shade_poly(image,[Vector2(10,26),Vector2(6,22),Vector2(3,17),Vector2(5,13),Vector2(9,15),Vector2(12,21)],STEEL,6,18,6,8,0.62)
	for point: Vector2 in [Vector2(5,16),Vector2(6,19)]: _dot(image,int(point.x),int(point.y),Color(STEEL[0]))
	_shade_poly(image,[Vector2(10,25),Vector2(38,25),Vector2(40,35),Vector2(36,40),Vector2(12,40),Vector2(8,35)],STEEL,24,32,15,8,0.6)
	for knuckle in range(4):
		_shade_disc(image,13.0 + knuckle * 7.0,27.0,3.0,STEEL,0.75)
	for x in range(12,37): _dot(image,x,31,Color(STEEL[4]))
	for point: Vector2 in [Vector2(15,35),Vector2(24,35),Vector2(33,35)]: _shade_disc(image,point.x,point.y,1.6,GOLD,0.7)
	_shade_poly(image,[Vector2(11,40),Vector2(37,40),Vector2(39,46),Vector2(9,46)],LEATHER,24,43,15,4,0.58)
	for x in range(10,39): _dot(image,x,41,Color(GOLD[2]))
	for x in range(12,38,4): _dot(image,x,44,Color(LEATHER[4]))

static func _boots(image: Image) -> void:
	for pair in range(2):
		var cx := 13 + pair * 22
		_shade_poly(image,[Vector2(cx - 9,10),Vector2(cx + 9,10),Vector2(cx + 9,30),Vector2(cx + 12,34),Vector2(cx + 13,41),Vector2(cx - 13,41),Vector2(cx - 12,34),Vector2(cx - 9,30)],LEATHER,cx,26,12,16,0.58)
		_shade_poly(image,[Vector2(cx - 10,4),Vector2(cx + 10,4),Vector2(cx + 9,12),Vector2(cx - 9,12)],LEATHER,cx,8,10,5,0.78)
		for x in range(cx - 8,cx + 9,3): _dot(image,x,10,Color(LEATHER[5]))
		for strap in [17,24]:
			for x in range(cx - 9,cx + 10): _dot(image,x,strap,Color(LEATHER[5]))
			for x in range(cx - 9,cx + 10): _dot(image,x,strap + 1,Color(LEATHER[3]))
		_shade_rect(image,cx - 3,16,6,5,GOLD,0.7)
		_dot(image,cx - 2,17,Color(GOLD[0]))
		_shade_poly(image,[Vector2(cx - 12,34),Vector2(cx + 12,34),Vector2(cx + 13,41),Vector2(cx - 13,41)],LEATHER,cx,37,13,4,0.72)
		_shade_rect(image,cx - 14,41,28,4,LEATHER,0.12)
		for x in range(cx - 13,cx + 14,3): _dot(image,x,43,Color(LEATHER[5]))

static func _ring(image: Image) -> void:
	_shade_disc(image,24,30,16,GOLD,0.62)
	_erase_disc(image,24,31,9.5)
	for angle in range(0,360,30):
		var at := Vector2(24,30) + Vector2.from_angle(deg_to_rad(float(angle))) * 12.6
		if angle in [210,240,270]: _dot(image,roundi(at.x),roundi(at.y),Color(GOLD[0]))
	for y in range(30,46):
		for x in range(24,40):
			if Vector2(x + 0.5,y + 0.5).distance_to(Vector2(24,31)) > 9.5 and Vector2(x + 0.5,y + 0.5).distance_to(Vector2(24,30)) <= 16 and Vector2(x + 0.5,y + 0.5).distance_to(Vector2(24,31)) < 11: image.set_pixel(x,y,Color(GOLD[5]))
	_shade_poly(image,[Vector2(24,2),Vector2(34,9),Vector2(30,19),Vector2(18,19),Vector2(14,9)],BLUE,24,11,10,9,0.62)
	_shade_poly(image,[Vector2(24,2),Vector2(14,9),Vector2(24,13)],BLUE,22,8,6,6,0.95)
	_line(image,Vector2(14,9),Vector2(34,9),Color(BLUE[4]))
	_line(image,Vector2(24,13),Vector2(24,19),Color(BLUE[4]))
	_line(image,Vector2(24,13),Vector2(18,19),Color(BLUE[3]))
	_dot(image,19,7,Color("#ffffff"))
	_dot(image,20,6,Color("#ffffff"))
	for point: Vector2 in [Vector2(14,20),Vector2(34,20),Vector2(24,21)]: _shade_disc(image,point.x,point.y,2.2,GOLD,0.75)

static func _amulet(image: Image) -> void:
	for step in range(0,19):
		var t := float(step) / 18.0
		var left := Vector2(5,2).lerp(Vector2(22,17),t) + Vector2(0,sin(t * PI) * -2.0)
		var right := Vector2(43,2).lerp(Vector2(26,17),t) + Vector2(0,sin(t * PI) * -2.0)
		for at: Vector2 in [left,right]:
			_shade_disc(image,at.x,at.y,1.9,GOLD,0.72 if step % 2 == 0 else 0.45)
	_shade_poly(image,[Vector2(20,15),Vector2(28,15),Vector2(30,21),Vector2(18,21)],GOLD,24,18,6,4,0.7)
	_shade_disc(image,24,32,15,GOLD,0.62)
	_shade_disc(image,24,32,11,GOLD,0.2)
	_shade_disc(image,24,32,9.4,BLUE,0.55)
	for y in range(N):
		for x in range(N):
			var d := Vector2(x + 0.5,y + 0.5).distance_to(Vector2(24,32))
			if d <= 9.4: image.set_pixel(x,y,_pick(BLUE,_light(x + 0.5,y + 0.5,24,32,9.4,9.4,0.55)))
	for point: Vector2 in [Vector2(24,17),Vector2(9,32),Vector2(39,32),Vector2(24,47)]:
		if point.y < 46: _shade_disc(image,point.x,point.y,1.8,GOLD,0.9)
	_dot(image,19,27,Color("#ffffff"))
	_dot(image,20,26,Color("#ffffff"))
	_dot(image,19,28,Color(BLUE[0]))

static func _book(image: Image) -> void:
	_shade_rect(image,8,5,31,38,PURPLE,0.6)
	_shade_rect(image,8,5,7,38,PURPLE,0.1)
	_shade_rect(image,37,7,3,35,PARCH,0.7)
	_shade_rect(image,10,41,29,3,PARCH,0.7)
	for y in range(8,40,3): _dot(image,38,y,Color(PARCH[4]))
	for x in range(10,38,3): _dot(image,x,42,Color(PARCH[4]))
	for y in [9,18,27,36]:
		_shade_rect(image,8,y,7,3,GOLD,0.72)
	for corner: Vector2 in [Vector2(17,7),Vector2(34,7),Vector2(17,38),Vector2(34,38)]:
		_shade_rect(image,int(corner.x) - 1,int(corner.y) - 1,4,4,GOLD,0.72)
	_shade_poly(image,[Vector2(26,13),Vector2(34,24),Vector2(26,35),Vector2(18,24)],GOLD,26,24,8,11,0.65)
	_shade_poly(image,[Vector2(26,16),Vector2(31,24),Vector2(26,32),Vector2(21,24)],BLUE,26,24,5,8,0.6)
	_dot(image,24,20,Color("#ffffff"))
	_dot(image,25,19,Color("#ffffff"))
	_shade_poly(image,[Vector2(30,41),Vector2(34,41),Vector2(34,47),Vector2(32,45),Vector2(30,47)],RED,32,44,2,4,0.6)
	for x in range(16,38): _dot(image,x,6,Color(PURPLE[0]))

static func _flask(image: Image) -> void:
	_shade_rect(image,19,10,10,14,PARCH,0.9)
	_shade_disc(image,24,33,14,PARCH,0.9)
	_shade_poly(image,[Vector2(17,8),Vector2(31,8),Vector2(30,12),Vector2(18,12)],PARCH,24,10,7,2,0.85)
	_shade_rect(image,20,2,8,7,LEATHER,0.6)
	_shade_rect(image,20,2,8,2,LEATHER,0.85)
	for y in range(N):
		for x in range(N):
			var point := Vector2(x + 0.5,y + 0.5)
			if point.distance_to(Vector2(24,33)) <= 12.0 and y >= 28:
				image.set_pixel(x,y,_pick(BLUE,_light(x + 0.5,y + 0.5,24,34,12,10,0.55)))
	for x in range(13,36): if Vector2(x + 0.5,28.5).distance_to(Vector2(24,33)) <= 12.0: _dot(image,x,28,Color(BLUE[0]))
	_dot(image,18,31,Color("#ffffff"))
	for step in range(7): _dot(image,15,28 + step,Color("#ffffff"))
	for point: Vector2 in [Vector2(28,34),Vector2(22,38),Vector2(30,31)]: _dot(image,int(point.x),int(point.y),Color(BLUE[0]))
	for y in range(12,24): _dot(image,21,y,Color("#ffffff"))

static func _map(image: Image) -> void:
	_shade_rect(image,4,8,40,32,PARCH,0.62)
	for x in [17,31]:
		for y in range(8,40): _dot(image,x,y,Color(PARCH[4]))
		for y in range(8,40): _dot(image,x + 1,y,Color(PARCH[0]))
	for corner: Vector2 in [Vector2(4,8),Vector2(43,8),Vector2(4,39),Vector2(43,39)]: _dot(image,int(corner.x),int(corner.y),Color(PARCH[5]))
	_shade_poly(image,[Vector2(7,13),Vector2(15,12),Vector2(16,24),Vector2(9,27),Vector2(7,21)],GREEN,11,19,5,8,0.6)
	_shade_poly(image,[Vector2(20,14),Vector2(29,13),Vector2(29,32),Vector2(22,34),Vector2(19,25)],GREEN,24,22,6,10,0.55)
	_shade_poly(image,[Vector2(34,12),Vector2(41,12),Vector2(41,22),Vector2(34,22)],BLUE,37,17,4,5,0.6)
	for step in range(8):
		_dot(image,10 + step * 4,32 - (step % 3) * 2,Color(RED[3]))
		_dot(image,11 + step * 4,32 - (step % 3) * 2,Color(RED[3]))
	for point: Vector2 in [Vector2(35,28),Vector2(40,28),Vector2(37,31),Vector2(35,34),Vector2(40,34)]:
		_shade_rect(image,int(point.x) - 1,int(point.y) - 1,3,3,RED,0.5)

static func _gem(image: Image) -> void:
	_shade_poly(image,[Vector2(13,6),Vector2(35,6),Vector2(45,18),Vector2(24,44),Vector2(3,18)],BLUE,24,22,20,19,0.55)
	_shade_poly(image,[Vector2(13,6),Vector2(24,6),Vector2(20,18),Vector2(3,18)],BLUE,14,12,10,6,0.95)
	_shade_poly(image,[Vector2(24,6),Vector2(35,6),Vector2(45,18),Vector2(28,18)],BLUE,36,12,10,6,0.35)
	_line(image,Vector2(3,18),Vector2(45,18),Color(BLUE[4]))
	_line(image,Vector2(13,6),Vector2(20,18),Color(BLUE[1]))
	_line(image,Vector2(35,6),Vector2(28,18),Color(BLUE[4]))
	_line(image,Vector2(20,18),Vector2(24,44),Color(BLUE[1]))
	_line(image,Vector2(28,18),Vector2(24,44),Color(BLUE[5]))
	for point: Vector2 in [Vector2(10,10),Vector2(11,10),Vector2(10,11)]: _dot(image,int(point.x),int(point.y),Color("#ffffff"))

static func _grid(image: Image) -> void:
	for row in range(3):
		for column in range(3):
			_shade_rect(image,5 + column * 14,5 + row * 14,11,11,GOLD,0.62)
			for x in range(5 + column * 14,16 + column * 14): _dot(image,x,5 + row * 14,Color(GOLD[0]))
