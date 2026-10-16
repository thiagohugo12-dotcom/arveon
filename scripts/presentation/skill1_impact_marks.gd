extends RefCounted
static func draw_marks(canvas: Node2D,category: String,alpha: float) -> void:
	var spread := 5+(1-alpha)*9
	if category == "cajado":
		for mark in range(6):
			var point := Vector2(0,-27)+Vector2.RIGHT.rotated(mark*TAU/6)*spread
			canvas.draw_rect(Rect2(point.round(),Vector2(2,2)),Color(0.66,0.89,0.76,alpha))
		return
	if category == "machado":
		for offset: Vector2 in [Vector2(-12,5),Vector2(10,6),Vector2(-5,9)]:
			canvas.draw_rect(Rect2(offset+Vector2(0,-(1-alpha)*8),Vector2(3,2)),Color(0.82,0.65,0.42,alpha))
		return
	if category == "arco":
		for side in [-1,1]:
			canvas.draw_line(Vector2(side*5,-31),Vector2(side*11,-37),Color(1,0.94,0.72,alpha),2,false)
			canvas.draw_line(Vector2(side*5,-23),Vector2(side*11,-17),Color(0.46,0.75,0.69,alpha),1,false)
		return
	if category == "lanca":
		canvas.draw_line(Vector2(-8,-27),Vector2(8,-27),Color(0.88,0.94,0.75,alpha),1,false)
		canvas.draw_line(Vector2(0,-33),Vector2(0,-21),Color(0.88,0.94,0.75,alpha),1,false)
		return
	for axis: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		canvas.draw_rect(Rect2((Vector2(0,-27)+axis*spread).round(),Vector2(2,2)),Color(1,0.94,0.72,alpha))
