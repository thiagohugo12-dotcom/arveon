class_name TowerView
extends Node2D

const ASCENSION_TOWER := preload("res://assets/art/hub_v3/ascension_tower.png")
const LEGACY_PORTAL := preload("res://assets/art/mata_v2/camp.png")
const LEGACY_PORTAL_REGION := Rect2(104,64,84,100)
var visual_v2 := false
var unlocked := false
var nearby := false

func _ready() -> void:
	position = TowerEntrance.POSITION
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_notify_local_transform(true)
	_sync_depth()

# Como as árvores: a torre ordena pela base da porta, então quem passa atrás dela fica escondido pelo sprite.
func _sync_depth() -> void:
	z_as_relative = false
	z_index = roundi(position.y - 36.0) + 100

func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED: _sync_depth()

func set_state(available: bool, close: bool) -> void:
	if available != unlocked or close != nearby:
		unlocked = available
		nearby = close
		queue_redraw()

func _draw() -> void:
	if visual_v2:
		_draw_v2()
	else:
		_draw_legacy()

func _draw_legacy() -> void:
	draw_texture_rect_region(LEGACY_PORTAL,Rect2(-42,-100,84,100),LEGACY_PORTAL_REGION)
	if unlocked:
		draw_rect(Rect2(-13,-58,26,48),Color("#45cda680"))
	if nearby:
		draw_rect(Rect2(-7,1,14,4),Color("#b5f1c4"))

func _draw_v2() -> void:
	# Dedicated stone tower. Its lit doorway communicates the unlocked state.
	draw_rect(Rect2(-70,-7,140,10),Color("#718f3f80"))
	draw_texture_rect(ASCENSION_TOWER,Rect2(-80,-216,160,216),false)
	if unlocked:
		draw_rect(Rect2(-19,-72,38,54),Color("#45cda680"))
		draw_rect(Rect2(-7,-67,5,39),Color("#b5f1c4a0"))
		draw_rect(Rect2(5,-56,4,29),Color("#b5f1c480"))
	else:
		draw_rect(Rect2(-5,-48,10,13),Color("#785633"))
		draw_rect(Rect2(-3,-51,6,9),Color("#e0b75d"))
		draw_rect(Rect2(-1,-46,2,5),Color("#ffe08a"))
	if nearby:
		draw_rect(Rect2(-12,2,24,4),Color("#d7b268"))
