# Fähigkeiten und Kampfanimationen

## Vollständigkeit

Alle **70 spielbaren Entwicklungslinien**, **143 verwendeten Formen** und **210 Kombinationen aus Linie und Sternstufe** besitzen eine explizit zugeordnete Fähigkeitschoreografie. `data/ability_animations.json` ordnet nach konkreter Fähigkeit zu, nicht pauschal nach Typ. Die vollständige Tabelle steht in `ANIMATIONS-ZUORDNUNG.md`; `docs/animation-coverage.json` enthält die Resultate pro Sternstufe und Form.

Verwendet werden 27 lokal gebündelte Showdown-Effekt-PNGs. Zu 62 der 70 Rezepte wurde ein entsprechender Referenz-Move im untersuchten Quellstand gefunden. Die Abläufe wurden für unseren ereignisbasierten Auto-Battler und dessen feste Perspektive in GDScript umgesetzt; es wird keine fremde Oberfläche oder JavaScript-Engine geladen. Für eigene Fähigkeiten und abweichende Wirkungen wurden eigene Kombinationen ergänzt. Kein Roster-Eintrag ist lediglich mit einem technischen Fallback versehen.

Beispiele: Egelsamen mit Samenflug, Ranken und Heilimpuls; Glut mit Feuerpartikeln; Flammenrad mit rotierendem Feuerring; Doppelkick mit zwei Fußtreffern; Kreuzschere mit gekreuzten Schnitten; Magnetfeld mit Zahnrad-Orbit, Schild und elektrischen Treffern; Familienwacht mit getrennten Schutzimpulsen; Draco Meteor mit fallenden Meteoren; Himmelslied mit Federn und Heilzeichen. Unterschiedliche selektierte Ziele werden durch echte Trefferereignisse dargestellt.

Stern 2 ergänzt Akzente. Stern 3 vergrößert die Signatur und ergänzt einen goldenen Ring/Stern. Psycho-Verstärkung zeigt einen violetten Doppelimpuls; Nachhall und zusätzliche Schutzwirkungen erzeugen eigene Ereignisse. Entwicklungen verwenden weiterhin die passende gebündelte Pokémon-Form.

## Anbindung an die Spiellogik

Normale Angriffe behalten kurze Bewegungen und kleine Projektile. Fähigkeiten verwenden eine 0,3-Sekunden-Lade-/Flugphase entsprechend dem bestehenden Kampfresolver. Die danach ausgelösten `ability_impact`-Ereignisse enthalten den tatsächlichen Empfänger, seine Position, Effektart und Sternstufe. Flächenmarkierungen zeigen betroffene Tiles, keine willkürlich gewählten Kreise. Die anfängliche Flugvorschau verwendet die zu diesem Zeitpunkt ausgewählten Ziele; bei einer Zieländerung während der Ladezeit bestimmen ausschließlich die tatsächlichen Auflösungsereignisse die Treffer.

Heilung, Schutz, Schildbruch, Reinigung, Treffer und Tod bleiben an echte Ereignisse gekoppelt. Brennen, Gift/Toxin, Frost/Einfrieren, Wachstum, Überhitzen, Kettenladung, Erdbeben und Wiederbelebung haben zusätzliches Feedback. Wasserfelder und Risse folgen den im Kampf gespeicherten Tiles und ihrer echten Dauer. Sandsturm/Regentanz stellen ihre vorhandenen Fähigkeiten dar; ein zusätzliches, nicht vorhandenes Wettersimulationssystem wird dadurch nicht vorgetäuscht.

Der Kern besitzt derzeit keine eigene Zufalls-Kritmechanik. Es werden deshalb keine erfundenen kritischen Treffer angezeigt; vorhandene Treffer-/Impact-Ressourcen wurden geprüft und integriert. Eine neue Kritmechanik wurde nicht in die bestehende Balance eingeschoben.

Welt-Effekte werden nach Spielfeldreihe zusammen mit den Einheiten gezeichnet. Namen, Sterne und Balken folgen als flache letzte Ebene. Pokémon sind insbesondere in kleineren Fenstern sichtbar größer, stehen weiterhin mit festem Fußpunkt auf dem Boden und bleiben proportional. Effekte lesen nur Ereignisse und lösen keine Spielaktionen aus. Wiederholtes Lesen desselben Frames dupliziert nichts; Tod entfernt laufende Angriffs-/Cast-Kanäle, Rundenende und Verlassen räumen Effekte auf.

## Interne Vorschau

`ui/animation_preview.tscn` startet dieselbe Kampfdarstellung mit echten vorbereiteten Kämpfern und dem normalen Fähigkeitsresolver. Links/Rechts: Linie wechseln. Pfeil oben: Sternstufe wechseln. F11: Vollbild. Esc: Beenden. Die Fähigkeit wiederholt sich automatisch; Stern 3 aktiviert zusätzlich die Psycho-Verstärkung zum Prüfen.

Aus dem Projekt: Godot mit `--path <Projektordner> res://ui/animation_preview.tscn` starten. Der gepackte Build enthält diese interne Szene ebenfalls; `PokeTactics.exe --path <Buildordner> res://ui/animation_preview.tscn` funktioniert ohne Editor. `Animationsvorschau.cmd` im Build bietet denselben Aufruf.

## Geprüft

`tests/test_v9_animations.gd`: **2.273 Prüfungen bestanden**, 0 fehlgeschlagen. Alle 210 Varianten durchlaufen den normalen Pending-Action-Resolver; die echten Empfänger und die anschließend tatsächlich gezeichneten Animationen werden geprüft. Jede Choreografie wird in drei Zeitphasen gerendert; Texte und Metadaten werden geprüft. Für jede Linie wurde ein Screenshot erzeugt. Zusätzliche Größen: 1600×900, 1920×1080 und natives Vollbild.

Die bestehende Grafik-Stressprüfung mit 20 Kämpfern und wiederholten gleichzeitigen Casts bestand mit 838 Assertions. Gemessene Bildzeiten sind in `docs/v9-performance.log` festgehalten und hängen von GPU und gleichzeitig laufenden Builds ab. Kein externer Download ist während eines Kampfes erforderlich.

## Recherche und Quellen

Untersucht: [smogon/pokemon-showdown-client](https://github.com/smogon/pokemon-showdown-client), festgehaltener Commit `1e3b209011340e7c149a2e94769183eb4351b2e9`.

- `play.pokemonshowdown.com/src/battle-animations-moves.ts`: individuelle Angriffsabläufe, Partikel, Sprite-Bewegungen, Nahkampf, Geschosse, Heilung und Status. Dateikopf: CC0-1.0.
- `play.pokemonshowdown.com/src/battle-animations.ts`: Effektkatalog, Sprite-Bewegungen, Wetter-/Terrain-/Statusdarstellung; Datei nennt MIT für die Replay-/Animations-Engine und ausdrücklich CC0 für den Großteil der Effekte. Die benannten Ausnahmen wurden nicht übernommen.
- `play.pokemonshowdown.com/fx/*.png`: die tatsächlich im Repository liegenden gebündelten Effektdateien. Jede hat eine feste Quell-URL und SHA-256 in `assets/showdown/manifest.json`.
- `play.pokemonshowdown.com/src/battle-dex.ts`: Auswahl von PNG-Fallbacks und externen GIF-Sprites inklusive Front-/Rückansicht und Formen. Laut README sind `/sprites/` und `/audio/` nicht im Repository enthalten. Vier konkrete externe GIF-Abrufe (Bisasam Front/Rückansicht, Bisaflor, moderner Frontsprite) lieferten HTTP 403. Ihre Dateiverfügbarkeit/Frameanzahl konnte daher nicht bestätigt werden. Es werden keine externen Showdown-Sprites als erfolgreich eingebunden behauptet.
- Die bestehenden 143 PokeAPI-Idle-Atlanten bleiben gebündelt. Sie enthalten Idle-Schleifen, keine gesonderten Angriffs-/Treffer-/Tod-Zustände. Diese Aktionen werden aus Sprite-Bewegungen und den neuen Effekten erzeugt. Herkunft und Prüfsummen bleiben in den bisherigen Asset-Manifests erhalten.

Lizenz- und Urheberhinweise: `SHOWDOWN-NOTICES.txt`, vorhandene PokeAPI-/Pokémon-Hinweise sowie `POWER-GREEN-SOURCE.txt`. Die CC0-Freigabe der Effekte gilt ausdrücklich nicht für Pokémon-Sprites. Es wurden weder die gesamte AGPL-Clientoberfläche noch die GPL-/CC-BY-SA-Ausnahmebilder übernommen.
