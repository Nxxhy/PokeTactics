extends SceneTree
const B = preload("res://core/battle.gd")
const C = preload("res://core/catalog.gd")
const M = preload("res://core/match.gd")
var cat = C.new()
var passed = 0
var failed = 0
func check(ok: bool,label: String):
 if ok: passed += 1
 else: failed += 1;printerr("FAIL V8: "+label)
func unit(id: int,uid: int,slot: int,star: int = 1) -> Dictionary:
 return {"species":id,"uid":uid,"slot":slot,"star":star,"zone":"board"}
func fixture(type: String,tier: int):
 var source = {}
 for m in cat.roster:
  for star in [1,2,3]:
   if type in cat.combat_types(unit(m.id,1,3,star)):
    source = unit(m.id,1,3,star);break
  if not source.is_empty(): break
 var b = B.new()
 var team = b.prepare([source,unit(4,2,4)],[unit(1,3,3),unit(4,4,4),unit(172,5,5)],123)
 for u in team: u.trait_counts = {type:tier} if u.side == 0 else {}
 b.traits.init(b,team,123)
 return [b,team,team[0],team[2]]
func _init():
 economy()
 roster()
 for type in cat.trait_descriptions:
  for tier in [2,4,6,8]: exercise(type,tier)
 interactions()
 simulations()
 growth_battle()
 print("V8: %d passed, %d failed" % [passed,failed])
 quit(1 if failed else 0)
func economy():
 for gold in [0,9,10,49,50,99]:
  var m = M.new(7);m.state.gold=gold
  check(m.interest()==mini(5,int(gold/10)),"Interest "+str(gold))
  var round_before = m.state.round
  var forecast = m.income_forecast()
  m._settle(1)
  check(m.state.gold==gold+forecast.loss and m.state.income.base==6,"Exact loss payout")
  check(m.state.lives==2 and m.state.round==round_before,"Loss retries same round")
  var after = m.snapshot();m._settle(1,m.state.settled_serial)
  check(m.snapshot()==after,"Settlement idempotent")
 var m = M.new(0)
 for level in range(1,11):
  m.state.level=level
  check(M.SHOP_ODDS[level].reduce(func(a,b):return a+b,0)==100,"Odds sum")
  check(m.xp_needed()==[0,2,3,4,8,14,22,32,48,64,0][level],"XP "+str(level))
 check(M.SHOP_ODDS[10][4]==20,"Legendary chance 20")
 for cost in range(1,6):
  var mon = cat.roster.filter(func(r):return r.cost==cost)[0]
  var stats = cat.stats(unit(mon.id,1,0,3))
  check(stats.hp==int(mon.hp*3.24*C.STAR3[cost-1][0]),"Star HP "+str(cost))
  check(stats.attack==int(mon.attack*3.24*C.STAR3[cost-1][1]),"Star attack "+str(cost))
  check(stats.power==int(mon.power*3.24*C.STAR3[cost-1][2]),"Star ability "+str(cost))
func roster():
 check(cat.roster.size()==70,"Exactly 70 lines")
 for type in cat.trait_descriptions:
  var candidates=[]
  for mon in cat.roster:
   for star in [1,2,3]:
    var u = unit(mon.id,candidates.size()+1,candidates.size(),star)
    if type in cat.combat_types(u): candidates.append(u);break
  check(candidates.size()>=7,"Seven real lines: "+type)
  var a = preload("res://core/augments.gd").new()
  var emblems=a.all.filter(func(e):return e.get("emblem","")==type)
  check(emblems.size()==1,"One emblem "+type)
  check(a.counts(candidates.slice(0,7),[emblems[0].id])[type]>=8,"8 threshold reachable "+type)
  check(a.counts([],[emblems[0].id])[type]==1,"Emblem without unit "+type)
 var m=M.new(10);m.state.round=5;m._ensure_augments()
 check(m.state.augment_offers.size()==3 and m.state.augment_offers[0]!=m.state.augment_offers[1] and m.state.augment_offers[1]!=m.state.augment_offers[2] and m.state.augment_offers[0]!=m.state.augment_offers[2],"Distinct offers")
func exercise(type: String,tier: int):
 var f=fixture(type,tier);var b=f[0];var team=f[1];var u=f[2];var target=f[3];var t=b.traits
 check(t.n(u,type)==tier,"Tier "+type+str(tier))
 match type:
  "Feuer":
   check(t.speed(u)>=1.1,"Fire speed")
   if tier>=4:
    u.attacks=5;t.after_attack(b,u,target,team,10);check(u.heat==1,"Heat fifth hit")
   if tier>=6:
    u.heat=5;t.before_attack(u);check(t.damage_factor(b,u,target,"attack")>=1.5,"Overheat crit")
    t.after_attack(b,u,target,team,10);check(u.heat==0 and u.overheat_until==30,"Overheat consumption")
    if tier==8: check(b.active(target,"burn"),"Overheat burn")
  "Wasser":
   t.after_cast(b,u,target,team);check(t.fields.size()==1,"Water field")
   check(t.fields[0].until==(60 if tier>=4 else 40),"Water duration")
   if tier==8:check(t.fields[0].tiles.size()==21,"Flood half board")
   if tier>=6:
    u.x=3;u.y=3 if tier==8 else target.y;t.step(b,team,1);check(u.water_buff,"Water defense")
  "Pflanze":
   u.hp=int(u.max_hp*0.5)
   for tick in range(50,1001,50): t.step(b,team,tick)
   check(u.growth==(20 if tier>=6 else 5),"Growth cap")
   if tier>=4:check(u.hp>u.max_hp*0.5,"Growth healing")
   if tier==8:check(t.cost(u)==int(u.max_mana*0.8) and t.power(u)>=1.9,"Bloom at 100s")
  "Elektro":
   for i in range(40):t.after_cast(b,u,target,team)
   check(b.events.any(func(e):return e.spell=="Kettenladung"),"Seeded lightning")
   check(b.events.size()<600,"Finite lightning")
  "Eis":
   for i in range(5 if tier>=4 else 3):t.frost(b,u,target,team,1)
   check(target.frost_slow==30,"Frost slow")
   if tier>=4:check(target.frozen_until==15 and target.frost==0 and target.frost_guard==35,"Freeze consumption and guard")
   if tier>=6:check(t.damage_factor(b,u,target,"attack")>=1.2,"Frozen vulnerability")
  "Kampf":
   check(u.spirit==2,"Spirit starts 2")
   for i in range(8):t.after_damage(b,u,target,team,1,"attack",false)
   check(u.spirit==10,"Spirit cap")
   if tier>=6:
    b.apply_status(target,u,"stun",20);check(not b.active(u,"stun"),"Unstoppable CC immunity")
   if tier>=4:
    target.hp=0;t.after_damage(b,u,target,team,1,"attack",false)
    check(u.spirit==(10 if tier==8 else 5),"Kill reset")
  "Gift":
   for i in range(10):t.toxin(u,target)
   check(target.toxin==(10 if tier>=6 else 1),"Toxin stack cap")
   if tier>=4:check(target.toxin_reduction==(0.5 if tier==8 else 0.4),"Healing reduction replaces")
   if tier==8:check(target.toxin_potent,"Uncleanseable toxin")
  "Gestein":
   target.y=u.y-1;check(t.damage_factor(b,target,u,"attack")<=0.85,"Front armor")
   if tier>=4:
    check(u.rock_shield==int(u.max_hp*0.2),"Rock starts shield")
    u.shield=0;u.rock_shield=0;t.after_damage(b,target,u,team,1,"attack",false)
    if tier>=6:check(b.events.any(func(e):return e.spell=="Splittersturm"),"Shatter")
    if tier==8:t.step(b,team,80);check(u.rock_regenerated and u.shield>0,"One regeneration")
  "Käfer":
   check(t.speed(u)>=1.1,"Bug speed")
   if tier>=4:
    u.hp=0;t.after_damage(b,target,u,team,1,"attack",false)
    check(team.size()==6 and team.back().summoned,"One larva")
    var larva=team.back();larva.hp=0;t.after_damage(b,target,larva,team,1,"attack",false)
    check(team.size()==6,"No summon chain")
  "Geist":
   u.hp=int(u.max_hp*0.5);t.after_damage(b,target,u,team,1,"attack",false)
   check(u.phantom_used and t.damage_factor(b,target,u,"attack")==0,"Phantom invulnerable")
   t.step(b,team,15)
   if tier>=6:check(u.hp>u.max_hp*0.5,"Phantom heal")
   if tier==8:
    u.hp=0;t.after_damage(b,target,u,team,1,"attack",false);check(u.phantom_revived and u.hp>0,"One revival")
  "Drache":
   check(t.damage_factor(b,u,target,"spell")>=1.15,"Dragon ability")
   if tier>=4:
    team[1].hp=0;t.after_damage(b,target,team[1],team,1,"attack",false);check(u.dragon_deaths==1,"Natural death bonus")
    t.after_damage(b,target,team[1],team,1,"attack",false);check(u.dragon_deaths==1,"No repeated death bonus")
   if tier==8:t.step(b,team,1);check(u.dragon_blood,"Only dragons remain")
  "Unlicht":
   target.hp=1;target.damage_done=99999
   check(b.choose_target(u,team).uid==target.uid,"Predator target")
   if tier>=6:target.hp=0;t.after_damage(b,u,target,team,1,"attack",false);check(u.mana==40,"Predator mana")
  "Psycho":
   b.gain_mana(u,10);check(u.mana==12,"Psychic mana rate")
   check(t.threshold(u)==int(ceil(u.max_mana*([1.0,1.25,1.5,2.0][int(tier/2)-1]))),"Focus threshold")
  "Fee":
   var blessed=team.filter(func(v):return v.side==0 and v.blessed).size()
   check(blessed==(1 if tier==2 else 2),"Bless recipients")
  "Flug":
   check(t.reach(b,u)==int(cat.get_mon(u.species).range)+1,"Flight range")
   var occupied={}
   for v in team:
    check(not occupied.has(Vector2i(v.x,v.y)),"Unique landing");occupied[Vector2i(v.x,v.y)]=true
  "Boden":
   if tier>=4:
    u.x=target.x;u.y=target.y+1;t.step(b,team,80)
    check(b.events.any(func(e):return e.spell=="Erdbeben"),"Earthquake timer")
    if tier>=6:check(b.active(target,"stun"),"Airborne interrupt")
    if tier==8:check(t.fields.any(func(field):return field.kind=="rift"),"Rifts")
  "Stahl":
   check(u.armor>=20,"Steel armor")
   if tier>=4:
    var before=u.armor;t.step(b,team,50);check(u.armor==before+5,"Steel scaling")
   if tier>=6:
    u.hp=int(u.max_hp*0.3);t.after_damage(b,target,u,team,1,"attack",false)
    check(u.steel_charges==1,"Steel first charge")
    t.after_damage(b,target,u,team,1,"attack",false);check(u.steel_charges==1,"No simultaneous second charge")
    if tier==8:t.tick+=60;t.after_damage(b,target,u,team,1,"attack",false);check(u.steel_charges==2,"Steel second charge")
  "Normal":
   check(u.max_hp>cat.stats(unit(u.species,1,3,u.star)).hp,"Adaptation stats")
func interactions():
 var f=fixture("Wasser",8);var b=f[0];var team=f[1];var u=f[2];var target=f[3]
 b.traits.after_cast(b,u,target,team)
 var plant=team.filter(func(v):return "Pflanze" in cat.combat_types(v))[0]
 plant.x=3;plant.y=3;plant.hp=int(plant.max_hp/2);var before=plant.hp
 b.traits.step(b,team,10);check(plant.hp>before,"Water plant regeneration")
 var f2=fixture("Drache",6);b=f2[0];team=f2[1];u=f2[2];target=f2[3]
 team[1].summoned=true;team[1].hp=0;b.traits.after_damage(b,target,team[1],team,1,"attack",false);check(u.dragon_deaths==0,"Summon does not feed Dragon")
 var f3=fixture("Normal",8);b=f3[0];team=f3[1];u=f3[2]
 for v in team:
  if v.side==0:v.trait_counts={"Normal":8,"Psycho":4,"Feuer":4,"Wasser":1}
 b.traits.init(b,team,1)
 check(b.traits.n(u,"Normal")==8 and b.traits.n(u,"Feuer")==2 and b.traits.n(u,"Wasser")==0,"Normal copies only naturally represented types")
 # A natural Electric caster without active Electric trait still gets one water jump.
 b=B.new();team=b.prepare([unit(172,1,3)],[unit(1,2,3),unit(4,3,4)],3)
 u=team[0];target=team[1]
 b.traits.fields=[{"kind":"water","side":0,"tiles":[Vector2i(target.x,target.y)],"until":40,"tier":2}]
 b.events=[];b.traits.after_cast(b,u,target,team)
 check(b.events.filter(func(e):return e.kind=="hit" and e.spell=="Kettenladung").size()==1,"Water grants exactly one electric jump without recursive chains")
func simulations():
 for seed_value in range(3):
  var m=M.new(seed_value)
  var result=B.new().run(m.board(),m.state.enemy,seed_value)
  var replay=B.new().run(m.board(),m.state.enemy,seed_value)
  check(result==replay,"Deterministic battle "+str(seed_value))
  check(result.ticks<=1200,"Finite battle")
  var launch={};var hits=0
  for frame in result.frames:
   for e in frame.events:
    if e.kind=="attack":launch[e.from]=frame.tick
    if e.kind=="hit" and e.spell=="attack":
     check(launch.has(e.from) and frame.tick>=launch[e.from]+2,"Attack hit follows projectile");hits+=1
  check(hits>0,"Attacks resolve")
  var clean=B.new().prepare(m.board(),m.state.enemy,seed_value)
  check(clean.all(func(v):return v.growth==0 and v.toxin==0 and not v.phantom_used),"Transient state reset")

func growth_battle():
 var team=[]
 for m in cat.roster:
  if "Pflanze" in cat.combat_types(unit(m.id,1,0,3)): team.append(unit(m.id,team.size()+1,team.size(),3))
 var emblem=preload("res://core/augments.gd").new().all.filter(func(a):return a.get("emblem","")=="Pflanze")[0].id
 var b=B.new()
 var result=b.run(team,team,100,[emblem])
 var growth=0
 for frame in result.frames:
  for u in frame.units:growth=maxi(growth,u.growth)
 check(growth==20 and result.ticks<=1200,"20 stacks reachable in real seven-line battle")
 var reset=b.prepare(team,team,100,[emblem])
 check(reset.all(func(u):return u.growth==0),"Growth resets on reused battle controller")
