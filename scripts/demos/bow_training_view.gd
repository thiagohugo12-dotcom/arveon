extends ActorView
func _draw() -> void:
	draw_rect(Rect2(-15,10,30,4),Color("#66863f70"))
	draw_rect(Rect2(-4,-32,8,43),Color("#71482e"))
	draw_rect(Rect2(-18,-38,36,22),Color("#523721"))
	draw_rect(Rect2(-15,-36,30,17),Color("#b5844b"))
	draw_rect(Rect2(-8,-32,16,9),Color("#eacb87"))
	draw_rect(Rect2(-3,-29,6,4),Color("#a65532"))
	_draw_hit_feedback()
