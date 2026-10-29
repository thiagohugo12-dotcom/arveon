class_name SwampEnemy
extends EnemyActor

# Inimigos comuns do Pântano das Vozes. Território, perseguição, sono por distância,
# dano recebido, recompensas e respawn continuam os de EnemyActor.
#  8 Limo do Brejo  · tanque lento: golpe de lodo sincronizado com o quadro de impacto
#                     da animação aprovada e mancha de lodo temporária no chão.
#  9 Sapo Venenoso  · alcance: mantém distância, cospe veneno e salta para se reposicionar.
# 10 Vulto do Brejo · rápido: aproxima, golpeia, recua e circula antes do próximo golpe.
const SLIME_REACH := 50.0
const SLIME_TRIGGER := 74.0
const TOAD_KEEP := Vector2(130.0, 210.0)
const WRAITH_TRIGGER := 54.0

var attack_cooldown := 0.6
var slime_attacking := false
var slime_hit_done := false
var attack_aim := Vector2.RIGHT
var hop_left := 0.0
var hop_direction := Vector2.ZERO
var shot_windup := 0.0
var strike_windup := 0.0
var retreat_left := 0.0
var circle_left := 0.0
var reposition_left := 2.0

func _ready() -> void:
	super._ready()
	if view is Floor3MonsterView:
		(view as Floor3MonsterView).impact.connect(_on_slime_impact)
		(view as Floor3MonsterView).attack_finished.connect(_on_slime_finished)

func _custom_behavior(delta: float, offset: Vector2, distance: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	match kind:
		8: _slime(offset, distance)
		9: _toad(delta, offset, distance)
		10: _wraith(delta, offset, distance)

func _return_home() -> void:
	shot_windup = 0.0
	strike_windup = 0.0
	hop_left = 0.0
	(view as Floor3MonsterView).set_telegraph("", Vector2.ZERO, 0.0)
	super._return_home()

# ── Limo do Brejo ─────────────────────────────────────────────────────────────
func _slime(offset: Vector2, distance: float) -> void:
	if slime_attacking:
		velocity = Vector2.ZERO
		return
	if distance <= SLIME_TRIGGER and attack_cooldown == 0.0:
		slime_attacking = true
		slime_hit_done = false
		attack_aim = offset.normalized()
		view.set_facing(attack_aim)
		# Aviso: ícone sobre a cabeça + os quadros de preparo da animação aprovada.
		view.set_warning(true)
		(view as Floor3MonsterView).play_slime_attack()
		return
	view.set_warning(false)
	if distance > 44.0:
		velocity = offset.normalized() * stats.move_speed

# Chamado pela vista no quadro de impacto: um único golpe por ataque.
func _on_slime_impact() -> void:
	view.set_warning(false)
	if slime_hit_done or not slime_attacking or not is_targetable(): return
	slime_hit_done = true
	var reach_point := global_position + attack_aim * 40.0
	_spawn_slime_puddle(global_position + attack_aim * 52.0)
	if not is_instance_valid(target) or not target.health.is_alive() or SafeCamp.in_clearance(target.global_position): return
	if target.global_position.distance_to(reach_point) <= SLIME_REACH and _clear_line():
		target.receive_damage(stats.contact_damage, "physical", display_name())

func _on_slime_finished() -> void:
	slime_attacking = false
	attack_cooldown = 2.2

func _spawn_slime_puddle(at: Vector2) -> void:
	if get_parent() == null or not is_instance_valid(target): return
	SwampHazard.spawn(get_parent(), at, target, {"radius": 30.0, "warn_left": 0.0, "active_left": 2.6,
		"damage": maxi(1, roundi(stats.contact_damage * 0.25)), "interval": 0.8, "style": "lodo", "source_name": display_name()})

# ── Sapo Venenoso ─────────────────────────────────────────────────────────────
func _toad(delta: float, offset: Vector2, distance: float) -> void:
	if hop_left > 0.0:
		hop_left = maxf(0.0, hop_left - delta)
		velocity = hop_direction * stats.move_speed * 2.6
		return
	if shot_windup > 0.0:
		shot_windup = maxf(0.0, shot_windup - delta)
		view.set_warning(true)
		if shot_windup == 0.0: _spit()
		return
	view.set_warning(false)
	var direction := offset.normalized()
	if distance < TOAD_KEEP.x and attack_cooldown > 0.4:
		# Perto demais: salta para trás, um pouco de lado.
		hop_direction = (-direction).rotated(0.5 * strafe_sign)
		hop_left = 0.3
		strafe_sign *= -1.0
		return
	if distance <= 250.0 and attack_cooldown == 0.0:
		shot_windup = 0.45
		return
	if distance > TOAD_KEEP.y:
		velocity = direction * stats.move_speed * 0.8
		return
	reposition_left -= delta
	if reposition_left <= 0.0:
		hop_direction = Vector2(-direction.y, direction.x) * strafe_sign
		hop_left = 0.26
		reposition_left = 2.3
		strafe_sign *= -1.0

func _spit() -> void:
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive(): return
	if SafeCamp.in_clearance(target.global_position): return
	var origin := global_position + Vector2(0, -24)
	projectile_requested.emit(origin, origin.direction_to(target.global_position), projectile_damage_override, display_name())
	view.play_attack()
	attack_cooldown = 1.9

# ── Vulto do Brejo ────────────────────────────────────────────────────────────
func _wraith(delta: float, offset: Vector2, distance: float) -> void:
	var direction := offset.normalized()
	if retreat_left > 0.0:
		retreat_left = maxf(0.0, retreat_left - delta)
		velocity = -direction * stats.move_speed * 1.1
		return
	if circle_left > 0.0:
		circle_left = maxf(0.0, circle_left - delta)
		velocity = Vector2(-direction.y, direction.x) * strafe_sign * stats.move_speed * 0.75
		return
	if strike_windup > 0.0:
		strike_windup = maxf(0.0, strike_windup - delta)
		view.set_warning(true)
		if strike_windup == 0.0: _wraith_strike()
		return
	view.set_warning(false)
	if distance <= WRAITH_TRIGGER and attack_cooldown == 0.0:
		strike_windup = 0.3
		return
	if distance > 36.0:
		velocity = direction * stats.move_speed

func _wraith_strike() -> void:
	view.set_warning(false)
	if not is_targetable() or not is_instance_valid(target) or not target.health.is_alive(): return
	view.play_attack(target.global_position - global_position)
	if global_position.distance_to(target.global_position) <= 62.0 and not SafeCamp.in_clearance(target.global_position) and _clear_line():
		target.receive_damage(stats.contact_damage, "physical", display_name())
	retreat_left = 0.42
	circle_left = 0.55
	strafe_sign *= -1.0
	attack_cooldown = 1.3

func _clear_line() -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
