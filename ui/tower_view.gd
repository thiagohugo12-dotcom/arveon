class_name TowerArtView
extends Control

# Torre Ancestral desenhada em código (pixel art): céu, montanhas, torre de pedra com
# dez andares e um medalhão tocável por andar. A arte é só apresentação; quem decide
# o estado de cada andar é o HUD, a partir de AscensionProgress e FloorCatalog.
signal floor_selected(id: int)

const FLOORS := 10
const SKY_TOP := Color("#6fb0e6")
const SKY_BOTTOM := Color("#cfe6f2")
const STONE := Color("#c9b487")
const STONE_LIGHT := Color("#dccba0")
const STONE_DARK := Color("#9d8963")
const STONE_SHADE := Color("#7c6a49")
const MOSS := Color("#4f8a3d")
const MOSS_DARK := Color("#2f6130")

var nodes: Array[Button] = []
var infos: Array = []
var margin_top := 22.0
var base_height := 86.0

class Medallion:
	extends Button
	var floor_id := 1
	var state := "locked"
	var chosen := false
	var radius := 17
	var number_font := DefeatView.font()

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		clip_text = true
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for style_name in ["normal","hover","pressed","focus","disabled"]:
			add_theme_stylebox_override(style_name,StyleBoxEmpty.new())
		for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
			add_theme_color_override(color_name,Color.TRANSPARENT)

	func _disc(center: Vector2, r: int, color: Color) -> void:
		for dy in range(-r,r + 1):
			var half := roundi(sqrt(maxf(0.0,float(r * r - dy * dy))))
			draw_rect(Rect2(center.x - half,center.y + dy,half * 2,1),color)

	func _draw() -> void:
		var center := (size / 2.0).floor()
		var r := radius
		var locked := state in ["locked","unavailable"]
		var ring := Color("#d6a53a") if state in ["current","completed"] else Color("#7fe07a") if state == "available" else Color("#55514a")
		var fill := Color("#1f5a3c") if not locked else Color("#2f2d2a")
		if state == "current":
			var swords := DefeatArt.texture("swords",3)
			draw_texture(swords,center - swords.get_size() / 2.0 + Vector2(0,-1))
		if chosen:
			_disc(center,r + 5,Color("#fff6d0"))
		_disc(center + Vector2(0,2),r + 3,Color(0,0,0,0.45))
		_disc(center,r + 3,Color("#14110d"))
		_disc(center,r + 1,ring)
		_disc(center,r - 2,fill)
		var text := str(floor_id)
		var font_size := 20 if r >= 16 else 16
		var width := number_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var shift := -3.0 if locked else 0.0
		var origin := Vector2(center.x - width / 2.0,center.y + font_size * 0.32 + shift)
		var color := Color("#fff0c3") if not locked else Color("#a39d90")
		draw_string_outline(number_font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color("#10261b") if not locked else Color("#151311"))
		draw_string(number_font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
		if locked:
			var lock := DefeatArt.texture("lock",1)
			draw_texture(lock,center + Vector2(-4,r * 0.35))
		elif state == "completed":
			var check := DefeatArt.texture("check",2)
			draw_texture(check,center + Vector2(r - 6,-r - 1))

func _init() -> void:
	custom_minimum_size = Vector2(0,450)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(_place_nodes)

# info: lista com {"id","state","selected","caption"} por andar, do 1 ao 10.
func configure(info: Array) -> void:
	for node in nodes:
		remove_child(node)
		node.queue_free()
	nodes.clear()
	infos = info
	for entry: Dictionary in info:
		var node := Medallion.new()
		node.floor_id = int(entry.id)
		node.state = str(entry.state)
		node.chosen = bool(entry.selected)
		node.text = str(entry.caption)
		node.tooltip_text = str(entry.caption)
		node.custom_minimum_size = Vector2(46,30)
		node.size = Vector2(46,38)
		var floor_id := int(entry.id)
		node.pressed.connect(func(): floor_selected.emit(floor_id))
		add_child(node)
		nodes.append(node)
	_place_nodes()
	queue_redraw()

func node_center(id: int) -> Vector2:
	var top := margin_top
	var bottom := size.y - base_height
	var step := (bottom - top) / float(FLOORS - 1)
	return Vector2(roundf(size.x / 2.0),roundf(bottom - float(id - 1) * step))

func _place_nodes() -> void:
	var step := (size.y - base_height - margin_top) / float(FLOORS - 1)
	for node: Medallion in nodes:
		node.radius = clampi(int(step * 0.46),12,17)
		# A altura do toque acompanha o espaçamento para os medalhões não se sobreporem.
		node.size = Vector2(46,minf(44.0,floorf(step)))
		node.position = node_center(node.floor_id) - node.size / 2.0
	queue_redraw()

func _tower_rect() -> Rect2:
	var width := minf(size.x * 0.58,230.0)
	return Rect2(roundf((size.x - width) / 2.0),12.0,width,size.y - 40.0)

func _draw() -> void:
	var w := size.x
	var h := size.y
	# Céu em faixas e nuvens.
	var bands := 16
	for i in range(bands):
		draw_rect(Rect2(0,floorf(i * h / bands),w,ceilf(h / bands) + 1),SKY_TOP.lerp(SKY_BOTTOM,float(i) / float(bands - 1)))
	for cloud: Vector3 in [Vector3(0.14,0.12,1.0),Vector3(0.82,0.18,0.8),Vector3(0.9,0.42,0.7),Vector3(0.08,0.4,0.9)]:
		_cloud(Vector2(w * cloud.x,h * cloud.y),cloud.z)
	# Montanhas e castelo ao longe.
	_mountain(Vector2(w * 0.1,h * 0.62),w * 0.34,h * 0.3)
	_mountain(Vector2(w * 0.9,h * 0.6),w * 0.38,h * 0.34)
	draw_rect(Rect2(w * 0.8,h * 0.52,w * 0.14,h * 0.05),Color("#9aa7b5"))
	for tower_x in [0.81,0.86,0.91]:
		draw_rect(Rect2(w * tower_x,h * 0.49,w * 0.025,h * 0.04),Color("#b8c0c9"))
	# Falésias e mata dos lados.
	draw_rect(Rect2(0,h * 0.62,w * 0.2,h * 0.38),Color("#7d8a82"))
	draw_rect(Rect2(w * 0.8,h * 0.66,w * 0.2,h * 0.34),Color("#7d8a82"))
	for i in range(18):
		var tx := (i % 2) * (w - 40.0) + (6.0 if i % 2 == 0 else 0.0) + float((i * 37) % 30)
		var ty := h * 0.55 + float((i * 53) % int(h * 0.4))
		_bush(Vector2(tx,ty),10.0 + float((i * 7) % 8))
	_tower(w,h)
	_ground(w,h)
	_decorations()

func _cloud(at: Vector2, scale_value: float) -> void:
	var white := Color(1,1,1,0.92)
	var unit := 8.0 * scale_value
	draw_rect(Rect2(at + Vector2(0,unit),Vector2(unit * 6,unit)),white)
	draw_rect(Rect2(at + Vector2(unit,0),Vector2(unit * 3,unit * 2)),white)
	draw_rect(Rect2(at + Vector2(unit * 3,unit * 0.5),Vector2(unit * 2.5,unit * 1.5)),white)

func _mountain(base: Vector2, width: float, height: float) -> void:
	var steps := 14
	for i in range(steps):
		var t := float(i) / float(steps)
		var row_width := width * (0.15 + t * 0.85)
		var y := base.y - height + t * height
		draw_rect(Rect2(base.x - row_width / 2.0,y,row_width,height / steps + 1),Color("#6f86a6").lerp(Color("#566d8c"),t))
		if t < 0.22:
			draw_rect(Rect2(base.x - row_width / 2.0,y,row_width,height / steps + 1),Color("#eef3f8"))

func _bush(at: Vector2, radius_value: float) -> void:
	var r := int(radius_value)
	for dy in range(-r,r + 1):
		var half := roundi(sqrt(maxf(0.0,float(r * r - dy * dy))))
		draw_rect(Rect2(at.x - half,at.y + dy,half * 2,1),MOSS if dy < r * 0.2 else MOSS_DARK)

func _tower(w: float, h: float) -> void:
	var body := _tower_rect()
	var flare := 10.0
	# Corpo com leve alargamento na base.
	for y in range(int(body.position.y),int(body.end.y)):
		var t := (float(y) - body.position.y) / body.size.y
		var extra := flare * t * t
		draw_rect(Rect2(body.position.x - extra,y,body.size.x + extra * 2.0,1),STONE)
	# Tijolos: fileiras com juntas alternadas.
	for row in range(0,int(body.size.y / 14.0)):
		var y := body.position.y + row * 14.0
		draw_rect(Rect2(body.position.x - 3.0,y,body.size.x + 6.0,1),STONE_DARK)
		var offset := 0.0 if row % 2 == 0 else 12.0
		var joint := body.position.x + offset
		while joint < body.end.x:
			draw_rect(Rect2(joint,y,1,14),STONE_DARK)
			joint += 24.0
	# Sombras laterais.
	draw_rect(Rect2(body.position.x - 3.0,body.position.y,body.size.x * 0.1,body.size.y),STONE_LIGHT)
	draw_rect(Rect2(body.end.x - body.size.x * 0.14,body.position.y,body.size.x * 0.17,body.size.y),STONE_DARK)
	# Cornijas entre andares.
	for id in range(1,FLOORS + 1):
		var y := node_center(id).y + 24.0
		draw_rect(Rect2(body.position.x - 7.0,y,body.size.x + 14.0,5),STONE_LIGHT)
		draw_rect(Rect2(body.position.x - 7.0,y + 5.0,body.size.x + 14.0,3),STONE_SHADE)
	# Ameias no topo.
	var crenel := 14.0
	var x := body.position.x - 4.0
	while x < body.end.x:
		draw_rect(Rect2(x,body.position.y - 9.0,crenel * 0.6,10.0),STONE_LIGHT)
		x += crenel
	# Janelas arqueadas ao lado de cada medalhão.
	for id in range(1,FLOORS + 1):
		var cy := node_center(id).y
		for side: float in [-1.0,1.0]:
			var wx := size.x / 2.0 + side * body.size.x * 0.34 - 5.0
			draw_rect(Rect2(wx,cy - 12.0,10,22),Color("#2b2620"))
			draw_rect(Rect2(wx + 2.0,cy - 15.0,6,4),Color("#2b2620"))
			draw_rect(Rect2(wx - 1.0,cy - 13.0,12,1),STONE_LIGHT)
	# Hera.
	for vine: Vector3 in [Vector3(0.1,0.18,16),Vector3(0.86,0.3,20),Vector3(0.12,0.55,14),Vector3(0.9,0.62,18),Vector3(0.18,0.78,16)]:
		var vx := body.position.x + body.size.x * vine.x
		var vy := h * vine.y
		for k in range(int(vine.z)):
			draw_rect(Rect2(vx + float((k * 5) % 7),vy + k * 3.0,5,4),MOSS if k % 3 != 0 else MOSS_DARK)
	# Porta e degraus.
	var cx := size.x / 2.0
	var base_y := body.end.y
	draw_rect(Rect2(cx - 32,base_y - 52,64,52),STONE_SHADE)
	draw_rect(Rect2(cx - 26,base_y - 46,52,46),Color("#5a3b22"))
	draw_rect(Rect2(cx - 22,base_y - 54,44,8),Color("#5a3b22"))
	draw_rect(Rect2(cx - 1,base_y - 46,2,46),Color("#2e1d10"))
	draw_rect(Rect2(cx - 22,base_y - 40,44,1),Color("#2e1d10"))
	draw_rect(Rect2(cx - 36,base_y,72,5),STONE_LIGHT)
	draw_rect(Rect2(cx - 42,base_y + 5,84,5),STONE_DARK)

func _ground(w: float, h: float) -> void:
	draw_rect(Rect2(0,h - 34.0,w,34.0),Color("#3d7a36"))
	for i in range(14):
		_bush(Vector2(float(i) * w / 13.0,h - 26.0 + float((i * 13) % 14)),9.0 + float((i * 5) % 9))
	for rock in [Vector2(w * 0.1,h - 14.0),Vector2(w * 0.88,h - 16.0),Vector2(w * 0.68,h - 8.0)]:
		draw_rect(Rect2(rock.x - 12,rock.y - 8,24,12),Color("#7b7d78"))
		draw_rect(Rect2(rock.x - 8,rock.y - 12,16,6),Color("#a1a39d"))

func _decorations() -> void:
	var body := _tower_rect()
	var cx := size.x / 2.0
	for side: float in [-1.0,1.0]:
		# Estandartes verdes com a árvore dourada.
		var bx := cx + side * (body.size.x * 0.5 + 4.0) - 9.0
		var by := size.y - base_height - 20.0
		draw_rect(Rect2(bx,by,18,36),Color("#1f5a3c"))
		draw_rect(Rect2(bx + 7,by + 6,4,16),Color("#d6a53a"))
		draw_rect(Rect2(bx + 3,by + 9,12,4),Color("#d6a53a"))
		draw_rect(Rect2(bx,by + 36,18,3),Color("#14110d"))
		# Tochas junto à porta.
		var tx := cx + side * 52.0 - 4.0
		var ty := size.y - 62.0
		draw_rect(Rect2(tx,ty + 10,8,14),Color("#4a4a48"))
		draw_rect(Rect2(tx + 1,ty,6,10),Color("#f08a2a"))
		draw_rect(Rect2(tx + 2,ty - 6,4,8),Color("#ffd84a"))
	for entry: Dictionary in infos:
		var center := node_center(int(entry.id))
		if str(entry.state) == "completed":
			var cup := DefeatArt.texture("trophy",2)
			draw_texture(cup,center + Vector2(34,-cup.get_height() / 2.0))
		elif str(entry.state) == "current":
			# Estandarte do Guardião ao lado do andar atual.
			var gx := center.x + 34.0
			draw_rect(Rect2(gx,center.y - 22,24,40),Color("#7a1f18"))
			draw_rect(Rect2(gx,center.y + 18,24,3),Color("#14110d"))
			var skull := DefeatArt.texture("skull",1)
			draw_texture(skull,Vector2(gx + 2,center.y - 14))
