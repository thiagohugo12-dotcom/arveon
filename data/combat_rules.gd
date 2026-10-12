class_name CombatRules
extends RefCounted

# Injectable randomness for deterministic combat QA; runtime uses one roll/hit.
static var random_roll_source := Callable()
static var _event_sequence := 0

static func next_event() -> int:
	_event_sequence += 1
	return _event_sequence

static func roll() -> float:
	return float(random_roll_source.call()) if random_roll_source.is_valid() else randf()

static func resolve(base: float, bonus: float, multiplier: float, chance: float, critical_multiplier: float, random_value: float) -> Dictionary:
	var critical := random_value < clampf(chance,0.0,0.15)
	var amount := maxf(0.0,base) * clampf(bonus,1.0,1.295) * maxf(0.0,multiplier)
	if critical: amount *= clampf(critical_multiplier,1.5,1.8)
	return {"damage":roundi(amount),"critical":critical}
