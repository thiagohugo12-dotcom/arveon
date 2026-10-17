class_name SwordTechniqueEffect
extends Node2D
## Presentation only: ClassCombat owns damage, reach, cooldowns and guard timing.
const ESTOCADA: Texture2D = preload("res://assets/art/sword_techniques/estocada_precisa_fx.png")
const GUARDA: Texture2D = preload("res://assets/art/sword_techniques/guarda_reativa_fx.png")
const CELL := 512.0
const ESTOCADA_FRAMES := SwordTechniqueTiming.FRAMES["estocada_precisa"]
const GUARDA_FRAMES := [0.05, 0.07, 0.0, 0.045, 0.075, 0.10]
const KAMUSARI_FRAMES := SwordTechniqueTiming.FRAMES["danca_laminas"]
# Each source pose was placed differently in its cell. Register the body at its
# feet, then normalize its height to the original 60 px explorer silhouette.
const BODY_HEIGHT := 60.0
const ESTOCADA_FEET := [Vector2(220,478), Vector2(215,478), Vector2(210,478), Vector2(175,368), Vector2(185,368), Vector2(280,368)]
const GUARDA_FEET := [Vector2(245,460), Vector2(235,460), Vector2(255,460), Vector2(225,386), Vector2(230,386), Vector2(270,386)]
const KAMUSARI_FEET := [Vector2(230,436), Vector2(225,436), Vector2(210,436), Vector2(175,388), Vector2(235,388), Vector2(270,388)]
const ESTOCADA_HEIGHTS := [254.0, 238.0, 238.0, 225.0, 225.0, 250.0]
const GUARDA_HEIGHTS := [264.0, 264.0, 264.0, 258.0, 230.0, 258.0]
const KAMUSARI_HEIGHTS := [228.0, 228.0, 185.0, 188.0, 200.0, 234.0]

var kind := ""
var direction := Vector2.RIGHT
var remaining := 0.0
var duration := 0.72
var guard_follow: Node2D
var counter_elapsed := -1.0
var bursts := 0 # Compatibility with the existing guard feedback contract.
var guard_time := 0.0
var elapsed := 0.0
var externally_clocked := false
var real_reach := 150.0
const EXTRA_DURATIONS := {"corte_crescente":0.30,"ruptura_ancestral":0.34}

func _draw_passing_cut(alpha: float) -> void:
	var contact := SwordTechniqueTiming.contact("danca_laminas")
	var launch := clampf((elapsed-contact+0.045)/0.11,0,1)
	var front := lerpf(72,real_reach-8,launch)
	var origin := Vector2(0,-24)
	var aim := direction.angle()
	# A broad swept cut crosses the enemy, rather than hiding a small wave behind it.
	for layer in range(3):
		var width: float = [40.0,31.0,23.0][layer]
		var rear: float = [-26.0,2.0,20.0][layer]
		var points := PackedVector2Array()
		for i in range(25):
			var t := float(i)/24
			var point := Vector2(rear,-width).bezier_interpolate(Vector2(front*0.45,-width),Vector2(front*0.85,-width*0.50),Vector2(front-layer*2,0),t)
			points.append(origin+point.rotated(aim))
		for i in range(23,-1,-1):
			var t := float(i)/24
			var point := Vector2(rear,width).bezier_interpolate(Vector2(front*0.45,width),Vector2(front*0.85,width*0.50),Vector2(front-layer*2,0),t)
			points.append(origin+point.rotated(aim))
		points.append(origin+Vector2(front*0.35,0).rotated(aim))
		var color: Color = [Color(0.90,0.03,0.12,alpha),Color(1,0.32,0.34,alpha),Color(1,0.96,0.88,alpha)][layer]
		draw_colored_polygon(points,color)
	# Thin separated streaks carry the red tails through the moving head.
	for side: float in [-1.0,1.0]:
		var bend := origin+direction*(front*0.30)+direction.orthogonal()*side*(36+launch*7)
		var tip := origin+direction*front
		draw_colored_polygon(tapered_streak(origin-direction*18+direction.orthogonal()*side*12,bend,3),Color(0.95,0.06,0.14,alpha))
		draw_colored_polygon(tapered_streak(bend,tip,6),Color(1,0.12,0.19,alpha))
		draw_colored_polygon(tapered_streak(bend,tip,2.5),Color(1,0.90,0.81,alpha))
	draw_colored_polygon(tapered_streak(origin+direction*8,origin+direction*front,5),Color(1,0.36,0.34,alpha))
	draw_colored_polygon(tapered_streak(origin+direction*12,origin+direction*(front-3),2),Color(1,0.96,0.88,alpha))

static func ribbon(center: Vector2, radius: float, angle: float, span: float, width: float) -> PackedVector2Array:
	# Continuous tapered curves: no texture cell or alpha cutout can clip a tail.
	var points:=PackedVector2Array()
	const SEGMENTS:=28
	for i in range(SEGMENTS+1):
		var t:=float(i)/SEGMENTS
		var thickness:=width*pow(t,0.7)
		points.append(center+Vector2.RIGHT.rotated(angle-span+t*span)*(radius-thickness))
	for i in range(SEGMENTS,0,-1):
		var t:=float(i)/SEGMENTS
		points.append(center+Vector2.RIGHT.rotated(angle-span+t*span)*radius)
	return points

static func forward_crescent(center: Vector2, aim: float, radius: float, width: float) -> PackedVector2Array:
	var points:=PackedVector2Array()
	const SEGMENTS:=24
	for i in range(SEGMENTS+1):
		var t:=float(i)/SEGMENTS
		points.append(center+Vector2.RIGHT.rotated(aim-0.95+t*1.9)*(radius-sin(t*PI)*width))
	# Both tips taper to zero. Omit duplicate tip vertices to keep triangulation valid.
	for i in range(SEGMENTS-1,0,-1):
		var t:=float(i)/SEGMENTS
		points.append(center+Vector2.RIGHT.rotated(aim-0.95+t*1.9)*radius)
	return points

func _draw_kamusari() -> void:
	var contact:=SwordTechniqueTiming.contact("danca_laminas")
	var aim:=direction.angle()
	if elapsed < contact:
		var p:=clampf(elapsed/contact,0,1)
		var angle:=aim-1.3+p*0.8
		draw_colored_polygon(ribbon(Vector2(0,-24),26+p*12,angle,0.9,4),Color("#a73339"))
		draw_colored_polygon(ribbon(Vector2(0,-24),26+p*12,angle,0.55,2),Color("#f1ae83"))
		if elapsed >= contact-0.045: _draw_passing_cut(0.65+0.35*clampf((elapsed-contact+0.045)/0.045,0,1))
		return
	var progress:=clampf((elapsed-contact)/(duration-contact),0,1)
	var alpha:=pow(1.0-progress,1.3)
	var angle:=aim+0.35+progress*TAU
	# Complete unchanged damage disk on contact; the blade still has a direction.
	draw_arc(Vector2.ZERO,real_reach-2,0,TAU,72,Color(0.82,0.19,0.22,0.70*alpha),2,false)
	draw_arc(Vector2.ZERO,real_reach-6,0,TAU,72,Color(0.98,0.58,0.39,0.30*alpha),1,false)
	draw_colored_polygon(ribbon(Vector2.ZERO,real_reach-2,angle,2.1,10*(1-progress)+2),Color(0.82,0.14,0.20,alpha))
	draw_colored_polygon(ribbon(Vector2.ZERO,real_reach-3,angle,1.65,4*(1-progress)+1),Color(1.0,0.69,0.48,alpha))
	draw_colored_polygon(ribbon(Vector2.ZERO,real_reach-4,angle,0.9,2),Color(1.0,0.94,0.77,alpha))
	var blade_center:=Vector2(0,-24)
	draw_colored_polygon(ribbon(blade_center,43,angle,1.9,7),Color(0.90,0.20,0.24,alpha))
	draw_colored_polygon(ribbon(blade_center,42,angle,1.5,3),Color(1.0,0.91,0.73,alpha))
	_draw_passing_cut(alpha)

static func frame_duration_total(frames: Array) -> float:
	var total := 0.0
	for frame_time in frames: total += float(frame_time)
	return total

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func cast(id: String, at: Vector2, aim: Vector2, guard_time: float = 0.0) -> void:
	kind = id
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	global_position = at
	self.guard_time = maxf(0.1, guard_time)
	duration = self.guard_time + GUARDA_FRAMES[5] if id == "guarda_reativa" else (frame_duration_total(KAMUSARI_FRAMES) if id == "danca_laminas" else frame_duration_total(ESTOCADA_FRAMES))
	if EXTRA_DURATIONS.has(id): duration=EXTRA_DURATIONS[id]
	remaining = duration
	elapsed = 0.0
	externally_clocked = false
	guard_follow = get_parent().get_parent() as Node2D
	counter_elapsed = -1.0
	bursts = 0
	queue_redraw()

func counter(at: Vector2, aim: Vector2) -> void:
	if kind != "guarda_reativa" or remaining <= 0.0: return
	global_position = at
	direction = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	counter_elapsed = 0.0
	bursts = 1
	remaining = maxf(remaining, GUARDA_FRAMES[3] + GUARDA_FRAMES[4] + GUARDA_FRAMES[5])
	queue_redraw()

func clear() -> void:
	kind = ""
	remaining = 0.0
	guard_follow = null
	counter_elapsed = -1.0
	bursts = 0
	guard_time = 0.0
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if remaining <= 0.0: return
	if not externally_clocked:
		remaining = maxf(0.0, remaining - delta)
		elapsed += delta
	if is_instance_valid(guard_follow):
		global_position = guard_follow.global_position
		z_index = clampi(roundi(global_position.y) + 99, -4096, 4096)
	if counter_elapsed >= 0.0:
		counter_elapsed += delta
		if counter_elapsed >= GUARDA_FRAMES[3] + GUARDA_FRAMES[4] + GUARDA_FRAMES[5] and elapsed < guard_time:
			counter_elapsed = -1.0
	if remaining <= 0.0: clear()
	else: queue_redraw()

func _frame() -> int:
	if EXTRA_DURATIONS.has(kind): return mini(5,3+floori(elapsed/duration*3))
	if SwordTechniqueTiming.FRAMES.has(kind): return SwordTechniqueTiming.frame(kind,elapsed)
	if kind == "guarda_reativa":
		if counter_elapsed >= 0.0:
			return 3 if counter_elapsed < GUARDA_FRAMES[3] else (4 if counter_elapsed < GUARDA_FRAMES[3] + GUARDA_FRAMES[4] else 5)
		return 0 if elapsed < GUARDA_FRAMES[0] else (1 if elapsed < GUARDA_FRAMES[0] + GUARDA_FRAMES[1] else (2 if elapsed < guard_time else 5))
	var frames: Array = KAMUSARI_FRAMES if kind == "danca_laminas" else ESTOCADA_FRAMES
	var boundary := 0.0
	for index in range(frames.size() - 1):
		boundary += float(frames[index])
		if elapsed < boundary: return index
	return 5

func replaces_body() -> bool:
	return false # All three atlases contain only VFX; the original explorer is always drawn.

func frame_rect(frame: int) -> Rect2:
	var feet: Array = GUARDA_FEET if kind == "guarda_reativa" else (KAMUSARI_FEET if kind == "danca_laminas" else ESTOCADA_FEET)
	var heights: Array = GUARDA_HEIGHTS if kind == "guarda_reativa" else (KAMUSARI_HEIGHTS if kind == "danca_laminas" else ESTOCADA_HEIGHTS)
	var scale_factor := BODY_HEIGHT / float(heights[frame])
	return Rect2(Vector2(0,12) - feet[frame] * scale_factor, Vector2.ONE * CELL * scale_factor)

func source_outline(frame: int) -> PackedVector2Array:
	# These illustrations are not a regular atlas: attack tips cross into the
	# next column. Trace the complete effect and exclude the neighboring body.
	if frame == 3 and kind == "danca_laminas":
		return PackedVector2Array([Vector2(0,0),Vector2(512,0),Vector2(650,260),Vector2(675,285),Vector2(650,310),Vector2(512,390),Vector2(512,512),Vector2(0,512)])
	if frame == 3 and kind == "estocada_precisa":
		return PackedVector2Array([Vector2(0,0),Vector2(512,0),Vector2(512,212),Vector2(630,225),Vector2(630,270),Vector2(512,285),Vector2(512,512),Vector2(0,512)])
	if frame == 4 and kind == "danca_laminas":
		return PackedVector2Array([Vector2(55,405),Vector2(80,350),Vector2(140,300),Vector2(125,260),Vector2(170,230),Vector2(210,215),Vector2(165,150),Vector2(130,40),Vector2(480,0),Vector2(610,100),Vector2(610,512),Vector2(55,512)])
	if frame == 4 and kind == "estocada_precisa":
		return PackedVector2Array([Vector2(25,390),Vector2(50,330),Vector2(120,270),Vector2(95,210),Vector2(155,160),Vector2(180,120),Vector2(610,0),Vector2(610,512),Vector2(25,512)])
	if frame == 4 and kind == "guarda_reativa":
		return PackedVector2Array([Vector2(0,0),Vector2(610,0),Vector2(610,512),Vector2(0,512)])
	return PackedVector2Array()

func _draw_complete_frame(atlas: Texture2D, target: Rect2, source: Rect2, outline: PackedVector2Array) -> void:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var scale_factor := target.size.x / CELL
	for point in outline:
		points.append(target.position + point * scale_factor)
		uv.append((source.position + point) / atlas.get_size())
	draw_polygon(points, PackedColorArray([Color.WHITE]), uv, atlas)

static func tapered_streak(start: Vector2, end: Vector2, width: float) -> PackedVector2Array:
	var side := (end-start).normalized().orthogonal()*width
	var middle := start.lerp(end,0.60)
	return PackedVector2Array([start,middle-side,end,middle+side])

func _draw_estocada() -> void:
	var contact := SwordTechniqueTiming.contact("estocada_precisa")
	var origin := Vector2(0,-24)
	var aim := direction.angle()
	if elapsed < contact-0.035:
		var p := clampf(elapsed/(contact-0.035),0,1)
		draw_colored_polygon(forward_crescent(origin,aim,24+p*6,2),Color(0.65,0.85,1,0.4+p*0.5))
		return
	var p := clampf((elapsed-contact+0.035)/(duration-contact+0.035),0,1)
	var launch := clampf((elapsed-contact+0.035)/0.035,0,1)
	var alpha := pow(1-p,1.2)
	var length := lerpf(32,100,launch)
	for side: float in [-1.0,0.0,1.0]:
		var offset := direction.orthogonal()*side*9
		var start := origin+direction*8+offset
		var end := origin+direction*(length-absf(side)*13)+offset
		draw_colored_polygon(tapered_streak(start,end,4),Color(0.12,0.50,1,alpha))
		draw_colored_polygon(tapered_streak(start,end,1.5),Color(0.85,0.96,1,alpha))
	if elapsed >= contact:
		var center := origin+direction*92
		var impact := clampf((elapsed-contact)/0.06,0,1)
		for i in range(8):
			var ray := Vector2.RIGHT.rotated(i*TAU/8+aim)
			draw_colored_polygon(tapered_streak(center+ray*3,center+ray*(9+impact*13),1.6),Color(1,0.78,0.30,alpha))

func _draw_guard() -> void:
	var origin := Vector2(0,-24)
	var aim := direction.angle()
	var alpha := clampf(elapsed/0.12,0,1)*clampf(remaining/0.10,0,1)
	# Whole curves are drawn in world space, without irregular atlas boundaries.
	draw_arc(origin,35,0,TAU,64,Color(0.25,0.65,1,0.20*alpha),2,false)
	draw_colored_polygon(forward_crescent(origin,aim,35,3),Color(0.55,0.88,1,0.85*alpha))
	if counter_elapsed >= 0:
		var p := clampf(counter_elapsed/0.22,0,1)
		var center := origin+direction*30
		for i in range(7):
			var ray := Vector2.RIGHT.rotated(aim-1.3+i*2.6/6)
			draw_colored_polygon(tapered_streak(center+ray*(4+p*10),center+ray*(10+p*23),1.5),Color(1,0.80,0.35,1-p))
		draw_colored_polygon(ribbon(origin,40+p*10,aim-0.8+p*1.6,1.4,4*(1-p)+0.3),Color(0.55,0.88,1,1-p))

func _draw() -> void:
	if remaining <= 0.0: return
	match kind:
		"danca_laminas": _draw_kamusari()
		"estocada_precisa": _draw_estocada()
		"guarda_reativa": _draw_guard()
		"corte_crescente":
			var p := clampf(elapsed/duration,0,1)
			var alpha := pow(1-p,1.2)
			var angle := direction.angle()-0.7+p*2.2
			draw_colored_polygon(ribbon(Vector2.ZERO,real_reach-4,angle,2.3,12*(1-p)+1),Color(0.15,0.75,0.72,alpha))
			draw_colored_polygon(ribbon(Vector2.ZERO,real_reach-5,angle,2.0,4*(1-p)+0.5),Color(0.85,1,0.92,alpha))
		"ruptura_ancestral":
			var p := clampf(elapsed/duration,0,1)
			var alpha := pow(1-p,1.2)
			var origin := Vector2(0,-18)
			for side: float in [-1.0,0.0,1.0]:
				var start := origin+direction*10+direction.orthogonal()*side*12
				var end := origin+direction*(real_reach-absf(side)*15)+direction.orthogonal()*side*20
				draw_colored_polygon(tapered_streak(start,end,6),Color(0.94,0.55,0.18,alpha))
				draw_colored_polygon(tapered_streak(start,end,2),Color(1,0.95,0.72,alpha))

func _draw_legacy_atlas() -> void:
	if remaining <= 0.0: return
	if kind == "danca_laminas":
		_draw_kamusari()
		return
	var atlas: Texture2D = GUARDA if kind == "guarda_reativa" else ESTOCADA
	var frame := _frame()
	if kind == "guarda_reativa" and frame == 2:
		# Keep the normal walking body during the three-second protection window.
		draw_set_transform(Vector2(0,-24), 0.0, Vector2(0.80,1.0))
		draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 40, Color(0.25,0.65,1.0,0.20), 4.0)
		draw_arc(Vector2.ZERO, 35.0, -1.2, 1.2, 24, Color(0.55,0.88,1.0,0.85), 1.5)
		draw_arc(Vector2.ZERO, 35.0, 1.8, 4.4, 24, Color(0.25,0.65,1.0,0.65), 1.5)
		draw_set_transform(Vector2.ZERO)
		return
	var target := frame_rect(frame)
	if frame >= 3 and frame <= 4: target.position.y += 8.0 if kind == "guarda_reativa" else 14.0
	var source := Rect2(float(frame % 3) * CELL, float(floori(frame / 3.0)) * CELL, CELL, CELL)
	# Direction now applies only to energy; the original explorer keeps its
	# matching four-direction body art and never gets rotated with the overlay.
	if absf(direction.y) > absf(direction.x):
		var pivot := Vector2(0,-24)
		var angle := direction.angle()
		draw_set_transform(pivot-pivot.rotated(angle),angle)
	elif direction.x < 0.0: draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	var outline := source_outline(frame)
	if outline.is_empty(): draw_texture_rect_region(atlas, target, source)
	else: _draw_complete_frame(atlas, target, source, outline)
	draw_set_transform(Vector2.ZERO)
