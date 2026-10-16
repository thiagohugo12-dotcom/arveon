class_name Skill1GameView
extends "res://scripts/demos/skill1_actor_view.gd"
## Reuses the approved review presentation; combat remains owned by PlayerActor.
var ground_effect: Node2D
var sword_technique: Node2D
var sword_pose := ""
var sword_pose_time := 0.0
var sword_pose_duration := 0.32
var sword_pose_row := 3
func _ready() -> void:
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
	clear_sword_technique()
func play_skill(index: int) -> void:
	super.play_skill(index)
	if index != 0 or not village_scale or skill_config.is_empty(): return
	var actor = get_parent()
	var reach_bonus := 20.0 if actor.class_combat.has_passive("alcance_treinado") else 0.0
	ground_effect.show_cast(actor.global_position,skill1_direction,skill_category,reach_bonus)
	ground_effect.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)

func play_sword_technique(id: String, aim: Vector2, guard_time: float = 0.0) -> void:
	if skill_category != "espada" or not village_scale or not is_instance_valid(sword_technique): return
	if not id in ["guarda_reativa","estocada_precisa","danca_laminas"]: return
	sword_pose = id
	sword_pose_duration = 0.44 if id == "danca_laminas" else 0.32
	sword_pose_time = sword_pose_duration
	sword_pose_row = SwordActorView.direction_row(aim)
	var actor: Node2D = get_parent()
	sword_technique.cast(id,actor.global_position,aim,guard_time)
	sword_technique.z_index = clampi(roundi(actor.global_position.y)+100,-4096,4096)
	skill_left = 0.0
	queue_redraw()

func play_sword_counter(aim: Vector2) -> void:
	if sword_pose != "guarda_reativa" and sword_technique.kind != "guarda_reativa": return
	sword_pose = "guarda_reativa"
	sword_pose_time = 0.26
	sword_pose_duration = 0.26
	sword_pose_row = SwordActorView.direction_row(aim)
	sword_technique.counter(get_parent().global_position,aim)
	queue_redraw()

func clear_sword_technique() -> void:
	sword_pose = ""
	sword_pose_time = 0.0
	if is_instance_valid(sword_technique): sword_technique.clear()
	queue_redraw()

func _process(delta: float) -> void:
	super._process(delta)
	if not village_scale:
		clear_sword_technique()
	elif sword_pose_time > 0:
		sword_pose_time = maxf(0,sword_pose_time-delta)
		if sword_pose_time == 0: sword_pose = ""
		queue_redraw()

func _draw_explorer(tint: Color) -> void:
	if sword_pose_time <= 0 or skill_category != "espada" or not village_scale:
		super._draw_explorer(tint)
		return
	# Reuse the approved sword atlas and distance-based walking legs.
	var legs := anim_frame if walking or settle_left > 0 else 0
	draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,sword_pose_row*40+32,32,8),tint)
	var progress := 1.0-sword_pose_time/sword_pose_duration
	var frame := 1 if progress < 0.22 else 2 if progress < 0.45 else 3 if progress < 0.7 else 5
	if sword_pose == "guarda_reativa": frame = 0 if progress < 0.55 else 3
	draw_texture_rect_region(SwordActorView.SWORD,Rect2(-80,-104,160,160),Rect2(frame*80,sword_pose_row*80,80,80),tint)
