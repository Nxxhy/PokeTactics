# Pokémon-Auto-Battler — Erweiterung V3

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

| Level | 1 Gold | 2 Gold | 3 Gold | 4 Gold | 5 Gold |
|---|---:|---:|---:|---:|---:|
| 1 | 100 % | 0 % | 0 % | 0 % | 0 % |
| 2 | 80 % | 20 % | 0 % | 0 % | 0 % |
| 3 | 65 % | 30 % | 5 % | 0 % | 0 % |
| 4 | 50 % | 35 % | 15 % | 0 % | 0 % |
| 5 | 35 % | 35 % | 23 % | 7 % | 0 % |
| 6 | 25 % | 30 % | 25 % | 17 % | 3 % |
| 7 | 18 % | 25 % | 27 % | 23 % | 7 % |
| 8 | 12 % | 20 % | 28 % | 25 % | 15 % |
| 9 | 8 % | 15 % | 25 % | 32 % | 20 % |
| 10 | 5 % | 10 % | 25 % | 35 % | 25 % |

Jede Zeile ergibt 100 %. Auf Level 10 sind es genau 25 % für 5-Gold-Angebote. Die Verteilung gilt bei verfügbaren Linien aller vorgesehenen Stufen; ausverkaufte/gesperrte Stufen werden ausgenommen und die restlichen Gewichte normiert. Wenn keine normalerweise erreichbare Stufe verfügbar ist, wird eine andere verfügbare Stufe genutzt. Nur bei vollständig ausgeschöpftem Gesamtangebot bleibt ein Platz leer.

## Roster-Verteilung

| Kosten | Linien |
|---|---:|
| 1 Gold | 16 |
| 2 Gold | 16 |
| 3 Gold | 16 |
| 4 Gold | 12 |
| 5 Gold | 10 |

Die zehn 5-Gold-Einheiten sind Arktos, Zapdos, Lavados, Mewtu, Mew, Raikou, Entei, Suicune, Lugia, Rayquaza.

Die vollständigen Listen liegen in [ROSTER.md](ROSTER.md) und [AUGMENTS.md](AUGMENTS.md). Alle 52 Augments sind dort mit konkreten Werten aufgeführt. Formeln und sämtliche Fähigkeitseffekte: [BALANCING.md](BALANCING.md). Prüfungen und Grenzen: [TESTBERICHT.md](TESTBERICHT.md).
