import json
from pathlib import Path
old=json.loads(Path('data/roster-v7-backup.json').read_text(encoding='utf-8'));new=json.loads(Path('data/roster.json').read_text(encoding='utf-8'))
oldids={m['id'] for m in old}; newids={m['id'] for m in new}
removed=sorted([m for m in old if m['id'] not in newids],key=lambda m:(m['cost'],m['id']))
added=sorted([m for m in new if m['id'] not in oldids],key=lambda m:(m['cost'],m['id']))
alias={a['id']:b['id'] for a,b in zip(removed,added)}
p=Path('core/catalog.gd');s=p.read_text(encoding='utf-8').replace('const VERSION = 4','const REPLACEMENTS = '+str(alias)+'\nconst VERSION = 4');p.write_text(s,encoding='utf-8')
p=Path('core/match.gd');s=p.read_text(encoding='utf-8').replace('for id in [1,4,7]:','for original in [1,4,7]:\n  var id = Catalog.REPLACEMENTS.get(original,original)');p.write_text(s,encoding='utf-8')
p=Path('core/difficulty.gd');s=p.read_text(encoding='utf-8').replace('var theme = THEMES[posmod(seed_value+int((round_no-1)/5),THEMES.size())]','var theme = THEMES[posmod(seed_value+int((round_no-1)/5),THEMES.size())].map(func(id): return catalog.REPLACEMENTS.get(id,id))').replace('  var mon = catalog.get_mon(id)','  id = catalog.REPLACEMENTS.get(id,id)\n  var mon = catalog.get_mon(id)');p.write_text(s,encoding='utf-8')
p=Path('tools/pack.gd');s=p.read_text(encoding='utf-8').replace(' files.append("assets/fonts/pkmnem.ttf")',' files.append_array(["core/traits.gd","data/traits.json","data/roster-v7-backup.json"])\n files.append("assets/fonts/pkmnem.ttf")');p.write_text(s,encoding='utf-8')
# Retain old atlases; fetch only new IDs, then add their animation entries.
p=Path('tools/import_idle.py');s=p.read_text(encoding='utf-8');s=s.replace('def fetch(id):','existing=json.loads((OUT/"manifest.json").read_text(encoding="utf-8")) if (OUT/"manifest.json").exists() else {}\n\ndef fetch(id):\n if str(id) in existing and not existing[str(id)].get("fallback") and (OUT/f"{id}.png").exists(): return str(id),existing[str(id)]');p.write_text(s,encoding='utf-8')
print('Replacements',alias)
