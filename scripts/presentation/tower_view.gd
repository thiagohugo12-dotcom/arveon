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
	var outline := Color("#4c4437")
	var stone_dark := Color("#6e6b57")
	var stone := Color("#969077")
	var stone_light := Color("#c9bf96")
	var moss := Color("#758e43")
	var portal := Color("#3fc59f") if unlocked else Color("#253f39")
	var portal_light := Color("#a7ecc2") if unlocked else Color("#415b50")

	# One soft footprint and three generous steps anchor the structure to the path.
	draw_rect(Rect2(-46,2,92,12),Color("#78984380"))
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

	var font := ThemeDB.fallback_font
	var title := "Torre de Ascensão"
	draw_string(font, Vector2(-font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x * 0.5, -96), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#344d3d"))
