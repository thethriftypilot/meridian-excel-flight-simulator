# Changelog

## 0.5 — 2026-11-10

- Replaced the repeating cloud shapes with four wraparound skies rendered from a procedural cloud volume. Daylight, sunset, overcast and night lighting cover all seven weather presets. The sky follows camera heading, pitch and bank.
- Added a textured cockpit panel, recessed gauges, finer tick marks and a moving pitch ladder on the attitude indicator.
- Added asphalt grain and rubber streaks anchored to the runway so surface details move past the cockpit on takeoff and landing.

## 0.4.1 — 2026-11-10

- Fixed a visible flash during flight and replay. The previous cockpit frame now stays on screen until the renderer copies its replacement. Only the margins outside the picture are filled.

## 0.3 — 2026-11-08

- Added inverse-depth testing shared by terrain, airport buildings, runway markings and the original low-poly chase aircraft. Added a generalized apron/taxiway, seven collidable hangars, and runway 15/33 designators.
- Aligned the runway center and true heading to retained FAA geometry effective 29 October–24 December 2026. Added an independent source comparison.
- Added rain, sun glow, sunset terrain lighting, crosswind approach, latitude/longitude and wind-aware groundspeed displays.
- Fixed fuel exhaustion regenerating idle RPM. Added E engine shutdown/restart, original startup/touchdown/switch cues, and menu tones.
- Preserved gauge proportions with aspect-correct presentation and expanded the flight form to cover Excel's window.
- Added isolated framebuffer checks for all 13 instrument bindings, depth regression, engine/collision checks, and a continuous renderer/audio/physics diagnostic with memory/resource logging.
- Caught and fixed diagnostic calls parsed as VBA labels; added a source guard to CI. Native measurements and exact continuous-flight results are in Documentation/TESTING.md and PERFORMANCE.md.

## 0.2 — 2026-11-08

- Rebuilt the cockpit as a conventional six-pack with rotating magnetic heading card, signed vertical-speed needle, turn/slip display, engine gauge, and AGL/fuel/power/oil flight computer.

- Cached the panel artwork and replaced attitude scanline GDI calls with a single bitmap upload. Panel cost measured 3.55 ms versus 9.06 ms in v0.1.

- Added shaded multi-lobed clouds with a cached feathered opacity mask and resident terrain hillshade.

- Added a separate instrument-view bitmap to avoid overlapping source/destination scaling.

- Native verification: 28 checks passed, 30 camera/weather combinations rendered, no GDI growth in three cycles. Measured 16.14 FPS Balanced and 25.03 FPS Performance on the development machine.

- Created the private GitHub repository, source history, tooling syntax workflow, and complete downloadable release package.

## 0.1 — 2026-11-08

- Built native Excel/VBA flight application with GDI framebuffer presentation.

- Packaged authentic USGS 3DEP and NAIP Plus terrain around KFCI.

- Integrated 60 Hz flight dynamics, collision/landing rules, keyboard controls, and automatic demonstration controller.

- Added cockpit, five view modes, moving map, weather/lighting presets, and synthesized waveOut audio.

- Built automated native Excel tests and actual frame/performance captures.

- Corrected VBA compilation issues found in Excel, runway elevation profile, missed short keypresses, bitmap capture lifecycle, and status-bar restoration.

- Added texture mipmaps and conservative terrain-ray skipping. Set Performance as default based on measured results.

See Documentation/KNOWN_LIMITATIONS.md for specification items not implemented or not fully validated.
