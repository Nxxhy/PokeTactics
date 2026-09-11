# Balancing und tatsächliche Effekte — V3

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

## Alle Fähigkeitseffekte

Multiplikatoren beziehen sich auf die Fähigkeitsstärke der Sternstufe. Wiederholte Schaden-Einträge sind mehrere Treffer. `amount` bei Mana ist ein fixer Wert. `duration` ist in Ticks (10 = 1 Sekunde). Zielbereiche sind oben erklärt.

### Bisasam: Egelsamen — 65 Mana, Typ Pflanze

damage → enemy: 1 × Stärke; heal → weak_ally: 1.4 × Stärke.

### Glumanda: Glut — 60 Mana, Typ Feuer

damage → enemy: 1 × Stärke; burn → enemy: 0.15 × Stärke, 40 Ticks.

### Schiggy: Panzerschutz — 75 Mana, Typ Wasser

shield → self: 1.4 × Stärke; damage → enemy: 0.7 × Stärke.

### Pichu: Kettenblitz — 80 Mana, Typ Elektro

damage → chain: 0.8 × Stärke, 3 Ziele; stun → chain: , 5 Ticks, 3 Ziele.

### Vulpix: Feuerwirbel — 90 Mana, Typ Feuer

damage → area: 0.8 × Stärke; burn → area: 0.12 × Stärke, 50 Ticks.

### Myrapla: Heilpollen — 55 Mana, Typ Pflanze

heal → weak_ally: 1.6 × Stärke; poison → enemy: 0.18 × Stärke, 50 Ticks.

### Enton: Aquawelle — 60 Mana, Typ Wasser

damage → area: 0.9 × Stärke; slow → area: , 30 Ticks.

### Kleinstein: Felswacht — 65 Mana, Typ Gestein

shield → self: 1.6 × Stärke; taunt → near_enemies: , 30 Ticks.

### Endivie: Aromakur — 85 Mana, Typ Pflanze

heal → all_allies: 0.45 × Stärke; cleanse → all_allies: .

### Feurigel: Flammenrad — 85 Mana, Typ Feuer

damage → area: 1.2 × Stärke; burn → area: 0.12 × Stärke, 40 Ticks.

### Karnimani: Aquaknarre — 65 Mana, Typ Wasser

damage → enemy: 1.6 × Stärke; haste → self: , 40 Ticks.

### Wiesor: Superzahn — 65 Mana, Typ Normal

damage → enemy: 1.8 × Stärke; break → enemy: , 40 Ticks.

### Voltilamm: Donnerwelle — 85 Mana, Typ Elektro

damage → chain: 0.8 × Stärke, 3 Ziele; stun → enemy: , 15 Ticks.

### Geckarbor: Laubklinge — 65 Mana, Typ Pflanze

damage → enemy: 2 × Stärke; heal → self: 0.35 × Stärke.

### Flemmli: Doppelkick — 65 Mana, Typ Kampf

damage → enemy: 1 × Stärke; damage → enemy: 1 × Stärke; haste → self: , 30 Ticks.

### Hydropi: Lehmschuss — 65 Mana, Typ Boden

damage → enemy: 1.3 × Stärke; slow → enemy: , 50 Ticks; shield → self: 0.5 × Stärke.

### Abra: Psychokinese — 75 Mana, Typ Psycho

damage → weak_enemy: 1.4 × Stärke.

### Machollo: Karateschlag — 55 Mana, Typ Kampf

break → enemy: , 50 Ticks; damage → enemy: 1.2 × Stärke.

### Magnetilo: Magnetfeld — 85 Mana, Typ Elektro

shield → weak_ally: 1.1 × Stärke; damage → chain: 0.8 × Stärke, 2 Ziele; stun → chain: , 8 Ticks, 2 Ziele.

### Nebulak: Nachtmahr — 70 Mana, Typ Geist

damage → weak_enemy: 1.1 × Stärke; poison → weak_enemy: 0.16 × Stärke, 40 Ticks.

### Onix: Erdbeben — 100 Mana, Typ Gestein

damage → near_enemies: 1 × Stärke; stun → near_enemies: , 14 Ticks.

### Sterndu: Sternenlicht — 80 Mana, Typ Wasser

heal → weak_ally: 1.7 × Stärke; mana → other_allies: 15 Mana.

### Webarak: Giftfaden — 95 Mana, Typ Gift

poison → enemy: 0.25 × Stärke, 60 Ticks; slow → enemy: , 50 Ticks; damage → enemy: 0.6 × Stärke.

### Lampi: Lichtreserve — 95 Mana, Typ Wasser

heal → weak_ally: 1.8 × Stärke; mana → other_allies: 12 Mana.

### Hoppspross: Schlafpuder — 95 Mana, Typ Pflanze

stun → area: , 20 Ticks; heal → weak_ally: 1.1 × Stärke.

### Felino: Lehmbad — 75 Mana, Typ Boden

shield → self: 1.3 × Stärke; slow → near_enemies: , 40 Ticks.

### Tannza: Stachler — 75 Mana, Typ Boden

damage → near_enemies: 1.3 × Stärke; break → near_enemies: , 50 Ticks.

### Schneckmag: Lavapanzer — 75 Mana, Typ Feuer

shield → self: 1.5 × Stärke; burn → near_enemies: 0.2 × Stärke, 50 Ticks.

### Loturzel: Regentanz — 95 Mana, Typ Wasser

heal → all_allies: 0.55 × Stärke; haste → all_allies: , 30 Ticks.

### Samurzel: Kugelsaat — 75 Mana, Typ Pflanze

damage → chain: 1.2 × Stärke, 3 Ziele.

### Trasla: Gedankenstoß — 95 Mana, Typ Psycho

damage → area: 1.6 × Stärke; break → area: , 40 Ticks.

### Knilz: Pilzfaust — 75 Mana, Typ Kampf

damage → enemy: 1.6 × Stärke; stun → enemy: , 25 Ticks; heal → self: 0.5 × Stärke.

### Relaxo: Erholung — 110 Mana, Typ Normal

heal → self: 2 × Stärke; taunt → near_enemies: , 20 Ticks.

### Chaneira: Vitalglocke — 125 Mana, Typ Normal

cleanse → all_allies: ; heal → all_allies: 1.1 × Stärke; shield → weak_ally: 1.2 × Stärke.

### Sichlor: Kreuzschere — 60 Mana, Typ Käfer

damage → weak_enemy: 0.95 × Stärke; damage → weak_enemy: 0.95 × Stärke; haste → self: , 40 Ticks.

### Yanma: Ultraschall — 85 Mana, Typ Käfer

damage → chain: 1 × Stärke, 3 Ziele; slow → chain: , 40 Ticks, 3 Ziele.

### Kramurx: Nachtflügel — 85 Mana, Typ Unlicht

damage → weak_enemy: 2.2 × Stärke; haste → self: , 40 Ticks.

### Traunfugil: Spukgesang — 105 Mana, Typ Geist

damage → all_enemies: 0.8 × Stärke; break → all_enemies: , 30 Ticks.

### Skorgla: Sandfalle — 85 Mana, Typ Boden

damage → area: 1.4 × Stärke; taunt → near_enemies: , 40 Ticks.

### Snubbull: Knuddler — 85 Mana, Typ Fee

damage → enemy: 2.3 × Stärke; slow → enemy: , 50 Ticks.

### Pottrott: Krafttrick — 85 Mana, Typ Käfer

shield → self: 2.2 × Stärke; poison → near_enemies: 0.2 × Stärke, 60 Ticks.

### Panzaeron: Stahlflügel — 85 Mana, Typ Stahl

damage → near_enemies: 1.6 × Stärke; shield → self: 1.3 × Stärke.

### Makuhita: Wirbelwurf — 85 Mana, Typ Kampf

damage → enemy: 2 × Stärke; stun → enemy: , 30 Ticks; taunt → near_enemies: , 30 Ticks.

### Nasgnet: Blockade — 85 Mana, Typ Gestein

shield → all_allies: 0.7 × Stärke; taunt → near_enemies: , 50 Ticks.

### Stollunior: Eisenschädel — 85 Mana, Typ Stahl

damage → enemy: 2.1 × Stärke; stun → enemy: , 25 Ticks.

### Frizelbliz: Funkensprung — 85 Mana, Typ Elektro

damage → chain: 1.25 × Stärke, 4 Ziele; haste → self: , 30 Ticks.

### Roselia: Blütenkur — 105 Mana, Typ Pflanze

heal → all_allies: 0.7 × Stärke; poison → area: 0.2 × Stärke, 50 Ticks.

### Zwirrlicht: Nachtnebel — 105 Mana, Typ Geist

damage → area: 1.4 × Stärke; slow → area: , 60 Ticks.

### Lapras: Polarlicht — 115 Mana, Typ Wasser

heal → all_allies: 0.95 × Stärke; slow → all_enemies: , 30 Ticks.

### Fukano: Flammensturm — 95 Mana, Typ Feuer

damage → area: 1 × Stärke; burn → area: 0.14 × Stärke, 40 Ticks; haste → all_allies: , 40 Ticks.

### Kangama: Familienwacht — 100 Mana, Typ Normal

shield → self: 1.3 × Stärke; shield → weak_ally: 1.1 × Stärke; damage → enemy: 1 × Stärke.

### Dratini: Draco Meteor — 120 Mana, Typ Drache

damage → area: 1.3 × Stärke; shield → self: 1.1 × Stärke.

### Skaraborn: Vielender — 95 Mana, Typ Käfer

damage → enemy: 3 × Stärke; break → enemy: , 50 Ticks.

### Larvitar: Sandsturm — 95 Mana, Typ Gestein

damage → all_enemies: 1 × Stärke; shield → self: 1.2 × Stärke.

### Zobiris: Trickschutz — 115 Mana, Typ Unlicht

cleanse → all_allies: ; shield → all_allies: 0.8 × Stärke; mana → weak_ally: 30 Mana.

### Flunkifer: Eisenkiefer — 95 Mana, Typ Stahl

damage → enemy: 2.5 × Stärke; heal → self: 1 × Stärke.

### Knacklion: Erdwelle — 95 Mana, Typ Boden

damage → area: 2 × Stärke; break → area: , 60 Ticks.

### Wablu: Himmelslied — 115 Mana, Typ Normal

heal → all_allies: 0.8 × Stärke; haste → all_allies: , 50 Ticks.

### Absol: Unheilsklinge — 95 Mana, Typ Unlicht

damage → weak_enemy: 3.2 × Stärke.

### Kindwurm: Drachensturz — 95 Mana, Typ Drache

damage → area: 2.1 × Stärke; haste → self: , 50 Ticks.

### Arktos: Eisorkan — 125 Mana, Typ Eis

damage → all_enemies: 1.4 × Stärke; slow → all_enemies: , 60 Ticks.

### Zapdos: Donnergewitter — 130 Mana, Typ Elektro

damage → chain: 1.1 × Stärke, 4 Ziele; stun → chain: , 15 Ticks, 4 Ziele.

### Lavados: Läuterfeuer — 125 Mana, Typ Feuer

damage → area: 2 × Stärke; burn → all_enemies: 0.18 × Stärke, 60 Ticks.

### Mewtu: Psychostoß — 140 Mana, Typ Psycho

break → all_enemies: , 50 Ticks; damage → all_enemies: 1.05 × Stärke.

### Mew: Lebensfunke — 125 Mana, Typ Psycho

heal → all_allies: 1 × Stärke; cleanse → all_allies: ; mana → other_allies: 25 Mana.

### Raikou: Donnerjagd — 105 Mana, Typ Elektro

damage → chain: 1.7 × Stärke, 5 Ziele; haste → self: , 60 Ticks.

### Entei: Vulkanwacht — 105 Mana, Typ Feuer

damage → near_enemies: 2 × Stärke; shield → self: 2 × Stärke; taunt → near_enemies: , 60 Ticks.

### Suicune: Auroraschutz — 125 Mana, Typ Wasser

shield → all_allies: 1 × Stärke; heal → all_allies: 0.7 × Stärke; slow → all_enemies: , 30 Ticks.

### Lugia: Luftwall — 105 Mana, Typ Psycho

damage → all_enemies: 1 × Stärke; shield → all_allies: 1 × Stärke; stun → area: , 20 Ticks.

### Rayquaza: Zenitsturm — 105 Mana, Typ Drache

damage → all_enemies: 1.5 × Stärke; damage → enemy: 2 × Stärke; haste → self: , 40 Ticks.

