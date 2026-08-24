# AUTO BOSS – GitHub Cloud Build

Diese Version ist dafür vorbereitet, dass GitHub Actions automatisch eine Android-APK baut.

## Auf deinem Samsung

1. Öffne github.com und melde dich an.
2. Tippe auf **+** > **New repository**.
3. Repository-Name z. B. `auto-boss`.
4. Wähle am einfachsten **Private**.
5. Erstelle das Repository ohne README, falls GitHub danach fragt.
6. Entpacke diese ZIP-Datei auf deinem Samsung.
7. Lade den kompletten Inhalt in das Repository hoch. Wichtig: `.github/workflows/android-build.yml` muss ebenfalls hochgeladen werden.
8. Öffne im Repository den Reiter **Actions**.
9. Wähle **Build AUTO BOSS Android APK**.
10. Tippe auf **Run workflow**.
11. Nach erfolgreichem Build öffnest du den Workflow-Lauf.
12. Unten bei **Artifacts** findest du `AUTO_BOSS-Android-APK`.
13. Lade das Artifact herunter und entpacke es.
14. Darin liegt `AUTO_BOSS.apk`.
15. Tippe die APK an und erlaube auf dem Samsung gegebenenfalls die Installation unbekannter Apps.

## Falls der Android-Export fehlschlägt

Godot benötigt für Android normalerweise Java/Android-SDK bzw. passende Export-Templates. Der Workflow richtet Godot und die Export-Templates ein. Falls ein zukünftiges Godot-/Action-Update zusätzliche Android-SDK-Schritte verlangt, muss der Workflow entsprechend angepasst werden.

## Für Google Play später

Für den Play Store brauchst du eine signierte Release-Datei, normalerweise `.aab`.
Dafür sollten der Keystore und die Passwörter als GitHub Secrets gespeichert werden und niemals direkt ins Repository.
