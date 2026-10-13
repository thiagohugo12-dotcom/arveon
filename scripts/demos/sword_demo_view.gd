extends ActorView
## Opt-in presentation. Original atlas, walking and core ActorView are unchanged.
## Six upper-body/weapon frames: prepare, strike, impact, three recovery steps.
const SWORD := preload("res://assets/art/sword_demo_v1/attack.png")
const DIRECTIONS := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const PREPARE_TIME := 0.07
var sword_row := 0
var sword_time := 0.0
var sword_duration := 0.24
var preparing := false
var preparation_weight := 0.0
var sword_attacks := 0
var pose_override := -1 # Contact-sheet inspection only; never gameplay.

static func direction_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y): return 2 if direction.x < 0 else 3
	return 1 if direction.y < 0 else 0

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
	# 240 ms at the original 650 ms cadence; Dex speeds the whole swing too.
	# Always shorter than its actual interval; never changes the damage timer.
	sword_duration = minf(0.30,interval*(0.24/0.65))
	sword_time = sword_duration
	preparing = false
	preparation_weight = 0.0
	sword_attacks += 1
	queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	if sword_time > 0.0:
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

func _draw() -> void:
	if phase() < 0:
		super._draw()
		return
	px(-15,13,30,2,Color("#66863f70"))
	px(-12,11,24,2,Color("#66863f70"))
	px(-8,9,16,2,Color("#66863f70"))
	var tint := Color(2.0,1.75,1.35) if flash_left > 0 else Color.WHITE
	var walk_frame := anim_frame if walking or settle_left > 0 else 0
	# The approved legs continue their distance-based stride under the attack.
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(walk_frame*32,sword_row*40+32,32,8),tint)
	# Upper body + attached arm/weapon baked on the same integer source grid.
	draw_texture_rect_region(SWORD,Rect2(-80,-104,160,160),Rect2(frame_index()*80,sword_row*80,80,80),tint)
	_draw_hit_feedback()
