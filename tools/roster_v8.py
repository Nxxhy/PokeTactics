import csv,json,copy
from pathlib import Path
P=Path('.')
def read(p):return json.loads((P/p).read_text(encoding='utf-8-sig'))
def save(p,o):(P/p).write_text(json.dumps(o,ensure_ascii=False,indent=2),encoding='utf-8')
old=read('data/roster.json');save('data/roster-v7-backup.json',old)
rows={int(r['id']):r for r in csv.DictReader(open('data/source/pokemon_species.csv',encoding='utf-8-sig'))}
names={int(r['pokemon_species_id']):r['name'] for r in csv.DictReader(open('data/source/pokemon_species_names.csv',encoding='utf-8-sig')) if r['local_language_id']=='6'}
typenames={int(r['type_id']):r['name'] for r in csv.DictReader(open('data/source/type_names.csv',encoding='utf-8-sig')) if r['local_language_id']=='6'}
types={}
for r in csv.DictReader(open('data/source/pokemon_types.csv',encoding='utf-8-sig')):
 if int(r['type_id'])<=18:types.setdefault(int(r['pokemon_id']),[]).append(typenames[int(r['type_id'])])
selected=read('docs/roster-solution.json')
bychain={rows[r['id']]['evolution_chain_id']:r for r in old}
selectedchains={r['evolution_chain_id'] for r in selected}
removed=[r for r in old if rows[r['id']]['evolution_chain_id'] not in selectedchains]
costs=iter(sorted(r['cost'] for r in removed));result=[];changes=[]
for row in selected:
 end=int(row['id']);path=[];node=end
 while node:
  if int(rows[node]['generation_id'])<=3 or node==478:path.append(node)
  node=int(rows[node]['evolves_from_species_id'] or 0)
 path=path[::-1][-3:]
 existing=bychain.get(row['evolution_chain_id'])
 if existing:
  mon=copy.deepcopy(existing)
  # Keep the original shop identity when it belongs to the chosen path.
  if mon['id'] in path:path=path[path.index(mon['id']):]
  mon['id']=path[0];mon['name']=names[path[0]];mon['forms']=path;mon['types']=types[path[0]]
 else:
  c=next(costs);kind=types[end][0];role='Tank' if kind in ['Stahl','Gestein','Boden'] else 'Unterstützer' if kind in ['Fee','Pflanze'] else 'Magier' if kind in ['Geist','Psycho','Elektro','Eis'] else 'Angreifer'
  effects=[{'kind':'damage','target':'enemy','scale':1.3}]
  if role=='Tank':effects.append({'kind':'shield','target':'self','scale':1.0})
  elif role=='Unterstützer':effects.append({'kind':'heal','target':'weak_ally','scale':1.1})
  else:effects.append({'kind':'slow' if kind in ['Eis','Wasser','Käfer'] else 'break','target':'enemy','duration':20+c*3})
  mon={'id':path[0],'name':names[path[0]],'types':types[path[0]],'cost':c,'range':1 if role=='Tank' else 2,'forms':path,'role':role,'mana':60+c*8,'ability':names[end]+'s '+('Schutzstoß' if role=='Tank' else 'Lebensfunke' if role=='Unterstützer' else 'Kraftstoß'),'effects':effects,'hp':520+c*150+(200 if role=='Tank' else 0),'attack':38+c*12,'armor':14+c*5,'power':90+c*42,'interval':13,'generation':int(rows[path[0]]['generation_id']),'attack_type':kind,'ability_type':kind,'ability_range':'Auslösung in Angriffsreichweite. Unterstützer global.'}
  mon['description']='Trifft das Hauptziel mit 130 % Fähigkeitsstärke. '+('Erhält einen Schild mit 100 % Stärke.' if role=='Tank' else 'Heilt den schwächsten Verbündeten mit 110 % Stärke.' if role=='Unterstützer' else 'Schwächt das Ziel für %.1f Sekunden.' % ((20+c*3)/10))
  changes.append(mon['name'])
 result.append(mon)
result.sort(key=lambda m:(m['cost'],m['id']))
assert len(result)==70 and len({rows[r['id']]['evolution_chain_id'] for r in result})==70
counts={t:sum(any(t in types[f] for f in r['forms']) for r in result) for t in typenames.values() if t in set(t for r in result for f in r['forms'] for t in types[f])}
assert all(v>=7 for v in counts.values()),counts
save('data/roster.json',result)
species=read('data/species_gen1_3.json');species.append({'id':478,'name':names[478],'generation':4,'parent':361,'types':types[478],'legendary':False,'mythical':False});save('data/species_gen1_3.json',species)
formnames=read('data/form_names.json');formnames['478']=names[478];save('data/form_names.json',formnames)
save('docs/roster-v8-changes.json',{'removed':[r['name'] for r in removed],'added':changes,'counts':counts,'forms':len({f for r in result for f in r['forms']})})
print('Added:',changes);print('Removed:',[r['name'] for r in removed]);print(counts)
