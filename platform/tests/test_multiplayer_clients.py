import os, pathlib, subprocess, time, uuid
root=pathlib.Path(__file__).resolve().parents[2]
godot=pathlib.Path(os.environ.get('POKE_GODOT_PATH',str(root.parent/'Godot/Godot_v4.7.2-stable_win64_console.exe')))
exchange=root/'platform/tests/.runtime'/('mp-'+str(uuid.uuid4()))
exchange.parent.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env.update(ASPNETCORE_URLS='http://127.0.0.1:18797',POKE_LAN='1',POKE_REQUIRED_VERSION='9.3.0',POKE_GAME_DIR=str(root/'dist/PlayerBuild'))
processes=[];logs=[]
try:
 logs.append(open(root/'docs/mp-process-server.log','w'))
 server=subprocess.Popen(['dotnet',str(root/'platform/Server/bin/Release/net10.0/Server.dll')],env=env,stdout=logs[-1],stderr=logs[-1]);processes.append(server)
 time.sleep(1)
 for role in ['host','guest']:
  logs.append(open(root/f'docs/mp-process-{role}.log','w'))
  processes.append(subprocess.Popen([str(godot),'--headless','--path',str(root),'--log-file',str(root/f'docs/mp-engine-{role}.log'),'--script','res://tests/multiplayer_client.gd','--',role,str(exchange)],stdout=logs[-1],stderr=logs[-1]))
 for process in processes[1:]:
  if process.wait(timeout=105)!=0: raise RuntimeError('Godot client failed; inspect mp-process logs')
 for role in ['host','guest']:
  text=(root/f'docs/mp-process-{role}.log').read_text()
  if 'SCRIPT ERROR' in text or 'MULTIPLAYER CLIENT '+role not in text: raise RuntimeError('Client did not finish successfully: '+role)
  print(text,flush=True)
 print('PASS Two separate Godot game processes complete one shared multiplayer match.')
finally:
 for process in reversed(processes):
  if process.poll() is None: process.terminate();process.wait(timeout=10)
 for log in logs:log.close()
