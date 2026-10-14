extends RefCounted
## Source-pixel landmarks shared by bake, muzzle placement and proportion QA.
const SHOULDERS := [[Vector2(22,27),Vector2(10,27)],[Vector2(9,24),Vector2(22,24)],[Vector2(17,26),Vector2(19,25)],[Vector2(14,26),Vector2(12,25)]]
const HANDS := [
	[Vector2(25,29),Vector2(25,28),Vector2(25,27),Vector2(25,26),Vector2(26,27),Vector2(25,27),Vector2(25,28),Vector2(25,29)],
	[Vector2(7,28),Vector2(7,27),Vector2(7,26),Vector2(7,25),Vector2(6,24),Vector2(7,26),Vector2(7,27),Vector2(7,28)],
	[Vector2(12,28),Vector2(11,27),Vector2(10,26),Vector2(10,25),Vector2(9,26),Vector2(10,26),Vector2(11,27),Vector2(12,28)],
	[Vector2(20,28),Vector2(21,27),Vector2(22,26),Vector2(22,25),Vector2(23,26),Vector2(22,26),Vector2(21,27),Vector2(20,28)]]
const TIPS := [
	[Vector2(3,-16),Vector2(6,-10),Vector2(7,-5),Vector2(7,3),Vector2(7,4),Vector2(6,-5),Vector2(4,-12),Vector2(3,-16)],
	[Vector2(-4,-16),Vector2(-6,-15),Vector2(-8,-14),Vector2(-9,-13),Vector2(-10,-12),Vector2(-8,-14),Vector2(-6,-15),Vector2(-4,-16)],
	[Vector2(-5,-15),Vector2(-8,-13),Vector2(-11,-11),Vector2(-12,-10),Vector2(-13,-9),Vector2(-10,-12),Vector2(-7,-14),Vector2(-5,-15)],
	[Vector2(6,-15),Vector2(8,-13),Vector2(11,-11),Vector2(12,-10),Vector2(13,-9),Vector2(10,-12),Vector2(7,-14),Vector2(6,-15)]]
const FREE_HANDS := [
	[Vector2(10,30),Vector2(11,29),Vector2(12,28),Vector2(12,27),Vector2(13,28),Vector2(12,29),Vector2(11,30),Vector2(10,31)],
	[Vector2(22,29),Vector2(21,28),Vector2(21,27),Vector2(21,26),Vector2(20,27),Vector2(21,28),Vector2(22,29),Vector2(22,30)],
	[Vector2(18,30),Vector2(18,29),Vector2(17,28),Vector2(17,27),Vector2(16,28),Vector2(17,29),Vector2(18,30),Vector2(19,31)],
	[Vector2(13,30),Vector2(13,29),Vector2(14,28),Vector2(14,27),Vector2(15,28),Vector2(14,29),Vector2(13,30),Vector2(12,31)]]
static func muzzle(row: int) -> Vector2:
	return (HANDS[row][4]+TIPS[row][4]-Vector2(16,32))*2.0
