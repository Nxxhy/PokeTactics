# LAN-Multiplayer und Launcher ab 9.3.0

## Host und Gäste

1. Host: Launcher öffnen, **LAN-LOBBY → Server auf diesem PC starten**. Angezeigte Adresse (z. B. `192.168.178.20:18790`) teilen.
2. Gäste: **LAN-LOBBY → Mit einem anderen Host verbinden**, Adresse eingeben und **Adresse prüfen & verwenden**.
3. Alle: **SPIELEN**. Host erstellt eine Lobby und teilt den Lobby-Code; Gäste treten bei.
4. Bei 2–8 Teilnehmern stellen sich alle bereit. Der Host startet die Partie.
5. Teams kaufen und aufstellen; **Bereit für den Kampf** anklicken. Der nächste Kampf beginnt, sobald alle bereit sind, spätestens nach 90 Sekunden Vorbereitung.
6. Launcher während der Partie geöffnet lassen. Zum Beenden zuerst das Spiel schließen, dann den lokalen Server beenden.

Beide PCs müssen im selben privaten IPv4-Netz sein. Windows muss eingehende Verbindungen für `PokeLobby.exe` im privaten Netzwerk zulassen; der Launcher verändert keine Firewall-Regeln. Keine Router-Portfreigabe nötig. Gast-WLANs mit Client-Isolation verhindern Verbindungen. Bei belegtem Port einen anderen Port zwischen 1024 und 65535 wählen. Die gespeicherte Gast-Adresse muss beim nächsten Launcher-Start erneut geprüft werden.

Setup und Updates enthalten Server, Laufzeit und Spielengine. Docker und eine separate .NET-/Godot-Installation sind nicht nötig. Die Online-Prüfung der neuesten Version bleibt auch für LAN erforderlich. Der lokale Server selbst braucht keinen GitHub-Zugriff.

## Spielregeln

Jeder Trainer beginnt mit drei Leben. Eine Niederlage kostet genau ein Leben, nur Siege erhöhen die persönliche Runde. Die gemeinsame Kampfphase zählt separat. Gegner wechseln zwischen den noch lebenden Teilnehmern; der letzte überlebende Trainer gewinnt. Bei einem Unentschieden verlieren beide ein Leben; scheiden alle gleichzeitig aus, endet die Partie ohne Sieger. Bei ungerader Teilnehmerzahl rotiert ein Freilos: sechs Gold und zwei EP, kein Sieg und kein Lebensverlust.

Shop, Verschmelzungen, Synergien, Augments und Fähigkeiten verwenden die bestehende Spiellogik. Bei Ablauf der Vorbereitungszeit wird ein noch offenes Augment automatisch gewählt und das Team aus der Bank aufgefüllt. Nach Bereitschaft sind Änderungen bis zur nächsten Vorbereitung gesperrt. Nach den Kampfanimationen bestätigen die Clients das Ergebnis; spätestens nach 150 Sekunden beginnt die nächste Vorbereitung. Ausscheidende Spieler können die Tabelle verfolgen.

Der Host berechnet Käufe, Teams und Kampfergebnisse in einer eigenen Spielengine. Clients übertragen Befehle, keine frei bestimmbaren Ergebnisse. Beide Seiten spielen dieselbe deterministische Kampfsequenz aus ihrer Perspektive ab. Doppelte Befehle führen nicht zu doppelten Käufen. Gegner-Augments wirken auf das richtige Team.

Kurze Verbindungsunterbrechungen können innerhalb von 30 Sekunden aufgeholt werden. Danach scheidet ein Gast aus. Verlässt der Host die Lobby oder bleibt länger getrennt, endet die gesamte Partie. Es gibt keine Host-Übernahme und keine Wiederaufnahme nach Neustart. Nach Partiestart können keine neuen Teilnehmer nachrücken. Ein lokaler Server ersetzt keine Interneterreichbarkeit. Das bisherige Linux-Docker-Image enthält noch keine Spielengine und ist daher nicht für diese gemeinsamen Kämpfe eingerichtet.

## Launcher

Gebündelte Power-Green-Pixelschrift, dunkelgrüne Rahmen, cremefarbene Inhalte und mintfarbene Auswahl. Spiel/Updates und LAN besitzen getrennte Reiter. Lange Beschreibungen umbrechen, Inhalte scrollen und der Spielstart bleibt in der unteren Leiste erreichbar. Fenster ab 720 × 720 werden unterstützt. Keine neuen externen Bildassets.

Der Launcher startet und beendet nur seinen eigenen Server; nach Launcher-Absturz beendet sich der Server über das geschlossene Eingaberohr. LAN-Anfragen sind auf private IPv4- und Loopback-Adressen begrenzt, Host und Gäste benötigen dieselbe Version. GitHub-Updates verwenden weiterhin HTTPS und signierte Pakete.

## Prüfung und Grenzen

Automatisiert bestanden: 101 Prüfungen der Mehrspieler-Spielregeln einschließlich einer vollständigen 8er-Partie; HTTP-Integration mit echter Spielengine einschließlich kompletter Partie, Wiederverbindung, Zeitüberschreitung, Berechtigungen und doppelten Befehlen; zwei separate Godot-Spielprozesse mit je elf Prüfungen einer gemeinsamen Partie. Zusätzlich: 77 Updater-/Launcher-Prüfungen (Layout bei 720 × 720, 900 × 840 und 1920 × 1080), 21 LAN-Host-, 12 Endpunkt-, elf Startfreigabe-, 217 Menü- und 1.005 Spiellogik-Prüfungen.

Die Layout-Prüfungen ersetzen keine visuelle Abnahme. Die Windows-Computersteuerung konnte das Launcher-Fenster nicht aktivieren; eine visuelle Prüfung im Fenster-/Maximiert-Modus bleibt offen. Ein zweiter physischer PC steht derzeit nicht zur Verfügung: LAN-Verbindung zwischen zwei Geräten und deren Windows-Firewall sind noch nicht geprüft.

Entwicklertests: `tools/test-multiplayer.ps1` nach `tools/build-platform.ps1`; die Release-Automation führt beide aus. Veröffentlichungsablauf: [GitHub Releases](GITHUB-RELEASES.md).
