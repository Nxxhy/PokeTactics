from pathlib import Path
import json
p=Path('core/match.gd');s=p.read_text(encoding='utf-8').replace('10:[5,10,25,35,25]','10:[5,10,25,40,20]').replace('[0,2,4,6,10,16,22,28,36,44,0]','[0,2,3,4,8,14,22,32,48,64,0]').replace('"base":7','"base":6');s=s.replace('var index = rng.randi_range(0,eligible.size()-1)','var weights = eligible.map(func(a): return 1.0+minf(4.0,float(catalog.synergies(board()).get(a.get("emblem",""),0))))\n    var total = weights.reduce(func(a,b): return a+b,0.0)\n    var roll = rng.randf()*total\n    var index = 0\n    while index < weights.size()-1 and roll >= weights[index]:\n     roll -= weights[index]\n     index += 1');p.write_text(s,encoding='utf-8')
p=Path('core/augments.gd');s=p.read_text(encoding='utf-8').replace('if int(result.get(type,0)) > 0:\n   result[type] += 1','if not type.is_empty():\n   result[type] = int(result.get(type,0))+1').replace('return cat.synergies(team).get(aug.emblem,0) > 0','return true');p.write_text(s,encoding='utf-8')
p=Path('data/augments.json');a=json.loads(p.read_text(encoding='utf-8-sig'));types=['Normal','Feuer','Wasser','Pflanze','Elektro','Eis','Kampf','Gift','Boden','Flug','Psycho','Käfer','Gestein','Geist','Drache','Unlicht','Stahl','Fee']
for i,t in enumerate(types):
 entry=next((x for x in a if x.get('emblem')==t),None)
 if entry is None:
  entry={'id':'type_emblem_'+str(i),'name':t+'-Emblem','emblem':t};a.append(entry)
 entry['description']='Dein Team zählt für '+t+' als hätte es ein zusätzliches Pokémon dieses Typs. Erzeugt keine Einheit.'
p.write_text(json.dumps(a,ensure_ascii=False,indent=2),encoding='utf-8')
p=Path('core/catalog.gd');s=p.read_text(encoding='utf-8');s=s.replace('const VERSION = 3','const VERSION = 4\n# Additional three-star HP / attack / ability multipliers, indexed by original cost.\nconst STAR3 = [[1.08,1.06,1.10],[1.14,1.12,1.18],[1.25,1.22,1.35],[1.50,1.45,1.70],[2.50,2.20,3.00]]');s=s.replace('return {"hp":int(mon.hp * multiplier), "attack":int(mon.attack * multiplier), "armor":int(mon.armor), "power":int(mon.power * multiplier)}','var extra = STAR3[int(mon.cost)-1] if int(unit.star) == 3 else [1.0,1.0,1.0]\n return {"hp":int(mon.hp * multiplier*extra[0]), "attack":int(mon.attack * multiplier*extra[1]), "armor":int(mon.armor), "power":int(mon.power * multiplier*extra[2])}');p.write_text(s,encoding='utf-8')
