from pathlib import Path
p=Path('ui/main.gd');s=p.read_text(encoding='utf-8')
s=s.replace('var compact = false','var compact = false\nvar trait_page = 0\nvar trait_open = ""')
s=s.replace('func _ready():\n','func _ready():\n if save_path == "user://match.json" and "--fresh-demo" not in OS.get_cmdline_user_args() and not OS.has_feature("web"):\n  get_window().mode = Window.MODE_FULLSCREEN\n')
s=s.replace('func _new_game():','func _new_game():\n if OS.has_feature("web"):\n  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)')
s=s.replace('if event.keycode == KEY_ESCAPE:','if event.keycode == KEY_ESCAPE:\n  if not trait_open.is_empty():\n   trait_open = ""\n   return')
s=s.replace('and not start_open and game.state.augment_offers.is_empty()','and not start_open and trait_open.is_empty() and game.state.augment_offers.is_empty()')
s=s.replace(' draw_usec = Time.get_ticks_usec()-draw_started',' if not trait_open.is_empty(): _trait_modal()\n draw_usec = Time.get_ticks_usec()-draw_started')
a=s.index(' var stat_width = (size.x-550)/4');z=s.index(' _button(layout.help',a)
s=s[:a]+''' var stat_width = (size.x-550)/4
 var titles = ["GOLD","RUNDE / LEBEN","LEVEL / ERFAHRUNG","AUFSTELLUNG"]
 var values = ["%d G" % int(s.gold),"%d/30 · %d/3 LP" % [mini(30,int(s.round)),int(s.lives)],"Lv.%d · %d/%d EP" % [int(s.level),int(s.xp),[0,2,3,4,8,14,22,32,48,64,0][int(s.level)]],"%d / %d" % [s.units.filter(func(u): return u.zone == "board").size(),int(s.level)]]
 for i in range(4):
  var x = 280+i*stat_width
  _label(titles[i],Rect2(x,5,stat_width-8,15),12,Color("b7d2c5"))
  _label(values[i],Rect2(x,20,stat_width-8,22),22 if i == 0 else 16,GOLD if i == 0 else PAPER)
  if i == 0:
   _label("Basis +%d · Zins +%d" % [6+int((int(s.round)-1)/5),mini(5,int(s.gold/10))],Rect2(x,42,stat_width-8,14),12,PAPER)
  elif i == 2: _label("4 Gold = %d EP" % (4+int(game.augments.value(s.augments,"xp_buy"))),Rect2(x,42,stat_width-8,14),12,PAPER)
'''+s[z:]
a=s.index(' _label("TEAM-SYNERGIEN');z=s.index(' r = layout.augments',a)
s=s[:a]+''' _label("TYPEN · 2/4/6/8",Rect2(r.position+Vector2(35,5),Vector2(r.size.x-116,24)),16,INK)
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
  _hit(box,func(): trait_open = type,type+": "+detail+"\\n"+catalog.trait_text(type))
'''+s[z:]
a=s.index('func _augment_modal():')
s=s[:a]+'''func _trait_modal():
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

'''+s[a:]
s=s.replace('var colors = [PAPER,PAPER,PAPER,PAPER,Color("f8f0c8")]','var colors = [Color("eceddf"),Color("dcebc4"),Color("d9e9f5"),Color("eddef4"),Color("fff0b8")]')
s=s.replace('draw_rect(Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,3)),_type_color(mon))','draw_rect(Rect2(rect.position+Vector2(3,3),Vector2(rect.size.x-6,4)),[Color("7b8276"),Color("509448"),Color("4888c0"),Color("9860b0"),Color("c28c20")][int(mon.cost)-1])')
s=s.replace(' var reason = "Treuerabatt:', ' var reason = "Treuerabatt:')
s=s.replace('  var reason = "Treuerabatt:', '  var reason = "Treuerabatt:')
s=s.replace(' if not combat and s.phase == "planning":\n  var reason',' if game.state.gold < game.purchase_cost(id):\n  _label("ZU TEUER",Rect2(rect.position+Vector2(6,rect.size.y-23),Vector2(rect.size.x*0.31,16)),12,RED)\n if not combat and s.phase == "planning":\n  var reason')
s=s.replace('Vector2(4,rect.size.y-34),Vector2(rect.size.x-8,3)','Vector2(4,rect.size.y-39),Vector2(rect.size.x-8,6)').replace('Vector2(4,rect.size.y-30),Vector2(rect.size.x-8,2)','Vector2(4,rect.size.y-32),Vector2(rect.size.x-8,3)')
s=s.replace('  _label("%d/%d" % [unit.mana,unit.max_mana]','  if unit.shield > 0: _bar(Rect2(rect.position+Vector2(4,rect.size.y-43),Vector2(rect.size.x-8,3)),float(unit.shield)/unit.max_hp,Color("e8d689"))\n  _label("%d/%d" % [unit.mana,unit.max_mana]')
s=s.replace('var duration = 0.42 if event.kind in ["attack","mana"] else 0.8','var duration = 0.2 if event.kind == "attack" else 0.35 if event.kind == "hit" and event.spell == "attack" else 0.8').replace('duration = 1.3','duration = 0.6').replace('minf(1,t*2.4)','minf(1,t*2)')
s=s.replace(' for i in range(8):\n  var spark = (b+', ' for i in range(8 if t >= 0.5 else 0):\n  var spark = (b+')
s=s.replace('func _ground_effects():\n','func _ground_effects():\n if not playback.is_empty():\n  for field in playback.frames[frame_index].get("fields",[]):\n   for tile in field.tiles:\n    var poly = tile_polygon(tile.x,tile.y)\n    draw_colored_polygon(poly,Color(0.15,0.55,0.95,0.26) if field.kind == "water" else Color(0.3,0.2,0.12,0.4))\n    if field.kind == "rift":\n     var c = project_grid(tile.x+0.5,tile.y+0.5)\n     draw_polyline(PackedVector2Array([c+Vector2(-12,-3),c+Vector2(2,1),c+Vector2(-3,4),c+Vector2(11,7)]),INK,2)\n')
s=s.replace(' if not grounded: _unit_metadata(content,unit,enemy,combat,alpha)',' if combat:\n  if unit.get("phantom_until",0) > playback.frames[frame_index].tick: _ring(area.get_center(),12,Color(BLUE,0.7))\n  var marks = []\n  if unit.get("growth",0)>0: marks.append("W%d" % unit.growth)\n  if unit.get("heat",0)>0: marks.append("H%d" % unit.heat)\n  if unit.get("spirit",0)>0: marks.append("K%d" % unit.spirit)\n  if unit.get("blessed",false): marks.append("Segen")\n  if unit.get("toxin",0)>0: marks.append("G%d" % unit.toxin)\n  if not marks.is_empty(): _label(" ".join(marks),Rect2(area.position+Vector2(0,-14),Vector2(area.size.x,14)),11,INK,HORIZONTAL_ALIGNMENT_CENTER)\n if not grounded: _unit_metadata(content,unit,enemy,combat,alpha)')
p.write_text(s,encoding='utf-8')
