extends RefCounted
# Per-battle trait controller. All mutable state lives in this instance or fighters.
var rng = RandomNumberGenerator.new()
var tick = 0
var fields: Array = []
var dead_seen = {}
var next_uid = 3000000

func n(u: Dictionary,t: String) -> int:
 return int(u.get("traits",{}).get(t,0))
func alive(team: Array,side: int) -> Array:
 return team.filter(func(u): return u.hp > 0 and u.side == side)
func init(b,team: Array,seed_value: int):
 rng.seed = seed_value
 tick = 0
 next_uid = 3000000
 fields.clear()
 dead_seen.clear()
 for u in team:
  var counts = u.trait_counts
  var natural = b.catalog.synergies(team.filter(func(v): return v.side == u.side))
  u.traits = {}
  for t in b.catalog.combat_types(u): u.traits[t] = mini(8,int(counts.get(t,0))/2*2)
  u.growth = 0
  u.heat = 0
  u.spirit = 2 if n(u,"Kampf") >= 2 else 0
  u.damage_done = 0
  u.phantom_used = false
  u.phantom_revived = false
  u.steel_charges = 0
  u.steel_ready = 0
  u.rock_broken = false
  u.rock_timer = -1
  u.rock_regenerated = false
  u.dragon_deaths = 0
  u.blessed = false
  u.summoned = false
  u.frost = 0
  u.frost_guard = 0
  u.toxin = 0
  u.toxin_until = 0
  u.toxin_potent = false
  u.toxin_source = -1
  u.dark_priority = "Schadensspitze" if n(u,"Unlicht") >= 8 else "Niedrigste LP"
  # Copy only finite 2er effects; originals are counted once, copies never feed counters.
  if n(u,"Normal") >= 6:
   var choices = counts.keys().filter(func(t): return t != "Normal" and int(counts[t]) >= 2)
   choices.sort_custom(func(a,c): return counts[a] > counts[c] or counts[a] == counts[c] and a < c)
   var normals = team.filter(func(v): return v.side == u.side and "Normal" in b.catalog.combat_types(v))
   normals.sort_custom(func(a,c): return a.uid < c.uid)
   if not choices.is_empty() and normals[0].uid == u.uid: u.traits[choices[0]] = maxi(n(u,choices[0]),2)
  if n(u,"Normal") >= 8:
   for t in natural:
    if t != "Normal" and natural[t] > 0: u.traits[t] = maxi(n(u,t),2)
  if n(u,"Normal") >= 2:
   var diversity = natural.keys().filter(func(t): return t != "Normal" and natural[t] > 0).size()
   var scale = 1.05+diversity*(0.04 if n(u,"Normal") >= 4 else 0.02)
   u.max_hp = int(u.max_hp*scale); u.hp = u.max_hp
   u.attack = int(u.attack*scale); u.power = int(u.power*scale); u.armor = int(u.armor*scale)
  if n(u,"Stahl") >= 2: u.armor += 20
  if n(u,"Gestein") >= 4:
   u.rock_shield = int(u.max_hp*0.2)
   u.shield += u.rock_shield
  else: u.rock_shield = 0
 for side in [0,1]:
  var friends = alive(team,side)
  var fairy = 0
  for u in friends: fairy = maxi(fairy,n(u,"Fee"))
  friends.sort_custom(func(a,c): return a.hp < c.hp or a.hp == c.hp and a.uid < c.uid)
  for i in range(friends.size() if fairy >= 6 else (mini(2,friends.size()) if fairy >= 4 else mini(1,friends.size()) if fairy >= 2 else 0)):
   friends[i].blessed = true
 for u in team:
  if n(u,"Flug") >= 6: jump(b,u,team,false)

func speed(u: Dictionary) -> float:
 var value = 1.0
 if n(u,"Feuer") >= 2: value += 0.1
 if n(u,"Käfer") >= 2: value += 0.1
 if u.get("blessed",false): value += 0.15
 if u.get("growth",0) >= 20 and n(u,"Pflanze") >= 8: value += 0.3
 if u.get("dragon_blood",false): value += 0.5
 if u.get("water_buff",false): value += 0.2
 if u.get("pheromone_until",0) > tick: value += 0.25
 if u.get("overheat_until",0) > tick: value *= 0.7
 if u.get("frost_slow",0) > tick: value *= 0.8
 if u.get("rift_until",0) > tick: value *= 0.7
 return value
func cost(u: Dictionary) -> int:
 return maxi(1,int(u.max_mana*(0.8 if u.get("growth",0) >= 20 and n(u,"Pflanze") >= 8 else 1.0)))
func threshold(u: Dictionary) -> int:
 return int(ceil(cost(u)*(2.0 if n(u,"Psycho") >= 8 else 1.5 if n(u,"Psycho") >= 6 else 1.25 if n(u,"Psycho") >= 4 else 1.0)))
func power(u: Dictionary) -> float:
 return 1.0+u.get("growth",0)*0.02+(0.5 if u.get("growth",0) >= 20 and n(u,"Pflanze") >= 8 else 0.0)
func reach(b,u: Dictionary) -> int:
 return (int(b.catalog.get_mon(u.species).range)+(1 if n(u,"Flug") >= 2 else 0))*(2 if n(u,"Psycho") >= 8 else 1)
func in_field(u: Dictionary,kind: String) -> bool:
 for f in fields:
  if f.kind == kind and f.until > tick and (kind == "water" or f.side != u.side) and Vector2i(u.x,u.y) in f.tiles: return true
 return false
func field(b,u: Dictionary,target: Dictionary,kind: String,duration: int,radius: int):
 var tiles = []
 for y in range(6):
  for x in range(7):
   if ((y >= 3 if u.side == 0 else y < 3) if kind == "water" and n(u,"Wasser") >= 8 else absi(x-target.x)+absi(y-target.y) <= radius):
    tiles.append(Vector2i(x,y))
 fields.append({"kind":kind,"side":u.side,"tiles":tiles,"until":tick+duration,"tier":n(u,"Wasser")})
 b._event("field",u,target,duration,kind)

func step(b,team: Array,now: int):
 tick = now
 fields = fields.filter(func(f): return f.until > tick)
 for u in team.duplicate():
  if u.hp <= 0: continue
  u.cast_threshold = threshold(u)
  u.water_buff = false
  for f in fields:
   if f.kind == "water" and f.side == u.side and f.tier >= 6 and Vector2i(u.x,u.y) in f.tiles: u.water_buff = true
  if in_field(u,"rift"): u.rift_until = tick+2
  if u.get("summoned",false) and tick >= u.get("expires",999999):
   if u.get("can_transform",false) and rng.randf() < 0.5:
    u.can_transform = false
    u.summon_stage = "pokemon"
    u.expires = tick+150
    var bugs = b.catalog.roster.filter(func(m): return "Käfer" in b.catalog.combat_types({"species":m.id,"star":1}))
    var mon = bugs[rng.randi_range(0,bugs.size()-1)]
    u.species = int(mon.id);u.star = 1
    u.max_hp = int(mon.hp*0.35);u.hp = u.max_hp;u.attack = int(mon.attack*0.35);u.power = int(mon.power*0.35)
    b._event("status",u,u,0,"Metamorphose")
   else:
    u.hp = 0;b._event("defeat",u,u,0,"Larve erlischt")
   continue
  if tick % 10 == 0:
   if "Pflanze" in b.catalog.combat_types(u) and in_field(u,"water"): b.heal(u,u,int(u.max_hp*0.02),"Bewässerung")
   if u.toxin > 0 and u.toxin_until > tick:
    var source = team.filter(func(v): return v.uid == u.toxin_source)
    b.hit(source[0] if not source.is_empty() else u,u,int(u.max_hp*(0.08 if u.toxin_potent else 0.005*u.toxin)),"Toxin",true,"Gift",true)
   elif u.toxin_until <= tick: u.toxin = 0;u.toxin_potent = false
  if u.hp <= 0: continue
  if n(u,"Pflanze") >= 2 and tick % 50 == 0:
   var old = u.growth
   u.growth = mini(20 if n(u,"Pflanze") >= 6 else 5,u.growth+1)
   if old < 5 and u.growth == 5 and n(u,"Pflanze") >= 4: b.heal(u,u,int(u.max_hp*0.15),"Wachstum")
   if old < 20 and u.growth == 20 and n(u,"Pflanze") >= 8: b._event("status",u,u,0,"Erblüht")
  if n(u,"Stahl") >= 4 and tick % 50 == 0: u.armor += 5
  if u.get("phantom_until",0) == tick:
   if n(u,"Geist") >= 6: b.heal(u,u,int(u.max_hp*0.2),"Phantom")
   b._event("status",u,u,0,"Rückkehr")
  if n(u,"Gestein") >= 8 and u.rock_timer == tick and not u.rock_regenerated:
   u.rock_regenerated = true;u.rock_broken = false;u.rock_shield = int(u.max_hp*0.2);u.shield += u.rock_shield
   b._event("shield",u,u,u.rock_shield,"Bollwerk")
  if n(u,"Drache") >= 8:
   u.dragon_blood = alive(team,u.side).filter(func(v): return not v.get("summoned",false)).all(func(v): return "Drache" in b.catalog.combat_types(v))
  if n(u,"Boden") >= 4 and tick % 80 == 0:
   for enemy in alive(team,1-u.side):
    if b._distance(u,enemy) <= 2:
     if n(u,"Boden") >= 6:
      b.hit(u,enemy,int(u.power*0.5),"Erdbeben",false,"Boden",true)
      b.apply_status(u,enemy,"stun",10)
      enemy.erase("pending_action")
     else: b.apply_status(u,enemy,"slow",20)
   if n(u,"Boden") >= 8: field(b,u,u,"rift",40,2)
   b._event("cast",u,u,0,"Erdbeben")

func damage_factor(b,source: Dictionary,target: Dictionary,spell: String) -> float:
 if target.get("phantom_until",0) > tick: return 0.0
 var v = 1.0
 if spell == "attack":
  v *= 1+source.get("spirit",0)*0.02
  if n(source,"Unlicht") >= 2 and target.hp < target.max_hp*0.5 and rng.randf()<0.25:
   v *= 2.0 if n(source,"Unlicht") >= 4 else 1.5
  if source.get("heat_strike",false): v *= 1.5
 else:
  if n(source,"Drache") >= 2: v *= 1.15
 v *= 1+source.get("dragon_deaths",0)*0.1
 if source.get("dragon_blood",false): v *= 1.5
 if target.get("dragon_blood",false): v *= 0.7
 if target.get("steel_until",0) > tick: v *= 0.5
 if target.get("water_buff",false): v *= 0.85
 if n(target,"Gestein") >= 2 and (source.y <= target.y if target.side == 0 else source.y >= target.y): v *= 0.85
 if target.get("frozen_until",0) > tick and target.get("frost_vulnerable",false): v *= 1.2
 return v
func before_attack(u: Dictionary):
 u.heat_strike = n(u,"Feuer") >= 6 and u.get("heat",0) >= 5
func after_attack(b,u: Dictionary,target: Dictionary,team: Array,lost: int):
 if lost <= 0: return
 if n(u,"Feuer") >= 4 and u.attacks%5 == 0: u.heat = mini(5,u.heat+1)
 if u.get("heat_strike",false):
  u.heat = 0;u.heat_strike = false;u.overheat_until = tick+30
  for enemy in alive(team,1-u.side):
   if b._distance(target,enemy) <= 1:
    b.hit(u,enemy,int(u.attack*0.5),"Überhitzen",false,"Feuer",true)
    if n(u,"Feuer") >= 8: b.apply_status(u,enemy,"burn",50,int(enemy.max_hp*0.05))
  b._event("cast",u,target,0,"Überhitzen")
 if n(u,"Eis") >= 2: frost(b,u,target,team,1)
 if n(u,"Gift") >= 2: toxin(u,target)
 if n(u,"Boden") >= 2 and rng.randf()<0.1: b.apply_status(u,target,"slow",15)
func frost(b,u: Dictionary,target: Dictionary,team: Array,amount: int):
 if target.frost_guard > tick or target.get("unstoppable_until",0)>tick: return
 target.frost += amount
 if target.frost >= 3: target.frost_slow = tick+30
 if target.frost >= 5 and n(u,"Eis") >= 4:
  target.frost = 0;target.frost_guard = tick+35;target.frozen_until = tick+15;target.frost_vulnerable = n(u,"Eis") >= 6
  b.apply_status(u,target,"stun",15)
  if n(u,"Eis") >= 8:
   for enemy in alive(team,1-u.side):
    if enemy.uid != target.uid and b._distance(enemy,target)<=1 and enemy.frost_guard <= tick: enemy.frost = mini(4,enemy.frost+2)
 elif n(u,"Eis") < 4 and target.frost >= 3: target.frost = 0
func toxin(u: Dictionary,target: Dictionary):
 if target.hp <= 0: return
 target.toxin = mini(10 if n(u,"Gift") >= 6 else 1,target.toxin+1)
 target.toxin_until = tick+50;target.toxin_source = u.uid
 target.toxin_potent = target.toxin_potent or (n(u,"Gift") >= 8 and target.toxin >= 10)
 target.toxin_reduction = 0.5 if target.toxin_potent else 0.4 if n(u,"Gift") >= 4 else 0.0
func after_damage(b,u: Dictionary,target: Dictionary,team: Array,lost: int,spell: String,secondary: bool):
 if lost > 0:
  u.damage_done = u.get("damage_done",0)+lost
  if not secondary and u.uid != target.uid:
   if n(u,"Kampf") >= 2:
    var old_spirit = u.spirit
    u.spirit = mini(10,u.spirit+1)
    if old_spirit < 10 and u.spirit == 10 and n(u,"Kampf") >= 6 and u.get("unstoppable_until",0) <= tick:
     u.unstoppable_until = tick+40;b._event("status",u,u,40,"Unaufhaltsam")
   var steal = u.get("growth",0)*0.01+(0.3 if u.get("unstoppable_until",0)>tick else 0.0)
   if steal>0: b.heal(u,u,int(lost*steal),"Kampfheilung")
   if spell != "attack" and n(u,"Gift") >= 2: toxin(u,target)
 if target.hp > 0:
  if n(target,"Geist") >= 2 and target.hp <= target.max_hp*0.5 and not target.phantom_used:
   target.phantom_used = true;target.phantom_until = tick+15
   if n(target,"Geist") >= 4: jump(b,target,team,false)
   b._event("status",target,target,15,"Phantom")
  if n(target,"Stahl") >= 6 and target.hp <= target.max_hp*0.3 and tick >= target.steel_ready and target.steel_charges < (2 if n(target,"Stahl") >= 8 else 1):
   target.steel_charges += 1;target.steel_until = tick+40;target.steel_ready = tick+60
   b._event("status",target,target,40,"Unzerbrechlich")
 if n(target,"Gestein") >= 4 and target.get("rock_shield",0) <= 0 and not target.rock_broken:
  target.rock_broken = true;target.rock_timer = tick+80
  if n(target,"Gestein") >= 6:
   for enemy in alive(team,1-target.side):
    if b._distance(target,enemy)<=1: b.hit(target,enemy,int(enemy.max_hp*0.1),"Splittersturm",true,"Gestein",true)
 if target.hp > 0 or dead_seen.has(target.uid): return
 dead_seen[target.uid] = true
 if u.uid != target.uid:
  if n(u,"Unlicht") >= 6: b.gain_mana(u,40)
  if n(u,"Elektro") >= 2 and spell != "attack" and not secondary: b.gain_mana(u,30)
  if n(u,"Kampf") >= 4:
   u.spirit = 10 if n(u,"Kampf") >= 8 else 5
   if n(u,"Kampf") >= 8: u.unstoppable_until = maxi(tick+40,u.get("unstoppable_until",0)+30)
 if not target.get("summoned",false):
  for friend in alive(team,target.side):
   if n(friend,"Drache") >= 4: friend.dragon_deaths = mini(10 if n(friend,"Drache") >= 6 else 1,friend.dragon_deaths+1)
  if n(target,"Käfer") >= 4: summon(b,target,team)
 if target.blessed and target.trait_counts.get("Fee",0) >= 8:
  var friends = alive(team,target.side).filter(func(v): return not v.blessed)
  friends.sort_custom(b._weakest)
  if not friends.is_empty(): friends[0].blessed = true
 if n(target,"Geist") >= 8 and not target.phantom_revived:
  target.phantom_revived = true;target.hp = int(target.max_hp*0.3);target.phantom_until = tick+10
  b._event("heal",target,target,target.hp,"Zweite Lebensphase")

func summon(b,source: Dictionary,team: Array):
 var occupied = b._occupied(source,team)
 if occupied.has(source.y*7+source.x): return
 var larva = source.duplicate(true)
 next_uid += 1;larva.uid = next_uid;larva.star = 1;larva.summoned = true;larva.traits = {};larva.trait_counts = {};larva.status = {};larva.mods = {}
 larva.max_hp = maxi(1,int(source.max_hp*0.1));larva.hp = larva.max_hp;larva.attack = maxi(1,int(source.attack*0.15));larva.power = 0;larva.mana = 0;larva.max_mana = 9999;larva.shield = 0;larva.blessed = false;larva.rock_shield = 0
 larva.summon_stage = "larva"
 larva.expires = tick+50;larva.can_transform = n(source,"Käfer") >= 6
 larva.growth = 0;larva.spirit = 0;larva.dragon_deaths = 0;larva.toxin = 0;larva.toxin_potent = false
 team.append(larva)
 b._event("status",larva,larva,50,"Larve")
 if n(source,"Käfer") >= 8:
  for friend in alive(team,source.side):
   if "Käfer" in b.catalog.combat_types(friend): friend.pheromone_until = tick+50
  b._event("field",source,source,50,"Pheromone")
func jump(b,u: Dictionary,team: Array,value_target: bool):
 var enemies = alive(team,1-u.side)
 if enemies.is_empty(): return
 enemies.sort_custom(func(a,c): return a.get("damage_done",0)>c.get("damage_done",0) if value_target else (a.y<c.y if u.side == 0 else a.y>c.y))
 var target = enemies[0]
 var occupied = b._occupied(u,team)
 var options = []
 for y in range(6):
  for x in range(7):
   if not occupied.has(y*7+x) and absi(x-target.x)+absi(y-target.y)<=reach(b,u): options.append(Vector2i(x,y))
 if options.is_empty(): return
 options.sort_custom(func(a,c): return a.distance_squared_to(Vector2i(target.x,target.y))<c.distance_squared_to(Vector2i(target.x,target.y)))
 b._relocate(u,options[0].x,options[0].y)
func after_cast(b,u: Dictionary,target: Dictionary,team: Array):
 if n(u,"Wasser") >= 2: field(b,u,target,"water",60 if n(u,"Wasser") >= 4 else 40,2 if n(u,"Wasser") >= 4 else 1)
 var electric = n(u,"Elektro") >= 2 and rng.randf()<0.2
 var water_jump = "Elektro" in b.catalog.combat_types(u) and in_field(target,"water")
 if electric or water_jump:
  var amount = int(u.power*0.4)
  var used = []
  for i in range(((3 if n(u,"Elektro")>=4 else 1) if electric else 0) + (1 if water_jump else 0)):
   var enemies = alive(team,1-u.side).filter(func(v): return n(u,"Elektro") >= 8 or v.uid not in used)
   if enemies.is_empty(): break
   var enemy = enemies[rng.randi_range(0,enemies.size()-1)];used.append(enemy.uid)
   b.hit(u,enemy,amount,"Kettenladung",false,"Elektro",true)
   b._event("cast",u,enemy,0,"Kettenladung")
   if n(u,"Elektro")>=6: amount = int(amount*1.25)
 if n(u,"Flug")>=8: jump(b,u,team,true)
