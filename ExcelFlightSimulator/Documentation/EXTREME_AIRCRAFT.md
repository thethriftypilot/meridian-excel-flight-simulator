# Extreme aircraft candidate

Status: integrated into the runtime asset and captured in native Excel. See `Tests/extreme-final/scene-3.png` and `scene-7.png`, and `EXTREME_STATUS.md` for measured results and remaining limitations. Offline previews are not used as simulator evidence.

## What changed

The original 930-triangle exterior had an oversized cabin, broad wing chord, tall fin, flat wheel disks and abrupt polygon lighting. The candidate uses a smoothly lofted fuselage with interpolated vertex colors, a semi-tapered wing with curved airfoil sections, separate curved windshield and side-window patches, rounded tires with metallic hubs, cylindrical gear struts, upper main-gear fairings and a shaped spinner. Continuous red/navy paint ribbons follow the fuselage. Wingwalk, fuel caps, light lenses, control-surface seams, a right-side door outline/handle, exhausts, antennas and boarding step add close-up detail.

The generator accepts `--output` so experimental geometry can be generated without touching the current runtime asset:

```powershell
python Tools/TerrainProcessing/build_airframe.py --output Assets/ExtremeCandidate/airframe.f32
```

The existing dependency set includes NumPy and SciPy. Python remains an offline build dependency only.

## Dimensions and provenance

General dimensions follow the manufacturer-authored [Piper Warrior II POH VB-1180, Figure 1-1](https://www.basic6aviation.com/downloads/PA-28-161-POH.pdf), hosted by a flight school: 35-foot wing span, approximately 23 feet 9.5 inches overall length, 10-foot main-gear track and about 7 feet 3.6 inches height. This is an August 1982 handbook, not a serial-specific 1978 reference. The handbook and artwork are not redistributed. All generated geometry is original.

Wing skin span is 10.668 m; light lenses extend overall width to approximately 10.69 m. Length is 7.2517 m, and gear track is 3.048 m. Fin-to-ground extent is approximately 2.24 m; a generalized roof antenna extends above it. Fuselage/cabin profiles, airfoil shape, minor fittings and paint are engineering estimates rather than surveyed geometry.

## Runtime compatibility

- Same headerless little-endian float32 C3F_V3F triangles: six floats per vertex, RGB then XYZ.
- Same body axes: X right, Y up, Z aft, in metres.
- Gear contact plane remains Y = -1.12 m.
- The VBA propeller plane remains Z = -3.02 m; the new spinner extends in front. Propeller animation remains runtime VBA geometry.
- Existing day/night arrays and actual-mesh shadow pass can read the candidate without format changes.
- 34,310 triangles, 102,930 vertices and 2,470,320 bytes versus 930 triangles and 66,960 bytes before. Day/night CPU arrays together add about 4.8 MB. Driver storage and shadow-pass cost require native measurement.
- Generated JSON records bounds, size and SHA-256. Handoff hash: `636a3f61cc1c8118e0f80f668d3a5022db167ad0189a1ebc4ad5524617cb4d3f`.

## Verification and limits

The generator checks triangle alignment, finite values and colors in [0, 1]. Offline depth-buffer inspection confirms coherent glazing, wing proportions, silhouette and wheel/gear geometry. The earlier painter-sorted comparison showed false ordering artifacts resolved by the depth-buffered inspection. Neither preview is an Excel screenshot or native performance evidence.

Baked shading is fixed in aircraft coordinates, not dynamic sunlight or physically based materials. Glazing is opaque reflective-colored geometry with no visible cabin interior. Light lenses are not dynamic emitters. Control-surface seams do not animate. Exact 1978 fidelity is not claimed. Native matched captures and performance snapshots are retained in `Tests/extreme-final`. Close-range materials and animations remain unfinished.

Development-only inspection:

```powershell
python Tools/TerrainProcessing/inspect_airframe.py Assets/ExtremeCandidate/airframe.f32 Assets/ExtremeCandidate/mesh-zbuffer.png
```

`Assets/ExtremeCandidate/airframe-v07.f32` preserves the prior asset. Experimental assets should remain outside release packages until integrated; only generators and documentation belong in source control.
