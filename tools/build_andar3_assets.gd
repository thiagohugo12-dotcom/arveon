extends SceneTree

# Gera os recursos derivados do Andar 3 a partir das folhas ORIGINAIS aprovadas em
# art_source/andar3 (que nunca são alteradas). Cada peça é recortada pelos pixels
# conectados da própria peça (sem presumir grade), perde o resíduo verde da borda,
# mantém transparência real, é reduzida com filtro de alta qualidade para a escala do
# mundo e recebe alfa nítido para ser mostrada com filtro "nearest".
# Os quadros do Limo do Brejo são alinhados pela base do corpo (mesmo ponto em todos).
# Uso: godot --headless --path . -s res://tools/build_andar3_assets.gd
const SRC := "res://art_source/andar3/"
const OUT := "res://assets/art/andar3/"

# nome: [folha, retângulo na folha, largura final em pixels do mundo]
const PROPS := {
	# Árvores, arbustos, juncos e raízes (02).
	"arvore_grande_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(16, 16, 380, 360), 200],
	"arvore_media_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(408, 32, 284, 356), 150],
	"arvore_grande_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(688, 20, 332, 376), 176],
	"arvore_media_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1028, 80, 268, 308), 140],
	"arvore_pequena_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1304, 108, 220, 268), 116],
	"arvore_anciã": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(28, 376, 444, 360), 262],
	"arvore_seca": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(504, 400, 284, 332), 160],
	"arvore_media_c": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(800, 432, 256, 284), 136],
	"arvore_pequena_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1076, 452, 220, 256), 120],
	"arvore_pequena_c": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1312, 416, 208, 284), 116],
	"arbusto_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(16, 732, 140, 128), 58],
	"arbusto_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(164, 768, 96, 96), 40],
	"arbusto_flor": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(272, 756, 116, 104), 46],
	"arbusto_frutos": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(400, 756, 104, 108), 42],
	"arbusto_flor_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(512, 740, 140, 120), 56],
	"folhagem_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(664, 740, 140, 124), 54],
	"folhagem_junco": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(816, 736, 140, 120), 54],
	"junco_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(992, 712, 144, 168), 56],
	"junco_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1152, 728, 140, 160), 54],
	"junco_c": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1312, 720, 116, 172), 46],
	"junco_d": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1440, 728, 72, 88), 28],
	"junco_e": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1448, 828, 60, 80), 24],
	"raiz_arco": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(16, 868, 208, 128), 92],
	"raiz_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(240, 876, 124, 124), 54],
	"raiz_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(372, 880, 160, 116), 70],
	"raiz_c": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(544, 872, 148, 128), 64],
	"tronco_caido": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(700, 884, 176, 112), 80],
	"planta_a": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(884, 888, 92, 104), 34],
	"planta_b": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1072, 908, 84, 88), 32],
	"planta_flor": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1176, 904, 104, 96), 38],
	"planta_c": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1360, 912, 80, 84), 30],
	"planta_d": ["02_ARVORES_ARBUSTOS_RAIZES.png", Rect2i(1452, 920, 64, 76), 26],
	# Pontes, ruínas, acampamento e santuário (03).
	"ponte_curta": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(28, 76, 116, 112), 58],
	"ponte_media": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(172, 52, 128, 144), 64],
	"ponte_longa": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(324, 16, 124, 188), 62],
	"ponte_muito_longa": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(480, 8, 132, 256), 66],
	"ponte_larga": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(652, 24, 156, 180), 78],
	"ponte_gasta": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(844, 16, 140, 192), 70],
	"pilar_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(24, 224, 76, 180), 36],
	"arco_quebrado": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(116, 232, 120, 160), 58],
	"pilar_lua_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(256, 236, 64, 172), 30],
	"pilar_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(332, 256, 96, 148), 46],
	"pilar_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(444, 280, 76, 132), 36],
	"muro_pilar": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(532, 256, 152, 140), 74],
	"arco_grande": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(704, 224, 244, 180), 120],
	"pilar_d": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(968, 240, 80, 160), 38],
	"pilar_e": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1052, 264, 84, 140), 40],
	"pilar_lua_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1160, 232, 80, 176), 38],
	"pilar_f": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1252, 280, 72, 132), 34],
	"pilar_lua_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1344, 248, 76, 176), 36],
	"placa_madeira": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1440, 296, 76, 136), 36],
	"muro_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(16, 392, 144, 136), 70],
	"muro_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(180, 416, 196, 112), 96],
	"muro_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(392, 416, 136, 108), 66],
	"arco_baixo": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(540, 388, 144, 140), 70],
	"muro_d": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(696, 400, 168, 120), 82],
	"muro_e": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(888, 412, 108, 112), 52],
	"pedras_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1016, 420, 92, 92), 44],
	"pedras_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1132, 444, 104, 68), 50],
	"pedras_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1256, 436, 72, 92), 34],
	"pedras_d": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1344, 460, 64, 68), 30],
	"pedras_e": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1424, 480, 72, 56), 34],
	"barraca": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(16, 524, 288, 200), 150],
	"lanterna_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(320, 536, 84, 132), 40],
	"fogueira": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(436, 536, 124, 124), 60],
	"lanterna_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(576, 540, 84, 120), 40],
	"estandarte": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(690, 536, 84, 136), 38],
	"poste_cipo": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(792, 532, 72, 136), 34],
	"placa_dupla": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(880, 540, 80, 136), 38],
	"tronco_oco": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1000, 532, 144, 120), 70],
	"barril": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(268, 632, 52, 64), 24],
	"toco_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(424, 668, 40, 48), 20],
	"toco_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(548, 660, 36, 48), 18],
	"pedras_musgo": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(948, 664, 72, 60), 34],
	"tronco_oco_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1028, 640, 96, 80), 46],
	"toco_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1136, 604, 56, 72), 26],
	"toco_d": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1192, 580, 76, 128), 36],
	"toco_e": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1276, 584, 76, 108), 36],
	"toco_f": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1440, 576, 76, 112), 36],
	"anel_pedras": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(472, 684, 76, 56), 36],
	"laje_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(32, 744, 76, 72), 48],
	"laje_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(120, 740, 60, 76), 38],
	"laje_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(192, 740, 64, 76), 40],
	"laje_d": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(32, 824, 76, 64), 48],
	"laje_e": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(32, 900, 64, 84), 40],
	"laje_f": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(108, 900, 80, 84), 50],
	"circulo_lunar": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(292, 798, 124, 124), 104],
	"braseiro_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1024, 732, 76, 116), 38],
	"braseiro_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1024, 856, 64, 132), 32],
	"braseiro_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1108, 864, 60, 128), 30],
	"pilar_santuario_a": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1116, 720, 80, 132), 40],
	"pilar_santuario_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1208, 756, 52, 100), 26],
	"ruina_santuario": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1272, 736, 92, 108), 46],
	"pilar_lua_santuario": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1384, 708, 60, 156), 30],
	"pilar_santuario_c": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1464, 740, 52, 124), 26],
	"portal_santuario": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1256, 872, 108, 128), 54],
	"ruina_santuario_b": ["03_PONTES_RUINAS_ACAMPAMENTO_SANTUARIO.png", Rect2i(1380, 868, 132, 136), 66],
	# Flora aquática, poças e pedras do tileset (01).
	"lirios_a": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(264, 932, 76, 60), 34],
	"lirios_b": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(416, 956, 60, 52), 28],
	"lirio_c": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(492, 956, 44, 44), 20],
	"lirio_d": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(356, 964, 44, 40), 20],
	"pedras_agua_a": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(16, 924, 72, 72), 34],
	"pedras_agua_b": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(164, 936, 92, 68), 42],
	"poca_agua": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(152, 840, 128, 80), 84],
	"poca_lama": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(300, 848, 100, 72), 66],
	"junco_agua_a": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(920, 812, 92, 108), 40],
	"junco_agua_b": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(1032, 808, 68, 112), 30],
	"junco_agua_c": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(1112, 804, 76, 116), 34],
	"moita_a": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(496, 844, 96, 68), 42],
	"moita_b": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(616, 848, 84, 64), 38],
	"moita_flor": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(720, 848, 84, 68), 38],
	"moita_c": ["01_TERRENO_AGUA_REFINADO.png", Rect2i(828, 848, 76, 64), 34]}

# Inimigos estáticos aprovados (03_INIMIGOS): largura final em pixels do mundo.
const MONSTERS := {
	"sapo_venenoso": ["04_LIMO_SAPO_VULTO.png", Rect2i(720, 180, 672, 484), 84],
	"vulto_do_brejo": ["04_LIMO_SAPO_VULTO.png", Rect2i(1444, 8, 592, 660), 72],
	"limo_do_brejo": ["04_LIMO_SAPO_VULTO.png", Rect2i(28, 136, 632, 492), 52],
	"jacare_anciao": ["05_JACARE_ANCIAO.png", Rect2i(0, 0, 1536, 1024), 236],
	"mae_dos_sussurros_fase1": ["06_MAE_DOS_SUSSURROS_FASE_1.png", Rect2i(0, 0, 1536, 1024), 300],
	"mae_dos_sussurros_fase2": ["07_MAE_DOS_SUSSURROS_FASE_2.png", Rect2i(0, 0, 1448, 1086), 300]}

# Amostras de textura contínua do tileset aprovado (01): [retângulo, contínua (1) ou faixa (0)], 1:1.
const TERRAIN := {
	"grama_a": [Rect2i(34, 14, 60, 60), 1],
	"grama_b": [Rect2i(16, 140, 50, 50), 1],
	"terra": [Rect2i(172, 318, 44, 44), 1],
	"agua": [Rect2i(708, 586, 48, 48), 1],
	"lama": [Rect2i(538, 150, 88, 88), 1],
	"barranco": [Rect2i(150, 774, 64, 24), 0]}

const LIMO_BODY_WIDTH := 52.0

var meta := {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for folder in ["props", "monsters", "terrain", "derived"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + folder))
	var sheets := {}
	for name: String in PROPS:
		var entry: Array = PROPS[name]
		var sprite := _piece(_sheet(sheets, entry[0]), entry[1], float(entry[2]))
		sprite.save_png(OUT + "props/%s.png" % name)
		meta[name] = {"size": [sprite.get_width(), sprite.get_height()]}
	for name: String in MONSTERS:
		var entry: Array = MONSTERS[name]
		var sprite := _piece(_sheet(sheets, entry[0]), entry[1], float(entry[2]))
		sprite.save_png(OUT + "monsters/%s.png" % name)
		meta[name] = {"size": [sprite.get_width(), sprite.get_height()]}
	var tileset: Image = _sheet(sheets, "01_TERRENO_AGUA_REFINADO.png")
	for name: String in TERRAIN:
		var entry: Array = TERRAIN[name]
		var swatch := tileset.get_region(entry[0])
		swatch.convert(Image.FORMAT_RGBA8)
		if int(entry[1]) > 0: swatch = _seamless(swatch)
		_opaque(swatch)
		swatch.save_png(OUT + "terrain/%s.png" % name)
	_limo("idle", _sheet(sheets, "08_LIMO_IDLE_4_QUADROS.png"), 4)
	_limo("ataque", _sheet(sheets, "09_LIMO_ATAQUE_6_QUADROS.png"), 6)
	var file := FileAccess.open(OUT + "derived/andar3_assets.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t", true))
	file.close()
	print("ANDAR3_ASSETS props=%d monsters=%d" % [PROPS.size(), MONSTERS.size()])
	quit(0)

func _sheet(cache: Dictionary, name: String) -> Image:
	if not cache.has(name):
		var image := Image.load_from_file(SRC + name)
		image.convert(Image.FORMAT_RGBA8)
		cache[name] = image
	return cache[name]

# Peça = maior componente opaco do retângulo + componentes vizinhos relevantes
# (folhas, pingos), sem pegar pedaços de peças vizinhas que invadem o retângulo.
func _piece(sheet: Image, area: Rect2i, width: float) -> Image:
	var crop := sheet.get_region(area.grow(6).intersection(Rect2i(Vector2i.ZERO, sheet.get_size())))
	var keep := _main_components(crop, 0.02)
	_clean(crop, keep)
	var box := _bounds(crop)
	if box.size.x <= 0: return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var piece := crop.get_region(box)
	return _downscale(piece, width / float(piece.get_width()))

func _main_components(image: Image, min_share: float) -> PackedByteArray:
	var w := image.get_width()
	var h := image.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var sizes: Array = []
	for start in range(w * h):
		if label[start] >= 0 or image.get_pixel(start % w, start / w).a < 0.5: continue
		var id := sizes.size()
		var stack := [start]
		label[start] = id
		var count := 0
		while not stack.is_empty():
			var current: int = stack.pop_back()
			count += 1
			var cx := current % w
			var cy := current / w
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var nx := cx + dx
					var ny := cy + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
					var next := ny * w + nx
					if label[next] < 0 and image.get_pixel(nx, ny).a >= 0.5:
						label[next] = id
						stack.append(next)
		sizes.append(count)
	var largest := 0
	for size: int in sizes: largest = maxi(largest, size)
	# Peças que tocam a borda do recorte (vizinhas invadindo) só ficam se forem a principal.
	var touches := {}
	for x in range(w):
		for y in [0, h - 1]:
			if label[y * w + x] >= 0: touches[label[y * w + x]] = true
	for y in range(h):
		for x in [0, w - 1]:
			if label[y * w + x] >= 0: touches[label[y * w + x]] = true
	var keep := PackedByteArray()
	keep.resize(w * h)
	for i in range(w * h):
		var id := label[i]
		if id < 0: continue
		var size: int = sizes[id]
		if size == largest or (size >= largest * min_share and not touches.has(id)): keep[i] = 1
	return keep

# Remove fundo, pixels fora das peças mantidas e o halo verde neon da geração.
func _clean(image: Image, keep: PackedByteArray) -> void:
	var w := image.get_width()
	for y in range(image.get_height()):
		for x in range(w):
			var c := image.get_pixel(x, y)
			if keep[y * w + x] == 0 or c.a < 0.5:
				image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
				continue
			if c.g > 0.72 and c.r < 0.5 and c.b < 0.38 and c.g - c.r > 0.35:
				var border := false
				for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
					var at := Vector2i(x, y) + offset
					if at.x < 0 or at.y < 0 or at.x >= w or at.y >= image.get_height() or image.get_pixelv(at).a < 0.5 or keep[at.y * w + at.x] == 0:
						border = true
						break
				if border:
					image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
					continue
			image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))

func _bounds(image: Image) -> Rect2i:
	var min_p := Vector2i(image.get_width(), image.get_height())
	var max_p := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.0:
				min_p = Vector2i(mini(min_p.x, x), mini(min_p.y, y))
				max_p = Vector2i(maxi(max_p.x, x), maxi(max_p.y, y))
	return Rect2i(min_p, max_p - min_p + Vector2i.ONE) if max_p.x >= 0 else Rect2i()

# Redução com Lanczos: as cores invadem o fundo antes (sem borda escura) e o alfa
# final é binário, para o pixel art continuar nítido com filtro "nearest".
func _downscale(image: Image, factor: float) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var colors := PackedColorArray()
	colors.resize(w * h)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for i in range(w * h):
		var c := image.get_pixel(i % w, i / w)
		colors[i] = c
		solid[i] = 1 if c.a > 0.0 else 0
	for _pass in range(4):
		var next := colors.duplicate()
		var next_solid := solid.duplicate()
		for y in range(h):
			for x in range(w):
				var i := y * w + x
				if solid[i] == 1: continue
				var sum := Color(0, 0, 0, 0)
				var count := 0
				for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + offset.x
					var ny := y + offset.y
					if nx >= 0 and ny >= 0 and nx < w and ny < h and solid[ny * w + nx] == 1:
						sum += colors[ny * w + nx]
						count += 1
				if count > 0:
					next[i] = sum / float(count)
					next_solid[i] = 1
		colors = next
		solid = next_solid
	var color_image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var alpha_image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for i in range(w * h):
		var c := colors[i]
		color_image.set_pixel(i % w, i / w, Color(c.r, c.g, c.b, 1.0))
		var a := image.get_pixel(i % w, i / w).a
		alpha_image.set_pixel(i % w, i / w, Color(a, a, a, 1.0))
	var tw := maxi(1, roundi(w * factor))
	var th := maxi(1, roundi(h * factor))
	color_image.resize(tw, th, Image.INTERPOLATE_LANCZOS)
	alpha_image.resize(tw, th, Image.INTERPOLATE_BILINEAR)
	var out := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	for y in range(th):
		for x in range(tw):
			var c := color_image.get_pixel(x, y)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 if alpha_image.get_pixel(x, y).r >= 0.5 else 0.0))
	return out

# Textura contínua: as bordas opostas se misturam para repetir sem emenda visível.
func _seamless(image: Image) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var out := image.duplicate() as Image
	var band := maxi(4, w / 4)
	for y in range(h):
		for x in range(w):
			var c := image.get_pixel(x, y)
			if x < band:
				var t := 0.5 - 0.5 * float(x) / band
				c = c.lerp(image.get_pixel(w - 1 - (band - 1 - x), y), t)
			if y < band:
				var t := 0.5 - 0.5 * float(y) / band
				c = c.lerp(image.get_pixel(x, h - 1 - (band - 1 - y)), t)
			out.set_pixel(x, y, c)
	for y in range(h):
		for x in range(w):
			var c := out.get_pixel(x, y)
			if x >= w - band:
				var t := 0.5 - 0.5 * float(w - 1 - x) / band
				c = c.lerp(out.get_pixel(band - 1 - (w - 1 - x), y), t)
			if y >= h - band:
				var t := 0.5 - 0.5 * float(h - 1 - y) / band
				c = c.lerp(out.get_pixel(x, band - 1 - (h - 1 - y)), t)
			out.set_pixel(x, y, c)
	return out

func _opaque(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))

# Quadros do Limo: separa por componentes (pingos soltos vão para o quadro mais
# próximo), mantém a ordem original da esquerda para a direita e alinha todos pela
# base do corpo e pelo centro do domo (a parte de cima, que não muda com o golpe).
func _limo(name: String, sheet: Image, frames: int) -> void:
	var w := sheet.get_width()
	var h := sheet.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var parts: Array = []
	for start in range(w * h):
		if label[start] >= 0 or sheet.get_pixel(start % w, start / w).a < 0.5: continue
		var id := parts.size()
		var stack := [start]
		label[start] = id
		var count := 0
		var sum_x := 0.0
		var min_x := w
		var max_x := 0
		while not stack.is_empty():
			var current: int = stack.pop_back()
			var cx := current % w
			var cy := current / w
			count += 1
			sum_x += cx
			min_x = mini(min_x, cx)
			max_x = maxi(max_x, cx)
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				var nx := cx + offset.x
				var ny := cy + offset.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h: continue
				var next := ny * w + nx
				if label[next] < 0 and sheet.get_pixel(nx, ny).a >= 0.5:
					label[next] = id
					stack.append(next)
		parts.append({"id": id, "count": count, "cx": sum_x / count, "min_x": min_x, "max_x": max_x})
	parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.count) > int(b.count))
	var bodies: Array = parts.slice(0, frames)
	bodies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.cx) < float(b.cx))
	var owner := {}
	for index in range(bodies.size()): owner[int(bodies[index].id)] = index
	for part: Dictionary in parts.slice(frames):
		if int(part.count) < 12: continue
		var best := 0
		var best_distance := INF
		for index in range(bodies.size()):
			var body: Dictionary = bodies[index]
			var distance := 0.0 if float(part.cx) >= float(body.min_x) and float(part.cx) <= float(body.max_x) else minf(absf(float(part.cx) - float(body.min_x)), absf(float(part.cx) - float(body.max_x)))
			if distance < best_distance:
				best_distance = distance
				best = index
		owner[int(part.id)] = best
	var images: Array = []
	for index in range(frames):
		var frame := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for i in range(w * h):
			if label[i] >= 0 and owner.get(label[i], -1) == index:
				var c := sheet.get_pixel(i % w, i / w)
				frame.set_pixel(i % w, i / w, Color(c.r, c.g, c.b, 1.0))
		var box := _bounds(frame)
		images.append({"image": frame.get_region(box), "box": box})
	# Escala única por folha: o quadro de repouso (primeiro) tem a largura do corpo.
	var factor := LIMO_BODY_WIDTH / float((images[0].image as Image).get_width())
	var anchors: Array = []
	var scaled: Array = []
	for entry: Dictionary in images:
		var small := _downscale(entry.image, factor)
		scaled.append(small)
		anchors.append(_anchor(small))
	var left := 0
	var right := 0
	var up := 0
	for index in range(scaled.size()):
		var image: Image = scaled[index]
		var anchor: Vector2i = anchors[index]
		left = maxi(left, anchor.x)
		right = maxi(right, image.get_width() - anchor.x)
		up = maxi(up, anchor.y)
	var down := 0
	for index in range(scaled.size()):
		down = maxi(down, (scaled[index] as Image).get_height() - (anchors[index] as Vector2i).y)
	var cell := Vector2i(left + right + 2, up + down + 2)
	var strip := Image.create(cell.x * frames, cell.y, false, Image.FORMAT_RGBA8)
	for index in range(frames):
		var image: Image = scaled[index]
		var anchor: Vector2i = anchors[index]
		strip.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(index * cell.x + 1 + left - anchor.x, 1 + up - anchor.y))
	strip.save_png(OUT + "monsters/limo_%s.png" % name)
	meta["limo_" + name] = {"frames": frames, "cell": [cell.x, cell.y], "anchor": [1 + left, 1 + up]}

# Âncora = (centro do domo, linha da base). O domo é o terço de cima do corpo; a base
# é a última linha larga (ignora pingos soltos embaixo).
func _anchor(image: Image) -> Vector2i:
	var w := image.get_width()
	var h := image.get_height()
	var widths := PackedInt32Array()
	widths.resize(h)
	var widest := 0
	for y in range(h):
		var count := 0
		for x in range(w):
			if image.get_pixel(x, y).a > 0.0: count += 1
		widths[y] = count
		widest = maxi(widest, count)
	var top := 0
	while top < h and widths[top] == 0: top += 1
	var base := h - 1
	while base > top and widths[base] < widest * 0.3: base -= 1
	var sum := 0.0
	var count := 0
	for y in range(top, top + maxi(1, (base - top) / 3)):
		for x in range(w):
			if image.get_pixel(x, y).a > 0.0:
				sum += x
				count += 1
	return Vector2i(roundi(sum / maxf(1.0, count)), base)
