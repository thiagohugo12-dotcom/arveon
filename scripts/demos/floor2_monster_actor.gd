extends Node2D
## Presentation-only actor. No enemy AI, hitbox, damage, spawn or save state.

const NAMES := ["goblin_garimpeiro", "tatu_rochoso", "escorpiao_da_chapada"]
const STATE_ROWS := [
	["idle", "walk", "attack", "hit", "death"],
	["idle", "walk", "charge", "hit", "death"],
	["idle", "walk", "attack", "hit", "death"],
]
const FRAME_COUNTS := [4, 6, 6, 3, 6]
const FPS := {"idle": 3.0, "walk": 7.0, "attack": 9.0, "charge": 9.0, "hit": 8.0, "death": 6.0}

@export_range(0, 2) var monster_index := 0
var sprite: AnimatedSprite2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	var sheet: Texture2D = load("res://assets/art/andar2/monsters/%s.png" % NAMES[monster_index])
	assert(sheet != null)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"): frames.remove_animation("default")
	for row in range(STATE_ROWS[monster_index].size()):
		var state: String = STATE_ROWS[monster_index][row]
		frames.add_animation(state)
		frames.set_animation_speed(state, FPS.get(state, 6.0))
		frames.set_animation_loop(state, state != "death")
		for column in range(FRAME_COUNTS[row]):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(column * 72, row * 64, 72, 64)
			frames.add_frame(state, atlas)
	sprite.sprite_frames = frames
	play_state("idle")

func play_state(state: String) -> void:
	if sprite == null: return
	if not sprite.sprite_frames.has_animation(state): return
	sprite.play(state)

func available_states() -> Array:
	return STATE_ROWS[monster_index]

func current_state() -> String:
	return sprite.animation if sprite != null else ""
