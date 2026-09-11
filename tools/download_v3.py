import json,pathlib,urllib.request,concurrent.futures,hashlib
P=pathlib.Path(__file__).resolve().parents[1]
roster=json.loads((P/'data/roster.json').read_text(encoding='utf-8'))
ids=sorted({f for m in roster for f in m['forms']})
def fetch(id):
 path=P/'assets/pokemon'/f'{id}.png'
 url=f'https://raw.githubusercontent.com/PokeAPI/sprites/6e523c72bb714306c90912647e0b2ccc4fd2fff1/sprites/pokemon/{id}.png'
 if not path.exists():
  with urllib.request.urlopen(url,timeout=30) as r: data=r.read()
  assert data.startswith(b'\x89PNG\r\n\x1a\n')
  path.write_bytes(data)
 return dict(id=id,url=url,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool: manifest=list(pool.map(fetch,ids))
(P/'assets/manifest-v3.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Verified sprites',len(manifest))
