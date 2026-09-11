extends SceneTree
var ui
var passed=0
var failed=0
func _init():call_deferred("run")
func check(ok,label):
 if ok:passed+=1
 else:failed+=1;printerr("FAIL V8 UI "+label)
func frames():
 await process_frame
 await process_frame
func run():
 ui=load("res://ui/main.tscn").instantiate()
 ui.save_path="res://tests/v8-ui-save.json"
 root.add_child(ui)
 await frames()
 ui.start_open=false
 ui.game=ui.MatchModel.new(1)
 for resolution in [Vector2i(1280,720),Vector2i(1600,800),Vector2i(1920,1080)]:
  root.size=resolution
  await frames()
  for type in ui.catalog.trait_descriptions:
   ui.trait_open=type
   await frames()
   check(ui.label_overflows().is_empty(),"Trait modal fits "+type+str(ui.label_overflows()))
   check(ui.slots.is_empty(),"Trait modal blocks drop targets")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/v8-traits-%d.png" % resolution.x)
  ui.trait_open=""
  ui.game.state.gold=0
  ui.game.state.shop=ui.catalog.roster.filter(func(m):return m.cost==5).slice(0,5).map(func(m):return m.id)
  await frames()
  check(ui.label_overflows().is_empty(),"Unaffordable prices fit")
  check(ui.text_boxes.any(func(t):return "fehlt" in t.text),"Affordability independent of color")
 # Actual field overlays, stacked states and overcharge mana.
 var b=preload("res://core/battle.gd").new()
 var u={"uid":1,"species":1,"star":3,"slot":3,"zone":"board"}
 var fighters=b.prepare([u],[{"uid":2,"species":4,"star":3,"slot":3,"zone":"board"}],0)
 fighters[0].growth=20;fighters[0].heat=5;fighters[0].spirit=10;fighters[0].toxin=10;fighters[0].blessed=true;fighters[0].unstoppable_until=90
 fighters[0].mana=120;fighters[0].cast_threshold=130;fighters[0].shield=100
 fighters[0].traits={"Wasser":8};b.traits.after_cast(b,fighters[0],fighters[1],fighters)
 var frame={"units":fighters,"events":[],"tick":10,"fields":b.traits.fields}
 ui.playback={"before":ui.game.snapshot(),"round":1,"frames":[frame]};ui.paused=true;ui.inspected=fighters[0];ui.frame_index=0
 await frames()
 check(ui.label_overflows().is_empty(),"Stacked combat states fit "+str(ui.label_overflows()))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/v8-fields.png")
 print("V8 UI: %d passed, %d failed" % [passed,failed])
 ui.queue_free();await process_frame
 quit(1 if failed else 0)
