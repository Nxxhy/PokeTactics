import sys,csv,json
from pathlib import Path
sys.path.insert(0,str(Path('.validation-python').resolve()))
import numpy as np
from scipy.optimize import milp,Bounds,LinearConstraint
rows=list(csv.DictReader(open('data/source/pokemon_species.csv',encoding='utf-8-sig')))
rows=[r for r in rows if int(r['generation_id'])<=4]
chain={int(r['id']):int(r['evolution_chain_id']) for r in rows}
parents={int(r['evolves_from_species_id']) for r in rows if r['evolves_from_species_id']}
types={}
for r in csv.DictReader(open('data/source/pokemon_types.csv',encoding='utf-8-sig')):
 types.setdefault(int(r['pokemon_id']),[]).append(int(r['type_id']))
# Default species forms only. At most one endpoint in each evolution chain.
candidates=rows
row_by_id={int(r["id"]):r for r in rows}
for r in rows:
 parent=r["evolves_from_species_id"]
 while parent:
  types[int(r["id"])]=list(set(types[int(r["id"])])|set(types[int(parent)]))
  parent=row_by_id[int(parent)]["evolves_from_species_id"]
roster=json.loads(Path('data/roster.json').read_text(encoding='utf-8-sig'))
oldchains={chain[r['id']] for r in roster}
A=[];lo=[];hi=[]
for t in range(1,19):
 A.append([int(t in types.get(int(r['id']),[])) for r in candidates]);lo.append(7);hi.append(np.inf)
for ch in sorted(set(chain.values())):
 A.append([int(chain[int(r['id'])]==ch) for r in candidates]);lo.append(0);hi.append(1)
A.append([1]*len(candidates));lo.append(70);hi.append(70)
cost=[1000*(int(r['generation_id'])>3)+int(chain[int(r['id'])] not in oldchains) for r in candidates]
res=milp(cost,integrality=np.ones(len(candidates)),bounds=Bounds(0,1),constraints=LinearConstraint(np.array(A),lo,hi),options={'time_limit':30})
print(res.message)
if res.x is not None:
 selected=[r for r,x in zip(candidates,res.x) if x>0.5]
 Path('docs/roster-solution.json').write_text(json.dumps(selected,indent=2),encoding='utf-8')
 print('Later species:',[(r['id'],r['identifier']) for r in selected if int(r['generation_id'])>3])
 print('Counts:',{t:sum(t in types[int(r['id'])] for r in selected) for t in range(1,19)})
