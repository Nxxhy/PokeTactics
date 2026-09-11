# Prüfbericht V6 — 2026-09-09

Nach Umstellung auf Power Green, klassische Fenster und Textschatten: erneut **1.327 Prüfungen bestanden, 0 fehlgeschlagen** (459 UI, 42 Perspektive, 826 Animationen). 20 animierte Einheiten: median 16,7 ms / p95 16,7 ms; gleichzeitige Effektgruppen: median 16,7 ms / p95 21,8 ms. Vollständige Labels, Drag-and-drop und Vollbild bleiben geprüft. Gestaltung und Schriftquelle: V6-UI.md.

## Historischer Prüfstand V5

Aktuelle Designänderung: **1.327 Prüfungen bestanden, 0 fehlgeschlagen** — Oberfläche 459, Perspektive/Touch/Vollbild 42, Animationen/Teamhälften 826. Die Spielmodelldateien wurden in dieser Überarbeitung nicht verändert; die früheren Mechanikprüfungen sind unten als historischer Stand dokumentiert.

Alle 140 verwendeten Entwicklungsformen haben lokale GIF-Animationen. 8.994 Frames wurden mit Originalzeiten und konstantem Ausschnitt importiert. Geprüft: Frameübergänge und Schleifen, Atlasgrenzen, Entwicklungszuordnung, statischer Ersatz, reine eigene Platzierungsziele, sichtbare Teambezeichnungen während des Kampfes, Labels und Preise sowie Fenstergrößen und echtes Vollbild.

Leistung: Intel Iris Xe, OpenGL, 1920 × 1080. Nach Zwischenspeicherung der Landschaft, Textumbrüche und geformten Textzeilen sowie Zusammenfassung gleicher Effektkanäle erreichte der abschließende Lauf mit den Auslieferungseinstellungen: 20 animierte Einheiten ohne Effektstoß median 16,7 ms / p95 16,7 ms; wiederholte Gruppen von 20 gleichzeitigen Fähigkeiten median 16,7 ms / p95 20,7 ms. Das entspricht überwiegend 60 FPS, mit einzelnen langsameren Bildern unter hoher Effektlast. Ein früherer unlimitierter Vergleichslauf lag unter höherer Systemlast bei 22,3 ms / p95 34,7 ms für die Effektgruppen. Die Auslieferung verwendet ein 60-FPS-Limit ohne VSync, das auf diesem Rechner erhebliche zusätzliche Wartezeiten verursacht hatte. Die alternative experimentelle Render-Thread-Einstellung wurde geprüft, aber nicht übernommen.

Die Videoauswertung war auf tatsächlich betrachtete Menüausschnitte beschränkt. Keine eigenen Angriffs-/Treffer-/Besiegt-Dateien werden der GIF-Quelle zugeschrieben. Quellen und Umfang stehen in V5-DESIGN.md.

## Historischer Prüfstand V4

Aktueller Stand: **4.218 Prüfungen bestanden, 0 fehlgeschlagen**: Kernregeln 1.133, V3-Regeln 705, Schwierigkeitsgrade/Preise 1.879, Oberfläche 459, Projektion/Touch/Vollbild 42. Die Anzahl in der Kernsuite hängt vom Verlauf der sechs simulierten Partien ab; die stärkeren Gegner beenden diese früher.

Geprüft wurden projizierte Zielpolygone, Maus- und Touch-Ziehen, Tauschen, ungültige Ziele, Abbruch, Größenwechsel während des Ziehens, interpolierte Tiefensortierung, Trefferbereiche oberhalb der Zielbalken, alle 70 Namen und Fähigkeiten sowie 1280 × 720, 1920 × 1080 und 2560 × 1080. Echtes Vollbild verwendet die volle verfügbare Monitorfläche; auch darin wurde eine Einheit erfolgreich auf die Bank gezogen. Screenshots: `scene-1280x720.png`, `scene-1920x1080.png`, `scene-2560x1080.png`, `scene-fullscreen.png`.

Die Regressionen prüfen weiterhin Shopkosten 4/5, Rollenmana, Niederlagen ohne Rundenerhöhung, Augments und persistente Shop-Sperren. Normal/Schwer aktivieren Team-Synergien; Unterstützer stehen hinten. Alle drei Schwierigkeiten wurden über 30 Runden und vier Seeds geprüft, einschließlich Speichern/Laden.

Grenzen: Touch-Ereignisse wurden simuliert; kein physischer Touchscreen und kein physischer Ultrawide-Monitor standen zur Prüfung zur Verfügung. Godot meldet im eingeschränkten Testkontext einen Fehler beim Lesen des Windows-Zertifikatspeichers. Die lokalen Grafik- und Spieltests funktionieren ohne Netzwerk.

Windows-Paket V4: eigenständig aus `dist/PokeTactics` gestartet, 140 Sprites geladen und 0 Textüberläufe gemeldet. Das Paket enthält beide aktiven Schriften sowie das Schwierigkeitsmodul. Das ZIP wurde ohne Entpacken auf CRC-Fehler geprüft. Wegen des knappen freien Speicherplatzes wurde keine zusätzliche V3-Paketkopie erzeugt; die bestehenden V1-/V2-Archive bleiben erhalten.

## Historischer Prüfstand V3

Godot 4.7.2, Windows x64, Intel Iris Xe / OpenGL 3.3. Prüfungen verwenden separate Projektdateien, nicht den persönlichen Spielstand.

**Endergebnis: 2.532 Prüfungen bestanden, 0 fehlgeschlagen** — 1.445 bestehende/angepasste Mechanikprüfungen, 705 gezielte V3-Prüfungen und 382 Bedienungs-/Layoutprüfungen. Die Kernsuite trägt im Konsolenpräfix aus Kompatibilitätsgründen noch die Bezeichnung CORE V2; die geprüften Daten und Regeln sind Version 3.

## Eigenständiges Windows-Paket

Das fertige ZIP wurde in ein separates Verzeichnis entpackt und die enthaltene EXE ohne Projektpfad gestartet. Alle 140 aktiven Sprites, Schrift und neue JSON-/GDScript-Module wurden aus dem PCK geladen. Der echte Grafiklauf erzeugte `v3-package.png`, meldete 0 Textüberläufe und beendete sich erfolgreich. Der vorherige V2-Stand bleibt unter `dist/previous/PokeTactics-v2.zip` erhalten.

## Automatisierte Prüfungen

- `tests/test_core.gd`: bestehende Regressionstests auf die absichtlich geänderten Regeln angepasst. 70 echte Fähigkeiten mit ihren Effektlisten; Rollenmana, Käufe, Verkäufe, Poolerhaltung, Bewegung, Rückzug, Status, Speichern und deterministische Simulation. 8.000 Shopangebote auf Level 3–10; jede beobachtete Kostenverteilung innerhalb von 5 Prozentpunkten der Vorgabe. Level 10: 254 von 1.000 Angeboten kosten 5 Gold (25,4 % gegenüber 25 % konfiguriert).
- `tests/test_v3.gd`: genau 70 Linien, Kostenverteilung 16/16/16/12/10, zehn legendäre/mysteriöse Premium-Linien, vollständige 386-Spezies-Auswahlbasis und korrekte Formen auf allen drei Sternstufen. Permanente Shop-Sperren einschließlich Verkauf, gesperrter Shops und bereits reservierter Doppelangebote; Ersatzangebote bleiben gültig. Autofill über den echten Kampf-Befehl, Bankreihenfolge, Teamlimit und unveränderte manuelle Positionen.
- Typentest: 2×, 0,5×, 4×, 0,25× und 0× bei doppelten Typen; Immunität verursacht wirklich keinen Lebensverlust und kein Schadensmana. Gemeinsame Manhattan-Metrik. Mehrstufige Synergien zählen weder Bankfiguren noch doppelte Linien mehrfach.
- Alle 52 Augments: reale Geld-/EP-Transaktionen, bedingte Kampfwerte, Synergieschwellen, Mana- und Heilungswerte, echte Treffer-/Fähigkeits-/Todes-Procs und zeitliche Effekte in vollständigen Simulationen. Auswahl vor Runde 5/12/20, gespeicherte Angebote, drei unterschiedliche Optionen, nur eine Wahl und keine zweite Wahl nach Niederlage. Zinsen an acht Goldgrenzen, genau einmalige Auszahlung und Lebensverlust über Kampf-IDs, Wiederholung derselben Runde als neuer Kampf.
- V1-/V2-Migration, neue Basis-IDs, erhaltene Leben/Runden, Dreisternsperren, nachgeholte Augment-Meilensteine und erneutes JSON-Laden. Ein dabei gefundener Unterschied zwischen JSON-Zahlen und Integer-Listen wurde behoben und abgesichert.
- `tests/test_ui.gd`: echte Eingabeereignisse für Drag-and-drop, Feld-/Banktausch, ungültige Ziele, Fokusverlust, Esc, veraltete Revision, Klickbedienung und Fenstergrößenänderung. Kaufen, Verkauf, Pause, Replay und Speichern. Alle 70 Linien in Feld, Bank, Shop und Details sowie volle Manawerte. Alle 52 Augment-Texte im Auswahlfenster und in der dauerhaften Übersicht; vielfältiges Team im kompakten Synergieraster. Eingabesperre des Auswahlfensters und tatsächliche einmalige Wahl per Mausklick. 140 Sprites und lokale VT323-Schrift geladen. Keine gemessenen Textüberläufe.

## Sichtprüfung

Die echte Godot-Oberfläche wurde als spätes Team mit Kostenfarben und Reichweitenmarkierung, Augment-Auswahl, Drag-Vorschau, Fähigkeitsframe, Niederlage und Handbuch gerendert. Neue Darstellungsfehler beim Effektivitätsformat sowie ein durch Neuzeichnen abgebrochener Augment-Klick wurden entdeckt und behoben. Das Fenster startet mit 1600 × 800, interne Zeichenfläche 1920 × 960. F11 ermöglicht Vollbild.

## Automatisierte Partien

Sechs Partien einer einfachen Einkaufsstrategie mit der endgültigen Gegnerkurve: vier Ausscheiden in Runde 14, 16, 26 und 27; eine erfolgreich mit 30 Siegen und drei verbliebenen Leben; eine nach dem Testlimit von 40 Kämpfen noch in Runde 27 (14 Unentschieden). Bei jeder Runde wurden Zustandsinvarianten und erneutes Laden geprüft. Die Strategie passt bei Gleichständen ihr Team nur eingeschränkt an. Die Läufe sind Plausibilitätsprüfungen, keine belastbare menschliche Siegquote.

## Grenzen

Keine menschlichen Langzeittests und noch kein Test auf einem zweiten Rechner. Einzelne Kombinationen können Gleichstände erzeugen; dafür bleiben Umbau, Shop und Verkauf verfügbar. Die theoretische vollständige Erschöpfung aller 70 Linien kann kein neues Angebot liefern. LAN/Online ist weiterhin nicht implementiert.

Die Sandbox meldet beim Engine-Start fehlenden Zugriff auf den Windows-Zertifikatsspeicher. Das Spiel verwendet keine Laufzeit-Netzwerkzugriffe; dieser Umgebungshinweis ist kein Spielskriptfehler.
