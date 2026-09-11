# UI-Korrekturen – Version 7

Der akzeptierte Smaragd-Stil bleibt erhalten. Die Textdarstellung berücksichtigt jetzt Breite, Höhe, Schatten und ganze Pixelpositionen. Beschreibungen verwenden die tatsächlich geformten Zeilen einschließlich Sonderzeichen zur Berechnung der Zeilenabstände. Bevorzugt werden 16 Pixel; kleinere Größen kommen nur bei Platzbedarf zum Einsatz. Das kompakte Detailfeld hat 20 Pixel mehr Höhe.

Shop: Pokémon-Bild, Preis, Rolle und Typen beziehungsweise Rabatt stehen in getrennten Bereichen. Auswahlpfeile erhalten einen eigenen Bereich im Button. Breite Fenster unter 800 Pixel Höhe verwenden die kompakte Aufteilung, damit das Ergebnisfeld nicht zwischen seinen Inhalten zusammengedrückt wird.

## Prüfung

- 459 Bedienprüfungen bestanden: Namen und Fähigkeiten aller 70 Linien, Menüs, Augments, Kauf/Verkauf, Drag-and-drop, Kampf und Replay.
- 28.567 geometrische Layout-Prüfungen bestanden: alle 70 Linien bei 1280×720, 1366×768, 1600×720, 1600×800, 1920×1080 und 2560×1080. Prüft Textgrenzen einschließlich Höhe/Schatten, tatsächliche Überlappungen im Detailfenster und Shop, Sprite-Abstände und Rabattpreise.
- 42 Perspektivprüfungen bestanden, einschließlich Drag-and-drop im echten Vollbild.
- 826 Animationsprüfungen bestanden. 20 Pokémon mit wiederholten 20 Fähigkeiten: Median 16,7 ms, 95. Perzentil 17,6 ms pro Bild; ohne Effektwelle 16,7 ms.
- Screenshots der kompakten und dreispaltigen Ansicht visuell kontrolliert.

Die Spielregeln wurden nicht verändert. Die Messungen beziehen sich auf diesen Rechner und die geprüften Fenstergrößen. Godot meldet weiterhin einen Fehler beim Lesen des Windows-Zertifikatsspeichers; die lokalen Offline-Tests bestehen trotzdem.

## Bankrahmen-Korrektur

Bank-Pokémon verwenden jetzt die Innenfläche mit sechs Pixeln Rahmenabstand. Sprite, Name und Sterne bleiben innerhalb dieser Fläche; auch die Platzierungsvorschau verwendet dieselbe Darstellung. Die Tile-Fläche für Drag-and-drop bleibt unverändert. Die Layoutsuite enthält jetzt explizite Prüfungen für belegte Bankplätze aller 70 Linien in sechs Fenstergrößen: 29.407 Prüfungen bestanden.
