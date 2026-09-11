extends RefCounted
const Catalog = preload("res://core/catalog.gd")
static var cached: Array = []
var all: Array = []

func _init():
 if cached.is_empty():
  cached = JSON.parse_string(FileAccess.get_file_as_string("res://data/augments.json"))
 all = cached

func get_aug(id: String) -> Dictionary:
 for aug in all:
  if aug.id == id:
   return aug
 return {}

func value(ids: Array,key: String) -> float:
 var total = 0.0
 for id in ids:
  total += float(get_aug(id).get(key,0))
 return total

func counts(team: Array,ids: Array) -> Dictionary:
 var result = Catalog.new().synergies(team)
 for id in ids:
  var type = get_aug(id).get("emblem","")
  if not type.is_empty():
   result[type] = int(result.get(type,0))+1
 return result

func usable(aug: Dictionary,state: Dictionary) -> bool:
 var cat = Catalog.new()
 var team = state.units.filter(func(u): return u.zone == "board")
 if aug.has("emblem"):
  return true
 if (aug.has("xp_round") or aug.has("xp_buy")) and state.level >= 10:
  return false
 if aug.has("loss_gold") and state.lives <= 1:
  return false
 if aug.has("dividend") and cat.synergies(team).size() < 4:
  return false
 if aug.has("underdog") and team.filter(func(u): return cat.get_mon(u.species).cost == 1).size() < 3:
  return false
 if aug.has("underdog"):
  var lines = {}
  for u in team:
   if cat.get_mon(u.species).cost == 1:
    lines[u.species] = true
  return lines.size() >= 3
 if aug.has("condition"):
  return team.any(func(u): return matches(aug.condition,u,team))
 return true

func matches(condition: String,u: Dictionary,team: Array) -> bool:
 var cat = Catalog.new()
 var mon = cat.get_mon(u.species)
 var adjacent = team.any(func(v): return v.uid != u.uid and Catalog.distance(Vector2i(u.slot%7,int(u.slot/7)),Vector2i(v.slot%7,int(v.slot/7))) == 1)
 match condition:
  "front": return int(u.slot/7) == 0
  "back": return int(u.slot/7) == 2
  "solo": return not adjacent
  "neighbors": return adjacent
  "edges": return u.slot%7 in [0,6]
  "center": return u.slot%7 == 3
  "pairs": return team.filter(func(v): return v.species == u.species).size() >= 2
  "mono": return cat.combat_types(u).size() == 1
  "diverse": return cat.synergies(team).size() >= 6
  "lowcost": return mon.cost <= 2
 return mon.role == condition

func modifiers(u: Dictionary,team: Array,ids: Array) -> Dictionary:
 var result = {}
 for id in ids:
  var aug = get_aug(id)
  if aug.has("condition") and not matches(aug.condition,u,team):
   continue
  for key in aug.get("mods",{}):
   result[key] = float(result.get(key,0))+float(aug.mods[key])
 return result
