extends Node2D
## Non-enemy training stand: actual AutoAttack damage, no AI/rewards/proficiency.
signal hit(amount: int)
var enabled := true
var hits := 0
var total_damage := 0
var impact := 0.0
var last_damage := 0

func _ready() -> void:
	add_to_group("damageable_enemies")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func is_targetable() -> bool:
	return enabled

func receive_damage(amount: int) -> void:
	hits += 1
	total_damage += amount
	last_damage = amount
	impact = 0.12
	hit.emit(amount)
	queue_redraw()

func _process(delta: float) -> void:
	z_as_relative = false
	z_index = clampi(roundi(global_position.y)+100,-4096,4096)
	if impact > 0:
		impact = maxf(0,impact-delta)
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-15,10,30,4),Color("#66863f70"))
	draw_rect(Rect2(-4,-32,8,43),Color("#71482e"))
	draw_rect(Rect2(-18,-38,36,22),Color("#523721"))
	draw_rect(Rect2(-15,-36,30,17),Color("#b5844b"))
	draw_rect(Rect2(-8,-32,16,9),Color("#eacb87"))
	draw_rect(Rect2(-3,-29,6,4),Color("#a65532"))
	if impact > 0:
		for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
			var at: Vector2 = Vector2(0,-27)+direction*(8+(0.12-impact)*75)
			draw_line(at.round(),(at+direction*4).round(),Color("#fff1c1"),2)
		draw_string(ThemeDB.fallback_font,Vector2(-10,-46),str(last_damage),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#fff1c1"))
