extends Node2D
# One small overlay, eight updates per second; no light, shader or particles.
var elapsed := 0.0
var phase := 0

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed += delta
	if elapsed >= 0.125:
		elapsed = fmod(elapsed,0.125)
		phase = (phase+1)%8
		queue_redraw()

func _draw() -> void:
	var rise := (phase%4)*2
	draw_rect(Rect2(-2,-38-rise,4,8),Color("#ffe99b"))
	if phase < 3:
		draw_rect(Rect2(6,-56-rise,2,2),Color("#efaa4f"))
