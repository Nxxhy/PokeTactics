extends SceneTree
const Battle = preload("res://core/battle.gd")
var ui
var passed = 0
var failed = 0
var coverage: Array = []
func _init(): call_deferred("run")
func check(ok,label):
 if ok: passed += 1
 else: failed += 1;printerr("FAIL V9: "+label)
func unit(id,uid,slot,star): return {"species":id,"uid":uid,"slot":slot,"star":star,"zone":"board"}
func run():
 root.size = Vector2i(1280,720)
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/unused-v9.json"
 root.add_child(ui)
 await process_frame
 check(ui.ability_fx.recipes.size()==70,"Every roster line has an explicit recipe")
 check(ui.ability_fx.textures.size()==27,"All bundled Showdown textures load")
 for mon in ui.catalog.roster:
  for star in [1,2,3]:
   var b = Battle.new()
   # Run the normal pending-action resolver against real prepared fighters.
   var fighters = b.prepare([unit(mon.id,1,3,star),unit(143,2,4,3)],[unit(143,1,3,3),unit(143,2,4,3),unit(143,3,2,3)],912)
   for fighter in fighters:
    fighter.max_hp = 100000;fighter.hp = 50000
    fighter.trait_counts = {"Psycho":8} if fighter.side == 0 and star == 3 else {}
   var caster = fighters[0]
   var target = fighters[2]
   caster.mana = 500
   b._cast_event(caster,target,fighters)
   var launch = b.events.duplicate(true)
   b.events.clear()
   caster.pending_action = {"kind":"cast","target":target.uid,"when":3}
   b.resolve_action(caster,fighters)
   var impacts = b.events.filter(func(e):return e.kind == "ability_impact" and e.from == caster.uid)
   check(not impacts.is_empty(),mon.name+" emits ability impacts star "+str(star))
   for e in impacts:
    check(e.spell==mon.ability and e.source_star==star,"Correct ability/star attached to real recipient")
    check(fighters.any(func(f):return f.uid==e.to and f.x==e.tx and f.y==e.ty),"Impact uses actual target position")
   var frame = {"tick":star,"units":fighters,"events":launch+b.events,"fields":[]}
   ui.playback = {"before":ui.game.state,"frames":[frame]}
   ui.frame_index=0;ui.paused=true;ui.effects.clear();ui.last_visual_tick=-1
   ui._frame_effects(frame)
   var count = ui.effects.size()
   ui._frame_effects(frame)
   check(ui.effects.size()==count,"Re-reading frame never duplicates events")
   for t in [0.1,0.45,0.8]:
    for e in ui.effects: e.age=e.duration*t
    ui.queue_redraw()
    await process_frame
    await process_frame
   check(ui.ability_fx.triggered.has(str(int(mon.id))+":"+mon.ability),mon.name+" animation actually rendered")
   check(ui.label_overflows().is_empty(),mon.name+" labels fit")
   coverage.append({"id":mon.id,"form":ui.catalog.sprite_id({"species":mon.id,"star":star}),"pokemon":ui.catalog.display_name({"species":mon.id,"star":star}),"star":star,"ability":mon.ability,"pattern":ui.ability_fx.recipes[str(int(mon.id))].pattern,"impacts":impacts.size(),"verified":not impacts.is_empty()})
   # Export one reviewed frame per line for a complete visual contact sheet.
   if star == 3:
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("res://docs/animation-captures/%d.png" % mon.id)
 ui.playback={};ui.effects.clear()
 for dims in [Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=dims
  await process_frame;await process_frame
  check(ui.label_overflows().is_empty(),"Window layout "+str(dims))
 root.mode=Window.MODE_FULLSCREEN
 await process_frame;await process_frame
 check(ui.label_overflows().is_empty(),"Fullscreen labels fit")
 root.mode=Window.MODE_WINDOWED
 var file=FileAccess.open("res://docs/animation-coverage.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(coverage,"  "))
 print("V9 ANIMATIONS: %d passed, %d failed; %d form/star casts" % [passed,failed,coverage.size()])
 quit(1 if failed else 0)
