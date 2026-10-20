extends SceneTree

# Provisional, code-native launcher mark. The official ARVÉON symbol awaits art approval.
const SIZE := 72
const INK := Color("#133c31")
const GOLD := Color("#e8c66c")
const CREAM := Color("#fff0bc")
const LEAF := Color("#91b758")
const LETTER := ["00100", "01010", "10001", "10001", "11111", "10001", "10001"]

func _initialize() -> void:
	var main := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	main.fill(INK)
	main.fill_rect(Rect2i(4, 4, 64, 64), GOLD)
	main.fill_rect(Rect2i(7, 7, 58, 58), INK)
	_draw_mark(main)
	_save(main, "res://assets/branding/alpha02-icon-proposal.png")
	var foreground := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	foreground.fill(Color.TRANSPARENT)
	_draw_mark(foreground)
	_save(foreground, "res://assets/branding/alpha02-icon-foreground.png")
	var background := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	background.fill(INK)
	_save(background, "res://assets/branding/alpha02-icon-background.png")
	quit()

func _draw_mark(image: Image) -> void:
	image.fill_rect(Rect2i(34, 10, 4, 4), LEAF)
	image.fill_rect(Rect2i(30, 14, 4, 4), LEAF)
	image.fill_rect(Rect2i(38, 14, 4, 4), LEAF)
	for y in range(LETTER.size()):
		for x in range(5):
			if LETTER[y][x] == "1":
				image.fill_rect(Rect2i(19 + x * 7, 22 + y * 6, 6, 5), GOLD)
	image.fill_rect(Rect2i(17, 61, 38, 2), CREAM)

func _save(image: Image, path: String) -> void:
	image.resize(432, 432, Image.INTERPOLATE_NEAREST)
	image.save_png(ProjectSettings.globalize_path(path))
