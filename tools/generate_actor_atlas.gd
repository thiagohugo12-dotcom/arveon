extends SceneTree

# Hand-authored 48px frames, four walk phases per actor. Source stays reproducible.
const SIZE := 48
var atlas: Image

func _initialize() -> void:
	atlas = Image.create(SIZE * 4, SIZE * 4, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for actor in range(4):
		for frame in range(4):
			var o := Vector2i(frame * SIZE, actor * SIZE)
			match actor:
				0: _adventurer(o, frame)
				1: _boar(o, frame)
				2: _spider(o, frame)
				3: _cactus(o, frame)
	var error := atlas.save_png("res://assets/art/actor_atlas.png")
	print("Actor atlas: ", error, " · 192x192")
	quit(0 if error == OK else 1)

func _p(o: Vector2i, x: int, y: int, w: int, h: int, c: String) -> void:
	atlas.fill_rect(Rect2i(o + Vector2i(x, y), Vector2i(w, h)), Color(c))

func _adventurer(o: Vector2i, f: int) -> void:
	var bob := 1 if f % 2 else 0
	var left := 2 if f == 1 else -1 if f == 3 else 0
	var right := -1 if f == 1 else 2 if f == 3 else 0
	# Separated boots, cloak hem, belt and shoulder pads define the silhouette.
	_p(o, 15 + left, 37, 8, 8, "#172922")
	_p(o, 25 + right, 37, 8, 8, "#172922")
	_p(o, 16 + left, 38, 6, 5, "#6c513a")
	_p(o, 26 + right, 38, 6, 5, "#6c513a")
	_p(o, 17 + left, 43, 7, 2, "#a28156")
	_p(o, 25 + right, 43, 7, 2, "#a28156")
	_p(o, 12, 22 + bob, 24, 17, "#172922")
	_p(o, 14, 23 + bob, 20, 14, "#2d6579")
	_p(o, 14, 30 + bob, 5, 6, "#225066")
	_p(o, 29, 30 + bob, 5, 6, "#225066")
	_p(o, 16, 34 + bob, 16, 3, "#b29860")
	_p(o, 22, 33 + bob, 4, 5, "#e5c27b")
	_p(o, 9, 22 + bob + left, 5, 13, "#ab7655")
	_p(o, 34, 22 + bob + right, 5, 13, "#ab7655")
	_p(o, 8, 20 + bob + left, 8, 5, "#1b3440")
	_p(o, 32, 20 + bob + right, 8, 5, "#1b3440")
	_p(o, 13, 9 + bob, 22, 15, "#172922")
	_p(o, 15, 13 + bob, 18, 11, "#d6a879")
	_p(o, 17, 17 + bob, 3, 2, "#24302d")
	_p(o, 28, 17 + bob, 3, 2, "#24302d")
	_p(o, 21, 21 + bob, 6, 2, "#9a684d")
	_p(o, 12, 10 + bob, 24, 6, "#493a31")
	_p(o, 16, 7 + bob, 16, 6, "#493a31")
	_p(o, 18, 9 + bob, 12, 2, "#79634c")
	_p(o, 13, 14 + bob, 3, 5, "#493a31")
	_p(o, 32, 13 + bob, 3, 5, "#493a31")
	# Short blade at the hip; actual attack is rendered by ActorView.
	_p(o, 39, 23 + bob, 3, 16, "#a6bcc0")
	_p(o, 39, 23 + bob, 2, 12, "#ecdfb6")
	_p(o, 36, 34 + bob, 9, 3, "#75583c")

func _boar(o: Vector2i, f: int) -> void:
	var bob := 1 if f % 2 else 0
	for x in [10, 31]:
		_p(o, x, 35 + (2 if (f + x) % 2 else 0), 8, 9, "#1e2825")
		_p(o, x + 1, 35, 6, 7, "#70432f")
	_p(o, 7, 18 + bob, 34, 19, "#242b27")
	_p(o, 9, 19 + bob, 30, 16, "#76402c")
	_p(o, 11, 14 + bob, 26, 12, "#9b5632")
	_p(o, 15, 13 + bob, 18, 7, "#b67543")
	_p(o, 6, 12 + bob, 10, 12, "#302e28")
	_p(o, 32, 12 + bob, 10, 12, "#302e28")
	_p(o, 9, 14 + bob, 6, 7, "#af7450")
	_p(o, 33, 14 + bob, 6, 7, "#af7450")
	_p(o, 16, 25 + bob, 16, 11, "#c38754")
	_p(o, 19, 29 + bob, 10, 6, "#5e3d34")
	for x in [12, 32]:
		_p(o, x, 25 + bob, 5, 7, "#f0d9a2")
		_p(o, x + 1, 22 + bob, 3, 3, "#f1cf73")
	_p(o, 22, 31 + bob, 4, 3, "#342e2b")

func _spider(o: Vector2i, f: int) -> void:
	for side in [-1, 1]:
		for leg in range(4):
			var x := 6 if side < 0 else 36
			var y := 19 + leg * 5 + (2 if (f + leg) % 2 else 0)
			_p(o, x, y, 7, 3, "#312b35")
			_p(o, x - 3 if side < 0 else x + 6, y + 2, 4, 6, "#785b72")
	_p(o, 12, 20, 24, 19, "#2a2932")
	_p(o, 15, 21, 18, 16, "#624969")
	_p(o, 18, 12 + f % 2, 12, 13, "#302c38")
	_p(o, 20, 14 + f % 2, 8, 9, "#8b6b8b")
	_p(o, 17, 25, 14, 3, "#9a7694")
	_p(o, 18, 31, 12, 3, "#8e7193")
	_p(o, 19, 17 + f % 2, 3, 3, "#f5cc74")
	_p(o, 26, 17 + f % 2, 3, 3, "#f5cc74")
	_p(o, 22, 22, 4, 2, "#d8b2a8")

func _cactus(o: Vector2i, f: int) -> void:
	var sway := 1 if f == 1 else -1 if f == 3 else 0
	_p(o, 14, 37, 8, 7, "#26392c")
	_p(o, 27, 37, 8, 7, "#26392c")
	_p(o, 13 + sway, 17, 22, 22, "#244a38")
	_p(o, 15 + sway, 17, 18, 20, "#509368")
	_p(o, 18 + sway, 19, 3, 17, "#81b780")
	_p(o, 29 + sway, 19, 2, 16, "#326f4b")
	_p(o, 6 + sway, 23, 9, 13, "#274936")
	_p(o, 8 + sway, 24, 6, 10, "#5ba272")
	_p(o, 33 + sway, 17, 9, 18, "#274936")
	_p(o, 34 + sway, 18, 6, 15, "#5ba272")
	_p(o, 17 + sway, 11, 15, 8, "#315e3f")
	_p(o, 20 + sway, 9, 9, 8, "#edab5e")
	_p(o, 23 + sway, 6, 3, 8, "#f6d37d")
	for x in [18, 28]:
		_p(o, x + sway, 26, 3, 3, "#1d3c32")
	_p(o, 22 + sway, 32, 5, 2, "#2a6342")
