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

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	# V2 has a stable pose. Its duplicated frames preserve the existing atlas
	# contract while avoiding movement that reads as the NPC sliding sideways.
	if visual_v2:
		draw_texture_rect_region(V2_ATLAS, Rect2(-20, -27, 40, 48), Rect2(0, kind * 48, 40, 48))
	else:
		draw_texture_rect_region(ATLAS, Rect2(-16, -22, 32, 40), Rect2(phase * 32, kind * 40, 32, 40))
