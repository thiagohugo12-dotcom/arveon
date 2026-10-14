extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error("INSPECTION_FAIL: "+message)
func run() -> void:
 root.size=Vector2i(960,620)
 root.content_scale_size=root.size
 var demo=load("res://scenes/demos/skill1_review.tscn").instantiate()
 root.add_child(demo)
 demo.set_process(false)
 check(demo.inspection_mode and demo.visual_speed==1.0,"default isolated normal-speed inspection")
 for category in demo.CATALOGUE.ORDER:
  demo.select_category(category)
  var player=demo.players[1]
  var cooldowns: Dictionary=player.progress.abilities.skill1_cooldowns.duplicate(true)
  var hp: int=demo.targets[1].health.current
  var hits: int=demo.targets[1].hits
  var casts: int=demo.accepted_casts
  var ability_casts: int=player.view.skill1_casts
  var writes: int=player.progress.disk_writes
  for row in range(4):
   demo.select_direction(row)
   demo.visual_loop=false
   demo.execute_visual_skill()
   check(player.view.skill1_preparing and player.view.skill1_row==row,"correct preparation "+category+str(row))
   var observed:=0
   for frame in range(120):
    demo.step_inspection(0.01)
    if player.view.skill1_phase()>=0: observed|=1<<player.view.skill1_frame()
   check(observed==255,"all eight skill frames reached "+category+str(row))
   check(demo.visual_time<0,"recovers from inspection "+category+str(row))
   check(demo.get_tree().get_nodes_in_group("player_projectiles").size()==0,"no real projectiles "+category+str(row))
   for repeat in range(3): demo.execute_visual_skill();demo.step_inspection(0.01)
   check(player.progress.abilities.skill1_cooldowns==cooldowns,"replay never writes cooldown "+category+str(row))
   check(demo.targets[1].health.current==hp and demo.targets[1].hits==hits and demo.accepted_casts==casts,"replay never deals damage or real casts "+category+str(row))
  check(player.view.skill1_casts>ability_casts,"existing special view was invoked "+category)
  check(player.progress.disk_writes==writes,"no journal writes "+category)
  demo._toggle_attacks()
  check(not demo.visual_basics,"basics pause independently")
  demo._toggle_attacks()
  demo._toggle_dex()
  check(demo.visual_speed==0.5,"half speed selected")
  demo._toggle_dex()
  check(demo.visual_speed==1.0,"normal speed selected")
  check(player.progress.attributes.Destreza==0,"speed does not modify Dexterity")
 demo.visual_loop=true
 demo.execute_visual_skill()
 var replays: int=demo.visual_replays
 for frame in range(250): demo.step_inspection(0.01)
 check(demo.visual_replays>replays,"visual loop without real cooldown")
 demo.set_inspection_mode(false)
 check(demo.players[1].is_physics_processing() and demo.players[1].view.is_processing(),"real combat restored independently")
 demo.select_category("arco")
 demo.players[1].progress.abilities.skill1_cooldowns.arco=0
 demo.players[1]._sync_skill_cooldowns()
 check(demo.release_skill1(),"fixture has a real projectile before inspection")
 var projectile=demo.get_tree().get_nodes_in_group("player_projectiles")[0]
 var budget: float=projectile.distance_left
 var active: int=demo.get_tree().get_nodes_in_group("player_projectiles").size()
 var real_cooldown: float=demo.players[1].progress.abilities.skill1_cooldowns.arco
 var health: int=demo.targets[1].health.current
 demo.set_inspection_mode(true)
 for i in range(10):demo.execute_visual_skill();demo.step_inspection(0.25)
 check(demo.get_tree().get_nodes_in_group("player_projectiles").size()==active,"inspection does not add/remove existing real shots")
 check(projectile.distance_left==budget and not projectile.is_physics_processing(),"in-flight real projectile is frozen intact")
 check(demo.players[1].progress.abilities.skill1_cooldowns.arco==real_cooldown and demo.targets[1].health.current==health,"spent real cooldown and health preserved exactly")
 demo.visual_speed=0.5;demo.execute_visual_skill();demo._process(0.1)
 check(is_equal_approx(demo.visual_time,0.05),"half-speed scales only visual timeline")
 demo.set_inspection_mode(false)
 check(projectile.is_physics_processing() and projectile.distance_left==budget,"real shot resumes with same remaining budget")
 projectile.finish()
 demo.queue_free();await process_frame
 print("INSPECTION_RESULT: %d checks, %d failures" % [checks,failures])
 quit(failures)
