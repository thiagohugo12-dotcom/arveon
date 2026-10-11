class_name CampNpcView
extends Node2D

const ATLAS := preload("res://assets/art/camp_npcs.png")
@export_enum("Ferreiro", "Vendedor") var kind := 0
var visual_v2 := false:
	set(value):
		if visual_v2 != value:
			visual_v2 = value
			queue_redraw()
var phase := 0
var idle_time := 0.0
var action_frame := 0

func _process(delta: float) -> void:
	if not visual_v2 or not is_visible_in_tree(): return
	idle_time = fmod(idle_time+delta,4.6)
	var cycle := fmod(idle_time+kind*1.7,4.6)
	var next := mini(3,int((cycle-3.4)/0.3)+1) if cycle >= 3.4 else 0
	if next != action_frame:
		action_frame = next
		queue_redraw()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_rect(Rect2(-11, 15, 22, 4), Color("#718f3f80"))
	# Action frames share a crop and planted feet; no whole-body translation.
	if visual_v2:
		VillageActorArt.person(self,4+kind,action_frame,Vector2(0,8))
	else:
		draw_texture_rect_region(ATLAS, Rect2(-16, -22, 32, 40), Rect2(phase * 32, kind * 40, 32, 40))
