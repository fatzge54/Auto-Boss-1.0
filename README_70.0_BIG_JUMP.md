# AUTO BOSS 70.0 – GERMAN ROADS WORLD REMASTER

**Entwicklungsstand:** spielbarer Open-World-Prototyp auf Basis von AUTO BOSS 63.0. Weder die vollständige AAA-Gesamtvision noch die reale Android-Performance wurden hier abschließend getestet.

## Wichtige Änderungen gegenüber 63.0

- **Straßen & Stadtgestaltung:** zusätzliche Kreuzungsdetails, Zebrastreifen, Haltelinien, Seitenwege, Straßenbegrenzungen, Richtungsflächen und synchronisierte Ampelanzeigen.
- **Architektur:** Dachgeometrien mit Giebeln, Fensterbänke, Seitenfenster, Balkone, Schaufenster, Lieferhallen und Hallenlüftungen. Instancing (MultiMesh) reduziert die Zahl einzelner 3D-Objekte.
- **Umgebung:** regionale Farbgestaltung für Stadt, Feld und Mittelgebirge sowie zusätzliche Feldreihen und Straßenleitpfosten.
- **Fahrzeuge:** neu generierte, verjüngte Karosserieschale statt eines reinen Quaderkörpers; zusätzliche Außendetails sowie Fahrzeugklassen-Spezialmerkmale.
- **Verkehr:** vereinfachte Ampelphasen, Mindestabstände und Abbremsen von KI-Fahrzeugen vor Kreuzungen. Noch keine vollständige Straßenverkehrsordnung-KI.
- **Wetter:** dynamische Himmelstöne, nachts sichtbare Fenster-/Lampenemissionen, umschaltende Straßennässe, vereinfachte Regenstreifen und fahrzeuggebundenes Abblendlicht.
- **Navigation:** zusätzliche Abbiegehinweise, zeitlich bewertete Expressüberführungen, Übersichtskarte und transparente Bonusabrechnung.
- **Savegame:** Fortschritt und Expressfahrzeit werden gespeichert; automatische Sicherung alle 70 Sekunden während der Fahrt.
- **Mobile:** Beim ersten Start wird das Performance-Profil gewählt; auf Wunsch höhere Grafikstufen mit mehr Stadtgebäuden/Vegetation/Traffic.
- **Altstand:** Die ursprünglichen `main.gd`, `legacy_main.tscn` und die Dokumentationen bleiben im Archiv. Die neue `main.tscn` startet den Open-World-Zweig.

## Schnellstart via GitHub (Android)

1. ZIP entpacken.
2. **Den Inhalt** von `Auto-Boss-1.0-main/` (inklusive des versteckten Ordners `.github/`) **in das Wurzelverzeichnis** des bestehenden GitHub-Repositories hochladen. Keine zusätzliche Ordner-Ebene erzeugen.
3. In GitHub unter **Actions** den Workflow **AUTO BOSS 70 - Android & Open World** starten oder die `main`-Branch aktualisieren.
4. Nach erfolgreichem Build das Artefakt **AUTO-BOSS-70.0-APK** herunterladen und auf Android testen. Ein erfolgreicher Build ist kein Garantiebeweis für stabile FPS.
5. **Bei Fehlern** den Action-Log nach `Parse Error`, `SCRIPT ERROR`, `export` und `Android` prüfen und uns den Fehlerabschnitt geben.

## PC / Godot

Ordner `Auto-Boss-1.0-main/` in Godot 4 öffnen und `main.tscn` starten. Für Ressourcenimporte erst einmal den Godot-Editor öffnen.

## Diagnose und Qualität

```bash
python3 tools/check_open_world70.py
# Bei installiertem Godot:
godot --headless --editor --path . --import --quit
godot --headless --path . --quit-after 5
```

Die Python-Prüfung prüft Dateireferenzen, Scriptstruktur und erwartete Funktionen. **Sie ersetzt keinen Godot-Parse-Test oder einen Android-Lauftest**. Der GitHub-Workflow soll diese zusätzlichen Kontrollen vor dem APK-Export übernehmen.

## Bekannte Grenzen

- Die 25 × 25 km sind eine **prozedurale Koordinatenfläche**, nicht 625 km² handmodellierte deutsche Großstädte.
- Viele Straßen verlaufen aktuell als verbundenes Raster; echte Autobahnkreuze und komplexes kurviges Straßennetz fehlen noch.
- Licht, Regen, Schäden und Verkehr sind vereinfachte Simulationssysteme und nicht mit einer AAA-Simulation gleichzusetzen.
- Preis/Spielbalance der 44 Vertragsangebote ist vorläufig.
- Das geschlossene Handy-Testergebnis (Start, Speicherbedarf, Bildrate, Grafik, Regen) ist noch offen.
- Godot oder eine Android-Emulation sind in dieser Erstellungsumgebung nicht verfügbar; daher kein seriöses FPS- oder Laufzeitversprechen.

## Priorität für die nächste geprüfte Ausbaustufe

Android-Start und Logs prüfen → flüssiges Rendering sicherstellen → realistisches Straßennetz → hochwertige Außenmodelle → GPS mit Verkehrsregeln → echte Logistik-Langzeitwelt.
