extends RefCounted
# Authoritative command boundary: a future server owns this object per match.
const Catalog = preload("res://core/catalog.gd")
const Battle = preload("res://core/battle.gd")
const Augments = preload("res://core/augments.gd")
const Difficulty = preload("res://core/difficulty.gd")
const SCHEMA = 3
const BENCH_SIZE = 8
const MAX_ROUNDS = 30
const MAX_LEVEL = 10
const SHOP_ODDS = {1:[100,0,0,0,0],2:[80,20,0,0,0],3:[65,30,5,0,0],4:[50,35,15,0,0],5:[35,35,23,7,0],6:[25,30,25,17,3],7:[18,25,27,23,7],8:[12,20,28,25,15],9:[8,15,25,32,20],10:[5,10,25,40,20]}
var augments = Augments.new()
var catalog = Catalog.new()
var rng = RandomNumberGenerator.new()
var state: Dictionary = {}
var last_battle: Dictionary = {}
var command_log: Array = []

func _init(seed_value: int = 1337,difficulty: String = "Normal"):
 rng.seed = seed_value
 state = {"schema":SCHEMA, "rules":Catalog.VERSION, "seed":str(seed_value), "round":1, "lives":3, "attempt":1, "gold":14, "level":3, "xp":0, "wins":0, "streak":0, "phase":"planning", "next_uid":1, "units":[], "shop":[], "pool":{}, "locked":false, "revision":0, "enemy":[], "last_result":"Dein Abenteuer beginnt. Gewinne 20 Runden!", "outcome":"none"}
 for mon in catalog.roster:
  state.pool[str(int(mon.id))] = 18
 state.merge({"completed_lines":[],"augments":[],"augment_rounds":[],"augment_offers":[],"augment_at":0,"free_rolls":0,"discount_ready":false,"income":{},"battle_serial":0,"settled_serial":0})
 state.difficulty = difficulty if Difficulty.SETTINGS.has(difficulty) else "Normal"
 state.last_result = "Dein Abenteuer beginnt. Gewinne 30 Runden!"
 _roll()
 _make_enemy()
 # A small starting team makes the first battle immediately playable.
 for original in [1,4,7]:
  var id = Catalog.REPLACEMENTS.get(original,original)
  state.pool[str(id)] -= 1
  _add_unit(id, "board", state.units.size() + 2)

func board() -> Array:
 return state.units.filter(func(u): return u.zone == "board")

func command(action: Dictionary, expected_revision: int = -1) -> Dictionary:
 if expected_revision >= 0 and expected_revision != int(state.revision):
  return _error("Veralteter Spielstand. Bitte aktualisieren.")
 if typeof(action.get("type")) != TYPE_STRING:
  return _error("Ungültiger Befehl.")
 if state.phase != "planning":
  return _error("Die Partie ist beendet.")
 var result = {}
 match action.type:
  "buy":
   if not _integer(action.get("index")):
    return _error("Ungültiger Shop-Platz.")
   result = _buy(int(action.index))
  "move":
   if not _integer(action.get("uid")) or not _integer(action.get("slot")) or action.get("zone") not in ["board", "bench"]:
    return _error("Ungültige Position.")
   result = _move(int(action.uid), action.zone, int(action.slot))
  "sell":
   if not _integer(action.get("uid")):
    return _error("Ungültige Figur.")
   result = _sell(int(action.uid))
  "reroll":
   if state.gold < reroll_cost():
    return _error("Du brauchst 2 Gold.")
   state.gold -= reroll_cost()
   state.free_rolls = maxi(0,int(state.free_rolls)-1)
   _roll()
   result = _ok("Shop erneuert.")
  "xp":
   if state.level >= MAX_LEVEL:
    return _error("Maximales Level erreicht.")
   if state.gold < 4:
    return _error("Du brauchst 4 Gold.")
   state.gold -= 4
   var gained = 4+int(augments.value(state.augments,"xp_buy"))
   _gain_xp(gained)
   result = _ok("%d Erfahrung erhalten." % gained)
  "augment":
   if not _integer(action.get("index")) or action.index < 0 or action.index >= state.augment_offers.size():
    return _error("Ungültige Augment-Auswahl.")
   var id = state.augment_offers[int(action.index)]
   state.augments.append(id)
   state.augment_rounds.append(state.augment_at)
   state.augment_offers = []
   state.gold += int(augments.get_aug(id).get("gold",0))
   state.free_rolls = maxi(state.free_rolls,int(augments.get_aug(id).get("free_roll",0)))
   state.discount_ready = state.discount_ready or augments.get_aug(id).has("discount")
   _ensure_augments()
   result = _ok("Augment gewählt: "+augments.get_aug(id).name)
  "lock":
   state.locked = not state.locked
   result = _ok("Shop gesperrt." if state.locked else "Shop entsperrt.")
  "battle":
   _ensure_augments()
   if not state.augment_offers.is_empty():
    return _error("Wähle vor dem Kampf dein Augment.")
   if state.units.is_empty():
    return _error("Stelle mindestens ein Pokémon auf das Feld.")
   auto_fill()
   _fight()
   result = _ok(state.last_result)
  _:
   return _error("Unbekannter Befehl.")
 if result.ok:
  state.revision += 1
  command_log.append({"revision":state.revision, "action":action.duplicate(true)})
 return result

func _integer(value) -> bool:
 return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == floor(float(value)) and abs(float(value)) < 1000000

func _buy(index: int) -> Dictionary:
 if index < 0 or index >= state.shop.size() or state.shop[index] == 0:
  return _error("Dieses Angebot ist nicht verfügbar.")
 var species = int(state.shop[index])
 var mon = catalog.get_mon(species)
 if species in state.completed_lines:
  return _error("Diese Linie ist bereits vollständig entwickelt.")
 if state.gold < purchase_cost(species):
  return _error("Nicht genug Gold für " + str(mon.name) + ".")
 var slot = _free_slot("bench", BENCH_SIZE)
 var matching = state.units.filter(func(u): return int(u.species) == species and int(u.star) == 1)
 if slot < 0 and matching.size() < 2:
  return _error("Die Bank ist voll. Stelle eine Figur auf oder verkaufe sie.")
 state.gold -= purchase_cost(species)
 state.discount_ready = false
 state.shop[index] = 0
 _add_unit(species, "bench", slot)
 var upgraded = _merge()
 if upgraded:
  var forms = state.units.filter(func(u): return int(u.species) == species)
  forms.sort_custom(func(a,b): return a.star > b.star)
  return _ok("Entwicklung zu %s!" % catalog.display_name(forms[0]))
 return _ok(mon.name + " ist auf deiner Bank.")

func _add_unit(species: int, zone: String, slot: int):
 state.units.append({"uid":state.next_uid, "species":species, "star":1, "zone":zone, "slot":slot})
 state.next_uid += 1

func _merge() -> bool:
 var changed = false
 for star in [1, 2]:
  for mon in catalog.roster:
   var matches = state.units.filter(func(u): return int(u.species) == int(mon.id) and int(u.star) == star)
   while matches.size() >= 3:
    # Keep an existing board position; otherwise keep the earliest bench slot.
    matches.sort_custom(func(a,b):
     if a.zone != b.zone:
      return a.zone == "board"
     return int(a.uid) < int(b.uid))
    var keep = matches[0]
    keep.star += 1
    if keep.star == 3 and int(keep.species) not in state.completed_lines:
     state.completed_lines.append(int(keep.species))
    state.units.erase(matches[1])
    state.units.erase(matches[2])
    changed = true
    matches = state.units.filter(func(u): return int(u.species) == int(mon.id) and int(u.star) == star)
 if changed:
  _replace_completed()
 return changed

func _move(uid: int, zone: String, slot: int) -> Dictionary:
 var valid = validate_move(uid,zone,slot)
 if not valid.ok:
  return valid
 var unit = find_unit(uid)
 var occupant = at(zone, slot)
 var old_zone = unit.zone
 var old_slot = unit.slot
 unit.zone = zone
 unit.slot = slot
 if not occupant.is_empty() and occupant.uid != uid:
  occupant.zone = old_zone
  occupant.slot = old_slot
 return _ok("Aufstellung aktualisiert.")

func validate_move(uid: int, zone: String, slot: int) -> Dictionary:
 # Read-only validation shared by drag preview and authoritative commit.
 var unit = find_unit(uid)
 if state.phase != "planning" or zone not in ["board","bench"] or unit.is_empty() or slot < 0 or slot >= (21 if zone == "board" else BENCH_SIZE):
  return _error("Hier kann dieses Pokémon nicht platziert werden.")
 if zone == "board" and unit.zone != "board" and at(zone,slot).is_empty() and board().size() >= int(state.level):
  return _error("Team voll: Tausche mit einer Figur oder erhöhe dein Level.")
 return _ok("Tauschen" if not at(zone,slot).is_empty() else "Platzieren")

func _sell(uid: int) -> Dictionary:
 var unit = find_unit(uid)
 if unit.is_empty():
  return _error("Diese Figur gibt es nicht.")
 var copies = int(pow(3, int(unit.star) - 1))
 var value = int(catalog.get_mon(int(unit.species)).cost) * copies
 state.gold += value
 state.pool[str(int(unit.species))] += copies
 state.units.erase(unit)
 return _ok("Verkauft für %d Gold." % value)

func find_unit(uid: int) -> Dictionary:
 for unit in state.units:
  if int(unit.uid) == uid:
   return unit
 return {}

func at(zone: String, slot: int) -> Dictionary:
 for unit in state.units:
  if unit.zone == zone and int(unit.slot) == slot:
   return unit
 return {}

func _free_slot(zone: String, limit: int) -> int:
 for slot in range(limit):
  if at(zone, slot).is_empty():
   return slot
 return -1

func _roll():
 for id in state.shop:
  if int(id) != 0:
   state.pool[str(int(id))] += 1
 state.shop = []
 for _i in range(5):
  state.shop.append(_draw_offer())

func _draw_offer() -> int:
 var buckets = [[],[],[],[],[]]
 for mon in catalog.roster:
  if int(mon.id) in state.completed_lines:
   continue
  for _copy in range(int(state.pool[str(int(mon.id))])):
   buckets[int(mon.cost)-1].append(int(mon.id))
 var weights = SHOP_ODDS[int(state.level)].duplicate()
 for tier in range(5):
  if buckets[tier].is_empty():
   weights[tier] = 0
 var total = weights.reduce(func(a,b): return a+b,0)
 # If every normally available tier is exhausted, use any eligible remaining tier.
 if total == 0:
  weights = buckets.map(func(b): return 0 if b.is_empty() else 1)
  total = weights.reduce(func(a,b): return a+b,0)
 if total == 0:
  return 0 # Only possible when all 70 lines have been completed/exhausted.
 var roll = rng.randi_range(0,total-1)
 for tier in range(5):
  if roll < weights[tier]:
   var id = buckets[tier][rng.randi_range(0,buckets[tier].size()-1)]
   state.pool[str(id)] -= 1
   return id
  roll -= weights[tier]
 return 0

func _replace_completed():
 for i in range(state.shop.size()):
  if int(state.shop[i]) in state.completed_lines:
   state.pool[str(int(state.shop[i]))] += 1
   state.shop[i] = _draw_offer()

func reroll_cost() -> int:
 return 0 if state.free_rolls > 0 else 2

func income_forecast() -> Dictionary:
 var base = 6+int((int(state.round)-1)/5)+interest()
 var extras = int(augments.value(state.augments,"saver")) if state.gold >= 50 else 0
 if catalog.synergies(board()).size() >= 4: extras += int(augments.value(state.augments,"dividend"))
 var cheap = {}
 for u in board():
  if catalog.get_mon(u.species).cost == 1: cheap[u.species] = true
 if cheap.size() >= 3: extras += int(augments.value(state.augments,"underdog"))
 return {"win":base+extras+2+mini(3,int((maxi(0,state.streak)+1)/3))+int(augments.value(state.augments,"win_gold")),"loss":base+extras+3+int(augments.value(state.augments,"loss_gold")),"interest":interest()}

func purchase_cost(id: int) -> int:
 return maxi(1,int(catalog.get_mon(id).cost)-(1 if state.discount_ready else 0))

func auto_fill():
 var bench = state.units.filter(func(u): return u.zone == "bench")
 bench.sort_custom(func(a,b): return a.slot < b.slot)
 for unit in bench:
  if board().size() >= state.level:
   break
  var slot = _free_slot("board",21)
  if slot < 0:
   break
  unit.zone = "board"
  unit.slot = slot

func _ensure_augments():
 if not state.augment_offers.is_empty() or state.phase != "planning":
  return
 for milestone in [5,12,20]:
  if state.round >= milestone and milestone not in state.augment_rounds:
   var eligible = augments.all.filter(func(a): return a.id not in state.augments and augments.usable(a,state))
   state.augment_at = milestone
   for _i in range(3):
    var weights = eligible.map(func(a): return 1.0+minf(4.0,float(catalog.synergies(board()).get(a.get("emblem",""),0))))
    var total = weights.reduce(func(a,b): return a+b,0.0)
    var roll = rng.randf()*total
    var index = 0
    while index < weights.size()-1 and roll >= weights[index]:
     roll -= weights[index]
     index += 1
    state.augment_offers.append(eligible[index].id)
    eligible.remove_at(index)
   return

func xp_needed() -> int:
 return [0,2,3,4,8,14,22,32,48,64,0][int(state.level)]

func _gain_xp(amount: int):
 state.xp += amount
 while state.level < MAX_LEVEL and state.xp >= xp_needed():
  state.xp -= xp_needed()
  state.level += 1
 if state.level == MAX_LEVEL:
  state.xp = 0

func _make_enemy():
 state.enemy = Difficulty.team(catalog,int(state.seed),int(state.round),state.difficulty)

func _fight():
 var round_number = int(state.round)
 var before = snapshot()
 state.battle_serial += 1
 last_battle = Battle.new().run(board(), state.enemy, int(state.seed) + round_number * 104729,state.augments)
 last_battle["round"] = round_number
 last_battle["before"] = before
 _settle(last_battle.winner,state.battle_serial)

func _settle(winner: int,serial: int = -1):
 if state.phase == "finished":
  return
 if serial == -1:
  state.battle_serial += 1
  serial = state.battle_serial
 if serial <= state.settled_serial:
  return
 state.settled_serial = serial
 var round_number = int(state.round)
 var before_gold = int(state.gold)
 var breakdown = {"before":before_gold,"base":6,"progress":int((round_number-1)/5),"interest":interest(),"result":0,"augments":0,"total":0,"serial":serial}
 if winner == 0:
  state.wins += 1
  state.round += 1
  state.attempt = 1
  state.streak = maxi(1, int(state.streak) + 1)
  breakdown.result = 2 + mini(3, int(state.streak / 3))
  state.outcome = "win"
 elif winner == 1:
  state.lives -= 1
  state.attempt += 1
  state.streak = 0
  breakdown.result = 3
  state.outcome = "loss"
 else:
  breakdown.base = 0
  breakdown.progress = 0
  breakdown.interest = 0
  state.attempt += 1
  state.outcome = "draw"
 var verdict = "SIEG" if winner == 0 else ("UNENTSCHIEDEN" if winner == -1 else "NIEDERLAGE")
 if winner != -1:
  breakdown.augments = int(augments.value(state.augments,"win_gold" if winner == 0 else "loss_gold"))
  if before_gold >= 50:
   breakdown.augments += int(augments.value(state.augments,"saver"))
  if catalog.synergies(board()).size() >= 4:
   breakdown.augments += int(augments.value(state.augments,"dividend"))
  var cheap = {}
  for unit in board():
   if catalog.get_mon(unit.species).cost == 1:
    cheap[unit.species] = true
  if cheap.size() >= 3:
   breakdown.augments += int(augments.value(state.augments,"underdog"))
 var income = breakdown.base+breakdown.progress+breakdown.interest+breakdown.result+breakdown.augments
 breakdown.total = income
 state.income = breakdown
 state.last_result = "Runde %d: %s. +%d Gold.%s" % [round_number,verdict,income," 1 Leben verloren; gleiche Runde." if winner == 1 else ""]
 state.gold += income
 if state.lives == 0 or state.round > MAX_ROUNDS:
  state.phase = "finished"
  return
 if winner != -1:
  _gain_xp((3 if winner == 0 else 2)+int(augments.value(state.augments,"xp_round")))
  state.free_rolls = int(augments.value(state.augments,"free_roll"))
  state.discount_ready = augments.value(state.augments,"discount") > 0
 var floor_level = mini(MAX_LEVEL,3+int((int(state.round)-1)/4))
 if state.level < floor_level:
  state.level = floor_level
  _gain_xp(0)
 if not state.locked and winner != -1:
  _roll()
 _make_enemy()
 _ensure_augments()

func interest() -> int:
 return mini(5,int(state.gold/10))

func snapshot() -> Dictionary:
 var data = state.duplicate(true)
 data["rng_state"] = str(rng.state)
 return data

func _ok(message: String) -> Dictionary:
 return {"ok":true, "message":message}

func _error(message: String) -> Dictionary:
 return {"ok":false, "message":message}
