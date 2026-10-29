class_name Floor2MonsterView
extends ActorView

# The five rows of each approved sheet share the same 72 x 64 cell grid.
# Gameplay remains in EnemyActor; this view only selects the visible pose.
const SHEETS := [
	preload("res://assets/art/andar2/monsters/goblin_garimpeiro.png"),
	preload("res://assets/art/andar2/monsters/tatu_rochoso.png"),
	preload("res://assets/art/andar2/monsters/escorpiao_da_chapada.png")
]
const ROWS := {"idle": 0, "walk": 1, "attack": 2, "charge": 2, "hit": 3, "death": 4}
const COUNTS := {"idle": 4, "walk": 6, "attack": 6, "charge": 6, "hit": 3, "death": 6}
const SPEEDS := {"idle": 3.0, "walk": 7.0, "attack": 9.0, "charge": 9.0, "hit": 8.0, "death": 6.0}

@export_range(0, 2) var monster_index := 0
var animation_state := "idle"
var animation_frame := 0
var animation_time := 0.0
var dying := false

func play_attack(target_offset := Vector2.ZERO) -> void:
	super.play_attack(target_offset)
	# A complete six-frame swing is presentation-only; contact damage is still
	# controlled by EnemyActor and cannot repeat with animation frames.
	attack_left = 6.0 / SPEEDS["attack"]
	_select_state("attack")

func flash() -> void:
	super.flash()
	flash_left = 3.0 / SPEEDS["hit"]
	_select_state("hit")

func play_defeat() -> void:
	super.play_defeat()
	dying = true
	defeat_left = 1.0
	_select_state("death")

func _process(delta: float) -> void:
	super._process(delta)
	var state := "idle"
	if dying:
		state = "death"
	elif flash_left > 0.0:
		state = "hit"
	elif attack_left > 0.0:
		state = "attack"
	elif monster_index == 1 and get_parent() is EnemyActor and (get_parent().charge_windup > 0.0 or get_parent().charge_left > 0.0):
		state = "charge"
	elif walking:
		state = "walk"
	_select_state(state)
	animation_time += delta
	var frame_count: int = int(COUNTS[state])
	var frame_step: int = int(animation_time * float(SPEEDS[state]))
	var next_frame: int = mini(frame_count - 1, frame_step) if state == "death" else frame_step % frame_count
	if next_frame != animation_frame:
		animation_frame = next_frame
		queue_redraw()

func _select_state(state: String) -> void:
	if animation_state == state:
		return
	animation_state = state
	animation_time = 0.0
	animation_frame = 0
	queue_redraw()

func _draw_monster() -> void:
	var source := Rect2(animation_frame * 72, ROWS[animation_state] * 64, 72, 64)
	var destination := Rect2(-36, -60, 72, 64)
	var tone := Color(1.65, 1.65, 1.4) if flash_left > 0.0 else Color.WHITE
	if facing.x < -0.25:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(SHEETS[monster_index], destination, source, tone)
	draw_set_transform(Vector2.ZERO)
