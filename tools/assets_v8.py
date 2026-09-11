import json,urllib.request,concurrent.futures,hashlib
from pathlib import Path
ids={f for m in json.loads(Path('data/roster.json').read_text(encoding='utf-8')) for f in m['forms']}
def fetch(i):
 p=Path(f'assets/pokemon/{i}.png')
 if p.exists(): return
 url=f'https://raw.githubusercontent.com/PokeAPI/sprites/6e523c72bb714306c90912647e0b2ccc4fd2fff1/sprites/pokemon/{i}.png'
 raw=urllib.request.urlopen(url,timeout=30).read();p.write_bytes(raw)
 print(i,len(raw))
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:list(pool.map(fetch,ids))
