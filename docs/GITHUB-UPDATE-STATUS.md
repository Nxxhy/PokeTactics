# Prüfung vom 11. September 2026

## Lokal abgeschlossen

- Spiel-Repository lokal initialisiert; Remote `https://github.com/Nxxhy/PokeTactics.git`, öffentlicher Zielkanal nach Nutzerentscheidung.
- GitHub-Updater, Entwickler-App, Release-Workflow, Paket-Signiertool und neue Setup-Version 9.1.0 gebaut.
- 47 Prüfungen für den GitHub-Updater bestanden. GitHub-Antworten wurden simuliert; der tatsächliche Launcher lädt signierte Testpakete, aktiviert Versionsverzeichnisse und startet die echten Spiel-Binärdateien. Zwei aufeinanderfolgende Versionswechsel, unvollständige Releases, manipulierte Signatur/Prüfsumme, Download-Abbruch, ZIP-Pfadtraversal, Offlinebetrieb, ETag/304, persistentes Rate-Limit-Backoff, individuelle Zugangsdaten, gesperrte Aktivierungsdatei und laufendes Spiel wurden geprüft.
- 1.005 Spiellogik-Prüfungen und 16 HTTP-Lobby-Prüfungen bestanden. Die beiden alten Update-/Publisher-Endpunkte liefern jetzt 404.
- Tatsächliche Setup-Migration getestet: vorhandenen 9.0.0-Installer installiert, 9.1.0 darüber installiert, neuen aktiven Launcher, vorherige Version, GitHub-Konfiguration und unveränderte Einstellungs-Testdatei geprüft; installiertes Spiel erfolgreich gestartet. Testinstallation danach deinstalliert.
- Release-Paket 9.1.0 lokal RSA-PSS-signiert. Der Signierer prüft die Übereinstimmung mit dem im Installer enthaltenen öffentlichen Schlüssel.
- PowerShell-Syntax und Workflow-YAML geprüft. Der Workflow ist noch nicht auf einem GitHub-Runner gelaufen.
- Öffentliche Quellen vor dem Commit auf private Schlüssel und typische GitHub-Tokens geprüft; keine Treffer. Der private Schlüssel liegt ausschließlich lokal mit Windows DPAPI geschützt und ist von Git ausgeschlossen.

## Für den öffentlichen Betrieb noch erforderlich

Das externe Repository wurde noch nicht angelegt und es wurde nichts zu GitHub hochgeladen. Der Nutzer hat den GitHub-MCP-Connector installiert; dessen Werkzeuge waren in dieser laufenden Aufgabe jedoch noch nicht aufrufbar. Der alternativ geöffnete Browser zeigte eine GitHub-Anmeldeseite.

Nach verfügbarem GitHub-Zugriff: Repository öffentlich anlegen, vorbereitete Quellen pushen, `UPDATE_SIGNING_PRIVATE_KEY` sicher als Actions-Secret hinterlegen, Release-Workflow ausführen und das vollständige Release gezielt veröffentlichen. Danach den geforderten Ablauf mit **zwei echten GitHub-Releases** und dem tatsächlichen Netzwerk-Download durchführen. Dieser öffentliche Ende-zu-Ende-Test ist offen und wird durch die lokalen Prüfungen nicht ersetzt.

Lobby-Hosting bleibt unabhängig davon noch einzurichten. Ein Windows-Authenticode-Zertifikat ist nicht vorhanden; die Update-Pakete besitzen stattdessen die beschriebene eigene kryptografische Signatur.
