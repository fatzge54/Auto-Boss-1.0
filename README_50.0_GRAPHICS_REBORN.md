# AUTO BOSS 50.0 – GRAPHICS REBORN

**Basis:** AUTO BOSS 43.0 / Godot 4.x, Android GL Compatibility.

## Grafische Kernänderungen

1. **Neu erzeugte Asphalt-Texturen:** nahtlose hochaufgelöste Asphalt-Albedo und Normalmap statt körnigem Hash-Look. Texturen werden mit Mipmaps, anisotropem Filter und realistischen Reifenspuren eingesetzt. Bei Regen wird das Asphaltmaterial dunkler und glänzender.
2. **Kontinuierliche Landschaft:** 1100 Meter breites texturiertes Grasland beseitigt den scharfen, hellen Geländeabschluss. Procedural Mesh-Terrain bildet beiderseits der Straße sanfte, kilometerlange Hügel, in 20 Sichtweite-Chunks unterteilt.
3. **Bäume mit natürlichen Silhouetten:** die früheren Kugel-/Kegel-Bäume sind auf texturierte gekreuzte Flächen umgestellt. MultiMesh gruppiert die Bäume in 220-m-Abschnitte; jede gekreuzte Baumkarte benötigt insgesamt nur 4 Dreiecke.
4. **Natürlichere Büsche:** die bisherigen 3D-Kugeln am Straßenrand nutzen jetzt alpha-getestete, texturierte Pflanzen. Statt vieler kleiner Meshes werden sie gruppenweise gerendert.
5. **Atmosphäre:** schlanke Wolkenkarten im Himmel; weichere direkte Schatten. Die Himmel-/Wetter-Logik und die bestehende Steuerung bleiben erhalten.
6. **Überlagerte Fahrbahnelemente entfernt:** alte dunkle Asphalt-Rechtecke, harte Querstriche und kugelige Hecken werden nicht mehr generiert.
7. **Leistung:** 3D-Bäume und Büsche haben keine dynamischen Schatten, die Entfernungen für das Rendern sind begrenzt. Bestehende KI-LOD und bewegte Kamera bleiben erhalten.

## Herkunft und Bearbeitung

Sämtliche neuen .png-Dateien in `assets/graphics50/` sind eigenständig prozedural erzeugte Grafiken. Sie benötigen keine externen Downloads oder Asset-Lizenzen. Ein reproduzierbarer Generator befindet sich unter `tools/generate_graphics50.py` (Python: numpy, scipy, Pillow).

## Android-Build / GitHub

- ZIP **entpacken** und **den Inhalt des Ordners `Auto-Boss-1.0-main`** in das Wurzelverzeichnis des GitHub-Repositories legen.
- GitHub Actions führt zunächst den neuen Godot-Asset-Import aus und exportiert anschließend die APK (Android arm64).
- APK nach erfolgreichem Workflow als Artefakt **AUTO-BOSS-50.0-APK** herunterladen.
- Alte getestete 43.0 als Backup behalten.

## Test und offene Punkte

Der Dateiaufbau und die Ressourcereferenzen sind statisch geprüft. **In dieser Arbeitsumgebung war kein Godot-Editor oder Android-Gerät verfügbar**; daher konnten Shader-Kompatibilität, Aussehen auf dem Gerät, Android-Build, Renderzeiten und FPS nicht live bestätigt werden. Diese Version ist ein großer Grafik-Experimentalsprung, keine bereits im Gerät validierte 60-FPS-Version.

Teste jeweils 1 Minute: Stillstand auf freier Straße, Fahrt mit mehreren KI-Fahrzeugen, Regenfahrt und Nacht; beachte FPS-Minima und sichtbares Mikroruckeln. Texturimport oder Shader-Fehler in GitHub Actions bitte über das rote Fehlerprotokoll identifizieren.

**Wichtig:** Das Fahrzeugmodell wurde nicht ersetzt, Spielstände bleiben logisch kompatibel; das Paket hat keine neue Fahrphysik. Hochwertige PBR-Scans, Gebäude-Assets und echte volumetrische Beleuchtung wären ein weiterer (teurerer) Ausbau.
