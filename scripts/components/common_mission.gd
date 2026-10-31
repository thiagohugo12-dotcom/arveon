class_name CommonMission
extends RefCounted

# Minimal, always-active FREE contracts. No NPC, acceptance cost or cooldown.
# Numbers are temporary, until economy and progression are balanced.
signal completed(xp_reward: int, gold_reward: int)

const NAMES := ["Derrote criaturas", "Colete materiais"]
const TARGETS := [8, 5]
const XP_REWARDS := [40, 30]
const GOLD_REWARDS := [12, 10]

var mission_index: int = 0
var progress: int = 0
var completed_count: int = 0
var enabled := true
# Floor without any material source (today the Pântano): the collection contract is replaced
# by defeats, same target and reward, so the always-active mission never stalls.
var materials_available := true

func summary() -> String:
	return "Missão comum: %s %d/%d" % [NAMES[0 if substituted() else mission_index], progress, TARGETS[mission_index]]

func substituted() -> bool:
	return mission_index == 1 and not materials_available

func record_defeat() -> void:
	if enabled and (mission_index == 0 or substituted()):
		_advance(1)

func record_material(amount: int = 1) -> void:
	if enabled and mission_index == 1 and amount > 0:
		_advance(amount)

func _advance(amount: int) -> void:
	progress = mini(progress + amount, TARGETS[mission_index])
	if progress < TARGETS[mission_index]:
		return
	var earned_xp: int = XP_REWARDS[mission_index]
	var earned_gold: int = GOLD_REWARDS[mission_index]
	completed_count += 1
	mission_index = (mission_index + 1) % NAMES.size()
	progress = 0
	completed.emit(earned_xp, earned_gold)
