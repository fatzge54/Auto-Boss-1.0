# AUTO BOSS 62.0 – Open World / German Roads

## Neu: technisch echte Weltkoordinaten statt Fahrbahnschleife

Die aktive Spielszene `main.tscn` verwendet jetzt `scripts/open_world/game.gd` und **keine** wiederholte 3-km-Straße mehr. Der Code verwaltet einen **25 × 25 km großen geografischen Bereich** (Koordinaten jeweils ±12.500 m), während die Landschaft in **400 × 400 m großen Sektoren** erzeugt und beim Fahren dynamisch geladen wird. Im ausgewogenen und detaillierten Modus sind maximal 25 Sektoren vorgesehen; im Performance-Modus sind es neun. Es gibt keine absichtliche Teleportation entlang der Straße. Die Gebäude, Vegetation und das Straßennetz werden aktuell regelbasiert und nicht manuell individuell modelliert.

## Aktueller Implementierungsstand

| Bereich | Implementiert (62.0) | Noch ausstehend / Qualität |
|---|---|---|
| Offene Welt | 25-km-Koordinatenwelt, Sektor-Streaming, bewaldetes Gelände, Straßenraster, 5 Stadtregionen | Individuelle Straßengeometrie, Handarbeit-Stadtteile, Tunneleinfahrten, echte Brücken |
| Fahrzeuge | 6 Klassen, unterschiedliche Leistung, Bremse, Masse, Treibstoff, Kollision/Schaden | Aufhängungsphysik mit Reifenmodellen, markenreife Cockpits, echte LKW-Auflieger |
| Gameplay | Abholfahrt → Fahrzeugübernahme → Zielübergabe → Vergütung | Fahrzeugübergabe-Protokolle, Zeitfenster, Verkehrsvorschriften |
| Karriere | Geld, Ruf, Auftragsstufen, 44 feste/prozedurale Verträge, Reparatur und Basis-Upgrades | Mitarbeiter als aktive NPC-Flotte, Gesellschaftsbilanzen, Verträge mit Fahrpersonal |
| GPS | Route über verbundenes Hauptstraßenraster, Minikarte, ETA, Zielmarkierung | A*-Routing, Baustellen-Umfahrung, Navigationssprachausgabe |
| Weltleben | Bis zu 16 nahe Verkehrswagen | Verkehrs-KI mit Ampeln, Vorfahrtsregeln und Fußgängern |
| Wetter | Sonne, Uhrzeit, Regen/Nebel-Status, Grip- und Sichtanpassungen | Regenpartikel, Pfützen, echte Schneedecke |
| Grafik | Vorhandene Asphalt-/Fassadentexturen, gebatchte Stadtgebäude und Bäume, Streaming | Hochdetaillierte Einzelgebäude, hochwertiges Landschafts- und Vegetationsmodell |
| Sound | Prozedural synthetisierter, loopender Grundmotor | Aufnahmen pro Antrieb, Verkehr, Wind, Stadtatmosphäre |
| Mobile | Touchbuttons Gas/Bremse/Lenkung, kompakte HUD-Elemente, drei Performance-Profile | Gerätespezifische Profile, langfristiger Performance-Nachweis |

Das ist ein **umfangreicher technischer Open-World-Prototyp**, **nicht** ein fertig produziertes AAA-Spiel mit 625 km² handgestalteter Welt. Alle im Dokument aufgeführten offenen Punkte bleiben echte Entwicklungsaufgaben.

## Start und Kontrolle

1. ZIP entpacken, Inhalt des Ordners `Auto-Boss-1.0-main` in ein Godot 4.7.2-Projekt oder in das GitHub-Repository kopieren.
2. Das vorhandene `.github/workflows/android-build.yml` baut wie bisher eine Debug-APK via GitHub Actions (bei Upload aller Dateien/Ordner).
3. Auf PC in Godot `project.godot` öffnen und `F6`/`F5` zum Starten benutzen.
4. Im Hauptmenü `AUFTRAGSBÖRSE` öffnen, einen freien Auftrag annehmen und zur gelben Markierung fahren.
5. Anhalten und `FAHRZEUG ÜBERNEHMEN` (oder `F`) drücken, anschließend zum Ziel fahren und abgeben.

## Steuerung

- PC: `W/↑` Gas, `S/↓` Bremse und Rückwärts, `A/D` oder Pfeile lenken, `F` interagieren, `C` Kamera, `M` Kartenzoom, `ESC` Pause.
- Android: `◀`/`▶`, `GAS`, `BREMSE`, `KAMERA`, `KARTE ±`, Übernahme/Übergabe.

## Kompatibilität und Bestandsschutz

- Die gesamte alte Version-61-Spielszene ist über `legacy_main.tscn` weiter vorhanden; `scripts/main.gd` und `main.gd` sind nicht überschrieben.
- Speicherdaten der alten Version liegen in `user://autoboss.cfg`; die neue Open World benutzt **getrennte Speicherstände** (`user://autoboss_open_world.cfg` und `user://autoboss_world_position.cfg`). Es gibt noch keine automatische Migration von Version 61.
- Die neue Welt benutzt bestehende Texturen in `assets/graphics50`, `graphics51`, `graphics60` und zusätzlich ein generiertes Audio in `assets/open_world`.
- Für die neuen GDScript-Dateien wurden automatisierbare Quelltext- und Strukturtests bereitgestellt. **Ein tatsächlicher Godot- oder Android-Lauf war in der bereitstellenden Umgebung nicht möglich.** Erst ein erfolgreicher GitHub-Build und ein Test auf Zielgeräten bestätigen die Lauffähigkeit.

## Wichtigste nächste Qualitätsblöcke

1. Godot-Parser/Android-Build prüfen und ggf. GDScript-Fehler beheben.
2. Auf dem Smartphone Ladehänger, RAM, FPS und Temperatur messen.
3. Verkehrssteuerung, Kollisionen mit statischen Gebäuden und Fußgängersicherheit ergänzen.
4. Statt des globalen Straßenrasters ein gestaltetes, verknüpftes Straßengraphsystem inklusive Autobahnkreuzen, Auf-/Abfahrten und echten Fahrspurregeln implementieren.
5. Eigene Gebiete mit wiedererkennbaren Landmarken und detaillierten Architektur-Modulen ersetzen.
6. Langfristig physischen Fahrzeugtransport, Fahrzeugschäden, Rückfahrlogistik, KI-Mitarbeiter und Wirtschaft vertiefen.
