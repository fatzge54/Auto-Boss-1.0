# AUTO BOSS 35.0 – WORLD GRAPHICS & PERFORMANCE

Basis: hochgeladenes GitHub-Projekt (34.0-Inhalte vorhanden, project.godot zeigte 33.0).

- Fahrbahn-Mittelmarkierungen: 240 einzelne MeshInstance3D durch eine MultiMeshInstance3D mit 240 Instanzen ersetzt.
- Material-Cache für wiederholte StandardMaterial3D-Farben, statt ständig neue Materialien zu erstellen.
- Wetter, Sonnenstand, Straßenlampen und Regenaktualisierung nur noch etwa 10-mal pro Sekunde, nicht bei jedem Physikframe. Zeitfortschritt bleibt durch akkumuliertes delta erhalten.
- Projektname und Fahr-HUD auf Version 35.0 gesetzt.
- Fahrzeugmodell und Fahrmechanik nicht verändert.

Wichtig: Noch kein vollständiger Grafik-Neuaufbau und keine gemessene FPS-Verbesserung. Bitte APK bauen und auf dem Gerät testen; Wetter/Regen/Beleuchtung und alle Spielmodi prüfen.
