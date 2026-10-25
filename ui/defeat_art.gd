class_name DefeatArt
extends RefCounted

# Pixel-art pieces for the Interface 2.0 defeat screen. Everything is authored
# here as character maps or small drawing routines, so no text is baked into a
# raster file. Textures are built once and cached.
const COLORS := {
	"k": Color("#1b0f08"), "w": Color("#f6efd8"), "b": Color("#d5c59a"), "B": Color("#a8956a"),
	"g": Color("#e8b83a"), "h": Color("#fff3a8"), "G": Color("#a8741a"),
	"r": Color("#b3392a"), "R": Color("#7a1f18"), "n": Color("#8a5a30"), "N": Color("#5a3820"),
	"e": Color("#6fd36a"), "E": Color("#2f7a3e"), "D": Color("#1f4a37"),
	"s": Color("#d3dbe4"), "S": Color("#8d98a8"), "o": Color("#f08a2a"), "y": Color("#ffd84a"),
	"p": Color("#9a9a94"), "P": Color("#62625e"), "c": Color("#f1e2bd"),
	"u": Color("#5b84e8"), "U": Color("#2c4aa8")
}

const MAPS := {
	"shield": [
		"................", "..kkkkkkkkkkkk..", "..kEeeeeEEEEEk..", "..kEeeEEEEEEEk..",
		"..kEeEEEEEEEDk..", "..kEeEEEEEEEDk..", "..kEEEEEEEEEDk..", "..kEEEEEEEEEDk..",
		"...kEEEEEEEDk...", "...kEEEEEEEDk...", "....kEEEEEDk....", ".....kEEEDk.....",
		"......kEDk......", ".......kk.......", "................", "................"],
	"bag": [
		"................", ".....kkkkkk.....", "......krrk......", ".....kcccck.....",
		"....kcccccck....", "...kcccccccck...", "..kccccggcccck..", "..kcccgGGgccck..",
		"..kcccgggGccck..", "..kccccgGcccck..", "...kcccccccck...", "...kBBBBBBBBk...",
		"....kkkkkkkk....", "................", "................", "................"],
	"home": [
		"................", ".......kk.......", "......krrk......", ".....krrrrk.....",
		"....krrrrrrk....", "...krrrrrrrrk...", "..krrrrrrrrrrk..", "....kcccccck....",
		"....kccnncck....", "....kccnncck....", "....kccnncck....", "....kkkkkkkk....",
		"................", "................", "................", "................"],
	"fire": [
		"................", ".......y........", "......yoy.......", ".....yoooy.y....",
		"....yooyooyy....", "...yooyyyyooy...", "...yooyyyyooy...", "....oooyyooo....",
		".....oooooo.....", "..kNnNNNNNNnNk..", ".kppkNNNNNNkppk.", ".kpPpkkkkkkkpPpk",
		"................", "................", "................", "................"],
	"scroll": [
		"................", "...kkkkkkkkkk...", "..kcccccccccck..", "..kckkkkkkkkck..",
		"..kcccccccccck..", "..kckkkkkkkkck..", "..kcccccccccck..", "..kckkkkkkkkck..",
		"..kcccccccccck..", "..kckkkkkkkkck..", "..kcccccccccck..", "...kkkkkkkkkk...",
		"................", "................", "................", "................"],
	"helmet": [
		"................", "......krrk......", ".....kkrrkk.....", "...kkssssssSkk..",
		"..kssssssssssSk.", "..ksshssssssSSk.", ".kssssssssssSSSk", ".kssPPPPPPPPSSSk",
		".kssPkkkkkkPSSSk", ".kssPPPPPPPPSSSk", ".ksssk....kSSSk.", ".ksssk....kSSSk.",
		".kkkkk....kkkkk.", "................", "................", "................"],
	"gloves": [
		"................", "....kk.kk.kk....", "...kSskSskSSk...", "...kSskSskSSk.kk",
		"...kSsssssSSkksk", "..kkSsssssSSksSk", "..kSsssssssSSSk.", "..kSssPPPPSSSk..",
		"...kSsssssSSSk..", "...kPssssSSSk...", "....kPPPPPPk....", "....kBBBBBBk....",
		"....kBbbbbBk....", ".....kkkkkk.....", "................", "................"],
	"ring": [
		"................", "................", ".....kkkkkk.....", "....kuhuuuUk....",
		"....kuuuuUUk....", ".....kkkkkk.....", "...kggggggggk...", "..kgGkkkkkkGgk..",
		"..kgk......kGk..", "..kgk......kGk..", "..kgk......kGk..", "..kgGk....kGgk..",
		"...kgGkkkkGgk...", "....kkggggkk....", ".....kkkkkk.....", "................"],
	"amulet": [
		"................", ".k............k.", ".kg..........gk.", "..kg........gk..",
		"..kGg......gGk..", "...kGg....gGk...", "....kGg..gGk....", ".....kGggGk.....",
		"......kggk......", ".....kkGGkk.....", "....kuuhuuUk....", "....kuuuuUUk....",
		"....kUuuuUUk....", ".....kUUUUk.....", "......kkkk......", "................"],
	"map": ["kkkkkkkk","kcBeeBrk","kcBeeBck","kcBccBck","kcBecBck","kcBccBck","kcBccBck","kkkkkkkk"],
	"bolt": ["....yy..", "...yy...", "..yy....", ".yyyyyy.", "...yy...", "..yy....", ".yy.....", "y......."],
	"heart": [".rr..rr.", "rrrrrrrr", "rrrrrrrr", "rrrrrrrr", ".rrrrrr.", "..rrrr..", "...rr...", "........"],
	"clover": [".ee..ee.", "eeeeeeee", "eeEeeEee", ".eeEEee.", ".eeEEee.", "eeEeeEee", "eeeeeeee", ".ee..ee."],
	"up": ["....cc....", "...cccc...", "..cccccc..", ".cccccccc.", "cccccccccc", "...cccc...", "...cccc...", "...cccc...", "...cccc...", ".........."],
	"star": ["....cc....", "....cc....", "...cccc...", "cccccccccc", ".cccccccc.", "..cccccc..", "..cccccc..", ".cccccccc.", ".ccc..ccc.", ".cc....cc."],
	"chev_down": ["........", "cccccccc", ".cccccc.", "..cccc..", "...cc...", "........", "........", "........"],
	"chev_right": ["..c.....", "..cc....", "..ccc...", "..cccc..", "..ccc...", "..cc....", "..c.....", "........"],
	"anvil": [".......y..y.", "........y...", "sssssssssss.", "ssssssssssss", ".sssssssssS.", "..sssssssS..", "....ssSS....", "....ssSS....", "...ssssSS...", "..ssssssSS..", "..SSSSSSSS.."],
	"check": ["....yy", "...yy.", "y.yy..", "yyy...", ".y...."],
	"trophy": ["gggggggg", "ghhgghgg", ".gggggg.", "..gggg..", "...gg...", "...gg...", "..gGGg..", ".gGGGGg."],
	"chest": [".kkkkkkkk.", "kggggggggk", "kgGGGGGGgk", "kkkkhhkkkk", "kgggkkgggk", "kgGGkkGGgk", "kggggggggk", ".kkkkkkkk."],
	"leaf_badge": ["kkkkkkkkk", "kDDDDDDDk", "kDDDeeDDk", "kDDeeeeDk", "kDeeeeeDk", "kDDeeeeDk", "kDDDeDDDk", "kDDDDDDDk", "kkkkkkkkk"],
	"person": ["..cccc..", ".cccccc.", ".cccccc.", "..cccc..", ".cccccc.", "cccccccc", "cccccccc", "cccccccc"],
	"chart": ["......cc", "......cc", "...cc.cc", "...cc.cc", "cc.cc.cc", "cc.cc.cc", "cc.cc.cc", "cccccccc"],
	"tree": [".cc..cc.", ".cc..cc.", "..c..c..", "..cccc..", "...cc...", "...cc...", ".cccccc.", "........"],
	"lock": ["..SSSS..", ".S....S.", ".S....S.", "SSSSSSSS", "SSSppSSS", "SSSppSSS", "SSSSSSSS", "........"],
	"flame": ["...uu...", "..uuu...", "..uuuu..", ".uuUuuu.", ".uuUUuu.", ".uuUUuu.", "..uuuu..", "...uu..."],
	"target": ["..rrrr..", ".rrwwrr.", "rrwrrwrr", "rwrwwrwr", "rwrwwrwr", "rrwrrwrr", ".rrwwrr.", "..rrrr.."],
	"boot": ["..gg....", "..gg....", "..gg....", "..ggg...", "..gggg..", ".ggggggg", ".gGGGGGG", "........"],
	"plus": ["....ww....", "....ww....", "....ww....", "....ww....", "wwwwwwwwww", "wwwwwwwwww", "....ww....", "....ww....", "....ww....", "....ww...."],
	"diamond": [
		"...k...", "..kgk..", ".kghgk.", "kghhhgk", ".kgggk.", "..kgk..", "...k..."],
	"leaf": [
		"..kEEk..", ".kEeEEk.", "kEeEEEEk", ".kEEEEk.", "..kkkk.."],
	"skull": [
		".....kkkkkkkkkk.....", "...kkwwwwwwwwwwkk...", "..kwwwwwwwwwwwwwwk..", ".kwwwwwwwwwwwwwwwwk.",
		".kwwwwwwwwwwwwwwwwk.", ".kwwkkkkwwwwkkkkwwk.", ".kwwkkkkwwwwkkkkwwk.", ".kwwwkkwwwwwwkkwwwk.",
		".kbwwwwwwkkwwwwwwbk.", "..kbwwwwwkkwwwwwbk..", "...kbbwwwwwwwwbbk...", "....kwkwkwwkwkwk....",
		".....kkkkkkkkkk....."]
}

static var _textures: Dictionary = {}
static var _plates: Dictionary = {}

# Layers run from the outside in as [color, thickness]; the rest is the fill.
const PLATES := {
	"frame": {"layers": [["#1b0f08", 1], ["#8a5a30", 2], ["#4a2d18", 1], ["#d6a53a", 1]], "fill": "#3a2314"},
	"banner": {"layers": [["#1b0f08", 1], ["#d6a53a", 1], ["#2a0f0c", 1]], "fill": "#6a1f1d"},
	"paper": {"layers": [["#3a2416", 1], ["#c9a24a", 1]], "fill": "#f3e4bd"},
	"section": {"layers": [["#10261b", 1], ["#c9a24a", 1]], "fill": "#1f4a37"},
	"slot": {"layers": [["#1b0f08", 1], ["#8a5a30", 1]], "fill": "#3a2416"},
	"ok": {"layers": [["#7f9a62", 1], ["#eef2d0", 1]], "fill": "#dfe8c0"},
	"bad": {"layers": [["#a8574a", 1], ["#f6dcc8", 1]], "fill": "#f1cdb6"},
	"button": {"layers": [["#0d1d13", 1], ["#d6a53a", 1], ["#10261b", 1]], "fill": "#1f5a3c"},
	"button_down": {"layers": [["#0d1d13", 1], ["#b88a2e", 1], ["#10261b", 1]], "fill": "#16432c"},
	"ghost": {"layers": [["#1b0f08", 1], ["#a8723c", 1], ["#4a2d18", 1]], "fill": "#6b4526"},
	"ghost_down": {"layers": [["#1b0f08", 1], ["#8a5a30", 1], ["#4a2d18", 1]], "fill": "#4e321b"},
	"title": {"layers": [["#10261b", 1], ["#d6a53a", 2], ["#10261b", 1]], "fill": "#1f4a37"},
	"tab": {"layers": [["#1b0f08", 1], ["#6e4727", 1], ["#2a170c", 1]], "fill": "#3a2416"},
	"tab_on": {"layers": [["#1b0f08", 1], ["#f0c850", 2], ["#1b0f08", 1]], "fill": "#4a2d18"},
	"close": {"layers": [["#1b0f08", 1], ["#e8b83a", 1], ["#5a0f0f", 1]], "fill": "#c0261f"},
	"close_down": {"layers": [["#1b0f08", 1], ["#b88a2e", 1], ["#3a0808", 1]], "fill": "#8f1a15"},
	"item": {"layers": [["#c9b27a", 1], ["#f8eccb", 1]], "fill": "#f1e2bd"},
	"item_on": {"layers": [["#f0c850", 2], ["#b88a2e", 1]], "fill": "#fff1c9"},
	"danger": {"layers": [["#1b0f08", 1], ["#a8574a", 1]], "fill": "#4a1414"},
	"note": {"layers": [["#10261b", 1], ["#c9a24a", 1]], "fill": "#153a2c"},
	"paper_bg": {"layers": [["#8a5a30", 1], ["#c9a24a", 1]], "fill": "#efdcab"},
	"chip": {"layers": [["#8a5a30", 1]], "fill": "#e9d6a0"},
	"chip_on": {"layers": [["#1b0f08", 1], ["#f0c850", 1]], "fill": "#1f5a3c"},
	"dim": {"layers": [["#1b1b18", 1], ["#6a6a5e", 1], ["#2a2a26", 1]], "fill": "#4a4a40"},
	"skill_on": {"layers": [["#f0c850", 2], ["#1b0f08", 1]], "fill": "#4a2d18"},
	"skill_off": {"layers": [["#1b0f08", 1], ["#4a4a40", 1]], "fill": "#2a2a26"}
}

static func texture(id: String, scale: int = 2) -> ImageTexture:
	var key := "%s@%d" % [id, scale]
	if not _textures.has(key):
		var image := _build(id)
		if scale > 1: image.resize(image.get_width()*scale, image.get_height()*scale, Image.INTERPOLATE_NEAREST)
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]

static func plate(id: String, margin: int = 8) -> StyleBoxTexture:
	if not _plates.has(id):
		var spec: Dictionary = PLATES[id]
		var layers: Array = spec.layers
		var depth := 0
		for layer: Array in layers: depth += int(layer[1])
		var size := depth*2+4
		var image := Image.create(size,size,false,Image.FORMAT_RGBA8)
		for y in range(size):
			for x in range(size):
				var edge := mini(mini(x,size-1-x),mini(y,size-1-y))
				var color := Color(str(spec.fill))
				var walked := 0
				for layer: Array in layers:
					walked += int(layer[1])
					if edge < walked:
						color = Color(str(layer[0]))
						break
				# Chamfered outer corners keep the frame pixel-art instead of a hard box.
				if mini(x,size-1-x) == 0 and mini(y,size-1-y) == 0: color = Color.TRANSPARENT
				image.set_pixel(x,y,color)
		var style := StyleBoxTexture.new()
		style.texture = ImageTexture.create_from_image(image)
		style.texture_margin_left = depth
		style.texture_margin_right = depth
		style.texture_margin_top = depth
		style.texture_margin_bottom = depth
		_plates[id] = style
	var result: StyleBoxTexture = (_plates[id] as StyleBoxTexture).duplicate()
	result.set_content_margin_all(margin)
	return result

static func _build(id: String) -> Image:
	match id:
		"coins": return _coins()
		"xp": return _xp()
		"swords": return _swords()
		"x": return _cross()
		"crest": return _crest()
	var rows: Array = MAPS[id]
	var image := Image.create(String(rows[0]).length(),rows.size(),false,Image.FORMAT_RGBA8)
	_stamp(image,id,Vector2i.ZERO)
	return image

static func _stamp(image: Image, id: String, origin: Vector2i) -> void:
	var rows: Array = MAPS[id]
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var key := row[x]
			if key != ".": image.set_pixelv(origin+Vector2i(x,y),COLORS[key])

static func _disc(image: Image, center: Vector2i, radius: Vector2i) -> void:
	# Thick coin: a darker disc one pixel below, then the lit face on top.
	for layer in range(2):
		var shift := Vector2i(0,1-layer)
		for dy in range(-radius.y,radius.y+1):
			for dx in range(-radius.x,radius.x+1):
				var inside := pow(float(dx)/radius.x,2.0)+pow(float(dy)/radius.y,2.0) <= 1.05
				if not inside: continue
				var outer := pow(float(dx)/(radius.x-1),2.0)+pow(float(dy)/maxf(1.0,radius.y-1),2.0) > 1.05
				var color: Color = COLORS["k"] if outer else (COLORS["G"] if layer == 0 else COLORS["g"])
				if layer == 1 and not outer and dy < 0 and dx < 0: color = COLORS["h"]
				image.set_pixelv(center+Vector2i(dx,dy)+shift,color)

static func _coins() -> Image:
	var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
	_disc(image,Vector2i(5,10),Vector2i(4,3))
	_disc(image,Vector2i(10,11),Vector2i(4,3))
	_disc(image,Vector2i(8,6),Vector2i(5,3))
	return image

static func _xp() -> Image:
	var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
	for y in range(1,15):
		for x in range(1,15):
			var edge := mini(mini(x-1,14-x),mini(y-1,14-y))
			image.set_pixel(x,y,COLORS["k"] if edge == 0 else COLORS["e"] if edge == 1 else COLORS["E"])
	var glyph := ["e..e.eee", "e..e.e..e", ".ee..eee", ".ee..e", "e..e.e", "e..e.e"]
	for y in range(glyph.size()):
		var row: String = glyph[y]
		for x in range(row.length()):
			if row[x] == "e": image.set_pixel(3+x,4+y,COLORS["e"])
	return image

static func _line(image: Image, from: Vector2i, to: Vector2i, color: Color, thick: int = 1) -> void:
	var steps := maxi(absi(to.x-from.x),absi(to.y-from.y))
	for i in range(steps+1):
		var point := Vector2i(roundi(lerpf(from.x,to.x,float(i)/maxf(1.0,steps))),roundi(lerpf(from.y,to.y,float(i)/maxf(1.0,steps))))
		for dy in range(thick):
			for dx in range(thick):
				var at := point+Vector2i(dx,dy)-Vector2i(thick/2,thick/2)
				if at.x >= 0 and at.y >= 0 and at.x < image.get_width() and at.y < image.get_height(): image.set_pixelv(at,color)

static func _sword(image: Image, tip: Vector2i, hilt: Vector2i, mirror_width: int = 0) -> void:
	var a := tip
	var b := hilt
	if mirror_width > 0:
		a = Vector2i(mirror_width-1-tip.x,tip.y)
		b = Vector2i(mirror_width-1-hilt.x,hilt.y)
	var direction := Vector2(b-a).normalized()
	var side := Vector2i(roundi(-direction.y*3.0),roundi(direction.x*3.0))
	_line(image,a,b,COLORS["k"],3)
	_line(image,a+Vector2i(direction*1.0),b,COLORS["s"],1)
	_line(image,b-side,b+side,COLORS["k"],3)
	_line(image,b-side,b+side,COLORS["g"],1)
	var pommel := b+Vector2i(direction*3.0)
	_line(image,b,pommel,COLORS["N"],2)

static func _cross() -> Image:
	var image := Image.create(10,10,false,Image.FORMAT_RGBA8)
	_line(image,Vector2i(1,1),Vector2i(8,8),COLORS["w"],2)
	_line(image,Vector2i(8,1),Vector2i(1,8),COLORS["w"],2)
	return image

static func _swords() -> Image:
	var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
	_sword(image,Vector2i(2,2),Vector2i(10,10))
	_sword(image,Vector2i(2,2),Vector2i(10,10),16)
	return image

static func _crest() -> Image:
	var image := Image.create(152,26,false,Image.FORMAT_RGBA8)
	for x in range(20,133):
		var center := 9+int(pow((x-76)/56.0,2.0)*8.0)
		_line(image,Vector2i(x,center-1),Vector2i(x,center+4),COLORS["k"])
		_line(image,Vector2i(x,center),Vector2i(x,center+3),COLORS["r"] if x%9 != 0 else COLORS["R"])
	_sword(image,Vector2i(42,1),Vector2i(58,16))
	_sword(image,Vector2i(42,1),Vector2i(58,16),152)
	var rocks := [Rect2i(56,17,18,6),Rect2i(70,15,14,8),Rect2i(80,17,18,6),Rect2i(62,21,28,4)]
	for rock: Rect2i in rocks:
		image.fill_rect(rock,COLORS["P"])
		image.fill_rect(Rect2i(rock.position+Vector2i(1,1),rock.size-Vector2i(2,2)),COLORS["p"])
	_stamp(image,"skull",Vector2i(66,2))
	_stamp(image,"leaf",Vector2i(3,8))
	_stamp(image,"leaf",Vector2i(141,8))
	_stamp(image,"leaf",Vector2i(9,14))
	_stamp(image,"leaf",Vector2i(135,14))
	return image
