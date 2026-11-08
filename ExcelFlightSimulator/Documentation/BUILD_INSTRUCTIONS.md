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
