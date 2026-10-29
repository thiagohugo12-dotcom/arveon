extends SwordTechniqueEffect
## Previous bitmap presentation retained ONLY for the comparison panel.
const LEGACY_KAMUSARI := preload("res://assets/art/sword_techniques/kamusari_fx.png")
func _draw() -> void:
	if kind != "danca_laminas":
		super._draw()
		return
	if remaining <= 0: return
	var frame:=_frame()
	var target:=frame_rect(frame)
	if frame in [3,4]: target.position.y+=14
	var source:=Rect2(float(frame%3)*CELL,float(floori(frame/3.0))*CELL,CELL,CELL)
	if absf(direction.y)>absf(direction.x):
		var pivot:=Vector2(0,-24)
		draw_set_transform(pivot-pivot.rotated(direction.angle()),direction.angle())
	elif direction.x<0: draw_set_transform(Vector2.ZERO,0,Vector2(-1,1))
	var outline:=source_outline(frame)
	if outline.is_empty(): draw_texture_rect_region(LEGACY_KAMUSARI,target,source)
	else: _draw_complete_frame(LEGACY_KAMUSARI,target,source,outline)
	draw_set_transform(Vector2.ZERO)
