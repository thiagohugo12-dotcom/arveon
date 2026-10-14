extends "res://tools/melee_pose_rig.gd"
## Build-time proportion guard shared by all five Skill 1 rigs.
var max_arm_span := 0.0
func arm(shoulder: Vector2,elbow: Vector2,hand: Vector2) -> void:
	max_arm_span = maxf(max_arm_span,shoulder.distance_to(hand))
	assert(shoulder.distance_to(hand) <= 12,"Skill 1 arm exceeds approved compact proportions")
	super.arm(shoulder,elbow,hand)
