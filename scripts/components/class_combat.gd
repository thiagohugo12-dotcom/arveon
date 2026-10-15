class_name ClassCombat
extends RefCounted

# Transient effects never refill HP. Persistent timers/charges live in AbilityState.
var player: PlayerActor
var progress: GameProgress
var category := ""
var combo := 0
var last_target := 0
var same_target_hits := 0
var perfect_ready := false
var guard_left := 0.0
var barrier := 0
var counter_left := 0.0
var fury_left := 0.0
var technique_hits := 0
var moving_time := 0.0

func bind(actor: PlayerActor, value: GameProgress) -> void:
	player = actor
	progress = value
	if category != progress.active_category():
		clear_effects()
		category = progress.active_category()

func clear_effects() -> void:
	combo = 0
	last_target = 0
	same_target_hits = 0
	perfect_ready = false
	guard_left = 0.0
	barrier = 0
	counter_left = 0.0
	fury_left = 0.0
	technique_hits = 0
	moving_time = 0.0

func has_passive(id: String) -> bool:
	return progress != null and progress.abilities.loadouts.get(category,{}).get("passives",[]).has(id)

func has_talent(id: String) -> bool:
	return progress != null and progress.abilities.talents.get(category,[]).has(id)

func specialization() -> String:
	return progress.abilities.loadouts.get(category,{}).get("specialization","") if progress != null else ""

func mastery() -> bool:
	return progress != null and progress.talents.level(category) >= 30

func tick(delta: float) -> void:
	guard_left = maxf(0,guard_left-delta)
	counter_left = maxf(0,counter_left-delta)
	fury_left = maxf(0,fury_left-delta)
	if guard_left == 0: barrier = 0
	moving_time = minf(3,moving_time+delta) if player.velocity.length_squared() > 4 else 0.0

func record_hit(actor: EnemyActor, source: String, critical: bool) -> void:
	if source == "basic":
		combo += 1
		var id := actor.get_instance_id()
		same_target_hits = mini(5,same_target_hits+1) if last_target == id else 1
		last_target = id
		if mastery() and category == "espada" and combo % 3 == 0: perfect_ready = true
		if has_passive("ritmo_combate") and combo % 3 == 0:
			for ability: String in progress.abilities.cooldowns[category]:
				progress.abilities.cooldowns[category][ability] = maxf(0,float(progress.abilities.cooldowns[category][ability])-0.3)
		if has_passive("golpe_pesado"):
			actor.apply_control(0.18)
		if has_passive("fio_afiado") and critical:
			actor.apply_mark(category,0.10,3.0)
		if has_passive("mira_instintiva") and combo % 3 == 0:
			actor.apply_mark(category,0.12,2.0)
		if has_talent("mira_continua") and same_target_hits == 3:
			actor.apply_mark(category,0.15,3.0)
		if has_talent("primeiro_disparo") and same_target_hits == 1:
			actor.apply_control(0.25)
		if has_passive("vigilancia") and player.global_position.distance_to(actor.global_position) < 120: counter_left = 1.5
		if has_talent("posicao_firme") and player.velocity.length_squared() < 4:
			counter_left = 2.0
		if has_passive("canalizacao") and combo % 3 == 0:
			progress.abilities.skill1_cooldowns[category] = maxf(0,float(progress.abilities.skill1_cooldowns[category])-0.5)
		if has_passive("foco_arcano") and critical:
			counter_left = 3.0

func hit_modifiers(target: EnemyActor, source: String) -> Dictionary:
	var scale := 1.0
	var chance := player.attack.critical_chance
	var distance := player.global_position.distance_to(target.global_position)
	var ratio := float(target.health.current)/maxi(1,target.health.maximum)
	var basic := source == "basic"
	if category == "espada":
		if has_talent("sequencia_precisa") and basic and (combo+1)%3 == 0: scale += 0.15
		if has_talent("ritmo_afiado") and basic and combo >= 3: scale += 0.08
		if has_passive("instinto_veterano"): chance = minf(1.0,chance+0.06)
		if specialization() == "duelista" and target.get_instance_id() == last_target and same_target_hits >= 3: scale += 0.12
		if not basic and perfect_ready: chance = 1.0
		if not basic and counter_left > 0 and has_talent("contra_ataque_fatal"): chance = 1.0
	elif category == "machado":
		if has_passive("executor") and ratio <= 0.30: scale += 0.20
		if has_talent("impacto_crescente") and basic and target.get_instance_id() == last_target: scale += minf(0.15,same_target_hits*0.03)
		if has_talent("finalizador") and not basic and ratio <= 0.20: scale += 0.25
		if specialization() == "berserker" and player.health.current < player.health.maximum*0.5: scale += 0.15
		if mastery() and not basic: scale += (1.0-ratio)*0.25
	elif category == "lanca":
		if has_passive("ponta_precisa") and distance >= 110: scale += 0.10
		if has_talent("alcance_ideal") and distance >= 100 and distance <= 170: scale += 0.12
		if has_talent("ponta_letal") and not basic and counter_left > 0: chance = 1.0
		if specialization() == "cacador" and target.mark_category == category and target.mark_left > 0: scale += 0.12
		if mastery() and distance >= 120: scale += 0.15
	elif category == "arco":
		if has_passive("cacador_preciso") and distance >= 180: scale += 0.15
		if has_talent("distancia_segura") and distance >= 240: scale += 0.12
		if specialization() == "atirador_elite" and not basic and distance >= 200: chance = maxf(chance,0.40)
		if mastery() and not basic and target.mark_left > 0 and target.mark_category == category: chance = 1.0
	elif category == "cajado":
		if has_talent("energia_focada") and not basic and barrier > 0: scale += 0.15
		if has_passive("foco_arcano") and not basic and counter_left > 0: scale += 0.12
		if specialization() == "arcanista" and not basic and source not in ["orbe_arcano","basic"]: scale += 0.12
		if mastery() and not basic and counter_left > 0: chance = 1.0
	if fury_left > 0: scale += 0.45
	return {"scale":scale,"chance":chance,"charge_scale":scale-(0.45 if fury_left > 0 else 0.0)}

func receive(amount: int) -> int:
	var scale := 1.0
	if guard_left > 0:
		scale -= 0.30
		counter_left = 3.0
	if has_passive("postura_firme") and player.velocity.length_squared() < 4: scale -= 0.08
	if has_passive("vontade_ancestral") and player.health.current < player.health.maximum*0.5: scale -= 0.10
	if has_talent("bastiao_ancestral") and guard_left > 0: scale -= 0.08
	if has_passive("pele_ferro") and player.health.current < player.health.maximum*0.5: scale -= 0.10
	if has_passive("vigilancia") and counter_left > 0: scale -= 0.10
	if has_passive("passos_leves") and moving_time >= 1.0: scale -= 0.08
	if has_passive("guarda_eter") and barrier > 0: scale -= 0.10
	if has_talent("postura_equilibrada") and guard_left > 0: scale -= 0.05
	if has_talent("recuo_tatico") and player.dash.active(): scale -= 0.15
	if has_talent("evasao_agil") and player.dash.active(): scale -= 0.20
	if has_talent("protecao_mistica") and barrier > 0: scale -= 0.10
	if specialization() == "sentinela" and player.velocity.length_squared() < 4: scale -= 0.10
	if specialization() == "batedor" and moving_time >= 2: scale -= 0.10
	if fury_left > 0: scale -= 0.20
	var reduced := ceili(amount*maxf(0.40,scale))
	var absorbed := mini(barrier,reduced)
	barrier -= absorbed
	return reduced-absorbed

func use(index: int) -> bool:
	if progress == null or category.is_empty(): return false
	var state := progress.abilities
	var prof := progress.talents.level(category)
	var rule := AbilityRules.skill1(progress.equipped.Arma) if index == 0 else AbilityRules.active_skill(category,state.loadouts[category].skills[index-1])
	if rule.is_empty(): return false
	if AbilityRules.effect(rule.id).shape == "projectile" and player.get_tree().get_nodes_in_group("player_projectiles").size() >= PlayerProjectile.MAX_ACTIVE: return false
	var ultimate: bool = rule.id == AbilityRules.CATEGORIES[category].ultimate.id
	if index == 0:
		if not state.start_skill1(category,float(rule.cooldown)): return false
	elif ultimate:
		if prof < 15 or not state.use_ultimate(category,category): return false
	elif not state.start_normal(category,rule.id,prof): return false
	var grade := int(state.grades[category].get(rule.id,1))
	var effect := AbilityRules.effect(rule.id,grade)
	if effect.shape == "guard":
		guard_left = float(effect.duration)+(1.0 if has_talent("guarda_aperfeicoada") else 0.0)
		barrier = roundi((12+player.spirit*2)*(1+0.25*(grade-1))) if rule.id == "barreira_espiritual" else 0
		if specialization() in ["guardiao_lamina","guardiao_espiritual"]: barrier += ceili(player.health.maximum*0.08)
	elif effect.shape == "buff":
		fury_left = float(effect.duration)
		if specialization() == "colosso": barrier = ceili(player.health.maximum*0.12)
	else:
		var power := float(rule.get("power",effect.get("power",1.0)))*(1+0.15*(grade-1))
		if ultimate and category == "espada" and prof >= 60: power *= 1.20
		if index == 0: power *= 1+0.03*int(progress.equipment[progress.equipped.Arma])
		var hits := _execute(rule.id,effect,power,ultimate)
		technique_hits += 1
		if specialization() == "colosso" and hits >= 2:
			guard_left = maxf(guard_left,3.0)
			barrier = maxi(barrier,ceili(player.health.maximum*0.08))
		if has_talent("corpo_ferro") and hits > 0:
			guard_left = maxf(guard_left,2.0)
		if specialization() == "guardiao_espiritual" and hits > 0:
			guard_left = maxf(guard_left,2.0)
			barrier = maxi(barrier,8+player.spirit)
		if has_talent("veu_espiritual") and hits > 0:
			guard_left = maxf(guard_left,2.0)
			barrier = maxi(barrier,6+player.spirit)
		if mastery() and category == "cajado" and technique_hits%3 == 0:
			guard_left = maxf(guard_left,3.0)
			barrier = maxi(barrier,10+player.spirit)
			counter_left = 3.0
	if index > 0 and not ultimate: perfect_ready = false
	player.view.play_skill(2 if ultimate else mini(index,1))
	player.skill_used.emit(index)
	return true

func _execute(id: String, effect: Dictionary, power: float, ultimate: bool) -> int:
	var hits := 0
	var event := CombatRules.next_event()
	var origin := player.global_position
	var direction := player.last_direction.normalized()
	var reach := float(effect.reach)+(20.0 if has_passive("alcance_treinado") else 0.0)
	var candidates := player.get_tree().get_nodes_in_group("damageable_enemies")
	var nearest: EnemyActor = null
	var nearest_squared := reach*reach
	if effect.shape == "projectile":
		for candidate in candidates:
			if not candidate is EnemyActor or not candidate.is_targetable(): continue
			var distance := origin.distance_squared_to(candidate.global_position)
			if distance > nearest_squared or not _visible(candidate): continue
			nearest = candidate
			nearest_squared = distance
		if nearest == null: return 0
		var modifiers := hit_modifiers(nearest,id)
		var roll := CombatRules.roll()
		var hit := CombatRules.resolve(player.attack.damage_base,player.special_bonus,power*float(modifiers.scale),float(modifiers.chance),player.attack.critical_multiplier,roll,float(modifiers.chance) if float(modifiers.chance) > player.attack.critical_chance else -1.0)
		var eligible := CombatRules.resolve(player.attack.damage_base,player.special_bonus,power*float(modifiers.charge_scale),float(modifiers.chance),player.attack.critical_multiplier,roll,float(modifiers.chance) if float(modifiers.chance) > player.attack.critical_chance else -1.0)
		if player.get_tree().get_nodes_in_group("player_projectiles").size() < PlayerProjectile.MAX_ACTIVE:
			player.attack.projectile_requested.emit(player,nearest,{"damage":hit.damage,"kind":"orbe" if category == "cajado" else "flecha","speed":player.attack.weapon.projectile_speed,"reach":reach,"category":category,"event":event,"damage_type":player.attack.damage_type,"critical":hit.critical,"ultimate":ultimate,"source":id,"eligible_damage":eligible.damage})
		return 1
	for candidate in candidates:
		if not candidate is EnemyActor or not candidate.is_targetable() or origin.distance_squared_to(candidate.global_position) > reach*reach or not _visible(candidate): continue
		var offset: Vector2 = candidate.global_position-origin
		if effect.shape == "cone" and offset.normalized().dot(direction) < float(effect.get("dot",0.0)): continue
		if effect.shape == "line" and (offset.dot(direction) < 0 or absf(offset.cross(direction)) > float(effect.get("width",30.0))): continue
		var modifiers := hit_modifiers(candidate,id)
		for strike in range(int(effect.get("hits",1))):
			if not candidate.is_targetable(): break
			var roll := CombatRules.roll()
			var hit := CombatRules.resolve(player.attack.damage_base,player.special_bonus,power*float(modifiers.scale),float(modifiers.chance),player.attack.critical_multiplier,roll,float(modifiers.chance) if float(modifiers.chance) > player.attack.critical_chance else -1.0)
			var eligible := CombatRules.resolve(player.attack.damage_base,player.special_bonus,power*float(modifiers.charge_scale),float(modifiers.chance),player.attack.critical_multiplier,roll,float(modifiers.chance) if float(modifiers.chance) > player.attack.critical_chance else -1.0)
			candidate.receive_damage(hit.damage,category,event if strike == 0 else CombatRules.next_event(),player.attack.damage_type,hit.critical,ultimate,id,eligible.damage)
		if candidate.health.is_alive():
			if effect.get("control",0.0) > 0.0: candidate.apply_control(float(effect.control))
			if effect.get("mark",0.0) > 0.0: candidate.apply_mark(category,float(effect.mark),4.0)
			if has_talent("presenca_imponente"): candidate.apply_control(0.25)
			if has_talent("eco_arcano") and category == "cajado": candidate.apply_mark(category,0.10,3.0)
			if specialization() == "guardiao_lamina" and counter_left > 0: candidate.apply_control(0.3)
		hits += 1
	return hits

func _visible(target: EnemyActor) -> bool:
	var query := PhysicsRayQueryParameters2D.create(player.global_position,target.global_position,1)
	return player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
