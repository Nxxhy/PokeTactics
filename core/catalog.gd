extends RefCounted

const REPLACEMENTS = {7: 48, 37: 60, 54: 69, 152: 111, 158: 122, 252: 173, 258: 238, 63: 133, 187: 174, 194: 298, 113: 215, 193: 220, 198: 228, 207: 290, 299: 307, 58: 353, 150: 361, 151: 363, 245: 380, 249: 381}
const VERSION = 4
# Additional three-star HP / attack / ability multipliers, indexed by original cost.
const STAR3 = [[1.08,1.06,1.10],[1.14,1.12,1.18],[1.25,1.22,1.35],[1.50,1.45,1.70],[2.50,2.20,3.00]]
const FORM_NAMES = {
 1:"Bisasam",2:"Bisaknosp",3:"Bisaflor",4:"Glumanda",5:"Glutexo",6:"Glurak",
 7:"Schiggy",8:"Schillok",9:"Turtok",25:"Pikachu",26:"Raichu",37:"Vulpix",38:"Vulnona",
 43:"Myrapla",44:"Duflor",45:"Giflor",54:"Enton",55:"Entoron",63:"Abra",64:"Kadabra",65:"Simsala",
 66:"Machollo",67:"Maschock",68:"Machomei",74:"Kleinstein",75:"Georok",76:"Geowaz",
 81:"Magnetilo",82:"Magneton",462:"Magnezone",92:"Nebulak",93:"Alpollo",94:"Gengar",
 95:"Onix",208:"Stahlos",120:"Sterndu",121:"Starmie",143:"Relaxo",131:"Lapras",59:"Arkani",
 123:"Sichlor",115:"Kangama",150:"Mewtu",149:"Dragoran",145:"Zapdos",242:"Heiteira"
}
const COLORS = {"Pflanze":"477b39", "Gift":"855092", "Feuer":"b64432", "Wasser":"326aa1", "Elektro":"967014", "Psycho":"a33f73", "Kampf":"8c4b32", "Gestein":"76603d", "Stahl":"476b72", "Geist":"65528e", "Normal":"6b6555", "Eis":"277e86", "Drache":"6845a0", "Flug":"5b6da0", "Käfer":"607a27"}
const ROLES = {
 "Tank":{"attack":8,"hit":18,"passive":0,"text":"8 Mana/Angriff; 18 + bis zu 12 Mana pro Schadenstreffer. Bindet nahe Gegner."},
 "Angreifer":{"attack":23,"hit":4,"passive":0,"text":"23 Mana/Angriff; 4 Mana pro Schadenstreffer. Sucht verletzte Ziele in Reichweite."},
 "Magier":{"attack":12,"hit":6,"passive":5,"text":"12 Mana/Angriff; 6 pro Schadenstreffer; 5 Mana/s. Hält Abstand."},
 "Unterstützer":{"attack":5,"hit":5,"passive":9,"text":"5 Mana/Angriff; 5 pro Schadenstreffer; 9 Mana/s. Bleibt hinter dem Team."}
}
const BONUSES = {
 "Pflanze":"Pflanze: +18 % Leben", "Gift":"Gift: Angriffe vergiften (8 Schaden/s)",
 "Feuer":"Feuer: +25 % Angriff", "Wasser":"Wasser: +18 Rüstung",
 "Elektro":"Elektro: +25 % Angriffstempo", "Psycho":"Psycho: +35 % Fähigkeitsschaden",
 "Gestein":"Gestein: +30 Rüstung", "Normal":"Normal: +15 % Leben", "Flug":"Flug: +15 % Angriffstempo"
}
var roster: Array = []
var by_id: Dictionary = {}
static var cached: Dictionary = {}
var form_names: Dictionary = {}
var type_chart: Dictionary = {}
var species: Dictionary = {}
var trait_descriptions = JSON.parse_string(FileAccess.get_file_as_string("res://data/traits.json"))

func _init():
 if not cached.is_empty():
  roster = cached.roster
  by_id = cached.by_id
  species = cached.species
  form_names = cached.form_names
  type_chart = cached.type_chart
  return
 form_names = JSON.parse_string(FileAccess.get_file_as_string("res://data/form_names.json"))
 type_chart = JSON.parse_string(FileAccess.get_file_as_string("res://data/type_chart.json"))
 for entry in JSON.parse_string(FileAccess.get_file_as_string("res://data/species_gen1_3.json")):
  species[int(entry.id)] = entry
 roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/roster.json"))
 for entry in roster:
  by_id[int(entry.id)] = entry
 cached = {"roster":roster,"by_id":by_id,"species":species,"form_names":form_names,"type_chart":type_chart}

func get_mon(id: int) -> Dictionary:
 return by_id.get(id, {})

func sprite_id(unit: Dictionary) -> int:
 var mon = get_mon(int(unit.species))
 var index = int(unit.star)-1 if mon.forms.size() == 3 else (1 if mon.forms.size() == 2 and int(unit.star) == 3 else 0)
 return int(mon.forms[index])

func display_name(unit: Dictionary) -> String:
 if unit.get("summon_stage","") == "larva": return "Larve"
 return form_names.get(str(sprite_id(unit)),get_mon(int(unit.species)).name)

func combat_types(unit: Dictionary) -> Array:
 return species[sprite_id(unit)].types

static func distance(a: Vector2i,b: Vector2i) -> int:
 return absi(a.x-b.x)+absi(a.y-b.y)

func effectiveness(attack_type: String,unit: Dictionary) -> float:
 var multiplier = 1.0
 for type in combat_types(unit):
  multiplier *= float(type_chart[attack_type][type])
 return multiplier

func synergy_modifiers(_unit: Dictionary,_counts: Dictionary) -> Dictionary:
 return {} # Stateful effects are applied by the battle's trait controller.

func trait_text(type: String) -> String:
 var info = trait_descriptions[type]
 return "%s — %s\n2: %s\n4: %s\n6: %s\n8: %s" % [type,info[0],info[1],info[2],info[3],info[4]]

func synergies(units: Array) -> Dictionary:
 var seen = {}
 var counts = {}
 for unit in units:
  if unit.get("zone","board") != "board":
   continue
  var id = int(unit.species)
  if not seen.has(id) or int(unit.star) > int(seen[id].star):
   seen[id] = unit
 for unit in seen.values():
  for type in combat_types(unit):
   counts[type] = int(counts.get(type, 0)) + 1
 return counts

func stats(unit: Dictionary) -> Dictionary:
 var mon = get_mon(int(unit.species))
 var multiplier = [1.0, 1.8, 3.24][int(unit.star) - 1]*float(unit.get("training",1.0))
 var extra = STAR3[int(mon.cost)-1] if int(unit.star) == 3 else [1.0,1.0,1.0]
 return {"hp":int(mon.hp * multiplier*extra[0]), "attack":int(mon.attack * multiplier*extra[1]), "armor":int(mon.armor), "power":int(mon.power * multiplier*extra[2])}

func ability_text(unit: Dictionary) -> String:
 var mon = get_mon(int(unit.species))
 return "%s · %d Mana\n%s\nFähigkeitsstärke: %d" % [mon.ability,int(mon.mana),mon.description,stats(unit).power]

func evolution_text(unit: Dictionary) -> String:
 var lines = []
 for star in [1,2,3]:
  var form = {"species":unit.species,"star":star}
  lines.append("%d★ %s: %s" % [star,display_name(form)," / ".join(combat_types(form))])
 return "\n".join(lines)
