"""Reproducible roster/data build from the locally archived PokeAPI CSVs."""
import csv,json,pathlib,hashlib,urllib.request,concurrent.futures
P=pathlib.Path(__file__).resolve().parents[1]
def rows(name): return list(csv.DictReader((P/'data/source'/f'{name}.csv').open(encoding='utf-8')))
def save(name,obj): (P/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
names={int(r['pokemon_species_id']):r['name'] for r in rows('pokemon_species_names') if r['local_language_id']=='6'}
types={int(r['type_id']):r['name'] for r in rows('type_names') if r['local_language_id']=='6' and int(r['type_id'])<=18}
pt={}
for r in rows('pokemon_types'):
 if int(r['type_id']) in types: pt.setdefault(int(r['pokemon_id']),[]).append(types[int(r['type_id'])])
species=[dict(id=int(r['id']),name=names[int(r['id'])],generation=int(r['generation_id']),parent=int(r['evolves_from_species_id'] or 0),types=pt[int(r['id'])],legendary=r['is_legendary']=='1',mythical=r['is_mythical']=='1') for r in rows('pokemon_species') if int(r['id'])<=386]
save('data/species_gen1_3.json',species)
save('data/form_names.json',{str(k):v for k,v in names.items() if k<=386})
chart={a:{b:1.0 for b in types.values()} for a in types.values()}
for r in rows('type_efficacy'):
 a,b=int(r['damage_type_id']),int(r['target_type_id'])
 if a in types and b in types: chart[types[a]][types[b]]=int(r['damage_factor'])/100
save('data/type_chart.json',chart)
tiers=[[1,4,7,172,37,43,54,74,152,155,158,161,179,252,255,258],[63,66,81,92,95,120,167,170,187,194,204,218,270,273,280,285],[143,113,123,193,198,200,207,209,213,227,296,299,304,309,315,355],[131,58,115,147,214,246,302,303,328,333,359,371],[144,145,146,150,151,243,244,245,249,384]]
lines=[[1,2,3],[4,5,6],[7,8,9],[172,25,26],[37,38],[43,44,45],[54,55],[74,75,76],[152,153,154],[155,156,157],[158,159,160],[161,162],[179,180,181],[252,253,254],[255,256,257],[258,259,260],[63,64,65],[66,67,68],[81,82],[92,93,94],[95,208],[120,121],[167,168],[170,171],[187,188,189],[194,195],[204,205],[218,219],[270,271,272],[273,274,275],[280,281,282],[285,286],[143],[113,242],[123,212],[193],[198],[200],[207],[209,210],[213],[227],[296,297],[299],[304,305,306],[309,310],[315],[355,356],[131],[58,59],[115],[147,148,149],[214],[246,247,248],[302],[303],[328,329,330],[333,334],[359],[371,372,373]]+[[n] for n in tiers[4]]
forms={l[0]:l for l in lines}
old=json.loads((P/'data/roster.json').read_text(encoding='utf-8'))
remap={25:172,59:58,149:147,242:113}
old={remap.get(m['id'],m['id']):m for m in old}
def e(kind,target='enemy',scale=1,**kw): return dict(kind=kind,target=target,scale=scale,**kw)
# Role, reach, ability, effect recipe. Every recipe resolves real battle effects.
recipes={
152:('Unterstützer',2,'Aromakur',[e('heal','all_allies',.45),e('cleanse','all_allies')]),
155:('Magier',2,'Flammenrad',[e('damage','area',1.2),e('burn','area',.12,duration=40)]),
158:('Angreifer',1,'Aquaknarre',[e('damage',scale=1.6),e('haste','self',duration=40)]),
161:('Angreifer',1,'Superzahn',[e('damage',scale=1.8),e('break',duration=40)]),
179:('Magier',3,'Donnerwelle',[e('damage','chain',.8,count=3),e('stun',duration=15)]),
252:('Angreifer',2,'Laubklinge',[e('damage',scale=2),e('heal','self',.35)]),
255:('Angreifer',1,'Doppelkick',[e('damage',scale=1),e('damage',scale=1),e('haste','self',duration=30)]),
258:('Tank',1,'Lehmschuss',[e('damage',scale=1.3),e('slow',duration=50),e('shield','self',.5)]),
167:('Magier',2,'Giftfaden',[e('poison',scale=.25,duration=60),e('slow',duration=50),e('damage',scale=.6)]),
170:('Unterstützer',3,'Lichtreserve',[e('heal','weak_ally',1.8),e('mana','other_allies',amount=12)]),
187:('Unterstützer',3,'Schlafpuder',[e('stun','area',duration=20),e('heal','weak_ally',1.1)]),
194:('Tank',1,'Lehmbad',[e('shield','self',1.3),e('slow','near_enemies',duration=40)]),
204:('Tank',1,'Stachler',[e('damage','near_enemies',1.3),e('break','near_enemies',duration=50)]),
218:('Tank',1,'Lavapanzer',[e('shield','self',1.5),e('burn','near_enemies',.2,duration=50)]),
270:('Unterstützer',2,'Regentanz',[e('heal','all_allies',.55),e('haste','all_allies',duration=30)]),
273:('Angreifer',3,'Kugelsaat',[e('damage','chain',1.2,count=3)]),
280:('Magier',3,'Gedankenstoß',[e('damage','area',1.6),e('break','area',duration=40)]),
285:('Angreifer',1,'Pilzfaust',[e('damage',scale=1.6),e('stun',duration=25),e('heal','self',.5)]),
193:('Angreifer',3,'Ultraschall',[e('damage','chain',1,count=3),e('slow','chain',duration=40,count=3)]),
198:('Angreifer',3,'Nachtflügel',[e('damage','weak_enemy',2.2),e('haste','self',duration=40)]),
200:('Magier',3,'Spukgesang',[e('damage','all_enemies',.8),e('break','all_enemies',duration=30)]),
207:('Tank',1,'Sandfalle',[e('damage','area',1.4),e('taunt','near_enemies',duration=40)]),
209:('Angreifer',1,'Knuddler',[e('damage',scale=2.3),e('slow',duration=50)]),
213:('Tank',1,'Krafttrick',[e('shield','self',2.2),e('poison','near_enemies',.2,duration=60)]),
227:('Tank',1,'Stahlflügel',[e('damage','near_enemies',1.6),e('shield','self',1.3)]),
296:('Tank',1,'Wirbelwurf',[e('damage',scale=2),e('stun',duration=30),e('taunt','near_enemies',duration=30)]),
299:('Tank',1,'Blockade',[e('shield','all_allies',.7),e('taunt','near_enemies',duration=50)]),
304:('Tank',1,'Eisenschädel',[e('damage',scale=2.1),e('stun',duration=25)]),
309:('Angreifer',3,'Funkensprung',[e('damage','chain',1.25,count=4),e('haste','self',duration=30)]),
315:('Unterstützer',3,'Blütenkur',[e('heal','all_allies',.7),e('poison','area',.2,duration=50)]),
355:('Magier',2,'Nachtnebel',[e('damage','area',1.4),e('slow','area',duration=60)]),
214:('Angreifer',1,'Vielender',[e('damage',scale=3),e('break',duration=50)]),
246:('Tank',1,'Sandsturm',[e('damage','all_enemies',1),e('shield','self',1.2)]),
302:('Unterstützer',2,'Trickschutz',[e('cleanse','all_allies'),e('shield','all_allies',.8),e('mana','weak_ally',amount=30)]),
303:('Tank',1,'Eisenkiefer',[e('damage',scale=2.5),e('heal','self',1)]),
328:('Angreifer',2,'Erdwelle',[e('damage','area',2),e('break','area',duration=60)]),
333:('Unterstützer',3,'Himmelslied',[e('heal','all_allies',.8),e('haste','all_allies',duration=50)]),
359:('Angreifer',1,'Unheilsklinge',[e('damage','weak_enemy',3.2)]),
371:('Angreifer',2,'Drachensturz',[e('damage','area',2.1),e('haste','self',duration=50)]),
144:('Magier',4,'Eisorkan',[e('damage','all_enemies',1.4),e('slow','all_enemies',duration=60)]),
146:('Magier',4,'Läuterfeuer',[e('damage','area',2),e('burn','all_enemies',.18,duration=60)]),
151:('Unterstützer',4,'Lebensfunke',[e('heal','all_allies',1),e('cleanse','all_allies'),e('mana','other_allies',amount=25)]),
243:('Angreifer',3,'Donnerjagd',[e('damage','chain',1.7,count=5),e('haste','self',duration=60)]),
244:('Tank',1,'Vulkanwacht',[e('damage','near_enemies',2),e('shield','self',2),e('taunt','near_enemies',duration=60)]),
245:('Unterstützer',3,'Polarlicht',[e('shield','all_allies',1),e('heal','all_allies',.7),e('slow','all_enemies',duration=30)]),
249:('Tank',3,'Luftwall',[e('damage','all_enemies',1),e('shield','all_allies',1),e('stun','area',duration=20)]),
384:('Angreifer',3,'Zenitsturm',[e('damage','all_enemies',1.5),e('damage',scale=2),e('haste','self',duration=40)])}
target_names={'enemy':'Hauptziel','area':'Gegner im Radius 1 um das Ziel','near_enemies':'Gegner im Radius 2','chain':'nächste Gegner am Ziel','self':'sich selbst','all_allies':'alle Verbündeten','other_allies':'andere Verbündete','all_enemies':'alle Gegner','weak_enemy':'schwächster Gegner','weak_ally':'schwächster Verbündeter'}
effect_names={'damage':'Schaden','heal':'Heilung','shield':'Schild','poison':'Gift','burn':'Brand','slow':'Langsam','stun':'Betäubung','break':'Rüstungsbruch','taunt':'Provokation','haste':'Tempo','cleanse':'Reinigung','mana':'Mana'}
roster=[]
for cost,ids in enumerate(tiers,1):
 for id in ids:
  if id in old: m=old[id]
  else:
   role,reach,ability,effects=recipes[id]
   m=dict(role=role,range=reach,ability=ability,effects=effects,hp=450+cost*140+(220 if role=='Tank' else 0),attack=35+cost*16+(15 if role=='Angreifer' else 0),armor=12+cost*5+(14 if role=='Tank' else 0),power=70+cost*45,mana=55+cost*10+(20 if role in ['Magier','Unterstützer'] else 0),interval=10 if role=='Angreifer' else 13)
   m['description']='; '.join(effect_names[e['kind']]+' → '+target_names[e['target']] for e in effects)+'.'
  m.update(id=id,name=names[id],cost=cost,forms=forms[id],types=pt[id],generation=next(s['generation'] for s in species if s['id']==id))
  m['attack_type']=pt[id][0]; m['ability_type']=pt[id][0]
  m['ability_type']={258:'Boden',255:'Kampf',167:'Gift',194:'Boden',204:'Boden',207:'Boden',285:'Kampf',304:'Stahl',303:'Stahl',371:'Drache'}.get(id,m['ability_type'])
  if id == 245: m['ability']='Auroraschutz'
  m['ability_range']='Auslösung: Angriffsreichweite; Unterstützer global. Flächen: Manhattan-Radius 1 am Ziel bzw. 2 am Anwender. Ketten und globale Effekte ohne Distanzlimit.'
  roster.append(m)
assert len(roster)==70 and len({m['id'] for m in roster})==70
save('data/roster.json',roster)
manifest=[]
for f in (P/'data/source').glob('*.csv'): manifest.append(dict(file=f.name,url='https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/'+f.name,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
save('data/source/manifest.json',manifest)
print('Roster:',len(roster),'source species:',len(species),'sprites:',len({f for m in roster for f in m['forms']}))
