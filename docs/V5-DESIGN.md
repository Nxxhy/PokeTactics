# Referenzgestaltung und animierte Pokémon — V5

Regeln und feste 2,5D-Projektion bleiben unverändert. Die warme grasgrüne Gegnerhälfte und die türkise eigene Hälfte sind durch eine helle pixelige Bodenmarkierung getrennt. Die Schilder „Gegner“ und „Dein Team“ bleiben auch im Kampf sichtbar. Beim Ziehen werden ausschließlich tatsächlich erlaubte Ziele hervorgehoben; die Gegnerhälfte enthält keine Platzierungsziele.

## Referenzen

- **Bild 1:** Türkisgrün, gestufte Baumkronen, felsige Einfassung, helle Kanten und dunkle Menüumrandungen. Übertragen wurden Palette, Felswand und Randbepflanzung außerhalb der Tiles.
- **Bild 2:** Cremefarbene Inhalte, grüne Kopf- und Auswahlflächen, kompakte mehrfache Rahmen und getrennte Bild-/Textbereiche. Diese Merkmale verbinden Bank, Markt, Details, Synergien und Augments.
- **[Arkeve: Make a Pokemon Game in Godot – Menu & Transitioning to Party Screen (#9)](https://www.youtube.com/watch?v=UwkvvFtOyiQ):** Die Textabfrage scheiterte, die Browserwiedergabe war zugänglich. Visuell geprüft wurden Ausschnitte der Menüeinrichtung, darunter etwa 4:15: helle kompakte Menüfläche mit mehrfacher dunkler/heller Pixelumrandung im Godot-Editor. Das Video wurde nicht vollständig angesehen. Aus diesen Ausschnitten werden keine Beobachtungen zu Kampfanimationen oder 2,5D-Kameras abgeleitet. Die Bilder sind die Hauptvorlagen für die Landschaft.

Die Landschaft und UI-Symbole werden im Projekt gezeichnet; keine Referenzbilder wurden als Hintergrund kopiert. Unveränderte Landschaftsteile werden als Textur zwischengespeichert, während Wolken und Gräser weiter animiert werden.

## Tatsächliche Animationsquelle

Die bisherigen Manifeste nennen **[PokeAPI/sprites](https://github.com/PokeAPI/sprites)**. Repository und README wurden geöffnet. Der verwendete [Schwarz/Weiß-Animationsordner](https://github.com/PokeAPI/sprites/tree/6e523c72bb714306c90912647e0b2ccc4fd2fff1/sprites/pokemon/versions/generation-v/black-white/animated) enthält Front-GIFs. Für sämtliche **140 verwendeten Pokémon- und Entwicklungsformen** wurden Schleifen gefunden: **8.994 Frames**.

Dieser Ordner bietet keine gesondert benannten Angriffs-, Treffer- oder Besiegt-Zustände. Die GIFs werden als Idle-Schleifen verwendet. Vorstoß, Geschosse, Rückstoß, Trefferblitze und Ausblenden besiegter Einheiten sind ergänzende Spielanimationen, keine behaupteten Original-Assetzustände.

Ein gemeinsamer Ausschnitt über alle GIF-Frames hält Abmessungen, Maßstab und Bodenanker stabil. Die Originaldauern bleiben erhalten. Natürliche Bewegung innerhalb des festen Rahmens stammt aus dem GIF. Die Entwicklungs-ID bestimmt sowohl Namen als auch Animation. Ein fehlender optionaler Atlas fällt auf den vorhandenen statischen Sprite zurück. Keine Downloads und keine GIF-Decodierung während des Spiels; Texturen werden einmal geladen. Die Bildstreifen benötigen etwa 5,1 MiB auf dem Datenträger.

**Rechteangaben:** Bildinhalte Copyright The Pokémon Company. Das Repository bezeichnet seine Verteilung als CC0 1.0, weist aber ausdrücklich auf das Copyright der Bildinhalte hin. Die CC0-Angabe wird nicht als Freigabe der Pokémon-Rechte dargestellt. `POKEAPI-LICENCE.txt` bleibt im Paket enthalten. URLs und SHA-256 der Original-GIFs stehen in `ANIMATION-MANIFEST.json`; `tools/import_idle.py` dokumentiert die reproduzierbare Umwandlung am festgelegten Commit.

## Prüfung

Die Oberflächensuite prüft Maus-Ziehen, Tauschen, ungültige Ziele, reine Klickauswahl, vollständige Namen/Fähigkeiten, Preise und Layout. Die neue V5-Suite prüft sämtliche Schleifen, Framegrenzen, GIF-Dauern, Entwicklungszuordnungen, statischen Ersatz, Teamhälften und erlaubte Ziehziele. Ein Belastungslauf rendert 20 animierte Pokémon und wiederholte Gruppen von 20 Fähigkeiten.

Die Perspektivsuite prüft Touch-Ziehen, Größenwechsel während des Ziehens, Tiefensortierung, Effektbereiche, 1280 × 720, 1920 × 1080, 2560 × 1080 und echtes Vollbild. Touch wird mit Eingabeereignissen geprüft; ein physischer Touchscreen wurde nicht verwendet.
