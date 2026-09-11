extends SceneTree
const Model = preload("res://core/match.gd")
const Battle = preload("res://core/battle.gd")
const Catalog = preload("res://core/catalog.gd")
var passed = 0
var failed = 0

func _init():
 transactions()
 merges()
 evolution_names()
 rounds()
 shops()
 mana_and_roles()
 abilities()
 deterministic_combat()
 campaigns()
 print("CORE V2: %d passed, %d failed" % [passed,failed])
 quit(1 if failed else 0)

func check(ok: bool,label: String):
 if ok:
  passed += 1
 else:
  failed += 1
  printerr("FAIL: "+label)

func mon(id: int,uid: int = 1,slot: int = 3,star: int = 1) -> Dictionary:
 return {"species":Catalog.REPLACEMENTS.get(id,id),"uid":uid,"slot":slot,"star":star,"zone":"board"}

func offer(game,id: int):
 id = Catalog.REPLACEMENTS.get(id,id)
 for previous in game.state.shop:
  if int(previous) != 0:
   game.state.pool[str(int(previous))] += 1
 game.state.shop = [id,0,0,0,0]
 game.state.pool[str(id)] -= 1

func pool_ok(game) -> bool:
 var counts = {}
 for unit in game.state.units:
  var key = str(int(unit.species))
  counts[key] = int(counts.get(key,0))+int(pow(3,int(unit.star)-1))
 for id in game.state.shop:
  if int(id) != 0:
   counts[str(int(id))] = int(counts.get(str(int(id)),0))+1
 for key in game.state.pool:
  if game.state.pool[key] < 0 or int(game.state.pool[key])+int(counts.get(key,0)) != 18:
   return false
 return true

func transactions():
 var game = Model.new(77)
 var before = game.snapshot()
 for action in [{"type":"buy","index":-1},{"type":"buy","index":"1"},{"type":"buy","index":1.5},{"type":"move","uid":1,"zone":"board","slot":21},{"type":"move","uid":1,"zone":"enemy","slot":0},{"type":"sell","uid":999},{}]:
  check(not game.command(action).ok and game.snapshot() == before,"Invalid command is atomic")
 check(not game.command({"type":"reroll"},99).ok and before == game.snapshot(),"Stale commands cannot spend gold")
 game.state.gold = 0
 for action in [{"type":"buy","index":0},{"type":"reroll"},{"type":"xp"}]:
  before = game.snapshot()
  check(not game.command(action).ok and game.snapshot() == before,"Insufficient funds")
 game.state.gold = 50
 game.command({"type":"buy","index":0})
 var unit = game.state.units.back()
 before = game.snapshot()
 check(not game.validate_move(unit.uid,"board",20).ok and game.snapshot() == before,"Preview checks team limit without mutation")
 check(game.command({"type":"move","uid":unit.uid,"zone":"board","slot":2}).ok,"Occupied tile swaps at full cap")
 check(game.board().size() == 3 and pool_ok(game),"Swap preserves units and pool")
 game.command({"type":"xp"})
 game.command({"type":"xp"})
 check(game.state.level == 4 and game.state.xp == 4,"XP carries across level")
 var shop = game.state.shop.duplicate()
 game.command({"type":"lock"})
 game._settle(0)
 check(game.state.shop == shop,"Shop lock remains functional")

func merges():
 var game = Model.new(33)
 game.state.gold = 200
 for _i in range(8):
  offer(game,1)
  check(game.command({"type":"buy","index":0}).ok and pool_ok(game),"Merge ingredients conserve pool")
 var unit = game.at("board",2)
 check(unit.star == 3 and game.state.units.size() == 3,"Nine copies merge at original location")
 var gold = game.state.gold
 game.command({"type":"sell","uid":unit.uid})
 check(game.state.gold == gold+9 and pool_ok(game),"Three-star sale returns 9 copies")
 game = Model.new(10)
 game.state.gold = 100
 for id in [1,172,37,43,54,63,66,74]:
  offer(game,id)
  game.command({"type":"buy","index":0})
 offer(game,95)
 var before = game.snapshot()
 check(not game.command({"type":"buy","index":0}).ok and before == game.snapshot(),"Full bank rejects purchase atomically")
 offer(game,1)
 check(game.command({"type":"buy","index":0}).ok and game.at("board",2).star == 2 and pool_ok(game),"Full bank permits immediate merge")

func evolution_names():
 var catalog = Catalog.new()
 for entry in catalog.roster:
  for star in range(1,4):
   var unit = mon(int(entry.id),1,3,star)
   check(catalog.form_names.has(str(catalog.sprite_id(unit))),"Every displayed form has a German name")
 check(catalog.display_name(mon(1,1,3,2)) == "Bisaknosp","Second evolution name")
 check(catalog.display_name(mon(1,1,3,3)) == "Bisaflor","Final evolution name")
 check(catalog.display_name(mon(172,1,3,3)) == "Raichu","Two-form line keeps final name")
 check(catalog.display_name(mon(144,1,3,3)) == "Arktos","Single-form species keeps name")
 var game = Model.new(33)
 game.state.gold = 200
 for i in range(8):
  offer(game,1)
  var result = game.command({"type":"buy","index":0})
  if i == 1:
   check(result.message.contains("Bisaknosp"),"Merge announces actual evolved name")
  if i == 7:
   check(result.message.contains("Bisaflor"),"Final merge announces final name")

func rounds():
 var game = Model.new(11)
 check(game.state.lives == 3 and game.state.round == 1,"Exactly 3 starting lives")
 var enemy = game.state.enemy.duplicate(true)
 game._settle(1)
 check(game.state.lives == 2 and game.state.round == 1 and game.state.attempt == 2,"First loss costs one life and retries round")
 check(game.state.enemy == enemy,"Loss keeps identical opponent")
 game._settle(1)
 check(game.state.lives == 1 and game.state.round == 1,"Second loss same round")
 game._settle(1)
 check(game.state.lives == 0 and game.state.round == 1 and game.state.phase == "finished","Third loss ends match")
 var before = game.snapshot()
 check(not game.command({"type":"battle"}).ok and before == game.snapshot(),"Cannot fight or lose lives after game over")
 game = Model.new(4)
 game._settle(1)
 game._settle(0)
 check(game.state.lives == 2 and game.state.round == 2 and game.state.attempt == 1 and game.state.wins == 1,"Only victory advances and resets attempt")
 before = game.snapshot()
 game._settle(-1)
 check(game.state.round == before.round and game.state.lives == before.lives and game.state.gold == before.gold and game.state.xp == before.xp and game.state.shop == before.shop,"Draw repeats without farming resources")
 game = Model.new(1)
 for i in range(30):
  game._settle(0)
  check(game.state.round == i+2,"Each victory advances exactly once")
 check(game.state.phase == "finished" and game.state.wins == 30 and game.state.round == 31,"30 victories complete campaign")
 check(not game.has_method("restore"),"Finished campaigns cannot be restored")
 # Exercise the actual battle command, not just outcome settlement.
 game = Model.new(1337)
 game.state.enemy = [mon(150,1,3,3),mon(147,2,2,3)]
 game.command({"type":"battle"})
 check(game.last_battle.winner == 1 and game.state.lives == 2 and game.state.round == 1,"Actual losing combat does not advance round")
 before = game.snapshot()
 var replay = Battle.new().run(game.last_battle.before.units.filter(func(u): return u.zone == "board"),game.last_battle.before.enemy,int(game.last_battle.seed))
 check(replay.winner == 1 and before == game.snapshot(),"Replaying loss does not lose another life")

func shops():
 var catalog = Catalog.new()
 check(catalog.roster.size() == 70,"70 configured Pokemon")
 for tier in [4,5]:
  check(catalog.roster.filter(func(m): return m.cost == tier).size() == (12 if tier == 4 else 10),"High-cost tier count")
 for level in range(3,11):
  var game = Model.new(700+level)
  game.state.level = level
  var counts = [0,0,0,0,0]
  for _i in range(200):
   game._roll()
   for id in game.state.shop:
    counts[int(catalog.get_mon(int(id)).cost)-1] += 1
  for tier in range(5):
   var percentage = counts[tier]*100.0/1000
   var expected = Model.SHOP_ODDS[level][tier]
   check(absf(percentage-expected) < 5.0,"Measured shop odds match configured tier probabilities L%d C%d" % [level,tier+1])
  check(pool_ok(game),"Rerolls conserve pool across high tiers")
  print("SHOP level %d: %s / 1000" % [level,str(counts)])
 var game = Model.new(19)
 for _i in range(28):
  game._settle(0)
 check(game.state.level >= 8 and game.state.gold >= 100,"Natural progression unlocks premium shop; late levels require investment")
 for id in [131,150]:
  offer(game,id)
  check(game.command({"type":"buy","index":0}).ok,"Premium Pokemon can be bought")
  var unit = game.state.units.back()
  check(game.command({"type":"move","uid":unit.uid,"zone":"board","slot":game._free_slot("board",21)}).ok,"Premium Pokemon can be deployed")

func mana_and_roles():
 var sim = Battle.new()
 var fighters = sim.prepare([mon(74),mon(4,2,2),mon(1,3,1),mon(179,4,0)],[mon(66)],4)
 var tank = fighters[0]
 var attacker = fighters[1]
 var support = fighters[2]
 var mage = fighters[3]
 for unit in [tank,attacker,support,mage]:
  sim.hit(fighters[4],unit,100,"test",true)
 check(tank.mana > attacker.mana and tank.mana >= 18,"Tank gains more mana from damage")
 for unit in [tank,attacker,support,mage]:
  unit.mana = 0
  sim.gain_mana(unit,int(Catalog.ROLES[unit.role].attack))
 check(attacker.mana == 23 and tank.mana == 8 and support.mana == 5,"Attack mana depends on role")
 var result = sim.run([mon(1,1,20)],[mon(74,1,20)],2)
 var first_second = result.frames[10].units[0]
 check(first_second.mana >= 9,"Support generates passive mana in real simulation")
 attacker.mana = 0
 attacker.shield = 300
 sim.hit(tank,attacker,100,"test",true)
 check(attacker.mana == 0,"Fully absorbed damage grants no damage mana")
 sim.gain_mana(attacker,999)
 check(attacker.mana == attacker.max_mana,"Mana clamps at individual cost")
 # Different target preferences and actual retreat behavior.
 fighters = sim.prepare([mon(4)],[mon(74,1,3),mon(66,2,2)],1)
 fighters[2].hp = 50
 check(sim.choose_target(fighters[0],fighters).uid == fighters[2].uid,"Attacker prioritizes wounded targets in reach")
 sim.apply_status(fighters[1],fighters[0],"taunt",20)
 check(sim.choose_target(fighters[0],fighters).uid == fighters[1].uid,"Taunt overrides attack targeting")
 fighters = sim.prepare([mon(1)],[mon(74)],1)
 check(sim.retreat(fighters[0],fighters[1],fighters) and fighters[0].y == 4,"Support can retreat from melee")

func abilities():
 var catalog = Catalog.new()
 var costs = {}
 var names = {}
 for entry in catalog.roster:
  costs[int(entry.mana)] = true
  names[entry.ability] = true
  check(Catalog.ROLES.has(entry.role) and not entry.effects.is_empty() and not entry.description.is_empty(),"Every Pokemon has role and ability")
  var sim = Battle.new()
  var fighters = sim.prepare([mon(int(entry.id)),mon(74,2,4)],[mon(66,1,3),mon(74,2,2),mon(74,3,4),mon(143,4,10)],17)
  var caster = fighters[0]
  caster.hp = int(caster.max_hp*0.5)
  fighters[1].hp = 100
  fighters[1].status = {"poison":20,"stun":10}
  caster.mana = caster.max_mana
  sim.cast(caster,fighters[2],fighters)
  check(caster.mana == 0,"Ability consumes its own mana cost: "+entry.name)
  check(sim.events.filter(func(e): return e.kind == "cast" and e.spell == entry.ability).size() == 1,"Individual ability executes: "+entry.name)
  for effect in entry.effects:
   var kind = {"damage":"hit","mana":"mana","shield":"shield","heal":"heal","cleanse":"cleanse"}.get(effect.kind,"status")
   check(sim.events.any(func(e): return e.kind == kind),"Ability applies real effect %s / %s" % [entry.name,effect.kind])
  var event_count = sim.events.size()
  sim.cast(caster,fighters[2],fighters)
  check(event_count == sim.events.size(),"Cannot cast again without mana")
 check(names.size() == catalog.roster.size() and costs.size() >= 10,"Unique abilities and varied mana costs")
 var sim = Battle.new()
 var fighters = sim.prepare([mon(302)],[mon(74)],1)
 fighters[0].status = {"poison":50,"burn":50,"stun":50}
 fighters[0].dot_power = {"poison":90,"burn":80}
 fighters[0].hp = 100
 fighters[0].mana = fighters[0].max_mana
 sim.cast(fighters[0],fighters[1],fighters)
 check(fighters[0].status.is_empty() and fighters[0].shield > 0,"Zobiris ability actually cleanses and shields")
 check(fighters[0].dot_power.is_empty(),"Cleanse removes stored damage-over-time strength")
 sim.apply_status(fighters[1],fighters[0],"poison",40,8)
 check(fighters[0].dot_power.poison == 8,"New poison after cleanse cannot inherit an old stronger effect")
 fighters = sim.prepare([mon(66)],[mon(4)],1)
 var base_interval = sim.interval(fighters[0])
 sim.apply_status(fighters[1],fighters[0],"slow",20)
 check(sim.interval(fighters[0]) > base_interval,"Slow affects real attack interval")
 var armor = fighters[1].armor
 sim.apply_status(fighters[0],fighters[1],"break",20)
 var lost = sim.hit(fighters[0],fighters[1],100,"test",false,"Normal")
 check(lost > int(10000.0/(100+armor)),"Armor break increases damage")

func deterministic_combat():
 var game = Model.new(1337)
 var source = game.board().duplicate(true)
 var sim = Battle.new()
 var result = sim.run(source,game.state.enemy,17)
 check(result == Battle.new().run(source,game.state.enemy,17),"Full simulation deterministic including visual events")
 check(source == game.board(),"Battle never mutates input")
 var valid = true
 var kinds = {}
 for frame in result.frames:
  var occupied = {}
  for unit in frame.units:
   valid = valid and unit.hp >= 0 and unit.hp <= unit.max_hp and unit.mana >= 0 and unit.mana <= unit.max_mana
   if unit.hp > 0:
    var key = int(unit.y)*7+int(unit.x)
    valid = valid and not occupied.has(key) and unit.x >= 0 and unit.x < 7 and unit.y >= 0 and unit.y < 6
    occupied[key] = true
  for event in frame.events:
   kinds[event.kind] = true
 check(valid,"All frames preserve HP, mana, board bounds and unique occupancy")
 check(kinds.has("attack") and kinds.has("hit") and kinds.has("mana") and kinds.has("cast") and kinds.has("defeat"),"Real combat produces animation events")
 check(result.ticks <= 1200,"Combat has time bound")

func campaigns():
 var ends = []
 for seed_value in range(6):
  var game = Model.new(seed_value)
  var battles = 0
  var draws = 0
  while game.state.phase == "planning" and battles < 40:
   while not game.state.augment_offers.is_empty():
    game.command({"type":"augment","index":0})
   # Affordable upgrade-seeking strategy, reserves slots for late premium recruits.
   for i in range(5):
    var id = int(game.state.shop[i])
    if id == 0:
     continue
    var owned = game.state.units.any(func(u): return int(u.species) == id and u.star < 3)
    if owned or game.state.units.size() < game.state.level+3 or game.catalog.get_mon(id).cost >= 4:
     game.command({"type":"buy","index":i})
   if game.state.gold >= 12 and game.state.level < 10:
    game.command({"type":"xp"})
   var sorted = game.state.units.duplicate()
   sorted.sort_custom(func(a,b):
    var sa = game.catalog.stats(a)
    var sb = game.catalog.stats(b)
    return sa.hp+sa.attack*8 > sb.hp+sb.attack*8)
   for unit in sorted:
    if unit.zone == "bench" and game.board().size() < game.state.level:
     game.command({"type":"move","uid":unit.uid,"zone":"board","slot":game._free_slot("board",21)})
   check(pool_ok(game),"Campaign pool remains conserved")
   check(not game.has_method("restore"),"No restore API exposed")
   var prior = game.state.round
   var lives = game.state.lives
   game.command({"type":"battle"})
   battles += 1
   if game.last_battle.winner == -1:
    draws += 1
   check(game.state.round == prior+(1 if game.last_battle.winner == 0 else 0),"Campaign round advances only on victory")
   check(game.state.lives == lives-(1 if game.last_battle.winner == 1 else 0),"Campaign loses exactly one life per defeat")
  ends.append({"seed":seed_value,"round":game.state.round,"lives":game.state.lives,"battles":battles,"draws":draws})
 print("CAMPAIGNS ",JSON.stringify(ends))
