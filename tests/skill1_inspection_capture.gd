extends "res://tests/bow_demo_capture.gd"
func _initialize() -> void:
 create_timer(90).timeout.connect(func():quit(1))
 call_deferred("run")
func run() -> void:
 var output:=OS.get_environment("QA_RENDER_DIR")
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(960,760);root.content_scale_size=root.size
 var demo=load("res://scenes/demos/skill1_review.tscn").instantiate()
 root.add_child(demo);demo.set_process(false);demo.visual_loop=false
 var failed:=0
 for category in demo.CATALOGUE.ORDER:
  demo.select_category(category)
  for row in range(4):
   demo.select_direction(row)
   for phase in range(3):
    demo.execute_visual_skill()
    var prepare: float=demo.CATALOGUE.CONFIGS[category].prepare
    var duration: float=demo.CATALOGUE.CONFIGS[category].duration
    var desired: float=[prepare*0.75,prepare+0.001,prepare+duration*0.30][phase]
    while demo.visual_time+0.005<desired:demo.step_inspection(minf(0.005,desired-demo.visual_time))
    demo.step_inspection(maxf(0,desired-demo.visual_time))
    # Pump rendering only. No pose override: the actual inspection timeline supplies frames.
    await process_frame;await process_frame
    demo._process(0)
    await capture(output,"%s_%d_%d" % [category,row,phase])
    var view=demo.players[1].view
    if view.displayed_skill1_atlas!=demo.CATALOGUE.CONFIGS[category].atlas or view.displayed_skill1_frame<0:failed+=1
    print("INSPECTION_RENDER: ",category," row=",row," phase=",phase," drawn_frame=",view.displayed_skill1_frame," atlas=",view.displayed_skill1_atlas)
 for category in ["arco","cajado"]:
  demo.select_category(category)
  for row in range(4):
   demo.select_direction(row);demo.execute_visual_skill()
   var prepare: float=demo.CATALOGUE.CONFIGS[category].prepare
   var desired: float=prepare+80.0/(440.0 if category=="arco" else 260.0)+0.015
   while demo.visual_time+0.005<desired:demo.step_inspection(0.005)
   demo._process(0)
   await process_frame;await capture(output,"%s_%d_hit" % [category,row])
   if demo.targets[1].view.impact_left<=0:failed+=1
 for category in demo.CATALOGUE.ORDER:
  demo.select_category(category)
  for row in range(4):
   demo.select_direction(row);demo.execute_visual_skill()
   for frame in range(32):
    demo.step_inspection(0.04);demo._process(0)
    await process_frame;await capture(output,"cycle_%s_%d_%02d" % [category,row,frame])
 demo.select_category("arco");demo.select_direction(3);demo.automatic_walk=true
 for i in range(24):
  demo.step_inspection(0.025);await process_frame
  await capture(output,"walking_%02d" % i)
 demo._process(0)
 root.size=Vector2i(390,844);root.content_scale_size=root.size;demo._layout()
 demo.execute_visual_skill();demo.step_inspection(0.12)
 await process_frame;await capture(output,"mobile")
 root.size=Vector2i(844,390);root.content_scale_size=root.size;demo._layout()
 await process_frame;await capture(output,"landscape")
 root.size=Vector2i(960,620);root.content_scale_size=root.size;demo._layout()
 await process_frame;await capture(output,"desktop")
 demo.queue_free();await process_frame
 print("INSPECTION_CAPTURE_RESULT: 68 phase/impact captures, 4 directions x 5 skills, %d failures" % failed)
 quit(failed)
