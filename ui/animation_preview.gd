extends "res://ui/main.gd"
# Internal inspection scene. Uses the same combat resolver and renderer as expeditions.
var roster_index = 0
var preview_star = 1
var preview_clock = 0.0
func _ready():
 save_path = "res://tests/preview-no-save.json"
 super._ready()
 await get_tree().process_frame
 _resize_layout()
 preview()
func _process(delta):
 super._process(delta)
 preview_clock += delta
 if preview_clock > 2.0: preview()
func _input(event):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_RIGHT: roster_index = (roster_index+1)%catalog.roster.size();preview()
  elif event.keycode == KEY_LEFT: roster_index = posmod(roster_index-1,catalog.roster.size());preview()
  elif event.keycode == KEY_UP: preview_star=preview_star%3+1;preview()
  elif event.keycode == KEY_F11: _key_input(event)
  elif event.keycode == KEY_ESCAPE: get_tree().quit()
func preview():
 if layout.is_empty(): return
 preview_clock = 0.0
 var mon = catalog.roster[roster_index]
 var b = preload("res://core/battle.gd").new()
 var fighters = b.prepare([{"species":mon.id,"uid":1,"star":preview_star,"slot":3,"zone":"board"},{"species":143,"uid":2,"star":3,"slot":4,"zone":"board"}],[{"species":143,"uid":1,"star":3,"slot":3,"zone":"board"},{"species":143,"uid":2,"star":3,"slot":4,"zone":"board"}],901)
 for f in fighters: f.max_hp=100000;f.hp=50000
 fighters[0].mana=500
 if preview_star == 3: fighters[0].trait_counts={"Psycho":8}
 b._cast_event(fighters[0],fighters[2],fighters)
 var sequence = [{"tick":0,"units":fighters.duplicate(true),"events":b.events.duplicate(true)}]
 b.events.clear()
 fighters[0].pending_action={"kind":"cast","target":fighters[2].uid,"when":3}
 b.resolve_action(fighters[0],fighters)
 for i in range(1,20): sequence.append({"tick":i,"units":fighters.duplicate(true),"events":b.events.duplicate(true) if i == 3 else []})
 playback={"before":game.state,"frames":sequence}
 frame_index=0;elapsed=0;paused=false;effects.clear();last_visual_tick=-1
 _frame_effects(sequence[0])
 message="ANIMATIONSVORSCHAU · Links/Rechts: Pokémon · Oben: Sterne · F11: Vollbild · Esc: Beenden · "+catalog.display_name(fighters[0])+" / "+mon.ability
