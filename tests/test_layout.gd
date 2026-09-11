extends SceneTree
var ui
var passed = 0
var failed = 0
func _init(): call_deferred("run")
func check(ok: bool, label: String):
 if ok: passed += 1
 else:
  failed += 1
  if failed < 8: printerr(label)
func frames():
 await process_frame
 await process_frame
func audit(panel: Rect2, label: String):
 var boxes = ui.text_boxes.filter(func(b): return b.has("painted") and panel.has_point(b.rect.get_center()))
 for a in range(boxes.size()):
  check(panel.grow(-3).encloses(boxes[a].painted),label+" panel boundary: "+boxes[a].text)
  for b in range(a+1,boxes.size()):
   check(not boxes[a].painted.intersects(boxes[b].painted),label+" overlapping text: "+boxes[a].text+" / "+boxes[b].text)
func run():
 create_timer(100).timeout.connect(func(): quit(2))
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/layout-save-test.json"
 root.add_child(ui)
 await frames()
 ui.start_open = false
 ui.game = ui.MatchModel.new(99)
 for resolution in [Vector2i(1280,720),Vector2i(1366,768),Vector2i(1600,720),Vector2i(1600,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
  root.size = resolution
  await frames()
  for entry in ui.catalog.roster:
   ui.selected = -1
   ui.inspected = {"uid":999,"species":int(entry.id),"star":3,"slot":0,"zone":"bench"}
   ui.game.state.shop = [int(entry.id),int(entry.id),0,0,0]
   ui.game.state.units = [{"uid":999,"species":int(entry.id),"star":3,"slot":0,"zone":"bench"}]
   await frames()
   check(ui.label_overflows().is_empty(),str(resolution)+": "+str(ui.label_overflows()))
   audit(ui.layout.info,"Details "+entry.name)
   var bank = ui.slot_rect("bench",0)
   audit(bank.grow(-3),"Bank "+entry.name)
   for region in ui.metadata_regions:
    if bank.has_point(region.get_center()): check(bank.grow(-6).encloses(region),"Bank metadata covers frame: "+entry.name)
   audit(ui.shop_rect(0),"Shop "+entry.name)
   ui.game.state.discount_ready = true
   await frames()
   check(ui.label_overflows().is_empty(),"Discount labels: "+entry.name)
   audit(ui.shop_rect(0),"Discount "+entry.name)
   ui.game.state.discount_ready = false
   var card = ui.shop_rect(0)
   var sprite = Rect2(card.position+Vector2(6,32),Vector2(card.size.x*0.31,card.size.y-40))
   for box in ui.text_boxes:
    if box.has("painted") and card.has_point(box.rect.get_center()): check(not sprite.intersects(box.painted),"Shop sprite overlap: "+box.text)
  check(not ui.layout.info.intersects(ui.layout.actions),"Panels stay separate")
  if not ui.compact:
   check(ui.layout.result.size.y >= 110,"Result panel has enough height")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/ui-v7-%dx%d.png" % [resolution.x,resolution.y])
 print("LAYOUT V7: %d passed, %d failed" % [passed,failed])
 ui.queue_free()
 await process_frame
 quit(1 if failed else 0)
