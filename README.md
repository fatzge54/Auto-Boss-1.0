# AUTO BOSS 1.2 — Godot 4.7.2 Prototype

## Was enthalten ist
- echte 3D-Szene in Godot 4
- steuerbares Auto mit Gas, Bremse und Lenkung
- mobile Touch-Buttons
- Außen- und Cockpit-nahe Kamera
- dreispurige Autobahn mit Markierungen und Leitplanken
- 24 einfache Verkehrsfahrzeuge als Kulisse
- Stuttgart → Köln als stark verkürzte Spielroute
- stilisierte Landmarken: Stuttgart, Ludwigsburg, Heilbronn, Mannheim, Darmstadt, Limburg, Siegburg, Köln
- Tankanzeige, Schaden-Anzeige, Geschwindigkeit, Entfernung, Geld
- Missionsabschluss mit 450 € und Reputation
- Android-Exportpreset als Ausgangspunkt

## Projekt öffnen
1. Godot 4.7.2 oder neuer installieren.
2. `project.godot` importieren/öffnen.
3. F6/F5 bzw. Play drücken.

Desktop-Steuerung:
- W / Pfeil hoch: Gas
- S / Pfeil runter: Bremse
- A/D oder Pfeile: Lenken
- C: Kamera wechseln

Android:
- Für Android-Export müssen in Godot Android SDK/JDK und Export Templates eingerichtet sein.
- Für Play Store muss anschließend ein signiertes AAB erzeugt werden.
- Package-ID im Preset: `com.autoboss.game` (vor Veröffentlichung ggf. auf deine endgültige ID ändern).

## Wichtig
Alle Bauwerke sind derzeit stilisierte, selbst erzeugte Formen und keine exakten 3D-Kopien realer Gebäude.
Die Strecke ist spielerisch komprimiert und keine Navigationssimulation.


## Neu in 1.2
- kleinere, höher gesetzte Autobahnschilder
- zwei Überführungsbrücken
- sichtbare Autobahnausfahrten mit Beschilderung
- Gebäudegruppen an der Strecke
- zusätzliche Fahrzeugdetails (Seitenscheiben und Spiegel)
