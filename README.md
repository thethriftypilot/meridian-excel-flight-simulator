# MERIDIAN

**A real flight simulator inside Microsoft Excel.**

Native VBA flight physics, a software terrain framebuffer, authentic USGS elevation and aerial imagery around Richmond Executive Airport (KFCI), a Piper Warrior-inspired aircraft, cockpit instruments, and synthesized Windows audio.

All simulation and rendering decisions execute inside Excel. No external graphics engine, browser, Python runtime, or compiled custom DLL is needed to fly.

## Fly

Download the complete package from this repository's **Releases**, extract it, and open `ExcelFlightSimulator.xlsm` in 64-bit Windows desktop Excel. Keep the Assets folder beside it. Authorize macros for this file through your normal trusted-file process, then choose **OPEN FLIGHT SIMULATOR** → **START FLIGHT** or **WATCH DEMONSTRATION**.

[Pilot guide](ExcelFlightSimulator/Documentation/README.md) · [Controls](ExcelFlightSimulator/Documentation/CONTROLS.md) · [Architecture](ExcelFlightSimulator/Documentation/ARCHITECTURE.md) · [Measured performance](ExcelFlightSimulator/Documentation/PERFORMANCE.md) · [Verification](ExcelFlightSimulator/Documentation/TESTING.md)

## Development

The source lives in `ExcelFlightSimulator/Source/VBA`. Build with `ExcelFlightSimulator/Tools/Build/build.ps1 -Test` on a Windows machine with installed Excel and authorized VBA project access. [Full build instructions](ExcelFlightSimulator/Documentation/BUILD_INSTRUCTIONS.md).

Large terrain binaries and generated workbooks are distributed in releases rather than Git history. Reproduce terrain from the retained public service URLs using the Python preprocessing tool, or obtain it from a release package. [Source attribution and rights](ExcelFlightSimulator/Documentation/TERRAIN_SOURCES.md).

This is experimental entertainment software. It is not a certified flight model, training device, or navigation source. [Known limitations](ExcelFlightSimulator/Documentation/KNOWN_LIMITATIONS.md) distinguish implemented systems from outstanding work.
