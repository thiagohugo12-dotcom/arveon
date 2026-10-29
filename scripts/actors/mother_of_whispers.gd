class_name MotherOfWhispers
extends RootGuardian

# Guardiã do Pântano das Vozes, no santuário lunar do Coração do Brejo. Usa a mesma
# arquitetura de Guardião (RootGuardian + BossPhases, estado do andar, drops e save)
# com limiar próprio de fase em 50% da vida (FloorCatalog "phase_thresholds").
# Fase 1 · Névoa Viva:      Rajada de Lodo (leque de projéteis), Manchas do Brejo
#                           (poças avisadas sob o jogador) e Onda de lodo ao redor.
# Fase 2 · Vozes do Fundo:  arte da fase 2, Raízes emergentes em fileira até o jogador,
#                           rajada mais larga, mais manchas e onda maior, com menos pausa.
enum Move { BURST, PUDDLES, WAVE, ROOTS }
const PHASE_ONE := [Move.BURST, Move.PUDDLES, Move.WAVE]
const PHASE_TWO := [Move.ROOTS, Move.BURST, Move.PUDDLES, Move.ROOTS, Move.WAVE]
const MOVE_WINDUP := {Move.BURST: 0.8, Move.PUDDLES: 0.6, Move.WAVE: 1.0, Move.ROOTS: 0.5}
const WAVE_RADIUS := [150.0, 175.0]
const LEASH := 380.0

var arena := Rect2()
var move := Move.BURST
var move_index := 0
var move_windup := 0.0
var move_recover := 1.6

func display_name() -> String:
	return "Mãe dos Sussurros"

func second_phase() -> bool:
	return phases.phase >= 2

func _physics_process(delta: float) -> void:
	tick_ability_status(delta)
	if phases.tick(self, delta):
		_cancel_move()
		return
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive():
		_cancel_move()
		return
	if SafeCamp.in_clearance(target.global_position) or target.global_position.distance_to(home_position) > LEASH:
		_cancel_move()
		_return_home()
		return
	var offset := target.global_position - global_position
	view.set_facing(offset)
	velocity = Vector2.ZERO
	if move_windup > 0.0:
		move_windup = maxf(0.0, move_windup - delta)
		if move_windup == 0.0:
			_resolve_move(offset)
			move_recover = (1.25 if second_phase() else 1.7)
			view.set_warning(false)
			view.set("telegraph", "")
	elif move_recover > 0.0:
		move_recover = maxf(0.0, move_recover - delta)
		if offset.length() > 140.0:
			velocity = offset.normalized() * stats.move_speed * (1.25 if second_phase() else 1.0)
	else:
		var cycle: Array = PHASE_TWO if second_phase() else PHASE_ONE
		move = cycle[move_index % cycle.size()]
		move_index += 1
		move_windup = float(MOVE_WINDUP[move]) * (0.85 if second_phase() else 1.0)
		aim = offset.normalized()
		aim_point = target.global_position
		view.set_warning(true)
		view.set("telegraph", ["rajada", "manchas", "onda", "raizes"][move])
		view.set("telegraph_direction", aim)
		view.set("telegraph_radius", WAVE_RADIUS[1 if second_phase() else 0])
	var before := global_position
	move_and_slide()
	if (arena.has_area() and not arena.has_point(global_position)) or SafeCamp.in_clearance(global_position):
		global_position = before
	view.set_moving(velocity.length_squared() > 1.0)

func _cancel_move() -> void:
	move_windup = 0.0
	move_recover = 1.4
	view.set_warning(false)
	view.set("telegraph", "")
	view.set_moving(false)

func _resolve_move(offset: Vector2) -> void:
	if not is_targetable() or not target.health.is_alive() or SafeCamp.in_clearance(target.global_position):
		return
	view.play_attack()
	match move:
		Move.BURST:
			var count := 7 if second_phase() else 5
			var spread := 0.95 if second_phase() else 0.7
			for i in range(count):
				var angle := -spread * 0.5 + spread * float(i) / float(count - 1)
				projectile_requested.emit(global_position + Vector2(0, -60), aim.rotated(angle), roundi(15 * damage_scale), display_name())
		Move.PUDDLES:
			var spots: Array = [aim_point]
			var extra := 4 if second_phase() else 2
			for i in range(extra):
				spots.append(aim_point + Vector2.RIGHT.rotated(TAU * float(i) / float(extra) + 0.4) * 70.0)
			for spot: Vector2 in spots:
				SwampHazard.spawn(get_parent(), spot, target, {"radius": 38.0, "warn_left": 0.85, "active_left": 3.6,
					"damage": roundi(6 * damage_scale), "interval": 0.8, "style": "lodo", "source_name": display_name()})
		Move.WAVE:
			var radius: float = WAVE_RADIUS[1 if second_phase() else 0]
			if Vector2(offset.x, offset.y * 1.6).length() <= radius:
				target.receive_damage(roundi(20 * damage_scale), "physical", display_name())
		Move.ROOTS:
			# Fileira de raízes do corpo até onde o jogador estava, em sequência.
			var steps := 6
			for i in range(steps):
				var spot: Vector2 = global_position.lerp(aim_point + aim * 40.0, float(i + 1) / float(steps))
				SwampHazard.spawn(get_parent(), spot, target, {"radius": 30.0, "warn_left": 0.55 + i * 0.12, "active_left": 0.6,
					"damage": roundi(18 * damage_scale), "style": "raiz", "source_name": display_name()})
