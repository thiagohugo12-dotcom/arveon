extends EnemyActor
var enabled := true
var hits := 0
var total_damage := 0

func _ready() -> void:
	super._ready()
	health.initialize(1000000)
	health.changed.connect(func(current: int, _maximum: int):
		var loss := 1000000-current
		if loss > total_damage:
			hits += 1
			total_damage = loss)
	set_physics_process(false)

func is_targetable() -> bool: return enabled and health.is_alive()
