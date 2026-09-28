extends SceneTree
var shell
var ui
var checks = 0
var seen = 0
var role = "guest"
var exchange = ""
func _init(): call_deferred("run")
func check(ok, message):
 if not ok:
  push_error(role+": "+message)
  quit(1)
  return false
 checks += 1
 return true
func response():
 var until = Time.get_ticks_msec()+35000
 while not shell.pending.is_empty() and Time.get_ticks_msec()<until: await process_frame
func run():
 var args = OS.get_cmdline_user_args()
 role = args[0]
 exchange = args[1]
 ui = load("res://ui/main.tscn").instantiate()
 ui.save_path = "res://tests/mp-no-save.json"
 root.add_child(ui)
 shell = load("res://ui/shell.gd").new()
 ui.shell = shell
 ui.add_child(shell)
 shell.version = "9.3.0"
 shell.service = "http://127.0.0.1:18797"
 shell.player_name = role
 if role == "host":
  shell.show_screen("create")
  shell.request("create")
  await response()
  if not check(not shell.room.is_empty(),"Lobby created"): return
  var file = FileAccess.open(exchange,FileAccess.WRITE)
  file.store_string(shell.room.code)
  file.close()
 else:
  var deadline = Time.get_ticks_msec()+20000
  while not FileAccess.file_exists(exchange) and Time.get_ticks_msec()<deadline: await process_frame
  shell.show_screen("join")
  shell.code_input.text = FileAccess.get_file_as_string(exchange)
  shell.request("join")
  await response()
  if not check(not shell.room.is_empty(),"Guest joins"): return
 shell.request("ready",{"ready":true})
 await response()
 var timeout = Time.get_ticks_msec()+90000
 while Time.get_ticks_msec()<timeout:
  await process_frame
  if not shell.pending.is_empty(): continue
  if not shell.network_match:
   if role == "host" and shell.room.get("members",[]).size()==2 and shell.room.members.all(func(m):return m.ready):
    shell.request("start")
   continue
  if not ui.playback.is_empty():
   if int(shell.seen_battle)>seen:
    seen = int(shell.seen_battle)
    if not check(ui.playback.frames.size()>1,"Received actual animated combat frames"): return
    if not check(ui.playback.winner == 0 if ui.game.state.outcome == "win" else ui.playback.winner != 0,"Displayed winner matches authoritative result"): return
    # Same operation as the player's 'Zum Ergebnis' control.
    ui._finish_playback()
   continue
  if shell.match_state.phase == "finished":
   if not check(shell.screen == "multiplayer_result","Shared result screen displayed"): return
   if not check(seen>0,"At least one real opponent battle played"): return
   print("MULTIPLAYER CLIENT %s: %d passed, serial %d" % [role,checks,seen])
   # Keep host heartbeat alive until both clients have observed the final result.
   var done = FileAccess.open(exchange+"."+role,FileAccess.WRITE)
   done.store_string("ok")
   done.close()
   while not FileAccess.file_exists(exchange+".host") or not FileAccess.file_exists(exchange+".guest"): await process_frame
   quit()
   return
  if shell.match_state.phase == "planning" and not shell.match_state.ready and ui.game.state.lives>0:
   if not ui.game.state.augment_offers.is_empty(): ui._send({"type":"augment","index":0})
   else: ui._send({"type":"battle"})
 push_error(role+": multiplayer client timed out")
 quit(1)
