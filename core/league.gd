extends RefCounted
# Owned exclusively by the host worker. Clients submit commands, never snapshots/results.
const MatchModel = preload("res://core/match.gd")
const Battle = preload("res://core/battle.gd")
var players: Dictionary = {}
var order: Array = []
var phase = "planning"
var stage = 1
var seed_value = 1
var deadline = 0.0
var champion = ""
var pairs: Array = []

func initialize(members: Array, seed_number: int):
 seed_value = seed_number
 for index in range(members.size()):
  var member = members[index]
  var model = MatchModel.new(seed_value + index * 7919)
  players[member.id] = {"model":model,"name":member.name,"ready":false,"ack":false,"recipe":{},"serial":0,"seq":-1,"result":{"ok":true,"message":"Partie gestartet."}}
  order.append(member.id)
 _planning()

func living() -> Array:
 return order.filter(func(id): return players[id].model.state.lives > 0)

func _planning():
 phase = "planning"
 deadline = Time.get_unix_time_from_system() + 90
 var active = living()
 if active.size() <= 1:
  phase = "finished"
  champion = str(active[0]) if active.size() == 1 else ""
  return
 # Rotate before pairing: odd-player byes move between players each stage.
 for i in range((stage - 1) % active.size()): active.push_back(active.pop_front())
 pairs = []
 for i in range(0,active.size(),2):
  pairs.append([active[i],active[i+1] if i+1 < active.size() else ""])
 for id in order:
  players[id].ready = false
  players[id].ack = false
  players[id].model.state.enemy = []

func advance(now: float):
 if phase == "planning" and now >= deadline:
  for id in living():
   var model = players[id].model
   while not model.state.augment_offers.is_empty(): model.command({"type":"augment","index":0})
   model.auto_fill()
   players[id].ready = true
  _fight()
 elif phase == "battle" and (now >= deadline or living().all(func(id): return players[id].ack)):
  stage += 1
  _planning()

func command(id: String, action: Dictionary, revision: int, seq: int) -> Dictionary:
 var player = players[id]
 if seq == int(player.seq): return player.result
 if seq < int(player.seq): return {"ok":false,"message":"Veraltete Anfrage verworfen."}
 var result = {"ok":false,"message":"Auf die nächste Planungsphase warten."}
 if phase == "planning" and player.model.state.lives > 0 and not player.ready:
  if action.get("type","") in ["buy","move","sell","reroll","xp","augment","lock"]:
   result = player.model.command(action,revision)
  else: result = {"ok":false,"message":"Dieser Befehl ist im Multiplayer nicht erlaubt."}
 player.seq = seq
 player.result = result
 return result

func ready(id: String, expected_stage: int) -> Dictionary:
 if phase != "planning" or expected_stage != stage or players[id].model.state.lives <= 0:
  return {"ok":false,"message":"Diese Kampfvorbereitung ist nicht mehr aktuell."}
 var player = players[id]
 if not player.model.state.augment_offers.is_empty(): return {"ok":false,"message":"Bitte zuerst ein Augment wählen."}
 player.model.auto_fill()
 if player.model.board().is_empty(): return {"ok":false,"message":"Mindestens ein Pokémon aufstellen."}
 player.ready = true
 if living().all(func(key): return players[key].ready): _fight()
 return {"ok":true,"message":"Bereit. Warte auf die anderen Trainer."}

func acknowledge(id: String, serial: int):
 if phase == "battle" and serial == int(players[id].serial): players[id].ack = true
 advance(Time.get_unix_time_from_system())

func drop(id: String):
 if not players.has(id): return
 players[id].model.state.lives = 0
 players[id].model.state.phase = "finished"
 players[id].ready = true
 players[id].ack = true
 if living().size() <= 1:
  phase = "finished"
  champion = str(living()[0]) if living().size() == 1 else ""
 elif phase == "planning":
  _planning()

func _fight():
 phase = "battle"
 deadline = Time.get_unix_time_from_system() + 150
 for pair in pairs:
  var left = players[pair[0]]
  if pair[1] == "":
   left.ack = true
   left.model.state.gold += 6
   left.model._gain_xp(2)
   left.model.state.last_result = "Freilos: +6 Gold und +2 Erfahrung. Kein Leben verloren."
   left.model.state.revision += 1
   continue
  var right = players[pair[1]]
  var recipe = {"allies":left.model.board().duplicate(true),"enemies":right.model.board().duplicate(true),"augments":left.model.state.augments.duplicate(),"enemy_augments":right.model.state.augments.duplicate(),"seed":seed_value+stage*104729+pairs.find(pair)*97,"stage":stage}
  var battle = Battle.new().run(recipe.allies,recipe.enemies,recipe.seed,recipe.augments,recipe.enemy_augments)
  recipe.winner = battle.winner
  for side in range(2):
   var player = left if side == 0 else right
   var model = player.model
   player.serial += 1
   player.recipe = recipe.duplicate(true)
   player.recipe.side = side
   player.recipe.serial = player.serial
   player.recipe.before = model.snapshot()
   # A timeout/draw costs both players one life, preventing endless matches.
   model._settle(0 if battle.winner == side else 1)
   model.state.revision += 1
   model.state.enemy = []
   if battle.winner == -1: model.state.last_result = "Unentschieden: Beide Trainer verlieren ein Leben."
   player.ack = false

func view(id: String, seen_serial: int = -1) -> Dictionary:
 var player = players[id]
 var result = {"phase":phase,"stage":stage,"deadline":deadline,"champion":champion,"ready":player.ready,"serial":player.serial,"state":player.model.snapshot(),"scores":[]}
 for key in order:
  var p = players[key]
  result.scores.append({"id":key,"name":p.name,"lives":p.model.state.lives,"wins":p.model.state.wins,"ready":p.ready,"ack":p.ack})
 if int(player.serial) > seen_serial and not player.recipe.is_empty(): result.recipe = player.recipe.duplicate(true)
 return result

static func replay(recipe: Dictionary) -> Dictionary:
 var battle = Battle.new().run(recipe.allies,recipe.enemies,int(recipe.seed),recipe.augments,recipe.enemy_augments)
 if int(recipe.side) == 1:
  mirror(battle.frames)
  if battle.winner != -1: battle.winner = 1-int(battle.winner)
 battle.before = recipe.before
 battle.round = recipe.before.round
 return battle

static func mirror(value):
 if value is Array:
  for item in value: mirror(item)
 elif value is Dictionary:
  for key in value:
   if key in ["y","sy","ty"] and (value[key] is int or value[key] is float): value[key] = 5-value[key]
   elif key == "side": value[key] = 1-int(value[key])
   else: mirror(value[key])
