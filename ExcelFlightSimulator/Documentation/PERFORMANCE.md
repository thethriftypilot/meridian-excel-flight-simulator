# Measured performance

Measured on 2026-11-08 in native 64-bit Excel 16 / Office 2021 on Windows 11 Home 10.0.26100, Intel Core i7-8700K @ 3.70 GHz. Other applications were open. These are local measurements, not hardware-independent promises.

| Measurement | Actual result |
|---|---:|
| Initial balanced renderer, 120 frames | 12.86 FPS |
| Final balanced renderer, 120 frames | 14.47 FPS |
| Final balanced terrain/presentation preparation | 58.50 ms/frame |
| Final balanced cockpit/overlay | 9.06 ms/frame |
| Final Performance preset, 120 frames | 22.73 FPS |

The automated renderer benchmark includes native terrain/cockpit generation, presentation to the UserForm, simulation advancement, and an event pump every ten frames. It is uncapped and excludes continuous audio mixing during that particular loop. It does not represent an end-to-end game-loop benchmark with all effects enabled. The two preset loops follow successive flight positions, so they are indicative workload comparisons rather than precisely identical-view A/B samples.

The separate timed live demonstration uses the production fixed-step loop with audio, input polling, per-frame event pumping, and frame pacing. Its once-per-second measurements are in `Tests/live-demo-pre-map-optimization.csv`; the latest user flight overwrites `Tests/last-flight.csv`. This 55-second UI-launched demonstration predates the final map optimization: mean 19.33 FPS, range 15.11–24.41 FPS, including the slower original map overlay. East position changed from -2169.7 to -143.5 m. The final map bitmap implementation separately measured 22.58 FPS over 30 frames. Physics typically costs a few hundredths of a millisecond per rendered frame; audio refill costs vary because buffers are not regenerated every frame.

## Optimizations supported by measurements

- Removed a general clamp/function call from every terrain ray sample.
- Skip near rays that cannot intersect the package's measured maximum height (117.37 m; conservative bound 125 m).
- Use preallocated typed arrays and one resident terrain package.
- Fill two-column spans and use larger distance steps in Performance mode.
- Use progressively coarser prefiltered texture levels beyond 1.5 km and 4.5 km.
- Draw circular attitude instruments with clipped scanline spans instead of per-pixel GDI calls.
- Reuse GDI bitmap/DC resources and cached fonts for the entire session.

Terrain generation remains the dominant bottleneck. Performance is the default. If Balanced falls below 18 measured FPS, the controller drops to Performance; it does not oscillate back upward during the same flight. The live loop is capped around 30 FPS and uses a 60 Hz physics accumulator. A single frame delay is capped at 200 ms to avoid an unbounded catch-up loop; severe stalls therefore lose wall-clock simulation time rather than exploding the physics integration.

Three repeated native render-window cycles ended with 404 GDI objects versus 406 before the test in the final run. This shows no growth in that bounded check, not proof of leak freedom over indefinite runtime. Whole-process working-set measurement and a long wall-clock soak were not performed.
