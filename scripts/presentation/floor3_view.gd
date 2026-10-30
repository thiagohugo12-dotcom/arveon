class_name Floor3View
extends FloorView

# Pântano das Vozes montado em camadas com as peças aprovadas do pacote do Andar 3:
# chão composto por shader (máscara do mapa + amostras do tileset), pontes, ruínas,
# acampamento, santuários e vegetação ordenados pela base (o jogador passa atrás
# das copas, que ficam translúcidas enquanto ele estiver escondido).
const GROUND_SHADER := preload("res://assets/shaders/pantano_ground.gdshader")
const CHEST_VIEW := preload("res://scripts/presentation/village_chest_view.gd")
const PROPS := "res://assets/art/andar3/props/%s.png"
const TERRAIN := "res://assets/art/andar3/terrain/%s.png"
const TREES := ["arvore_grande_a", "arvore_media_a", "arvore_grande_b", "arvore_media_b", "arvore_pequena_a", "arvore_media_c", "arvore_pequena_b", "arvore_pequena_c", "arvore_anciã"]
const BUSHES := ["arbusto_a", "arbusto_b", "arbusto_flor", "arbusto_frutos", "arbusto_flor_b", "folhagem_a", "folhagem_junco", "planta_a", "planta_b", "planta_flor", "moita_a", "moita_b", "moita_flor", "raiz_a", "raiz_c"]
const REEDS := ["junco_a", "junco_b", "junco_c", "junco_d", "junco_e", "junco_agua_a", "junco_agua_b", "junco_agua_c"]
const LILIES := ["lirios_a", "lirios_b", "lirio_c", "lirio_d", "pedras_agua_a"]
const BRIDGE_ART := ["ponte_curta", "ponte_media", "ponte_longa", "ponte_muito_longa", "ponte_larga", "ponte_gasta"]

var floor3_chest: Node2D
var canopies: Array[Sprite2D] = []
var _fade_left := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_ground()
	_build_shrine()
	for span: Dictionary in Floor3Layout.bridge_spans(): _build_bridge(span)
	for structure: Dictionary in Floor3Layout.STRUCTURES:
		var piece := _prop(str(structure.art), structure.feet, -40 if structure.get("ground", false) else 0)
		# Peças altas (árvore seca, arcos, barraca) também deixam ver o jogador atrás delas.
		if not structure.get("ground", false) and piece.texture.get_height() >= 90: canopies.append(piece)
	var decor := Floor3Layout.decor()
	for at: Vector2 in decor.lilies: _prop(LILIES[_pick(at, LILIES.size())], at + Vector2(0, 10), -45)
	for at: Vector2 in decor.reeds: _prop(REEDS[_pick(at, REEDS.size())], at + Vector2(0, 8), 0)
	for at: Vector2 in decor.bushes: _prop(BUSHES[_pick(at, BUSHES.size())], at + Vector2(0, 6), 0)
	for at: Vector2 in decor.trees:
		# A árvore anciã (a maior) aparece só de vez em quando.
		var count := TREES.size() if _pick(at * 1.7, 9) == 0 else TREES.size() - 1
		canopies.append(_prop(TREES[_pick(at, count)], at + Vector2(0, 10), 0))
	for station: String in ["Ferreiro", "Vendedor"]:
		var npc := CampNpcView.new()
		npc.kind = 0 if station == "Ferreiro" else 1
		npc.visual_v2 = true
		npc.position = Floor3Layout.STATIONS[station] - Vector2(0, 21)
		npc.z_as_relative = false
		npc.z_index = roundi(Floor3Layout.STATIONS[station].y) + 100
		add_child(npc)
	floor3_chest = CHEST_VIEW.new()
	floor3_chest.position = Floor3Layout.STATIONS["Baú"] - Vector2(0, 14)
	floor3_chest.z_as_relative = false
	floor3_chest.z_index = roundi(Floor3Layout.STATIONS["Baú"].y) + 100
	add_child(floor3_chest)

func set_visual_v2(enabled: bool) -> void:
	visual_v2 = enabled

func set_expanded_world(_enabled: bool) -> void:
	pass

func set_chest_open(opened: bool) -> void:
	if is_instance_valid(floor3_chest): floor3_chest.set_open(opened)

func _draw() -> void:
	pass

static func _pick(at: Vector2, count: int) -> int:
	return absi(int(at.x) * 7919 + int(at.y) * 104729) % maxi(1, count)

func _build_ground() -> void:
	var ground := Polygon2D.new()
	var margin := 420.0
	var area := Rect2(Vector2(-margin, -margin), Floor3Layout.WORLD_SIZE + Vector2(margin, margin) * 2.0)
	ground.polygon = PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("mask_cells", Floor3Layout.MASK)
	material.set_shader_parameter("mask_soft", Floor3Layout.MASK_SOFT)
	material.set_shader_parameter("cells", Vector2(Floor3Layout.grid_size()))
	material.set_shader_parameter("cell_size", Floor3Layout.CELL)
	material.set_shader_parameter("grass_a", load(TERRAIN % "grama_a"))
	material.set_shader_parameter("grass_b", load(TERRAIN % "grama_b"))
	material.set_shader_parameter("water", load(TERRAIN % "agua"))
	material.set_shader_parameter("dirt", load(TERRAIN % "terra"))
	material.set_shader_parameter("bank", load(TERRAIN % "barranco"))
	ground.material = material
	ground.z_as_relative = false
	ground.z_index = -60
	add_child(ground)

# Piso do santuário lunar do Coração do Brejo: lajes aprovadas em grade irregular
# e o círculo lunar no centro da arena do Guardião.
func _build_shrine() -> void:
	var floor_area := Floor3Layout.SHRINE_FLOOR
	var slabs := ["laje_a", "laje_d", "laje_f", "laje_b", "laje_c", "laje_e"]
	var y := floor_area.position.y
	var row := 0
	while y < floor_area.end.y:
		var x := floor_area.position.x - (20.0 if row % 2 == 1 else 0.0)
		var column := 0
		while x < floor_area.end.x:
			var slab := _prop(slabs[(row * 3 + column) % slabs.size()], Vector2(x + 24.0, y + 46.0), -52)
			slab.flip_h = (row + column) % 3 == 0
			x += 44.0
			column += 1
		y += 40.0
		row += 1
	var circle_size := (load(PROPS % "circulo_lunar") as Texture2D).get_size()
	_prop("circulo_lunar", Floor3Layout.GUARDIAN_ALTAR + Vector2(0, circle_size.y * 0.5), -50)

# Peça com os pés no ponto dado. `layer` 0 ordena pela base; negativo fica no chão.
func _prop(art: String, feet: Vector2, layer: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(PROPS % art) as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-floorf(sprite.texture.get_width() * 0.5), -sprite.texture.get_height())
	sprite.position = feet.round()
	if absi(int(feet.x * 13.0 + feet.y)) % 2 == 1 and layer == 0 and not art.begins_with("pilar") and not art.begins_with("arco") and not art.begins_with("braseiro") and not art.begins_with("barraca"):
		sprite.flip_h = true
	sprite.z_as_relative = false
	sprite.z_index = layer if layer < 0 else roundi(feet.y) + 100
	add_child(sprite)
	return sprite

# Ponte: a peça aprovada de proporção mais próxima ao vão, em escala uniforme; as de
# travessia leste-oeste são giradas. Fica no chão, sob os personagens.
func _build_bridge(span: Dictionary) -> void:
	var length: float = span.length
	var best := ""
	var best_error := INF
	for art: String in BRIDGE_ART:
		var texture := load(PROPS % art) as Texture2D
		var scaled_width := texture.get_width() * length / texture.get_height()
		var error := absf(scaled_width - 74.0)
		if error < best_error:
			best_error = error
			best = art
	var sprite := Sprite2D.new()
	sprite.texture = load(PROPS % best) as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = (span.center as Vector2).round()
	var factor := length / sprite.texture.get_height()
	sprite.scale = Vector2(factor, factor)
	if span.axis == "h": sprite.rotation = -PI * 0.5
	sprite.z_as_relative = false
	sprite.z_index = -30
	add_child(sprite)

func _process(delta: float) -> void:
	_fade_left -= delta
	if _fade_left > 0.0: return
	_fade_left = 0.12
	var main := get_tree().current_scene
	var player := main.get_node_or_null("Player") as Node2D if main != null else null
	if player == null: return
	var at := player.global_position
	for sprite: Sprite2D in canopies:
		var feet := sprite.position
		var hidden := at.y < feet.y - 6.0 and at.y > feet.y - sprite.texture.get_height() + 10.0 and absf(at.x - feet.x) < sprite.texture.get_width() * 0.42
		var target := 0.55 if hidden else 1.0
		if not is_equal_approx(sprite.modulate.a, target): sprite.modulate.a = target
