# Meridian Extreme: integrated development milestone

This is an experimental graphics milestone, not completion of the 10/10 challenge. The matched images show a clearer cockpit view, fuller woodland, mapped building volumes and a substantially revised aircraft. They also show blurred low-altitude ground imagery, repeated tree silhouettes, simple building materials and an unfinished cockpit. An honest provisional assessment is about **5/10**, subject to the user's judgment.

## Implemented and observed in Excel

- **Direct GPU presentation:** a dedicated CS_OWNDC Win32 child window, WGL context, double buffering and SwapBuffers. Normal frames do not read the GPU image back into GDI. Explicit screenshot capture still does.
- **Cached static geometry:** driver-managed display lists for terrain, trees, building tiles and regional runway geometry. This avoids repeated CPU submission and, for the regional runway markings, repeated terrain-height calculations.
- **CPU instruments, GPU composition:** state-linked gauges still draw with GDI into a DIB section. A 1000 × 700 UI texture is uploaded and selected rectangles are composited in OpenGL. This is still a CPU-to-GPU upload, not a fully GPU-rendered instrument panel.
- **Cockpit:** camera-space frame, glareshield, sidewalls and a control-linked yoke. Gauges are mapped onto a panel plane; the former six-pack presentation remains available. This is an approximate cockpit, not a documented exact 1978 Warrior interior.
- **World:** four original tree silhouettes with an overhead canopy plane, more coherent mature woodland, and 35,263 OpenStreetMap building footprints around KFCI. Building heights are almost entirely estimated. See the included [data license and limitations](../Assets/Landscape/BUILDINGS-LICENSE.md).
- **Aircraft:** original 34,310-triangle Warrior-inspired mesh, curved airframe/glazing, improved gear and exterior details. Existing animated propeller and mesh shadow remain. Glazing is opaque; control surfaces remain static.
- **Sky:** new offline-generated cloud panoramas and improved horizon blending. Clouds are static textured scenery at runtime, not volumetric clouds.
- **Controls:** H toggles the interface; +/= and - adjust field of view; C changes cameras. Keyboard edge polling supplements UserForm events so the child window can receive focus.

VBA still owns physics, input, scenery selection, camera, graphics commands, instruments, audio and lifecycle. Windows and the installed OpenGL driver execute documented system APIs. Python only prepares assets and builds evidence offline. There is no custom compiled runtime DLL.

## Native evidence and measurement limits

`Tests/baseline-v07` and `Tests/extreme-final` contain eight scenes at identical aircraft positions, weather and camera modes. `Tests/extreme-comparison.jpg` places them side by side without color enhancement. The cockpit geometry and hidden HUD intentionally change the visible framing; external and clean-forward views show the underlying scenery changes more directly.

`Tests/architecture-readback`, `architecture-direct` and `architecture-cached` compare the presentation architecture with the old assets. These synchronized, 90-frame snapshots show that direct presentation alone is not uniformly faster: the KFCI departure went from 40.55 to 36.70 FPS, while the external view went from 44.58 to 50.99 FPS. Adding cached geometry improved the corresponding results to 42.06 and 56.08 FPS. This supported combining direct presentation with geometry caching rather than treating SwapBuffers alone as the solution.

The final asset/cockpit/runway-cache combination measured 51.75–60.26 FPS across the eight 1000 × 700 scenes. A separate 1280 × 896 experiment measured 51.09–60.02 FPS. The latter is a larger, comparable-area viewport, **not 1280 × 720**. Its short-final sample included a 210 ms outlier, so it does not establish uniformly smooth 60 FPS. The 1000 × 700 UI atlas remains fixed resolution even when the 3D viewport is larger.

The harness performs `glFinish` after each frame, measures render/present plus driver completion, and excludes screenshot capture. This deliberately serializes the pipeline. Five warm-up frames and 90 measured frames per scene are limited snapshots, not a controlled repeated statistical study. Background workloads and the desktop compositor can affect comparisons; do not interpret the final/baseline ratio as an isolated GPU architecture speedup. Detailed timing columns describe the last sampled frame, not per-subsystem percentiles. Software fallback's historical CSV labels the canvas size; its terrain renderer is 480 × 480 and is not resolution-equivalent to GPU output.

Hardware: Intel Core i7-8700K, NVIDIA GeForce GTX 1080, OpenGL 4.6.0 NVIDIA 582.78, Excel 16.0 build 14334 on 64-bit Windows. Multi-display configuration includes DisplayLink adapters. No other GPU, high-DPI scale, laptop or Remote Desktop compatibility claim is made.

Native regression run: 117 PASS entries, with physical handling and independent instrument calibration still partial. GPU lifecycle run: three launches, 105 camera/weather combinations, resize, pause, capture and double cleanup; warmed GDI counts 347 → 347. These checks establish specific behavior, not visual quality.

Desktop inspection found and fixed an important bug that framebuffer captures missed: the MSForms pane covered the GPU child. The child is now explicitly raised above siblings at creation and resize. A subsequent live Excel flight visibly rendered; P pause/resume, C camera, +/= zoom and Escape-to-menu were exercised through desktop keyboard input. Sustained manual flying, focus-loss edge cases, minimize/restore and mixed-DPI monitor moves remain unvalidated.

The first requested 20-minute soak was interrupted after about ten minutes and correctly reported FAIL. It is retained as `Tests/extreme-soak-interrupted.txt`; it is not a completed endurance pass. The latest `Tests/extreme-soak-result.txt` is authoritative for the replacement run. A RUNNING or FAIL result is not release acceptance.

## Provisional quality scorecard

| Category | Score | Evidence and remaining gap |
|---|---:|---|
| Terrain and world | 9/20 | Coherent crowns and actual footprint volumes; ground remains blurry and buildings very simple. |
| Cockpit and aircraft | 10/20 | Better exterior proportions and pilot view; panel remains stylized, untextured cockpit and opaque glazing. |
| Rendering and smoothness | 11/15 | Direct presentation and caching support larger native viewports; short samples and one significant outlier limit confidence. |
| Flight dynamics and manual handling | 5/15 | Existing deterministic dynamics retained; no new calibration or credible manual-flight evaluation. |
| Atmosphere and weather | 5/10 | More varied cloud lighting and horizon; static panorama, no cloud volume or dynamic shadows. |
| Audio and immersion | 2/5 | Existing synthesis operates; no new sound-quality improvement demonstrated. |
| UI and controls | 6/10 | Cleaner flight view and working desktop toggles; menu image/panel design and some focus cases need work. |
| Stability | 3/5 | Repeated native launches and cleanup pass; broader compatibility and endurance acceptance remain gated by evidence. |
| **Total** | **51/100** | **Provisional engineering assessment, not user acceptance or 10/10.** |

## Explicitly unfinished

No new six-degree-of-freedom calibration, controller support, configurable bindings, new sound engine, animated aircraft control surfaces, exact Warrior cockpit, texture-streaming system, building collisions, relation/courtyard reconstruction, dynamic sky/cloud shadows, modern shader/VBO dispatch, MSAA, or verified 1920 × 1080 mode is claimed. Terrain imagery resolution is unchanged. Full per-stage GPU profiling, long manual flight testing and multiple-machine compatibility remain open. Modern OpenGL invocation constraints and the safe exported-API alternative are explained in [the architecture investigation](EXTREME_RENDER_RESEARCH.md).

## Try the existing showcase flights

Use **Extreme GPU** and select the existing KFCI departure for runway/cockpit detail. Use Richmond scenic flight with sunset and C for the external view; +/= moves the view closer. Use the existing crosswind approach for the challenging arrival. These use the interactive engine and existing physics; no recorded video substitutes for flight. WATCH DEMONSTRATION selects the scenic flight automatically, so use START FLIGHT for a chosen approach.

The next quality work should concentrate on the cockpit's instrument design/materials, close-range airport surfaces, scenery placement errors and manually evaluated handling. Adding more airports would not address the visible limitations.
