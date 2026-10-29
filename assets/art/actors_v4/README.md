# Village actors V4

Thiago requested simpler player, NPC, boar, spider and cactus sprites and
animations matching the approved village reference. Built-in image_gen,
11 October 2026. Prompts: production transparent sprite sheets, tiny top-down
mobile pixel art, 8–12 colors, broad opaque clusters, stable head/torso/feet,
four walk/action poses; four explorer directions, smith and merchant, three
monster types; closed/half-open/open chest, herbs, mushrooms and fallen wood.
No text, scenery, complex textures or tiny ornaments.

Original outputs retained in tools/art_source/actors_v4 (excluded from Web):
people.png: exec-297839da-5001-4f92-9df6-d594ff7c4590
monsters.png: exec-b828422c-ca66-42ac-af32-051cf8e887b1
pickups.png: exec-2300293f-c205-4231-a8a6-59ae7607b85e

tools/prepare_village_actors.ps1 reproduces these runtime atlases with
nearest sampling and original alpha. Common registration across each row
prevents crop-induced jitter. Runtime always uses integer 2x, no filtering.
Legacy actors remain available for floors 2–5. No gameplay data changes.
