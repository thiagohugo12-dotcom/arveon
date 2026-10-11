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
var idle_time := 0.0
var phase := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	idle_time = 0.4 if kind == 0 else 1.1

func _process(delta: float) -> void:
	idle_time += delta
	if idle_time >= (1.0 if kind == 0 else 1.4):
		idle_time = 0.0
		phase = 1 - phase
		queue_redraw()

func _draw() -> void:
	draw_texture_rect_region(V2_ATLAS if visual_v2 else ATLAS, Rect2(-16, -22, 32, 40), Rect2(phase * 32, kind * 40, 32, 40))
