import csv,json
from pathlib import Path
rows={int(r['id']):r for r in csv.DictReader(open('data/source/pokemon_species.csv',encoding='utf-8-sig'))};roster=json.loads(Path('data/roster.json').read_text(encoding='utf-8'));old=json.loads(Path('data/roster-v7-backup.json').read_text(encoding='utf-8'));old_by={m['id']:m for m in old};names=json.loads(Path('data/form_names.json').read_text(encoding='utf-8'))
for mon in roster:
 end=mon['forms'][-1];original_end=end
 while True:
  children=[i for i,r in rows.items() if int(r['evolves_from_species_id'] or 0)==end and (int(r['generation_id'])<=3 or i==478)]
  if not children:break
  preferred=old_by.get(mon['id'],{}).get('forms',[])
  end=next((i for i in children if i in preferred),sorted(children)[0])
  mon['forms'].append(end)
 assert len(mon['forms'])<=3
 if original_end!=end and mon['id'] not in old_by:mon['ability']=mon['ability'].replace(names[str(original_end)]+'s ',names[str(end)]+'s ')
Path('data/roster.json').write_text(json.dumps(roster,ensure_ascii=False,indent=2),encoding='utf-8')
count=len({i for m in roster for i in m['forms']});print('Full evolution assets',count)
for f in ['tests/test_ui.gd','tests/test_v5.gd']:
 p=Path(f);s=p.read_text(encoding='utf-8').replace('119',str(count));p.write_text(s,encoding='utf-8')
