class_name EncounterCamps
extends RefCounted

# Marco 3 · acampamentos de monstros (opt-in). Substitui o spawn contínuo por grupos
# fixos que nascem fora da tela, ficam limpos por um tempo e renascem longe do
# jogador. O estado vive só em memória: não há campo novo no save. Cada monstro é
# registrado por Main._register_enemy_defeat, então XP, ouro, drops, missão e
# contagem da Torre funcionam exatamente como no modo contínuo.
enum State { UNSPAWNED, ACTIVE, CLEARED }
const SPAWN_RADIUS := 900.0       # o centro precisa estar a esta distância (ou menos) para nascer
const DESPAWN_RADIUS := 1500.0    # acampamento intocado além disto é liberado
const MIN_SPAWN_DISTANCE := 520.0 # nenhum membro nasce mais perto que isto do jogador
const MAX_ALIVE := 16
const LOG_INTERVAL := 60.0

var main: Node
var floor_id := 0
var camps: Array = []
var initial_pass := true
var kills := 0
var log_left := LOG_INTERVAL

func setup(owner: Node, id: int) -> void:
	main = owner
	floor_id = id
	camps.clear()
	for definition: Dictionary in FloorCatalog.camps(id):
		var total := Vector2.ZERO
		for member: Dictionary in definition.members: total += member.position
		camps.append({"def": definition, "center": total / float(definition.members.size()), "state": State.UNSPAWNED, "actors": [], "timer": 0.0, "persistent": false})
	initial_pass = true
	log_left = LOG_INTERVAL

func is_empty() -> bool:
	return camps.is_empty()

# Chamado depois que os atores de combate foram removidos (Torre, troca de andar).
func reset() -> void:
	for camp: Dictionary in camps:
		camp.state = State.UNSPAWNED
		camp.actors = []
		camp.timer = 0.0
		camp.persistent = false
	initial_pass = true

func alive_count() -> int:
	var total := 0
	for camp: Dictionary in camps:
		for actor in camp.actors:
			if is_instance_valid(actor) and actor.health.is_alive(): total += 1
	return total

func update(delta: float, player_position: Vector2) -> void:
	for camp: Dictionary in camps:
		var distance: float = player_position.distance_to(camp.center)
		match camp.state:
			State.UNSPAWNED:
				if distance <= SPAWN_RADIUS and _can_spawn(camp, player_position):
					_spawn(camp)
			State.ACTIVE:
				_track(camp, distance)
			State.CLEARED:
				camp.timer = maxf(0.0, float(camp.timer) - delta)
				if camp.timer == 0.0 and _min_member_distance(camp, player_position) >= MIN_SPAWN_DISTANCE:
					camp.state = State.UNSPAWNED
	initial_pass = false
	log_left -= delta
	if log_left <= 0.0:
		log_left = LOG_INTERVAL
		print("ENCOUNTERS floor=%d kills=%d alive=%d active_camps=%d" % [floor_id, kills, alive_count(), count_state(State.ACTIVE)])

func count_state(state: int) -> int:
	var total := 0
	for camp: Dictionary in camps:
		if camp.state == state: total += 1
	return total

func _min_member_distance(camp: Dictionary, player_position: Vector2) -> float:
	var nearest := INF
	for member: Dictionary in camp.def.members:
		nearest = minf(nearest, player_position.distance_to(member.position))
	return nearest

func _can_spawn(camp: Dictionary, player_position: Vector2) -> bool:
	if alive_count() + camp.def.members.size() > MAX_ALIVE:
		return false
	# No carregamento do andar o mundo "já estava lá"; depois disso nada nasce à vista.
	return initial_pass or _min_member_distance(camp, player_position) >= MIN_SPAWN_DISTANCE

func _spawn(camp: Dictionary) -> void:
	camp.actors = []
	for member: Dictionary in camp.def.members:
		var adopted := _adopt(member)
		if adopted != null:
			camp.actors.append(adopted)
			camp.persistent = true
			continue
		camp.actors.append(main._spawn_camp_member(int(member.kind), member.position, str(camp.def.id)))
	camp.state = State.ACTIVE

# O monstro inicial do andar (Main.enemy) é o primeiro membro do primeiro acampamento.
func _adopt(member: Dictionary) -> EnemyActor:
	var candidate = main.enemy
	if not is_instance_valid(candidate) or candidate.has_meta("camp_id") or not candidate.health.is_alive():
		return null
	if candidate.kind != int(member.kind) or not candidate.position.is_equal_approx(member.position):
		return null
	candidate.set_meta("camp_id", "inicial")
	return candidate

func _track(camp: Dictionary, distance: float) -> void:
	var survivors: Array = []
	var touched := false
	for actor in camp.actors:
		if not is_instance_valid(actor):
			continue
		if not actor.health.is_alive():
			kills += 1
			continue
		survivors.append(actor)
		if actor.health.current < actor.health.maximum or actor.chasing:
			touched = true
	camp.actors = survivors
	if survivors.is_empty():
		camp.state = State.CLEARED
		camp.timer = float(camp.def.respawn)
		return
	if distance > DESPAWN_RADIUS and not touched and not camp.persistent:
		for actor in survivors: actor.queue_free()
		camp.actors = []
		camp.state = State.UNSPAWNED
