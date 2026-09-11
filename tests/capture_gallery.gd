extends SceneTree
var ui

func _init():
 call_deferred("run")

func frames():
 await process_frame
 await process_frame

func offer(id: int):
 for old in ui.game.state.shop:
  if int(old) != 0:
   ui.game.state.pool[str(int(old))] += 1
 ui.game.state.shop = [id,0,0,0,0]
 ui.game.state.pool[str(id)] -= 1

func capture(name: String):
 await frames()
 await RenderingServer.frame_post_draw
 var error = root.get_texture().get_image().save_png("res://docs/"+name+".png")
 print("GALLERY ",name,": ",error," overflows=",ui.label_overflows().size())
 if not ui.label_overflows().is_empty():
  print(ui.label_overflows())

func run():
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/gallery-save.json"
 root.add_child(ui)
 await frames()
 ui.game = ui.MatchModel.new(1337)
 for unit in ui.game.state.units.duplicate():
  ui.game.command({"type":"sell","uid":unit.uid})
 ui.game.state.level = 8
 ui.game.state.round = 16
 ui.game.state.wins = 15
 ui.game.state.gold = 250
 ui.game._make_enemy()
 var ids = [7,115,147,172,150,131,113,123]
 var positions = [2,4,3,9,11,16,18,5]
 for i in range(ids.size()):
  offer(ids[i])
  ui.game.command({"type":"buy","index":0})
  var unit = ui.game.state.units.back()
  ui.game.command({"type":"move","uid":unit.uid,"zone":"board","slot":positions[i]})
 offer(81)
 ui.game.command({"type":"buy","index":0})
 # Use real purchases/merges to show names matching evolved sprites.
 for id in [7,7,172,172,81,81]:
  offer(id)
  ui.game.command({"type":"buy","index":0})
 for old in ui.game.state.shop:
  if old != 0:
   ui.game.state.pool[str(int(old))] += 1
 ui.game.state.shop = [131,150,145,58,113]
 for id in ui.game.state.shop:
  ui.game.state.pool[str(int(id))] -= 1
 ui.game.state.gold = 48
 ui.selected = ui.game.at("board",11).uid
 ui.game._ensure_augments()
 await capture("v3-augment-choice")
 while not ui.game.state.augment_offers.is_empty():
  ui.game.command({"type":"augment","index":0})
 await capture("pixel-lategame")
 var at_pos = ui.slot_rect("bench",0).get_center()
 var press = InputEventMouseButton.new()
 press.button_index = MOUSE_BUTTON_LEFT
 press.pressed = true
 ui._pointer_input(press,at_pos)
 var motion = InputEventMouseMotion.new()
 ui._pointer_input(motion,ui.slot_rect("board",2).get_center())
 await capture("pixel-drag")
 ui._cancel_drag()
 ui.effects.clear()
 ui.game.command({"type":"battle"})
 ui._replay()
 ui.paused = true
 # Select an actual ability frame for the screenshot, no fabricated events.
 for i in range(ui.playback.frames.size()):
  var frame = ui.playback.frames[i]
  if frame.events.any(func(e): return e.kind == "cast" and int(e.species) == 150):
   ui.frame_index = i
   ui._frame_effects(frame)
   for effect in ui.effects:
    effect.age = minf(0.25,effect.duration*0.4)
   break
 for unit in ui.playback.frames[ui.frame_index].units:
  if unit.species == 150 and unit.side == 0:
   ui.inspected = unit.duplicate(true)
 await capture("pixel-abilities")
 ui._finish_playback()
 ui.game = ui.MatchModel.new(21)
 ui.game._settle(1)
 ui._finish_playback()
 await capture("pixel-loss")
 ui.help_open = true
 await capture("pixel-help")
 ui.queue_free()
 await process_frame
 quit()
