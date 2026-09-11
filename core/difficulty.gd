extends RefCounted
const SETTINGS = {
 "Leicht":{"base":0.84,"growth":0.004,"promotion":9,"step":5,"elite":28,"premium":19,"extra":0,"text":"Schwächere Werte, spätere Entwicklungen und Legendäre. Einfachere Teams mit weniger Kontrolle."},
 "Normal":{"base":1.04,"growth":0.007,"promotion":5,"step":4,"elite":25,"premium":15,"extra":0,"text":"Stärkere Werte, frühe Synergien und geschützte Heiler. Entwicklungen wachsen stetig; stärkere Kontrollfähigkeiten im späteren Team."},
 "Schwer":{"base":1.15,"growth":0.010,"promotion":4,"step":3,"elite":22,"premium":12,"extra":1,"text":"Größere frühe Teams, frühere Entwicklungen und Legendäre. Verstärkte Front, Heilung und Kontrollketten."}
}
const THEMES = [
 [7,194,258,170,270,131,120,54,245,249],
 [218,255,4,58,155,303,113,147,244,146],
 [285,1,152,252,315,43,187,302,151,384],
 [95,304,81,227,204,303,143,302,150,249]
]

static func team(catalog,seed_value: int,round_no: int,difficulty: String) -> Array:
 var setting = SETTINGS[difficulty]
 # Keep a themed trainer for five rounds, rotating deterministically between regions.
 var theme = THEMES[posmod(seed_value+int((round_no-1)/5),THEMES.size())].map(func(id): return catalog.REPLACEMENTS.get(id,id))
 var count = mini(10,2+int((round_no-1)/3)+int(setting.extra))
 var result = []
 var occupied = {}
 for i in range(count):
  var id = theme[i]
  if difficulty == "Leicht" and i == 3:
   id = [54,37,43,74][posmod(seed_value+int((round_no-1)/5),4)]
  if round_no >= setting.premium and i == count-1:
   id = theme[8]
  if round_no >= setting.premium+8 and i == count-2:
   id = theme[9]
  # Never duplicate a line after substituting the premium slots.
  if result.any(func(u): return u.species == id):
   for alternative in theme:
    if not result.any(func(u): return u.species == alternative):
     id = alternative
     break
  id = catalog.REPLACEMENTS.get(id,id)
  var mon = catalog.get_mon(id)
  var row = 2 if mon.role == "Unterstützer" else (0 if mon.role == "Tank" or mon.range == 1 else 1)
  var slot = row*7+[3,2,4,1,5,0,6,3,2,4][i]
  if occupied.has(slot):
   for column in [3,2,4,1,5,0,6]:
    if not occupied.has(row*7+column):
     slot = row*7+column
     break
  while occupied.has(slot): slot = (slot+1)%21
  occupied[slot] = true
  var promoted = 0 if round_no < setting.promotion else 1+int((round_no-setting.promotion)/setting.step)
  var star = 2 if i < promoted and mon.cost <= 3 else 1
  if round_no >= setting.elite and i < 1+int((round_no-setting.elite)/4):
   star = 3
  if mon.cost >= 4 and round_no >= setting.premium+11:
   star = 2
  result.append({"uid":i+1,"species":id,"star":star,"slot":slot,"zone":"board","training":float(setting.base)+round_no*float(setting.growth)})
 return result
