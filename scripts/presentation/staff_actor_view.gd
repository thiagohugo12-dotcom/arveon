class_name StaffActorView
extends BowActorView
const STAFF := preload("res://assets/art/staff_demo_v1/attack.png")
const POSES := preload("res://scripts/demos/staff_pose_data.gd")
var staff_row := 0
var staff_time := 0.0
var staff_duration := 0.285
var channeling := false
var staff_weight := 0.0
var staff_attacks := 0
static func staff_prepare_time(interval: float) -> float: return interval*0.38
func prepare_staff(offset: Vector2, remaining: float, interval: float) -> void:
	if staff_time > 0.0: return
	staff_row = BowActorView.direction_row(offset)
	channeling = true
	staff_weight = clampf(1-remaining/staff_prepare_time(interval),0,1)
	queue_redraw()
func cancel_channel() -> void:
	if not channeling: return
	channeling = false
	staff_weight = 0.0
	queue_redraw()
func clear_staff() -> void:
	if staff_time <= 0 and not channeling: return
	staff_time = 0.0
	cancel_channel()
	queue_redraw()
func play_staff_attack(offset: Vector2, interval: float) -> void:
	staff_row = BowActorView.direction_row(offset)
	attack_direction = [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT][staff_row]
	staff_duration = interval*0.30
	staff_time = staff_duration
	attack_left = 0.0
	cancel_channel()
	staff_attacks += 1
	queue_redraw()
func _process(delta: float) -> void:
	super._process(delta)
	if not village_scale:
		clear_staff()
	elif staff_time > 0:
		staff_time = maxf(0,staff_time-delta)
		queue_redraw()
func staff_phase() -> int:
	if pose_override >= 0: return pose_override
	if staff_time > 0: return 2 if staff_time/staff_duration > 0.76 else 3
	if channeling: return 0 if staff_weight < 0.5 else 1
	return -1
func staff_frame_index() -> int:
	if pose_override >= 0: return [1,3,4,7][pose_override]
	if channeling: return clampi(int(staff_weight*4),0,3)
	if staff_time > 0: return clampi(4+int((1-staff_time/staff_duration)*4),4,7)
	return 7
func _draw_explorer(tint: Color) -> void:
	if not village_scale or staff_phase() < 0:
		super._draw_explorer(tint)
		return
	var walk_frame := anim_frame if walking or settle_left > 0 else 0
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(walk_frame*32,staff_row*40+32,32,8),tint)
	draw_texture_rect_region(STAFF,Rect2(-80,-104,160,160),Rect2(staff_frame_index()*80,staff_row*80,80,80),tint)
