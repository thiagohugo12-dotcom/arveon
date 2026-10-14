# Skills 1 V1 - review only

Five pairs of RGBA atlases: espada, machado, lanca, arco and cajado.
Full/upper variants; 8 frames x 4 directions. See V2 dimensions/anchors below.
Rows front/back/left/right. Frames 0-2 prepare, 3 release, 4 impact, 5-7 recover.
Approved torso/head/scarf/backpack and original independent walking legs reused.
New poses reuse the source-grid arm rasterizer with <=12px shoulder-hand spans.
Basic atlases are unchanged. Sword arc, raised axe, thrust, stronger draw and
charged staff each have an independent rig/timing/effect.

Build with Godot 4.5.1: set SKILL1_CATEGORY to espada/machado/lanca/arco/cajado,
then run tools/bake_skill1.gd with native compatibility rendering and import.
Rigs/baker are excluded from Web export. Runtime effects are bounded drawing,
no shaders, Light2D, particles or new damage/collision. Original physics reused.

Preparation in the isolated review is visual intent. PlayerActor.use_skill(0)
executes unchanged at release; original cooldown/damage/projectile rules apply.
Repeat never bypasses cooldown. Preview stays separate pending visual approval.


V2 full-body acting: category.png contains posed hips, knees and planted boots.
category_upper.png combines the same acted torso with original walking legs.
Sword/axe/bow/staff keep 80px cells; spear uses 112px cells with anchor (56,64)
for transparent margin only. Source pixel scale remains 2x for every category.
Skill1BodyPose supplies head/torso/foot acting and matching release muzzles.
Profiles are independent: sword step/twist, axe lift/crouch, spear lunge,
bow brace/recoil, staff channel/forward release. Approved basic assets unchanged.
