extends SceneTree
const League = preload("res://core/league.gd")
func _init():
 var league = League.new()
 while true:
  var line = OS.read_string_from_stdin()
  if line.is_empty(): break
  var query = JSON.parse_string(line)
  if not query is Dictionary: continue
  var result = {"ok":true,"message":""}
  match query.get("op",""):
   "init": league.initialize(query.members,int(query.seed))
   "command": result = league.command(query.id,query.action,int(query.revision),int(query.seq))
   "ready": result = league.ready(query.id,int(query.stage))
   "ack": league.acknowledge(query.id,int(query.serial))
   "drop": league.drop(query.id)
  if not league.players.is_empty(): league.advance(Time.get_unix_time_from_system())
  var response = {"result":result}
  if league.players.has(query.get("id","")): response.match_state = league.view(query.id,int(query.get("seen",-1)))
  print("NET:"+JSON.stringify(response))
 quit()
