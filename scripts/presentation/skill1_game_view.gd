class_name Skill1GameView
extends "res://scripts/demos/skill1_actor_view.gd"
## Reuses approved skill presentation; combat remains owned by PlayerActor.
const TECHNIQUE_POSES := {
	"estocada_precisa": [0,0,1,1,1,5],
	"guarda_reativa": [0,1,1,1,1,5],
	"danca_laminas": [0,0,1,2,3,5],
	"corte_crescente": [0,1,2,3,4,5],
	"ruptura_ancestral": [0,0,1,1,1,5]
}
var ground_effect: Node2D
var sword_technique: SwordTechniqueEffect
var sword_pose := ""
var sword_pose_time := 0.0
var sword_pose_duration := 0.32
var sword_pose_row := 3
var displayed_technique_frame := -1
var bow_technique: BowTechniqueEffect
var bow_technique_row := 3
var staff_technique: StaffTechniqueEffect
var staff_guard: StaffTechniqueEffect
var staff_technique_row := 3
var axe_technique: AxeTechniqueEffect
var axe_fury: AxeTechniqueEffect
var axe_technique_row := 3
var spear_technique: SpearTechniqueEffect
var spear_technique_row := 3

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
	bow_technique = BowTechniqueEffect.new()
	add_child(bow_technique)
	bow_technique.top_level = true
	bow_technique.z_as_relative = false
	staff_technique = StaffTechniqueEffect.new()
	add_child(staff_technique)
	staff_technique.top_level = true
	staff_technique.z_as_relative = false
	staff_guard = StaffTechniqueEffect.new()
	add_child(staff_guard)
	staff_guard.top_level = true
	staff_guard.z_as_relative = false
	axe_technique = AxeTechniqueEffect.new()
	add_child(axe_technique)
	axe_technique.top_level = true
	axe_technique.z_as_relative = false
	axe_fury = AxeTechniqueEffect.new()
	add_child(axe_fury)
	axe_fury.top_level = true
	axe_fury.z_as_relative = false
	spear_technique = SpearTechniqueEffect.new()
	add_child(spear_technique)
	spear_technique.top_level = true
	spear_technique.z_as_relative = false

func clear_skill1() -> void:
	super.clear_skill1()
	if is_instance_valid(ground_effect): ground_effect.clear()
	# Skill 1 cancellation must not clear a different technique paused by a menu.
	# ClassCombat owns the latter's lifetime, death and equipment cancellation.

func configure(category: String) -> void:
	if category != skill_category:
		clear_sword_technique()
		clear_bow_technique()
		clear_staff_technique()
		clear_staff_guard()
		clear_axe_technique()
		clear_axe_fury()
		clear_spear_technique()
	super.configure(category)

func play_staff_technique(id: String, aim: Vector2, real_reach: float, guard_time: float = 0.0) -> void:
	if skill_category != "cajado" or not village_scale: return
	var effect := staff_guard if id == "barreira_espiritual" else staff_technique
	if not is_instance_valid(effect): return
	var actor := get_parent() as Node2D
	staff_technique_row = SwordActorView.direction_row(aim)
	effect.cast(id,actor.global_position,aim,real_reach,guard_time)
	effect.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)
	skill_left = 0.0
	queue_redraw()

func seek_staff_technique(time: float) -> void:
	if not is_instance_valid(staff_technique) or not staff_technique.active: return
	staff_technique.seek(time,(get_parent() as Node2D).global_position)
	queue_redraw()

func clear_staff_technique() -> void:
	if is_instance_valid(staff_technique): staff_technique.clear()
	queue_redraw()

func clear_staff_guard() -> void:
	if is_instance_valid(staff_guard): staff_guard.clear()
	queue_redraw()

func play_axe_technique(id: String, aim: Vector2, real_reach: float, fury_time: float = 0.0) -> void:
	if skill_category != "machado" or not village_scale: return
	var effect := axe_fury if id == "furia_machado" else axe_technique
	if not is_instance_valid(effect): return
	var actor := get_parent() as Node2D
	axe_technique_row = SwordActorView.direction_row(aim)
	effect.cast(id,actor.global_position,aim,real_reach,fury_time)
	effect.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)
	skill_left = 0.0
	queue_redraw()

func seek_axe_technique(time: float) -> void:
	if not is_instance_valid(axe_technique) or not axe_technique.active: return
	axe_technique.seek(time,(get_parent() as Node2D).global_position)
	queue_redraw()

func clear_axe_technique() -> void:
	if is_instance_valid(axe_technique): axe_technique.clear()
	queue_redraw()

func clear_axe_fury() -> void:
	if is_instance_valid(axe_fury): axe_fury.clear()
	queue_redraw()

func play_spear_technique(id: String, aim: Vector2, real_reach: float) -> void:
	if skill_category != "lanca" or not village_scale or not is_instance_valid(spear_technique): return
	var actor := get_parent() as Node2D
	spear_technique_row = SwordActorView.direction_row(aim)
	spear_technique.cast(id,actor.global_position,aim,real_reach)
	spear_technique.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)
	skill_left = 0.0
	queue_redraw()

func seek_spear_technique(time: float) -> void:
	if not is_instance_valid(spear_technique) or not spear_technique.active: return
	spear_technique.seek(time,(get_parent() as Node2D).global_position)
	queue_redraw()

func clear_spear_technique() -> void:
	if is_instance_valid(spear_technique): spear_technique.clear()
	queue_redraw()

func play_bow_technique(id: String, aim: Vector2, real_reach: float, marked_target: Node2D = null) -> void:
	if skill_category != "arco" or not village_scale or not is_instance_valid(bow_technique): return
	if not BowTechniqueEffect.TIMINGS.has(id): return
	var actor := get_parent() as Node2D
	bow_technique_row = SwordActorView.direction_row(aim)
	bow_technique.cast(id,actor.global_position,aim,real_reach,marked_target)
	bow_technique.z_index = clampi(roundi(actor.global_position.y)+99,-4096,4096)
	skill_left = 0.0
	queue_redraw()

func seek_bow_technique(time: float) -> void:
	if not is_instance_valid(bow_technique) or not bow_technique.active: return
	bow_technique.seek(time,(get_parent() as Node2D).global_position)
	queue_redraw()

func clear_bow_technique() -> void:
	if is_instance_valid(bow_technique): bow_technique.clear()
	queue_redraw()

func play_skill(index: int) -> void:
	super.play_skill(index)
	if index != 0 or not village_scale or skill_config.is_empty(): return
	var actor = get_parent()
	var reach_bonus := 20.0 if actor.class_combat.has_passive("alcance_treinado") else 0.0
	ground_effect.show_cast(actor.global_position, skill1_direction, skill_category, reach_bonus)
	ground_effect.z_index = clampi(roundi(actor.global_position.y) + 99, -4096, 4096)

func play_sword_technique(id: String, aim: Vector2, guard_time: float = 0.0) -> void:
	if skill_category != "espada" or not village_scale or not is_instance_valid(sword_technique): return
	if not TECHNIQUE_POSES.has(id): return
	var actor: Node2D = get_parent()
	sword_pose = id
	sword_pose_row = SwordActorView.direction_row(aim)
	sword_technique.cast(id, actor.global_position, aim, guard_time)
	if id in ["danca_laminas","corte_crescente","ruptura_ancestral"]:
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
		clear_bow_technique()
		clear_staff_technique()
		clear_staff_guard()
		clear_axe_technique()
		clear_axe_fury()
		clear_spear_technique()
	elif sword_pose_time > 0.0 and not sword_technique.externally_clocked:
		sword_pose_time = maxf(0.0, sword_pose_time - delta)
		if sword_pose_time <= 0.0: sword_pose = ""
	if is_instance_valid(staff_guard) and staff_guard.active:
		var actor := get_parent() as PlayerActor
		if actor == null or not actor.health.is_alive() or actor.progress == null or actor.progress.active_category() != "cajado": clear_staff_guard()
		else: staff_guard.seek_guard(actor.class_combat.guard_left,actor.global_position)
	if is_instance_valid(axe_fury) and axe_fury.active:
		var actor := get_parent() as PlayerActor
		if actor == null or not actor.health.is_alive() or actor.progress == null or actor.progress.active_category() != "machado": clear_axe_fury()
		else: axe_fury.seek_fury(actor.class_combat.fury_left,actor.global_position)

func _draw_explorer(tint: Color) -> void:
	if skill_category == "lanca" and village_scale and is_instance_valid(spear_technique) and spear_technique.active:
		var legs := anim_frame if walking or settle_left > 0 else 0
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,spear_technique_row*40+32,32,8),tint)
		draw_texture_rect_region(MeleeActorView.ATLASES[1],Rect2(-80,-104,160,160),Rect2(spear_technique.pose_frame()*80,spear_technique_row*80,80,80),tint)
		return
	var axe_effect: AxeTechniqueEffect = axe_technique if is_instance_valid(axe_technique) and axe_technique.active else axe_fury
	if skill_category == "machado" and village_scale and is_instance_valid(axe_effect) and axe_effect.active and (axe_effect.kind != "furia_machado" or axe_effect.elapsed < AxeTechniqueEffect.FURY_PREVIEW):
		var legs := anim_frame if walking or settle_left > 0 else 0
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,axe_technique_row*40+32,32,8),tint)
		draw_texture_rect_region(MeleeActorView.ATLASES[0],Rect2(-80,-104,160,160),Rect2(axe_effect.pose_frame()*80,axe_technique_row*80,80,80),tint)
		return
	var staff_effect: StaffTechniqueEffect = staff_technique if is_instance_valid(staff_technique) and staff_technique.active else staff_guard
	if skill_category == "cajado" and village_scale and is_instance_valid(staff_effect) and staff_effect.active and (staff_effect.kind != "barreira_espiritual" or staff_effect.elapsed < StaffTechniqueEffect.GUARD_PREVIEW):
		var release := 0.42 if staff_effect.kind == "barreira_espiritual" else float(StaffTechniqueEffect.TIMINGS[staff_effect.kind].release)
		var elapsed: float = staff_effect.elapsed
		var frame := clampi(int(elapsed/maxf(0.01,release)*4.0),0,3) if elapsed < release else clampi(4+int((elapsed-release)/0.15*2.0),4,7)
		var legs := anim_frame if walking or settle_left > 0 else 0
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,staff_technique_row*40+32,32,8),tint)
		draw_texture_rect_region(StaffActorView.STAFF,Rect2(-80,-104,160,160),Rect2(frame*80,staff_technique_row*80,80,80),tint)
		return
	if skill_category == "arco" and village_scale and is_instance_valid(bow_technique) and bow_technique.active:
		var timing: Dictionary = BowTechniqueEffect.TIMINGS[bow_technique.kind]
		var release: float = timing.release
		var elapsed: float = bow_technique.elapsed
		var frame := clampi(int(elapsed/maxf(0.01,release)*4.0),0,3) if elapsed < release else clampi(4+int((elapsed-release)/0.15*2.0),4,7)
		var legs := anim_frame if walking or settle_left > 0 else 0
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,bow_technique_row*40+32,32,8),tint)
		draw_texture_rect_region(BowActorView.BOW,Rect2(-80,-104,160,160),Rect2(frame*80,bow_technique_row*80,80,80),tint)
		return
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
