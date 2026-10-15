# AUTO BOSS 43.0 – Smooth Traffic & Clean Asphalt

Basis: AUTO BOSS 42.0. Fokus: 55-Sekunden Samsung-Test mit sichtbaren 44–99 FPS im Verlauf.

## Grafik & Performance

- Detailmodelle der KI-Fahrzeuge werden erst in 38–64 m Entfernung gebaut, nicht mehr bei 145 m. Bei niedriger Bildrate wird eine kleinere Detaildistanz verwendet.
- Zwischen zwei aufwendigen Fahrzeug-Upgrades liegen mindestens 0,65 Sekunden. Maximal fünf KI-Fahrzeuge mit vollem Detail gleichzeitig.
- Alte schwarze Reifenspuren und dunkle Asphalt-Flickrechtecke aus Version 17, 20, 21 und 26 sind entfernt. Asphalt-Verschleiß kommt nun aus dem Material-Shader.
- Asphalt- und Terrain-Noise ohne trigonometriche sin()-Hash-Aufrufe pro Fragment; etwas ruhigeres, weniger flimmerndes Straßenkorn.
- Entfernte Busch-Chunks haben 280 m Sichtdistanz, direktionale Schatten enden bei 75 statt 90 m.
- Karriere, HUD, Weltobjekte, Steuerung und vorhandene Speicherstände bleiben grundsätzlich erhalten.

## Test

GitHub Actions Android APK bauen und 42.0/43.0 auf demselben Samsung mit gleichen Einstellungen testen. Je 1 Minute: bei 0 km/h, Fahrt mit Verkehr, Regen. Min/Max/FPS allein beweisen keinen stabilen Frametakt: auf sichtbare Aussetzer und FPS-Tiefs achten.

Quelltext/ZIP-Konsistenz geprüft; keine Godot-Laufzeit oder Android-Build in dieser Umgebung verfügbar. Eine echte Leistungssteigerung ist noch nicht gemessen.
