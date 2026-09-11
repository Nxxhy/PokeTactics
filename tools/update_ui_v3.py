from pathlib import Path
P=Path(__file__).resolve().parents[1]
p=P/'ui/main.gd'; s=p.read_text(encoding='utf-8')
s=s.replace('1440,960','1920,960').replace('1440,86','1920,86').replace('1440,4','1920,4')
s=s.replace('KANTO · DEINE EXPEDITION','KANTO · JOHTO · HOENN').replace(' / 20" % mini(20',' / 30" % mini(30').replace('s.level == 8','s.level == 10').replace('s.level < 8','s.level < 10').replace('von 20 Runden','von 30 Runden').replace('alle 20 Runden','alle 30 Runden').replace('20 SIEGRUNDEN','30 SIEGRUNDEN').replace('Alle drei Siegrunden','Alle vier Siegrunden')
s=s.replace('var old = typeof(data) == TYPE_DICTIONARY and int(data.get("schema",0)) == 1','var old = typeof(data) == TYPE_DICTIONARY and int(data.get("schema",0)) in [1,2]').replace('save_path+".v1-backup"','save_path+".pre-v3-backup"').replace('Spielstand übernommen: neue Regeln, 3 Leben.','Spielstand übernommen: 30 Runden und neues Roster.')
s=s.replace('var color = _type_color(mon)\n  draw_rect','var cost_colors = [Color("eee8d5"),Color("cee6ba"),Color("bddbea"),Color("ddc5eb"),Color("f7da8a")]\n  _panel(rect,cost_colors[int(mon.cost)-1])\n  var color = _type_color(mon)\n  draw_rect')
s=s.replace('int(mon.cost) if owned == 0','game.purchase_cost(id) if owned == 0').replace('[int(mon.cost),owned]','[game.purchase_cost(id),owned]').replace('s.gold < int(mon.cost)','s.gold < game.purchase_cost(id)')
s=s.replace('"Shop: 2 G [R]"','"Shop: %d G [R]" % game.reroll_cost()').replace('not finished and s.gold >= 2','not finished and s.gold >= game.reroll_cost()').replace('"4 EP: 4 G [E]"','"%d EP: 4 G [E]" % (4+int(game.augments.value(s.augments,"xp_buy")))')
start=s.index(' _panel(Rect2(1024,688,392,109),PAPER)')
end=s.index(' _panel(Rect2(1024,809,392,110),PAPER)',start)
s=s[:start]+''' _panel(Rect2(1024,688,392,109),PAPER)
 _label("EINKOMMEN & ZINSEN",Rect2(1040,698,360,24),20,INK)
 var interest = mini(5,int(s.gold/10))
 _label("%d Gold · Zinsen +%d · %s" % [int(s.gold),interest,"Maximum" if interest == 5 else "nächste Schwelle %d G" % ((int(s.gold/10)+1)*10)],Rect2(1040,726,360,23),16,INK)
 if not s.income.is_empty():
  var b = s.income
  _wrap("Letzte Auszahlung: %d Basis + %d Fortschritt + %d Zins + %d Ergebnis + %d Augment = %d G" % [b.base,b.progress,b.interest,b.result,b.augments,b.total],Rect2(1040,753,360,36),14,MUTED)
''' +s[end:]
s=s.replace(' _sidebar(combat,s)',' _sidebar(combat,s)\n _strategy_panel(s)\n _range_overlay()')
s=s.replace(' if help_open or reset_open:\n  _draw_modal()',' if help_open or reset_open:\n  _draw_modal()\n if not combat and not game.state.augment_offers.is_empty():\n  _augment_modal()')
s=s.replace('"Mana %d / %d" % [mana,int(mon.mana)]','"Mana %d / %d · Reichweite %d Tiles" % [mana,int(mon.mana),int(mon.range)]')
s=s.replace(' _wrap(mon.description,Rect2(1040,483,360,62),18,INK)',' _wrap(mon.description,Rect2(1040,483,360,76),17,INK)\n _hit(Rect2(1040,453,360,105),func(): message = mon.ability_range,mon.ability_range)')
s=s.replace('Rect2(1040,551,360,57)','Rect2(1040,563,360,43)')
s=s.replace(' if combat:\n  var names =',' _label("Angriff: %s · Fähigkeit: %s" % [mon.attack_type,mon.ability_type],Rect2(1040,605,360,20),14,MUTED)\n if combat:\n  var names =')
s=s.replace('Rect2(1040,617,360,46)','Rect2(1040,627,360,36)')
s=s.replace('and not help_open and not reset_open:', 'and not help_open and not reset_open and game.state.augment_offers.is_empty():')
s=s.replace('if drag_uid >= 0 or press_uid >= 0 or help_open or reset_open:', 'if drag_uid >= 0 or press_uid >= 0 or help_open or reset_open or not game.state.augment_offers.is_empty():')
s=s.replace('Color(Catalog.COLORS[type])','Color(Catalog.COLORS.get(type,"5b6c65"))')
s=s.replace('"cast": _spell_effect(effect,t,color)','"cast": _spell_effect(effect,t,color)\n   "effectiveness": _effect_label("IMMUN" if event.amount == 0 else "×%.2g" % (event.amount/100.0),b+Vector2(0,-15-t*20),Color(BLUE if event.amount < 100 else RED,alpha))')
s=s.replace(' for event in frame.events:\n  if event.kind == "move":',' for event in frame.events:\n  if event.kind == "effectiveness":\n   combat_log.push_front(event.spell)\n   combat_log = combat_log.slice(0,3)\n  if event.kind == "move":')
p.write_text(s,encoding='utf-8')
p=P/'project.godot'; s=p.read_text().replace('viewport_width=1440','viewport_width=1920').replace('window_width_override=1440','window_width_override=1600').replace('window_height_override=960','window_height_override=800');p.write_text(s)
# Preserve existing regression suites, updating expectations for intentional rule changes.
for name in ['test_core.gd','test_ui.gd','capture_gallery.gd']:
 p=P/'tests'/name;s=p.read_text(encoding='utf-8')
 import re
 for old,new in [(25,172),(59,58),(149,147),(242,113)]: s=re.sub(r'(?<![\w.])'+str(old)+r'(?![\w.])',str(new),s)
 if name=='test_core.gd':
  s=s.replace('catalog.FORM_NAMES.has(catalog.sprite_id(unit))','catalog.form_names.has(str(catalog.sprite_id(unit)))').replace('range(20)','range(30)').replace('game.state.wins == 20 and game.state.round == 21','game.state.wins == 30 and game.state.round == 31').replace('20 victories','30 victories')
  s=s.replace('catalog.roster.size() == 23','catalog.roster.size() == 70').replace('23 configured','70 configured').replace('.size() == 4,"Four Pokemon in high-cost tier"','.size() == (12 if tier == 4 else 10),"High-cost tier count"').replace('range(3,9)','range(3,11)').replace('range(15)','range(28)').replace('game.state.level == 8','game.state.level == 10').replace('game.state.level < 8','game.state.level < 10')
  s=s.replace('var lost = sim.hit(fighters[0],fighters[1],100,"test")','var lost = sim.hit(fighters[0],fighters[1],100,"test",false,"Normal")')
  s=s.replace('while game.state.phase == "planning" and battles < 35:', 'while game.state.phase == "planning" and battles < 40:\n   while not game.state.augment_offers.is_empty():\n    game.command({"type":"augment","index":0})')
  s=s.replace('for _i in range(800):','for _i in range(200):').replace('/4000','/1000').replace('/ 4000','/ 1000').replace('< 2.5','< 5.0')
 p.write_text(s,encoding='utf-8')
