# Delivery audit — Meridian 0.3

The original brief mixes mandatory runtime requirements, engineering investigations, optional features, and visual aspirations. This audit distinguishes those categories. The package is an integrated experimental simulator; it is not a claim of commercial-simulator visual fidelity or exact 1978 Warrior handling.

| Area | Delivered implementation | Verification / boundary |
|---|---|---|
| Native Excel runtime | XLSM entry point, VBA simulation, software rendering, GDI presentation, native PCM audio | Actual desktop Excel execution; no external engine or runtime process |
| Startup and menus | Original title screen, actual runtime preview, scenarios, weather, quality, sound, sensitivity, START FLIGHT and WATCH DEMONSTRATION | Both buttons exercised in the UI across releases; single featured aircraft |
| Renderer | Heightfield visibility plus perspective-correct inverse-depth scenery rasterizer, near clipping, terrain textures, LOD, banked camera | Depth regression check, framebuffer captures, all 35 camera/weather combinations |
| Geographic world | Resident 20.48 × 20.48 km USGS elevation/imagery package | Binary integrity, geographic origin, current FAA geometry comparison |
| Airport | Published runway dimensions, FAA-derived center/heading, centerline/threshold/designator markings, night edge lights, apron, taxiway, seven hangars | Runway supports takeoff/landing; hangars have collision volumes; buildings/taxiways are generalized synthetic scenery |
| Flight dynamics | Lift/drag/thrust/gravity, mass/fuel, smooth controls, flaps, trim, wind, turbulence, stall/overspeed, ground steering/brakes/contact | Takeoff, full guided approach/flare, rollout, hard contact, engine failure, deterministic 20-minute simulated replay |
| Aircraft | PA-28-inspired low-wing, fixed-gear 3D chase model | Original low-poly geometry in the same depth-tested scene; no proprietary artwork |
| Instruments | Airspeed, attitude, altitude, VSI, magnetic heading, turn/slip, RPM, fuel, oil temperature/pressure, flaps, compass | All 13 corresponding display regions tested with isolated state changes; simplified scales/system models |
| Cameras | Cockpit, forward, chase, scenic, focused instruments | All five render and cycle in demonstration mode; scenic view is an off-axis aircraft camera |
| Keyboard | Required mappings, sensitivity, short-tap capture, focus handling, pause/reset/exit, E engine toggle | Native mappings plus UI checks; no editable binding UI or joystick support |
| Audio | Engine startup/idle/RPM, airflow/rain/rolling, touchdown, stall/overspeed, flap/engine switch and menu cues | Original synthesis/WAV tones, native buffer lifecycle, sustained-refill check; subjective speaker quality not certified |
| Weather/light | Clear/scattered, overcast, haze, crosswind, gusts, rain, day/sunset/night, horizon fog, sun glow, day/sunset directional terrain shading | Deterministic offline presets and bounded rain counts; no live METAR or volumetric weather |
| Navigation | Local-to-geographic conversion, MSL/AGL, IAS/TAS/groundspeed, true/magnetic heading, moving map | Approximate fixed magnetic variation and local projection; not aeronautical navigation data |
| Scenarios | Runway, scenic, approach, sunset, low visibility, night, apron, crosswind landing | Explicit initialization; demonstration uses actual physics and all five cameras |
| Window and cleanup | Large flight form covering the Excel window, aspect-correct presentation, reversible exit, emergency cleanup | No ribbon/calculation/event/security changes; repeated renderer/audio resource checks |
| Performance | 60 Hz physics, measured render/panel/audio timings, quality fallback, cached artwork/lighting, memory diagnostics | Actual local measurements in PERFORMANCE.md; Balanced is below target on this machine |
| Packaging | Workbook, assets, exported source/forms, build tools, documentation, test results, hash manifest, GitHub release | ZIP CRC and upload digest verified at publication |

## Deliberate alternatives and optional work

- The complete compact world stays resident rather than streaming tiles. At this package size it avoids runtime I/O and cache churn; a larger world would need a different loader.
- Trees and most infrastructure remain in the aerial texture. Detailed individual vegetation was not added at the expense of the default frame-rate target.
- Keyboard controls are the verified input path. Joystick integration and configurable binding UI remain optional and unimplemented; no physical controller was available for validation.
- Live METAR import is optional and unimplemented. Every weather preset works offline.
- The altitude indicator is a readable custom single-needle instrument, not an exact mechanical Piper replica. Flight dynamics, oil behavior, and magnetic variation remain approximations.
- Full manual crosswind-landing validation, multi-device audio testing, and other Windows/Office/DPI configurations require broader user testing. Automated checks do not substitute for those claims.

See TESTING.md and the raw Tests files for exact outcomes. Failed intermediate builds are not release candidates; release packaging follows the final native checks and continuous-flight diagnostic.
