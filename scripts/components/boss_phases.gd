class_name BossPhases
extends RefCounted

# Fases de chefe guiadas pelo catálogo: 100% → 66% → 33% da vida. Cada troca dá uma pausa
# curta e invulnerável (pulso) para o jogador se reposicionar; a fase 3 chama asseclas.
var phase := 1
var transition_left := 0.0
var minion_kinds: Array = []

func setup(floor_id: int, role: String) -> void:
	minion_kinds = FloorCatalog.boss_minions(floor_id, role)

static func phase_for(ratio: float) -> int:
	var limits: Array = FloorCatalog.BOSS_PHASES.thresholds
	if ratio <= float(limits[1]): return 3
	return 2 if ratio <= float(limits[0]) else 1

func windup_scale() -> float:
	return float(FloorCatalog.BOSS_PHASES.windup[phase - 1])

func speed_scale() -> float:
	return float(FloorCatalog.BOSS_PHASES.speed[phase - 1])

func transitioning() -> bool:
	return transition_left > 0.0

# Chamado a cada quadro de física do chefe; devolve true enquanto ele está na pausa de troca.
func tick(actor: EnemyActor, delta: float) -> bool:
	if transition_left > 0.0:
		transition_left = maxf(0.0, transition_left - delta)
		if transition_left == 0.0:
			actor.invulnerable = false
			actor.modulate = Color.WHITE
		return transition_left > 0.0
	var next := phase_for(float(actor.health.current) / maxf(1.0, float(actor.health.maximum)))
	if next <= phase or not actor.health.is_alive():
		return false
	phase = next
	transition_left = float(FloorCatalog.BOSS_PHASES.transition)
	actor.invulnerable = true
	actor.modulate = Color(1.5, 1.3, 0.8)
	actor.phase_changed.emit(phase)
	if phase == 3 and not minion_kinds.is_empty():
		actor.summon_requested.emit(minion_kinds, int(FloorCatalog.BOSS_PHASES.max_minions))
	return true
