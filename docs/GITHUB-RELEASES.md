# GitHub Releases – Poké Tactics

Zielrepository: **Nxxhy/PokeTactics**, öffentlich, vom Nutzer festgelegt. Pokémon Showdown ist ausschließlich eine Animationsreferenz und wird niemals als Update-Quelle verwendet.

## Einmalige Einrichtung

1. Öffentliches Repository `Nxxhy/PokeTactics` anlegen und die Projektquellen einschließlich `.github/workflows/release.yml`, Assets und `platform/updates.json` auf `main` übertragen. `.release-secrets`, Testlaufzeiten, Installationsdateien, `.godot` und `dist` dürfen nicht eingecheckt werden. Der private Schlüssel ist nicht im öffentlichen Konfigurationsfile enthalten.
2. Der lokale RSA-3072-Schlüssel liegt Windows-DPAPI-geschützt in `.release-secrets/signing-key.dpapi`. Er ist nur für den aktuellen Windows-Benutzer entschlüsselbar. Den Schlüssel sicher sichern; bei Verlust lassen sich Updates für bereits ausgelieferte Prüfschlüssel nicht mehr signieren. `tools/initialize-signing.ps1` erstellt ihn nur, solange kein Schlüssel existiert, und verhindert versehentliche Rotation.
3. GitHub CLI auf Entwicklerseite anmelden (`gh auth login`) und `tools/set-github-signing-secret.ps1` ausführen. Dies setzt das Repository-Secret **UPDATE_SIGNING_PRIVATE_KEY**, ohne den Schlüssel als Klartextdatei oder Befehlsargument abzulegen. Alternativ den Schlüssel über eine selbst verwaltete sichere Methode als gleichnamiges GitHub Actions Secret hinterlegen. Niemals in Chat, Quellcode, Release oder Installer einfügen.
4. GitHub Actions aktivieren, die Umgebung `release` auf vertrauenswürdige Branches/Tags beschränken und nach Bedarf mit manueller Freigabe schützen. Der Release-Workflow benötigt `contents: write`. Nur vertrauenswürdiger Projektcode darf mit dem Signiersecret laufen.
5. Die neue Setup-Version einmal installieren. Sie fügt `updates.json` mit Repository und öffentlichem Prüfschlüssel hinzu, auch bei bestehenden V9-Installationen. Alte V9-Launcher können diese neue Quelle noch nicht selbständig erkennen. Einstellungen und Spielername in `%APPDATA%\PokeTactics\settings.cfg` bleiben erhalten. Die Lobby-Adresse in `service.json` bleibt separat.

## Eine neue Version veröffentlichen

1. Änderungen und getestete Quellen auf `main` pushen.
2. `PokePublisher.exe` öffnen; daneben muss die mitgelieferte `updates.json` liegen. Persönlichen Fine-grained GitHub-Token für genau dieses Repository eingeben (Actions: Write, Contents: Write). Er wird nur auf Wunsch unter dem Entwickler-Windows-Benutzer mit DPAPI gespeichert.
3. Branch/Commit, **x.y.z** und Versionshinweise eingeben, „Build starten“ wählen. Der Workflow baut Spiel, selbständigen Windows-Launcher und Installer, führt Tests aus und signiert das Windows-Update. Status wird alle 30 Sekunden angezeigt; ausgewählten Build öffnen zeigt die konkreten Jobs/Logs und Fehler. Keine erfundene Prozentanzeige für GitHub-Jobs.
4. Der fertige Release bleibt zunächst ein **Entwurf**. In der Entwickler-App auswählen und „veröffentlichen“ klicken. Vorher prüft sie die vollständigen Assets und die Metadaten-Signatur. Alternativ denselben Entwurf direkt in GitHub veröffentlichen.
5. Launcher prüfen beim Start und anschließend regelmäßig. Sie laden und prüfen neue Pakete automatisch; laufende Spiele werden nicht beendet. Nach Aktivierung startet auch der neue Launcher.

Alternativ startet ein gepushter Tag `vX.Y.Z` denselben Workflow. Ein direkt in GitHub veröffentlichtes stabiles Release löst ebenfalls den Build aus; es wird erst installierbar, sobald alle signierten Dateien bereitstehen. Ein bereits fertiges Release wird nicht neu gebaut. Nie veröffentlichte Binärdateien ersetzen: Korrekturen erhalten eine neue, höhere Version. `v9.10.0` ist größer als `v9.9.9`; führende Nullen, Vorabversionen und Build-Suffixe sind in diesem stabilen Windows-Kanal nicht erlaubt (Versionsteile 0–65535).

## Release-Dateien und Vertrauen

- `PokeTactics-X.Y.Z-win-x64.zip`: vollständiges Windows-Spiel, `build.json`, Launcher und Lizenzhinweise; kein Quellcode-Download.
- `update-win-x64.json`: Repository, Version, Tag, Plattform, Paketname, Größe und SHA-256.
- `update-win-x64.sig`: Base64-RSA-PSS/SHA-256-Signatur über die exakten JSON-Bytes.
- `SHA256SUMS.txt`: lesbare Prüfsumme, mit den signierten Metadaten abgeglichen.
- `PokeTactics-Setup-X.Y.Z.exe`: Erstinstallation und Migration alter Launcher.

Der öffentliche Schlüssel wird durch den vertrauenswürdigen Erstinstaller festgelegt, nicht aus demselben Release nachgeladen. Die Metadaten-Signatur authentifiziert die Paket-Prüfsumme. HTTPS bleibt obligatorisch; Weiterleitungen sind auf bekannte GitHub-Asset-Hosts beschränkt und erhalten keine Zugangstokens. Die Signatur ist keine Windows-Authenticode-Signatur; ein entsprechendes Code-Signing-Zertifikat ist weiterhin nicht eingerichtet.

Abfragen verwenden den offiziellen stabilen `releases/latest`-Kanal und vergleichen die Tag-Version numerisch. Die von GitHub als „latest“ bezeichnete Veröffentlichung sollte stets die höchste stabile Version sein; ältere Releases werden niemals als Downgrade installiert. Regulär 15 Minuten zwischen Prüfungen, einminütige Mindestpause für Wiederholungen, ETag/304 und persistentes Backoff bei GitHub-Abfragelimits. Ein fehlendes Internet verhindert den Einzelspielerstart nicht. Abgebrochene Pakete werden verworfen; „Erneut prüfen“ startet nach der Abfragepause einen neuen Download.

Installation erfolgt in einem neuen Versionsverzeichnis, anschließend wird `active.txt` atomar ersetzt. Bisherige Dateien bleiben erhalten; Fehler vor der Aktivierung lassen die bisherige Version aktiv. Der stabile Bootstrap startet den neuen Launcher; Launcher und .NET-Laufzeit werden im Update mitgeliefert. Der Bootstrap selbst wird durch den Installer aktualisiert. Benutzereinstellungen liegen außerhalb dieser Versionsverzeichnisse.

Für ein später privates Repository ist optional ein **eigener** Token je berechtigtem Spieler (Contents: Read) vorgesehen, Windows-geschützt gespeichert und jederzeit entfernbar. Es gibt keinen gemeinsamen eingebetteten Zugriffstoken. Das aktuell gewünschte öffentliche Repository benötigt keine Spieler-Anmeldung.

## Tests und aktueller Betriebsstatus

`tools/test-github-updates.ps1` prüft den tatsächlichen Launcher mit simulierten GitHub-HTTP-Antworten, signierten Paketen, echten Spieldateien, zwei aufeinanderfolgenden Aktualisierungen, Start des aktualisierten Spiels, laufendem Spiel, Signatur-/Hashfehlern, unvollständigen Releases, unterbrochenen Downloads, Offlinebetrieb, ETags und Abfragelimits. Ergebnis: `docs/github-update-tests.txt`.

Der öffentliche Ende-zu-Ende-Nachweis (alte Setup-Version installieren → GitHub Actions → echtes Release → Download über GitHub → neue Version starten) benötigt ein tatsächlich angelegtes Repository, authentifizierten Schreibzugriff und das GitHub-Signiersecret. Lokale Simulationen ersetzen diesen Nachweis nicht. Der konkrete Auslieferungsstatus wird im Abschlussbericht genannt.

Der frühere eigene Update-/Publisher-Server wurde entfernt. Das ASP.NET-Projekt stellt weiterhin ausschließlich die bestehende Lobby bereit; optional bestimmt `POKE_MINIMUM_VERSION` die Mindestversion für Lobbybeitritte. GitHub Releases ersetzt nicht das noch fehlende Lobby-Hosting oder die noch nicht implementierten Multiplayer-Kämpfe.

## Referenzen

- [GitHub Releases API](https://docs.github.com/en/rest/releases/releases)
- [Workflow Dispatch API](https://docs.github.com/en/rest/actions/workflows)
- [GitHub REST Best Practices und bedingte Abfragen](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api)
