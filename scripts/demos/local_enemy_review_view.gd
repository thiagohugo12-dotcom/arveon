extends ActorView
const ATTACKS := preload("res://assets/art/local_combat_review/enemy_attacks.png")
var sample_frame := 0
var sample_direction := Vector2.DOWN
func _draw_monster() -> void:
	var row := SwordActorView.direction_row(sample_direction)
	var kind := clampi(appearance-1,0,2)
	var tint := Color(1.8,1.8,1.35) if flash_left > 0 else Color.WHITE
	var recoil:=Vector2(0,-2) if impact_left > 0.06 else Vector2.ZERO
	draw_texture_rect_region(ATTACKS,Rect2(Vector2(-48,-64)+recoil,Vector2(96,96)),Rect2(sample_frame*48,(kind*4+row)*48,48,48),tint)
