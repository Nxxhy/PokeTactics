extends SceneTree
var host
var guest
var passed=0
var failed=0
func _init(): call_deferred("run")
func check(ok,label):
 if ok:passed+=1
 else:failed+=1;printerr("FAIL LOBBY: "+label)
func wait_response(client):
 var start=Time.get_ticks_msec()
 while not client.pending.is_empty() and Time.get_ticks_msec()-start<8000:await process_frame
 await process_frame
func run():
 var ui=load("res://ui/main.tscn").instantiate()
 ui.save_path="res://tests/lobby-no-save.json"
 root.add_child(ui)
 await process_frame
 host=load("res://ui/shell.gd").new();guest=load("res://ui/shell.gd").new()
 ui.add_child(host);ui.add_child(guest)
 for client in [host,guest]:client.service="http://127.0.0.1:18794"
 host.player_name="Host";host.show_screen("create");host.request("create")
 await wait_response(host)
 check(host.screen=="lobby" and not host.token.is_empty(),"Godot client creates real server lobby")
 if host.room.is_empty():quit(1);return
 guest.player_name="Gast";guest.show_screen("join");guest.code_input.text=host.room.code;guest.request("join")
 await wait_response(guest)
 host.request("poll");await wait_response(host)
 check(host.room.members.size()==2 and guest.room.members.size()==2,"Two independent Godot sessions synchronize membership")
 guest.request("ready",{"ready":true});await wait_response(guest)
 host.request("poll");await wait_response(host)
 check(host.room.members[1].ready,"Ready synchronized to host UI")
 guest.http.cancel_request();guest.pending="";guest.set_process(false)
 await create_timer(6).timeout
 host.request("poll");await wait_response(host)
 check(not host.room.members[1].connected,"Disconnect visible in Godot client")
 var uid=guest.room.me
 guest.set_process(true);guest.request("poll");await wait_response(guest)
 check(guest.room.me==uid and guest.room.members.size()==2,"Reconnect keeps same membership")
 host.request("kick",{"target":guest.room.me});await wait_response(host)
 guest.request("poll");await wait_response(guest)
 check(guest.screen=="main" and guest.token.is_empty(),"Kicked client returns to menu with error")
 host.request("leave");await wait_response(host)
 check(host.screen=="main" and host.token.is_empty(),"Host closes lobby and returns to menu")
 print("GODOT LOBBY: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
