class_name SwordTechniqueTiming
extends RefCounted
## Shared physics clock: drawing and damage use the same contact boundary.
const FRAMES := {
	"estocada_precisa": [0.04,0.06,0.035,0.045,0.055,0.10],
	"danca_laminas": [0.07,0.10,0.045,0.065,0.075,0.13]
}
const CONTACT_FRAME := 3
static func contact(id: String) -> float:
	var result := 0.0
	for i in range(CONTACT_FRAME): result += FRAMES[id][i]
	return result
static func duration(id: String) -> float:
	var result := 0.0
	for value in FRAMES[id]: result += value
	return result
static func frame(id: String, time: float) -> int:
	var boundary := 0.0
	for i in range(5):
		boundary += FRAMES[id][i]
		if time < boundary-0.000001: return i
	return 5
