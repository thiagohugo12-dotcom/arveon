class_name Skill1GameView
extends "res://scripts/demos/skill1_actor_view.gd"
## Reuses approved skill presentation; combat remains owned by PlayerActor.
const TECHNIQUE_POSES := {
	"estocada_precisa": [0,0,1,1,1,5],
	"guarda_reativa": [0,1,1,1,1,5],
	"danca_laminas": [0,0,1,2,3,5]
}
var ground_effect: Node2D
var sword_technique: SwordTechniqueEffect
var sword_pose := ""
var sword_pose_time := 0.0
var sword_pose_duration := 0.32
var sword_pose_row := 3
var displayed_technique_frame := -1

func seek_sword_technique(time: float) -> void:
	if not is_instance_valid(sword_technique) or not SwordTechniqueTiming.FRAMES.has(sword_technique.kind): return
	sword_technique.externally_clocked = true
	sword_technique.elapsed = time
	sword_technique.remaining = maxf(0.0,sword_technique.duration-time)
	sword_technique.queue_redraw()
	sword_pose_time = sword_technique.remaining
	queue_redraw()

func _ready() -> void:
	super._ready() # Original nearest filtering and initial foot position.
	ground_effect = preload("res://scripts/demos/skill1_ground_effect.gd").new()
	add_child(ground_effect)
	ground_effect.top_level = true
	ground_effect.z_as_relative = false
	sword_technique = preload("res://scripts/presentation/sword_technique_effect.gd").new()
	add_child(sword_technique)
	sword_technique.top_level = true
	sword_technique.z_as_relative = false

func clear_skill1() -> void:
	super.clear_skill1()
	if is_instance_valid(ground_effect): ground_effect.clear()
	# Skill 1 cancellation must not clear a different technique paused by a menu.
	# ClassCombat owns the latter's lifetime, death and equipment cancellation.

func configure(category: String) -> void:
	if category != skill_category: clear_sword_technique()
	super.configure(category)

func play_skill(index: int) -> void:
	super.play_skill(index)
	if index != 0 or not village_scale or skill_config.is_empty(): return
	var actor = get_parent()
	var reach_bonus := 20.0 if actor.class_combat.has_passive("alcance_treinado") else 0.0
	ground_effect.show_cast(actor.global_position, skill1_direction, skill_category, reach_bonus)
	ground_effect.z_index = clampi(roundi(actor.global_position.y) + 99, -4096, 4096)

func play_sword_technique(id: String, aim: Vector2, guard_time: float = 0.0) -> void:
	if skill_category != "espada" or not village_scale or not is_instance_valid(sword_technique): return
	if not id in ["guarda_reativa", "estocada_precisa", "danca_laminas"]: return
	var actor: Node2D = get_parent()
	sword_pose = id
	sword_pose_row = SwordActorView.direction_row(aim)
	sword_technique.cast(id, actor.global_position, aim, guard_time)
	if id == "danca_laminas":
		var bonus:=20.0 if actor is PlayerActor and actor.class_combat.has_passive("alcance_treinado") else 0.0
		sword_technique.real_reach=float(AbilityRules.effect(id).reach)+bonus
	sword_pose_duration = sword_technique.duration
	sword_pose_time = sword_pose_duration
	sword_technique.z_index = clampi(roundi(actor.global_position.y) + 99, -4096, 4096)
	skill_left = 0.0
	queue_redraw()

func play_sword_counter(aim: Vector2) -> void:
	if not is_instance_valid(sword_technique) or sword_technique.kind != "guarda_reativa": return
	var actor := get_parent() as Node2D
	sword_pose = "guarda_reativa"
	sword_pose_row = SwordActorView.direction_row(aim)
	sword_technique.counter(actor.global_position, aim)
	sword_pose_duration = sword_technique.remaining
	sword_pose_time = sword_pose_duration
	queue_redraw()

func clear_sword_technique() -> void:
	sword_pose = ""
	sword_pose_time = 0.0
	if is_instance_valid(sword_technique): sword_technique.clear()
	displayed_technique_frame = -1
	queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	var technique_frame := sword_technique._frame() if is_instance_valid(sword_technique) and sword_technique.remaining > 0.0 else -1
	if technique_frame != displayed_technique_frame:
		displayed_technique_frame = technique_frame
		queue_redraw()
	if not village_scale:
		clear_sword_technique()
	elif sword_pose_time > 0.0 and not sword_technique.externally_clocked:
		sword_pose_time = maxf(0.0, sword_pose_time - delta)
		if sword_pose_time <= 0.0: sword_pose = ""

func _draw_explorer(tint: Color) -> void:
	if skill_category == "espada" and village_scale and is_instance_valid(sword_technique) and sword_technique.remaining > 0.0:
		var frame := sword_technique._frame()
		if sword_technique.kind == "guarda_reativa" and frame == 2:
			super._draw_explorer(tint)
			return
		# The approved basic atlas is built from the exact PEOPLE pixels. Reuse
		# its articulated upper body and normal walking legs for every technique.
		var pose: int = TECHNIQUE_POSES[sword_technique.kind][frame]
		var legs := anim_frame if walking or settle_left > 0 else 0
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,sword_pose_row*40+32,32,8),tint)
		draw_texture_rect_region(SwordActorView.SWORD,Rect2(-80,-104,160,160),Rect2(pose*80,sword_pose_row*80,80,80),tint)
		return
	super._draw_explorer(tint)
