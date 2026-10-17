extends TowerGuardianView
const SPRITES := preload("res://assets/art/local_combat_review/guardiao.png")
var sample_time := 0.0
var sample_direction := Vector2.DOWN
func sprite_frame() -> int:
	if sample_time < 0: return 0 if int(-sample_time*2)%2 == 0 else 1
	if sample_time < 0.375: return 2
	if sample_time < 0.75: return 3
	if sample_time < 0.87: return 4
	if sample_time < 1.20: return 5
	if sample_time < 1.60: return 6
	return 7
func _draw_body() -> void:
	var row := SwordActorView.direction_row(sample_direction)
	var tint := Color(1.7,1.55,1.25) if flash_left > 0 else Color.WHITE
	draw_texture_rect_region(SPRITES,Rect2(-80,-132,160,160),Rect2(sprite_frame()*80,row*80,80,80),tint)
