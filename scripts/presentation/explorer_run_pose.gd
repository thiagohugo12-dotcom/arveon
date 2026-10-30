class_name ExplorerRunPose
extends RefCounted
## Six articulated contacts built from the original pixels, without changing art files.
const STRIDE := 84.0
const STEPS := [0.0, 1.0, 0.35, 0.0, -1.0, -0.35]
const SOURCE_FRAMES := [0, 1, 1, 2, 3, 3]

static func legs(canvas: CanvasItem, row: int, phase: float, tint: Color) -> void:
	var step := int(floor(phase * 6.0)) % 6
	# Keep both legs from the same original frame together: splitting the sheet
	# at its midpoint cuts through the bent leg in the side-facing frames.
	var source := Rect2(SOURCE_FRAMES[step]*32,row*40+29,32,11)
	canvas.draw_texture_rect_region(VillageActorArt.PEOPLE,Rect2(-32,-6,64,22),source,tint)

static func draw(canvas: CanvasItem, row: int, phase: float, tint: Color) -> void:
	var step := int(floor(phase * 6.0)) % 6
	# Draw the complete original pose; separated body slices produced visible
	# seams through the arms and waist. Rotate around the feet as one piece.
	var tilt := -0.27 if row == 2 else 0.27 if row == 3 else 0.0
	canvas.draw_set_transform(Vector2.ZERO,tilt)
	VillageActorArt.person(canvas,row,SOURCE_FRAMES[step],Vector2.ZERO,tint)
	canvas.draw_set_transform(Vector2.ZERO)
