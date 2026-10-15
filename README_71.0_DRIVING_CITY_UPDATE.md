# AUTO BOSS 71.0 – DRIVING & CITY UPDATE

## Aus dem Handy-Testvideo vom 15. Oktober 2026

Version 70.0 erreicht mit der Limousine innerhalb weniger Sekunden ungefähr 205 km/h. Das Fahrzeug bewegt sich in mehreren Szenen mit Autobahntempo auf Grasflächen, die Städte haben zu viele Lücken, und ein Auftrag ist beim Start nicht sofort aktiv. 71.0 behebt gezielt diese Punkte.

## Tatsächlich im Code geändert

1. **Anderes Beschleunigungsmodell:** Die Beschleunigung fällt mit steigender Geschwindigkeit. Die Limousine erreicht ihre Höchstgeschwindigkeit nicht mehr fast sofort. Fahrzeugklassen, Bremsen und Wetter bleiben erhalten.
2. **Geländefahrten:** Das Spiel unterscheidet befestigte Straßen von Grünflächen. Abseits der Straße sinkt die Traktion auf 64 % und die erreichbare Geschwindigkeit auf 23 m/s (= ca. 83 km/h). Sehr schnelle Geländefahrten werden kontinuierlich abgebremst. Kraftstoffverbrauch im Gelände steigt.
3. **Straßenbebauung:** In Städten und Dörfern werden Gebäude und Bäume teilweise entlang von Straßenfronten platziert. Die bestehenden Fassaden, Dächer und Fenster bleiben bestehen. Einfache blaue Wegweiser verbessern die regionale Erkennbarkeit.
4. **Schneller Missionseinstieg:** Der Startbildschirm besitzt jetzt „ERSTEN TRANSPORT SOFORT STARTEN“. Im freien Fahrmodus wird ohne Auftrag ein zusätzlicher Auftragsstartknopf eingeblendet. Bestehende Aufträge lassen sich fortsetzen.
5. **Bessere Kontinuität:** Kraftstoff, Schaden und Kilometerstand des Fahrerfahrzeugs werden zusammen mit Position und Karriere gespeichert. Bestehende Spielstände aus 70.0 behalten ihre Positions- und Karrieredaten.
6. **Fahrtkamera:** Leichte, kontrollierte Änderung des Sichtwinkels mit der Geschwindigkeit.
7. **Diagnose:** Neuer statischer Projektcheck `tools/check_open_world71.py`. Der GitHub-Android-Workflow verwendet diesen Check und legt sein APK unter `AUTO-BOSS-71.0-APK` ab.

## Installation bei GitHub

- Archiv entpacken, den **Inhalt** von `Auto-Boss-1.0-main/` (einschließlich `.github`) in das Wurzelverzeichnis deines vorhandenen GitHub-Repositorys übernehmen und Änderungen committen.
- Unter GitHub Actions den Workflow `AUTO BOSS 71 - Android & Open World` starten. APK aus dem Build-Artefakt `AUTO-BOSS-71.0-APK` beziehen.
- **Nicht** alte und neue `project.godot`-Dateien in getrennten Unterordnern mischen.
- Einen alten funktionierenden APK-Build als Rückfallstand behalten.

## Prüfpunkte auf dem Samsung

1. Startet das Menü und erscheint der Knopf „ERSTEN TRANSPORT SOFORT STARTEN“?
2. Wird ein Zielmarker sichtbar, erscheint eine Route auf der Minikarte und kann das Abholfahrzeug bei Stillstand übernommen werden?
3. Beschleunigt die Limousine auf Asphalt kontrollierter und wird sie auf Gras deutlich langsamer?
4. Wirken Straßenkanten und Stadtfronten voller, ohne dass deutliche Ladehänger oder schwarze Flächen erscheinen?
5. Bleiben Fahrzeugschaden, Tankfüllung und Aufträge nach einem vollständigen Neustart erhalten?

## Ehrlicher Qualitätsstatus

**Implementierung:** Projektcode/ZIP erstellt und offline statisch geprüft. **Noch nicht nachgewiesen:** erfolgreiche Kompilierung durch Godot, Android-APK-Ausführung, tatsächliche mobile FPS und visuelle Fehlerfreiheit. Ein erfolgreicher GitHub-Build und ein Samsung-Test bleiben erforderlich. Die 25 × 25 km sind weiterhin ein technisch generierter Koordinatenraum, kein vollständig produziertes deutsches Open-World-Spiel. LKW-Physik, echte Straßenverkehrsregeln, Animationen und professionell modellierte Städte benötigen gesonderte Produktion.
