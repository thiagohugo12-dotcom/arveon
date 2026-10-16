class_name SwordActorView
extends ActorView
## Approved upper-body frames; combat and the distance-based legs stay independent.
const SWORD := preload("res://assets/art/sword_demo_v1/attack.png")
const DIRECTIONS := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const PREPARE_TIME := 0.07
var sword_row := 0
var sword_time := 0.0
var sword_duration := 0.24
var preparing := false
var preparation_weight := 0.0
var sword_attacks := 0
var pose_override := -1 # Contact-sheet inspection only.

static func direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 2 if direction.x < 0 else 3
	return 1 if direction.y < 0 else 0

func clear_sword() -> void:
	if sword_time > 0.0 or preparing:
		sword_time = 0.0
		cancel_preparation()
		queue_redraw()

func prepare_sword(offset: Vector2, remaining: float) -> void:
	if sword_time > 0.0: return
	sword_row = direction_row(offset)
	preparing = true
	preparation_weight = clampf(1.0-remaining/PREPARE_TIME,0.0,1.0)
	queue_redraw()

func cancel_preparation() -> void:
	if preparing:
		preparing = false
		preparation_weight = 0.0
		queue_redraw()

func play_sword_attack(offset: Vector2, interval: float) -> void:
	sword_row = direction_row(facing if offset.is_zero_approx() else offset)
	attack_direction = DIRECTIONS[sword_row]
	# Same approved timing: 240 ms at 650 ms cadence, shortened by Dex.
	sword_duration = minf(0.30,interval*(0.24/0.65))
	sword_time = sword_duration
	attack_left = 0.0 # The attached blade replaces the old generic strike overlay.
	preparing = false
	preparation_weight = 0.0
	sword_attacks += 1
	queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	if not village_scale:
		clear_sword()
	elif sword_time > 0.0:
		sword_time = maxf(0.0,sword_time-delta)
		queue_redraw()

func phase() -> int:
	if pose_override >= 0: return pose_override
	if sword_time > 0:
		var p := 1.0-sword_time/sword_duration
		return 1 if p < 0.22 else 2 if p < 0.48 else 3
	return 0 if preparing else -1

func frame_index() -> int:
	var key := phase()
	if key < 3: return maxi(0,key)
	if pose_override >= 0: return 5
	return clampi(3+int((1.0-sword_time/sword_duration-0.48)/0.52*3),3,5)

func _draw_explorer(tint: Color) -> void:
	if not village_scale or phase() < 0:
		super._draw_explorer(tint)
		return
	var walk_frame := anim_frame if walking or settle_left > 0 else 0
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(walk_frame*32,sword_row*40+32,32,8),tint)
	draw_texture_rect_region(SWORD,Rect2(-80,-104,160,160),Rect2(frame_index()*80,sword_row*80,80,80),tint)
