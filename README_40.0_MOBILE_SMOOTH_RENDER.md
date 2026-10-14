# AUTO BOSS 40.0 – Mobile Smooth Rendering

## Änderungen

- Statische Straßen- und Landschaftsboxen: beim Spielstart zu MultiMesh-Draw-Gruppen pro Material und 240-m-Streckenabschnitt zusammengefasst. Laufende Fahrzeugmodelle, KI-Fahrzeuge, UI, Straße-/Wiesen-Shader bleiben unberührt.
- Verhindert übergroße 3-km-Instanzgruppen; Abschnitte sind weiterhin einzeln per Frustum-Culling sichtbar.
- Godot Physics Interpolation aktiviert; Teleport-Reset beim Missionsstart, KI-Spawns und Straßen-Loop, damit Kamera und Autos beim Rendern weniger ruckartig springen.
- Regen folgt dem Spieler im Physiktakt statt nur alle 0,1 s; Wettersimulation bleibt reduziert.
- Unveränderte Ereignis-/Tankstellen-Beschriftungen werden nicht mehr in jedem Physik-Tick neu gesetzt.
- Fahr-HUD zeigt Version 40.0 und FPS an. Beide Script-Kopien (`scripts/main.gd` aktiv, `main.gd` als Backup) sind identisch.
- Workflow-Artifact-Name jetzt `AUTO-BOSS-40.0-APK`.

## Samsung / GitHub

1. Den **Inhalt dieses ZIP-Ordners** in das vorhandene GitHub-Projekt übernehmen, inklusive `.github/workflows/android-build.yml`, `scripts/main.gd` und `project.godot`.
2. GitHub Actions unter `AUTO BOSS Android` starten bzw. Build abwarten.
3. `AUTO-BOSS-40.0-APK` herunterladen und auf dem Samsung testen.
4. FPS im Stand und bei Fahrt vergleichen; zuerst gerade Strecke, dann Regen und Tankstellen testen.

## Grenzen

Nur Quellcode-/ZIP-Prüfung in dieser Ausgabe. Die tatsächliche FPS-Zahl muss auf dem Android-Gerät gemessen werden. Für den Fall einer inkompatiblen GPU/Renderer-Konfiguration zuerst den Godot-GitHub-Actions-Buildlog prüfen. Bestehende Spielstände bleiben unter `user://autoboss.cfg` gespeichert.
