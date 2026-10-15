# AUTO BOSS 51.0 – ROADSIDE REMASTER

Basis: AUTO BOSS 50.0. Keine Änderungen an Fahrphysik, Missionen, Karriere oder Spielständen.

## Änderungen

- **Schwarze Fahrbahn-Flecken beseitigt:** Zwei alte Code-Stellen aus 10.0 und 22.0 zeichneten immer noch 24 dunkle Rechtecke über dem Asphalt. Beide entfernt.
- **Gebäude sichtbar überarbeitet:** Statt eintönigen flachen Klötzen besitzen die Häuser jetzt Fensterfassaden aus eigens generierten Plaster-/Klinker-Texturen sowie geneigte Ziegeldächer.
- **Lärmschutzwände:** Strukturierte Metall-/Akustikpaneele statt einfarbiger blauer Flächen.
- **Menüs:** Die veraltete Versionsanzeige „34.0“ bei Niederlassungen/Contract Command wurde aktualisiert.
- **Performance:** Nur rund 21 zusätzliche, sehr einfache Dach-Meshes; Fassaden und Paneele teilen sich Materialien und schalten sich aus großer Entfernung ab. Keine neuen physikalischen Objekte.

## Dateien

Neue Texturen liegen unter `assets/graphics51/` (5 PNGs). Der Ordner `assets/graphics50/` bleibt vollständig erhalten. `main.gd` und `scripts/main.gd` sind identisch und Godot lädt `scripts/main.gd` über `main.tscn`. Die GitHub-Actions-Builddateien sind im Paket.

## Installation auf GitHub

Den Inhalt des entpackten Ordners `Auto-Boss-1.0-main` in das Repository-Hauptverzeichnis übernehmen: inklusive `assets/graphics51`, `scripts`, `project.godot`, `main.tscn` und `.github/workflows/android-build.yml`. Die ZIP-Datei **nicht einfach als Datei** im Repo speichern. Auf einem Samsung-Handy kann die GitHub-Weboberfläche das Hochladen ganzer Ordner einschränken. Ordnernamen müssen exakt übereinstimmen (Groß-/Kleinschreibung).

## Test

Bei der nächsten APK die Stellen mit dunklen Rechtecken prüfen; Häuser aus ca. 50–150m betrachten. FPS bei Stillstand, Verkehr, Regen und Nacht jeweils testen. Bisher sind nur statische Code-/Dateiprüfungen erfolgt; **kein** realer Godot-Build, kein Android-Test oder garantierter FPS-Gewinn.
