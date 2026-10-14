extends ActorView
const ATLASES := [preload("res://assets/art/axe_demo_v1/attack.png"),preload("res://assets/art/spear_demo_v1/attack.png")]
var weapon_kind := 0
var attack_row := 0
var swing_time := 0.0
var swing_duration := 0.3
var preparing := false
var prepare_weight := 0.0
var swings := 0
var pose_override := -1
static func prepare_time(interval: float) -> float: return interval*0.22
func clear_melee() -> void:
	swing_time = 0
	preparing = false
	queue_redraw()
func prepare_melee(offset: Vector2,remaining: float,interval: float) -> void:
	if swing_time > 0: return
	attack_row = SwordActorView.direction_row(offset)
	preparing = true
	prepare_weight = clampf(1-remaining/prepare_time(interval),0,1)
	queue_redraw()
func cancel_preparation() -> void:
	preparing = false
	queue_redraw()
func play_melee(offset: Vector2,interval: float) -> void:
	attack_row = SwordActorView.direction_row(offset)
	attack_direction = SwordActorView.DIRECTIONS[attack_row]
	swing_duration = interval*(0.42 if weapon_kind == 0 else 0.34)
	swing_time = swing_duration
	attack_left = 0
	preparing = false
	swings += 1
	queue_redraw()
func _process(delta: float) -> void:
	super._process(delta)
	if swing_time > 0:
		swing_time = maxf(0,swing_time-delta)
		queue_redraw()
func phase() -> int:
	if pose_override >= 0: return pose_override
	if swing_time > 0:
		var elapsed := 1-swing_time/swing_duration
		return 1 if elapsed < 0.18 else 2 if elapsed < 0.48 else 3
	return 0 if preparing else -1
func frame_index() -> int:
	if pose_override >= 0: return [1,2,4,7][pose_override]
	if preparing: return 0 if prepare_weight < 0.5 else 1
	if swing_time > 0: return clampi(2+int((1-swing_time/swing_duration)*6),2,7)
	return 7
func _draw_explorer(tint: Color) -> void:
	if phase() < 0:
		super._draw_explorer(tint)
		return
	var walk_frame := anim_frame if walking or settle_left > 0 else 0
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(walk_frame*32,attack_row*40+32,32,8),tint)
	draw_texture_rect_region(ATLASES[weapon_kind],Rect2(-80,-104,160,160),Rect2(frame_index()*80,attack_row*80,80,80),tint)
