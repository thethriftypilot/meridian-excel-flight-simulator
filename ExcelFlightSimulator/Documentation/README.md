# MERIDIAN — the Excel flight experiment

An experimental, native VBA flight simulator for 64-bit Windows desktop Excel. The aircraft is inspired by a 1978 Piper PA-28-161 Warrior II. This is entertainment software, not a training device or navigation source.

## Fly

1. Extract the complete folder to a writable local directory. Keep `Assets` beside `ExcelFlightSimulator.xlsm`.

2. Open `ExcelFlightSimulator.xlsm` in desktop Excel. Authorize macros for this workbook through your normal trusted-file workflow. Do not enable all macros globally.

3. Click **OPEN FLIGHT SIMULATOR**, then **START FLIGHT** or **WATCH DEMONSTRATION**.

4. For the easiest introduction, use **Richmond scenic flight**, **Clear / calm**, and **Performance**. Demonstration mode flies the same physics model with an automatic controller.

5. Press **Esc** to return to the menu. Close the menu to return to Excel.

No Python, GIS software, network connection, custom DLL, or external rendering process is needed to fly. Excel, VBA7, GDI, user32, kernel32, and Windows winmm are the runtime dependencies. Build tools are separate.

The viewport is a dedicated UserForm covering the Excel window, with aspect-correct presentation. The workbook remains available behind it. The simulator does not change Excel's ribbon, calculation mode, events, or global display preferences.

## Getting airborne

Choose runway departure. Hold W to advance power. At approximately 55 knots, hold Down briefly to raise the nose, then release and use Page Up trim to sustain the climb. Down pulls back; Up pushes forward. Use gentle bank inputs. Neutral controls relax toward a stable pitch attitude; this is a simplified model.

For landing practice, choose runway 15 approach. The aircraft starts northwest of KFCI, about 2.5 km before the threshold, at 66 knots with flaps extended. Adjust power with W/S, align using bank and rudder, reduce descent near the surface, and brake with Space after landing. Contact faster than 3.2 m/s vertically, excessive attitude, or fast off-runway contact ends the flight.

The terrain ends roughly 10 km from the airport in each cardinal direction. The simulator pauses before crossing its boundary; reset or turn back. There is no streaming world beyond this local package.

The airport includes a generalized apron, taxiway and collidable hangars; the chase camera shows an original 3D low-wing aircraft. Try the crosswind approach or rain preset after learning the basic controls. Press E to shut down or restart the engine when fuel is available.

## Evidence and limits

`Tests/results.txt` contains native Excel execution results. `Tests/*.bmp` are frames captured from the actual VBA renderer. `Tests/last-flight.csv` records the most recent interactive flight, including actual frame rate and subsystem timings. See `PERFORMANCE.md`, `KNOWN_LIMITATIONS.md`, and `TESTING.md` for scope and unresolved coverage.

## Troubleshooting

- Missing terrain: restore the complete Assets directory; do not move only the workbook.

- Macros unavailable: use desktop Excel and your normal per-file authorization. Organizational policies may prevent execution.

- Slow flight: use Performance. Balanced automatically falls back if measured FPS drops below 18.

- Controls inactive: click the simulator window. Physics and input suspend when the simulator loses foreground focus.

- Emergency stop: Esc normally exits. Excel's Ctrl+Break interrupts VBA if necessary; run `EmergencyCleanup` from Alt+F8 afterward to release audio and graphics resources.

- Rebuilding requires temporary **Trust access to the VBA project object model**. Running the finished workbook does not require this setting. Restore it to your preferred setting after development.
