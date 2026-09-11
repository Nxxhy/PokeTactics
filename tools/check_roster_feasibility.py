import csv,json,random,math
from pathlib import Path
S=json.loads(Path('data/species_gen1_3.json').read_text(encoding='utf-8-sig'))
R=json.loads(Path('data/roster.json').read_text(encoding='utf-8-sig'))
rows=list(csv.DictReader(open('data/source/pokemon_species.csv',encoding='utf-8-sig')))
chain={int(r['id']):int(r['evolution_chain_id']) for r in rows}
by={s['id']:s for s in S}; types=sorted({t for s in S for t in s['types']})
parents={s['parent'] for s in S}; candidates=[s for s in S if s['id'] not in parents]
candidates.append({'id':425,'name':'Driftlon','types':['Geist','Flug'],'generation':4})
original={chain[r['id']] for r in R}
rng=random.Random(917)
best=None
for attempt in range(12):
 selected=[]; used=set()
 for r in R:
  s=by[r['forms'][-1]]
  if chain[s['id']] not in used: selected.append(s); used.add(chain[s['id']])
 def counts(team): return {t:sum(t in s['types'] for s in team) for t in types}
 def loss(team): return sum(max(0,7-v)**2 for v in counts(team).values())
 score=loss(selected)
 for step in range(7000):
  if score==0: break
  new=rng.choice(candidates); i=rng.randrange(70)
  if chain[new['id']] in used and chain[new['id']]!=chain[selected[i]['id']]: continue
  old=selected[i]; selected[i]=new; newscore=loss(selected)
  if newscore<=score or rng.random()<math.exp((score-newscore)/max(0.1,2*(1-step/7000))):
   used.discard(chain[old['id']]);used.add(chain[new['id']]);score=newscore
  else: selected[i]=old
 if score==0:
  best=selected;break
result={'generation_1_3_max':{t:len({chain[s['id']] for s in S if t in s['types']}) for t in types},'current_available_line_counts':{t:sum(any(t in by[f]['types'] for f in r['forms']) for r in R) for t in types},'feasible_70_line_example':best,'simultaneous_final_form_counts':counts(best) if best else None}
Path('docs/roster-feasibility.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('Feasible 70-line example found:',best is not None)
if best: print(counts(best));print('Later generation:',[s['name'] for s in best if s['generation']>3])
