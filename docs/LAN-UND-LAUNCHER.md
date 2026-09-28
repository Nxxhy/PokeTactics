# LAN-Lobbys und Launcher ab 9.2.0

## Auf dem Host-PC

1. Den Launcher öffnen und **LAN-LOBBY** wählen.
2. **Server auf diesem PC starten** anklicken. Standardport: **18790**.
3. Eine angezeigte LAN-Adresse, beispielsweise `192.168.178.20:18790`, an die Mitspieler weitergeben. Bei mehreren Netzwerkkarten die Adresse des gemeinsamen WLAN/LAN wählen.
4. **SPIELEN** wählen und im Spiel **Lobby erstellen**. Den angezeigten Lobby-Code ebenfalls weitergeben.
5. Den Launcher geöffnet lassen. Zum Beenden zuerst das Spiel schließen, dann im Launcher **Lokalen Server beenden**.

## Auf den Gast-PCs

1. Im Launcher **LAN-LOBBY** öffnen und unter **Mit einem anderen Host verbinden** die Host-Adresse eingeben.
2. **Adresse prüfen & verwenden** anklicken. Der Dienst und die identische Spielversion werden überprüft.
3. **SPIELEN**, dann **Lobby beitreten** wählen und den Lobby-Code eingeben.

Beide PCs müssen im selben privaten IPv4-Netz sein. Windows muss eingehende Verbindungen für `PokeLobby.exe` im privaten Netzwerk zulassen; der Launcher verändert keine Firewall-Regeln. Keine Router-Portfreigabe nötig. Gast-WLANs mit Client-Isolation verhindern Verbindungen. Bei einem belegten Port einen anderen Port zwischen 1024 und 65535 wählen. Die zuletzt eingegebene Gast-Adresse wird gespeichert, aber beim nächsten Launcher-Start erst durch erneutes Prüfen aktiviert.

Der Server ist inklusive Laufzeit im Setup und im signierten Update-Paket enthalten; Docker, eine separate .NET-Installation und öffentliches Hosting sind dafür nicht nötig. Die bestehende Online-Versionspflicht bleibt auch bei lokalen Lobbys bestehen. Der lokale Lobbyserver benötigt selbst keinen GitHub-Zugriff.

**Funktionsumfang:** bis zu acht Teilnehmer, Lobby-Code, Bereitschaftsstatus, Host-Rechte, Entfernen von Gästen, Verlassen/Schließen und Wiederverbindung. Gemeinsame Multiplayer-Kämpfe sind weiterhin nicht implementiert; die Oberfläche weist darauf hin. Ein lokaler Server ersetzt keine Interneterreichbarkeit.

## Gestaltung

Der Launcher verwendet weiterhin die gebündelte Power-Green-Pixelschrift. Dunkelgrün `#285840` rahmt cremefarbene Inhalte `#F8F8E8`; Mint `#B8D8A0` kennzeichnet Auswahl und Spielstart. Ein selbst gezeichneter Pixel-Pokéball und Grasmarkierungen verbinden ihn mit dem Spiel. Es wurden keine neuen externen Bildassets eingebunden.

Zwei beschriftete Reiter trennen Spiel/Updates und LAN. Der Spielstart bleibt in einer festen unteren Leiste erreichbar. Inhaltsflächen scrollen, Labels umbrechen anhand ihrer verfügbaren Breite. Buttons haben sichtbare Rahmen sowie Auswahl-, Hover-, Fokus- und deaktivierte Zustände. Standard-Windows-Tastaturnavigation bleibt erhalten; Eingaben besitzen zugängliche Namen. Fenstergrößen ab 720 × 720 werden unterstützt.

## Technik und Prüfung

`LanHost` startet ausschließlich den mitgelieferten Prozess, prüft eine zufällige Instanzkennung und stoppt nur den eigenen Server. Bei Launcher-Absturz beendet der Server sich über das geschlossene Eingaberohr. LAN-Anfragen sind auf private IPv4- und Loopback-Adressen beschränkt. Host und Gäste benötigen dieselbe Version. Öffentliche Dienste behalten HTTPS; GitHub-Updates verwenden unverändert HTTPS und signierte Pakete.

Automatisiert getestet: 21 LAN-Host-Prüfungen mit dem tatsächlich gebündelten Server und zwei HTTP-Sitzungen; 12 Godot-Prüfungen der erlaubten/verbotenen Endpunkte; sieben Integrationsprüfungen mit zwei echten Godot-Lobbyclients; 16 HTTP-Lobby-Regressionen; 217 Menüprüfungen ohne sichtbares Fenster; 71 Updater-, elf Startfreigabe- und 1.005 Spiellogik-Prüfungen. Die Tests umfassen Portkonflikt, Neustart, verlorenen Launcher, Bereitschaft und Versionskonflikt.

[Windows-Build 9.2.0](https://github.com/Nxxhy/PokeTactics/actions/runs/36395314219) ist erfolgreich. [Release v9.2.0](https://github.com/Nxxhy/PokeTactics/releases/tag/v9.2.0) ist veröffentlicht; die öffentlichen Update-Metadaten, Signatur, Prüfsummen-Datei und Paketgröße wurden mit dem tatsächlichen Updater verifiziert.

Die manuelle Computer-Use-Prüfung wurde durch die Escape-Taste gestoppt. Die visuelle Prüfung von Fenster-/Maximiert-Darstellung ist deshalb nicht abgeschlossen. Eine Verbindung zwischen zwei physischen Rechnern einschließlich Windows-Firewall wurde ebenfalls noch nicht geprüft.
