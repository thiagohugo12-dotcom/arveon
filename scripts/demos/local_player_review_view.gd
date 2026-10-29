extends Skill1GameView
const TECHNIQUE_ATLASES := {
	"estocada_precisa": preload("res://assets/art/local_combat_review/estocada_precisa.png"),
	"guarda_reativa": preload("res://assets/art/local_combat_review/guarda_reativa.png"),
	"danca_laminas": preload("res://assets/art/local_combat_review/danca_laminas.png")
}
func _ready() -> void:
	super._ready()
	remove_child(sword_technique)
	sword_technique.queue_free()
	sword_technique = preload("res://scripts/demos/local_sword_effect.gd").new()
	add_child(sword_technique)
	sword_technique.top_level = true
	sword_technique.z_as_relative = false
func play_sword_technique(id: String, aim: Vector2, guard_time: float=0.0) -> void:
	super.play_sword_technique(id,aim,guard_time)
	if id == "danca_laminas":
		var actor: PlayerActor = get_parent()
		sword_technique.real_reach = float(AbilityRules.effect(id).reach)+(20.0 if actor.class_combat.has_passive("alcance_treinado") else 0.0)
func _draw_explorer(tint: Color) -> void:
	if not is_instance_valid(sword_technique) or sword_technique.remaining <= 0 or not TECHNIQUE_ATLASES.has(sword_technique.kind):
		super._draw_explorer(tint)
		return
	var frame := sword_technique._frame()
	var texture: Texture2D = TECHNIQUE_ATLASES[sword_technique.kind]
	if walking:
		draw_texture_rect_region(texture,Rect2(-80,-104,160,104),Rect2(frame*80,sword_pose_row*80,80,52),tint)
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(anim_frame*32,sword_pose_row*40+32,32,8),tint)
	else:
		draw_texture_rect_region(texture,Rect2(-80,-104,160,160),Rect2(frame*80,sword_pose_row*80,80,80),tint)
