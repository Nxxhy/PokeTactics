> Historische V9-Anleitung: Der hier beschriebene Update-/Publisher-Server wurde in 9.1 entfernt. Für Veröffentlichung, Signierung und Launcher gilt ausschließlich [GITHUB-RELEASES.md](GITHUB-RELEASES.md). Lobby-Hosting benötigt jetzt nur DOMAIN und optional POKE_MINIMUM_VERSION; keine Update-Schlüssel oder Admin-Tokens.

# Poké Tactics 9.0.0 – Installation, Lobby und Veröffentlichungen

## Stand der Auslieferung

Der Windows-Installer enthält Spiel, Launcher und benötigte Laufzeiten. Die Entwickler-App wird separat ausgeliefert. **Es ist noch kein öffentliches Hosting eingerichtet.** Daher sind im ausgelieferten `service.json` weder eine erfundene Serveradresse noch ein Testschlüssel hinterlegt. Einzelspieler funktioniert offline. Die Lobby- und Update-Komponenten wurden lokal über echte HTTP-Verbindungen geprüft, nicht auf mehreren externen Geräten.

## Installieren und spielen

1. `PokeTactics-Setup-9.0.0.exe` ausführen. Die Installation erfolgt pro Windows-Benutzer, ohne Administratorrechte. Eine Desktop-Verknüpfung ist optional.
2. „Poké Tactics“ aus dem Startmenü öffnen. Die Verknüpfung startet den Launcher.
3. „Spielen“ öffnet das Hauptmenü. „Expedition starten“ bietet die drei bisherigen Schwierigkeitsgrade.
4. „Menü [Esc]“ zeigt vor dem Verlassen einer Expedition den Fortschrittsverlust an. Es gibt kein Autosave, Fortsetzen oder Laden alter Partien. Alte Dateien werden nicht gelesen oder gelöscht. Nur Einstellungen und Spielername bleiben in `%APPDATA%\PokeTactics\settings.cfg` erhalten.
5. Deinstallation über die Windows-App-Verwaltung. Installierte Versionen, Update-Staging und Verknüpfungen werden entfernt. Persönliche Einstellungen bleiben erhalten.

Die ausführbaren Dateien sind noch nicht mit einem kommerziellen Windows-Code-Signing-Zertifikat signiert. Die separate kryptografische Update-Signatur ersetzt dieses Windows-Zertifikat nicht.

## Einmaliges Hosting einrichten (Entwickler)

Erforderlich: ein Linux-Server mit Docker Compose, eine eigene Domain/DNS-A-Adresse, eingehend TCP 80/443 und genügend Speicher für versionierte Pakete. Es werden keine Zugänge automatisch gekauft oder angenommen.

1. Den Ordner `platform` auf den Server übertragen; `bin`, `obj`, Tests, lokale Compiler und `.runtime` auslassen. Nur `Server` und `hosting` werden benötigt.
2. In `platform/hosting/.env` `DOMAIN=deine-echte-domain` und `POKE_ADMIN_TOKEN=<mindestens 32 kryptografisch zufällige Zeichen>` setzen. Datei nur für den Administrator lesbar halten (`chmod 600`).
3. Den Bind-Mount `platform/hosting/data` erstellen, dem Container-Benutzer UID 1654 zuordnen (`chown 1654:1654 data`) und auf `chmod 700` setzen. Darin liegen Pakete, Veröffentlichungshistorie und der private Signierschlüssel. Regelmäßig gesichert aufbewahren.
4. In `platform/hosting` `docker compose up -d --build` ausführen. Caddy stellt das HTTPS-Zertifikat aus; der Spielserver-Port wird nicht öffentlich freigegeben. Es darf genau eine Server-Instanz laufen; die Lobby-Verwaltung ist pro Prozess verbindlich, nicht über mehrere Replikate verteilt.
5. `https://deine-echte-domain/health` prüfen. Der Server erzeugt beim ersten Start `data/signing-private.pem` und `data/signing-public.pem`. **Nur den öffentlichen Schlüssel** zum Build-Rechner übertragen.
6. In `platform/service.json` `endpoint` auf die echte HTTPS-Adresse und `publicKey` auf den vollständigen öffentlichen PEM-Schlüssel setzen. Den privaten Schlüssel und den Admin-Token niemals in Builds aufnehmen.
7. `tools/build-platform.ps1` erstellt anschließend den für diesen öffentlichen Dienst konfigurierten Installer. Die zuvor ausgelieferte unkonfigurierte Offline-Installation benötigt einmalig diese Konfiguration bzw. den neu gebauten Installer. In bestehenden Installationen wird `service.json` absichtlich nicht ungeprüft überschrieben; eine leere Datei kann der Entwickler einmalig durch die geprüfte öffentliche Konfiguration ersetzen.
8. Von zwei getrennten Geräten über Internet prüfen: Erstellen/Beitreten, acht Teilnehmer, Ready, Verlassen, Reconnect und ein vollständiges Update. Diese externen Tests sind noch offen.

Lobby-Zustände sind flüchtig. Bei Server-Neustart werden Lobbys geschlossen; Updates und Historie bleiben im Volume. Verbindungsstatus wechselt nach fünf Sekunden ohne Poll auf getrennt; nach 30 Sekunden endet die Reservierung. Ein dauerhaft getrennter Host schließt die Lobby. Die Clients fragen etwa einmal pro Sekunde ab. Gastzugänge sind an kryptografische Sitzungstokens gebunden, nicht an Namen. Es gibt keine Benutzerkonten und bewusst keine Multiplayer-Kämpfe.

## Lobby verwenden (nach Hosting-Einrichtung)

„Lobby erstellen“ → Namen eingeben → erstellen → Code kopieren. Weitere Spieler wählen „Lobby beitreten“ und geben den Code ein. Der Host zählt zu den acht Plätzen. „Bereit“ wird allen angezeigt. Nur der Host darf Gäste entfernen oder die Lobby schließen. Der Startbutton bleibt deaktiviert: „Multiplayer-Partien folgen in einem späteren Update“.

## Updates veröffentlichen

1. `PokePublisher.exe` starten. Server-Adresse und Entwickler-Token eingeben; „Zugang speichern / Historie laden“. Der Token wird mit Windows DPAPI für den aktuellen Benutzer geschützt gespeichert, getrennt von der Spielerinstallation.
2. Den fertigen Ordner `dist/PlayerBuild` auswählen. Er muss `PokeTactics.exe`, `PokeTactics.pck` und `PokeLauncher.exe` enthalten. Der Launcher selbst ist Bestandteil jedes versionierten Update-Pakets.
3. Eine neue, höhere Version `x.y.z`, Versionshinweise und gegebenenfalls die Online-Pflicht wählen. „Paket vorbereiten und prüfen“ erzeugt ZIP und SHA-256 und zeigt die Zusammenfassung. Die Spielversionsdatei `build.json` wird passend zur Veröffentlichung geschrieben. Änderungen an den Eingaben erfordern erneute Vorbereitung.
4. Erst „Update veröffentlichen“ lädt hoch. Der authentifizierte Server prüft ZIP-Pfade, Größe, erforderliche Dateien, Buildversion und Hash; danach aktiviert er die Veröffentlichung. Abrufbare Metadaten signiert der Server mit RSA-PSS/SHA-256. Das Paket selbst bleibt ohne Adminrechte abrufbar, die Veröffentlichung nicht.
5. Historie aktualisieren; Veröffentlichung wählen und zurückziehen. Bereits aktualisierte Nutzer werden nicht auf niedrigere Versionsnummern heruntergestuft. Zur Korrektur den letzten funktionierenden Build unter einer **neuen höheren Wiederherstellungsversion** veröffentlichen. Verwendete Nummern bleiben auch nach Rückzug gesperrt.

Keine Befehlszeile ist für normale Veröffentlichungen nach der einmaligen Einrichtung erforderlich. Der separate Entwickler-Zugang gehört niemals in Spielerpakete.

## Update-Verhalten und Grenzen

Der Launcher prüft automatisch. Ein benannter Windows-Mutex verhindert parallele Launcher/Update-Vorgänge. HTTPS ist Pflicht; ausschließlich `127.0.0.1` darf für lokale Tests HTTP verwenden. Umleitungen werden nicht automatisch verfolgt. Der eingebettete öffentliche Schlüssel prüft signierte Metadaten mit Ablaufzeit, anschließend werden Größe und Hash des Downloads geprüft. Fremde Download-Hosts und unsichere ZIP-Pfade werden abgelehnt.

Updates werden unter `staging` vorbereitet. Während ein Spiel läuft, bleibt die aktive Version unverändert. Erst nach dessen Ende wird ein neuer Versionsordner vollständig verschoben und `active.txt` atomar ersetzt. `previous.txt` hält die Rückfallversion fest. Fehlgeschlagene Downloads oder Installationen lassen die bisherige Version startfähig; eine unterbrochene Aktivierung kann erneut versucht werden. Offline bleibt „Spielen“ verfügbar. Einstellungen liegen außerhalb dieser Verzeichnisse.

Der kleine Starter in der Verknüpfung lädt den versionierten Launcher. Dadurch kann der Launcher samt .NET-Laufzeit aktualisiert werden, ohne seine laufende EXE zu überschreiben. Änderungen am stabilen Starter selbst erfolgen über den Installer. Aufbewahrte alte Versionen werden bei Deinstallation entfernt; automatische Speicherbereinigung ist noch nicht vorgesehen.

## Tatsächlich geprüfte Bereiche

- 1.005 Kernprüfungen: Wirtschaft, Runden, Leben, deterministischer Kampf, Rollen, Mana und Shop.
- 471 UI-Prüfungen einschließlich Maus-Drag-and-drop, ungültiger Ziele, Namen, Mana und Fenstergrößen.
- 217 Menü-/Ergebnisprüfungen bei drei Größen und Vollbild; keine Save-/Restore-Funktionen.
- 25 Serverprüfungen mit parallelen unabhängigen HTTP-Clients: Platzlimit, Reconnect, Hostverlust, Rechte, Authentifizierung, Versionen, Rückzug und Wiederherstellung.
- 7 zusätzliche Prüfungen mit zwei eigenständigen Godot-Lobby-Sitzungen gegen den echten lokalen Server.
- 15 Desktop-Integrationstests über die tatsächlichen Methoden der Entwickler-App und des Launchers: vollständiger realer Build, Upload, Signaturprüfung, Start des aktualisierten Spiels, Fälschung, korrupter/abgebrochener Download, ZIP-Pfadschutz, fehlgeschlagene Aktivierung, laufendes Spiel, erneuter Versuch und Offline-Zustand.
- Windows-Setup im isolierten Installationsordner auf diesem Gerät installiert; Startmenü-Verknüpfung, Launcher-Start, Start des installierten Spiels und saubere Deinstallation geprüft.
- Fähigkeits- und Grafiktests: siehe `V9-ANIMATIONEN.md` und maschinenlesbare Protokolle im Projektordner `docs`.

Die Veröffentlichungstests bedienen dieselben App-Methoden programmgesteuert. Ein kompletter manueller Klicktest auf einem zweiten, entwicklungsumgebungsfreien Windows-PC sowie öffentliche HTTPS-/Mehrgerätetests sind noch offen.
