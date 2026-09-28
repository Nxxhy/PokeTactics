extends SceneTree
const Endpoint = preload("res://core/lobby_endpoint.gd")
func _init():
 var failures = 0
 for url in ["http://127.0.0.1:18790","http://192.168.178.20:18790","http://10.0.0.5:18790","http://172.31.0.2:18790","https://example.com"]:
  if not Endpoint.allowed(url):
   push_error("Rejected valid endpoint: "+url)
   failures += 1
 for url in ["http://8.8.8.8:80","http://172.32.0.1:80","http://192.168.1.2.evil.test:80","http://192.168.1.2:99999","http://192.168.1.2:80/path","http://user@192.168.1.2:80","file:///tmp"]:
  if Endpoint.allowed(url):
   push_error("Accepted invalid endpoint: "+url)
   failures += 1
 print("LAN ENDPOINT: %d passed, %d failed" % [12-failures,failures])
 quit(1 if failures else 0)
