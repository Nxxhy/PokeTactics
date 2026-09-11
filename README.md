# Poké Tactics – GitHub-Updates (9.1)

Spiel-Repository: `Nxxhy/PokeTactics` (öffentlich, Einrichtung in Arbeit). Spiel und Launcher werden zusammen über signierte Windows-Pakete aus GitHub Releases aktualisiert. Die Entwickler-App startet denselben GitHub-Actions-Workflow und veröffentlicht fertige Entwürfe.

Aktuelle Anleitung: [GitHub Releases](docs/GITHUB-RELEASES.md). Der frühere eigene Update-Server wurde entfernt; Lobby-Hosting bleibt separat.

Die folgenden V9/V8-Berichte sind historische Implementierungsberichte. Ihre Aussagen über den alten Publisher-/Update-Server gelten nicht mehr.

# Poké Tactics 9.0.0

Windows-Setup und separater Launcher: `dist/PokeTactics-Setup-9.0.0.exe`. Entwickler-App: `dist/Developer/PokePublisher.exe`.

Neu: Hauptmenü ohne Spielstandspeicherung, echte servergestützte 8er-Lobbys, versionierte signierte Updates und individuelle Fähigkeitsanimationen für alle 70 Linien. **Öffentliches Hosting ist noch nicht eingerichtet.**

Anleitung: [docs/V9-ANLEITUNG.md](docs/V9-ANLEITUNG.md). Animationen und Quellen: [docs/V9-ANIMATIONEN.md](docs/V9-ANIMATIONEN.md).

---

## Historische Projektdokumentation (V8 und früher)

# Poké Tactics — Smaragd-Oberfläche, Version 8

Neu in V8: 18 Typ-Systeme mit 2/4/6/8-Schwellen, Typ-Embleme, neue Wirtschaft, stärkere 3-Sterne-Einheiten und 70 neu abgestimmte Linien mit Frosdedje als freigegebener Gen.-4-Ausnahme. [Werte, Roster, Regeln und Tests](docs/V8-SYSTEME.md).

Vorherige UI-Korrekturen: korrigierte Textgrenzen, mehr Platz für Beschreibungen, getrennte Shop-Inhalte und ein höhenabhängiges Layout. [UI-Korrekturen und Prüfungen](docs/V7-UI.md).

Die UI verwendet jetzt durchgehend die klassische Smaragd-Schrift Power Green und dazu passende Dialograhmen, Textschatten, Farben und Auswahlpfeile. [Gestaltung und Quellen](docs/V6-UI.md).

Neu: getrennte Teamhälften, grün-türkise Felslichtung, cremefarbene Pixelmenüs und 143 animierte Pokémon-Formen. [Referenzen und tatsächliche Animationsquellen](docs/V5-DESIGN.md). Spielregeln und feste Perspektive bleiben erhalten.

Privater Pokémon-Auto-Battler in Godot mit 70 kaufbaren Entwicklungslinien, 30 Siegrunden, 3 Leben, Level 10 und 64 Augments. Neu: feste 2,5D-Lichtung, räumliche Effekte, drei Schwierigkeitsgrade und eine anpassbare Oberfläche. Die aktive Oberfläche verwendet lokal enthaltene Power-Green-Pixelschriften. [Darstellung, Quellen und Änderungen](docs/V4-DARSTELLUNG.md).

## Starten

Im Projektordner **Starten.cmd** doppelklicken. Ein bereits geöffnetes Spiel vorher schließen, damit das aktualisierte Paket geladen wird.

Auf einem anderen Windows-Rechner **dist/PokeTactics-Windows.zip** vollständig entpacken und **PokeTactics.exe** starten. EXE und PCK bleiben zusammen. Keine separate Godot-Installation, kein Konto, keine Internetverbindung und keine Administratorrechte erforderlich. Windows x64 / OpenGL 3.3. Das Spiel startet im Vollbild; F11 wechselt zum Fenster.

## Spielen

- Karte anklicken: kaufen. Pokémon zwischen Bank und Feld ziehen; belegte Plätze tauschen. Ungültiges Loslassen, Esc und Fokusverlust brechen sicher ab. Beim Kampfstart werden freie Teamplätze automatisch aus der Bank besetzt.
- Drei Exemplare derselben Linie und Sternstufe verschmelzen. Drei Formen: Basis/Mitte/Ende; zwei Formen: Basis/Basis/Ende. Bei drei Sternen ist die Linie für den Rest der Partie aus dem Shop ausgeschlossen, auch nach Verkauf.
- Nur Siege erhöhen die Runde. Niederlage: ein Leben weniger, gleicher Gegner und gleiche Runde. Nach 30 Siegen gewonnen, nach drei Niederlagen beendet. Gleichstand gewährt keine Ressourcen.
- Vor Runde 5, 12 und 20 einen von drei Augments wählen. Gewählte Boni und alle Team-Synergien stehen dauerhaft rechts. 2/4/6/8 unterschiedliche passende Linien einschließlich Typ-Emblemen aktivieren die jeweilige Bonusstufe. Klick auf einen Typ zeigt alle Effekte.
- Figur auswählen oder überfahren: Angriffsreichweite. Details zeigen Rolle, Mana, Angriffs- und Fähigkeitstyp; der Fähigkeitstooltip erklärt Zielbereiche. Sehr effektive Treffer, Resistenzen und Immunitäten erscheinen im Kampf.
- Leertaste: Kampf/Pause · R: Shop erneuern · E: EP kaufen · Entf: ausgewählte Figur verkaufen · Esc/Rechtsklick: Auswahl/Ziehen abbrechen · F1: Hilfe · F11: Vollbild.

## Übersichten

[Alle Änderungen und Shop-Wahrscheinlichkeiten](docs/V3-UEBERSICHT.md) · [70 Linien und Werte](docs/ROSTER.md) · [Alle 64 Augments mit konkreten Effekten](docs/AUGMENTS.md) · [Balancing und Fähigkeiten](docs/BALANCING.md) · [Prüfbericht](docs/TESTBERICHT.md).

## Speichern und Entwicklung

Automatische Speicherung nach erfolgreichen Aktionen unter `%APPDATA%/PokeTactics/match.json`. Alte V1-/V2-Spielstände werden vor Übernahme als `.pre-v3-backup` gesichert. Vorhandene Linien werden auf die neuen Basiseinheiten abgebildet; abgeschlossene Dreisterne bleiben gesperrt. Bereits erreichte Augment-Meilensteine werden einmalig nachgeholt. V2 behält vorhandene Leben; V1 startet nach Migration mit drei Leben. Alte Siege werden in die 30-Runden-Expedition übernommen. Beschädigte Dateien werden zur Wiederherstellung gesichert.

**Editor.cmd** öffnet den Quellcode. Tests: `tests/test_core.gd`, `tests/test_v3.gd`, `tests/test_ui.gd` mit Godot `--headless --path . --script res://tests/DATEI.gd`. Build: `powershell -ExecutionPolicy Bypass -File tools/build.ps1`.

Das unabhängige Spielmodell, deterministische Kampfereignisse und versionierte Snapshots bleiben als Multiplayer-Grundlage erhalten. LAN/Online, Lobby und Netzwerktransport sind weiterhin nicht implementiert. Kein Audio, keine Items. Medienquellen und Lizenzen: [MEDIEN.md](docs/MEDIEN.md).
