extends RefCounted
## Source-pixel landmarks shared by the baker and review assertions.
const SHOULDERS := [[Vector2(22,27),Vector2(10,27)],[Vector2(9,24),Vector2(22,24)],[Vector2(17,26),Vector2(19,25)],[Vector2(14,26),Vector2(12,25)]]
const AXE_HANDS := [
	[Vector2(24,24),Vector2(24,22),Vector2(25,25),Vector2(25,29),Vector2(24,32),Vector2(24,31),Vector2(24,30),Vector2(24,29)],
	[Vector2(7,23),Vector2(7,21),Vector2(6,22),Vector2(6,25),Vector2(7,28),Vector2(7,28),Vector2(7,27),Vector2(7,26)],
	[Vector2(15,23),Vector2(15,21),Vector2(13,23),Vector2(9,26),Vector2(10,29),Vector2(11,29),Vector2(12,28),Vector2(12,28)],
	[Vector2(16,23),Vector2(16,21),Vector2(18,23),Vector2(22,26),Vector2(21,29),Vector2(20,29),Vector2(20,28),Vector2(20,28)]]
const SPEAR_HAND := [Vector2(24,29),Vector2(7,26),Vector2(12,28),Vector2(20,28)]
const AXE_ANGLES := [-1.65,-1.9,-0.85,-0.12,0.55,0.8,-0.1,-1.2]
const SPEAR_PUSH := [-1.0,-2.0,0.0,3.0,4.0,2.0,0.0,-1.0]
static func hand(kind: int,row: int,frame: int) -> Vector2:
	if kind == 0: return AXE_HANDS[row][frame]
	return SPEAR_HAND[row]+BowActorView.DIRECTIONS[row]*SPEAR_PUSH[frame]
static func axis(kind: int,row: int,frame: int) -> Vector2:
	var aim: Vector2 = BowActorView.DIRECTIONS[row]
	return aim.rotated(AXE_ANGLES[frame]*(1 if row != 2 else -1)) if kind == 0 else aim
