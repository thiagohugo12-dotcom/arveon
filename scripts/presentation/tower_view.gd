class_name TowerView
extends Node2D

const V2_CAMP := preload("res://assets/art/mata_v2/camp.png")
const V2_PORTAL := Rect2(104,64,84,100)
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
	# The special structure now uses the same authored raster language as the
	# village and foliage. Gameplay position and collision remain unchanged.
	draw_rect(Rect2(-40,-6,80,10),Color("#66863f70"))
	if unlocked:
		draw_rect(Rect2(-25,-76,50,68),Color("#62ddb52d"))
	draw_texture_rect_region(V2_CAMP,Rect2(-42,-100,84,100),V2_PORTAL)
	if unlocked:
		draw_rect(Rect2(-13,-58,26,48),Color("#45cda680"))
		draw_rect(Rect2(-6,-52,5,36),Color("#b5f1c4a0"))
		draw_rect(Rect2(3,-43,4,25),Color("#b5f1c480"))
	else:
		draw_rect(Rect2(-5,-39,10,13),Color("#785633"))
		draw_rect(Rect2(-3,-42,6,9),Color("#e0b75d"))
		draw_rect(Rect2(-1,-37,2,5),Color("#ffe08a"))
	if nearby:
		draw_rect(Rect2(-7,1,14,4),Color("#b5f1c4"))

	var font := ThemeDB.fallback_font
	var title := "Torre de Ascensão"
	draw_string(font, Vector2(-font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x * 0.5, -108), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#344d3d"))
