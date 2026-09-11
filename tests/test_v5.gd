extends SceneTree
var ui
var passed = 0
var failed = 0
func _init(): call_deferred("run")
func check(ok,label):
 if ok: passed += 1
 else:
  failed += 1
  printerr("FAIL V5: "+label)
func frames():
 await process_frame
 await process_frame
func run():
 root.size = Vector2i(1920,1080)
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/v5-save.json"
 root.add_child(ui)
 await frames()
 ui.start_open = false
 ui.game = ui.MatchModel.new(1337)
 await frames()
 check(ui.idle.size() == 143,"All 143 evolution sprites have animations")
 for id in ui.idle:
  var a = ui.idle[id]
  check(a.frames >= 2 and a.ends.size() == a.frames,"Multiple timed frames "+str(id))
  check(ui.idle_frame(id,0) == 0 and ui.idle_frame(id,a.total+0.001) == 0,"Loop wraps "+str(id))
  check(ui.idle_frame(id,a.ends[0]+0.001) == 1,"Source timing advances "+str(id))
  check(a.texture.get_width() == a.width*a.columns and a.texture.get_height() >= a.height*ceil(a.frames/float(a.columns)),"Fixed frame canvas fits atlas "+str(id))
 for mon in ui.catalog.roster:
  for star in [1,2,3]:
   check(ui.idle.has(ui.catalog.sprite_id({"species":mon.id,"star":star})),"Correct evolution animation "+mon.name)
 check(ui.arena_color(1,false) != ui.arena_color(4,false),"Team halves have distinct floor colors")
 for y in range(3):
  for x in range(7): check(ui._slot_at(ui.project_grid(x+0.5,y+0.5)).is_empty(),"Enemy tile not placeable")
 ui.drag_uid = ui.game.at("board",2).uid
 ui.drag_unit = ui.game.at("board",2).duplicate(true)
 ui.drag_revision = ui.game.state.revision
 await frames()
 for slot in ui.valid_drag_slots:
  check(ui.game.validate_move(ui.drag_uid,slot.zone,slot.slot).ok,"Highlight agrees with actual placement rules")
 ui._cancel_drag()
 # Stress the renderer with 20 animated fighters and overlapping spell events.
 var own = []
 var enemy = []
 for i in range(10):
  own.append({"uid":i+1,"species":ui.catalog.roster[i].id,"star":3,"zone":"board","slot":i})
  enemy.append({"uid":i+1,"species":ui.catalog.roster[i+20].id,"star":3,"zone":"board","slot":i})
 var fighters = preload("res://core/battle.gd").new().prepare(own,enemy,1)
 var frame = {"units":fighters,"events":[],"tick":0}
 ui.playback = {"before":ui.game.snapshot(),"round":1,"frames":[frame]}
 ui.paused = true
 ui.frame_index = 0
 var times = []
 for i in range(120):
  if i%8 == 0:
   for u in fighters:
    ui._frame_effects({"units":fighters,"events":[{"kind":"cast","from":u.uid,"to":u.uid,"sx":u.x,"sy":u.y,"tx":u.x,"ty":u.y,"species":u.species,"target_species":u.species,"star":u.star,"amount":0,"spell":"Test"}]})
  for effect in ui.effects: effect.age = 0.35
  var start = Time.get_ticks_usec()
  await process_frame
  times.append((Time.get_ticks_usec()-start)/1000.0)
 times.sort()
 print("20-unit / repeated 20-cast render: median %.1f ms, p95 %.1f ms" % [times[60],times[114]])
 print("Draw CPU ms: ",ui.draw_usec/1000.0,"; calls: ",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
 print("Draw stages us: ",ui.draw_profile)
 check(ui.label_overflows().is_empty(),"Stress fight labels fit")
 check(ui.effects.size() <= 220,"Effect list remains bounded")
 check(ui.text_boxes.any(func(t): return t.text == "Dein Team") and ui.text_boxes.any(func(t): return t.text == "Gegner"),"Team labels visible in combat")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/v5-stress.png")
 ui.effects.clear()
 var idle_times = []
 for i in range(60):
  var start = Time.get_ticks_usec()
  await process_frame
  idle_times.append((Time.get_ticks_usec()-start)/1000.0)
 idle_times.sort()
 print("20 animated units without cast burst: median %.1f ms, p95 %.1f ms" % [idle_times[30],idle_times[57]])
 # Missing optional atlas retains a working static sprite.
 var saved = ui.idle[1]
 ui.idle.erase(1)
 check(ui.textures.has(1) and ui.idle_frame(1,2) == 0,"Missing animation uses static fallback")
 await frames()
 ui.idle[1] = saved
 print("V5: %d passed, %d failed" % [passed,failed])
 ui.queue_free()
 await process_frame
 quit(1 if failed else 0)
