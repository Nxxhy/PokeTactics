# Medien und Herkunft

## V6: klassische Menüschrift

Aktive Schrift: Power Green / Power Green Narrow aus dem [Essentials-Fontverzeichnis](https://github.com/synaestheory/essentials/tree/master/Fonts), Copyright 2008 Peter O. Dateien und Herkunft sind in `assets/fonts/POWER-GREEN-SOURCE.txt` dokumentiert; der Quellenvermerk liegt dem Windows-Paket bei. Die folgenden Schriftangaben beschreiben ältere Versionen. [V6-Gestaltungsreferenzen](V6-UI.md).

## V5: animierte Sprites und Referenzgestaltung

140 Schwarz/Weiß-Idle-GIFs aus dem bereits verwendeten PokeAPI/sprites-Repository sind als lokale Bildstreifen eingebunden. [Quellen, Rechteangaben, Referenzauswertung und Animationsumfang](V5-DESIGN.md). Original-GIF-URLs und Hashes stehen in `assets/animated/manifest.json` beziehungsweise `ANIMATION-MANIFEST.json` im Windows-Paket.

## Erweiterung V3 — 2026-09-09

Das aktuelle Roster nutzt 140 verschiedene lokale PNG-Sprites. `assets/manifest-v3.json` enthält URLs und SHA-256 aller aktiven Bilder, aus demselben unten genannten PokeAPI-Sprite-Commit. Alte, nicht mehr genutzte Dateien bleiben als Projektressourcen erhalten.

Auswahlgrundlage: sämtliche 386 Spezies aus Generation 1–3, darunter alle 100 der zweiten und 135 der dritten Generation. Deutsche Namen, Abstammung, Typen und die moderne 18-Typen-Effektivität stammen aus den CSV-Dateien von https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv . Die unveränderten heruntergeladenen CSVs stehen in `data/source`; `data/source/manifest.json` hält Quelle und Prüfsumme fest. `tools/expand_v3.py` erzeugt daraus die Spieltabellen; das Spiel lädt ausschließlich lokale JSON- und PNG-Dateien. `tools/download_v3.py` ergänzt die gewählten Bilder. Für den normalen Build sind keine Downloads notwendig.

Die folgenden Abschnitte beschreiben außerdem die ursprünglichen V1-/V2-Medien. Aktive Schrift bleibt VT323; Rechtehinweise der Pokémon-Sprites gelten weiterhin.

Für diesen privaten Prototyp werden 46 statische PNG-Sprites verwendet. Es gibt keine Laufzeit-Abfragen an externe Dienste und keine Audio-Downloads.

- Quelle: https://github.com/PokeAPI/sprites
- Verzeichnis: `sprites/pokemon/{id}.png`
- Gepinnter Commit: `6e523c72bb714306c90912647e0b2ccc4fd2fff1`
- Heruntergeladen am 2026-09-08.
- `assets/manifest.json` dokumentiert jeden Download mit vollständiger URL und SHA-256.
- `assets/POKEAPI-LICENCE.txt` enthält den unveränderten Rechte-/Lizenztext des Repositories.

Das Repository weist ausdrücklich darauf hin, dass die Bildinhalte Copyright The Pokémon Company sind. Die CC0-Angabe des Repositories ist keine pauschale Freigabe der Pokémon-Bilder oder Marken. Dieses Projekt ist ein privater, nicht offizieller Fan-Prototyp; es wird durch diese Arbeit nicht öffentlich veröffentlicht.

Die Oberfläche, das Spielfeld und die einfachen Kampflinien werden im eigenen Code gezeichnet. Godot wird mit seiner Lizenzdatei ausgeliefert; weitere Engine-Lizenzinformationen: https://godotengine.org/license/ und https://godotengine.org/license/third-party/ .

## Pixel-Schrift (V2)

Die Oberfläche nutzt seit V4 Pixelify Sans für Pixelüberschriften und Atkinson Hyperlegible für Beschreibungen und Zahlen. Beide Schriften sind lokal gebündelt. VT323 bleibt als ältere Projektressource erhalten. Es wird keine Schrift vom Betriebssystem benötigt oder zur Laufzeit heruntergeladen.

Atkinson Hyperlegible: [Google-Fonts-Quelldatei](https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegible), SIL Open Font License 1.1. Lokal: `assets/fonts/AtkinsonHyperlegible-Regular.ttf`, Lizenz `assets/fonts/ATKINSON-OFL.txt`, ebenfalls im Windows-Paket enthalten.

Die V4-Landschaft mit Himmel, Wolken, Hügeln, Bäumen, Gras und perspektivischem Boden wird im eigenen Code gezeichnet. [Recherchierte Gestaltungsreferenzen](V4-DARSTELLUNG.md#gestaltungsreferenzen).

VT323, Copyright 2011 The VT323 Project Authors, SIL Open Font License 1.1.

- Download: https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/VT323-Regular.ttf
- Lizenz: https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/OFL.txt
- Lokal: `assets/fonts/VT323-Regular.ttf` und `assets/fonts/VT323-OFL.txt`.
- SHA-256: `CF4DE751ADA78CEAC033DBE16A687742939995B77BC2A052AE17A4957958594D`.

Pixelify Sans, Copyright 2021 The Pixelify Sans Project Authors (https://github.com/eifetx/Pixelify-Sans), SIL Open Font License 1.1.

- Download: https://raw.githubusercontent.com/google/fonts/main/ofl/pixelifysans/PixelifySans%5Bwght%5D.ttf
- Lizenz: https://raw.githubusercontent.com/google/fonts/main/ofl/pixelifysans/OFL.txt
- Lokal: `assets/fonts/PixelifySans.ttf` und `assets/fonts/OFL.txt`.
- SHA-256 der unveränderten Schrift: `9BA86CD010A4DE309D263CEFF8E8044092C9DB7EFDA869620CB9FF1C4389E8A5`.

Pixelrahmen, Pokéball-/Herzsymbole, Partikel und alle Kampf-/Menüanimationen werden im eigenen Code erzeugt. Die Schriftlizenz wird dem Windows-Paket beigelegt. Zusätzliche V2-Sprite-IDs: 59, 115, 123, 131, 145, 149, 150, 242; Quellen und Hashes stehen im Manifest.


## V8

143 aktive Formen aus derselben PokeAPI-Quelle; Hashes und URLs in `assets/manifest-v8.json`, Idle-Zeiten im Animationsmanifest. Freigegebene Ausnahme: Frosdedje (Generation 4). Details in [V8-SYSTEME.md](V8-SYSTEME.md).
