extends ActorView
const BOW := preload("res://assets/art/bow_demo_v1/attack.png")
const DIRECTIONS := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const MUZZLES := [Vector2(10,6),Vector2(-12,-32),Vector2(-32,-12),Vector2(30,-12)]
var bow_row := 0
var bow_time := 0.0
var bow_duration := 0.25
var preparing := false
var preparation_weight := 0.0
var bow_attacks := 0
var pose_override := -1

static func direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 2 if direction.x < 0 else 3
	return 1 if direction.y < 0 else 0

static func prepare_time(interval: float) -> float: return interval*0.4

func prepare_bow(offset: Vector2, remaining: float, interval: float) -> void:
	if bow_time > 0.0: return
	bow_row = direction_row(offset)
	preparing = true
	preparation_weight = clampf(1.0-remaining/prepare_time(interval),0.0,1.0)
	queue_redraw()

func cancel_preparation() -> void:
	preparing = false
	preparation_weight = 0.0
	queue_redraw()

func clear_bow() -> void:
	bow_time = 0.0
	cancel_preparation()

func play_bow_attack(offset: Vector2, interval: float) -> void:
	bow_row = direction_row(facing if offset.is_zero_approx() else offset)
	attack_direction = DIRECTIONS[bow_row]
	bow_duration = interval*(0.25/0.8)
	bow_time = bow_duration
	attack_left = 0.0
	cancel_preparation()
	bow_attacks += 1

func _process(delta: float) -> void:
	super._process(delta)
	if bow_time > 0:
		bow_time = maxf(0,bow_time-delta)
		queue_redraw()

func phase() -> int:
	if pose_override >= 0: return pose_override
	if bow_time > 0: return 2 if bow_time/bow_duration > 0.72 else 3
	if preparing: return 0 if preparation_weight < 0.5 else 1
	return -1

func frame_index() -> int:
	if pose_override >= 0: return [1,3,4,7][pose_override]
	if preparing: return clampi(int(preparation_weight*4),0,3)
	if bow_time > 0: return clampi(4+int((1-bow_time/bow_duration)*4),4,7)
	return 7

func _draw_explorer(tint: Color) -> void:
	if phase() < 0:
		super._draw_explorer(tint)
		return
	var walk_frame := anim_frame if walking or settle_left > 0 else 0
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(walk_frame*32,bow_row*40+32,32,8),tint)
	draw_texture_rect_region(BOW,Rect2(-80,-104,160,160),Rect2(frame_index()*80,bow_row*80,80,80),tint)
