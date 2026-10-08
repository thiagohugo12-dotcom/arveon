extends SceneTree

# Small source atlas; generated deterministically and committed with this script.
const TILE := 32
var atlas: Image

func _initialize() -> void:
	atlas = Image.create(256, 128, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for variant in range(4):
		_ground(Vector2i(variant * TILE, 0), variant)
	for variant in range(3):
		_tree(Vector2i(variant * 64, 64), variant)
	var path := "res://assets/art/forest_atlas.png"
	var error := atlas.save_png(path)
	print("Forest atlas: ", error, " · 256x128")
	quit(0 if error == OK else 1)

func _rect(origin: Vector2i, x: int, y: int, w: int, h: int, color: String) -> void:
	atlas.fill_rect(Rect2i(origin + Vector2i(x, y), Vector2i(w, h)), Color(color))

func _ground(o: Vector2i, v: int) -> void:
	# Shared base means no visible grid seam between tile variants.
	_rect(o, 0, 0, 32, 32, "#294c37")
	var rng := RandomNumberGenerator.new()
	rng.seed = 30320 + v * 16231
	for i in range(13):
		var x := rng.randi_range(2, 29)
		var y := rng.randi_range(2, 29)
		_rect(o, x, y, rng.randi_range(2, 5), 2, ["#315a3e", "#355e40", "#254533"][i % 3])
	for i in range(4):
		var x := rng.randi_range(3, 28)
		var y := rng.randi_range(4, 27)
		_rect(o, x, y - 2, 2, 5, "#417347")
		_rect(o, x - 2, y - 1, 2, 3, "#366242")
		_rect(o, x + 2, y, 2, 3, "#366242")
	if v == 1:
		_rect(o, 18, 13, 2, 3, "#bbc884")
		_rect(o, 16, 14, 6, 1, "#ecdf9a")
		_rect(o, 19, 14, 1, 1, "#e8a76a")
	if v == 2:
		_rect(o, 7, 22, 6, 3, "#384b3e")
		_rect(o, 8, 21, 3, 2, "#728577")
		_rect(o, 23, 6, 3, 2, "#a5754d")
	if v == 3:
		for p in [Vector2i(7, 6), Vector2i(15, 23), Vector2i(26, 13)]:
			_rect(o, p.x, p.y, 4, 2, "#6f583b")
			_rect(o, p.x + 1, p.y + 2, 2, 2, "#435c3a")

func _tree(o: Vector2i, v: int) -> void:
	# Ground shadow + bark remain legible under the canopy.
	_rect(o, 10, 52, 44, 5, "#162f29")
	_rect(o, 17, 57, 32, 2, "#1d392d")
	_rect(o, 27, 34, 11, 22, "#49392f")
	_rect(o, 30, 35, 5, 20, "#795639")
	_rect(o, 32, 39, 2, 12, "#a07445")
	_rect(o, 25, 52, 5, 5, "#4c3b2f")
	_rect(o, 36, 52, 5, 5, "#4c3b2f")
	var lobes: Array = [
		[[18, 25, 11, 11], [43, 23, 11, 11], [30, 15, 16, 13], [31, 27, 18, 12]],
		[[18, 23, 12, 12], [46, 21, 10, 13], [31, 13, 17, 12], [32, 29, 19, 13]],
		[[23, 27, 11, 11], [41, 25, 10, 12], [31, 13, 12, 13], [32, 30, 16, 11]]
	][v]
	for lobe: Array in lobes:
		_canopy_lobe(o, Vector2i(lobe[0], lobe[1]), lobe[2], lobe[3], v)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8900 + v * 313
	for i in range(38):
		var x := rng.randi_range(16, 47)
		var y := rng.randi_range(11, 34)
		if atlas.get_pixelv(o + Vector2i(x, y)).a > 0.0:
			_rect(o, x, y, rng.randi_range(2, 4), 2, "#5e9153" if i % 3 else "#80a65c")
	for p in [Vector2i(23, 18), Vector2i(39, 25), Vector2i(29, 11)]:
		_rect(o, p.x, p.y, 2, 2, "#c3ad68" if v == 1 else "#7fab63")

func _canopy_lobe(o: Vector2i, c: Vector2i, rx: int, ry: int, v: int) -> void:
	for dy in range(-ry, ry + 1, 2):
		var span := floori(rx * sqrt(maxf(0.0, 1.0 - pow(float(dy) / ry, 2))))
		if span < 2:
			continue
		_rect(o, c.x - span, c.y + dy, span * 2, 2, "#18392e")
		if absi(dy) < ry - 2:
			_rect(o, c.x - span + 2, c.y + dy, span * 2 - 4, 2, "#315e3e" if v != 1 else "#3a6346")
		if dy < -2 and span > 6:
			_rect(o, c.x - span + 4, c.y + dy, span - 5, 2, "#47754a" if v != 1 else "#4a7652")
