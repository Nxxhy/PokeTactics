extends SceneTree
var ui
var passed = 0
var failed = 0

func _init():
 call_deferred("run")

func check(ok: bool,label: String):
 if ok:
  passed += 1
 else:
  failed += 1
  printerr("FAIL UI: "+label)
  if failed < 5 and is_instance_valid(ui): printerr(ui.label_overflows())

func frames():
 await process_frame
 await process_frame

func mouse(point: Vector2,pressed: bool):
 var event = InputEventMouseButton.new()
 event.position = root.get_final_transform()*point
 event.global_position = event.position
 event.button_index = MOUSE_BUTTON_LEFT
 event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
 event.pressed = pressed
 Input.parse_input_event(event)
 await frames()

func motion(point: Vector2):
 var event = InputEventMouseMotion.new()
 event.position = root.get_final_transform()*point
 event.global_position = event.position
 event.button_mask = MOUSE_BUTTON_MASK_LEFT
 Input.parse_input_event(event)
 await frames()

func key(code: int):
 var event = InputEventKey.new()
 event.pressed = true
 event.keycode = code
 Input.parse_input_event(event)
 await frames()

func click(point: Vector2):
 await mouse(point,true)
 await mouse(point,false)

func drag(from: Vector2,to: Vector2):
 await mouse(from,true)
 await motion(from+Vector2(10,10))
 check(ui.drag_uid >= 0,"Pointer movement starts drag")
 await motion(to)
 await mouse(to,false)

func center(zone: String,slot: int) -> Vector2:
 return ui.slot_rect(zone,slot).get_center()

func run():
 create_timer(90).timeout.connect(func(): printerr("UI timeout"); quit(2))
 root.size = Vector2i(1600,800)
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/v2-save-test.json"
 root.add_child(ui)
 await frames()
 ui.start_open = false
 ui.game = ui.MatchModel.new(1337)
 ui.selected = -1
 await frames()
 check(ui.textures.size() == 143,"143 local sprites decode")
 check(ui.heading_font.get_font_name().contains("Power Green"),"Smaragd pixel font loaded")
 check(ui.label_overflows().is_empty(),"Initial labels fit their rectangles")
 var original_uid = ui.game.at("board",2).uid
 var count = ui.game.state.units.size()
 await drag(center("board",2),center("bench",0))
 check(ui.game.find_unit(original_uid).zone == "bench" and ui.game.state.units.size() == count,"Board to bank drag conserves unit")
 await drag(center("bench",0),center("board",15))
 check(ui.game.at("board",15).uid == original_uid and ui.game.state.units.size() == count,"Bank to empty board drag")
 var swap_uid = ui.game.at("board",3).uid
 await drag(center("board",15),center("board",3))
 check(ui.game.at("board",3).uid == original_uid and ui.game.at("board",15).uid == swap_uid,"Occupied board drop swaps exactly once")
 var before = ui.game.snapshot()
 await drag(center("board",3),Vector2(90,190))
 check(ui.game.snapshot() == before and ui.drag_uid == -1,"Enemy-side drop restores without mutation")
 await drag(center("board",3),Vector2(-30,-30))
 check(ui.game.snapshot() == before,"Outside-window drop preserves source")
 await mouse(center("board",3),true)
 await motion(center("bench",4))
 await key(KEY_ESCAPE)
 await mouse(center("bench",4),false)
 check(ui.game.snapshot() == before and ui.drag_uid == -1,"Escape cancels drag without release committing")
 await mouse(center("board",3),true)
 await motion(center("bench",4))
 ui.notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
 await mouse(center("bench",4),false)
 check(ui.game.snapshot() == before and ui.drag_uid == -1,"Focus loss cancels drag")
 await mouse(center("board",3),true)
 await motion(center("bench",4))
 ui.game.command({"type":"reroll"})
 var newer = ui.game.snapshot()
 await mouse(center("bench",4),false)
 check(ui.game.snapshot() == newer and ui.message_error,"Stale drag rejected atomically")
 # Clicking only inspects; it never moves units.
 ui.selected = -1
 before = ui.game.snapshot()
 await click(center("board",3))
 check(ui.selected == original_uid,"Click selects Pokemon")
 await click(center("bench",0))
 check(ui.game.snapshot() == before,"Click does not move Pokemon")
 # Buy a non-duplicate and test cap and bank swaps.
 ui.game.state.gold = 100
 for id in ui.game.state.shop:
  if id != 0:
   ui.game.state.pool[str(int(id))] += 1
 ui.game.state.shop = [172,60,0,0,0]
 ui.game.state.pool["172"] -= 1
 ui.game.state.pool["60"] -= 1
 await frames()
 await click(ui.shop_rect(0).get_center())
 check(ui.game.at("bench",0).species == 172,"Shop release buys Pokemon")
 check(ui.effects.any(func(e): return e.kind == "buy"),"Purchase has nonblocking animation")
 var bench_uid = ui.game.at("bench",0).uid
 before = ui.game.snapshot()
 await drag(center("bench",0),center("board",20))
 check(ui.game.snapshot() == before and ui.message_error,"Full team rejects empty board drop")
 await drag(center("bench",0),center("board",3))
 check(ui.game.at("board",3).uid == bench_uid and ui.game.at("bench",0).uid == original_uid,"Full team permits swap")
 await click(ui.shop_rect(1).get_center())
 var second_uid = ui.game.at("bench",1).uid
 await drag(center("bench",0),center("bench",1))
 check(ui.game.at("bench",1).uid == original_uid and ui.game.at("bench",0).uid == second_uid,"Bank-to-bank swap")
 # Read-only preview mirrors commit validation and doesn't spend or move anything.
 before = ui.game.snapshot()
 await mouse(center("bench",0),true)
 await motion(center("board",20))
 check(not ui.game.validate_move(ui.drag_uid,"board",20).ok,"Invalid drop highlighted using real rules")
 check(ui.game.validate_move(ui.drag_uid,"board",3).ok,"Swap target is a valid highlighted target")
 check(ui.game.snapshot() == before,"Dragging itself never mutates authoritative state")
 await key(KEY_ESCAPE)
 await mouse(center("board",20),false)
 # Inspect all names/descriptions: measure the actual rendered rectangles.
 for entry in ui.catalog.roster:
  ui.selected = -1
  ui.inspected = {"uid":999,"species":int(entry.id),"star":3,"slot":0,"zone":"bench"}
  await frames()
  var overflows = ui.label_overflows()
  check(overflows.is_empty(),"Complete labels/description: "+entry.name+str(overflows))
 var real_game = ui.game
 # Every species is actually rendered in shop, board and bank, not just the inspector.
 for entry in ui.catalog.roster:
  ui.game = ui.MatchModel.new(2)
  ui.game.state.units = [{"uid":1,"species":int(entry.id),"star":3,"zone":"board","slot":3},{"uid":2,"species":int(entry.id),"star":3,"zone":"bench","slot":0}]
  ui.game.state.shop = [int(entry.id),0,0,0,0]
  ui.effects.clear()
  ui._frame_effects({"events":[{"kind":"cast","from":1,"to":2,"sx":3,"sy":3,"tx":3,"ty":2,"species":int(entry.id),"target_species":48,"star":1,"amount":0,"spell":entry.ability}]})
  await frames()
  check(ui.label_overflows().is_empty(),"Board, bank, shop and cast labels: "+entry.name)
  var fighters = preload("res://core/battle.gd").new().prepare([{"uid":1,"species":int(entry.id),"star":3,"slot":3,"zone":"board"}],[],1)
  fighters[0].mana = fighters[0].max_mana
  ui._frame_effects({"units":fighters,"events":[{"kind":"cast","from":fighters[0].uid,"to":2,"sx":3,"sy":3,"tx":3,"ty":2,"species":int(entry.id),"target_species":48,"star":1,"amount":0,"spell":entry.ability}]})
  check(ui.combat_log[0].begins_with(ui.catalog.display_name(fighters[0])+":"),"Combat log uses caster evolution, not target star")
  ui.playback = {"before":ui.game.snapshot(),"round":1,"frames":[{"units":fighters,"events":[],"tick":0}]}
  ui.paused = true
  ui.frame_index = 0
  ui.inspected = fighters[0].duplicate(true)
  await frames()
  check(ui.label_overflows().is_empty(),"Full mana label and combat name: "+entry.name)
  ui.playback = {}
 ui.game = real_game
 ui.effects.clear()
 ui.inspected = {}
 await click(ui.layout.help.get_center())
 check(ui.help_open,"Pixel help opens")
 await frames()
 check(ui.label_overflows().is_empty(),"Help text fits")
 before = ui.game.snapshot()
 await click(ui.shop_rect(0).get_center())
 check(before == ui.game.snapshot(),"Modal prevents clicks through to shop")
 await key(KEY_ESCAPE)
 # Test actual combat input, mana display, replay and save.
 await click(ui.layout.fight.get_center())
 check(not ui.playback.is_empty(),"Battle starts from UI")
 await click(ui.layout.fight.get_center())
 check(ui.paused,"Pause remains responsive")
 ui.frame_index = mini(40,ui.playback.frames.size()-1)
 ui.inspected = ui.playback.frames[ui.frame_index].units[0].duplicate(true)
 await frames()
 check(ui.label_overflows().is_empty(),"Combat labels and role/mana details fit")
 check(ui._detail_unit().mana == ui.playback.frames[ui.frame_index].units[0].mana,"Detail pane shows live mana, not stale selection")
 before = ui.game.snapshot()
 await click(ui.layout.xp.get_center())
 check(ui.playback.is_empty(),"Skip completes visual playback")
 await click(ui.layout.replay.get_center())
 check(not ui.playback.is_empty(),"Replay begins")
 await click(ui.layout.xp.get_center())
 check(ui.game.snapshot() == before,"Replay does not change lives, rounds, gold")
 check(not ui.has_method("_save") and not ui.game.has_method("restore"),"No autosave or restore entry points")
 await click(center("bench",0))
 var sold_uid = ui.selected
 await key(KEY_DELETE)
 check(sold_uid >= 0 and ui.game.find_unit(sold_uid).is_empty(),"Delete key sells selected Pokemon")
 check(ui.effects.any(func(e): return e.kind == "sell"),"Sale emits visual feedback")
 # Viewport scaling is included in actual input injection, matching resized windows.
 root.size = Vector2i(1280,720)
 await frames()
 var moving = ui.game.at("board",3).uid
 await drag(center("board",3),center("bench",4))
 check(ui.game.at("bench",4).uid == moving,"Drag works after window resize")
 ui._cancel_drag()
 ui.playback = {}
 ui.help_open = false
 ui.reset_open = false
 ui.game = ui.MatchModel.new(99)
 ui.game.state.round = 5
 ui.game.state.wins = 4
 ui.game._ensure_augments()
 await frames()
 before = ui.game.snapshot()
 await key(KEY_SPACE)
 await click(ui.shop_rect(0).get_center())
 check(before == ui.game.snapshot(),"Augment modal blocks gameplay and keyboard shortcuts")
 await click(ui.layout.augment_buttons[0].get_center())
 check(ui.game.state.augments.size() == 1 and ui.game.state.augment_offers.is_empty(),"Actual UI selects exactly one augment")
 var owned = ui.game.state.augments.size()
 await click(ui.layout.augment_buttons[0].get_center())
 check(ui.game.state.augments.size() == owned,"Repeated click cannot select twice")
 for aug in ui.game.augments.all:
  ui.game.state.augment_offers = [aug.id]
  ui.game.state.augments = [aug.id,aug.id,aug.id]
  await frames()
  check(ui.label_overflows().is_empty(),"Full augment text and persistent summary fit: "+aug.id)
 ui.game.state.augment_offers = []
 ui.game.state.augments = []
 ui.game.state.level = 10
 ui.game.state.units = []
 var diverse_ids = [302,304,333,238,255,1,172,280,123,131]
 for i in range(diverse_ids.size()):
  ui.game.state.units.append({"uid":i+1,"species":diverse_ids[i],"star":3,"slot":i,"zone":"board"})
 await frames()
 check(ui.label_overflows().is_empty(),"Diverse team synergy grid fits")
 # Native viewport sizes use the same projected hit polygons.
 for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1080)]:
  root.size = resolution
  await frames()
  for y in range(3,6):
   for x in range(7):
    var point = ui.project_grid(x+0.5,y+0.5)
    var target = ui._slot_at(point)
    check(not target.is_empty() and target.zone == "board" and target.slot == (y-3)*7+x,"Projected center resolves at "+str(resolution))
  check(ui._slot_at(Vector2(13,155)).is_empty(),"Outside trapezoid is not a tile")
  check(ui.label_overflows().is_empty(),"Native resolution labels "+str(resolution))
  ui.game = ui.MatchModel.new(99)
  await frames()
  var uid = ui.game.at("board",2).uid
  await drag(center("board",2),center("bench",0))
  await drag(center("bench",0),center("board",20))
  check(ui.game.at("board",20).uid == uid,"Projected drag at "+str(resolution))
 var tiles = ui.range_tiles(Vector2i(3,3),2)
 check(tiles.size() == 13 and Vector2i(4,4) in tiles and Vector2i(5,4) not in tiles,"Range tiles share Manhattan combat metric")
 print("UI V4: %d passed, %d failed" % [passed,failed])
 ui.queue_free()
 await process_frame
 quit(1 if failed else 0)
