import pathlib,os,subprocess,secrets,time
root=pathlib.Path(__file__).resolve().parents[2]
env=os.environ.copy();env.update(POKE_ADMIN_TOKEN=secrets.token_hex(32),POKE_DATA=str(root/'platform/tests/.runtime/godot-server'),ASPNETCORE_URLS='http://127.0.0.1:18794')
with open(root/'docs/v9-godot-server.log','w') as log:
 server=subprocess.Popen(['dotnet',str(root/'platform/Server/bin/Release/net10.0/Server.dll')],env=env,stdout=log,stderr=log)
 try:
  time.sleep(2)
  result=subprocess.run([str(root.parent/'Godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(root),'--log-file',str(root/'docs/v9-lobby-client.log'),'--script','res://tests/test_v9_lobby.gd'],timeout=60)
  raise SystemExit(result.returncode)
 finally:server.terminate();server.wait(timeout=10)
