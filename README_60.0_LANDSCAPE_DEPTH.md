# AUTO BOSS 60.0 — Landscape Depth / Roadcraft

Complete Godot project for the existing GitHub Actions Android workflow.

## Features
- Geometry-based, textured roadside oaks and conifers, built with shared vertex meshes and per-chunk GPU MultiMesh batches (nearby only). The earlier 50.0 billboard woodland remains in the distance.
- Three newly generated small, local graphics60 textures: bark, varied foliage and flower/grass cutouts. Files are already packaged; no generator script needed.
- Flowering meadow plants rendered as limited-visibility, alpha-tested batches rather than hundreds of nodes.
- Optimized road hard shoulder sections, upper galvanized guardrail rails and instanced posts; no additional collision or physics code.
- Field variation within the existing terrain shader, with muted farm parcels and crop-row shading.
- Reduced high-frequency asphalt contrast and stronger roughness to avoid over-bright, flickery roadway texture.
- Houses augmented with chimney, roof caps, entrance awning and architectural facade accents.
- Procedural sky horizon warms near sunrise/sunset, with lighting and fog tint updated at most once per second.
- Version label and Android GitHub Actions artifact updated to 60.0.

## Structure
Retain `assets/graphics50`, `assets/graphics51` and **new** `assets/graphics60` in the repository. The `tools` directory does not need an additional graphics60 generator because all generated textures are included.

## Quality and testing
Existing vehicle physics, missions, menu structure, save logic, career routes, and controls are unmodified. Run the GitHub Android workflow and test on the Samsung for scene loading, road visibility, city approach, frame-time spikes with traffic/rain, and nighttime lighting. A high FPS readout is not itself proof of stable frame times.
