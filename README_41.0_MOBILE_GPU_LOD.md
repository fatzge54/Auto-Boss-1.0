# AUTO BOSS 41.0 – Mobile GPU + Traffic LOD

**Basis:** AUTO BOSS 40.0 Smooth Rendering. Der bisherige Spielstand (`user://autoboss.cfg`), Fahrzeugsteuerung, Karriere und Missionslogik bleiben unverändert.

## Verbesserungen

1. **KI-Autos mit zwei Detailstufen:** Neue Verkehrsfahrzeuge erhalten zunächst eine sparsame Silhouette (Karosserie, Kabine, Scheiben, Räder, Rücklicht). Erst unter ca. 145 m Entfernung wird das ursprüngliche detaillierte Modell nachgeladen. Es wird maximal **ein Auto pro Physikframe** detailliert aufgebaut. Kollisionen, Spurwechsel und Tempo funktionieren auf den gleichen Fahrzeugknoten wie bisher.
2. **Regen als MultiMesh:** Die 42 Regentropfen werden aus **einer** `MultiMeshInstance3D` gezeichnet statt aus 42 separaten `MeshInstance3D`. Der Regen bewegt sich weiterhin mit dem Auto und wird alle 0,1 s aktualisiert.
3. **Lokale Straßenbeleuchtung:** OmniLight3D-Straßenlampen werden nur aktiviert, wenn Nacht/Regen herrscht und sie höchstens ca. **80 m** vom Auto entfernt sind. Die beleuchteten Lampen in der Nähe bleiben erhalten.
4. **Günstigere Fahrbahnoberfläche:** Zwei symmetrische Radspuren per `smoothstep` ersetzen vier teure `exp`/`pow`-Berechnungen im Asphaltshader. Grobes Korn, Ausbesserungen, Fugen und Fahrbahnränder bleiben vorhanden.
5. **Sonnenschatten:** Zwei statt vier Kaskaden mit ca. 90 m Schattenreichweite, damit nahe Fahrzeugschatten erhalten bleiben und die GPU entlastet wird.
6. **Bessere statische Rendergruppen:** Große Straßenstreifen bleiben eigenständig. Kleinere Straßendetails werden zusätzlich nach Straßenseite und 240-m-Abschnitt in MultiMeshes zusammengefasst.
7. **Tankstellenprüfung** auf 5 Hz reduziert statt in jedem Physikframe (plus direkte Prüfung beim Missionsstart).
8. Godot-Projekttitel und Fahr-HUD auf **41.0** aktualisiert; GitHub-Actions-Artefaktname `AUTO-BOSS-41.0-APK`.

## Einspielen und Testen auf Samsung

1. ZIP-Inhalt (`Auto-Boss-1.0-main/`) komplett ins GitHub-Repository übernehmen; insbesondere `.github/workflows/android-build.yml`, `scripts/main.gd`, `project.godot`. Das Script `main.gd` im Projektstamm ist eine identische Sicherung.
2. Im Tab **Actions** das Projekt `AUTO BOSS Android` bauen lassen; die erzeugte Datei findest du unter `AUTO-BOSS-41.0-APK`.
3. Installiere die APK. Überprüfe **FPS in 0 km/h**, bei normaler Fahrt, **Nacht/Regen** und mit viel Verkehr. Achte auf mögliche sichtbare Modellwechsel bei ca. 145 m.
4. Vergleiche FPS und Ruckeln unter möglichst gleichen Bedingungen mit Version 40.0.

## Qualitätshinweis

Diese Version wurde auf ZIP-/Quelltextkonsistenz überprüft. **Ein realer Godot-Editor-, Android-Build- oder Samsung-FPS-Test war hier nicht möglich.** Der Effekt auf Bildrate, Wärmeentwicklung und Lade-Ruckler kann daher erst im Gerätetest beurteilt werden. Falls Godot eine Fehlermeldung ausgibt, den Wortlaut und die betreffende Zeile mitteilen.
