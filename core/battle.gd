extends RefCounted
# Headless, seeded, fixed-step combat. Presentation consumes immutable event frames.
const Catalog = preload("res://core/catalog.gd")
const Augments = preload("res://core/augments.gd")
const MAX_TICKS = 1200
const TICKS_PER_SECOND = 10
const NEGATIVE = ["poison","burn","stun","slow","break","taunt"]
var catalog = Catalog.new()
var events: Array = []
var traits = preload("res://core/traits.gd").new()
var combatants: Array = []
var augment_catalog = Augments.new()

func prepare(allies: Array, enemies: Array, seed_value: int,augments: Array = []) -> Array:
 var rng = RandomNumberGenerator.new()
 rng.seed = seed_value
 var fighters = []
 for side in range(2):
  var team = allies if side == 0 else enemies
  var ids = augments if side == 0 else []
  var synergy = augment_catalog.counts(team,ids)
  for source in team:
   var mon = catalog.get_mon(int(source.species))
   var stats = catalog.stats(source)
   var unit = source.duplicate(true)
   unit.side = side
   unit.uid = side * 1000000 + int(source.uid)
   unit.x = int(source.slot) % 7
   unit.y = 3 + int(int(source.slot)/7) if side == 0 else 2-int(int(source.slot)/7)
   unit.hp = stats.hp
   unit.max_hp = stats.hp
   unit.attack = stats.attack
   unit.armor = stats.armor
   unit.power = stats.power
   unit.interval = int(mon.interval)
   unit.cooldown = rng.randi_range(0,3)
   unit.role = mon.role
   unit.mana = 0
   unit.max_mana = int(mon.mana)
   unit.shield = 0
   unit.status = {}
   unit.dot_power = {}
   unit.taunter = -1
   unit.poisonous = false
   unit.mods = augment_catalog.modifiers(source,team,ids)
   unit.trait_counts = synergy.duplicate()
   var synergy_mods = {}
   for key in synergy_mods:
    unit.mods[key] = float(unit.mods.get(key,0))+float(synergy_mods[key])
   unit.hp = int(unit.hp*(1+mod(unit,"hp_pct")))
   unit.max_hp = unit.hp
   unit.attack = int(unit.attack*(1+mod(unit,"attack_pct")))
   unit.power = int(unit.power*(1+mod(unit,"power_pct")))
   unit.armor += int(mod(unit,"armor"))
   unit.interval = maxi(3,int(unit.interval/(1+mod(unit,"speed"))))
   unit.shield = int(unit.hp*mod(unit,"shield_pct"))
   unit.mana = mini(unit.max_mana,int(mod(unit,"start_mana")))
   unit.attacks = 0
   unit.revived = false
   fighters.append(unit)
 combatants = fighters
 traits.init(self,fighters,seed_value)
 for u in fighters: u.cast_threshold = traits.threshold(u)
 return fighters

func run(allies: Array, enemies: Array, seed_value: int,augments: Array = []) -> Dictionary:
 var fighters = prepare(allies,enemies,seed_value,augments)
 var frames = [{"tick":0,"units":fighters.duplicate(true),"events":[]}]
 var winner = -1
 var final_tick = 0
 for tick in range(1,MAX_TICKS+1):
  events = []
  traits.step(self,fighters,tick)
  var order = range(fighters.size())
  if tick % 2 == 0:
   order.reverse()
  for index in order:
   var unit = fighters[index]
   if unit.hp <= 0:
    continue
   if tick % 10 == 0:
    gain_mana(unit,int(Catalog.ROLES[unit.role].passive)+int(mod(unit,"passive_mana")))
    if mod(unit,"regen") > 0:
     heal(unit,unit,int(unit.max_hp*mod(unit,"regen")),"Erholung")
    for dot in ["poison","burn"]:
     if active(unit,dot):
      hit(unit,unit,int(unit.dot_power.get(dot,8)),dot,true)
   if mod(unit,"cleanse_tick") > 0 and tick % int(mod(unit,"cleanse_tick")) == 0:
    for status in NEGATIVE:
     unit.status.erase(status)
     unit.dot_power.erase(status)
    if not unit.get("toxin_potent",false):
     unit.toxin = 0
     unit.toxin_until = 0
    _event("cleanse",unit,unit,0,"Klarer Kopf")
   if tick == 200 and mod(unit,"patient") > 0:
    unit.attack = int(unit.attack*(1+mod(unit,"patient")))
    unit.power = int(unit.power*(1+mod(unit,"patient")))
    _event("status",unit,unit,0,"Geduld")
   if unit.hp <= 0:
    continue
   var stunned = active(unit,"stun")
   for status in unit.status.keys():
    unit.status[status] -= 1
    if unit.status[status] <= 0:
     unit.status.erase(status)
     unit.dot_power.erase(status)
     _event("expire",unit,unit,0,status)
   if stunned or unit.get("phantom_until",0)>tick:
    unit.erase("pending_action")
    continue
   if unit.has("pending_action"):
    if tick >= unit.pending_action.when: resolve_action(unit,fighters)
    continue
   unit.cooldown -= 1
   if unit.cooldown > 0:
    continue
   var target = choose_target(unit,fighters)
   if target.is_empty():
    continue
   var mon = catalog.get_mon(int(unit.species))
   # Supports can cast on allies before entering attack range.
   if unit.mana >= traits.threshold(unit) and (unit.role == "Unterstützer" or _distance(unit,target) <= traits.reach(self,unit)):
    unit.pending_action = {"kind":"cast","target":target.uid,"when":tick+3}
    _cast_event(unit,target,fighters)
    unit.cooldown = interval(unit)
    continue
   # Ranged roles create space periodically instead of standing in melee forever.
   if unit.role in ["Magier","Unterstützer"] and _distance(unit,target) <= 1 and tick % 3 == 0 and retreat(unit,target,fighters):
    unit.cooldown = 6
    continue
   if _distance(unit,target) > traits.reach(self,unit):
    move_towards(unit,target,fighters)
    unit.cooldown = 4
    continue
   unit.cooldown = interval(unit)
   _event("attack",unit,target,0,"attack")
   unit.pending_action = {"kind":"attack","target":target.uid,"when":tick+2}
  var alive = [0,0]
  for unit in fighters:
   if unit.hp > 0:
    alive[int(unit.side)] += 1
  final_tick = tick
  frames.append({"tick":tick,"units":fighters.duplicate(true),"events":events.duplicate(true),"fields":traits.fields.duplicate(true)})
  if alive[0] == 0 or alive[1] == 0:
   winner = 0 if alive[0] > 0 else (1 if alive[1] > 0 else -1)
   break
 var survivors = fighters.filter(func(u): return u.side == 1 and u.hp > 0).size()
 return {"winner":winner,"ticks":final_tick,"frames":frames,"survivors":survivors,"seed":seed_value}

func resolve_action(unit: Dictionary,fighters: Array):
 var action = unit.pending_action
 unit.erase("pending_action")
 var options = fighters.filter(func(u): return u.uid == action.target and u.hp > 0 and u.get("phantom_until",0) <= traits.tick)
 if options.is_empty(): return
 var target = options[0]
 if action.kind == "cast":
  cast(unit,target,fighters,true)
  return
 unit.attacks += 1
 traits.before_attack(unit)
 var boost = 1.0+(mod(unit,"firsthit") if unit.attacks == 1 else 0.0)+(mod(unit,"thirdhit") if unit.attacks%3 == 0 else 0.0)
 var lost = hit(unit,target,int(unit.attack*boost),"attack")
 gain_mana(unit,int(Catalog.ROLES[unit.role].attack)+int(mod(unit,"attack_mana")))
 _attack_procs(unit,target,fighters,lost)
 traits.after_attack(self,unit,target,fighters,lost)

func active(unit: Dictionary, status: String) -> bool:
 return int(unit.status.get(status,0)) > 0

func mod(unit: Dictionary,key: String) -> float:
 return float(unit.get("mods",{}).get(key,0))

func _attack_procs(unit: Dictionary,target: Dictionary,fighters: Array,lost: int):
 if lost <= 0:
  return
 if mod(unit,"poison_attack") > 0:
  apply_status(unit,target,"poison",40,int(mod(unit,"poison_attack")))
 if unit.attacks == 1 and mod(unit,"stun_first") > 0:
  apply_status(unit,target,"stun",int(mod(unit,"stun_first")))
 if unit.attacks%3 == 0:
  if mod(unit,"shred_attack") > 0:
   apply_status(unit,target,"break",int(mod(unit,"shred_attack")))
  if mod(unit,"mana_burn") > 0:
   var taken = mini(target.mana,int(mod(unit,"mana_burn")))
   target.mana -= taken
   gain_mana(unit,taken)
 var others = fighters.filter(func(u): return u.side != unit.side and u.uid != target.uid and u.hp > 0)
 for other in others:
  if mod(unit,"splash") > 0 and _distance(other,target) <= 1:
   hit(unit,other,int(unit.attack*mod(unit,"splash")),"Splittertreffer",false,catalog.get_mon(unit.species).attack_type,true)
 if mod(unit,"chain") > 0 and unit.attacks%3 == 0 and not others.is_empty():
  others.sort_custom(func(a,b): return _distance(a,target) < _distance(b,target) or _distance(a,target) == _distance(b,target) and a.uid < b.uid)
  hit(unit,others[0],int(unit.attack*mod(unit,"chain")),"Kettenfunke",false,"Elektro",true)

func interval(unit: Dictionary) -> int:
 var value = float(unit.interval)/traits.speed(unit)
 if active(unit,"slow"):
  value *= 1.5
 if active(unit,"haste"):
  value /= 1.35
 return maxi(3,int(value))

func gain_mana(unit: Dictionary, amount: int):
 if amount <= 0 or unit.hp <= 0:
  return
 var old = int(unit.mana)
 unit.mana = mini(traits.threshold(unit),old+int(ceil(amount*(1.2 if traits.n(unit,"Psycho") >= 2 else 1.0))))
 if unit.mana > old:
  _event("mana",unit,unit,int(unit.mana)-old,"mana")

func hit(source: Dictionary, target: Dictionary, raw: int, spell: String, pure: bool = false,attack_type: String = "",secondary: bool = false) -> int:
 if target.hp <= 0:
  return 0
 var armor = maxi(0,int(target.armor)-(18 if active(target,"break") else 0))
 if spell == "attack" and traits.n(source,"Flug") >= 4: armor = int(armor*0.8)
 var multiplier = 1.0
 if not pure:
  var mon = catalog.get_mon(source.species)
  var type = attack_type if not attack_type.is_empty() else (mon.attack_type if spell == "attack" else mon.ability_type)
  multiplier = catalog.effectiveness(type,target)
  if multiplier != 1:
   _event("effectiveness",source,target,int(multiplier*100),"Immun" if multiplier == 0 else ("Sehr effektiv ×%s" % multiplier if multiplier > 1 else "Resistent ×%s" % multiplier))
  if float(target.hp)/target.max_hp < 0.3:
   multiplier *= 1+mod(source,"execute")
  if target.max_hp > source.max_hp:
   multiplier *= 1+mod(source,"giant")
 var damage = (maxi(1,int(raw*multiplier*100.0/(100+armor))) if multiplier > 0 else 0) if not pure else maxi(0,raw)
 damage = int(damage*traits.damage_factor(self,source,target,spell))
 var absorbed = mini(int(target.shield),damage)
 target.shield -= absorbed
 if absorbed > 0 and target.shield == 0: _event("shield_break",source,target,absorbed,spell)
 target.rock_shield = maxi(0,target.get("rock_shield",0)-absorbed)
 var lost = mini(int(target.hp),damage-absorbed)
 target.hp -= lost
 _event("hit",source,target,lost,spell)
 if absorbed > 0:
  _event("absorb",source,target,absorbed,spell)
 if lost > 0:
  var mana = int(Catalog.ROLES[target.role].hit)+int(mod(target,"hit_mana"))
  if target.role == "Tank":
   mana += mini(12,int(100.0*lost/target.max_hp))
  gain_mana(target,mana)
 if lost > 0 and not pure and not secondary:
  var steal = mod(source,"lifesteal" if spell == "attack" else "spell_vamp")
  if steal > 0:
   heal(source,source,int(lost*steal),"Lebensraub")
  if spell != "attack" and mod(source,"burn_spell") > 0:
   apply_status(source,target,"burn",40,int(mod(source,"burn_spell")))
  if spell == "attack" and mod(target,"thorns") > 0 and source.hp > 0:
   hit(target,source,int(mod(target,"thorns")),"Dornen",true,"",true)
 if target.hp == 0 and mod(target,"revive") > 0 and not target.get("revived",false):
  target.revived = true
  target.hp = maxi(1,int(target.max_hp*mod(target,"revive")))
  _event("heal",target,target,target.hp,"Zweiter Atem")
 traits.after_damage(self,source,target,combatants,lost,spell,secondary)
 if target.hp == 0:
  _event("defeat",source,target,0,spell)
  if source.uid != target.uid and mod(source,"kill_haste") > 0:
   apply_status(source,source,"haste",int(mod(source,"kill_haste")))
 return lost

func heal(source: Dictionary, target: Dictionary, amount: int, spell: String):
 if target.hp <= 0:
  return
 var reduction = target.get("toxin_reduction",0.0) if target.get("toxin_until",0)>traits.tick else 0.0
 var restored = mini(int(amount*(1+mod(source,"healing"))*(1.1 if target.get("blessed",false) else 1.0)*(1-reduction)),int(target.max_hp)-int(target.hp))
 target.hp += restored
 _event("heal",source,target,restored,spell)

func apply_status(source: Dictionary, target: Dictionary, kind: String, duration: int, strength: int = 0):
 if target.hp <= 0:
  return
 if kind == "stun" and target.get("unstoppable_until",0)>traits.tick: return
 target.status[kind] = maxi(duration,int(target.status.get(kind,0)))
 if kind in ["poison","burn"]:
  target.dot_power[kind] = maxi(strength,int(target.dot_power.get(kind,0)))
 if kind == "taunt":
  target.taunter = source.uid
 _event("status",source,target,duration,kind)

func cast(unit: Dictionary, primary: Dictionary, fighters: Array,launched: bool = false):
 if unit.mana < traits.threshold(unit) or unit.hp <= 0:
  return
 unit.mana -= traits.threshold(unit)
 var mon = catalog.get_mon(int(unit.species))
 if not launched: _cast_event(unit,primary,fighters)
 if mod(unit,"shield_cast") > 0:
  unit.shield = mini(unit.max_hp,unit.shield+int(unit.max_hp*mod(unit,"shield_cast")))
  _event("shield",unit,unit,int(unit.max_hp*mod(unit,"shield_cast")),"Schutzzauber")
 var friends = fighters.filter(func(u): return u.side == unit.side and u.hp > 0)
 if mod(unit,"heal_cast") > 0:
  friends.sort_custom(_weakest)
  heal(unit,friends[0],int(friends[0].max_hp*mod(unit,"heal_cast")),"Heilende Worte")
 for friend in friends:
  if friend.uid != unit.uid:
   gain_mana(friend,int(mod(unit,"mana_cast")))
 # Resolve each selector once, so a heal/damage in the same spell cannot retarget later effects.
 var selections = {}
 for effect in mon.effects:
  var key = str(effect.target)+str(effect.get("count",0))
  if not selections.has(key):
   selections[key] = targets(unit,primary,fighters,effect)
 for effect in mon.effects:
  var recipients = selections[str(effect.target)+str(effect.get("count",0))]
  for target in recipients:
   if target.hp <= 0:
    continue
   var scale = (2.0 if traits.n(unit,"Psycho") >= 8 else 1.5 if traits.n(unit,"Psycho") >= 6 else 1.0)
   var amount = int(unit.power*float(effect.get("scale",1.0))*traits.power(unit)*scale)
   _event("ability_impact",unit,target,amount,mon.ability)
   events[-1].effect = effect.kind
   events[-1].selector = effect.target
   match effect.kind:
    "damage": hit(unit,target,amount,mon.ability)
    "heal": heal(unit,target,amount,mon.ability)
    "shield":
     target.shield = mini(int(target.max_hp),int(target.shield)+amount)
     _event("shield",unit,target,amount,mon.ability)
    "mana": gain_mana(target,int(effect.amount*scale))
    "cleanse":
     for kind in NEGATIVE:
      target.status.erase(kind)
      target.dot_power.erase(kind)
     if not target.get("toxin_potent",false):
      target.toxin = 0
      target.toxin_until = 0
     _event("cleanse",unit,target,0,mon.ability)
    _:
     apply_status(unit,target,effect.kind,int(effect.get("duration",30)*scale),amount)

 traits.after_cast(self,unit,primary,fighters)
 if traits.n(unit,"Psycho") >= 8:
  # Additional effect follows the ability's first effect, without recursive casts.
  var first = mon.effects[0]
  for recipient in targets(unit,primary,fighters,first):
   if recipient.hp <= 0: continue
   if first.kind == "damage": hit(unit,recipient,int(unit.power*0.5),"Fokus-Nachhall",false,mon.ability_type,true)
   elif first.kind == "heal":
    recipient.shield += int(unit.power*0.5)
    _event("shield",unit,recipient,int(unit.power*0.5),"Fokus-Nachhall")
   elif first.kind == "shield": heal(unit,recipient,int(unit.power*0.5),"Fokus-Schutz")
   elif first.kind == "mana": gain_mana(recipient,15)
   elif first.kind == "cleanse":
    recipient.shield += int(unit.power*0.5)
    _event("shield",unit,recipient,int(unit.power*0.5),"Fokus-Nachhall")
   else: apply_status(unit,recipient,first.kind,int(first.get("duration",30))*2+10,int(unit.power*float(first.get("scale",1.0))))

func targets(unit: Dictionary, primary: Dictionary, fighters: Array, effect: Dictionary) -> Array:
 var allies = fighters.filter(func(u): return u.side == unit.side and u.hp > 0)
 var enemies = fighters.filter(func(u): return u.side != unit.side and u.hp > 0 and u.get("phantom_until",0)<=traits.tick)
 match effect.target:
  "self": return [unit]
  "enemy": return [primary]
  "weak_enemy":
   enemies.sort_custom(_weakest)
   return enemies.slice(0,1)
  "weak_ally":
   allies.sort_custom(_weakest)
   return allies.slice(0,1)
  "all_allies": return allies
  "other_allies": return allies.filter(func(u): return u.uid != unit.uid)
  "all_enemies": return enemies
  "near_enemies": return enemies.filter(func(u): return _distance(u,unit) <= (4 if traits.n(unit,"Psycho")>=8 else 2))
  "area": return enemies.filter(func(u): return _distance(u,primary) <= (2 if traits.n(unit,"Psycho")>=8 else 1))
  "chain":
   enemies.sort_custom(func(a,b):
    var da = _distance(a,primary)
    var db = _distance(b,primary)
    return da < db or da == db and a.uid < b.uid)
   return enemies.slice(0,int(effect.get("count",3)))
 return []

func _weakest(a: Dictionary,b: Dictionary) -> bool:
 var ar = float(a.hp)/a.max_hp
 var br = float(b.hp)/b.max_hp
 return ar < br or is_equal_approx(ar,br) and a.uid < b.uid

func choose_target(unit: Dictionary,fighters: Array) -> Dictionary:
 var enemies = fighters.filter(func(u): return u.side != unit.side and u.hp > 0 and u.get("phantom_until",0)<=traits.tick)
 if enemies.is_empty():
  return {}
 if active(unit,"taunt"):
  for other in enemies:
   if other.uid == unit.taunter:
    return other
 var reach = traits.reach(self,unit)
 if traits.n(unit,"Unlicht") >= 2:
  if traits.n(unit,"Unlicht") >= 8:
   enemies.sort_custom(func(a,b): return a.get("damage_done",0)>b.get("damage_done",0) or a.get("damage_done",0)==b.get("damage_done",0) and a.uid<b.uid)
  else: enemies.sort_custom(_weakest)
  return enemies[0]
 if unit.role == "Angreifer":
  var in_reach = enemies.filter(func(u): return _distance(unit,u) <= reach)
  if not in_reach.is_empty():
   in_reach.sort_custom(_weakest)
   return in_reach[0]
 enemies.sort_custom(func(a,b):
  var da = _distance(unit,a)
  var db = _distance(unit,b)
  return da < db or da == db and a.uid < b.uid)
 return enemies[0]

func _distance(a: Dictionary,b: Dictionary) -> int:
 return Catalog.distance(Vector2i(a.x,a.y),Vector2i(b.x,b.y))

func retreat(unit: Dictionary,target: Dictionary,fighters: Array) -> bool:
 var occupied = _occupied(unit,fighters)
 for offset in [Vector2i(0,1 if unit.side == 0 else -1),Vector2i(-1,0),Vector2i(1,0)]:
  var x = int(unit.x)+offset.x
  var y = int(unit.y)+offset.y
  if x >= 0 and x < 7 and y >= 0 and y < 6 and not occupied.has(y*7+x) and absi(x-int(target.x))+absi(y-int(target.y)) > _distance(unit,target):
   _relocate(unit,x,y)
   return true
 return false

func _occupied(unit: Dictionary,fighters: Array) -> Dictionary:
 var occupied = {}
 for other in fighters:
  if other.hp > 0 and other.uid != unit.uid:
   occupied[int(other.y)*7+int(other.x)] = true
 return occupied

func _relocate(unit: Dictionary,x: int,y: int):
 var before = unit.duplicate(true)
 unit.x = x
 unit.y = y
 _event("move",before,unit,0,"move")

func move_towards(unit: Dictionary,target: Dictionary,fighters: Array):
 var occupied = _occupied(unit,fighters)
 var start = int(unit.y)*7+int(unit.x)
 var queue = [start]
 var previous = {start:-1}
 var cursor = 0
 var reach = traits.reach(self,unit)
 while cursor < queue.size():
  var current = queue[cursor]
  cursor += 1
  var cx = current % 7
  var cy = int(current/7)
  if current != start and absi(cx-int(target.x))+absi(cy-int(target.y)) <= reach:
   while previous[current] != start:
    current = previous[current]
   _relocate(unit,current%7,int(current/7))
   return
  for offset in [Vector2i(0,-1),Vector2i(-1,0),Vector2i(1,0),Vector2i(0,1)]:
   var nx = cx+offset.x
   var ny = cy+offset.y
   var next = ny*7+nx
   if nx < 0 or nx >= 7 or ny < 0 or ny >= 6 or occupied.has(next) or previous.has(next):
    continue
   previous[next] = current
   queue.append(next)

func _cast_event(unit: Dictionary,primary: Dictionary,fighters: Array):
 var mon = catalog.get_mon(int(unit.species))
 _event("cast",unit,primary,0,mon.ability)
 var destinations: Array = []
 var ids: Array = []
 for effect in mon.effects:
  for target in targets(unit,primary,fighters,effect):
   if target.uid not in ids:
    ids.append(target.uid)
    destinations.append({"uid":target.uid,"x":target.x,"y":target.y})
 events[-1].targets = destinations

func _event(kind: String,source: Dictionary,target: Dictionary,amount: int,spell: String):
 events.append({"kind":kind,"from":source.uid,"to":target.uid,"sx":source.x,"sy":source.y,"tx":target.x,"ty":target.y,"species":source.species,"target_species":target.species,"star":target.star,"source_star":source.star,"overloaded":traits.n(source,"Psycho") >= 6,"amount":amount,"spell":spell})
