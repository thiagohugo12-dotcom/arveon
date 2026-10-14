extends BowProjectile
## The original projectile owns physical origin, steering, budget, walls and damage.
func _draw() -> void:
	var offset := visual_offset().rotated(-rotation)
	draw_set_transform(offset.round(),visual_direction.angle()-rotation)
	draw_rect(Rect2(-28,-1,10,2),Color("#f4dc9a55"))
	draw_rect(Rect2(-18,-1,7,2),Color("#fff0b999"))
	draw_rect(Rect2(-10,-2,22,4),Color("#42514b"))
	draw_rect(Rect2(-10,-1,22,2),Color("#fff0b9"))
	draw_rect(Rect2(9,-3,5,6),Color("#42514b"))
	draw_rect(Rect2(10,-2,4,4),Color("#edf4d5"))
	draw_rect(Rect2(-10,-4,4,8),Color("#76bfb0"))
	draw_rect(Rect2(-9,-2,3,4),Color("#fff0b9"))
	draw_set_transform(Vector2.ZERO)
