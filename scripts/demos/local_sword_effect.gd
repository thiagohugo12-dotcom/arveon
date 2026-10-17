extends SwordTechniqueEffect
## Proposed presentation, used ONLY by the local review scene.
var real_reach := 150.0
func _draw() -> void:
	if remaining <= 0: return
	if kind != "danca_laminas":
		super._draw()
		return
	var frame := _frame()
	var impact := SwordTechniqueTiming.contact(kind)
	var alpha := 1.0-clampf((elapsed-impact)/(duration-impact),0,1)
	var radius := real_reach if frame >= 3 else lerpf(20,42,elapsed/impact)
	var center := Vector2.ZERO # Exactly the collision origin, not the torso center.
	if frame >= 3:
		draw_circle(center,real_reach,Color(0.8,0.12,0.12,0.035*alpha))
		draw_arc(center,radius,0,TAU,64,Color(0.95,0.20,0.17,0.85*alpha),3,false)
		draw_arc(center,radius-5,0,TAU,64,Color(1.0,0.73,0.49,0.60*alpha),1,false)
		# Direction remains visible, while the ring communicates every legal target.
		draw_arc(center,radius,direction.angle()-0.55,direction.angle()+0.55,16,Color(1,0.92,0.72,alpha),5,false)
		draw_arc(Vector2(0,-24),42,direction.angle()-0.85,direction.angle()+0.55,12,Color(1,0.80,0.60,alpha),3,false)
	else:
		draw_arc(Vector2(0,-24),radius,-2.5,2.5,24,Color(0.9,0.20,0.15,0.8),2,false)
