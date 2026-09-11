extends Control
const MatchModel = preload("res://core/match.gd")
const Catalog = preload("res://core/catalog.gd")
const BG = Color("e7ebd5")
const PAPER = Color("f8f8e8")
const INK = Color("484850")
const MUTED = Color("687078")
const RED = Color("b84c49")
const GREEN = Color("488858")
const BLUE = Color("607898")
const GOLD = Color("e3b94f")
var BOARD_ORIGIN = Vector2(26,162)
var CELL_STEP = Vector2(138,78)
var CELL_SIZE = Vector2(132,72)
var save_path = "user://match.json"
var game = MatchModel.new()
var catalog = Catalog.new()
var font: FontFile
var heading_font: FontFile
var narrow_font: FontFile
var layout: Dictionary = {}
var compact = false
var trait_page = 0
var trait_open = ""
var start_open = false
var chosen_difficulty = "Normal"
var touch_id = -1
var metadata_regions: Array = []
var effect_regions: Array = []
var depth_order: Array = []
var world_labels: Array = []
var textures = {}
var crops = {}
var idle = {}
var valid_drag_slots: Array = []
var forest_view: SubViewport
var draw_usec = 0
var draw_profile = []
var line_cache = {}
var shaped_cache = {}
var hits: Array = []
var slots: Array = []
var text_boxes: Array = []
var selected = -1
var inspected: Dictionary = {}
var message = "Willkommen in Kanto! Ziehe Pokémon aus der Bank auf dein Feld."
var message_error = false
var playback: Dictionary = {}
var frame_index = 0
var elapsed = 0.0
var speed = 1.0
var paused = false
var help_open = false
var reset_open = false
var combat_log: Array = []
var effects: Array = []
var clock_time = 0.0
var capture_frames = 0
var pointer = Vector2.ZERO
var press_at = Vector2.ZERO
var press_uid = -1
var pressed_hit: Dictionary = {}
var drag_uid = -1
var drag_revision = -1
var drag_unit: Dictionary = {}
var drag_origin: Dictionary = {}
var result_time = 0.0
var shell
var ability_fx = preload("res://ui/ability_fx.gd").new()
var last_visual_tick = -1

func _ready():
 if not preload("res://ui/launch_gate.gd").admit():
  set_process(false)
  set_process_input(false)
  get_tree().quit()
  return
 if save_path == "user://match.json" and "--fresh-demo" not in OS.get_cmdline_user_args() and not OS.has_feature("web"):
  get_window().mode = Window.MODE_FULLSCREEN
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 font = FontFile.new()
 font.data = FileAccess.get_file_as_bytes("res://assets/fonts/pkmnem.ttf")
 heading_font = FontFile.new()
 heading_font.data = FileAccess.get_file_as_bytes("res://assets/fonts/pkmnem.ttf")
 narrow_font = FontFile.new()
 narrow_font.data = FileAccess.get_file_as_bytes("res://assets/fonts/pkmnemn.ttf")
 narrow_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
 narrow_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
 font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
 heading_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
 font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
 var pixel_theme = Theme.new()
 pixel_theme.default_font = font
 pixel_theme.default_font_size = 16
 var tooltip_frame = StyleBoxFlat.new()
 tooltip_frame.bg_color = PAPER
 tooltip_frame.border_color = INK
 tooltip_frame.set_border_width_all(3)
 tooltip_frame.content_margin_left = 10
 tooltip_frame.content_margin_right = 10
 tooltip_frame.content_margin_top = 8
 tooltip_frame.content_margin_bottom = 8
 pixel_theme.set_stylebox("panel","TooltipPanel",tooltip_frame)
 pixel_theme.set_color("font_color","TooltipLabel",INK)
 theme = pixel_theme
 for mon in catalog.roster:
  for id in mon.forms:
   var key = int(id)
   if textures.has(key):
    continue
   var picture = Image.new()
   if picture.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/pokemon/%d.png" % key)) == OK:
    textures[key] = ImageTexture.create_from_image(picture)
    crops[key] = picture.get_used_rect()
 game = MatchModel.new(int(Time.get_unix_time_from_system()) % 1000000000)
 if "--fresh-demo" in OS.get_cmdline_user_args():
  start_open = false
  game = MatchModel.new(1337)
 if "--capture-battle" in OS.get_cmdline_user_args():
  game.command({"type":"battle"})
  _replay()
  frame_index = mini(60,playback.frames.size()-1)
  _frame_effects(playback.frames[frame_index])
  paused = true
  inspected = playback.frames[frame_index].units[0].duplicate(true)
 if "--capture" in OS.get_cmdline_user_args() or "--capture-battle" in OS.get_cmdline_user_args():
  capture_frames = 4
 resized.connect(_resize_layout)
 _load_idle()
 _resize_layout()
 if save_path == "user://match.json" and "--fresh-demo" not in OS.get_cmdline_user_args():
  shell = preload("res://ui/shell.gd").new()
  add_child(shell)
 queue_redraw()

func _process(delta):
 clock_time += delta
 result_time = maxf(0,result_time-delta)
 for effect in effects:
  effect.age += delta*((0.0 if paused else speed) if not playback.is_empty() and not effect.get("event",{}).is_empty() else 1.0)
 effects = effects.filter(func(e): return e.age < e.duration)
 if not playback.is_empty() and not paused:
  elapsed += delta*speed
  while elapsed >= 0.1 and not playback.is_empty():
   elapsed -= 0.1
   frame_index += 1
   if frame_index >= playback.frames.size():
    _finish_playback()
    break
   _frame_effects(playback.frames[frame_index])
 queue_redraw()
 if capture_frames > 0:
  capture_frames -= 1
  if capture_frames == 0:
   await RenderingServer.frame_post_draw
   var target = "res://docs/pixel-battle.png" if not playback.is_empty() else "res://docs/pixel-overview.png"
   for arg in OS.get_cmdline_user_args():
    if arg.begins_with("--capture-output="):
     target = arg.trim_prefix("--capture-output=")
   var error = get_viewport().get_texture().get_image().save_png(target)
   print("Capture result: ",error,"; sprites: ",textures.size(),"; idle animations: ",idle.size(),"; label overflows: ",label_overflows().size())
   get_tree().quit()

func board_rect(x: int,y: int) -> Rect2:
 var poly = tile_polygon(x,y)
 var r = Rect2(poly[0],Vector2.ZERO)
 for point in poly: r = r.expand(point)
 return r

func project_grid(x: float,y: float) -> Vector2:
 var depth = y/6.0
 var width = layout.main.size.x*(0.76+0.22*depth)
 var height = CELL_STEP.y*6-58
 return Vector2(layout.main.get_center().x+(x/7.0-0.5)*width,BOARD_ORIGIN.y+58+depth*height)

func tile_polygon(x: int,y: int) -> PackedVector2Array:
 return PackedVector2Array([project_grid(x,y),project_grid(x+1,y),project_grid(x+1,y+1),project_grid(x,y+1)])

func _contains(item: Dictionary,point: Vector2) -> bool:
 return Geometry2D.is_point_in_polygon(point,item.polygon) if item.has("polygon") else item.rect.has_point(point)

func world_rect(pos: Vector2) -> Rect2:
 var foot = project_grid(pos.x+0.5,pos.y+0.5)
 var width = (project_grid(pos.x+1,pos.y)-project_grid(pos.x,pos.y)).x-3
 var height = CELL_STEP.y-58.0/6-1
 return Rect2(foot-Vector2(width/2,height-30),Vector2(width,height))

func _world_unit(pos: Vector2,unit: Dictionary,enemy: bool,combat: bool,alpha: float = 1.0):
 var r = world_rect(pos)
 var foot = project_grid(pos.x+0.5,pos.y+0.5)
 draw_ellipse_shadow(Vector2(foot.x,_sprite_area(r).end.y),Vector2(r.size.x*0.22,4),Color("41634d",0.35*alpha))
 _unit(r,unit,enemy,combat,alpha,true)
 world_labels.append({"rect":r,"unit":unit,"enemy":enemy,"combat":combat,"alpha":alpha})

func draw_ellipse_shadow(at: Vector2,radius: Vector2,color: Color):
 var points = PackedVector2Array()
 for i in range(12): points.append((at+Vector2(cos(i*TAU/12)*radius.x,sin(i*TAU/12)*radius.y)).round())
 draw_colored_polygon(points,color)

func _landscape():
 var r = Rect2(BOARD_ORIGIN,Vector2(layout.main.size.x,CELL_STEP.y*6))
 if is_instance_valid(forest_view): draw_texture_rect(forest_view.get_texture(),r,false)
 for i in range(4):
  var x = r.position.x+fposmod(i*r.size.x/4+clock_time*1.4,r.size.x-50)
  draw_rect(Rect2(x,r.position.y+4+i%2*4,32,4),Color("c8eed4"))
 for i in range(10):
  var at = Vector2(r.position.x+4 if i%2 else r.end.x-5,r.position.y+90+i*(r.size.y-100)/10)
  draw_line(at,at+Vector2(roundf(sin(clock_time*2+i))*2,-4),Color("a5d779"),2)

func arena_color(row: int,alternate: bool) -> Color:
 var color = Color("92b777") if row < 3 else Color("64b991")
 return color.lightened(0.025) if alternate else color

func _arena_boundary():
 var a = project_grid(0,3)
 var b = project_grid(7,3)
 draw_line(a,b,Color("315c48"),7)
 draw_line(a,b,Color("ffedaa"),3)
 for i in range(28):
  var p = a.lerp(b,(i+0.5)/28)
  draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),Color("f7f6ce"))
 # Labels sit in the empty scenery margins and remain visible throughout battle.
 for row in [1,3]:
  var edge = project_grid(0,1.5 if row == 1 else 3.22)
  var label = "Gegner" if row == 1 else "Dein Team"
  var plate = Rect2(2,edge.y-10,minf(98,project_grid(0,1.7 if row == 1 else 3.45).x-5),20)
  _panel(plate,Color("eee7b7") if row == 1 else Color("d2f4b7"),false)
  _label(label,plate.grow(-2),12,INK,HORIZONTAL_ALIGNMENT_CENTER)

func _load_idle():
 var path = "res://assets/animated/manifest.json"
 if not FileAccess.file_exists(path): return
 var manifest = JSON.parse_string(FileAccess.get_file_as_string(path))
 if typeof(manifest) != TYPE_DICTIONARY: return
 for key in manifest:
  var entry = manifest[key]
  if entry.get("fallback",false): continue
  var image = Image.new()
  var png = "res://assets/animated/%s.png" % key
  if not FileAccess.file_exists(png): continue
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(png)) != OK: continue
  entry.texture = ImageTexture.create_from_image(image)
  entry.total = 0.0
  entry.ends = []
  entry.columns = int(entry.columns)
  for duration in entry.durations:
   entry.total += duration
   entry.ends.append(entry.total)
  idle[int(key)] = entry

func idle_frame(id: int,time: float) -> int:
 if not idle.has(id): return 0
 var animation = idle[id]
 var phase = fposmod(time,animation.total)
 for i in range(animation.ends.size()):
  if phase < animation.ends[i]: return i
 return 0

func slot_rect(zone: String,slot: int) -> Rect2:
 if zone == "board":
  return board_rect(slot%7,3+int(slot/7))
 var r = layout.get("bench",Rect2(26,672,968,98))
 return Rect2(Vector2(r.position.x+slot*r.size.x/8,r.position.y).round(),Vector2(floor(r.size.x/8)-5,r.size.y))

func shop_rect(index: int) -> Rect2:
 var r = layout.get("shop",Rect2(26,807,970,112))
 return Rect2(Vector2(r.position.x+index*r.size.x/5,r.position.y).round(),Vector2(floor(r.size.x/5)-6,r.size.y))

func _draw():
 var draw_started = Time.get_ticks_usec()
 draw_profile = []
 hits.clear()
 slots.clear()
 text_boxes.clear()
 metadata_regions.clear()
 effect_regions.clear()
 world_labels.clear()
 if layout.is_empty(): return
 var s = playback.get("before",game.state)
 var combat = not playback.is_empty()
 draw_rect(Rect2(Vector2.ZERO,size),Color("80b898"))
 for stripe in range(0,int(size.y),8): draw_rect(Rect2(0,stripe,size.x,3),Color("78b090"))
 draw_rect(Rect2(0,0,size.x,60),Color("507878"))
 draw_rect(Rect2(0,57,size.x,3),GOLD)
 _ball(Vector2(31,30),16)
 _label("POKÉ TACTICS",Rect2(58,7,220,29),26,PAPER)
 _label(s.difficulty+" · 3 Regionen",Rect2(60,35,210,19),14,Color("cadfd4"))
 var forecast = game.income_forecast()
 var stat_width = (size.x-550)/4
 var titles = ["GOLD","RUNDE / LEBEN","LEVEL / ERFAHRUNG","AUFSTELLUNG"]
 var values = ["%d G" % int(s.gold),"%d/30 · %d/3 LP" % [mini(30,int(s.round)),int(s.lives)],"Lv.%d · %d/%d EP" % [int(s.level),int(s.xp),[0,2,3,4,8,14,22,32,48,64,0][int(s.level)]],"%d / %d" % [s.units.filter(func(u): return u.zone == "board").size(),int(s.level)]]
 for i in range(4):
  var x = 280+i*stat_width
  _label(titles[i],Rect2(x,5,stat_width-8,15),12,Color("b7d2c5"))
  _label(values[i],Rect2(x,20,stat_width-8,22),22 if i == 0 else 16,GOLD if i == 0 else PAPER)
  if i == 0:
   _label("Runde +%d–%d · Z +%d" % [mini(forecast.win,forecast.loss),maxi(forecast.win,forecast.loss),forecast.interest],Rect2(x,42,stat_width-8,14),12,PAPER)
  elif i == 2: _label("4 Gold = %d EP" % (4+int(game.augments.value(s.augments,"xp_buy"))),Rect2(x,42,stat_width-8,14),12,PAPER)
 _button(layout.help,"Hilfe [F1]",func(): _cancel_drag(); help_open = true)
 if is_instance_valid(shell):
  _button(layout.new_game,"Menü [Esc]",func(): shell.leave_game(false))
 else:
  _button(layout.new_game,"Neue Partie",func(): _cancel_drag(); chosen_difficulty = game.state.difficulty; reset_open = true)
 _label(("KAMPF" if combat else "AUFSTELLUNG")+" · "+(combat_log[0] if combat and not combat_log.is_empty() else "Ziehen zum Platzieren · Klick für Details"),Rect2(12,65,layout.main.size.x,21),14,INK)
 _landscape()
 for y in range(6):
  for x in range(7):
   var rect = board_rect(x,y)
   var polygon = tile_polygon(x,y)
   draw_colored_polygon(polygon,arena_color(y,(x+y)%2 == 0))
   draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[3],polygon[0]]),Color("478c64",0.5),1)
   if y >= 3:
    var slot = (y-3)*7+x
    slots.append({"rect":rect,"polygon":polygon,"zone":"board","slot":slot})
    if not combat:
     _hit(rect,_select_slot.bind("board",slot),"Ziehen zum Bewegen · Klick für Details")
     hits[-1].polygon = polygon
 _arena_boundary()
 _range_overlay()
 _ground_effects()
 draw_profile.append(Time.get_ticks_usec()-draw_started)
 if combat:
  _combat_units()
 else:
  for y in range(6):
   for x in range(7):
    var unit = game.at("board",(y-3)*7+x) if y >= 3 else {}
    if y < 3:
     for enemy in s.enemy:
      if enemy.slot%7 == x and 2-int(enemy.slot/7) == y: unit = enemy
    if not unit.is_empty() and not _hide_unit(unit,y < 3):
     _world_unit(Vector2(x,y),unit,y < 3,false)
     if y < 3:
      _hit(board_rect(x,y),_inspect.bind(unit),_unit_tip(unit))
      hits[-1].polygon = tile_polygon(x,y)
 draw_profile.append(Time.get_ticks_usec()-draw_started)
 _label("BANK",Rect2(12,layout.bench.position.y-22,80,20),16,GREEN)
 _label("Level %d · %s" % [int(s.level),"MAX" if s.level == 10 else "%d / %d EP" % [int(s.xp),game.xp_needed()]],Rect2(110,layout.bench.position.y-22,layout.main.size.x-115,20),14,INK,HORIZONTAL_ALIGNMENT_RIGHT)
 for i in range(8):
  var rect = slot_rect("bench",i)
  _panel(rect,PAPER)
  slots.append({"rect":rect,"zone":"bench","slot":i})
  var unit = game.at("bench",i)
  if not unit.is_empty() and not _hide_unit(unit,false): _unit(rect,unit,false,false)
  elif unit.is_empty(): _label(str(i+1),rect,16,Color("82958c"),HORIZONTAL_ALIGNMENT_CENTER)
  if not combat: _hit(rect,_select_slot.bind("bench",i),_unit_tip(unit) if not unit.is_empty() else "Freier Bankplatz")
 _label("POKÉ-MARKT",Rect2(12,layout.shop.position.y-23,190,21),18,INK)
 _label("Chancen 1–5 G: "+" / ".join(MatchModel.SHOP_ODDS[int(s.level)].map(func(n): return "%d%%" % n)),Rect2(202,layout.shop.position.y-23,layout.main.size.x-207,21),13,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
 for i in range(5): _shop_card(i,s,combat)
 _actions(combat,s)
 _information(combat,s)
 _strategy_panel(s)
 if not compact: _economy_result(s,combat)
 draw_rect(Rect2(0,size.y-20,size.x,20),Color("183d48"))
 _label(message,Rect2(12,size.y-20,size.x-24,20),13,Color("ffccad") if message_error else PAPER)
 _draw_effects()
 draw_profile.append(Time.get_ticks_usec()-draw_started)
 # Flat nameplates are a final overlay: nearer sprites never erase another unit's name or stars.
 for plate in world_labels:
  _unit_metadata(plate.rect,plate.unit,plate.enemy,plate.combat,plate.alpha,true)
 draw_profile.append(Time.get_ticks_usec()-draw_started)
 if drag_uid >= 0: _draw_drag()
 if help_open or reset_open or start_open: _draw_modal()
 if not combat and not game.state.augment_offers.is_empty() and not start_open and not reset_open: _augment_modal()
 if not trait_open.is_empty(): _trait_modal()
 draw_usec = Time.get_ticks_usec()-draw_started

func _header_stat(title: String,value: String,x: float,width: float):
 _label(title,Rect2(x,12,width,22),16,PAPER)
 _label(value,Rect2(x,34,width,37),28,PAPER)

func _strategy_panel(s: Dictionary):
 var r = layout.synergies
 _panel(r,PAPER)
 draw_rect(Rect2(r.position+Vector2(7,5),Vector2(r.size.x-14,24)),Color("d7e9a1"))
 _ball(r.position+Vector2(20,17),9)
 _label("TYPEN · 2/4/6/8",Rect2(r.position+Vector2(35,5),Vector2(r.size.x-116,24)),16,INK)
 var nav = Rect2(r.position+Vector2(r.size.x-72,6),Vector2(62,22))
 draw_rect(nav,PAPER)
 _label("%d/3 >" % (trait_page+1),nav,14,INK,HORIZONTAL_ALIGNMENT_CENTER)
 _hit(nav,func(): trait_page = (trait_page+1)%3,"Weitere Typen anzeigen")
 var team = s.units.filter(func(u): return u.zone == "board")
 var natural = catalog.synergies(team)
 var counts = game.augments.counts(team,s.augments)
 var names = catalog.trait_descriptions.keys()
 names.sort_custom(func(a,b): return counts.get(a,0)>counts.get(b,0) or counts.get(a,0)==counts.get(b,0) and a<b)
 var row_h = minf(64,(r.size.y-38)/4)
 for i in range(8):
  var index = trait_page*8+i
  if index >= names.size(): break
  var type = names[index]
  var n = int(counts.get(type,0))
  var raw = int(natural.get(type,0))
  var tier = mini(8,int(n/2)*2)
  var next = "MAX" if n>=8 else str((int(n/2)+1)*2)
  var box = Rect2(r.position+Vector2(8+(i%2)*(r.size.x-16)/2,33+int(i/2)*row_h),Vector2((r.size.x-16)/2-4,row_h-3))
  draw_rect(box,Color("d1e5b8") if tier >= 2 else Color("e8ebe0"))
  _label("%s %d+%d=%d" % [type,raw,n-raw,n],Rect2(box.position,Vector2(box.size.x,17)),13,GREEN if tier>=2 else INK)
  _label("Stufe %d > %s" % [tier,next],Rect2(box.position+Vector2(0,18),Vector2(box.size.x,maxf(13,box.size.y-18))),12,INK)
  var detail = "%d Pokémon + %d Augment = %d. Stufe %d. Nächste: %s." % [raw,n-raw,n,tier,next]
  _hit(box,func(): trait_open = type,type+": "+detail+"\n"+catalog.trait_text(type))
 r = layout.augments
 _panel(r,PAPER)
 draw_rect(Rect2(r.position+Vector2(7,5),Vector2(r.size.x-14,23)),Color("d7e9a1"))
 _pixel_star(r.position+Vector2(20,17),GOLD)
 _label("AUGMENTS · 5 / 12 / 20",Rect2(r.position+Vector2(35,4),Vector2(r.size.x-44,24)),18,INK)
 var entry_h = (r.size.y-32)/3
 for j in range(s.augments.size()):
  var aug = game.augments.get_aug(s.augments[j])
  var box = Rect2(r.position+Vector2(9,30+j*entry_h),Vector2(r.size.x-18,entry_h-3))
  _label(aug.name,Rect2(box.position,Vector2(box.size.x,20)),15,BLUE)
  if not compact: _wrap(aug.description,Rect2(box.position+Vector2(0,23),Vector2(box.size.x,box.size.y-23)),14,INK)
  _hit(box,func(): message = aug.name+": "+aug.description,aug.name+"\n"+aug.description)
 if s.augments.is_empty(): _wrap("Wähle vor Runde 5, 12 und 20 dauerhafte Boni.",Rect2(r.position+Vector2(10,33),Vector2(r.size.x-20,r.size.y-40)),14,MUTED)

func _trait_modal():
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.06,0.13,0.17,0.88))
 hits.clear();slots.clear()
 var r = Rect2(size*Vector2(0.12,0.12),size*Vector2(0.76,0.76))
 _panel(r,PAPER)
 var info = catalog.trait_descriptions[trait_open]
 _label(trait_open+" – "+info[0],Rect2(r.position+Vector2(18,14),Vector2(r.size.x-36,38)),26,INK)
 var natural = catalog.synergies(game.board()).get(trait_open,0)
 var total = game.augments.counts(game.board(),game.state.augments).get(trait_open,0)
 _label("%d Pokémon + %d Augment = %d" % [natural,total-natural,total],Rect2(r.position+Vector2(18,56),Vector2(r.size.x-36,24)),16,GREEN)
 var row_h = (r.size.y-146)/4
 for i in range(4):
  var box = Rect2(r.position+Vector2(18,90+i*row_h),Vector2(r.size.x-36,row_h-5))
  draw_rect(box,Color("d1e5b8") if total >= (i+1)*2 else Color("e8ebe0"))
  _wrap("%d: %s" % [(i+1)*2,info[i+1]],box.grow(-7),16,INK)
 _button(Rect2(r.position+Vector2(18,r.size.y-44),Vector2(r.size.x-36,30)),"Zurück [Esc]",func(): trait_open = "")

func _augment_modal():
 if drag_uid >= 0 or press_uid >= 0: _cancel_drag()
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.06,0.13,0.17,0.88))
 hits.clear()
 slots.clear()
 var r = Rect2(size*Vector2(0.07,0.22),size*Vector2(0.86,0.57))
 _panel(r,PAPER)
 _label("RUNDE %d · DEIN AUGMENT" % int(game.state.augment_at),Rect2(r.position+Vector2(15,17),Vector2(r.size.x-30,40)),26,INK,HORIZONTAL_ALIGNMENT_CENTER)
 layout.augment_buttons = []
 for i in range(game.state.augment_offers.size()):
  var aug = game.augments.get_aug(game.state.augment_offers[i])
  var width = (r.size.x-48)/3
  var box = Rect2(r.position+Vector2(12+i*(width+12),75),Vector2(width,r.size.y-92))
  _panel(box,Color("f4e3b9"))
  _label(aug.name,Rect2(box.position+Vector2(10,12),Vector2(width-20,30)),22,INK,HORIZONTAL_ALIGNMENT_CENTER)
  _wrap(aug.description,Rect2(box.position+Vector2(13,55),Vector2(width-26,box.size.y-111)),16,INK)
  var button = Rect2(box.position+Vector2(12,box.size.y-43),Vector2(width-24,31))
  layout.augment_buttons.append(button)
  _button(button,"Diesen Bonus wählen",_send.bind({"type":"augment","index":i}),GREEN)

func _effective_reach(unit: Dictionary) -> int:
 var counts = unit.get("traits",{})
 if not unit.has("traits"):
  var all_counts = game.augments.counts(game.board(),game.state.augments)
  for type in catalog.combat_types(unit): counts[type] = all_counts.get(type,0)
 return (int(catalog.get_mon(unit.species).range)+(1 if counts.get("Flug",0)>=2 else 0))*(2 if counts.get("Psycho",0)>=8 else 1)

func range_tiles(origin: Vector2i,reach: int) -> Array:
 var tiles = []
 for y in range(6):
  for x in range(7):
   if Catalog.distance(origin,Vector2i(x,y)) <= reach:
    tiles.append(Vector2i(x,y))
 return tiles

func _range_overlay():
 if drag_uid >= 0 or not game.state.augment_offers.is_empty() or help_open or reset_open:
  return
 var candidates = []
 if not playback.is_empty():
  for unit in playback.frames[frame_index].units:
   if unit.hp > 0:
    candidates.append({"unit":unit,"pos":Vector2i(unit.x,unit.y)})
 else:
  for unit in game.board():
   candidates.append({"unit":unit,"pos":Vector2i(unit.slot%7,3+int(unit.slot/7))})
  for unit in game.state.enemy:
   candidates.append({"unit":unit,"pos":Vector2i(unit.slot%7,2-int(unit.slot/7))})
 var focus = {}
 for candidate in candidates:
  if Geometry2D.is_point_in_polygon(pointer,tile_polygon(candidate.pos.x,candidate.pos.y)):
   focus = candidate
   break
 if focus.is_empty():
  for candidate in candidates:
   if (not playback.is_empty() and candidate.unit.uid == inspected.get("uid",-1)) or (playback.is_empty() and candidate.pos.y >= 3 and candidate.unit.uid == selected):
    focus = candidate
    break
 if focus.is_empty():
  return
 for tile in range_tiles(focus.pos,_effective_reach(focus.unit)):
  var poly = tile_polygon(tile.x,tile.y)
  draw_polyline(PackedVector2Array([poly[0],poly[1],poly[2],poly[3],poly[0]]),Color(BLUE,0.7),2)

func _sidebar(combat: bool,s: Dictionary):
 _panel(Rect2(1024,100,392,206),PAPER)
 if combat:
  _button(Rect2(1038,112,364,44),"Weiter [Leertaste]" if paused else "Pause [Leertaste]",func(): paused = not paused,GREEN)
  _button(Rect2(1038,166,175,34),"Tempo x%d" % int(speed),func(): speed = 1.0 if speed == 4 else speed*2)
  _button(Rect2(1224,166,178,34),"Zum Ergebnis",_finish_playback)
  _label("Kampfzeit: %.1f s" % (int(playback.frames[frame_index].tick)/10.0),Rect2(1040,213,360,25),20,INK)
  _label("Blau = Mana   Grün = Leben",Rect2(1040,245,360,22),18,MUTED)
  _label("Klicke eine Figur für aktuelle Werte.",Rect2(1040,273,360,19),16,MUTED)
 else:
  var finished = s.phase == "finished"
  _button(Rect2(1038,112,364,44),"Neues Abenteuer" if finished else "Kampf starten [Leertaste]",func():
   if finished:
    reset_open = true
   else:
    _send({"type":"battle"}),GREEN)
  _button(Rect2(1038,166,175,34),"Shop: %d G [R]" % game.reroll_cost(),_send.bind({"type":"reroll"}),PAPER,not finished and s.gold >= game.reroll_cost())
  _button(Rect2(1224,166,178,34),"%d EP: 4 G [E]" % (4+int(game.augments.value(s.augments,"xp_buy"))),_send.bind({"type":"xp"}),PAPER,not finished and s.gold >= 4 and s.level < 10)
  _button(Rect2(1038,210,175,32),"Shop gesperrt" if s.locked else "Shop sperren",_send.bind({"type":"lock"}),GOLD if s.locked else PAPER,not finished)
  _button(Rect2(1224,210,178,32),"Replay",_replay,PAPER,not game.last_battle.is_empty())
  _label("Shop-Chancen nach Kosten (1 / 2 / 3 / 4 / 5)",Rect2(1040,252,360,20),16,MUTED)
  _label(" / ".join(MatchModel.SHOP_ODDS[int(s.level)].map(func(n): return "%d%%" % n)),Rect2(1040,277,360,19),18,INK)
 _details(combat)
 _panel(Rect2(1024,688,392,109),PAPER)
 _label("EINKOMMEN & ZINSEN",Rect2(1040,698,360,24),20,INK)
 var interest = mini(5,int(s.gold/10))
 _label("%d Gold · Zinsen +%d · %s" % [int(s.gold),interest,"Maximum" if interest == 5 else "nächste Schwelle %d G" % ((int(s.gold/10)+1)*10)],Rect2(1040,726,360,23),16,INK)
 if not s.income.is_empty():
  var b = s.income
  _wrap("Letzte Auszahlung: %d Basis + %d Fortschritt + %d Zins + %d Ergebnis + %d Augment = %d G" % [b.base,b.progress,b.interest,b.result,b.augments,b.total],Rect2(1040,753,360,36),14,MUTED)
 _panel(Rect2(1024,809,392,110),PAPER)
 var color = GREEN if s.outcome == "win" else (RED if s.outcome == "loss" else BLUE)
 if combat:
  _label("KAMPFPROTOKOLL",Rect2(1040,819,360,24),20,INK)
  for i in range(mini(3,combat_log.size())):
   _label(combat_log[i],Rect2(1040,847+i*20,360,20),16,MUTED)
 else:
  var verdict = {"win":"SIEG!","loss":"NIEDERLAGE - 1 LEBEN","draw":"UNENTSCHIEDEN","none":"AUF NACH KANTO!"}[s.outcome]
  if s.phase == "finished":
   verdict = "KANTO-MEISTER!" if s.lives > 0 else "KEINE LEBEN MEHR"
  _label(verdict,Rect2(1040,820,360,26),22,color)
  var detail = "Runde %d bleibt. Versuch %d." % [int(s.round),int(s.attempt)] if s.outcome in ["loss","draw"] else "Nächste Herausforderung: Runde %d." % int(s.round)
  if s.phase == "finished":
   detail = "%d von 30 Runden gewonnen." % int(s.wins)
  _label(detail,Rect2(1040,851,360,22),18,INK)
  _label("%d Leben | %d Siege | Nur diese Sitzung" % [int(s.lives),int(s.wins)],Rect2(1040,881,360,22),16,MUTED)
 if result_time > 0:
  draw_rect(Rect2(1021,806,398,116),Color(color, minf(1,result_time/0.7)),false,4)

func _detail_unit() -> Dictionary:
 if not playback.is_empty() and not inspected.is_empty():
  for unit in playback.frames[frame_index].units:
   if unit.uid == inspected.uid:
    return unit
 var unit = game.find_unit(selected)
 return inspected if unit.is_empty() else unit

func _details(combat: bool):
 _panel(Rect2(1024,319,392,356),PAPER)
 var unit = _detail_unit()
 if unit.is_empty():
  _label("DEIN POKÉDEX",Rect2(1040,332,360,32),24,INK)
  _ball(Vector2(1220,415),29)
  _wrap("Wähle ein Pokémon. Hier siehst du Rolle, Fähigkeit und seine aktuellen Kampfwerte.",Rect2(1040,469,360,82),20,INK)
  _wrap("Ziehen: Bank und eigene Felder. Grüne Ziele sind gültig; besetzte Ziele tauschen die Figuren.",Rect2(1040,574,360,80),18,MUTED)
  return
 var mon = catalog.get_mon(int(unit.species))
 var stats = catalog.stats(unit)
 _label(catalog.display_name(unit),Rect2(1040,330,275,31),26,INK)
 _sprite(catalog.sprite_id(unit),Rect2(1337,331,61,61))
 _label("%s | %d Sterne | %d G" % [mon.role,int(unit.star),int(mon.cost)],Rect2(1040,365,290,25),18,_type_color(mon))
 _label("LP %d/%d   ATK %d   DEF %d" % [int(unit.get("hp",stats.hp)),int(unit.get("max_hp",stats.hp)),int(unit.get("attack",stats.attack)),int(unit.get("armor",stats.armor))],Rect2(1040,397,360,22),16,INK)
 var mana = int(unit.get("mana",0))
 _label("Mana %d / %d · Reichweite %d Tiles" % [mana,int(mon.mana),int(mon.range)],Rect2(1040,423,360,21),18,INK)
 _bar(Rect2(1040,445,360,6),float(mana)/int(mon.mana),BLUE)
 _label("%s [%d Mana]" % [mon.ability,int(mon.mana)],Rect2(1040,453,360,25),20,INK)
 _wrap(mon.description,Rect2(1040,483,360,76),17,INK)
 _hit(Rect2(1040,453,360,105),func(): message = mon.ability_range,mon.ability_range)
 _wrap(Catalog.ROLES[mon.role].text,Rect2(1040,563,360,43),16,MUTED)
 _label("Angriff: %s · Fähigkeit: %s" % [mon.attack_type,mon.ability_type],Rect2(1040,605,360,20),14,MUTED)
 if combat:
  var names = {"poison":"Gift","burn":"Brand","stun":"Betäubt","slow":"Langsam","break":"Rüstung -18","taunt":"Provoziert","haste":"Tempo +35%"}
  var status = []
  for key in unit.get("status",{}):
   status.append(names.get(key,key))
  _wrap("Status: " + (", ".join(status) if not status.is_empty() else "bereit") + " | Schild: %d" % int(unit.get("shield",0)),Rect2(1040,627,360,36),16,BLUE)
 elif selected >= 0:
  var value = int(mon.cost)*int(pow(3,int(unit.star)-1))
  _button(Rect2(1040,629,360,32),"Verkaufen: %d Gold [Entf]" % value,_send.bind({"type":"sell","uid":selected}),RED,game.state.phase == "planning")

func _unit(rect: Rect2,unit: Dictionary,enemy: bool,combat: bool,alpha: float = 1.0,grounded: bool = false):
 if not enemy and unit.uid == selected:
  draw_rect(rect.grow(-2),GOLD,false,2)
  var at = rect.position+Vector2(4,rect.size.y-21)
  draw_colored_polygon(PackedVector2Array([at,at+Vector2(6,4),at+Vector2(0,8)]),INK)
 # Bank cards have a six-pixel frame; only the inner surface holds content.
 var content = rect if grounded else rect.grow(-6)
 var area = _sprite_area(content) if grounded else Rect2(content.position,Vector2(content.size.x,content.size.y-30))
 var sprite_size = minf(minf(area.size.x,area.size.y),76)
 var box = Rect2(area.get_center()-Vector2.ONE*sprite_size/2,Vector2.ONE*sprite_size)
 if grounded: box.position.y = area.end.y-sprite_size
 if unit.star == 3 and catalog.get_mon(unit.species).cost == 5:
  _ring(area.get_center(),int(minf(24,area.size.y/2)),Color(GOLD,0.8))
  _pixel_star(area.get_center()+Vector2(0,-area.size.y/2),GOLD)
 if combat: box.position += _combat_sprite_offset(unit.uid)*0.4
 var phase_alpha = 0.18 if combat and unit.get("phantom_until",0)>playback.frames[frame_index].tick else 1.0
 if unit.get("summon_stage","") == "larva":
  for i in range(3):
   draw_rect(Rect2(box.get_center()+Vector2(i*5-7,-3),Vector2(6,6)),Color("90b850"))
  draw_rect(Rect2(box.get_center()+Vector2(6,-3),Vector2(2,2)),INK)
 else: _sprite(catalog.sprite_id(unit),box,alpha*phase_alpha,grounded)
 if combat:
  if unit.get("phantom_until",0) > playback.frames[frame_index].tick: _ring(area.get_center(),12,Color(BLUE,0.7))
  var marks = []
  if unit.get("growth",0)>0: marks.append("W%d" % unit.growth)
  if unit.get("heat",0)>0: marks.append("H%d" % unit.heat)
  if unit.get("spirit",0)>0: marks.append("K%d" % unit.spirit)
  if unit.get("blessed",false): marks.append("S")
  if unit.get("growth",0)>=20: marks.append("BL")
  if unit.get("unstoppable_until",0)>playback.frames[frame_index].tick: marks.append("U")
  if unit.get("toxin",0)>0: marks.append("G%d" % unit.toxin)
  if unit.get("frost",0)>0: marks.append("F%d" % unit.frost)
  if not marks.is_empty(): _label(" ".join(marks),Rect2(area.position+Vector2(0,-14),Vector2(area.size.x,14)),11,INK,HORIZONTAL_ALIGNMENT_CENTER)
 if not grounded: _unit_metadata(content,unit,enemy,combat,alpha)

func _combat_units():
 var frame = playback.frames[frame_index]
 var previous = playback.frames[maxi(0,frame_index-1)]
 var ordered = []
 for unit in frame.units:
  var alpha = 1.0
  if unit.hp <= 0:
   alpha = 0.0
   for effect in effects:
    if effect.kind == "defeat" and effect.get("event",{}).get("to",-1) == unit.uid:
     alpha = maxf(alpha,1.0-effect.age/effect.duration)
   if alpha <= 0: continue
  var pos = Vector2(unit.x,unit.y)
  for old in previous.units:
   if old.uid == unit.uid:
    pos = Vector2(old.x,old.y).lerp(pos,1.0 if paused else clampf(elapsed/0.1,0,1))
    break
  ordered.append({"unit":unit,"pos":pos,"alpha":alpha})
 ordered.sort_custom(func(a,b): return a.pos.y < b.pos.y if a.pos.y != b.pos.y else a.unit.uid < b.unit.uid)
 depth_order = ordered.map(func(entry): return entry.pos.y)
 for row in range(6):
  for entry in ordered:
   if int(entry.pos.y) != row: continue
   _world_unit(entry.pos,entry.unit,entry.unit.side == 1,true,entry.alpha)
   var center = _sprite_area(world_rect(entry.pos)).get_center()
   if entry.unit.get("frozen_until",0)>frame.tick:
    _trait_fx({"event":{"spell":"freeze"},"kind":"status","a":center,"b":center},fmod(clock_time,1.0))
   if entry.unit.get("toxin",0)>0:
    ability_fx.stamp(self,"poisonwisp",center+Vector2(-14,-10),10+mini(8,int(entry.unit.toxin)),Color(1,1,1,0.75))
   if entry.unit.get("growth",0)>0:
    ability_fx.stamp(self,"leaf1",center+Vector2(15,8),10+mini(8,int(entry.unit.growth)/2),Color(1,1,1,0.8))
   for kind in entry.unit.status:
    if entry.unit.status[kind] > 0 and kind in ["burn","poison","freeze","stun"]:
     _trait_fx({"event":{"spell":kind},"kind":"status","a":center,"b":center},fmod(clock_time,1.0))
   _hit(world_rect(entry.pos),_inspect.bind(entry.unit),_unit_tip(entry.unit))
  _draw_effects(row)

func _combat_nameplates():
 pass # Metadata is already in a separate, reserved region below each sprite.

func _combat_sprite_offset(uid: int) -> Vector2:
 var offset = Vector2.ZERO
 for effect in effects:
  var event = effect.get("event",{})
  if event.is_empty():
   continue
  var t = clampf(effect.age/effect.duration,0,1)
  if effect.kind == "attack" and event.from == uid:
   offset += (effect.b-effect.a).normalized()*sin(t*PI)*8
  elif effect.kind == "hit" and event.to == uid and t < 0.55:
   offset.x += sin(effect.age*60)*3
  elif effect.kind == "cast" and event.from == uid:
   offset.y -= sin(t*PI)*5
 return offset.limit_length(10).round()

func _draw_combat_auras():
 for effect in effects:
  if effect.kind not in ["cast","heal","shield","hit"]:
   continue
  var t = clampf(effect.age/effect.duration,0,1)
  var color = Color(GREEN if effect.kind == "heal" else BLUE,0.2*(1-t))
  if effect.kind == "cast":
   color = Color(_type_color(catalog.get_mon(int(effect.event.species))),0.25*(1-t))
  elif effect.kind == "hit":
   color = Color(1,0.9,0.55,0.3*(1-t))
  draw_rect(Rect2(effect.b-Vector2(58,28),Vector2(116,56)),color)
  if effect.kind == "cast":
   draw_rect(Rect2(effect.a-Vector2(58,28),Vector2(116,56)),color)

func _hide_unit(unit: Dictionary,enemy: bool) -> bool:
 if enemy:
  return false
 if unit.uid == drag_uid:
  return true
 for effect in effects:
  if effect.kind == "return" and effect.unit.uid == unit.uid:
   return true
 return false

func _sprite(id: int,rect: Rect2,alpha: float = 1.0,grounded: bool = false):
 if not textures.has(id):
  return
 if idle.has(id):
  var animation = idle[id]
  var frame = idle_frame(id,clock_time+id*0.137)
  var crop = Rect2(Vector2(frame%animation.columns,int(frame/animation.columns))*Vector2(animation.width,animation.height),Vector2(animation.width,animation.height))
  var factor = minf(rect.size.x/crop.size.x,rect.size.y/crop.size.y)
  var extent = (crop.size*factor).round()
  var dest = Rect2((rect.position+(rect.size-extent)/2).round(),extent)
  if grounded: dest.position.y = roundf(rect.end.y-extent.y)
  draw_texture_rect_region(animation.texture,dest,crop,Color(1,1,1,alpha),false)
  return
 var crop = Rect2(crops[id])
 var factor = minf(rect.size.x/crop.size.x,rect.size.y/crop.size.y)
 var extent = (crop.size*factor).round()
 var dest = Rect2((rect.position+(rect.size-extent)/2).round(),extent)
 if grounded: dest.position.y = roundf(rect.end.y-extent.y)
 draw_texture_rect_region(textures[id],dest,crop,Color(1,1,1,alpha),false)

func _type_color(mon: Dictionary) -> Color:
 return Color(Catalog.COLORS.get(mon.types[0],{"Boden":"8a6038","Unlicht":"514a65","Fee":"994c7b"}.get(mon.types[0],"465c55")))

func _panel(rect: Rect2,fill: Color,heavy: bool = true):
 var step = 4 if heavy else 2
 # Stepped corners and slate/white bevels match GBA dialog windows.
 draw_rect(Rect2(rect.position+Vector2(step,0),rect.size-Vector2(step*2,0)),Color("505868"))
 draw_rect(Rect2(rect.position+Vector2(0,step),rect.size-Vector2(0,step*2)),Color("505868"))
 draw_rect(rect.grow(-2),Color("a0a8b8"))
 draw_rect(rect.grow(-4),Color("ffffff"))
 draw_rect(rect.grow(-6 if heavy else -4),fill)
 if heavy:
  draw_line(rect.position+Vector2(6,rect.size.y-5),rect.end-Vector2(5,5),Color("c0c0c8"),2)
  draw_line(rect.position+Vector2(rect.size.x-5,6),rect.end-Vector2(5,5),Color("c0c0c8"),2)

func _bar(rect: Rect2,ratio: float,color: Color):
 draw_rect(rect,Color("303e48"))
 if rect.size.y >= 5: draw_rect(rect.grow(1),INK,false,1)
 draw_rect(Rect2(rect.position,Vector2(floor(rect.size.x*clampf(ratio,0,1)),rect.size.y)),color)

func _label(value: String,rect: Rect2,size_px: int,color: Color = INK,alignment: int = HORIZONTAL_ALIGNMENT_LEFT,exact_size: bool = false):
 var selected_font = heading_font if size_px >= 22 else font
 size_px = clampi(size_px,11,32) if exact_size else (32 if size_px >= 22 else 16)
 var shaped = _shaped(value,selected_font,size_px)
 var measured = shaped.get_size().x
 if measured > rect.size.x:
  selected_font = narrow_font
  shaped = _shaped(value,selected_font,size_px)
  measured = shaped.get_size().x
 while (measured+1 > rect.size.x or shaped.get_size().y+1 > rect.size.y) and size_px > 11:
  size_px -= 1
  shaped = _shaped(value,selected_font,size_px)
  measured = shaped.get_size().x
 var x = rect.position.x
 if alignment == HORIZONTAL_ALIGNMENT_CENTER: x += (rect.size.x-measured)/2
 elif alignment == HORIZONTAL_ALIGNMENT_RIGHT: x += rect.size.x-measured
 var at = Vector2(round(x),round(rect.position.y+(rect.size.y-shaped.get_size().y-1)/2))
 at.x = maxf(ceil(rect.position.x),minf(at.x,floor(rect.end.x-measured-1)))
 var painted = Rect2(at,shaped.get_size()+Vector2.ONE)
 text_boxes.append({"text":value,"rect":rect,"painted":painted,"width":measured,"font_size":size_px})
 shaped.draw(get_canvas_item(),at+Vector2(1,1),Color("b8b8b0",color.a*0.7) if color.get_luminance() < 0.5 else Color("384858",color.a*0.8))
 shaped.draw(get_canvas_item(),at,color)

func _shaped(value: String,selected_font: Font,size_px: int) -> TextLine:
 var key = "%s|%s|%s" % [selected_font.get_instance_id(),size_px,value]
 if shaped_cache.has(key): return shaped_cache[key]
 var line = TextLine.new()
 line.add_string(value,selected_font,size_px)
 if shaped_cache.size() > 4096: shaped_cache.clear()
 shaped_cache[key] = line
 return line

func _lines(value: String,width: float,size_px: int) -> Array:
 var key = "%s|%s|%s" % [value,width,size_px]
 if line_cache.has(key): return line_cache[key]
 var lines = []
 for paragraph in value.split("\n"):
  var line = ""
  for word in paragraph.split(" "):
   var candidate = word if line.is_empty() else line+" "+word
   if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x > width and not line.is_empty():
    lines.append(line)
    line = word
   else:
    line = candidate
  lines.append(line)
 if line_cache.size() > 2048: line_cache.clear()
 line_cache[key] = lines
 return lines

func _line_height(lines: Array,size_px: int) -> int:
 var height = 0
 for line in lines:
  height = maxi(height,ceili(_shaped(line,font,size_px).get_size().y)+2)
 return height

func _wrap(value: String,rect: Rect2,size_px: int,color: Color):
 size_px = 16
 var lines = _lines(value,rect.size.x,size_px)
 var line_height = _line_height(lines,size_px)
 while lines.size()*line_height > rect.size.y and size_px > 12:
  size_px -= 1
  lines = _lines(value,rect.size.x,size_px)
  line_height = _line_height(lines,size_px)
 for i in range(lines.size()):
  _label(lines[i],Rect2(rect.position+Vector2(0,i*line_height),Vector2(rect.size.x,line_height)),size_px,color,HORIZONTAL_ALIGNMENT_LEFT,true)
 if lines.size()*line_height > rect.size.y:
  text_boxes.append({"text":"VERTICAL: "+value,"rect":rect,"width":rect.size.x+1,"font_size":size_px})

func label_overflows() -> Array:
 return text_boxes.filter(func(box): return box.width > box.rect.size.x+0.1 or (box.has("painted") and not box.rect.grow(1).encloses(box.painted)))

func _button(rect: Rect2,label: String,callback: Callable,fill: Color = PAPER,enabled: bool = true):
 var hover = rect.has_point(pointer) and enabled and drag_uid < 0 and not help_open and not reset_open
 _panel(rect,Color("f8e8a0") if hover else fill)
 if hover:
  var cursor = rect.position+Vector2(9,rect.size.y/2-4)
  draw_colored_polygon(PackedVector2Array([cursor,cursor+Vector2(6,4),cursor+Vector2(0,8)]),Color("303038"))
 draw_rect(Rect2(rect.position+Vector2(3,rect.size.y-5),Vector2(rect.size.x-6,2)),Color(INK,0.25))
 _label(label,Rect2(rect.position+Vector2(19,6),rect.size-Vector2(27,12)),18,(PAPER if fill in [GREEN,RED] else INK) if enabled else Color("859084"),HORIZONTAL_ALIGNMENT_CENTER)
 if enabled:
  _hit(rect,callback,label)

func _hit(rect: Rect2,callback: Callable,tip: String):
 hits.append({"rect":rect,"callback":callback,"tip":tip})

func _slot_at(point: Vector2) -> Dictionary:
 for slot in slots:
  if _contains(slot,point):
   return slot
 return {}

func _input(event):
 if event is InputEventScreenTouch:
  if event.pressed and touch_id == -1:
   touch_id = event.index
  if event.index != touch_id: return
  if event.canceled:
   _cancel_drag()
   touch_id = -1
   return
  var mouse = InputEventMouseButton.new()
  mouse.button_index = MOUSE_BUTTON_LEFT
  mouse.pressed = event.pressed
  _pointer_input(mouse,get_global_transform_with_canvas().affine_inverse()*event.position)
  if not event.pressed: touch_id = -1
 elif event is InputEventScreenDrag:
  if event.index == touch_id:
   _pointer_input(InputEventMouseMotion.new(),get_global_transform_with_canvas().affine_inverse()*event.position)
 elif event is InputEventMouseMotion or event is InputEventMouseButton:
  if touch_id == -1 and event.device != InputEvent.DEVICE_ID_EMULATION:
   _pointer_input(event,get_global_transform_with_canvas().affine_inverse()*event.position)
 elif event is InputEventKey:
  _key_input(event)

func _pointer_input(event,point: Vector2):
 pointer = point
 if event is InputEventMouseMotion:
  if press_uid >= 0 and drag_uid < 0 and point.distance_to(press_at) >= 6:
   drag_uid = press_uid
   selected = drag_uid
  return
 if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
  _cancel_drag()
  selected = -1
  inspected = {}
  return
 if event.button_index != MOUSE_BUTTON_LEFT:
  return
 if event.pressed:
  press_at = point
  pressed_hit = {}
  press_uid = -1
  for hit in hits:
   if _contains(hit,point):
    pressed_hit = hit
    break
  if playback.is_empty() and game.state.phase == "planning" and not help_open and not reset_open and not start_open and trait_open.is_empty() and game.state.augment_offers.is_empty():
   var slot = _slot_at(point)
   if not slot.is_empty():
    var unit = game.at(slot.zone,slot.slot)
    if not unit.is_empty():
     press_uid = int(unit.uid)
     drag_unit = unit.duplicate(true)
     drag_origin = {"zone":unit.zone,"slot":unit.slot}
     drag_revision = int(game.state.revision)
 else:
  if drag_uid >= 0:
   var target = _slot_at(point)
   var result = {"ok":false,"message":"Ungültiges Ziel: Pokémon kehrt zurück."}
   if not target.is_empty():
    result = _send({"type":"move","uid":drag_uid,"zone":target.zone,"slot":target.slot},drag_revision)
   if not result.ok:
    message = result.message
    message_error = true
    _visual("return",point,slot_rect(drag_origin.zone,drag_origin.slot).get_center(),drag_unit,0.22)
   selected = -1
   _clear_drag()
  else:
   var clicked = pressed_hit
   _clear_drag()
   if not clicked.is_empty() and _contains(clicked,point):
    clicked.callback.call()

func _clear_drag():
 drag_uid = -1
 press_uid = -1
 pressed_hit = {}
 drag_unit = {}
 drag_origin = {}
 drag_revision = -1

func _cancel_drag():
 if drag_uid >= 0 and not drag_origin.is_empty():
  _visual("return",pointer,slot_rect(drag_origin.zone,drag_origin.slot).get_center(),drag_unit,0.2)
 _clear_drag()

func _notification(what):
 if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
  _cancel_drag()

func _key_input(event):
 if not event.pressed or event.echo:
  return
 if event.keycode == KEY_F11:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
  return
 if event.keycode == KEY_ESCAPE:
  if is_instance_valid(shell):
   shell.leave_game(false)
   return
  if not trait_open.is_empty():
   trait_open = ""
   return
  _cancel_drag()
  help_open = false
  reset_open = false
  selected = -1
  return
 if drag_uid >= 0 or press_uid >= 0 or help_open or reset_open or start_open or not game.state.augment_offers.is_empty():
  return
 match event.keycode:
  KEY_SPACE:
   if playback.is_empty():
    _send({"type":"battle"})
   else:
    paused = not paused
  KEY_R: _send({"type":"reroll"})
  KEY_E: _send({"type":"xp"})
  KEY_DELETE:
   if selected >= 0:
    _send({"type":"sell","uid":selected})
  KEY_F1: help_open = true

func _draw_drag():
 var hovered = _slot_at(pointer)
 valid_drag_slots.clear()
 for slot in slots:
  var valid = game.validate_move(drag_uid,slot.zone,slot.slot).ok and drag_revision == game.state.revision
  if not valid: continue
  valid_drag_slots.append(slot)
  if slot.has("polygon"):
   var p = slot.polygon
   draw_polyline(PackedVector2Array([p[0],p[1],p[2],p[3],p[0]]),Color("eafbba"),2)
  else: draw_rect(slot.rect.grow(-2),Color(GREEN if valid else RED,0.65),false,2)
 if not hovered.is_empty():
  var valid = game.validate_move(drag_uid,hovered.zone,hovered.slot).ok and drag_revision == game.state.revision
  if hovered.has("polygon"):
   draw_colored_polygon(hovered.polygon,Color(GREEN if valid else RED,0.3))
   if valid: _world_unit(Vector2(hovered.slot%7,3+int(hovered.slot/7)),drag_unit,false,false,0.5)
  else:
   draw_rect(hovered.rect,Color(GREEN if valid else RED,0.22))
   if valid: _unit(hovered.rect,drag_unit,false,false,0.5)
 _sprite(catalog.sprite_id(drag_unit),Rect2(pointer-Vector2(30,50),Vector2(60,60)),0.95)

func _select_slot(zone: String,slot: int):
 var unit = game.at(zone,slot)
 selected = int(unit.uid) if not unit.is_empty() else -1
 inspected = {}

func _inspect(unit: Dictionary):
 inspected = unit.duplicate(true)
 selected = -1

func _unit_tip(unit: Dictionary) -> String:
 var mon = catalog.get_mon(int(unit.species))
 return "%s | %s\n%s [%d Mana]\n%s" % [catalog.display_name(unit),mon.role,mon.ability,int(mon.mana),"\n".join(_lines(mon.description,420,16))]+"\n"+catalog.evolution_text(unit)

func _get_tooltip(point: Vector2) -> String:
 if drag_uid >= 0:
  return ""
 for hit in hits:
  if _contains(hit,point):
   return hit.tip
 return ""

func _send(action: Dictionary,revision: int = -1) -> Dictionary:
 if not playback.is_empty():
  return {"ok":false,"message":"Während des Kampfes ist die Aufstellung gesperrt."}
 var old_units = game.state.units.duplicate(true)
 var result = game.command(action,int(game.state.revision) if revision < 0 else revision)
 message = result.message
 message_error = not result.ok
 if result.ok:
  if action.type == "battle":
   _replay()
  else:
   _action_effects(action,old_units)
  if game.find_unit(selected).is_empty():
   selected = -1
 return result

func _replay():
 if game.last_battle.is_empty():
  return
 _cancel_drag()
 playback = game.last_battle
 frame_index = 0
 last_visual_tick = -1
 elapsed = 0
 paused = false
 selected = -1
 inspected = {}
 effects.clear()
 combat_log.clear()

func _finish_playback():
 playback = {}
 frame_index = 0
 effects.clear()
 message = game.state.last_result
 result_time = 2.5
 if game.state.outcome == "loss":
  _visual("life",Vector2(678,50),Vector2(678,110),{},1.0)
 elif game.state.outcome == "win":
  _visual("victory",Vector2(1218,820),Vector2(1218,820),{},1.4)

 if game.state.phase == "finished" and is_instance_valid(shell):
  shell.show_screen("result")

func _new_game():
 if OS.has_feature("web"):
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
 game = MatchModel.new(int(Time.get_unix_time_from_system())%1000000000,chosen_difficulty)
 selected = -1
 inspected = {}
 playback = {}
 effects.clear()
 combat_log.clear()
 help_open = false
 reset_open = false
 start_open = false
 message = "Neue Expedition · "+chosen_difficulty+" · 3 Leben"

func _draw_modal():
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.06,0.13,0.17,0.88))
 hits.clear()
 slots.clear()
 if start_open or reset_open:
  var r = Rect2(Vector2(size.x*0.12,size.y*0.17),Vector2(size.x*0.76,size.y*0.66))
  _panel(r,PAPER)
  _label("DEINE NÄCHSTE EXPEDITION",Rect2(r.position+Vector2(20,20),Vector2(r.size.x-40,40)),28,INK,HORIZONTAL_ALIGNMENT_CENTER)
  _label("Wähle die Herausforderung für alle 30 Runden.",Rect2(r.position+Vector2(20,68),Vector2(r.size.x-40,28)),18,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
  var i = 0
  for level in MatchModel.Difficulty.SETTINGS:
   var width = (r.size.x-56)/3
   var box = Rect2(r.position+Vector2(16+i*(width+12),117),Vector2(width,r.size.y-197))
   _panel(box,Color("d4e8bb") if chosen_difficulty == level else Color("e6e9df"))
   _label(level,Rect2(box.position+Vector2(10,9),Vector2(box.size.x-20,32)),24,INK,HORIZONTAL_ALIGNMENT_CENTER)
   _wrap(MatchModel.Difficulty.SETTINGS[level].text,Rect2(box.position+Vector2(13,55),Vector2(box.size.x-26,box.size.y-65)),16,INK)
   _hit(box,func(): chosen_difficulty = level,MatchModel.Difficulty.SETTINGS[level].text)
   i += 1
  layout.confirm_start = Rect2(r.position+Vector2(r.size.x/2+8,r.size.y-56),Vector2(r.size.x/2-26,38))
  _button(layout.confirm_start,"Mit "+chosen_difficulty+" starten",_new_game,GREEN)
  if not start_open: _button(Rect2(r.position+Vector2(18,r.size.y-56),Vector2(r.size.x/2-26,38)),"Abbrechen",func(): reset_open = false)
  return
 var r = Rect2(size*Vector2(0.14,0.1),size*Vector2(0.72,0.8))
 _panel(r,PAPER)
 _label("TRAINER-HANDBUCH",Rect2(r.position+Vector2(18,15),Vector2(r.size.x-36,35)),26,INK)
 _wrap("ZIEHEN: Pokémon ausschließlich per Drag-and-drop bewegen, auch per Touch. Klicks zeigen Details. Besetzte Ziele tauschen. Ungültige Ziele, Esc oder Fokusverlust brechen sicher ab.\n\nKAMPF: Leertaste startet oder pausiert. Freie Teamplätze werden von der Bank aufgefüllt. Nur Siege erhöhen die Runde; Niederlagen kosten ein Leben. Drei Leben, 30 Siegrunden.\n\nFORTSCHRITT: Level bis 10, Zinsen bis 5 Gold. Drei gleiche Exemplare entwickeln sich. Augments vor Runde 5, 12 und 20. Synergien bei 2 und 4 verschiedenen Linien.\n\nBEDIENUNG: R = Shop, E = EP, Entf = Verkaufen, F11 = Vollbild. Namen und Sterne bleiben unter den Animationen lesbar. Bewege den Zeiger über Preise, Fähigkeiten, Synergien und Augments für Erklärungen.",Rect2(r.position+Vector2(20,67),Vector2(r.size.x-40,r.size.y-135)),18,INK)
 _button(Rect2(r.position+Vector2(20,r.size.y-51),Vector2(r.size.x-40,35)),"Zurück zur Expedition",func(): help_open = false,GREEN)

func _visual(kind: String,from: Vector2,to: Vector2,unit: Dictionary,duration: float):
 effects.append({"kind":kind,"a":from,"b":to,"unit":unit.duplicate(true),"duration":duration,"age":0.0})

func _action_effects(action: Dictionary,before: Array):
 for old in before:
  var now = game.find_unit(int(old.uid))
  if action.type == "sell" and int(old.uid) == int(action.uid):
   _visual("sell",slot_rect(old.zone,old.slot).get_center(),Vector2(790,48),old,0.55)
  elif not now.is_empty() and (now.zone != old.zone or now.slot != old.slot):
   _visual("place",slot_rect(old.zone,old.slot).get_center(),slot_rect(now.zone,now.slot).get_center(),now,0.3)
  elif not now.is_empty() and now.star > old.star:
   _visual("evolve",slot_rect(now.zone,now.slot).get_center(),slot_rect(now.zone,now.slot).get_center(),now,1.2)
 if action.type == "buy":
  var old_ids = before.map(func(u): return u.uid)
  for unit in game.state.units:
   if unit.uid not in old_ids:
    _visual("buy",shop_rect(int(action.index)).get_center(),slot_rect(unit.zone,unit.slot).get_center(),unit,0.5)

func _frame_effects(frame: Dictionary):
 if frame.has("tick"):
  if int(frame.tick) == last_visual_tick: return
  last_visual_tick = int(frame.tick)
 for event in frame.events:
  if event.kind == "defeat":
   effects = effects.filter(func(e): return not (e.kind in ["cast","attack"] and e.has("event") and (e.event.from == event.to or e.event.to == event.to)))
  if event.kind == "effectiveness":
   combat_log.push_front(event.spell)
   combat_log = combat_log.slice(0,3)
  if event.kind == "move":
   continue # Movement already interpolates the unit itself.
  # Retrigger the same visual channel instead of layering identical flashes.
  # Authoritative battle events and combat logs are not altered.
  if event.kind in ["cast","mana","hit","status"]:
   effects = effects.filter(func(e): return not (e.kind == event.kind and e.has("event") and e.event.from == event.from and e.event.to == event.to))
  var duration = 0.2 if event.kind == "attack" else 0.35 if event.kind == "hit" and event.spell == "attack" else 0.8
  if event.kind == "cast":
   duration = 0.3
   var caster = {"species":event.species,"star":1}
   for unit in frame.get("units",[]):
    if unit.uid == event.from:
     caster = unit
     break
   combat_log.push_front(catalog.display_name(caster)+": "+event.spell)
   if combat_log.size() > 3:
    combat_log.pop_back()
  effects.append({"kind":event.kind,"a":_sprite_area(world_rect(Vector2(event.sx,event.sy))).get_center(),"b":_sprite_area(world_rect(Vector2(event.tx,event.ty))).get_center(),"event":event,"duration":duration,"age":0.0,"unit":{}})
 # Bound graphics memory only. Combat events and game state remain untouched.
 if effects.size() > 220:
  var excess = effects.size()-220
  for i in range(effects.size()-1,-1,-1):
   if excess == 0:
    break
   if effects[i].kind == "mana":
    effects.remove_at(i)
    excess -= 1
  if effects.size() > 220:
   effects = effects.slice(effects.size()-220)

func _draw_effects(depth_row: int = -1):
 for effect in effects:
  var t = clampf(effect.age/effect.duration,0,1)
  var alpha = clampf((1-t)*1.5,0,1)
  var event = effect.get("event",{})
  if event.is_empty() and depth_row >= 0: continue
  if not event.is_empty():
   if depth_row < 0 and not playback.is_empty(): continue
   if depth_row >= 0 and int(event.ty) != depth_row: continue
  if event.is_empty():
   if effect.kind == "return": _sprite(catalog.sprite_id(effect.unit),Rect2(effect.a.lerp(effect.b,t)-Vector2(16,16),Vector2(32,32)),alpha)
   elif effect.kind == "sell":
    var pos = effect.a.lerp(Vector2(size.x*0.58,40),t)
    draw_rect(Rect2(pos-Vector2(4,4),Vector2(8,8)),Color(GOLD,alpha))
   elif effect.kind in ["life","victory"]:
    var pos = Vector2(layout.main.get_center().x,112)
    _label("SIEG!" if effect.kind == "victory" else "−1 LEBEN",Rect2(pos-Vector2(110,18),Vector2(220,36)),28,Color(GOLD if effect.kind == "victory" else RED,alpha),HORIZONTAL_ALIGNMENT_CENTER)
   elif effect.kind in ["buy","place","evolve"]:
    var u = game.find_unit(effect.unit.get("uid",-1))
    if not u.is_empty():
     var r = _sprite_area(world_rect(Vector2(u.slot%7,3+int(u.slot/7)))) if u.zone == "board" else _sprite_area(slot_rect(u.zone,u.slot))
     _impact(r,effect.kind,Color(GOLD,alpha),t)
   continue
  if not playback.is_empty():
   for fighter in playback.frames[frame_index].units:
    if fighter.uid == event.from: effect.a = _sprite_area(world_rect(Vector2(fighter.x,fighter.y))).get_center()
    if fighter.uid == event.to: effect.b = _sprite_area(world_rect(Vector2(fighter.x,fighter.y))).get_center()
  var r = _sprite_area(world_rect(Vector2(event.tx,event.ty)))
  r.position = effect.b-r.size/2
  if r.size.y < 8: continue
  effect_regions.append(r)
  var color = Color(_type_color(catalog.get_mon(int(event.species))),alpha)
  if effect.kind == "attack":
   var a: Vector2 = effect.a
   var b: Vector2 = effect.b
   var pos = a.lerp(b,t)
   pos.y -= sin(t*PI)*24
   draw_line(pos-(b-a).normalized()*10,pos,color,3)
   draw_rect(Rect2(pos.round()-Vector2(3,3),Vector2(6,6)),color)
  elif effect.kind == "ability_impact":
   ability_fx.draw(self,effect,t)
  elif effect.kind in ["field","shield_break","absorb","cleanse"]:
   _trait_fx(effect,t)
  elif effect.kind in ["cast","hit","shield","heal","mana","status","defeat","effectiveness"]:
   if effect.kind != "cast": _impact(r,effect.kind,Color(GREEN,alpha) if effect.kind == "heal" else color,t)
   if effect.kind == "shield":
    _ring(effect.b,14+int(t*9),Color("a8d8ff",alpha))
    ability_fx.stamp(self,"gear",effect.b,22,Color(1,1,1,alpha*0.65))
   elif effect.kind == "defeat":
    for i in range(5): draw_rect(Rect2(effect.b+Vector2((i-2)*5,-t*(12+i*3)),Vector2(3,3)),Color("e8e8f0",alpha))
   if effect.kind == "cast":
    if event.spell == catalog.get_mon(int(event.species)).ability: ability_fx.draw(self,effect,t)
    else: _trait_fx(effect,t)
   if effect.kind in ["hit","heal","status"] and event.spell != "attack" and event.spell != catalog.get_mon(int(event.species)).ability: _trait_fx(effect,t)
   if effect.kind == "effectiveness":
    _label("IMMUN" if event.amount == 0 else "×"+str(event.amount/100.0),r,12,Color(INK,alpha),HORIZONTAL_ALIGNMENT_CENTER)

func _ground_effects():
 if not playback.is_empty():
  for field in playback.frames[frame_index].get("fields",[]):
   for tile in field.tiles:
    var poly = tile_polygon(tile.x,tile.y)
    draw_colored_polygon(poly,Color(0.15,0.55,0.95,0.26) if field.kind == "water" else Color(0.3,0.2,0.12,0.4))
    if field.kind == "rift":
     var c = project_grid(tile.x+0.5,tile.y+0.5)
     draw_polyline(PackedVector2Array([c+Vector2(-12,-3),c+Vector2(2,1),c+Vector2(-3,4),c+Vector2(11,7)]),INK,2)
 for effect in effects:
  if effect.kind not in ["ability_impact","shield","heal","status"] or not effect.has("event"): continue
  var e = effect.event
  var t = effect.age/effect.duration
  if effect.kind == "ability_impact" and e.get("selector","") in ["area","near_enemies","all_enemies","all_allies"]:
   draw_colored_polygon(tile_polygon(int(e.tx),int(e.ty)),Color(ability_fx.recipe(e).get("color","88b888"),0.22*(1-t)))
  var foot = project_grid(e.tx+0.5,e.ty+0.5)-Vector2(0,5)
  var color = _type_color(catalog.get_mon(int(e.species)))
  draw_ellipse_shadow(foot,Vector2(10+24*t,3+7*t),Color(color,0.25*(1-t)))

func _trait_fx(effect: Dictionary,t: float):
 var event = effect.event
 var p: Vector2 = effect.b
 var color = Color("b0d8ff",1-t)
 match event.spell:
  "Überhitzen":
   for i in range(5): ability_fx.stamp(self,"fireball",p+Vector2((i-2)*7,-t*18),22,Color(1,1,1,1-t))
  "Kettenladung","Kettenfunke":
   var points = PackedVector2Array()
   for i in range(8): points.append(effect.a.lerp(p,i/7.0)+Vector2(0,(-1 if i%2 else 1)*6))
   draw_polyline(points,Color("ffe878",1-t),3,false)
  "Erdbeben":
   _ring(p,12+int(t*20),Color("c89860",1-t))
  "Erblüht","Metamorphose":
   for i in range(5): ability_fx.stamp(self,"leaf1",p+Vector2(cos(i*TAU/5+t)*20,sin(i*TAU/5+t)*10),15,Color(1,1,1,1-t))
  "Rückkehr","Zweite Lebensphase","Zweiter Atem":
   _heart(p+Vector2(0,-t*20),Color("88e8a8",1-t),2)
   _ring(p,10+int(t*16),Color("e8d878",1-t))
  "poison","Toxin": ability_fx.stamp(self,"poisonwisp",p+Vector2(0,-t*15),24,Color(1,1,1,1-t))
  "freeze","slow": ability_fx.stamp(self,"iceball",p,26,Color(1,1,1,1-t))
  "burn": ability_fx.stamp(self,"fireball",p+Vector2(0,-t*14),22,Color(1,1,1,1-t))
  "stun":
   for i in range(3): _pixel_star(p+Vector2(cos(t*7+i*TAU/3)*16,-15),Color("ffe878",1-t))
  _:
   if effect.kind == "shield_break":
    for i in range(6): draw_rect(Rect2(p+Vector2(cos(i*TAU/6),sin(i*TAU/6))*(8+t*18),Vector2(5,5)),color)
   elif effect.kind == "cleanse": _cross(p,14,color)
   elif effect.kind == "absorb": _ring(p,17,color)
   elif event.spell.begins_with("Fokus"):
    _ring(p,10+int(t*18),Color("e8a8ff",1-t))
    _ring(p,14+int(t*18),Color("e8a8ff",1-t))

func _effect_label(value: String,at_pos: Vector2,color: Color):
 var width = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x+12
 var rect = Rect2((at_pos-Vector2(width/2,11)).round(),Vector2(width,22))
 draw_rect(rect,Color(PAPER,0.92*color.a))
 draw_rect(rect,Color(INK,color.a),false,1)
 _label(value,rect.grow(-2),20,color,HORIZONTAL_ALIGNMENT_CENTER)

func _ring(at_pos: Vector2,radius: int,color: Color):
 var r = maxi(2,radius)
 draw_line(at_pos+Vector2(-r,-r/2.0),at_pos+Vector2(-r,r/2.0),color,2,false)
 draw_line(at_pos+Vector2(r,-r/2.0),at_pos+Vector2(r,r/2.0),color,2,false)
 draw_line(at_pos+Vector2(-r/2.0,-r),at_pos+Vector2(r/2.0,-r),color,2,false)
 draw_line(at_pos+Vector2(-r/2.0,r),at_pos+Vector2(r/2.0,r),color,2,false)

func _cross(at_pos: Vector2,radius: int,color: Color):
 draw_rect(Rect2(at_pos.round()-Vector2(2,radius),Vector2(4,radius*2)),color)
 draw_rect(Rect2(at_pos.round()-Vector2(radius,2),Vector2(radius*2,4)),color)

func _ball(at_pos: Vector2,radius: int):
 var r = radius
 draw_rect(Rect2(at_pos-Vector2(r,r-3),Vector2(r*2,r*2-6)),INK)
 draw_rect(Rect2(at_pos-Vector2(r-3,r),Vector2(r*2-6,r*2)),INK)
 draw_rect(Rect2(at_pos-Vector2(r-3,r-3),Vector2(r*2-6,r-3)),RED)
 draw_rect(Rect2(at_pos+Vector2(-r+3,3),Vector2(r*2-6,r-6)),PAPER)
 draw_rect(Rect2(at_pos-Vector2(4,4),Vector2(8,8)),INK)
 draw_rect(Rect2(at_pos-Vector2(2,2),Vector2(4,4)),PAPER)

func _heart(at_pos: Vector2,color: Color,scale_px: int):
 var pixels = ["0110110","1111111","1111111","0111110","0011100","0001000"]
 for y in range(pixels.size()):
  for x in range(7):
   if pixels[y][x] == "1":
    draw_rect(Rect2(at_pos+Vector2(x-3,y-3)*scale_px,Vector2(scale_px,scale_px)),color)

func _resize_layout():
 var w = size.x
 var h = size.y
 if w < 100 or h < 100: return
 var old_origin = BOARD_ORIGIN
 var old_step = CELL_STEP
 compact = w < 1600 or h < 800
 var side = clampf(w*0.285,350,420) if compact else clampf(w*0.18,300,390)
 var main_width = w-side-36 if compact else w-side*2-48
 var shop_h = 98.0 if h < 800 else 120.0
 var bank_h = 68.0 if h < 800 else 88.0
 layout = {"main":Rect2(12,86,main_width,h-112),"shop":Rect2(12,h-24-shop_h,main_width,shop_h),"bench":Rect2(12,h-24-shop_h-26-bank_h,main_width,bank_h)}
 var board_bottom = layout.bench.position.y-25
 BOARD_ORIGIN = Vector2(12,90)
 CELL_STEP = Vector2(main_width/7,(board_bottom-BOARD_ORIGIN.y)/6)
 CELL_SIZE = CELL_STEP-Vector2(5,5)
 if is_instance_valid(forest_view): forest_view.queue_free()
 forest_view = SubViewport.new()
 forest_view.size = Vector2i(ceili(main_width),ceili(CELL_STEP.y*6))
 forest_view.render_target_update_mode = SubViewport.UPDATE_ONCE
 forest_view.transparent_bg = true
 add_child(forest_view)
 var landscape = preload("res://ui/forest_layer.gd").new()
 landscape.size = forest_view.size
 forest_view.add_child(landscape)
 var x = main_width+24
 layout.actions = Rect2(x,70,side,78 if compact else 92)
 layout.info = Rect2(x,layout.actions.end.y+8,side,240 if compact else clampf(h*0.4,340,440))
 if compact:
  var remaining = h-24-layout.info.end.y-16
  layout.synergies = Rect2(x,layout.info.end.y+8,side,remaining-112)
  layout.augments = Rect2(x,layout.synergies.end.y+8,side,104)
 else:
  layout.economy = Rect2(x,layout.info.end.y+8,side,112)
  layout.result = Rect2(x,layout.economy.end.y+8,side,h-24-layout.economy.end.y-8)
  layout.synergies = Rect2(x+side+12,70,side,(h-94)*0.65-8)
  layout.augments = Rect2(x+side+12,layout.synergies.end.y+8,side,h-24-layout.synergies.end.y-8)
 layout.help = Rect2(w-252,12,110,38)
 layout.new_game = Rect2(w-132,12,120,38)
 # Resolve active animation anchors into the new grid; dragging itself retains its original revision.
 for effect in effects:
  if not effect.get("event",{}).is_empty():
   var e = effect.event
   effect.a = _sprite_area(world_rect(Vector2(e.sx,e.sy))).get_center()
   effect.b = _sprite_area(world_rect(Vector2(e.tx,e.ty))).get_center()
  else:
   for key in ["a","b"]:
    var point = (effect[key]-old_origin)/old_step
    effect[key] = BOARD_ORIGIN+point*CELL_STEP
 # A resize invalidates a pending button press, not an active drag.
 if drag_uid < 0: pressed_hit = {}
 queue_redraw()


func _shop_card(index: int,s: Dictionary,combat: bool):
 var rect = shop_rect(index)
 var id = int(s.shop[index])
 var colors = [Color("eceddf"),Color("dcebc4"),Color("d9e9f5"),Color("eddef4"),Color("fff0b8")]
 if id == 0:
  _panel(rect,colors[0])
  _label("REKRUTIERT",rect.grow(-5),14,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
  return
 var mon = catalog.get_mon(id)
 _panel(rect,colors[int(mon.cost)-1])
 draw_rect(Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,4)),[Color("7b8276"),Color("509448"),Color("4888c0"),Color("9860b0"),Color("c28c20")][int(mon.cost)-1])
 if mon.cost == 5:
  draw_rect(rect.grow(-2),Color(GOLD,0.7+0.3*sin(clock_time*3)),false,2)
 _label(mon.name,Rect2(rect.position+Vector2(5,8),Vector2(rect.size.x-10,21)),16,INK,HORIZONTAL_ALIGNMENT_CENTER)
 var sprite_box = Rect2(rect.position+Vector2(6,32),Vector2(rect.size.x*0.31,rect.size.y-40))
 draw_rect(sprite_box,Color("a0c878"))
 draw_line(sprite_box.end,Vector2(sprite_box.end.x,sprite_box.position.y),Color("709858"),2)
 _sprite(id,sprite_box)
 var price_box = Rect2(rect.position+Vector2(rect.size.x*0.36,32),Vector2(rect.size.x*0.60,20))
 _price(id,price_box)
 var discounted = game.purchase_cost(id) < int(mon.cost)
 _label(mon.role,Rect2(price_box.position+Vector2(0,24),Vector2(price_box.size.x,16)),12,INK)
 if discounted:
  var badge = Rect2(rect.position+Vector2(rect.size.x*0.36,rect.size.y-23),Vector2(rect.size.x*0.60,16))
  draw_rect(badge,GREEN)
  _label("−%d Gold" % (int(mon.cost)-game.purchase_cost(id)),badge,12,PAPER,HORIZONTAL_ALIGNMENT_CENTER)
 elif rect.size.y > 105:
  _label(" / ".join(mon.types),Rect2(rect.position+Vector2(rect.size.x*0.36,rect.size.y-23),Vector2(rect.size.x*0.60,16)),12,_type_color(mon),HORIZONTAL_ALIGNMENT_CENTER)
 if not combat and s.phase == "planning":
  var reason = "Treuerabatt: Der erste Kauf kostet 1 Gold weniger (mindestens 1 Gold)." if discounted else "Regulärer Preis."
  _hit(rect,_send.bind({"type":"buy","index":index}),"%s · %d Gold\n%s\n%s" % [mon.name,game.purchase_cost(id),reason,mon.description]+"\n"+catalog.evolution_text({"species":id,"star":1}))


func _price(id: int,rect: Rect2):
 var original = int(catalog.get_mon(id).cost)
 var actual = game.purchase_cost(id)
 if actual < original:
  var old = Rect2(rect.position,Vector2(26,rect.size.y))
  _label(str(original),old,15,MUTED)
  draw_line(old.position+Vector2(0,old.size.y/2),old.position+Vector2(18,old.size.y/2),RED,2)
  _label("%d G" % actual,Rect2(rect.position+Vector2(28,0),Vector2(rect.size.x-28,rect.size.y)),18,GREEN)
 else:
  _label(("%d G · fehlt" if game.state.gold < actual else "%d Gold") % actual,rect,18,RED if game.state.gold < actual else INK)


func _actions(combat: bool,s: Dictionary):
 var r = layout.actions
 _panel(r,PAPER)
 var gap = 6
 var width = (r.size.x-20)/3
 layout.fight = Rect2(r.position+Vector2(6,6),Vector2(r.size.x-12,32))
 _button(layout.fight,"Weiter" if combat and paused else ("Pause" if combat else ("Neue Partie" if s.phase == "finished" else "Kampf starten [Leertaste]")),func():
  if combat: paused = not paused
  elif s.phase == "finished": reset_open = true
  else: _send({"type":"battle"}),GREEN)
 layout.reroll = Rect2(r.position+Vector2(6,43),Vector2(width,29))
 layout.xp = Rect2(r.position+Vector2(8+width,43),Vector2(width,29))
 layout.lock = Rect2(r.position+Vector2(10+width*2,43),Vector2(width,29))
 if combat:
  _button(layout.reroll,"Tempo ×%d" % int(speed),func(): speed = 1 if speed == 4 else speed*2)
  _button(layout.xp,"Ergebnis",_finish_playback)
  _label("%.1f s" % (playback.frames[frame_index].tick/10.0),layout.lock,16,INK,HORIZONTAL_ALIGNMENT_CENTER)
 else:
  _button(layout.reroll,"Shop %d G" % game.reroll_cost(),_send.bind({"type":"reroll"}),PAPER,s.phase == "planning" and s.gold >= game.reroll_cost())
  _button(layout.xp,"EP · 4 G",_send.bind({"type":"xp"}),PAPER,s.phase == "planning" and s.gold >= 4 and s.level < 10)
  _button(layout.lock,"Gesperrt" if s.locked else "Sperren",_send.bind({"type":"lock"}),GOLD if s.locked else PAPER,s.phase == "planning")


func _information(combat: bool,s: Dictionary):
 var r = layout.info
 _panel(r,PAPER)
 var unit = _detail_unit()
 if unit.is_empty():
  _label("TRAINER-PANEL",Rect2(r.position+Vector2(10,8),Vector2(r.size.x-20,30)),22,INK)
  _wrap("Ziehe Pokémon auf dein Feld. Ein Klick zeigt Details und Reichweite. Gegner: "+s.difficulty+".",Rect2(r.position+Vector2(12,49),Vector2(r.size.x-24,90)),16,INK)
  _wrap("Zinsen: +%d Gold. %s" % [game.interest(),"Maximum erreicht." if game.interest() == 5 else "Nächste Schwelle: %d Gold." % ((int(s.gold/10)+1)*10)],Rect2(r.position+Vector2(12,145),Vector2(r.size.x-24,50)),14,MUTED)
  if compact and not combat and not game.last_battle.is_empty():
   layout.replay = Rect2(r.position+Vector2(12,r.size.y-33),Vector2(r.size.x-24,25))
   _button(layout.replay,"Kampf erneut ansehen",_replay)
  return
 var m = catalog.get_mon(unit.species)
 var stats = catalog.stats(unit)
 var x = r.position.x+10
 var y = r.position.y+7
 var width = r.size.x-20
 _label(catalog.display_name(unit),Rect2(x,y,width-48,26),22,INK)
 _sprite(catalog.sprite_id(unit),Rect2(x+width-45,y,42,42))
 _label(m.role+" · "+" / ".join(catalog.combat_types(unit)),Rect2(x,y+29,width-46,19),13,_type_color(m))
 _label("LP %d/%d · ATK %d · DEF %d" % [unit.get("hp",stats.hp),unit.get("max_hp",stats.hp),unit.get("attack",stats.attack),unit.get("armor",stats.armor)],Rect2(x,y+51,width,18),13,INK)
 _label("Mana %d/%d · Reichweite %d Tiles" % [unit.get("mana",0),unit.get("cast_threshold",m.mana),_effective_reach(unit)],Rect2(x,y+71,width,18),14,BLUE)
 _bar(Rect2(x,y+91,width,4),float(unit.get("mana",0))/m.mana,BLUE)
 _label(m.ability+" · %d Mana" % int(m.mana),Rect2(x,y+99,width,20),16,INK)
 var text_height = 66 if compact else 78
 _wrap(m.description,Rect2(x,y+123,width,text_height),14 if compact else 17,INK)
 _hit(Rect2(x,y+99,width,20+text_height),func(): message = m.ability_range,m.ability_range+"\n"+Catalog.ROLES[m.role].text)
 if not compact:
  _wrap(Catalog.ROLES[m.role].text,Rect2(x,y+207,width,55),14,MUTED)
  _label("Angriff: %s · Fähigkeit: %s" % [m.attack_type,m.ability_type],Rect2(x,y+268,width,20),13,MUTED)
 layout.sell = Rect2(x,r.end.y-34,width,26)
 if combat:
  var states = ", ".join(unit.get("status",{}).keys())
  if unit.get("growth",0)>=20: states += " Erblüht"
  if unit.get("unstoppable_until",0)>playback.frames[frame_index].tick: states += " Unaufhaltsam"
  if unit.get("blessed",false): states += " Segen"
  _label("Schild %d · %s" % [unit.get("shield",0),states],layout.sell,12,MUTED)
  _hit(layout.sell,func(): message = states,"Zustände: "+states+"\nW = Wachstum, H = Hitze, K = Kampfgeist, G = Toxin, F = Frost, S = Segen, BL = Erblüht, U = Unaufhaltsam.\nUnlicht-Ziel: "+unit.get("dark_priority","–"))
 elif selected >= 0:
  _button(layout.sell,"Verkaufen · %d Gold" % (int(m.cost)*int(pow(3,unit.star-1))),_send.bind({"type":"sell","uid":selected}),RED,s.phase == "planning")


func _economy_result(s: Dictionary,combat: bool):
 var r = layout.economy
 _panel(r,PAPER)
 _label("EINKOMMEN",Rect2(r.position+Vector2(9,5),Vector2(r.size.x-18,24)),18,INK)
 _label("%d G · +%d Zins · %s" % [s.gold,mini(5,int(s.gold/10)),"MAX" if s.gold >= 50 else "ab %d G" % ((int(s.gold/10)+1)*10)],Rect2(r.position+Vector2(10,33),Vector2(r.size.x-20,23)),14,INK)
 if not s.income.is_empty():
  var b = s.income
  _wrap("%d Basis + %d Fortschritt + %d Zins + %d Ergebnis + %d Augment = %d Gold" % [b.base,b.progress,b.interest,b.result,b.augments,b.total],Rect2(r.position+Vector2(10,64),Vector2(r.size.x-20,41)),13,MUTED)
 r = layout.result
 _panel(r,PAPER)
 _label("KAMPFPROTOKOLL" if combat else "EXPEDITION",Rect2(r.position+Vector2(10,7),Vector2(r.size.x-20,26)),18,INK)
 _wrap("\n".join(combat_log) if combat else s.last_result,Rect2(r.position+Vector2(10,39),Vector2(r.size.x-20,maxf(30,r.size.y-81))),15,INK)
 if not combat and not game.last_battle.is_empty():
  layout.replay = Rect2(r.position+Vector2(10,r.size.y-36),Vector2(r.size.x-20,28))
  _button(layout.replay,"Letzten Kampf ansehen",_replay)
 if result_time > 0: draw_rect(r.grow(-2),GREEN if s.outcome == "win" else RED,false,3)


func _sprite_area(rect: Rect2) -> Rect2:
 var compact_meta = rect.size.y < 78
 var bottom = rect.end.y-(26 if compact_meta else 45)
 var height = clampf(rect.size.y-(29 if compact_meta else 48),24,76)
 return Rect2(Vector2(rect.position.x+5,bottom-height),Vector2(rect.size.x-10,height))


func _unit_metadata(rect: Rect2,unit: Dictionary,enemy: bool,combat: bool,alpha: float = 1.0,world: bool = false):
 if world and rect.size.y < 78:
  _compact_world_metadata(rect,unit,enemy,combat,alpha)
  return
 var name_rect = Rect2(rect.position+Vector2(3,rect.size.y-28),Vector2(rect.size.x-6,15))
 var meta = Rect2(rect.position+Vector2(3,rect.size.y-29),Vector2(rect.size.x-6,29))
 metadata_regions.append(meta)
 draw_rect(meta,Color("dce6dc") if enemy else Color("eff5df"))
 _label(catalog.display_name(unit),name_rect,13,Color(INK,alpha),HORIZONTAL_ALIGNMENT_CENTER)
 var badge = Rect2(rect.position+Vector2(4,rect.size.y-13),Vector2(42,11))
 draw_rect(badge,Color("47355f") if unit.star == 3 else Color("233947"))
 for i in range(int(unit.star)): _pixel_star(badge.position+Vector2(7+i*13,5),Color(GOLD,alpha))
 if combat:
  _bar(Rect2(rect.position+Vector2(4,rect.size.y-39),Vector2(rect.size.x-8,6)),float(unit.hp)/unit.max_hp,Color("e87868") if enemy else Color("70bc58"))
  _bar(Rect2(rect.position+Vector2(4,rect.size.y-32),Vector2(rect.size.x-8,3)),float(unit.mana)/unit.get("cast_threshold",unit.max_mana),BLUE)
  if unit.shield > 0: _bar(Rect2(rect.position+Vector2(4,rect.size.y-43),Vector2(rect.size.x-8,3)),float(unit.shield)/unit.max_hp,Color("e8d689"))
  _label("%d/%d" % [unit.mana,unit.get("cast_threshold",unit.max_mana)],Rect2(rect.position+Vector2(49,rect.size.y-14),Vector2(rect.size.x-53,13)),11,INK,HORIZONTAL_ALIGNMENT_RIGHT)
  if not unit.status.is_empty():
   var marks = {"poison":"G","burn":"F","stun":"Z","slow":"L","break":"B","taunt":"!","haste":"+"}
   var n = 0
   for key in unit.status:
    var at_pos = rect.position+Vector2(3+n*12,3)
    draw_rect(Rect2(at_pos,Vector2(11,13)),PAPER)
    _label(marks.get(key,"!"),Rect2(at_pos,Vector2(11,13)),11,RED)
    metadata_regions.append(Rect2(at_pos,Vector2(11,13)))
    n += 1
    if n == 3: break


func _compact_world_metadata(rect: Rect2,unit: Dictionary,enemy: bool,combat: bool,alpha: float):
 var name_rect = Rect2(rect.position.x+3,rect.end.y-15,rect.size.x-6,15)
 metadata_regions.append(name_rect)
 draw_rect(name_rect,Color("dce6dc") if enemy else Color("eff5df"))
 _label(catalog.display_name(unit),name_rect,13,Color(INK,alpha),HORIZONTAL_ALIGNMENT_CENTER)
 # Side badge uses free space beside the sprite instead of covering the next row.
 var badge = Rect2(rect.end.x-15,rect.end.y-59,12,33)
 metadata_regions.append(badge)
 for i in range(int(unit.star)): _pixel_star(badge.position+Vector2(6,6+i*10),Color(GOLD,alpha))
 if combat:
  _bar(Rect2(rect.position.x+4,rect.end.y-24,rect.size.x-8,5),float(unit.hp)/unit.max_hp,Color("e87868") if enemy else Color("70bc58"))
  _bar(Rect2(rect.position.x+4,rect.end.y-18,rect.size.x-8,3),float(unit.mana)/unit.get("cast_threshold",unit.max_mana),BLUE)
  if unit.shield>0: _bar(Rect2(rect.position.x+4,rect.end.y-26,rect.size.x-8,2),float(unit.shield)/unit.max_hp,Color("e8d689"))

func _pixel_star(pos: Vector2,color: Color):
 var points = PackedVector2Array([Vector2(0,-5),Vector2(2,-2),Vector2(5,-2),Vector2(3,1),Vector2(4,5),Vector2(0,3),Vector2(-4,5),Vector2(-3,1),Vector2(-5,-2),Vector2(-2,-2)])
 for i in range(points.size()): points[i] += pos.round()
 draw_colored_polygon(points,color)
 points.append(points[0])
 draw_polyline(points,Color("10222b"),1,false)


func _impact(r: Rect2,kind: String,color: Color,t: float):
 var center = r.get_center().round()
 var radius = minf(r.size.y/2-2,r.size.x/2-3)
 if radius < 2: return
 if kind in ["cast","evolve","buy"]:
  var pulse = radius*(0.35+0.65*sin(t*PI))
  draw_rect(Rect2(center-Vector2(pulse,pulse),Vector2.ONE*pulse*2),Color(color,0.12),true)
  draw_rect(Rect2(center-Vector2(pulse,pulse),Vector2.ONE*pulse*2),color,false,2)
  for i in range(6):
   var point = center+Vector2(cos(i*TAU/6+t),sin(i*TAU/6+t))*maxf(0,pulse-3)
   draw_rect(Rect2(point.round()-Vector2(2,2),Vector2(4,4)),color)
 elif kind in ["hit","heal","status"]: _cross(center,int(radius*(1-t)*0.7)+1,color)
 elif kind == "mana": draw_rect(Rect2(center+Vector2(-2,radius*(0.5-t)),Vector2(4,4)),BLUE)
 elif kind == "shield": draw_rect(r.grow(-2),color,false,2)
 elif kind == "defeat":
  for i in range(4): draw_rect(Rect2(center+Vector2((i%2*2-1),(int(i/2)*2-1))*radius*t-Vector2(1,1),Vector2(2,2)),color)

