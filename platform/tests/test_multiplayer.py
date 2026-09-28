import json, os, pathlib, subprocess, time, urllib.request, urllib.error
root = pathlib.Path(__file__).resolve().parents[2]
env = os.environ.copy()
env.update(ASPNETCORE_URLS='http://127.0.0.1:18796', POKE_LAN='1', POKE_REQUIRED_VERSION='9.3.0', POKE_GAME_DIR=str(root/'dist/PlayerBuild'))
log = open(root/'docs/multiplayer-server.log','w')
server = subprocess.Popen(['dotnet',str(root/'platform/Server/bin/Release/net10.0/Server.dll')],env=env,stdout=log,stderr=log)
count=0
def check(ok, name):
 global count
 assert ok, name
 count+=1
 print('PASS',name,flush=True)
def req(path, data=None, token=None):
 headers={'Content-Type':'application/json'}
 if token: headers['Authorization']='Bearer '+token
 request=urllib.request.Request('http://127.0.0.1:18796'+path,data=json.dumps(data).encode() if data is not None else None,headers=headers)
 try:
  with urllib.request.urlopen(request,timeout=35) as result: return result.status,json.load(result)
 except urllib.error.HTTPError as e: return e.code,json.load(e)
def join(name, code=''): return req('/lobby',dict(name=name,code=code,version='9.3.0'))[1]
def action(member, action, **extra): return req('/lobby/'+member['lobby']['code']+'/session',dict(action=action,version='9.3.0',**extra),member['token'])
try:
 for _ in range(50):
  try:
   if req('/health')[0]==200: break
  except OSError: time.sleep(.2)
 host=join('Host'); guest=join('Gast',host['lobby']['code'])
 check(action(guest,'start')[0]==403,'Non-host cannot start match')
 check(action(host,'start')[0]==409,'Unready participants cannot start')
 action(host,'ready',ready=True);action(guest,'ready',ready=True)
 code, view=action(host,'start')
 check(code==200 and view['match_state']['phase']=='planning','Host starts actual authoritative Godot worker')
 start=view['match_state']['state']
 command=dict(command={'type':'xp'},revision=start['revision'],seq=1)
 code, updated=action(host,'command',**command)
 check(code==200 and updated['match_state']['state']['gold']==start['gold']-4,'Network XP command uses authoritative economy')
 code, duplicate=action(host,'command',**command)
 check(duplicate['match_state']['state']['gold']==updated['match_state']['state']['gold'],'Retried request cannot spend gold twice')
 check(action(host,'command',command=None)[0]==400,'Malformed command rejected before worker')
 check(req('/lobby',dict(name='Late',code=host['lobby']['code'],version='9.3.0'))[0]==409,'Cannot join started match')
 check(action(host,'kick',target=guest['lobby']['me'])[0]==409,'Host cannot kick opponents during match')
 final=None
 seq={'host':1,'guest':0}
 for turn in range(15):
  snapshots={}
  for name, member in [('host',host),('guest',guest)]:
   _,v=action(member,'poll',seen=0);snapshots[name]=v['match_state']
  if snapshots['host']['phase']=='finished': final=snapshots['host'];break
  stage=snapshots['host']['stage']
  for name,member in [('host',host),('guest',guest)]:
   s=snapshots[name]['state']
   while s['augment_offers']:
    seq[name]+=1
    _,v=action(member,'command',command={'type':'augment','index':0},revision=s['revision'],seq=seq[name]);s=v['match_state']['state']
   check(action(member,'round_ready',stage=stage)[0]==200,'Trainer readies stage '+str(stage))
  _,a=action(host,'poll');_,b=action(guest,'poll')
  a=a['match_state'];b=b['match_state']
  check(a['recipe']['seed']==b['recipe']['seed'] and a['recipe']['winner']==b['recipe']['winner'],'Both clients receive one canonical battle recipe')
  winner=a['recipe']['winner']
  for name,snapshot,side in [('host',a,0),('guest',b,1)]:
   before=snapshots[name]['state']
   side=snapshot['recipe']['side']
   check(snapshot['state']['lives']==before['lives']-(0 if winner==side else 1),'One life removed only for loss or draw')
   check(snapshot['state']['round']==before['round']+(1 if winner==side else 0),'Only winner advances personal round')
  action(host,'battle_ack',seen=a['serial']);action(guest,'battle_ack',seen=b['serial'])
 check(final is not None and final['phase']=='finished','Actual match reaches final result with elimination')
 check(sum(s['lives']>0 for s in final['scores'])<=1,'At most one survivor/champion')
 action(host,'leave')
 check(action(guest,'poll')[0]==410,'Host closes multiplayer room cleanly')
 host=join('Reconnect host');guest=join('Reconnect guest',host['lobby']['code'])
 action(host,'ready',ready=True);action(guest,'ready',ready=True);action(host,'start')
 original=guest['lobby']['me']
 time.sleep(6)
 _,disconnected=action(host,'poll')
 check(not disconnected['members'][1]['connected'],'Temporary match disconnect is visible')
 _,rejoined=action(guest,'poll')
 check(rejoined['me']==original and rejoined['match_state']['state']['lives']==3,'Reconnect keeps authoritative team and lives')
 for _ in range(16): time.sleep(2);action(host,'poll')
 _,remaining=action(host,'poll')
 check(remaining['match_state']['phase']=='finished' and remaining['match_state']['champion']==host['lobby']['me'],'Expired participant is eliminated automatically')
 check(action(guest,'poll')[0]==403,'Expired participant cannot re-enter running session')
 action(host,'leave')
 print('MULTIPLAYER HTTP:',count,'passed, 0 failed',flush=True)
 (root/'docs/multiplayer-tests.txt').write_text(f'{count} passed, 0 failed. Actual Godot worker and HTTP clients on one PC.\n')
finally:
 server.terminate();server.wait(timeout=15);log.close()
