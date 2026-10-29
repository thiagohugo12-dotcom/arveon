class_name AncientCaiman
extends EnemyActor

# Mini-chefe opcional do Bosque Afundado. Três golpes avisados no chão:
#  mordida frontal (cone), investida em linha reta (faixa) e golpe de cauda (círculo).
# Com pouca vida (40%) fica mais agressivo: avisos 30% mais curtos e mais rápido.
# Não sai da própria arena; quando o jogador foge, volta para casa e recupera a postura.
enum Act { BITE, CHARGE, TAIL }
const BITE_RANGE := 98.0
const CHARGE_RANGE := 240.0
const CHARGE_SPEED := 380.0
const TAIL_RADIUS := 118.0
const WINDUPS := [0.65, 0.85, 0.75]
const ACTIVES := [0.12, 0.55, 0.16]
const DAMAGE := [1.0, 1.25, 0.9]

var arena := Rect2()
var act := Act.BITE
var windup := 0.0
var active := 0.0
var recover := 1.2
var aim := Vector2.RIGHT
var hit_done := false
var cycle := 0

func display_name() -> String:
	return "Jacaré Ancião"

func enraged() -> bool:
	return health.current <= health.maximum * 0.4

func _physics_process(delta: float) -> void:
	tick_ability_status(delta)
	velocity = Vector2.ZERO
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive():
		_cancel()
		return
	var engaged := arena.grow(60.0).has_point(target.global_position) and not SafeCamp.in_clearance(target.global_position)
	if not engaged:
		_cancel()
		_return_home()
		return
	var offset := target.global_position - global_position
	var fury := 0.7 if enraged() else 1.0
	view.set_fury(enraged())
	if active > 0.0:
		active = maxf(0.0, active - delta)
		_resolve(offset)
		if active == 0.0:
			recover = 1.1 * fury
			(view as Floor3MonsterView).set_telegraph("", Vector2.ZERO, 0.0)
			view.set_warning(false)
	elif windup > 0.0:
		windup = maxf(0.0, windup - delta)
		if windup == 0.0:
			active = ACTIVES[act]
			hit_done = false
			view.play_attack(aim * 40.0)
	elif recover > 0.0:
		recover = maxf(0.0, recover - delta)
		view.set_facing(offset)
		if offset.length() > 110.0:
			velocity = offset.normalized() * stats.move_speed * (1.3 if enraged() else 1.0)
	else:
		_choose(offset, fury)
	var before := global_position
	move_and_slide()
	if not arena.grow(80.0).has_point(global_position) or SafeCamp.in_clearance(global_position):
		global_position = before
		if active > 0.0 and act == Act.CHARGE:
			# A investida para na borda da arena e vira recuperação.
			active = 0.0
			recover = 1.0
			view.set_warning(false)
			(view as Floor3MonsterView).set_telegraph("", Vector2.ZERO, 0.0)
	view.set_moving(velocity.length_squared() > 1.0)

func _choose(offset: Vector2, fury: float) -> void:
	var distance := offset.length()
	act = Act.BITE if distance <= 120.0 else Act.CHARGE
	if cycle % 3 == 2: act = Act.TAIL if distance <= 150.0 else Act.CHARGE
	if enraged() and cycle % 4 == 3: act = Act.CHARGE
	cycle += 1
	aim = offset.normalized()
	view.set_facing(aim)
	windup = float(WINDUPS[act]) * fury
	view.set_warning(true)
	var shape: String = ["mordida", "investida", "cauda"][act]
	var reach: float = [BITE_RANGE, CHARGE_RANGE, TAIL_RADIUS][act]
	(view as Floor3MonsterView).set_telegraph(shape, aim, reach)

func _resolve(offset: Vector2) -> void:
	match act:
		Act.BITE:
			if not hit_done and offset.length() <= BITE_RANGE and offset.normalized().dot(aim) > 0.5: _hit()
		Act.CHARGE:
			velocity = aim * CHARGE_SPEED * (1.15 if enraged() else 1.0)
			if not hit_done and offset.length() <= 60.0: _hit()
		Act.TAIL:
			if not hit_done and Vector2(offset.x, offset.y * 1.6).length() <= TAIL_RADIUS: _hit()

func _hit() -> void:
	hit_done = true
	if SafeCamp.in_clearance(target.global_position): return
	target.receive_damage(roundi(stats.contact_damage * float(DAMAGE[act])), "physical", display_name())

func _cancel() -> void:
	windup = 0.0
	active = 0.0
	recover = 1.2
	view.set_warning(false)
	view.set_fury(false)
	(view as Floor3MonsterView).set_telegraph("", Vector2.ZERO, 0.0)

func apply_control(duration: float) -> void:
	# Investida em andamento não é interrompida; fora dela vale o controle normal.
	if active > 0.0 and act == Act.CHARGE: return
	super.apply_control(duration)
