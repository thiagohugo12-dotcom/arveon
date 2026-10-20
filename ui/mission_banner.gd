class_name MissionBanner
extends Control

## Small code-native quest plaque. It stays crisp at the game's nearest-neighbor scale.
func _draw() -> void:
	if size.x < 8.0 or size.y < 8.0:
		return
	var outer := Rect2(Vector2.ZERO,size)
	var shadow := Rect2(Vector2(3,3),size)
	draw_rect(shadow,Color("#11170de0"),true)
	draw_rect(outer,Color("#281d14f0"),true)
	draw_rect(outer,Color("#1a130ee8"),false,2.0)
	draw_rect(outer.grow(-3),Color("#d5a650"),false,1.0)
	draw_rect(outer.grow(-5),Color("#6e4328"),false,1.0)
	# Four stepped brass corners avoid the generic rectangular-card look.
	for corner in [Vector2(0,0),Vector2(size.x,0),Vector2(0,size.y),Vector2(size.x,size.y)]:
		var sx := 1.0 if corner.x == 0.0 else -1.0
		var sy := 1.0 if corner.y == 0.0 else -1.0
		draw_line(corner+Vector2(5*sx,2*sy),corner+Vector2(12*sx,2*sy),Color("#f0cf78"),2.0)
		draw_line(corner+Vector2(2*sx,5*sy),corner+Vector2(2*sx,12*sy),Color("#f0cf78"),2.0)
		draw_rect(Rect2(corner+Vector2(5*sx,5*sy)-Vector2(2,2),Vector2(4,4)),Color("#b77736"),true)
	# A small compass star gives the card a clear quest identity.
	var center := Vector2(21,size.y*0.5)
	draw_circle(center,9,Color("#382719"))
	draw_circle(center,8,Color("#c68e35"))
	draw_circle(center,5,Color("#f3d178"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-8),center+Vector2(2,-2),center+Vector2(0,8),center+Vector2(-2,-2)]),Color("#fff1b4"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(-8,0),center+Vector2(-2,-2),center+Vector2(8,0),center+Vector2(-2,2)]),Color("#e2a83f"))
	draw_circle(center,2,Color("#55301d"))
