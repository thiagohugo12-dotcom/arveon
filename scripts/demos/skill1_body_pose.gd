extends RefCounted
## Source-grid acting landmarks. Visual only; physical feet never move.
const AIM := [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
const PROFILES := {
 "espada":{"travel":[0,-1,-2,4,5,3,1,0],"crouch":[0,1,2,0,1,2,1,0],"lean":[0,-1,-2,3,4,2,1,0],"twist":[0,-1,-2,3,2,0,-1,0],"step":[0,0,-1,4,4,3,1,0]},
 "machado":{"travel":[0,-1,-1,2,3,2,1,0],"crouch":[0,-1,-2,3,4,3,1,0],"lean":[0,-1,-1,3,4,2,1,0],"twist":[0,0,-1,1,1,0,0,0],"step":[0,0,0,2,3,2,1,0]},
 "lanca":{"travel":[0,-2,-3,5,6,4,1,0],"crouch":[0,1,2,0,1,2,1,0],"lean":[0,-1,-2,4,4,2,1,0],"twist":[0,-1,-1,1,1,0,0,0],"step":[0,-1,-2,5,6,4,1,0]},
 "arco":{"travel":[0,-1,-2,-3,-1,0,0,0],"crouch":[0,1,1,1,2,1,0,0],"lean":[0,-1,-2,-3,-1,0,0,0],"twist":[0,-1,-2,2,1,0,0,0],"step":[0,0,-1,-2,-1,0,0,0]},
 "cajado":{"travel":[0,-1,-2,3,2,1,0,0],"crouch":[0,1,1,0,1,1,0,0],"lean":[0,-1,-2,3,2,1,0,0],"twist":[0,-1,-2,2,1,0,0,0],"step":[0,0,-1,2,2,1,0,0]}}
static func point(p: Vector2,category: String,row: int,frame: int) -> Vector2:
 var profile: Dictionary=PROFILES[category]
 var travel: float=0 if category=="machado" and row<2 else profile.travel[frame]
 var offset: Vector2=AIM[row]*travel+Vector2(0,profile.crouch[frame])
 var lean: float=profile.lean[frame]*AIM[row].x if row>=2 else profile.twist[frame]
 var weight:=0.75 if p.y<24 else clampf((31-p.y)/16.0,0,0.75)
 return (p+offset+Vector2(lean*weight,0)).round()
static func leg_point(p: Vector2,category: String,row: int,frame: int) -> Vector2:
 var leading:=p.x>=16 if row in [0,3] else p.x<16
 var step: float=PROFILES[category].step[frame] if leading else 0
 var spread:=Vector2((-1 if p.x<16 else 1),0) if row<2 and frame in [2,3,4,5] else Vector2.ZERO
 return (p+AIM[row]*step+spread).round()
static func muzzle(category: String,row: int) -> Vector2:
 var original: Vector2=preload("res://scripts/demos/staff_pose_data.gd").muzzle(row) if category=="cajado" else BowActorView.MUZZLES[row]
 if category=="arco" and row==1:original=Vector2(-18,-28)
 return (point(original/2+Vector2(16,32),category,row,3)-Vector2(16,32))*2
