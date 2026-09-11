extends SceneTree
const Model = preload("res://core/match.gd")
const Battle = preload("res://core/battle.gd")
const Catalog = preload("res://core/catalog.gd")
const Augments = preload("res://core/augments.gd")
var passed = 0
var failed = 0
var cat = Catalog.new()

func _init():
 roster_and_types()
 economy_and_choices()
 shop_completion()
 deployment()
 migration()
 augment_effects()
 print("V3 RULES: %d passed, %d failed" % [passed,failed])
 quit(1 if failed else 0)

func check(ok: bool,label: String):
 if ok:
  passed += 1
 else:
  failed += 1
  printerr("FAIL V3: "+label)

func mon(id: int,uid: int = 1,slot: int = 3,star: int = 1) -> Dictionary:
 return {"species":id,"uid":uid,"slot":slot,"star":star,"zone":"board"}

func roster_and_types():
 check(cat.roster.size() == 70 and cat.species.size() == 386,"70 lines from complete generation 1–3 source")
 var forms = {}
 for cost in range(1,6):
  check(cat.roster.filter(func(m): return m.cost == cost).size() == [16,16,16,12,10][cost-1],"Exact cost distribution")
 for m in cat.roster:
  check(m.id == m.forms[0] and (cat.species[int(m.id)].parent == 0 or cat.species[int(m.id)].parent > 386),"Shop line begins at base form within Gen 1–3: "+m.name)
  if m.cost == 5:
   check(cat.species[int(m.id)].legendary or cat.species[int(m.id)].mythical,"Legendary/mythical premium: "+m.name)
  for id in m.forms:
   check(not forms.has(int(id)),"Evolution belongs to only one purchasable line")
   forms[int(id)] = true
  for star in range(1,4):
   var expected = m.forms[star-1] if m.forms.size() == 3 else (m.forms[-1] if star == 3 else m.forms[0])
   check(cat.sprite_id(mon(m.id,1,3,star)) == expected,"Form/star mapping: "+m.name)
  check(m.range >= 1 and m.range <= 4 and cat.type_chart.has(m.attack_type) and cat.type_chart.has(m.ability_type),"Explicit valid attack types/range")
 for level in range(1,11):
  check(Model.SHOP_ODDS[level].reduce(func(a,b): return a+b,0) == 100,"Shop probabilities sum to 100")
 check(Model.SHOP_ODDS[10][4] == 25 and Model.MAX_ROUNDS == 30 and Model.MAX_LEVEL == 10,"Requested progression limits")
 check(cat.effectiveness("Feuer",mon(1)) == 2,"Super effective")
 check(cat.effectiveness("Wasser",mon(7)) == 0.5,"Resistance")
 check(cat.effectiveness("Elektro",mon(194)) == 0,"Dual type immunity multiplies to zero")
 check(cat.effectiveness("Feuer",mon(123,1,3,3)) == 4,"Dual weakness x4")
 check(cat.effectiveness("Pflanze",mon(4,1,3,3)) == 0.25,"Dual resistance x0.25")
 var sim = Battle.new()
 var f = sim.prepare([mon(172)],[mon(194)],1)
 var hp = f[1].hp
 check(sim.hit(f[0],f[1],500,"attack") == 0 and f[1].hp == hp and f[1].mana == 0,"Immunity deals exactly zero, gives no damage mana")
 check(sim.events.any(func(e): return e.kind == "effectiveness" and e.amount == 0),"Immunity combat feedback")
 var team = [mon(1),mon(1,2),mon(152,3),mon(252,4),mon(43,5)]
 var bench = mon(315,6)
 bench.zone = "bench"
 team.append(bench)
 check(cat.synergies(team).Pflanze == 4,"Only distinct deployed lines count")
 check(cat.synergy_modifiers(team[0],cat.synergies(team)).hp_pct == 0.3,"Four-type synergy stronger stage")
 check(Catalog.distance(Vector2i(2,2),Vector2i(4,3)) == 3,"Shared Manhattan distance")

func offer(game,id: int):
 for old in game.state.shop:
  if old != 0:
   game.state.pool[str(int(old))] += 1
 game.state.shop = [id,0,0,0,0]
 game.state.pool[str(id)] -= 1

func economy_and_choices():
 for gold in [0,9,10,19,20,49,50,99]:
  var game = Model.new(2)
  game.state.gold = gold
  game.state.battle_serial = 1
  game._settle(1,1)
  check(game.state.income.interest == mini(5,int(gold/10)) and game.state.income.before == gold,"Interest uses pre-payout gold")
  var snapshot = game.snapshot()
  game._settle(1,1)
  check(game.snapshot() == snapshot,"Duplicate settlement cannot pay or lose life twice")
  game.state.battle_serial = 2
  game._settle(1,2)
  check(game.state.lives == 1 and game.state.round == 1 and game.state.income.serial == 2,"Retry pays once for new completed battle")
 var game = Model.new(8)
 for round_no in range(1,31):
  game._ensure_augments()
  if round_no in [5,12,20]:
   check(game.state.augment_offers.size() == 3,"Three milestone offers before battle")
   var before = game.snapshot()
   check(not game.command({"type":"battle"}).ok and before == game.snapshot(),"Selection gates battle without mutation")
   var copy = Model.new(9)
   check(copy.restore(JSON.parse_string(JSON.stringify(before))) and copy.state.augment_offers == game.state.augment_offers,"Pending offers survive reload")
   var ids = game.state.augment_offers.duplicate()
   check(ids[0] != ids[1] and ids[0] != ids[2] and ids[1] != ids[2] and ids.all(func(id): return id not in game.state.augments),"Offers unique and exclude previous selections")
   check(game.command({"type":"augment","index":0}).ok,"Exactly one selection accepted")
   check(not game.command({"type":"augment","index":0}).ok,"No second selection")
   if round_no == 5:
    game._settle(1)
    check(game.state.round == 5 and game.state.augment_offers.is_empty() and game.state.augments.size() == 1,"Loss does not repeat augment")
  game._settle(0)
 check(game.state.phase == "finished" and game.state.wins == 30 and game.state.level == 10 and game.state.augments.size() == 3,"30 wins and three permanent augments")

func shop_completion():
 var game = Model.new(3)
 game.state.gold = 500
 for i in range(8):
  offer(game,1)
  game.command({"type":"buy","index":0})
 check(1 in game.state.completed_lines and game.at("board",2).star == 3,"Three-star locks entire line")
 var uid = game.at("board",2).uid
 game.command({"type":"sell","uid":uid})
 game.state.locked = true
 for i in range(60):
  game._roll()
  check(1 not in game.state.shop and 0 not in game.state.shop,"Completed line never returns even after sale")
 var copy = Model.new(9)
 check(copy.restore(JSON.parse_string(JSON.stringify(game.snapshot()))) and 1 in copy.state.completed_lines,"Permanent exclusion persists")
 # Locked current offers of a line must be replaced immediately at the merge.
 game = Model.new(1)
 game.state.gold = 500
 for i in range(7):
  offer(game,1)
  game.command({"type":"buy","index":0})
 offer(game,1)
 game.state.shop[1] = 1
 game.state.pool["1"] -= 1
 game.state.locked = true
 game.command({"type":"buy","index":0})
 check(1 not in game.state.shop and game.state.shop[1] != 0,"Locked duplicate offer replaced on completion")

func deployment():
 var game = Model.new(1)
 game.state.level = 5
 game.state.gold = 50
 for id in [74,63,66]:
  offer(game,id)
  game.command({"type":"buy","index":0})
 var originals = game.board().duplicate(true)
 var first = game.at("bench",0).uid
 var second = game.at("bench",1).uid
 var third = game.at("bench",2).uid
 game.command({"type":"battle"})
 var before = game.last_battle.before.units
 check(before.filter(func(u): return u.zone == "board").size() == 5,"Battle automatically fills team limit")
 check(before.any(func(u): return u.uid == first and u.slot == 0 and u.zone == "board") and before.any(func(u): return u.uid == second and u.slot == 1 and u.zone == "board"),"Autofill preserves bank order")
 check(before.any(func(u): return u.uid == third and u.zone == "bench"),"Autofill never exceeds team limit")
 for old in originals:
  check(before.any(func(u): return u == old),"Manual placement preserved")

func migration():
 var old = Model.new(123).snapshot()
 old.schema = 2
 old.rules = 2
 old.round = 20
 old.wins = 19
 old.lives = 2
 old.level = 8
 old.units[0].species = 25
 old.units[0].star = 3
 old.shop = [25,59,149,242,0]
 var game = Model.new(1)
 check(game.restore(old),"V2 schema migrates")
 check(game.state.lives == 2 and game.state.round == 20 and game.state.units[0].species == 172,"Migration keeps lives/progress and maps bases")
 check(172 in game.state.completed_lines and 172 not in game.state.shop,"Migrated three-star permanently excluded")
 check(game.state.augment_at == 5 and game.state.augment_offers.size() == 3,"Missing historical milestone offered once")
 while not game.state.augment_offers.is_empty():
  game.command({"type":"augment","index":0})
 check(game.state.augment_rounds == [5,12,20],"Migration catches up all three milestones")
 var saved = game.snapshot()
 var copy = Model.new(0)
 var restored = copy.restore(JSON.parse_string(JSON.stringify(saved)))
 check(restored and copy.snapshot() == saved,"Migrated state roundtrips")
 var invalid = saved.duplicate(true)
 invalid.augments[1] = invalid.augments[0]
 check(not copy.restore(invalid) and copy.snapshot() == saved,"Duplicate augments rejected without mutation")

func observable(fighters: Array) -> Array:
 return fighters.map(func(u): return [u.hp,u.max_hp,u.attack,u.power,u.armor,u.interval,u.mana,u.shield,u.status])

func augment_effects():
 var augs = Augments.new()
 check(augs.all.size() == 52,"52 distinct augments")
 var team = [mon(7,1,0),mon(4,2,14),mon(1,3,20),mon(63,4,3),mon(7,5,6),mon(143,6,8),mon(92,7,11),mon(81,8,17),mon(172,9,9),mon(58,10,13)]
 for aug in augs.all:
  if aug.has("condition") or aug.has("emblem"):
   var tested = team
   if aug.has("emblem"):
    tested = []
    for entry in cat.roster:
     if aug.emblem in entry.types and tested.size() < 3:
      tested.append(mon(int(entry.id),tested.size()+1,tested.size()))
   var base = Battle.new().prepare(tested,[],1)
   var changed = Battle.new().prepare(tested,[],1,[aug.id])
   check(observable(base) != observable(changed) or aug.id in ["tank_battery","attacker_battery","mage_battery","support_battery"],"Conditional augment changes actual stats: "+aug.id)
  elif not aug.has("mods"):
   var game = Model.new(42)
   game.state.gold = 60
   game.state.augment_at = 5
   game.state.round = 5
   game.state.wins = 4
   game.state.augment_offers = [aug.id]
   var base = game.snapshot()
   game.command({"type":"augment","index":0})
   var other = Model.new(42)
   other.restore(base.merged({"augment_offers":[]},true))
   if aug.id == "grant":
    check(game.state.gold == 72,"Immediate 12 gold grant")
   elif aug.id == "xp_buy":
    game.command({"type":"xp"})
    check(game.state.level == 4,"XP augment changes real purchase")
   elif aug.id == "free_roll":
    game.command({"type":"reroll"})
    check(game.state.gold == 60 and game.reroll_cost() == 2,"One free reroll consumed")
   elif aug.id == "discount":
    offer(game,150)
    game.command({"type":"buy","index":0})
    check(game.state.gold == 56 and not game.state.discount_ready,"Discount applies once to actual purchase")
   else:
    # Diversity is already present in the three-starter field; cost-1 lines also qualify.
    var winner = 1 if aug.id == "loss_gold" else 0
    game._settle(winner)
    other._settle(winner)
    check(game.state.gold > other.state.gold or game.state.xp > other.state.xp,"Economic augment has actual payout/XP: "+aug.id)
 # Exercise damage/cast procs with controlled living targets.
 for aug in augs.all:
  if not aug.has("mods") or aug.has("condition"):
   continue
  var sim = Battle.new()
  var f = sim.prepare([mon(143),mon(7,2,4)],[mon(143),mon(143,2,4)],1,[aug.id])
  f[0].hp = int(f[0].max_hp/2)
  f[1].hp = 100
  f[2].max_hp = 10000
  f[2].hp = 2000
  f[2].mana = 50
  f[0].attacks = 3
  var before = observable(f).duplicate(true)
  match aug.id:
   "lifesteal","spell_vamp":
    var hp = f[0].hp
    sim.hit(f[0],f[2],300,"attack" if aug.id == "lifesteal" else "ability")
    check(f[0].hp > hp,"Actual self healing: "+aug.id)
   "thorns":
    var hp = f[2].hp
    sim.hit(f[2],f[0],100,"attack")
    check(f[2].hp < hp,"Thorns returns damage")
   "execute","giant":
    var plain = sim.prepare([mon(143)],[mon(143)],1)
    plain[1].max_hp = 10000
    plain[1].hp = 2000
    check(sim.hit(f[0],f[2],100,"attack") > sim.hit(plain[0],plain[1],100,"attack"),"Conditional damage increase: "+aug.id)
   "splash","chain","poison_attack","stun_first","shred_attack","mana_burn":
    if aug.id == "stun_first": f[0].attacks = 1
    sim._attack_procs(f[0],f[2],f,30)
    check(before != observable(f),"Real attack proc: "+aug.id)
   "burn_spell":
    sim.hit(f[0],f[2],100,"ability")
    check(f[2].status.has("burn"),"Spell applies burn")
   "shield_cast","heal_cast","mana_cast":
    f[0].mana = f[0].max_mana
    sim.cast(f[0],f[2],f)
    var valid = f[0].shield > 0 if aug.id == "shield_cast" else (f[1].hp > 100 if aug.id == "heal_cast" else f[1].mana > 0)
    check(valid,"Actual cast proc: "+aug.id)
   "kill_haste":
    sim.hit(f[0],f[2],100000,"attack",true)
    check(f[0].status.has("haste"),"Kill gives haste")
   "revive":
    sim.hit(f[2],f[0],100000,"attack",true)
    check(f[0].hp > 0 and f[0].revived,"Revive prevents first death")
    sim.hit(f[2],f[0],100000,"attack",true)
    check(f[0].hp == 0,"Revive only once")
   "regen","cleanse_tick","patient","firsthit","thirdhit":
    var result = sim.run([mon(143,1,20,3)],[mon(143,1,20,3)],99,[aug.id])
    var plain = Battle.new().run([mon(143,1,20,3)],[mon(143,1,20,3)],99)
    if aug.id == "cleanse_tick":
     check(result.frames.any(func(frame): return frame.events.any(func(e): return e.kind == "cleanse" and e.spell == "Klarer Kopf")),"Periodic cleanse fires in simulation")
    else:
     var changed = result.frames.size() != plain.frames.size()
     for i in range(mini(result.frames.size(),plain.frames.size())):
      if observable(result.frames[i].units) != observable(plain.frames[i].units):
       changed = true
       break
     check(changed,"Timed/attack augment changes actual fight: "+aug.id)
 # Role mana/healing hooks use their live values.
 var sim = Battle.new()
 var f = sim.prepare([mon(7),mon(4,2),mon(63,3),mon(1,4)],[mon(143)],1,["tank_battery","attacker_battery","mage_battery","support_battery"])
 sim.hit(f[4],f[0],100,"attack",true)
 check(f[0].mana >= 28,"Tank augment adds hit mana")
 sim.gain_mana(f[1],int(Catalog.ROLES.Angreifer.attack)+int(sim.mod(f[1],"attack_mana")))
 check(f[1].mana == 31,"Attacker augment adds attack mana")
 var result = sim.run([mon(63,1,20)],[mon(143,1,20)],1,["mage_battery"])
 check(result.frames[10].units[0].mana >= 11,"Mage augment passive mana in real simulation")
 f[0].hp = 100
 sim.heal(f[3],f[0],100,"test")
 check(f[0].hp == 235,"Support augment adds 35 percent healing")
