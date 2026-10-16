# Cajado V1 - review only

attack.png: RGBA 640x320, eight 80x80 cells per row; front/back/left/right.
Foot anchor (40,52), source pixels at integer 2x in the demo.
Generated with Godot 4.5.1 using tools/bake_staff_demo.gd and
tools/staff_pose_rig.gd, which inherits the approved compact-arm rasterizer.
Head, scarf, clothes and backpack reuse actors_v4/people.png; original legs
remain independent. staff_pose_data.gd supplies hand/tip landmarks to both
the baker and the visual projectile muzzle. No extra physics or damage.

Rebuild: godot --path . --rendering-method gl_compatibility --audio-driver Dummy
--script res://tools/bake_staff_demo.gd

Approved for main-game integration and fixed TESTE on 14/10/2026.
The original atlas is shared unchanged by demo and game.
