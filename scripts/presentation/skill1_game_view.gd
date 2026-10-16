class_name Skill1GameView
extends "res://scripts/demos/skill1_actor_view.gd"
## Reuses the approved review presentation; combat remains owned by PlayerActor.
var ground_effect: Node2D
func _ready() -> void:
	ground_effect = preload("res://scripts/demos/skill1_ground_effect.gd").new()
	add_child(ground_effect)
	ground_effect.top_level = true
	ground_effect.z_as_relative = false
func clear_skill1() -> void:
	super.clear_skill1()
	if is_instance_valid(ground_effect): ground_effect.clear()
func play_skill(index: int) -> void:
	super.play_skill(index)
	if index != 0 or not village_scale or skill_config.is_empty(): return
	var actor = get_parent()
	var reach_bonus := 20.0 if actor.class_combat.has_passive("alcance_treinado") else 0.0
	ground_effect.show_cast(actor.global_position,skill1_direction,skill_category,reach_bonus)
	ground_effect.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)

# Sword techniques reuse the approved sword atlas; the effect node handles
# the separate blue shield / blue thrust / red travelling frontal wave.
var sword_special_id := ""
var sword_special_left := 0.0
var sword_special_duration := 0.0
var sword_special_row := 0

func play_sword_special(id: String, aim: Vector2) -> void:
	if not village_scale or id not in [SwordSkillVfx.GUARDA, SwordSkillVfx.ESTOCADA, SwordSkillVfx.KAMUSARI]:
		return
	sword_special_id = id
	sword_special_row = SwordActorView.direction_row(aim)
	sword_special_duration = 0.30 if id == SwordSkillVfx.GUARDA else 0.38 if id == SwordSkillVfx.ESTOCADA else 0.60
	sword_special_left = sword_special_duration
	# Replace only the old generic ring for these three named actions.
	skill_left = 0.0
	queue_redraw()

func clear_sword_special() -> void:
	if sword_special_left > 0.0:
		sword_special_left = 0.0
		sword_special_id = ""
		queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	if sword_special_left > 0.0:
		sword_special_left = maxf(0.0, sword_special_left - delta)
		if sword_special_left <= 0.0: sword_special_id = ""
		queue_redraw()

func _draw_explorer(tint: Color) -> void:
	if sword_special_left <= 0.0 or not village_scale:
		super._draw_explorer(tint)
		return
	var progress := 1.0 - sword_special_left / maxf(0.01, sword_special_duration)
	var frame := 1
	if sword_special_id == SwordSkillVfx.ESTOCADA:
		frame = 2 if progress < 0.32 else 3 if progress < 0.68 else 4
	elif sword_special_id == SwordSkillVfx.KAMUSARI:
		frame = 1 if progress < 0.18 else 2 if progress < 0.30 else 3 if progress < 0.55 else 4 if progress < 0.78 else 5
	var walk_frame := anim_frame if walking or settle_left > 0.0 else 0
	draw_texture_rect_region(VillageActorArt.PEOPLE, Rect2(-32, 0, 64, 16), Rect2(walk_frame * 32, sword_special_row * 40 + 32, 32, 8), tint)
	draw_texture_rect_region(SwordActorView.SWORD, Rect2(-80, -104, 160, 160), Rect2(frame * 80, sword_special_row * 80, 80, 80), tint)
