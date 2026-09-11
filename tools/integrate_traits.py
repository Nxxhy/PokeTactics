from pathlib import Path
p=Path('core/battle.gd');s=p.read_text(encoding='utf-8')
s=s.replace('var events: Array = []','var events: Array = []\nvar traits = preload("res://core/traits.gd").new()\nvar combatants: Array = []')
s=s.replace('var synergy_mods = catalog.synergy_modifiers(source,synergy)','unit.trait_counts = synergy.duplicate()\n   var synergy_mods = {}')
s=s.replace(' return fighters\n\nfunc run',' combatants = fighters\n traits.init(self,fighters,seed_value)\n return fighters\n\nfunc run')
s=s.replace('  events = []\n  var order','  events = []\n  traits.step(self,fighters,tick)\n  var order')
s=s.replace('   if stunned:\n    continue','   if stunned or unit.get("phantom_until",0)>tick:\n    unit.erase("pending_action")\n    continue\n   if unit.has("pending_action"):\n    if tick >= unit.pending_action.when: resolve_action(unit,fighters)\n    continue')
s=s.replace('unit.mana >= unit.max_mana','unit.mana >= traits.threshold(unit)').replace('_distance(unit,target) <= int(mon.range)','_distance(unit,target) <= traits.reach(self,unit)').replace('_distance(unit,target) > int(mon.range)','_distance(unit,target) > traits.reach(self,unit)')
s=s.replace('    cast(unit,target,fighters)\n    unit.cooldown = interval(unit)','    unit.pending_action = {"kind":"cast","target":target.uid,"when":tick+3}\n    _event("cast",unit,target,0,mon.ability)\n    unit.cooldown = interval(unit)')
a=s.index('   _event("attack",unit,target,0,"attack")');z=s.index('  var alive = [0,0]',a)
s=s[:a]+'''   _event("attack",unit,target,0,"attack")
   unit.pending_action = {"kind":"attack","target":target.uid,"when":tick+2}
'''+s[z:]
s=s.replace('"events":events.duplicate(true)})','"events":events.duplicate(true),"fields":traits.fields.duplicate(true)})')
a=s.index('func active(')
s=s[:a]+'''func resolve_action(unit: Dictionary,fighters: Array):
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

'''+s[a:]
s=s.replace('var value = float(unit.interval)','var value = float(unit.interval)/traits.speed(unit)')
s=s.replace('unit.mana = mini(int(unit.max_mana),old+amount)','unit.mana = mini(traits.threshold(unit),old+int(ceil(amount*(1.2 if traits.n(unit,"Psycho") >= 2 else 1.0))))')
s=s.replace('var armor = maxi(0,int(target.armor)-(18 if active(target,"break") else 0))','var armor = maxi(0,int(target.armor)-(18 if active(target,"break") else 0))\n if spell == "attack" and traits.n(source,"Flug") >= 4: armor = int(armor*0.8)')
s=s.replace(' var absorbed = mini(int(target.shield),damage)',' damage = int(damage*traits.damage_factor(self,source,target,spell))\n var absorbed = mini(int(target.shield),damage)')
s=s.replace(' if target.hp == 0:\n  _event("defeat"',' traits.after_damage(self,source,target,combatants,lost,spell,secondary)\n if target.hp == 0:\n  _event("defeat"')
s=s.replace('var restored = mini(int(amount*(1+mod(source,"healing"))),int(target.max_hp)-int(target.hp))','var reduction = target.get("toxin_reduction",0.0) if target.get("toxin_until",0)>traits.tick else 0.0\n var restored = mini(int(amount*(1+mod(source,"healing"))*(1.1 if target.get("blessed",false) else 1.0)*(1-reduction)),int(target.max_hp)-int(target.hp))')
s=s.replace(' target.status[kind] = maxi(duration,int(target.status.get(kind,0)))',' if kind == "stun" and target.get("unstoppable_until",0)>traits.tick: return\n target.status[kind] = maxi(duration,int(target.status.get(kind,0)))')
s=s.replace('func cast(unit: Dictionary, primary: Dictionary, fighters: Array):','func cast(unit: Dictionary, primary: Dictionary, fighters: Array,launched: bool = false):')
s=s.replace('unit.mana < unit.max_mana','unit.mana < traits.threshold(unit)').replace('unit.mana -= unit.max_mana','unit.mana -= traits.threshold(unit)')
s=s.replace(' _event("cast",unit,primary,0,mon.ability)',' if not launched: _event("cast",unit,primary,0,mon.ability)')
s=s.replace('var amount = int(unit.power*float(effect.get("scale",1.0)))','var scale = (2.0 if traits.n(unit,"Psycho") >= 8 else 1.5 if traits.n(unit,"Psycho") >= 6 else 1.0)\n   var amount = int(unit.power*float(effect.get("scale",1.0))*traits.power(unit)*scale)')
s=s.replace('   for status in NEGATIVE:\n     unit.status.erase(status)','   for status in NEGATIVE:\n     unit.status.erase(status)')
s=s.replace('    _event("cleanse",unit,target,0,mon.ability)','    if not target.get("toxin_potent",false): target.toxin = 0;target.toxin_until = 0\n     _event("cleanse",unit,target,0,mon.ability)') if False else s
needle='     _event("cleanse",unit,target,0,mon.ability)'
s=s.replace(needle,'     if not target.get("toxin_potent",false):\n      target.toxin = 0\n      target.toxin_until = 0\n'+needle)
s=s.replace('    _event("cleanse",unit,unit,0,"Klarer Kopf")','    if not unit.get("toxin_potent",false):\n     unit.toxin = 0\n     unit.toxin_until = 0\n    _event("cleanse",unit,unit,0,"Klarer Kopf")')
s=s.replace('\nfunc targets(','''\n traits.after_cast(self,unit,primary,fighters)
 if traits.n(unit,"Psycho") >= 8:
  # Additional effect follows the ability's first effect, without recursive casts.
  var first = mon.effects[0]
  for recipient in targets(unit,primary,fighters,first):
   if recipient.hp <= 0: continue
   if first.kind == "damage": hit(unit,recipient,int(unit.power*0.5),"Fokus-Nachhall",false,mon.ability_type,true)
   elif first.kind == "heal": recipient.shield += int(unit.power*0.5)
   elif first.kind == "shield": heal(unit,recipient,int(unit.power*0.5),"Fokus-Schutz")
   elif first.kind == "mana": gain_mana(recipient,15)
   elif first.kind == "cleanse": recipient.shield += int(unit.power*0.5)
   else: apply_status(unit,recipient,first.kind,int(first.get("duration",30))+10,int(unit.power*float(first.get("scale",1.0))))

func targets(''')
s=s.replace('_distance(u,unit) <= 2','_distance(u,unit) <= (4 if traits.n(unit,"Psycho")>=8 else 2)').replace('_distance(u,primary) <= 1','_distance(u,primary) <= (2 if traits.n(unit,"Psycho")>=8 else 1)')
s=s.replace('var reach = int(catalog.get_mon(int(unit.species)).range)','var reach = traits.reach(self,unit)')
s=s.replace('var enemies = fighters.filter(func(u): return u.side != unit.side and u.hp > 0)','var enemies = fighters.filter(func(u): return u.side != unit.side and u.hp > 0 and u.get("phantom_until",0)<=traits.tick)')
s=s.replace(' if unit.role == "Angreifer":',' if traits.n(unit,"Unlicht") >= 2:\n  if traits.n(unit,"Unlicht") >= 8:\n   enemies.sort_custom(func(a,b): return a.get("damage_done",0)>b.get("damage_done",0) or a.get("damage_done",0)==b.get("damage_done",0) and a.uid<b.uid)\n  else: enemies.sort_custom(_weakest)\n  return enemies[0]\n if unit.role == "Angreifer":')
p.write_text(s,encoding='utf-8')
