class_name CampNpcView
extends Node2D

const ATLAS := preload("res://assets/art/camp_npcs.png")
const V2_ATLAS := preload("res://assets/art/camp_npcs_v2.png")
@export_enum("Ferreiro", "Vendedor") var kind := 0
var visual_v2 := false:
	set(value):
		if visual_v2 != value:
			visual_v2 = value
			queue_redraw()
var phase := 0
var idle_time := 0.0
var blinking := false

func _process(delta: float) -> void:
	if not visual_v2 or not is_visible_in_tree(): return
	idle_time = fmod(idle_time+delta,4.6)
	var next := fmod(idle_time+kind*1.7,4.6) < 0.12
	if next != blinking:
		blinking = next
		queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_rect(Rect2(-11, 15, 22, 4), Color("#718f3f80"))
	# V2 has a stable pose. Its duplicated frames preserve the existing atlas
	# contract while avoiding movement that reads as the NPC sliding sideways.
	if visual_v2:
		draw_texture_rect_region(V2_ATLAS, Rect2(-20, -27, 40, 48), Rect2(0, kind * 48, 40, 48))
		if blinking:
			for x in [-4,3]:
				draw_rect(Rect2(x,-12,2,2),Color("#edc48a"))
				draw_rect(Rect2(x,-11,2,1),Color("#5a3728"))
	else:
		draw_texture_rect_region(ATLAS, Rect2(-16, -22, 32, 40), Rect2(phase * 32, kind * 40, 32, 40))
