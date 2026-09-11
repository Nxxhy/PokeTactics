import urllib.request,urllib.error,json,concurrent.futures,subprocess,os,secrets,pathlib,time,zipfile,io,hashlib,base64
root=pathlib.Path(__file__).resolve().parents[2]
runtime=root/'platform/tests/.runtime';runtime.mkdir(exist_ok=True)
token=secrets.token_hex(32)
env=os.environ.copy();env.update(POKE_ADMIN_TOKEN=token,POKE_DATA=str(runtime/'server'),ASPNETCORE_URLS='http://127.0.0.1:18791')
(runtime/'admin.json').write_text(json.dumps(dict(token=token,endpoint='http://127.0.0.1:18791')))
log=open(root/'docs/v9-server.log','w')
server=subprocess.Popen(['dotnet',str(root/'platform/Server/bin/Release/net10.0/Server.dll')],env=env,stdout=log,stderr=log)
passed=0
def request(path,body=None,auth=None,headers=None,raw=None):
 data=raw if raw is not None else json.dumps(body).encode() if body is not None else None
 h={'Content-Type':'application/json'} if raw is None else {'Content-Type':'application/zip'}
 if auth:h['Authorization']='Bearer '+auth
 if headers:h.update(headers)
 req=urllib.request.Request('http://127.0.0.1:18791'+path,data=data,headers=h)
 try:
  with urllib.request.urlopen(req,timeout=30) as r:return r.status,json.load(r)
 except urllib.error.HTTPError as e:
  text=e.read();return e.code,json.loads(text) if text else {}
def check(value,label):
 global passed
 assert value,label
 passed+=1;print('PASS',label,flush=True)
def join(code='',name='Trainer',version='9.0.0'):return request('/lobby',dict(name=name,code=code,version=version))
def session(member,action='poll',**extra):return request('/lobby/'+member['lobby']['code']+'/session',dict(action=action,version='9.0.0',**extra),member['token'])
try:
 for _ in range(50):
  try:
   if request('/health')[0]==200:break
  except OSError:time.sleep(.2)
 check(join(version='8.0.0')[0]==426,'Old lobby version rejected server-side')
 check(join('BAD')[0]==404,'Invalid code')
 check(join(name='')[0]==400,'Empty name rejected')
 _,host=join(name='Host');code=host['lobby']['code']
 with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool: results=list(pool.map(lambda n:join(code,'Trainer '+str(n)),range(16)))
 guests=[r[1] for r in results if r[0]==200]
 check(len(guests)==7 and sum(r[0]==409 for r in results)==9,'16 concurrent joins fill exactly seven remaining slots; ninth rejected')
 guest=guests[0]
 check(session(guest,'ready',ready=True)[0]==200,'Ready command accepted')
 _,view=session(host)
 check(len(view['members'])==8 and next(m for m in view['members'] if m['id']==guest['lobby']['me'])['ready'],'Ready and eight members synchronized between clients')
 check(session(guest,'kick',target=host['lobby']['me'])[0]==403,'Non-host cannot kick')
 before=guest['lobby']['me']
 time.sleep(6)
 _,view=session(host)
 check(not next(m for m in view['members'] if m['id']==before)['connected'],'Disconnect becomes visible')
 _,view=session(guest)
 check(view['me']==before and len(view['members'])==8,'Reconnect preserves same slot and ready state')
 check(session(host,'kick',target=before)[0]==200 and session(guest)[0]==403,'Host kick removes authorization')
 check(join(code)[0]==200,'Freed slot reusable')
 check(session(host,'leave')[0]==200 and session(guests[1])[0]==410,'Host leave closes lobby for everyone')
 _,h2=join();_,g2=join(h2['lobby']['code'])
 check(session(g2,'leave')[0]==200 and len(session(h2)[1]['members'])==1,'Guest leave synchronized')
 # Guest stays active; host exceeds grace period and the whole room closes.
 _,g3=join(h2['lobby']['code'])
 for _ in range(6):time.sleep(5);session(g3)
 check(session(g3)[0]==410,'Permanent host loss closes room after grace')
 check(request('/admin/releases')[0]==404,'Legacy publisher endpoint removed')
 check(request('/updates/latest')[0]==404,'Legacy update endpoint removed')
 print(f'SERVER: {passed} passed, 0 failed',flush=True)
 (root/'docs/v9-server-tests.txt').write_text(f'{passed} passed, 0 failed\nConcurrent HTTP clients on one Windows device; no public hosting/device verification.\n')
finally:
 server.terminate();server.wait(timeout=15);log.close()
