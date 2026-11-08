# Changelog

## 0.2 — 2026-11-08

- Rebuilt the cockpit as a conventional six-pack with rotating magnetic heading card, signed vertical-speed needle, turn/slip display, engine gauge, and AGL/fuel/power/oil flight computer.
- Cached the panel artwork and replaced attitude scanline GDI calls with a single bitmap upload. Panel cost measured 3.55 ms versus 9.06 ms in v0.1.
- Added shaded multi-lobed clouds with a cached feathered opacity mask and resident terrain hillshade.
- Added a separate instrument-view bitmap to avoid overlapping source/destination scaling.
- Native verification: 28 checks passed, 30 camera/weather combinations rendered, no GDI growth in three cycles. Measured 16.14 FPS Balanced and 25.03 FPS Performance on the development machine.
- Created the private GitHub repository, source history, tooling syntax workflow, and complete downloadable release package.

## 0.1 â€” 2026-11-08

- Built native Excel/VBA flight application with GDI framebuffer presentation.
- Packaged authentic USGS 3DEP and NAIP Plus terrain around KFCI.
- Integrated 60 Hz flight dynamics, collision/landing rules, keyboard controls, and automatic demonstration controller.
- Added cockpit, five view modes, moving map, weather/lighting presets, and synthesized waveOut audio.
- Built automated native Excel tests and actual frame/performance captures.
- Corrected VBA compilation issues found in Excel, runway elevation profile, missed short keypresses, bitmap capture lifecycle, and status-bar restoration.
- Added texture mipmaps and conservative terrain-ray skipping. Set Performance as default based on measured results.

See Documentation/KNOWN_LIMITATIONS.md for specification items not implemented or not fully validated.
