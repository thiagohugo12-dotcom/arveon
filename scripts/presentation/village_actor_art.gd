class_name VillageActorArt
extends RefCounted

const PEOPLE := preload("res://assets/art/actors_v4/people.png")
const MONSTERS := preload("res://assets/art/actors_v4/monsters.png")
const PICKUPS := preload("res://assets/art/actors_v4/pickups.png")

static func person(canvas: CanvasItem, row: int, frame: int, feet := Vector2.ZERO, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect_region(PEOPLE,Rect2(feet+Vector2(-32,-64),Vector2(64,80)),Rect2(frame*32,row*40,32,40),tint)

static func monster(canvas: CanvasItem, kind: int, frame: int, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect_region(MONSTERS,Rect2(-32,-48,64,64),Rect2(frame*32,kind*32,32,32),tint)

static func pickup(canvas: CanvasItem, at: Vector2, index: int, tint := Color.WHITE) -> void:
	canvas.draw_rect(Rect2(at+Vector2(-16,9),Vector2(32,4)),Color(0.44,0.56,0.25,0.44*tint.a))
	canvas.draw_texture_rect_region(PICKUPS,Rect2(at+Vector2(-32,-50),Vector2(64,64)),Rect2((index%4)*32,(index/4)*32,32,32),tint)
