extends "res://tools/bow_pose_rig.gd"
## Reuse the approved torso/arm rasterizer, replacing only weapon/arm landmarks.
const DATA := preload("res://scripts/demos/staff_pose_data.gd")
func _draw() -> void:
	super._draw()
	# Head/scarf occlude the held weapon, retaining every approved opaque pixel.
	draw_set_transform(Vector2(-16,-32))
	draw_texture_rect_region(PEOPLE,Rect2(0,0,32,24),Rect2(0,row*40,32,24))
	draw_texture_rect_region(PEOPLE,Rect2(13,24,7,3),Rect2(13,row*40+24,7,3))
	draw_set_transform(Vector2.ZERO)
func bow_parts() -> void:
	var hand: Vector2 = DATA.HANDS[row][frame]
	var tip: Vector2 = hand+DATA.TIPS[row][frame]
	var tail: Vector2 = hand-DATA.TIPS[row][frame].normalized()*2
	line(tail,tip,Color("#382b25"),3)
	line(tail,tip,Color("#ba884b"),1)
	draw_rect(Rect2(tip.round()-Vector2(2,2),Vector2(5,5)),Color("#295f55"))
	draw_rect(Rect2(tip.round()-Vector2.ONE,Vector2(3,3)),Color("#65c7b1"))
	draw_rect(Rect2(tip.round(),Vector2.ONE),Color("#e3f6be"))
	if frame >= 2 and frame <= 4:
		for offset: Vector2 in [Vector2(-4,-1),Vector2(3,-3),Vector2(1,4)]:
			draw_rect(Rect2(tip.round()+offset,Vector2.ONE),Color("#a9e4c2"))
	var shoulder: Vector2 = DATA.SHOULDERS[row][0]
	var free_shoulder: Vector2 = DATA.SHOULDERS[row][1]
	var free_hand: Vector2 = DATA.FREE_HANDS[row][frame]
	var bend := Vector2(1,1) if row < 2 else Vector2(0,1)
	arm(shoulder,(shoulder+hand)*0.5+bend,hand)
	arm(free_shoulder,(free_shoulder+free_hand)*0.5+Vector2(-1,0),free_hand)
