# Build and reproduce

The packaged workbook is the normal entry point. Rebuilding is optional.

## Workbook build

Requires installed 64-bit desktop Excel with VBA7 and Windows PowerShell/PowerShell. Temporarily enable Excel's **Trust access to the VBA project object model** if you intend to rebuild. This is not needed to fly an already-built workbook. The script never changes security settings.

From the package directory:

```powershell

& .\Tools\Build\build.ps1 -Test

```

The script creates an isolated Excel instance, imports the `.bas` modules, builds the two UserForms, adds menu code, saves the `.xlsm`, executes native VBA tests, and exports forms. The instance is closed in `finally`. The existing packaged workbook is replaced, so close it before rebuilding. Do not bypass an organization policy that prevents scripts or macros; use the locally approved development process.

## Terrain reproduction

Build-time dependencies: Python 3, NumPy, Pillow, standard-library urllib. No Python is used during flight.

```powershell

python .\Tools\TerrainProcessing\build_terrain.py

```

Cached source TIFF/JPEG exports are reused. To obtain a new dated source package, preserve the old directory and run with an empty Assets/Terrain directory. Source services require internet access only at build time. Export-service limits are respected by requesting four image quadrants. A failed source request raises an error rather than silently replacing the world with procedural terrain.

## Binary layout

All arrays are row-major, top row north, left column west, little-endian, with no leading headers. `manifest.json` provides dimensions, origin, extents, and checksums. Sample centers are half a cell inside the extent.

| File | Layout |
|---|---|
| height.bin | 1024×1024 IEEE754 float32 metres NAVD88 |
| color.bin | 4096×4096 uint32 0x00RRGGBB (disk bytes B,G,R,0) |
| color-lod1.bin | 1024×1024 uint32 box-filtered color |
| color-lod2.bin | 256×256 uint32 box-filtered color |

No ellipsoid/geoid conversion is applied. Aircraft MSL and terrain altitude share the local orthometric reference. Do not mix GPS ellipsoidal heights into this data without conversion.

## Diagnostics

`RunSelfTests` can be invoked from the VBA editor or Excel automation. It writes `Tests/results.txt` and BMP frame captures. `Tools/Build/run-live-test.ps1` runs a timed demonstration and leaves the menu open. With `-MenuOnly`, it just opens the simulator menu. `Tests/last-flight.csv` is overwritten each flight.

## Additional asset and source checks

```powershell
python .\Tools\Build\prepare_audio.py
python .\Tools\Build\check_vba_source.py
python .\Tools\TerrainProcessing\validate_assets.py
python .\Tools\TerrainProcessing\validate_airport.py
```

The source check catches procedure calls accidentally written as VBA labels. It is not a VBA compiler; installed Excel remains necessary for native verification.

## Continuous flight diagnostic

Close the simulator workbook before running:

```powershell
& .\Tools\Build\run-soak.ps1 -Seconds 1200
```

This opens an isolated Excel instance, runs the real renderer/audio/60 Hz physics with the demo controller, cycles weather and cameras, and records Tests/soak.csv plus soak-result.txt. It intentionally continues when another application has focus; it is a diagnostic harness, not a physical-control test. Close the diagnostic flight window to interrupt it, or use Excel's Ctrl+Break emergency stop. An incomplete run fails rather than reporting success. The wrapper closes its workbook and Excel instance afterward.

After a successful continuous diagnostic, `python .\Tools\Build\plot_soak.py` creates Tests/soak-performance.svg from the raw measurements. `python .\Tools\Build\package.py` generates PACKAGE_SHA256.json and the complete ZIP, then checks every archive entry CRC.


The v0.6 ZIP includes the ready-to-use Detailed 3D assets. To regenerate them from source, prepare the original terrain first, then run `build_landscape.py`, `build_airframe.py` and `build_windshield.py` in `Tools/TerrainProcessing` with Python, NumPy, Pillow and SciPy installed. The landscape builder fetches four USGS NAIP tiles and retains their source URLs in `Assets/Landscape/source.json`. Use `Tools/Build/run-soak.ps1 -Seconds 120 -Detailed` to repeat the graphics stress test, or replace `-Detailed` with `-Supersample` to test the 2� mode.
