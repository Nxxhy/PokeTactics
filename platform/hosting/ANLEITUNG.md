# Lobby-Hosting ab 9.1

Updates und Veröffentlichung laufen ausschließlich über `Nxxhy/PokeTactics` auf GitHub. Dieser Dienst ist nur für die bestehende Lobby zuständig, einschließlich acht Plätzen, Ready, Host-Rechten und Reconnect. Multiplayer-Kämpfe sind noch nicht implementiert.

1. Linux-Server mit Docker Compose bereitstellen; eine Domain per DNS auf dessen IP zeigen lassen und TCP 80/443 öffnen.
2. Das Hosting-Paket entpacken. Die Verzeichnisse `Server` und `hosting` müssen nebeneinander liegen.
3. In `hosting/.env` die tatsächlichen Werte eintragen:

   ```dotenv
   DOMAIN=lobby.deine-domain.example
   POKE_MINIMUM_VERSION=9.0.0
   ```

4. In `hosting` `docker compose up -d --build` ausführen. Caddy kümmert sich um HTTPS. `https://deine-domain/health` prüfen.
5. Im Spiel-Installer `platform/service.json` den Wert `endpoint` auf diese HTTPS-Adresse setzen und neu bauen. Bereits installierte Nutzer benötigen diese öffentliche Adresse einmalig in ihrer `service.json`; der Installer überschreibt vorhandene Lobby-Einstellungen nicht. Für GitHub-Updates ist diese Adresse nicht erforderlich.

Es werden keine Update-Pakete, Publisher-Tokens oder Signierschlüssel auf dem Lobby-Server benötigt. Lobbys liegen im Arbeitsspeicher; ein Neustart schließt sie. Genau eine Server-Instanz betreiben. `POKE_MINIMUM_VERSION` kann bei inkompatiblen Lobby-Protokolländerungen auf eine bereits verfügbare Version erhöht werden.

Der öffentliche Betrieb und ein Test von getrennten Geräten sind noch einzurichten. Die lokale Testabdeckung ist in den Projektberichten dokumentiert.
