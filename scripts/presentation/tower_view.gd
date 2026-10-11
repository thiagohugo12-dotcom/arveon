class_name TowerView
extends Node2D

var visual_v2 := false
var unlocked := false
var nearby := false

func _ready() -> void:
	position = TowerEntrance.POSITION
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_state(available: bool, close: bool) -> void:
	if available != unlocked or close != nearby:
		unlocked = available
		nearby = close
		queue_redraw()

func _draw() -> void:
	if visual_v2:
		_draw_v2()
		return

func _draw_v2() -> void:
	# Broad, quiet shapes keep the landmark readable at phone scale.
	var outline := Color("#35473f")
	var stone_dark := Color("#53665a")
	var stone := Color("#75806a")
	var stone_light := Color("#a7aa8b")
	var moss := Color("#71834d")
	var portal := Color("#3fc59f") if unlocked else Color("#253f39")
	var portal_light := Color("#a7ecc2") if unlocked else Color("#415b50")

	# One soft footprint and three generous steps anchor the structure to the path.
	draw_rect(Rect2(-46,2,92,12),Color("#94ad50"))
	draw_rect(Rect2(-38,-5,76,8),outline)
	draw_rect(Rect2(-34,-9,68,7),stone_dark)
	draw_rect(Rect2(-28,-13,56,6),stone)

	# The portal glow stays contained inside the arch.
	if unlocked:
		draw_rect(Rect2(-23,-65,46,56),Color("#52d2ad26"))
		draw_rect(Rect2(-19,-61,38,52),Color("#52d2ad38"))

	# Two simple pillars and a stepped lintel create a strong landmark silhouette.
	for side in [-1,1]:
		var x: float = 20.0 * side - (16.0 if side < 0 else 0.0)
		draw_rect(Rect2(x,-64,16,55),outline)
		draw_rect(Rect2(x+3,-61,10,49),stone)
		draw_rect(Rect2(x+3,-59,3,43),stone_light)
	draw_rect(Rect2(-40,-76,80,15),outline)
	draw_rect(Rect2(-35,-80,70,15),stone_dark)
	draw_rect(Rect2(-28,-85,56,12),stone)
	draw_rect(Rect2(-20,-88,40,6),stone_light)

	# A dark inner frame makes the portal readable in both locked states.
	draw_rect(Rect2(-20,-64,40,55),outline)
	draw_rect(Rect2(-15,-59,30,50),portal)
	draw_rect(Rect2(-10,-55,20,42),portal.darkened(0.16))
	if unlocked:
		draw_rect(Rect2(-7,-51,5,34),portal_light)
		draw_rect(Rect2(2,-45,5,25),portal_light)
		draw_rect(Rect2(-5,-18,10,4),Color("#d4f4cf"))
	else:
		# One warm seal communicates that the entrance is closed.
		draw_rect(Rect2(-5,-37,10,12),Color("#6e583a"))
		draw_rect(Rect2(-3,-39,6,7),Color("#d5ad61"))
		draw_rect(Rect2(-1,-34,2,5),Color("#f0cf7b"))

	# A single crest and two moss blocks add identity without surface noise.
	draw_rect(Rect2(-8,-77,16,4),outline)
	draw_rect(Rect2(-3,-81,6,8),portal_light if unlocked else Color("#b79555"))
	draw_rect(Rect2(-34,-58,7,5),moss)
	draw_rect(Rect2(27,-28,7,5),moss)
	if nearby:
		draw_rect(Rect2(-5,8,10,4),portal_light)
		draw_rect(Rect2(-2,5,4,3),portal_light)

	# Static geometry in the existing forest palette. No textures, particles,
	# per-frame animation or new gameplay effects.
	draw_rect(Rect2(-40, -5, 80, 18), Color("#819255"))
	draw_rect(Rect2(-38, -78, 76, 65), Color("#4b6254"))
	draw_rect(Rect2(-32, -74, 64, 59), Color("#939b83"))
	draw_rect(Rect2(-32,-74,64,7),Color("#bfc0a3"))
	for y in [-56,-28]:
		draw_rect(Rect2(-30,y,60,2),Color("#7e8971"))
	for x in [-34, -12, 10, 26]:
		draw_rect(Rect2(x, -87, 12, 13), Color("#b1b79a"))
	draw_rect(Rect2(-16, -49, 32, 42), Color("#26382e"))
	draw_rect(Rect2(-20, -53, 40, 5), Color("#ab9d6d"))
	for x in [-20, 16]:
		draw_rect(Rect2(x, -49, 4, 43), Color("#928960"))
	draw_rect(Rect2(-12, -45, 24, 38), Color("#3f9d83") if unlocked else Color("#243e34"))
	if unlocked:
		draw_rect(Rect2(-9,-12,18,5),Color("#78d5a8"))
	var rune := Color("#a1e3b2") if unlocked else Color("#8a9274")
	draw_rect(Rect2(-3, -66, 6, 9), rune)
	draw_rect(Rect2(-8, -63, 16, 3), rune)
	if not unlocked:
		draw_rect(Rect2(-14, -32, 28, 3), Color("#837650"))
		draw_rect(Rect2(-4, -36, 8, 10), Color("#ab9d6d"))
	for step in range(3):
		draw_rect(Rect2(-22 - step * 3, -6 + step * 4, 44 + step * 6, 4), Color("#918b63") if step % 2 == 0 else Color("#69745a"))
	# Roots join the entrance to the Mata without covering the main trail.
	for side in [-1, 1]:
		draw_rect(Rect2(27 * side - 3, -32, 6, 32), Color("#715536"))
		draw_rect(Rect2(32 * side - 6, -4, 12, 5), Color("#9a784a"))
	var font := ThemeDB.fallback_font
	var title := "Torre de Ascensão"
	draw_string(font, Vector2(-font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x * 0.5, -96), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#344d3d"))
	if nearby:
		draw_rect(Rect2(-3, 16, 6, 6), rune)
