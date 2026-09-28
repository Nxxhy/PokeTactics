extends SceneTree
const League = preload("res://core/league.gd")
var passed = 0
var failed = 0
func check(ok, text):
 if ok: passed += 1
 else:
  failed += 1
  push_error(text)
func _init():
 var league = League.new()
 league.initialize([{"id":"a","name":"A"},{"id":"b","name":"B"}],1234)
 check(league.living().size() == 2,"Two authoritative players initialized")
 var before = league.view("a").state
 var command = {"type":"xp"}
 var answer = league.command("a",command,int(before.revision),1)
 var gold = league.view("a").state.gold
 check(answer.ok and gold == before.gold-4,"Server applies purchase")
 check(league.command("a",command,int(before.revision),1).ok and league.view("a").state.gold == gold,"Duplicate command id never spends twice")
 check(not league.command("a",command,int(before.revision),2).ok,"Stale revision rejected")
 check(not league.command("a",{"type":"battle"},-1,3).ok,"Client cannot settle own battle")
 var team = league.players.a.model.board()
 var unbuffed = League.Battle.new().prepare(team,team,17)
 var buffed = League.Battle.new().prepare(team,team,17,[],["neighbors"])
 check(buffed[team.size()].max_hp > unbuffed[team.size()].max_hp,"Opponent augments affect their team")
 check(buffed[0].max_hp == unbuffed[0].max_hp,"Opponent augment does not leak to player team")
 check(league.ready("a",1).ok and league.phase == "planning","First player waits for opponent")
 check(not league.command("a",{"type":"reroll"},-1,4).ok,"Ready team locked")
 check(league.ready("b",1).ok and league.phase == "battle","Both ready start one shared battle")
 var a = league.view("a")
 var b = league.view("b")
 check(a.recipe.seed == b.recipe.seed and a.recipe.winner == b.recipe.winner,"Both perspectives share canonical outcome")
 var replay_a = League.replay(a.recipe)
 var replay_b = League.replay(b.recipe)
 check(replay_a.winner == -1 or replay_a.winner == 1-replay_b.winner,"Replay winners are complementary")
 for i in range(replay_a.frames[0].units.size()):
  check(replay_a.frames[0].units[i].y + replay_b.frames[0].units[i].y == 5,"Opponent perspective reflects ground position")
 check(a.state.lives + b.state.lives in [4,5],"Exactly one loser, or both on timeout, loses one life")
 check(not league.view("a",int(a.serial)).has("recipe"),"Already received battle is not retransmitted")
 league.acknowledge("a",int(a.serial))
 league.acknowledge("b",int(b.serial))
 check(league.stage == 2,"Both acknowledgements unlock next planning phase")
 check(not league.ready("a",1).ok,"Stale ready cannot trigger new round")
 league.drop("b")
 check(league.phase == "finished" and league.champion == "a","Disconnect/leave produces final champion")
 var odd = League.new()
 odd.initialize([{"id":"a","name":"A"},{"id":"b","name":"B"},{"id":"c","name":"C"}],42)
 var bye = odd.pairs[-1][0]
 odd.advance(odd.deadline+1)
 check(odd.phase == "battle" and odd.players[bye].model.state.lives == 3,"Planning timeout and odd-player bye work")
 check(odd.players[bye].model.state.gold == 20,"Bye receives explicit income")
 odd.advance(odd.deadline+1)
 check(odd.stage == 2 and odd.pairs[-1][0] != bye,"Bye rotates next stage")
 var full = League.new()
 var members: Array = []
 for i in range(8): members.append({"id":str(i),"name":"Trainer "+str(i)})
 full.initialize(members,98765)
 var steps = 0
 while full.phase != "finished" and steps < 30:
  full.advance(full.deadline+1)
  if full.phase == "battle":
   for id in full.order:
    var view = full.view(id)
    check(view.state.lives >= 0 and view.state.lives <= 3,"Eight-player life bounds")
   full.advance(full.deadline+1)
  steps += 1
 check(full.phase == "finished" and full.living().size() <= 1,"Eight players reach a shared final result")
 var lost = League.new()
 lost.initialize(members.slice(0,3),55)
 lost.ready("0",1)
 lost.drop("1")
 check(lost.phase == "planning" and lost.living().size() == 2,"Disconnected opponent is removed and pairings rebuilt")
 check(lost.view("0").state.gold == 14,"Disconnect does not duplicate rewards")
 print("LEAGUE: %d passed, %d failed" % [passed,failed])
 quit(1 if failed else 0)
