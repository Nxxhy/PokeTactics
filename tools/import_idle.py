"""Import pinned PokeAPI GIFs as fixed-canvas PNG atlases, preserving GIF timing."""
import concurrent.futures, hashlib, io, json, math, urllib.request
from pathlib import Path
from PIL import Image, ImageSequence
ROOT = Path(__file__).resolve().parents[1]
COMMIT = '6e523c72bb714306c90912647e0b2ccc4fd2fff1'
OUT = ROOT/'assets/animated'
OUT.mkdir(exist_ok=True)
ids = sorted({int(i) for mon in json.loads((ROOT/'data/roster.json').read_text(encoding='utf-8-sig')) for i in mon['forms']})
existing=json.loads((OUT/"manifest.json").read_text(encoding="utf-8")) if (OUT/"manifest.json").exists() else {}

def fetch(id):
 if str(id) in existing and not existing[str(id)].get("fallback") and (OUT/f"{id}.png").exists(): return str(id),existing[str(id)]
 url = f'https://raw.githubusercontent.com/PokeAPI/sprites/{COMMIT}/sprites/pokemon/versions/generation-v/black-white/animated/{id}.gif'
 try:
  raw = urllib.request.urlopen(url, timeout=30).read()
  gif = Image.open(io.BytesIO(raw))
  frames=[]; durations=[]; bounds=None
  for frame in ImageSequence.Iterator(gif):
   rgba=frame.convert('RGBA'); frames.append(rgba.copy())
   durations.append(max(20,frame.info.get('duration',100))/1000)
   box=rgba.getbbox()
   if box: bounds=box if bounds is None else (min(bounds[0],box[0]),min(bounds[1],box[1]),max(bounds[2],box[2]),max(bounds[3],box[3]))
  if len(frames)<2: raise ValueError('No animation frames')
  # A single union crop for the entire loop prevents per-frame scale/anchor jumps.
  w,h=bounds[2]-bounds[0],bounds[3]-bounds[1]
  columns=min(16,len(frames)); sheet=Image.new('RGBA',(w*columns,h*math.ceil(len(frames)/columns)))
  for n,frame in enumerate(frames): sheet.paste(frame.crop(bounds),(n%columns*w,n//columns*h))
  sheet.save(OUT/f'{id}.png')
  return str(id),dict(url=url,sha256=hashlib.sha256(raw).hexdigest(),width=w,height=h,columns=columns,frames=len(frames),durations=durations)
 except Exception as exc: return str(id),dict(fallback=True,reason=str(exc),url=url)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool: result=dict(pool.map(fetch,ids))
(OUT/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('Animated:',sum(not v.get('fallback') for v in result.values()),'Fallback:',sum(bool(v.get('fallback')) for v in result.values()))
