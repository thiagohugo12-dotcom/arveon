extends "res://tools/melee_pose_rig.gd"
## Whole-body acting on the source pixel grid; no global sprite squash/rotation.
const BODY := preload("res://scripts/demos/skill1_body_pose.gd")
var category := "espada"
var include_legs := true
var max_arm_span := 0.0
func source_point(p: Vector2) -> Vector2: return BODY.point(p,category,row,frame)
func line(a: Vector2,b: Vector2,color: Color,width: float=1.0) -> void:
 draw_line(source_point(a),source_point(b),color,width,false)
func pixel_mark(rect: Rect2,color: Color) -> void:
 draw_rect(Rect2(source_point(rect.position),rect.size),color)
func polygon_at(origin: Vector2,axis: Vector2,points: Array,color: Color) -> void:
 var vertices:=PackedVector2Array()
 for p: Vector2 in points:vertices.append(source_point(origin+axis*p.x+axis.orthogonal()*p.y))
 draw_colored_polygon(vertices,color)
func arm(shoulder: Vector2,elbow: Vector2,hand: Vector2) -> void:
 max_arm_span=maxf(max_arm_span,shoulder.distance_to(hand))
 assert(shoulder.distance_to(hand)<=12,"Skill 1 arm exceeds approved compact proportions")
 line(shoulder,elbow,Color("#382b25"),4)
 line(elbow,hand,Color("#382b25"),4)
 line(shoulder,elbow,Color("#ce673b"),2)
 line(elbow,hand,Color("#efbd84"),2)
 pixel_mark(Rect2(hand.round()-Vector2.ONE,Vector2(3,3)),Color("#f7d39b"))
func pixel(x: int,y: int,legs: bool=false) -> void:
 var p:=BODY.leg_point(Vector2(x,y),category,row,frame) if legs else source_point(Vector2(x,y))
 draw_texture_rect_region(PEOPLE,Rect2(p,Vector2.ONE),Rect2(x,row*40+y,1,1))
func _draw() -> void:
 draw_set_transform(Vector2(-16,-32))
 # Articulated thighs bridge the acted hips and planted boots, including a raised torso.
 for x in [14,19]:
  var hip:=source_point(Vector2(x,31))
  var ankle:=BODY.leg_point(Vector2(x,37),category,row,frame)
  var knee:=hip.lerp(ankle,0.55).round()+Vector2(-1 if x==14 else 1,0)
  draw_line(hip,knee,Color("#382b25"),4,false)
  draw_line(knee,ankle,Color("#382b25"),4,false)
  draw_line(hip,knee,Color("#805330"),2,false)
  draw_line(knee,ankle,Color("#805330"),2,false)
 if include_legs:
  for y in range(36,40):
   for x in range(32):pixel(x,y,true)
 if row==1:bow_parts()
 var holes: Array=[Rect2(7,24,6,8),Rect2(21,24,5,8)] if row<2 else [Rect2(16 if row==2 else 11,26,5,6)]
 for y in range(32):
  for x in range(32):
   var removed:=false
   for hole: Rect2 in holes:removed=removed or hole.has_point(Vector2(x,y))
   if not removed:pixel(x,y)
 if row!=1:bow_parts()
 # Keep the approved hair/face/scarf pixels, now following the acted head pose.
 for y in range(24):
  for x in range(32):pixel(x,y)
 for y in range(24,27):
  for x in range(13,20):pixel(x,y)
 draw_set_transform(Vector2.ZERO)
