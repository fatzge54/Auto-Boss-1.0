# AUTO BOSS 52.0 – Roadside Lighting & Calm Asphalt

Based on the Samsung recording of version 51.0 (approximately 38 seconds).

Changes:
- Rebuilt the wide motorway verge as 24 terrain chunks with consistent texture-based colouring, explicitly matching both mesh windings.
- Eliminated unintended lighting/shadow-blackening on the grass verges using a controllable day/night/rain brightness.
- Reused the existing graphics50 grass texture; no extra files necessary.
- Asphalt surface tuning: reduced bright noise, lower normal-map strength, milder specularity.
- HUD project version updated to 52.0. Android GitHub Actions artifact version updated to 52.0.
- Save state, career, traffic, input controls, and routes unchanged.

Test on Android:
1. Drive in clear daytime and check if right/left grass verge is evenly shaded, without continuous black planes.
2. Check road at 0 km/h and 130–150 km/h for motion shimmer and FPS spikes.
3. Test night and rain for sensible darkening of grass verges.
4. Verify Android build, startup, and pause / career / save screens.

The script was statically checked, but no Android or Godot engine test was performed here.
