import json,pathlib,re
P=pathlib.Path(__file__).resolve().parents[1]
def read(name): return json.loads((P/name).read_text(encoding='utf-8'))
R=read('data/roster.json'); A=read('data/augments.json'); N=read('data/form_names.json')
def write(name,text): (P/name).write_text(text,encoding='utf-8')
odds=[[100,0,0,0,0],[80,20,0,0,0],[65,30,5,0,0],[50,35,15,0,0],[35,35,23,7,0],[25,30,25,17,3],[18,25,27,23,7],[12,20,28,25,15],[8,15,25,32,20],[5,10,25,35,25]]
table='| Level | 1 Gold | 2 Gold | 3 Gold | 4 Gold | 5 Gold |\n|---|---:|---:|---:|---:|---:|\n'+''.join('| '+str(i+1)+' | '+' | '.join(str(x)+' %' for x in row)+' |\n' for i,row in enumerate(odds))
aug='# Alle 52 Augments — Version 3\n\nVor Runde 5, 12 und 20 werden drei verschiedene, noch nicht gewählte Boni angeboten. Genau eine Auswahl je Meilenstein; sie wird mit den Angeboten gespeichert. Eine Niederlage wiederholt die Auswahl nicht. Alle Boni sind nicht stapelbar. Rollen-, Typ- und Aufstellungsboni werden nur angeboten, wenn das aktuelle Feld sie nutzen kann. EP-Boni entfallen auf Level 10; Niederlagenprämie bei nur einem Leben.\n\nPositionsbedingungen gelten beim Kampfstart, danach bleibt der Bonus für diesen Kampf erhalten. Prozente addieren sich innerhalb desselben Modifikators. Angriffs- und Zauberheilung basieren auf tatsächlichem Lebensverlust nach Rüstung, Effektivität und Schild. Zusatztreffer lösen keine weiteren Zusatztreffer aus.\n\n| Nr. | Augment | Konkreter Effekt |\n|---:|---|---|\n'
aug+=''.join(f'| {i+1} | {a["name"]} | {a["description"]} |\n' for i,a in enumerate(A))
write('docs/AUGMENTS.md',aug)
dist='| Kosten | Linien |\n|---|---:|\n'+''.join(f'| {c} Gold | {sum(m["cost"]==c for m in R)} |\n' for c in range(1,6))
roster='# Roster: 70 kaufbare Entwicklungslinien\n\n'+dist+'\nDie vollständige Auswahlgrundlage enthält alle 386 Pokémon aus Generation 1–3 (100 aus Gen 2, 135 aus Gen 3). Entwicklungsformen und Verzweigungen werden nicht als zusätzliche Shop-Einheiten geführt. Angegeben ist jeweils eine eindeutige Linie innerhalb dieser Generationen; spätere Babyformen und Entwicklungen, Regional- oder Megaformen gehören nicht zum Roster. Myrapla führt zu Giflor, Ralts/Trasla zu Guardevoir.\n\nDrei Formen: Basis / Mitte / Ende auf Stern 1 / 2 / 3. Zwei Formen: Basis / Basis / Ende. Eine Form: gleiches Aussehen. Leben, Angriff und Fähigkeit skalieren auf 1 / 1,8 / 3,24. Pokémon-Typen folgen der dargestellten Form. Angriffstyp und Fähigkeitstyp bleiben pro Linie explizit festgelegt.\n\n| Basis | Gen. | Gold | Formen | Rolle | Reichw. | Mana | Fähigkeit |\n|---|---:|---:|---|---|---:|---:|---|\n'
roster+=''.join(f'| {m["name"]} | {m["generation"]} | {m["cost"]} | '+ ' → '.join(N[str(f)] for f in m['forms'])+f' | {m["role"]} | {m["range"]} | {m["mana"]} | {m["ability"]} |\n' for m in R)
roster+='\n## Werte und Angriffstypen auf einem Stern\n\n| Pokémon | LP | Angriff | Rüstung | Stärke | Angriffstakt (Ticks) | Angriffstyp | Fähigkeitstyp |\n|---|---:|---:|---:|---:|---:|---|---|\n'
roster+=''.join(f'| {m["name"]} | {m["hp"]} | {m["attack"]} | {m["armor"]} | {m["power"]} | {m["interval"]} | {m["attack_type"]} | {m["ability_type"]} |\n' for m in R)
write('docs/ROSTER.md',roster)
overview='''# Pokémon-Auto-Battler — Erweiterung V3

Stand: 2026-09-09. Bestehendes Godot-Spiel erweitert; keine neue Engine und keine Internetpflicht beim Spielen.

- 30 Siege schließen die Expedition ab. Start mit 3 Leben. Eine Niederlage kostet genau ein Leben und wiederholt dieselbe Runde gegen denselben Gegner. Nach 0 Leben ist Schluss.
- Level 10 ist das Maximum. Start auf Level 3; jeder vierte Fortschrittsschritt erhöht das Mindestlevel: 4/5/6/7/8/9/10 ab Runde 5/9/13/17/21/25/29. EP-Käufe ermöglichen frühere Aufstiege.
- Genau 70 Linien, davon zehn legendäre oder mysteriöse 5-Gold-Einheiten. 140 passende Sprites werden lokal geladen. Sterne und Namen folgen den Formregeln.
- Kostenfarbene Karten mit explizitem Preis. Vollständig entwickelte Linien werden dauerhaft gesperrt, auch nach Verkauf. Bereits reservierte Angebote dieser Linie werden ersetzt, selbst in einem gesperrten Shop.
- Beim Kampfstart füllt die Bank in aufsteigender Platzreihenfolge das Team bis zum Spielerlevel auf. Bereits platzierte Figuren bleiben stehen.
- Reichweite wird als Zahl und beim Überfahren/Auswählen als Tile-Markierung gezeigt. Bewegung, Ziele und Vorschau nutzen Manhattan-Distanz ohne Diagonalen. Fähigkeitstypen und besondere Zielbereiche sind in den Details bzw. deren Tooltip erklärt.
- Alle 18 Typen haben Synergien bei zwei und vier verschiedenen aufgestellten Linien. Die rechte Übersicht zeigt Anzahlen, beide Bonusstärken, aktive Stufe und fehlende Einheiten. Bei mehreren Formen derselben Linie zählt die höchste Sternstufe einmal. Bankfiguren zählen nicht.
- 52 wirksame Augments; Auswahl vor Runde 5/12/20. Die gewählten Boni sind ständig sichtbar. Angebote, Wahl und Meilensteine werden gespeichert.
- Vollständige moderne Typentabelle: 2×, 0,5× und 0×, multipliziert für beide Verteidigertypen (auch 4× bzw. 0,25×). Normale Angriffe und Fähigkeiten besitzen eigene explizite Angriffstypen. Immunitäten umgehen weder Schild noch Lebenspunkte und erzeugen kein Schadensmana. Gift-/Brand-Status und ausdrücklich direkter Dornenschaden sind separate direkte Schadenseffekte.
- Zinsen: min(5, floor(Gold vor Auszahlung / 10)). Gold, erwartete Zinsen und nächste Schwelle stehen im Interface. Die letzte Auszahlung wird in Basis, Fortschritt, Zins, Ergebnis und Augments zerlegt. Eine Kampf-ID verhindert doppelte Auszahlung oder doppelten Lebensverlust. Ein erneuter echter Kampf derselben Runde bekommt eine neue ID.

## Shop-Wahrscheinlichkeiten

'''+table+'''
Jede Zeile ergibt 100 %. Auf Level 10 sind es genau 25 % für 5-Gold-Angebote. Die Verteilung gilt bei verfügbaren Linien aller vorgesehenen Stufen; ausverkaufte/gesperrte Stufen werden ausgenommen und die restlichen Gewichte normiert. Wenn keine normalerweise erreichbare Stufe verfügbar ist, wird eine andere verfügbare Stufe genutzt. Nur bei vollständig ausgeschöpftem Gesamtangebot bleibt ein Platz leer.

## Roster-Verteilung

'''+dist+'\nDie zehn 5-Gold-Einheiten sind '+', '.join(m['name'] for m in R if m['cost']==5)+'.\n\nDie vollständigen Listen liegen in [ROSTER.md](ROSTER.md) und [AUGMENTS.md](AUGMENTS.md). Alle 52 Augments sind dort mit konkreten Werten aufgeführt. Formeln und sämtliche Fähigkeitseffekte: [BALANCING.md](BALANCING.md). Prüfungen und Grenzen: [TESTBERICHT.md](TESTBERICHT.md).\n'
write('docs/V3-UEBERSICHT.md',overview)
balance='''# Balancing und tatsächliche Effekte — V3

## Expedition und Wirtschaft

30 Siege, 3 Leben. Niederlage: genau −1 Leben, gleiche Runde, gleicher Gegner/Seed. Wiederholungen erlauben neue Einkäufe und Aufstellungen. Gleichstand nach 120 Sekunden: keine Auszahlung, keine EP, kein Gratis-Shopwechsel und kein Lebensverlust.

EP-Kosten für den nächsten Level 1–9: 2, 4, 6, 10, 16, 22, 28, 36, 44. Startlevel 3. Sieg +3 EP, Niederlage +2 EP, Einkauf 4 EP für 4 Gold. Mindestlevel steigt alle vier Runden; vorhandene EP bleiben erhalten. Auf Level 10 werden EP auf 0 begrenzt.

Auszahlung: 7 Basisgold + floor((abgeschlossene Rundennummer−1)/5) Fortschrittsgold + min(5,floor(Gold vor Auszahlung/10)) Zinsen + Ergebnisbonus + gewählte Wirtschaftsaugments. Ergebnisbonus: Sieg 2 + min(3,floor(Siegesserie/3)); Niederlage 3. Augments sind separat ausgewiesen, verändern nicht die Zinsformel. Pro gewertetem Kampf genau eine Auszahlung.

Pro Linie 18 Exemplare. Jede Shopkarte reserviert eines. Merge erhält die Exemplarmenge, Verkauf gibt 1/3/9 Exemplare zurück. Eine vollständig entwickelte Linie bleibt trotzdem ausgeschlossen. Rabattierte Käufe verkaufen sich zum regulären Linienwert.

## Gegnerkurve

Teamgröße min(10, 2 + floor((Runde−1)/3)). Ab Runde 7 wird eine frühe Figur zweisternig; alle fünf Runden eine weitere. Ab Runde 11 ergänzt eine Kosten-4-Linie, ab Runde 16 eine legendäre Linie. Ab Runde 26 erhält die erste frühe Figur drei Sterne, ab Runde 30 die zweite. Premium-Gegner werden ab Runde 27 zweisternig. Front-/Rückpositionen folgen Rolle und Reichweite. Unterschiedliche Themen mischen Generationen und Typen; Runde 30 stellt zehn Gegner mit zwei frühen Dreisternen und stärkeren Premium-Einheiten auf.

## Kampf

10 Ticks/s, maximal 1200 Ticks. Schaden = floor(Rohschaden × Typenfaktor × bedingte Augment-Multiplikatoren × 100/(100+Rüstung)); bei positiver Effektivität mindestens 1, bei Immunität exakt 0. Rüstungsbruch zieht 18 Rüstung ab, mindestens 0. Schilde absorbieren zuerst. Heilung endet am maximalen Leben. Statusdauern werden in Ticks angegeben; Schaden über Zeit tickt sekündlich. Slow: Takt ×1,5; Haste: Takt /1,35. Temporäre Status gleicher Art werden zeitlich verlängert, nicht gestapelt.

Mana je Angriff / Schadenstreffer / Sekunde: Tank 8 / 18 plus bis zu 12 nach verlorenem LP-Anteil / 0; Angreifer 23 / 4 / 0; Magier 12 / 6 / 5; Unterstützer 5 / 5 / 9. Vollständig absorbierte und immune Treffer geben kein Schadensmana. Augments ergänzen diese Werte. Die Fähigkeit verbraucht ihr individuelles Manalimit.

Manhattan-Reichweite. Unterstützer dürfen volle Fähigkeiten unabhängig von Gegnerdistanz auslösen; andere Rollen brauchen ein Ziel in ihrer Angriffsreichweite. Hauptziel: gewählter Gegner. Schwächstes Ziel: niedrigster relativer LP-Anteil, UID als Gleichstandsauflösung. Fläche: Radius 1 um Hauptziel; nahe Gegner: Radius 2 um Anwender; Kette: nach Entfernung zum Hauptziel sortiert. Globale/Ally-/Ketteneffekte haben nach Auslösung kein zusätzliches Reichweitenlimit.

## Shop

'''+table+'\n## Alle Fähigkeitseffekte\n\nMultiplikatoren beziehen sich auf die Fähigkeitsstärke der Sternstufe. Wiederholte Schaden-Einträge sind mehrere Treffer. `amount` bei Mana ist ein fixer Wert. `duration` ist in Ticks (10 = 1 Sekunde). Zielbereiche sind oben erklärt.\n\n'
for m in R:
 balance+=f'### {m["name"]}: {m["ability"]} — {m["mana"]} Mana, Typ {m["ability_type"]}\n\n'
 balance+='; '.join(f'{e["kind"]} → {e["target"]}: '+(str(e['amount'])+' Mana' if e['kind']=='mana' else str(e.get('scale',1))+' × Stärke' if e['kind'] in ['damage','heal','shield','poison','burn'] else '')+(f', {e["duration"]} Ticks' if 'duration'in e else '')+(f', {e["count"]} Ziele' if 'count'in e else '') for e in m['effects'])+'.\n\n'
write('docs/BALANCING.md',balance)
write('README.md','''# Poké Tactics — Drei Regionen, Version 3

Privater Pokémon-Auto-Battler in Godot mit 70 kaufbaren Entwicklungslinien, 30 Siegrunden, 3 Leben, Level 10 und 52 Augments. Lokale 8-Bit-Schrift VT323, Pixel-Sprites, Drag-and-drop und sichtbare Kampfeffekte bleiben erhalten.

## Starten

Im Projektordner **Starten.cmd** doppelklicken. Ein bereits geöffnetes Spiel vorher schließen, damit das aktualisierte Paket geladen wird.

Auf einem anderen Windows-Rechner **dist/PokeTactics-Windows.zip** vollständig entpacken und **PokeTactics.exe** starten. EXE und PCK bleiben zusammen. Keine separate Godot-Installation, kein Konto, keine Internetverbindung und keine Administratorrechte erforderlich. Windows x64 / OpenGL 3.3. Das Fenster startet mit 1600 × 800; Vergrößern oder F11 verbessert die Darstellung auf großen Bildschirmen.

## Spielen

- Karte anklicken: kaufen. Pokémon zwischen Bank und Feld ziehen; belegte Plätze tauschen. Ungültiges Loslassen, Esc und Fokusverlust brechen sicher ab. Beim Kampfstart werden freie Teamplätze automatisch aus der Bank besetzt.
- Drei Exemplare derselben Linie und Sternstufe verschmelzen. Drei Formen: Basis/Mitte/Ende; zwei Formen: Basis/Basis/Ende. Bei drei Sternen ist die Linie für den Rest der Partie aus dem Shop ausgeschlossen, auch nach Verkauf.
- Nur Siege erhöhen die Runde. Niederlage: ein Leben weniger, gleicher Gegner und gleiche Runde. Nach 30 Siegen gewonnen, nach drei Niederlagen beendet. Gleichstand gewährt keine Ressourcen.
- Vor Runde 5, 12 und 20 einen von drei Augments wählen. Gewählte Boni und alle Team-Synergien stehen dauerhaft rechts. Zwei/vier unterschiedliche Linien aktivieren die jeweilige Bonusstufe.
- Figur auswählen oder überfahren: Angriffsreichweite. Details zeigen Rolle, Mana, Angriffs- und Fähigkeitstyp; der Fähigkeitstooltip erklärt Zielbereiche. Sehr effektive Treffer, Resistenzen und Immunitäten erscheinen im Kampf.
- Leertaste: Kampf/Pause · R: Shop erneuern · E: EP kaufen · Entf: ausgewählte Figur verkaufen · Esc/Rechtsklick: Auswahl/Ziehen abbrechen · F1: Hilfe · F11: Vollbild.

## Übersichten

[Alle Änderungen und Shop-Wahrscheinlichkeiten](docs/V3-UEBERSICHT.md) · [70 Linien und Werte](docs/ROSTER.md) · [Alle 52 Augments mit konkreten Effekten](docs/AUGMENTS.md) · [Balancing und Fähigkeiten](docs/BALANCING.md) · [Prüfbericht](docs/TESTBERICHT.md).

## Speichern und Entwicklung

Automatische Speicherung nach erfolgreichen Aktionen unter `%APPDATA%/PokeTactics/match.json`. Alte V1-/V2-Spielstände werden vor Übernahme als `.pre-v3-backup` gesichert. Vorhandene Linien werden auf die neuen Basiseinheiten abgebildet; abgeschlossene Dreisterne bleiben gesperrt. Bereits erreichte Augment-Meilensteine werden einmalig nachgeholt. V2 behält vorhandene Leben; V1 startet nach Migration mit drei Leben. Alte Siege werden in die 30-Runden-Expedition übernommen. Beschädigte Dateien werden zur Wiederherstellung gesichert.

**Editor.cmd** öffnet den Quellcode. Tests: `tests/test_core.gd`, `tests/test_v3.gd`, `tests/test_ui.gd` mit Godot `--headless --path . --script res://tests/DATEI.gd`. Build: `powershell -ExecutionPolicy Bypass -File tools/build.ps1`.

Das unabhängige Spielmodell, deterministische Kampfereignisse und versionierte Snapshots bleiben als Multiplayer-Grundlage erhalten. LAN/Online, Lobby und Netzwerktransport sind weiterhin nicht implementiert. Kein Audio, keine Items. Medienquellen und Lizenzen: [MEDIEN.md](docs/MEDIEN.md).
''')
print('Generated V3 overview, roster, augment and balancing documentation')
