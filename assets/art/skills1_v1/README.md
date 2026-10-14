# Skills 1 V1 - review only

Five RGBA atlases: espada, machado, lanca, arco and cajado.png.
Each 640x320; eight 80x80 cells per direction; foot anchor (40,52).
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
