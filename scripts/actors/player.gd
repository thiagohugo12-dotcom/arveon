class_name PlayerActor
extends CharacterBody2D

signal skill_used(index: int)

@export var stats: ActorData
@onready var health: Health = $Health
@onready var dash: DashMotor = $DashMotor
@onready var attack: AutoAttack = $AutoAttack
@onready var view: ActorView = $View
var input_driver: InputDriver
var progress: GameProgress
var class_combat := ClassCombat.new()
var last_direction := Vector2.DOWN
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var skill_ranks: Array[int] = [1, 1, 1]
var cooldown_factor := 1.0
var spirit := 0
var armor := 0
var resistance := 0.0
var physical_damage := 12
var special_bonus := 1.0
var charge_event := 0
var charge_build: Dictionary = {}
var fury_left := 0.0
var charge_left := 0.0
var charge_direction := Vector2.DOWN
var charge_hits: Dictionary = {}
var base_max_hp := 100
var base_weapon_damage := 12
# Transient startup only: never serialized or written into ability cooldowns.
var skill1_pending := 0.0
var skill1_pending_category := ""
var skill1_pending_direction := Vector2.DOWN

func _cancel_skill1() -> void:
	skill1_pending = 0
	skill1_pending_category = ""
	if view is Skill1GameView: view.clear_skill1()
	_sync_skill_cooldowns()

func _tick_skill1(delta: float) -> void:
	if skill1_pending <= 0: return
	if not health.is_alive() or input_driver == null or input_driver.blocked or not view.village_scale or not attack.armed or progress.active_category() != skill1_pending_category or SafeCamp.in_clearance(global_position):
		_cancel_skill1()
		return
	skill1_pending = maxf(0,skill1_pending-delta)
	var preparation: float = view.skill_config.prepare
	view.prepare_skill1(skill1_pending_direction,1-skill1_pending/preparation)
	if skill1_pending == 0:
		# Commit once through the original combat implementation, with input aim.
		var walking_direction := last_direction
		last_direction = skill1_pending_direction
		skill1_pending_category = ""
		if not class_combat.use(0): view.clear_skill1()
		last_direction = walking_direction
	_sync_skill_cooldowns()

func _ready() -> void:
	stats = stats.duplicate() as ActorData
	attack.weapon = attack.weapon.duplicate() as WeaponData
	health.changed.connect(view.set_health)
	health.died.connect(_on_died)
	attack.attacked.connect(_on_attack)
	health.initialize(stats.max_hp)

func _physics_process(delta: float) -> void:
	if progress != null:
		progress.abilities.tick(delta,progress.active_category())
		class_combat.tick(delta)
		_sync_skill_cooldowns()
	fury_left = class_combat.fury_left
	attack.damage_scale = 1.0
	view.set_fury(fury_left > 0.0)
	if not health.is_alive() or input_driver == null:
		_cancel_skill1()
		_clear_sword_visual()
		_clear_bow_visual()
		_clear_staff_visual()
		_clear_melee_visual()
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	if input_driver.blocked:
		_cancel_skill1()
		_clear_sword_visual()
		_clear_bow_visual()
		_clear_staff_visual()
		_clear_melee_visual()
		dash.time_left = 0.0
		charge_left = 0.0
		charge_hits.clear()
		velocity = Vector2.ZERO
		view.set_moving(false)
		return
	dash.tick(delta)
	var movement := input_driver.movement()
	if not movement.is_zero_approx():
		last_direction = movement.normalized()
		view.set_facing(last_direction)
	if input_driver.consume_dash():
		dash.request(movement, last_direction, stats)
	velocity = dash.direction * stats.dash_speed if dash.active() else movement * stats.move_speed
	move_and_slide()

	view.set_moving(velocity.length_squared() > 1.0)
	_tick_skill1(delta)
	_prepare_sword_visual()
	_prepare_bow_visual()
	_prepare_staff_visual()
	_prepare_melee_visual()
	attack.tick(delta, self)

func _uses_melee_visual() -> bool:
	return view is MeleeActorView and view.village_scale and attack.armed and attack.weapon.category in ["machado","lanca"]

func _clear_melee_visual() -> void:
	if view is MeleeActorView: (view as MeleeActorView).clear_melee()

func _sync_melee_weapon() -> void:
	if not _uses_melee_visual():
		_clear_melee_visual()
		return
	var melee := view as MeleeActorView
	var kind := 0 if attack.weapon.category == "machado" else 1
	if melee.weapon_kind != kind:
		melee.clear_melee()
		melee.weapon_kind = kind

func _prepare_melee_visual() -> void:
	if not view is MeleeActorView: return
	var melee := view as MeleeActorView
	if not _uses_melee_visual() or SafeCamp.in_clearance(global_position):
		melee.clear_melee()
		return
	_sync_melee_weapon()
	var candidate: Node2D = null
	if attack.cooldown_left > 0 and attack.cooldown_left <= MeleeActorView.melee_prepare_time(attack.weapon.interval):
		candidate = attack.select_target(self)
	if candidate != null:
		melee.prepare_melee(candidate.global_position-global_position,attack.cooldown_left,attack.weapon.interval)
	else:
		melee.cancel_melee_preparation()

func _uses_staff_visual() -> bool:
	return view is StaffActorView and view.village_scale and attack.armed and attack.weapon.category == "cajado"

func _clear_staff_visual() -> void:
	if view is StaffActorView: (view as StaffActorView).clear_staff()

func _prepare_staff_visual() -> void:
	if not view is StaffActorView: return
	var staff := view as StaffActorView
	if not _uses_staff_visual() or SafeCamp.in_clearance(global_position):
		staff.clear_staff()
		return
	var candidate: Node2D = null
	if attack.cooldown_left > 0 and attack.cooldown_left <= StaffActorView.staff_prepare_time(attack.weapon.interval):
		candidate = attack.select_target(self)
	if candidate != null:
		staff.prepare_staff(candidate.global_position-global_position,attack.cooldown_left,attack.weapon.interval)
	else:
		staff.cancel_channel()

func _uses_bow_visual() -> bool:
	return view is BowActorView and view.village_scale and attack.armed and attack.weapon.category == "arco"

func _clear_bow_visual() -> void:
	if view is BowActorView: (view as BowActorView).clear_bow()

func _prepare_bow_visual() -> void:
	if not view is BowActorView: return
	var bow := view as BowActorView
	if not _uses_bow_visual() or SafeCamp.in_clearance(global_position):
		bow.clear_bow()
		return
	var candidate: Node2D = null
	if attack.cooldown_left > 0.0 and attack.cooldown_left <= BowActorView.prepare_time(attack.weapon.interval):
		candidate = attack.select_target(self)
	if candidate != null:
		bow.prepare_bow(candidate.global_position-global_position,attack.cooldown_left,attack.weapon.interval)
	else:
		bow.cancel_bow_preparation()

func _uses_sword_visual() -> bool:
	return view is SwordActorView and view.village_scale and attack.armed and attack.weapon.category == "espada"

func _clear_sword_visual() -> void:
	if view is SwordActorView:
		(view as SwordActorView).clear_sword()

func _prepare_sword_visual() -> void:
	if not view is SwordActorView: return
	var sword_view := view as SwordActorView
	if not _uses_sword_visual() or SafeCamp.in_clearance(global_position):
		sword_view.clear_sword()
		return
	# Read-only anticipation: target selection never spends cooldown or deals damage.
	var candidate: Node2D = null
	if attack.cooldown_left > 0.0 and attack.cooldown_left <= SwordActorView.PREPARE_TIME:
		candidate = attack.select_target(self)
	if candidate != null:
		sword_view.prepare_sword(candidate.global_position-global_position,attack.cooldown_left)
	else:
		sword_view.cancel_preparation()

func receive_damage(amount: int, damage_type: String = "physical") -> void:
	if SafeCamp.in_clearance(global_position) or not health.is_alive() or amount <= 0:
		return
	var reduced := RPGRules.received_damage(amount,damage_type,armor,resistance)
	reduced = class_combat.receive(reduced) if progress != null else reduced
	var before := health.current
	health.damage(reduced)
	view.show_damage(before - health.current)

func apply_progression(value: GameProgress, initial: bool = false) -> void:
	progress = value
	attack.armed = not progress.active_category().is_empty()
	if not attack.armed:
		view.attack_left = 0.0
	class_combat.bind(self,progress)
	_sync_skill_cooldowns()
	var values := progress.combat_stats()
	stats.max_hp = int(values.hp)
	stats.move_speed = float(values.speed)
	attack.weapon.damage = int(values.damage)
	stats.dash_speed = 620.0
	physical_damage = int(values.physical)
	resistance = float(values.resistance)
	special_bonus = 1.0+float(values.automatic)+float(values.special)
	attack.damage_base = float(values[values.damage_type])
	attack.basic_bonus = 1.0+float(values.automatic)+float(values.basic)
	attack.critical_chance = float(values.critical_chance)
	attack.critical_multiplier = float(values.critical_multiplier)
	attack.damage_type = values.damage_type
	var configuration := ArsenalRules.profile(progress.equipped.Arma)
	attack.weapon.category = progress.active_category()
	if view is Skill1GameView and view.skill_category != attack.weapon.category:
		_cancel_skill1()
		view.configure(attack.weapon.category)
	elif view is Skill1GameView and view.skill_config.is_empty():
		view.configure(attack.weapon.category)
	if not _uses_sword_visual(): _clear_sword_visual()
	if not _uses_bow_visual(): _clear_bow_visual()
	if not _uses_staff_visual(): _clear_staff_visual()
	_sync_melee_weapon()
	attack.weapon.reach = configuration.reach + (20.0 if class_combat.has_passive("alcance_treinado") else 0.0)
	attack.weapon.projectile_kind = configuration.projectile
	attack.weapon.projectile_speed = configuration.speed
	attack.weapon.interval = configuration.interval * float(values.basic_interval_factor)
	spirit = int(values.spirit)
	armor = int(values.armor)
	cooldown_factor = float(values.cooldown)
	for i in range(3):
		skill_ranks[i] = progress.skill_rank(i)
	if initial:
		health.initialize(stats.max_hp)
	else:
		# Repeated equip/unequip cannot heal or revive the player.
		health.maximum = stats.max_hp
		health.current = mini(health.current, health.maximum)
		health.changed.emit(health.current, health.maximum)

func use_skill(index: int) -> bool:
	if index < 0 or index >= 3 or progress == null or input_driver == null or input_driver.blocked or not health.is_alive() or SafeCamp.in_clearance(global_position): return false
	if index == 0 and view is Skill1GameView and view.village_scale and not view.skill_config.is_empty():
		if skill1_pending > 0 or float(progress.abilities.skill1_cooldowns[progress.active_category()]) > 0: return false
		var rule := AbilityRules.skill1(progress.equipped.Arma)
		if rule.is_empty(): return false
		if AbilityRules.effect(rule.id).shape == "projectile" and get_tree().get_nodes_in_group("player_projectiles").size() >= PlayerProjectile.MAX_ACTIVE: return false
		skill1_pending_category = progress.active_category()
		skill1_pending_direction = last_direction
		if AbilityRules.effect(rule.id).shape == "projectile":
			var reach := float(AbilityRules.effect(rule.id).reach)+(20.0 if class_combat.has_passive("alcance_treinado") else 0.0)
			var nearest_squared := reach*reach
			for candidate in get_tree().get_nodes_in_group("damageable_enemies"):
				if not candidate is EnemyActor or not candidate.is_targetable() or not class_combat._visible(candidate): continue
				var distance := global_position.distance_squared_to(candidate.global_position)
				if distance <= nearest_squared:
					nearest_squared = distance
					skill1_pending_direction = global_position.direction_to(candidate.global_position)
		skill1_pending = float(view.skill_config.prepare)
		view.prepare_skill1(skill1_pending_direction,0)
		_sync_skill_cooldowns()
		return true
	var used := class_combat.use(index)
	_sync_skill_cooldowns()
	return used

func _sync_skill_cooldowns() -> void:
	if progress == null: return
	var category := progress.active_category()
	if category.is_empty():
		skill_cooldowns = [0.0,0.0,0.0]
		return
	skill_cooldowns[0] = maxf(skill1_pending,float(progress.abilities.skill1_cooldowns[category]))
	for i in range(1,3):
		var id: String = progress.abilities.loadouts[category].skills[i-1]
		skill_cooldowns[i] = float(progress.abilities.cooldowns[category].get(id,0.0))

func skill_ready(index: int) -> bool:
	if progress == null or progress.active_category().is_empty(): return false
	if index == 0: return skill_cooldowns[0] <= 0
	var category := progress.active_category()
	var id: String = progress.abilities.loadouts[category].skills[index-1]
	if id.is_empty(): return false
	if id == AbilityRules.CATEGORIES[category].ultimate.id:
		return int(progress.abilities.charge[category]) == 100 and (progress.abilities.global_ultimate_cooldown == 0 or progress.abilities.last_ultimate_category == category)
	return skill_cooldowns[index] <= 0

func _on_attack(target: Node2D) -> void:
	# Snapshot the selected target, independently of movement/dash facing.
	if _uses_sword_visual():
		(view as SwordActorView).play_sword_attack(target.global_position-global_position,attack.weapon.interval)
	elif _uses_melee_visual():
		_sync_melee_weapon()
		(view as MeleeActorView).play_melee(target.global_position-global_position,attack.weapon.interval)
	elif _uses_staff_visual():
		(view as StaffActorView).play_staff_attack(target.global_position-global_position,attack.weapon.interval)
	elif _uses_bow_visual():
		(view as BowActorView).play_bow_attack(target.global_position-global_position,attack.weapon.interval)
	else:
		_cancel_skill1()
		_clear_sword_visual()
		_clear_bow_visual()
		_clear_staff_visual()
		_clear_melee_visual()
		view.play_attack(target.global_position-global_position)

func _on_died() -> void:
	class_combat.cancel_technique()
	_cancel_skill1()
	_clear_melee_visual()
	_clear_staff_visual()
	_clear_sword_visual()
	_clear_bow_visual()
	charge_left = 0.0
	fury_left = 0.0
	class_combat.clear_effects()
	if progress != null: progress.abilities.death_reset()
	_sync_skill_cooldowns()
	charge_hits.clear()
	velocity = Vector2.ZERO
	view.set_moving(false)
	if input_driver != null:
		input_driver.reset()
