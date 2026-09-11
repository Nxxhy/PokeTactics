# Prüfung vom 11. September 2026

## Lokal abgeschlossen

- Spiel-Repository lokal initialisiert; Remote `https://github.com/Nxxhy/PokeTactics.git`, öffentlicher Zielkanal nach Nutzerentscheidung.
- GitHub-Updater, Entwickler-App, Release-Workflow, Paket-Signiertool und neue Setup-Version 9.1.0 gebaut.
- 47 Prüfungen für den GitHub-Updater bestanden. GitHub-Antworten wurden simuliert; der tatsächliche Launcher lädt signierte Testpakete, aktiviert Versionsverzeichnisse und startet die echten Spiel-Binärdateien. Zwei aufeinanderfolgende Versionswechsel, unvollständige Releases, manipulierte Signatur/Prüfsumme, Download-Abbruch, ZIP-Pfadtraversal, Offlinebetrieb, ETag/304, persistentes Rate-Limit-Backoff, individuelle Zugangsdaten, gesperrte Aktivierungsdatei und laufendes Spiel wurden geprüft.
- 1.005 Spiellogik-Prüfungen und 16 HTTP-Lobby-Prüfungen bestanden. Die beiden alten Update-/Publisher-Endpunkte liefern jetzt 404.
- Tatsächliche Setup-Migration getestet: vorhandenen 9.0.0-Installer installiert, 9.1.0 darüber installiert, neuen aktiven Launcher, vorherige Version, GitHub-Konfiguration und unveränderte Einstellungs-Testdatei geprüft; installiertes Spiel erfolgreich gestartet. Testinstallation danach deinstalliert.
- Release-Paket 9.1.0 lokal RSA-PSS-signiert. Der Signierer prüft die Übereinstimmung mit dem im Installer enthaltenen öffentlichen Schlüssel.
- PowerShell-Syntax und Workflow-YAML geprüft; anschließend beide Release-Builds erfolgreich auf GitHub-Runnern ausgeführt.
- Öffentliche Quellen vor dem Commit auf private Schlüssel und typische GitHub-Tokens geprüft; keine Treffer. Die lokale Schlüsselkopie ist mit Windows DPAPI geschützt und von Git ausgeschlossen; GitHub besitzt nur das separat eingerichtete Actions-Secret.

## Öffentlicher Betrieb und tatsächlicher Update-Test abgeschlossen

Das öffentliche [Repository Nxxhy/PokeTactics](https://github.com/Nxxhy/PokeTactics) ist angelegt und enthält die Projektquellen. GitHub Actions ist aktiv. Der private Signierschlüssel wurde verschlüsselt als Environment-Secret `UPDATE_SIGNING_PRIVATE_KEY` in `release` hinterlegt; diese Umgebung lässt `main` und `v*`-Tags zu. Spiel und Launcher enthalten ausschließlich den öffentlichen Prüfschlüssel.

Zwei echte Windows-Builds wurden erfolgreich auf GitHub ausgeführt und veröffentlicht:

- [Build 9.1.0](https://github.com/Nxxhy/PokeTactics/actions/runs/34582604026), [Release v9.1.0](https://github.com/Nxxhy/PokeTactics/releases/tag/v9.1.0).
- [Build 9.1.1](https://github.com/Nxxhy/PokeTactics/actions/runs/34583111759), [Release v9.1.1](https://github.com/Nxxhy/PokeTactics/releases/tag/v9.1.1). Dieser Build wurde durch die tatsächliche Entwickler-App-Logik ausgelöst; Anmeldung über Git und Laden der Build-/Release-Historie wurden ebenfalls geprüft.

Der Installer 9.1.0 wurde von GitHub heruntergeladen und in einem isolierten Testverzeichnis installiert. Nach Veröffentlichung von 9.1.1 hat der tatsächlich installierte Launcher das neue Release erkannt, die Dateien heruntergeladen, Signatur und Paket geprüft, die neue Version aktiviert und sich durch den neuen Launcher-Prozess ersetzt. Das neue Spiel wurde erfolgreich gestartet; die Einstellungen-Testdatei sowie die vorherige Version blieben erhalten. Anschließend wurde die Testinstallation entfernt. Laufprotokoll lokal: `docs/github-live-update-tests.txt`.

Die Fehlerfälle (unvollständige Releases, Signatur-/Hashfehler, Download-Abbruch, Offlinebetrieb, gesperrte Installation und laufendes Spiel) wurden mit der tatsächlichen Updater-Implementierung und simulierten GitHub-Antworten getestet, ohne öffentliche Test-Releases zu beschädigen. Zusätzlich wurden die Metadaten beider öffentlichen Releases mit dem tatsächlichen GitHub-Updater und dem festgelegten Prüfschlüssel verifiziert.

Lobby-Hosting bleibt unabhängig davon noch einzurichten. Ein Windows-Authenticode-Zertifikat ist nicht vorhanden; die Update-Pakete besitzen stattdessen die beschriebene eigene kryptografische Signatur.
