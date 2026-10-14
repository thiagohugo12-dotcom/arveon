extends MeleeActorView
## Skill priority is visual only. Approved basic states continue underneath.
const CATALOGUE := preload("res://scripts/demos/skill1_catalogue.gd")
var skill_category := "espada"
var skill_config: Dictionary = {}
var skill_texture: Texture2D
var walking_skill_texture: Texture2D
var skill1_direction := Vector2.RIGHT
var skill1_row := 3
var skill1_preparing := false
var skill1_weight := 0.0
var skill1_remaining := 0.0
var skill1_casts := 0
var displayed_skill1_frame := -1
var displayed_skill1_atlas := ""
var skill1_pose_override := -1
func configure(category: String) -> void:
	clear_skill1()
	skill_category = category
	skill_config = CATALOGUE.CONFIGS.get(category,{})
	skill_texture = load(skill_config.atlas) if not skill_config.is_empty() else null
	walking_skill_texture = load(String(skill_config.atlas).replace(".png","_upper.png")) if skill_config.get("body",false) else skill_texture
func clear_skill1() -> void:
	skill1_remaining = 0
	skill1_preparing = false
	skill1_weight = 0
	queue_redraw()
func prepare_skill1(direction: Vector2,weight: float) -> void:
	if skill_config.is_empty(): return
	skill1_direction = direction.normalized()
	skill1_row = SwordActorView.direction_row(direction)
	skill1_preparing = true
	skill1_weight = clampf(weight,0,1)
	queue_redraw()
func play_skill(index: int) -> void:
	if index != 0 or skill_config.is_empty():
		super.play_skill(index)
		return
	# ClassCombat calls this only after the existing execution has succeeded.
	skill1_preparing = false
	skill1_remaining = float(skill_config.duration)
	skill1_row = SwordActorView.direction_row(skill1_direction)
	skill1_casts += 1
	skill_left = 0 # Suppress only the obsolete generic Skill 1 ring.
	queue_redraw()
func _process(delta: float) -> void:
	super._process(delta)
	if not village_scale: clear_skill1()
	elif skill1_remaining > 0:
		skill1_remaining = maxf(0,skill1_remaining-delta)
		queue_redraw()
func skill1_phase() -> int:
	if skill1_pose_override >= 0: return skill1_pose_override
	if skill1_preparing: return 0
	if skill1_remaining > 0:
		var elapsed := 1-skill1_remaining/float(skill_config.duration)
		return 1 if elapsed < 0.2 else 2 if elapsed < 0.5 else 3
	return -1
func skill1_frame() -> int:
	if skill1_pose_override >= 0: return [2,3,4,7][skill1_pose_override]
	if skill1_preparing: return clampi(int(skill1_weight*3),0,2)
	return clampi(3+int((1-skill1_remaining/maxf(0.01,float(skill_config.get("duration",0.24))))*5),3,7)
func _draw_explorer(tint: Color) -> void:
	if skill_texture == null or not village_scale or skill1_phase() < 0:
		displayed_skill1_frame = -1
		displayed_skill1_atlas = ""
		super._draw_explorer(tint)
		return
	displayed_skill1_frame = skill1_frame()
	var legs := anim_frame if walking or settle_left > 0 else 0
	if walking or settle_left > 0 or not skill_config.get("body",false):
		draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,0,64,16),Rect2(legs*32,skill1_row*40+32,32,8),tint)
	var texture := walking_skill_texture if walking or settle_left>0 else skill_texture
	displayed_skill1_atlas = texture.resource_path
	var cell: int = skill_config.get("cell",80)
	var anchor: Vector2 = skill_config.get("anchor",Vector2(40,52))
	draw_texture_rect_region(texture,Rect2(-anchor*2,Vector2.ONE*cell*2),Rect2(skill1_frame()*cell,skill1_row*cell,cell,cell),tint)
