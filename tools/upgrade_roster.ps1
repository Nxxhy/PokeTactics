$ErrorActionPreference = 'Stop'
$file = Join-Path $PSScriptRoot '..\data\roster.json'
$roster = @(Get-Content -Raw $file | ConvertFrom-Json)
$details = @'
[
 [1,"Unterstützer",65,"Egelsamen","Entzieht dem nächsten Gegner Kraft und heilt den schwächsten Verbündeten.",100,620,46,22,12,[{"kind":"damage","target":"enemy","scale":1},{"kind":"heal","target":"weak_ally","scale":1.4}]],
 [4,"Angreifer",60,"Glut","Trifft einen Gegner und verbrennt ihn 4 Sekunden lang.",120,550,62,15,11,[{"kind":"damage","target":"enemy","scale":1},{"kind":"burn","target":"enemy","duration":40,"scale":0.15}]],
 [7,"Tank",75,"Panzerschutz","Erhält einen Schild und trifft den Gegner mit einem Wasserstoß.",145,820,40,38,14,[{"kind":"shield","target":"self","scale":1.4},{"kind":"damage","target":"enemy","scale":0.7}]],
 [25,"Angreifer",80,"Kettenblitz","Ein Blitz springt auf bis zu 3 Gegner und betäubt sie kurz.",155,580,69,16,10,[{"kind":"damage","target":"chain","count":3,"scale":0.8},{"kind":"stun","target":"chain","count":3,"duration":5}]],
 [37,"Magier",90,"Feuerwirbel","Flächenschaden um das Ziel; getroffene Gegner brennen 5 Sekunden.",180,610,54,18,12,[{"kind":"damage","target":"area","scale":0.8},{"kind":"burn","target":"area","duration":50,"scale":0.12}]],
 [43,"Unterstützer",55,"Heilpollen","Heilt den schwächsten Verbündeten und vergiftet den nächsten Gegner.",115,570,39,18,13,[{"kind":"heal","target":"weak_ally","scale":1.6},{"kind":"poison","target":"enemy","duration":50,"scale":0.18}]],
 [54,"Magier",60,"Aquawelle","Eine Wasserwelle trifft das Zielgebiet und verlangsamt 3 Sekunden.",130,700,49,24,12,[{"kind":"damage","target":"area","scale":0.9},{"kind":"slow","target":"area","duration":30}]],
 [63,"Magier",75,"Psychokinese","Hoher Einzelschaden am Gegner mit dem geringsten Lebensanteil.",245,480,58,12,13,[{"kind":"damage","target":"weak_enemy","scale":1.4}]],
 [66,"Angreifer",55,"Karateschlag","Bricht 18 Rüstung für 5 Sekunden und trifft danach hart.",145,850,65,28,12,[{"kind":"break","target":"enemy","duration":50},{"kind":"damage","target":"enemy","scale":1.2}]],
 [74,"Tank",65,"Felswacht","Schützt sich mit einem Schild und zieht nahe Gegner 3 Sekunden auf sich.",185,970,43,45,15,[{"kind":"shield","target":"self","scale":1.6},{"kind":"taunt","target":"near_enemies","duration":30}]],
 [81,"Tank",85,"Magnetfeld","Schützt den schwächsten Verbündeten; lähmt und trifft zwei Gegner.",160,740,52,40,13,[{"kind":"shield","target":"weak_ally","scale":1.1},{"kind":"damage","target":"chain","count":2,"scale":0.8},{"kind":"stun","target":"chain","count":2,"duration":8}]],
 [92,"Magier",70,"Nachtmahr","Spukschaden am schwächsten Gegner und 4 Sekunden Gift.",205,540,58,14,12,[{"kind":"damage","target":"weak_enemy","scale":1.1},{"kind":"poison","target":"weak_enemy","duration":40,"scale":0.16}]],
 [95,"Tank",100,"Erdbeben","Trifft alle Gegner im Umkreis von 2 Feldern und betäubt 1,4 Sekunden.",240,1500,60,55,15,[{"kind":"damage","target":"near_enemies","scale":1},{"kind":"stun","target":"near_enemies","duration":14}]],
 [120,"Unterstützer",80,"Sternenlicht","Heilt den schwächsten Verbündeten; alle anderen Verbündeten erhalten 15 Mana.",150,650,51,22,11,[{"kind":"heal","target":"weak_ally","scale":1.7},{"kind":"mana","target":"other_allies","amount":15}]],
 [143,"Tank",110,"Erholung","Heilt sich stark und zieht nahe Gegner 2 Sekunden auf sich.",290,1650,71,35,16,[{"kind":"heal","target":"self","scale":2},{"kind":"taunt","target":"near_enemies","duration":20}]]
]
'@ | ConvertFrom-Json
foreach ($row in $details) {
 $mon = $roster | Where-Object { $_.id -eq $row[0] }
 $keys = @('role','mana','ability','description','power','hp','attack','armor','interval','effects')
 for ($i=0; $i -lt $keys.Count; $i++) { $mon | Add-Member -NotePropertyName $keys[$i] -NotePropertyValue $row[$i+1] -Force }
 $mon.PSObject.Properties.Remove('effect')
}
$new = @'
[
 {"id":131,"name":"Lapras","types":["Wasser","Eis"],"cost":4,"hp":1400,"attack":70,"armor":35,"range":3,"interval":13,"role":"Unterstützer","mana":115,"ability":"Polarlicht","description":"Heilt das gesamte Team; die eisige Welle verlangsamt alle Gegner 3 Sekunden.","power":250,"effects":[{"kind":"heal","target":"all_allies","scale":0.95},{"kind":"slow","target":"all_enemies","duration":30}],"forms":[131,131,131]},
 {"id":59,"name":"Arkani","types":["Feuer"],"cost":4,"hp":1300,"attack":130,"armor":32,"range":1,"interval":10,"role":"Angreifer","mana":95,"ability":"Flammensturm","description":"Verbrennt das Zielgebiet und beschleunigt das Team 4 Sekunden lang.","power":290,"effects":[{"kind":"damage","target":"area","scale":1},{"kind":"burn","target":"area","duration":40,"scale":0.14},{"kind":"haste","target":"all_allies","duration":40}],"forms":[59,59,59]},
 {"id":123,"name":"Sichlor","types":["Käfer","Flug"],"cost":4,"hp":1150,"attack":125,"armor":28,"range":1,"interval":8,"role":"Angreifer","mana":60,"ability":"Kreuzschere","description":"Zwei Schnitte gegen das schwächste Ziel; erhält 4 Sekunden erhöhtes Angriffstempo.","power":210,"effects":[{"kind":"damage","target":"weak_enemy","scale":0.95},{"kind":"damage","target":"weak_enemy","scale":0.95},{"kind":"haste","target":"self","duration":40}],"forms":[123,123,123]},
 {"id":115,"name":"Kangama","types":["Normal"],"cost":4,"hp":1900,"attack":90,"armor":45,"range":1,"interval":13,"role":"Tank","mana":100,"ability":"Familienwacht","description":"Schützt sich und den schwächsten Verbündeten; kontert mit einem harten Schlag.","power":310,"effects":[{"kind":"shield","target":"self","scale":1.3},{"kind":"shield","target":"weak_ally","scale":1.1},{"kind":"damage","target":"enemy","scale":1}],"forms":[115,115,115]},
 {"id":150,"name":"Mewtu","types":["Psycho"],"cost":5,"hp":1250,"attack":98,"armor":30,"range":3,"interval":12,"role":"Magier","mana":140,"ability":"Psychostoß","description":"Bricht die Rüstung aller Gegner für 5 Sekunden und trifft sie mit Psychokraft.","power":430,"effects":[{"kind":"break","target":"all_enemies","duration":50},{"kind":"damage","target":"all_enemies","scale":1.05}],"forms":[150,150,150]},
 {"id":149,"name":"Dragoran","types":["Drache","Flug"],"cost":5,"hp":1800,"attack":145,"armor":40,"range":2,"interval":10,"role":"Angreifer","mana":120,"ability":"Draco Meteor","description":"Ein Meteor trifft das Zielgebiet; der Drache erhält einen mächtigen Schild.","power":450,"effects":[{"kind":"damage","target":"area","scale":1.3},{"kind":"shield","target":"self","scale":1.1}],"forms":[149,149,149]},
 {"id":145,"name":"Zapdos","types":["Elektro","Flug"],"cost":5,"hp":1350,"attack":105,"armor":32,"range":3,"interval":11,"role":"Magier","mana":130,"ability":"Donnergewitter","description":"Vier Blitzschläge treffen verschiedene Gegner und betäuben sie 1,5 Sekunden.","power":410,"effects":[{"kind":"damage","target":"chain","count":4,"scale":1.1},{"kind":"stun","target":"chain","count":4,"duration":15}],"forms":[145,145,145]},
 {"id":242,"name":"Heiteira","types":["Normal"],"cost":5,"hp":2100,"attack":50,"armor":24,"range":3,"interval":15,"role":"Unterstützer","mana":125,"ability":"Vitalglocke","description":"Entfernt negative Status vom Team, heilt alle und schützt den schwächsten Verbündeten.","power":330,"effects":[{"kind":"cleanse","target":"all_allies"},{"kind":"heal","target":"all_allies","scale":1.1},{"kind":"shield","target":"weak_ally","scale":1.2}],"forms":[242,242,242]}
]
'@ | ConvertFrom-Json
$roster = @($roster | Where-Object { $_.id -notin @(131,59,123,115,150,149,145,242) }) + @($new)
$roster | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $file -Encoding utf8
