# Hub V3

New transparent pieces generated from Thiago's approved village reference,
2026-10-11. Packed offline with nearest sampling and original alpha, no
color-keying. Cottage, forge, market, two trees and shrub: village.png.
Fence, smith sign, barrel, crate, fire, lantern, bench, pebbles: props.png.
Runtime uses integer 2x scaling and proportional cells with padding.

Original generated sources retained in tools/art_source/hub_v3, excluded from
Godot imports and Web packaging (not required at runtime):
exec-a15a8dd2-568c-477d-936d-1a5c11bee378.png (1672x941)
exec-5efdb3d4-9875-4a9c-a82c-b0d9ce9d1ebb.png (1671x941).
tools/prepare_hub_art.ps1 packs the retained originals by default.
tools/generate_hub_ground.gd regenerates ground.png in Godot headless.

Ground is separate from sprites. Trees retain physical feet. Buildings have
independent base footprints, toggled with the floor-one theme. NPC feet and
interactions share DISPLAY_STATIONS. Legacy service anchors only apply to
floors 2–5. Approved monsters and explorer sprites are unchanged.
