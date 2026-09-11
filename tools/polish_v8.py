from pathlib import Path
p=Path('core/match.gd');s=p.read_text(encoding='utf-8');a=s.index('func purchase_cost(');s=s[:a]+'''func income_forecast() -> Dictionary:
 var base = 6+int((int(state.round)-1)/5)+interest()
 var extras = int(augments.value(state.augments,"saver")) if state.gold >= 50 else 0
 if catalog.synergies(board()).size() >= 4: extras += int(augments.value(state.augments,"dividend"))
 var cheap = {}
 for u in board():
  if catalog.get_mon(u.species).cost == 1: cheap[u.species] = true
 if cheap.size() >= 3: extras += int(augments.value(state.augments,"underdog"))
 return {"win":base+extras+2+mini(3,int((maxi(0,state.streak)+1)/3))+int(augments.value(state.augments,"win_gold")),"loss":base+extras+3+int(augments.value(state.augments,"loss_gold")),"interest":interest()}

'''+s[a:]
# Upgrade only well-formed v7 saves, refund removed lines; legacy recovery remains available.
a=s.index(' var legacy = int(data.get("schema",-1))')
s=s[:a]+''' if int(data.get("rules",0)) == 3 and int(data.get("schema",0)) == SCHEMA:
  if typeof(data.get("units")) != TYPE_ARRAY or typeof(data.get("shop")) != TYPE_ARRAY or not _integer(data.get("gold")): return false
  var previous = JSON.parse_string(FileAccess.get_file_as_string("res://data/roster-v7-backup.json"))
  var old_cost = {}
  for mon in previous: old_cost[int(mon.id)] = int(mon.cost)
  var retained = []
  for unit in data.units:
   if typeof(unit) != TYPE_DICTIONARY or not _integer(unit.get("species")) or not _integer(unit.get("star")) or int(unit.star) not in [1,2,3]: return false
   if catalog.by_id.has(int(unit.species)): retained.append(unit)
   elif old_cost.has(int(unit.species)): data.gold += old_cost[int(unit.species)]*int(pow(3,int(unit.star)-1))
   else: return false
  data.units = retained
  data.pool = {}
  for mon in catalog.roster: data.pool[str(int(mon.id))] = 18
  for unit in data.units: data.pool[str(int(unit.species))] -= int(pow(3,int(unit.star)-1))
  for i in range(data.shop.size()):
   if not _integer(data.shop[i]): return false
   if not catalog.by_id.has(int(data.shop[i])): data.shop[i] = 0
   if data.shop[i] != 0: data.pool[str(int(data.shop[i]))] -= 1
  if typeof(data.get("completed_lines")) != TYPE_ARRAY: return false
  data.completed_lines = data.completed_lines.filter(func(id): return catalog.by_id.has(int(id)))
  data.rules = Catalog.VERSION
'''+s[a:];p.write_text(s,encoding='utf-8')
p=Path('ui/main.gd');s=p.read_text(encoding='utf-8');s=s.replace('_label("Basis +%d · Zins +%d" % [6+int((int(s.round)-1)/5),mini(5,int(s.gold/10))]','_label("Runde +%d–%d · Z +%d" % [mini(game.income_forecast().win,game.income_forecast().loss),maxi(game.income_forecast().win,game.income_forecast().loss),game.income_forecast().interest]')
s=s.replace(' if game.state.gold < game.purchase_cost(id):\n  _label("ZU TEUER",Rect2(rect.position+Vector2(6,rect.size.y-23),Vector2(rect.size.x*0.31,16)),12,RED)\n','')
s=s.replace('_label("%d Gold" % actual,rect,18,','_label(("%d G · fehlt" if game.state.gold < actual else "%d Gold") % actual,rect,18,')
s=s.replace('[unit.mana,unit.max_mana]','[unit.mana,unit.get("cast_threshold",unit.max_mana)]').replace('float(unit.mana)/unit.max_mana','float(unit.mana)/unit.get("cast_threshold",unit.max_mana)')
s=s.replace('   DirAccess.copy_absolute(save_path,save_path+".pre-v3-backup")','   DirAccess.copy_absolute(save_path,save_path+".pre-v3-backup")\n  if typeof(data) == TYPE_DICTIONARY and int(data.get("rules",0)) == 3:\n   DirAccess.copy_absolute(save_path,save_path+".pre-v8-backup")')
s=s.replace('else "Dein Abenteuer wurde fortgesetzt."','else ("Version 8: Entfernte Linien zum vollen Verkaufswert erstattet." if int(data.get("rules",0)) == 3 else "Dein Abenteuer wurde fortgesetzt.")')
s=s.replace(' if combat: box.position +=',' if unit.star == 3 and catalog.get_mon(unit.species).cost == 5:\n  _ring(area.get_center(),int(minf(24,area.size.y/2)),Color(GOLD,0.8))\n  _pixel_star(area.get_center()+Vector2(0,-area.size.y/2),GOLD)\n if combat: box.position +=')
s=s.replace('    var a = _sprite_area(world_rect(Vector2(event.sx,event.sy))).get_center()\n    var b = r.get_center()','    var a = _sprite_area(world_rect(Vector2(event.sx,event.sy))).get_center()\n    if event.get("source_star",1) == 3 and catalog.get_mon(event.species).cost == 5:\n     _ring(a,26+int(t*20),GOLD)\n     _pixel_star(a+Vector2(0,-25),GOLD)\n    var b = r.get_center()')
p.write_text(s,encoding='utf-8')
p=Path('core/battle.gd');s=p.read_text(encoding='utf-8').replace('"star":target.star,"amount"','"star":target.star,"source_star":source.star,"amount"');s=s.replace(' traits.init(self,fighters,seed_value)',' traits.init(self,fighters,seed_value)\n for u in fighters: u.cast_threshold = traits.threshold(u)');p.write_text(s,encoding='utf-8')
p=Path('core/traits.gd');s=p.read_text(encoding='utf-8').replace('  u.water_buff = false','  u.cast_threshold = threshold(u)\n  u.water_buff = false');s=s.replace('return int(b.catalog.get_mon(u.species).range)+(1 if n(u,"Flug") >= 2 else 0)','return (int(b.catalog.get_mon(u.species).range)+(1 if n(u,"Flug") >= 2 else 0))*(2 if n(u,"Psycho") >= 8 else 1)');p.write_text(s,encoding='utf-8')
