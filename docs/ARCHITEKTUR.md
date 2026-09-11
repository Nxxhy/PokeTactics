# ADR-001: Autoritatives Spielmodell und getrennte Kampfsimulation

## Erweiterung V3 — 2026-09-09

Schema/Regeln 3: 30 Siegrunden, Level 10, 70 Linien und `core/augments.gd`. `completed_lines` bleibt auch nach Verkauf bestehen. `augment_offers`, `augment_at`, `augment_rounds` und `augments` sichern zufällige Angebote und einmalige Auswahl. Eine wiederhergestellte Partie würfelt offene Angebote nicht neu. `battle_serial` und `settled_serial` verhindern doppelte Auszahlung; die Einkommenszerlegung liegt in `income`.

Autofill findet innerhalb des autoritativen Kampf-Befehls statt. Vor der Simulation wird die aufgefüllte Aufstellung kopiert. Nur die eigene Seite bekommt gewählte Augments. Positionsboni werden beim Start berechnet; Angriffs-, Fähigkeits-, Schadens-, Heilungs-, Todes- und Zeitereignisse führen die übrigen Boni aus. Sekundärschaden löst keine rekursiven Angriffs-Procs aus. Synergien werden pro Linie einmal anhand ihrer höchsten aufgestellten Form gezählt.

`Catalog.distance` ist die gemeinsame Manhattan-Metrik für Vorschau und Kampf. Die moderne 18-Typen-Tabelle, deutsche Namen und alle 386 Spezies aus Gen 1–3 werden aus lokal archivierten PokeAPI-Daten erzeugt. `data/roster.json` enthält ausschließlich die 70 kaufbaren Basislinien. Gecachte Stammdaten vermeiden JSON-Ladevorgänge pro Frame; Battle-Instanzen mutieren diese Daten nicht.

V1-/V2-Migration bildet alte Shop-IDs auf Basislinien ab (Pikachu→Pichu, Arkani→Fukano, Dragoran→Dratini, Heiteira→Chaneira), rekonstruiert den Pool und merkt vorhandene Dreisterne. Noch nicht vorhandene historische Augment-Wahlen werden nachgeholt. V2-Leben bleiben erhalten. Die folgenden ursprünglichen ADR-Abschnitte dokumentieren die Vorgeschichte; aktuelle Zahlen stehen in V3-UEBERSICHT.md.

**Status:** umgesetzt für lokalen Prototyp; Multiplayer-Transport geplant

**Datum:** 2026-09-08

## Kontext

Das Spiel soll zuerst lokal leicht startbar sein, später mehrere menschliche Spieler unterstützen. UI-Animationen dürfen keine Ergebnisse beeinflussen. Ein einzelner Entwickler soll Regeln und Daten schnell ändern und headless testen können.

## Entscheidung

Godot 4 mit GDScript. Das Modell ist ein RefCounted-Objekt ohne SceneTree-Abhängigkeit. Alle Spieleraktionen laufen über `command(action, expected_revision)`. Die Oberfläche sendet Kauf-, Bewegungs-, Verkaufs-, EP-, Shop- und Kampf-Befehle; Kosten, Positionen, Phasen und Revisionen werden im Modell validiert. Ungültige Aktionen verändern weder Zustand noch Zufallsgenerator.

Die Simulation bekommt Kopien beider Aufstellungen und einen Seed. Sie verwendet feste Schritte, stabile Zielauswahl, alternierende Initiative und deterministische Wegsuche. Sie gibt Sieger, Restgegner und Ereignis-/Positionsframes zurück. Die lokale Simulation berechnet einen Kampf sofort; die UI spielt nur die Frames ab. Belohnungen werden genau beim Kampf-Befehl vergeben, niemals beim Ende eines Replays.

Versionierte JSON-Snapshots enthalten Wirtschaft, Einheiten, Angebote, Figurenpool und RNG-Zustand. 64-Bit-Seeds und RNG-Zustände werden als Strings gespeichert; beim Laden werden Spielzahlen in Integer normalisiert. Kaputte Spielstände werden vor Neustart gesichert. Die Dateien werden über eine temporäre Datei ersetzt.

## Erwogene Alternativen

| Option | Aufwand jetzt | Späterer Multiplayer | Konsequenz |
|---|---|---|---|
| Regeln direkt in UI-Nodes | gering | schwer zu entkoppeln | verworfen |
| Godot-Modell plus reine Simulation | moderat | serverseitig ohne Grafik ausführbar | gewählt |
| Separater TypeScript-/C#-Server sofort | hoch | gute eigene Serverumgebung | unnötige zweite Laufzeit im ersten Prototyp |

## Grenzen der heutigen Implementierung

Ein Modell repräsentiert genau einen menschlichen Spieler gegen generierte Bots. Der Bot verbraucht keine Exemplare aus dem lokalen Figurenpool. Ein echter Mehrspieler-Matchzustand, Identitäten und Netzwerkauthentifizierung sind noch nicht implementiert. Die Revision ist Schutz vor veralteten Befehlen, kein Authentifizierungsmechanismus. Snapshots sind lokale Dateien, keine ungeprüft akzeptierbaren Client-Nachrichten. Reproduzierbarkeit ist für identische Spiel-/Engine-Versionen getestet; kein plattformübergreifendes Lockstep-Versprechen.

## Konkreter Multiplayer-Ausbau

1. Match-Host mit `players[player_id]`, gemeinsamem Shop-Pool, Planungs-/Bereit-/Kampf-/Ergebnis-Phasen und Rundenfrist ergänzen.
2. Befehlsumschlag `{match_id, player_id, command_id, expected_revision, action}`; `player_id` aus authentifizierter Verbindung ableiten. Sequenz-/Duplikatprüfung, Nachrichtenlimits und Größenlimits vor dem Modell.
3. Zunächst LAN-Host/Beitreten über einen Godot-Netzwerkadapter. Headless-Host führt dieselben Spielregeln aus. Kein Client darf Gold, Treffer, Sieger oder Positionen außerhalb eines gültigen Befehls setzen.
4. Pro Empfänger nur erlaubte Informationen senden: eigener Shop/Bank, sichtbare Boards, öffentliche Wirtschaft nach festgelegten Regeln. Interne RNG-Zustände und komplette Host-Snapshots nicht an Mitspieler senden.
5. Kampf auf dem Host berechnen und komprimierte Events/Startzustände zur Darstellung versenden. Vollständige Prototyp-Frames nicht unverändert über das Netz streamen. Reconnect über gefilterten Snapshot plus aktuelle Phase.
6. Danach Internet-Lobby, NAT/Relay-Entscheidung, Abbrüche, Zeitüberschreitungen, Wiederbeitritt und separate Serverpakete testen.

## Folgen

Regeln lassen sich ohne Fenster prüfen; das erste Paket braucht keinen Server. Für Multiplayer bleiben Lobby, Mehrspieler-Zustandsmodell und Netzwerksicherheit echte Arbeit. Das jetzige Frame-Replay ist bewusst einfach und speicherintensiver als ein späterer Eventstream. Produktionscode sollte den Befehlseingang als einzige Schreibstelle weiter erzwingen; GDScript selbst kapselt die öffentlichen Dictionaries nicht gegen andere interne Skripte.

## Ergänzung V2

Das Modell enthält nun 20 Siegrunden, `lives`, `attempt`, `outcome` sowie Kostenstufen 1–5. Schema 1 wird vor dem Laden gesichert und in Schema 2 migriert. Rolle, individuelle Manakosten, Fähigkeit und Effektliste stehen pro Pokémon in JSON.

`validate_move` ist eine reine Vorschauprüfung und wird auch unmittelbar vor dem tatsächlichen Verschieben aufgerufen. Ein Drag speichert nur UID, Ursprung und Revision. Erst beim Loslassen wird ein normaler Bewegungsbefehl gesendet; Abbruch/Fokusverlust verändern keine Einheit. Server-Replikation kann später denselben Revisionsschutz verwenden. UI-Eingaben werden von Fenster- in Canvas-Koordinaten umgerechnet; die Tests berücksichtigen den Viewport-Transform bei eingespeisten Ereignissen.

Die Kampfsimulation emittiert strukturierte Ereignisse für Bewegung, Angriff, Treffer, Mana, Zauber, Heilung, Schild, Status und Besiegen. Die Oberfläche erstellt zeitbegrenzte Pixel-Effekte daraus. Eine Obergrenze begrenzt ausschließlich visuelle Partikel, niemals Simulation oder gespeicherte Kampfereignisse. Wiederholtes Abspielen und andere Abspielgeschwindigkeiten ändern die bereits autoritativ gewertete Partie nicht.
