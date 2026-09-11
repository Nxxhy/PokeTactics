extends SceneTree
const Model = preload("res://core/match.gd")
const Battle = preload("res://core/battle.gd")
var passed = 0
var failed = 0
func _init():
 for difficulty in Model.Difficulty.SETTINGS:
  for seed_value in range(4):
   var game = Model.new(seed_value,difficulty)
   for round_no in range(1,31):
    game.state.round = round_no
    game.state.wins = round_no-1
    game._make_enemy()
    var enemy = game.state.enemy
    var ids = {}
    var occupied = {}
    var valid = true
    for u in enemy:
     valid = valid and not ids.has(u.species) and not occupied.has(u.slot) and u.slot >= 0 and u.slot < 21 and u.star >= 1 and u.star <= 3
     ids[u.species] = true
     occupied[u.slot] = true
     var m = game.catalog.get_mon(u.species)
     if m.role == "Unterstützer": check(u.slot >= 14,"Healers positioned behind front")
    check(valid and enemy.size() >= 2 and enemy.size() <= 10,"Valid distinct themed team")
    check(enemy == Model.Difficulty.team(game.catalog,seed_value,round_no,difficulty),"Deterministic difficulty team")
    var counts = game.catalog.synergies(enemy)
    check(counts.values().any(func(n): return n >= 2) or difficulty == "Leicht","Normal/hard have active synergies")
   var copy = Model.new(0)
   check(copy.restore(JSON.parse_string(JSON.stringify(game.snapshot()))) and copy.state.difficulty == difficulty and copy.state.enemy == game.state.enemy,"Difficulty survives save/load")
 var cat = preload("res://core/catalog.gd").new()
 for round_no in range(1,31):
  var strengths = []
  for difficulty in ["Leicht","Normal","Schwer"]:
   var team = Model.Difficulty.team(cat,0,round_no,difficulty)
   var power = 0.0
   for u in team:
    var stats = cat.stats(u)
    power += stats.hp+stats.attack*6+stats.power
   strengths.append(power)
  check(strengths[0] < strengths[1] and strengths[1] < strengths[2],"Difficulty strength ordering round %d" % round_no)
 var game = Model.new(6)
 game.state.discount_ready = true
 game.state.gold = 10
 for old in game.state.shop:
  if old != 0: game.state.pool[str(int(old))] += 1
 game.state.shop = [150,0,0,0,0]
 game.state.pool["150"] -= 1
 check(game.purchase_cost(150) == 4,"Actual discounted price")
 game.command({"type":"buy","index":0})
 check(game.state.gold == 6 and not game.state.discount_ready,"Exactly displayed discounted amount charged once")
 var invalid = game.snapshot()
 invalid.difficulty = "Impossible"
 check(not game.restore(invalid),"Invalid saved difficulty rejected")
 print("V4 DIFFICULTY: %d passed, %d failed" % [passed,failed])
 quit(1 if failed else 0)
func check(ok: bool,label: String):
 if ok: passed += 1
 else:
  failed += 1
  printerr("FAIL: "+label)
