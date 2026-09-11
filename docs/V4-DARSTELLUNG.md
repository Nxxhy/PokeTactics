# Version 4: Pixel-Lichtung und feste 2,5D-Perspektive

Das Kampffeld wird als Trapez projiziert. Sieben Spalten und sechs Reihen behalten ihre Spielkoordinaten. Tile-Polygone, Reichweiten, Vorschauen, Bodeneffekte und Spritepositionen verwenden dieselbe Projektion. Die Kamera bleibt statisch. Himmel, langsam ziehende Pixelwolken, Hügel, Bäume und Gras bilden getrennte Ebenen. Die Landschaft wird im Spiel gezeichnet; es wurden keine fremden Hintergrundbilder übernommen.

Pokémon bleiben scharfe, proportional skalierte Sprites mit Bodenanker und Schatten. Im Kampf bestimmt die interpolierte Tiefe die Zeichenreihenfolge. Flache Namensschilder, feste Sternabzeichen und Balken sichern die Lesbarkeit bei Überdeckungen. Geschosse fliegen vom Ausgangspunkt zum Ziel; Feuer, Elektro sowie ringförmige und kreuzförmige Fähigkeiten unterscheiden sich. Heilung und Flächeneffekte erscheinen zusätzlich auf dem Boden. Es gibt keine Kamerafahrten oder blockierenden Animationen.

Shop, Bank und Trainerinformationen bleiben eine flache Oberfläche. Native Fenstergröße statt hochskalierter Leinwand verhindert schwarze Balken. Die Anordnung wechselt zwischen zwei und drei Spalten. Unterstützte Mindestgröße: 1280 × 720. F11 schaltet Vollbild um.

## Bedienung und Schrift

Manuelles Bewegen erfolgt ausschließlich durch Ziehen, per Maus oder Touch. Ein Klick zeigt Details und Reichweite. Ungültige Ziele, veraltete Aktionen, Esc und Fokusverlust verändern keine Einheiten. Größenwechsel während eines Ziehvorgangs behalten dessen Ursprung bei und berechnen die Ziele neu. Freie Plätze werden beim Kampfstart weiterhin automatisch von der Bank aufgefüllt.

Pixelify Sans für Überschriften, Atkinson Hyperlegible für Beschreibungen und Zahlen; beide lokal enthalten. Die Pixeloptik der Rahmen und Symbole bleibt erhalten. Rabatte zeigen Originalpreis mit Streichlinie, tatsächlichen Kaufpreis und Rabattgrund.

## Gegner und Spielregeln

Vor einer neuen Partie sind Leicht, Normal und Schwer wählbar. Gegner verwenden thematische Teams mit Synergien, Unterstützern im Hinterfeld, zunehmenden Sternstufen und späteren Premium-Pokémon. Normal startet bei 1,04 + Runde × 0,007 als Trainingsfaktor; Leicht bei 0,84 + Runde × 0,004; Schwer bei 1,15 + Runde × 0,010 und einer zusätzlichen Einheit bis zum Limit. Die Teamzusammenstellung bleibt deterministisch.

30 Siegrunden, drei Leben, Shop, Entwicklungen, 52 Augments und die Kampfmechanik bleiben erhalten. Niederlagen kosten genau ein Leben und erhöhen die Runde nicht. Alte Spielstände ohne Schwierigkeitsfeld werden als Normal übernommen. Die Schwierigkeit ist anschließend Teil des Spielstands.

## Gestaltungsreferenzen

- [Pokémon Schwarz/Weiß: Kampfszenen und Screenshot-Galerie](https://pokemondb.net/black-white): Referenz für die Kombination räumlicher Kampfumgebung und flacher Sprites. Die bewegliche Kamera des Originals wird ausdrücklich nicht übernommen.
- [Nintendo: Pokémon-Pearl-Handbuch](https://csassets.nintendo.com/noaext/image/private/t_KA_PDF/DS_Pokemon_Pearl?_a=DATAg1AAZAA0): Referenz für klare getrennte Kampf- und Teaminformationen.
- [Pokémon Black/White Sprite-Kategorien](https://www.spriters-resource.com/ds_dsi/pokemonblackwhite/): ergänzende Recherche zu Battle-HUD und Party-Screen. Keine Assets daraus im Paket.

Vorhandene Pokémon-Sprites stammen weiterhin aus den in MEDIEN.md dokumentierten PokéAPI-Quellen. Die Referenzen dienten der Gestaltung, nicht einer pixelgenauen Nachbildung.

## Grenzen

Multiplayer-Lobby und Netzwerktransport sind weiterhin nicht enthalten. Touch wurde durch Eingabeereignisse getestet, nicht auf einem physischen Touchscreen. Ultrawide wurde als 2560 × 1080 Fenstergröße gerendert; echtes Vollbild wurde auf dem verfügbaren Monitor geprüft. Die feste Projektion ist eine 2D-Zeichenlösung, keine frei begehbare 3D-Welt.
