extends SceneTree
var ui
var passed = 0
var failed = 0
func _init(): call_deferred("run")
func check(ok,label):
 if ok: passed += 1
 else:
  failed += 1
  printerr("FAIL PERSPECTIVE: "+label)
func frames():
 await process_frame
 await process_frame
func touch(point,pressed):
 var event = InputEventScreenTouch.new()
 event.index = 0
 event.position = point
 event.pressed = pressed
 ui._input(event)
 await frames()
func run():
 root.size = Vector2i(1280,720)
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/perspective-save.json"
 root.add_child(ui)
 await frames()
 ui.start_open = false
 ui.game = ui.MatchModel.new(1337)
 await frames()
 var uid = ui.game.at("board",2).uid
 await touch(ui.slot_rect("board",2).get_center(),true)
 var motion = InputEventScreenDrag.new()
 motion.index = 0
 motion.position = ui.slot_rect("bench",0).get_center()
 ui._input(motion)
 await frames()
 check(ui.drag_uid == uid,"Touch drag starts")
 await touch(motion.position,false)
 check(ui.game.at("bench",0).uid == uid,"Touch commits projected board to flat bank")
 # A resize during the gesture uses the new projection, preserving the original unit.
 await touch(ui.slot_rect("bench",0).get_center(),true)
 motion.position += Vector2(10,10)
 ui._input(motion)
 root.size = Vector2i(1920,1080)
 await frames()
 motion.position = ui.project_grid(6.5,5.5)
 ui._input(motion)
 await touch(motion.position,false)
 check(ui.game.at("board",20).uid == uid,"Active touch drag survives resize")
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1080)]:
  root.size = resolution
  ui.game = ui.MatchModel.new(77)
  ui.game.command({"type":"battle"})
  ui._replay()
  ui.paused = true
  ui.frame_index = mini(40,ui.playback.frames.size()-1)
  ui._frame_effects(ui.playback.frames[ui.frame_index])
  await frames()
  for i in range(1,ui.depth_order.size()): check(ui.depth_order[i] >= ui.depth_order[i-1],"Combat sprites sorted by interpolated depth")
  check(ui.label_overflows().is_empty(),"Battle labels fit "+str(resolution))
  for e in ui.effects:
   if not e.has("event"): continue
   var r = ui._sprite_area(ui.world_rect(Vector2(e.event.tx,e.event.ty)))
   var target_rect = ui.world_rect(Vector2(e.event.tx,e.event.ty))
   var meta_top = target_rect.end.y-(26 if target_rect.size.y<78 else 43)
   check(r.end.y <= meta_top,"Hit region is above target health/name")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/scene-%dx%d.png" % [resolution.x,resolution.y])
 root.mode = Window.MODE_FULLSCREEN
 await create_timer(0.5).timeout
 await frames()
 check(ui.size == Vector2(root.size),"Fullscreen uses actual viewport extent")
 ui.playback = {}
 ui.game = ui.MatchModel.new(77)
 await frames()
 var point = ui.project_grid(3.5,4.5)
 check(ui._slot_at(point).slot == 10,"Fullscreen polygon hit testing")
 uid = ui.game.at("board",2).uid
 await touch(ui.slot_rect("board",2).get_center(),true)
 motion.position = ui.slot_rect("bench",0).get_center()
 ui._input(motion)
 await touch(motion.position,false)
 check(ui.game.at("bench",0).uid == uid,"Drag commits in real fullscreen")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/scene-fullscreen.png")
 root.mode = Window.MODE_WINDOWED
 print("PERSPECTIVE: %d passed, %d failed" % [passed,failed])
 ui.queue_free()
 await process_frame
 quit(1 if failed else 0)
