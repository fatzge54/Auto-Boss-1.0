# AUTO BOSS 63.0 – VISUAL RECOVERY

## Warum dieser Patch?

Das am 15. Oktober 2026 bereitgestellte Smartphone-Video zeigt eine sehr helle, nahezu einfarbige Umgebung, leer wirkende Straßen, blockige Gebäude und ein stark vereinfachtes Fahrzeugmodell. Menüs, Auftragsbörse und die eigentliche Fahrt sind bereits vorhanden. Diese Version setzt bei den sichtbaren Defiziten an, ohne den Open-World-Kern neu zu schreiben.

## Änderungen

- Fogenvelope für klares Wetter stark reduziert; Regen/Nebel bleiben unterscheidbar. Dunkleres Himmelblau und geringere Beleuchtungsüberstrahlung.
- Terrain- und Straßenmaterialien doppelseitig gerendert, damit kein Himmel durch fehlende Rückseiten scheint.
- Ländliche Bodendetails: Felder, Bodenstreifen, Wiesenpatches, Büsche und zweite Nadelbaumform; zusätzliche Vegetationsinstanzen.
- Straßen mit abgesetzten Schotterseitenstreifen, verschiedenen Höhenversätzen, durchgehenden Randlinien, gestrichelten Fahrspurmarkierungen und Bordsteinkanten.
- 3D-Gebäude mit Fassadenfenstern, Eingangstüren, einem Fundamentsockel und erhöhter Stadtdichte; MultiMesh-Batching statt je Gebäude eigener Nodes.
- Zusätzliche Straßenbegrenzungen und die Ansätze von Leitplanken.
- Überarbeitetes Player-Car mit geneigter Frontscheibe und Heckscheibe, Fensterteilen, Spiegeln, Kühlergrill, Stoßfängern, Radnaben, Reifen und Lichtdetails. Bis zur professionellen GLB-Klasse besteht noch ein großer qualitativer Abstand.
- Verkehr mit Scheinwerfern, Rücklichtern und Stoßfängern.
- Nahkamera für eine besser erkennbare Karosserie; HUD mit dunklen Infopanels für Lesbarkeit.
- GPS-Minikarte markiert entfernte Ziele am Rand statt vollständig außerhalb des Anzeigebereichs.
- Bestehende Karriere-, Open-World- und Speicherdateien kompatibel belassen. `legacy_main.tscn` unverändert.

## Entwicklungsgrenzen

Keine behauptete AAA-Fotorealistik, keine nachgebildeten Großstädte, keine dichte Fußgänger-KI, kein realistisches Reifenfederungsmodell und kein gemessener 30-/60-FPS-Erfolg. Die 25 × 25 km Welt bleibt eine regelbasiert erzeugte Prototypkarte. Die zusätzliche Gebäudezahl kann die Performance auf schwächeren Geräten senken; bei Bedarf das Profil `PERFORMANCE` verwenden.

**Teststatus:** Skriptdateien sind statisch überprüft, ein vollständiger Godot-Parser-, GPU- und Android-Lauftest ist in dieser Umgebung nicht möglich. Daher erst GitHub Actions Build und dann Test auf dem Telefon.

## GitHub

ZIP entpacken und den **Inhalt** aus `Auto-Boss-1.0-main` in das vorhandene Repository einpflegen. Vorher Backup/Commit der laufenden Version 62.0 anlegen. `.github/workflows/android-build.yml` muss ebenfalls ersetzt werden. Für neue Repositories GitHub Actions Berechtigungen und Exporttemplates prüfen.
