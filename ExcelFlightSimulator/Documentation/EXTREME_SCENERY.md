# Extreme scenery candidates

The tree and sky assets are integrated and captured in `Tests/extreme-final`. Asset-generator previews are not simulator screenshots. See `EXTREME_STATUS.md` for the critical native assessment and performance limits.

## Visual audit of v0.7

The retained `Tests/sunset-v06.png` (also the v0.7 landscape design) and `Tests/KRIC-v07.png` expose ten visible weaknesses:

1. Tree crowns share nearly the same round silhouette.
2. The two perpendicular tree planes reveal crosses from above.
3. Uncorrelated tree height and dense random overlaps create a noisy canopy rather than coherent woodland.
4. Roads, roofs and parking lots often remain flat pixels at low altitude.
5. Airport markings are clean geometric strips on much blurrier surrounding surfaces.
6. Sky cloud structures repeat as small, similarly sized patches near the horizon.
7. Sunset is broadly peach without strong directional colour contrast.
8. The aircraft has visible fuselage facets and simplistic wing/gear detail.
9. The cockpit covers roughly the lower 44 percent of the KRIC frame and its large information display does not resemble a Warrior panel.
10. Monospace debug, navigation and map overlays occupy substantial sky area; natural scenery has little visual breathing room.

Only items 1â€“3 and part of 6â€“7 are addressed by this scenery subtask. Other work remains owned by the renderer/cockpit/airframe integration.

## Vegetation implementation

`Tools/TerrainProcessing/build_canopy.py` creates four original, generalized crown architectures inspired by spreading oak, loblolly pine, maple and tulip-poplar. These are synthetic illustrations, not surveyed trees or botanical measurements. Overlapping shaded crown volumes, fine leaf-edge erosion, internal openings, trunk/branch silhouettes and tonal differences replace the former four similar circular silhouettes.

`build_landscape.py` now accepts `--output PATH` for non-destructive candidates. It produces a 2048 Ã— 512 BGRA atlas with four equal 512 Ã— 512 cells. Runtime texture allocation and texture upload must use the new dimensions. Geometry retains the existing five-float vertex layout (u, v, east, altitude, south), tile order and 256-entry counts file. The per-tree geometry is three quads: two crossed upright silhouettes plus one overhead canopy plane sampling only the leafy atlas region. It is not full mesh foliage.

The candidate contains 236,028 instances and 2,832,336 vertices, compared with 357,605 instances and 2,860,840 vertices in the former two-quad model. More canopy coverage comes from coherent mature height and spread rather than more vertices. Candidate positions are jittered within a stratified grid and still selected by the existing imagery colour classification. The tree atlas is 4,194,304 bytes before mipmaps. Runtime performance must be measured; a similar vertex count is not a performance guarantee because larger crowns can increase overdraw.

The overhead plane is a deliberate compromise. It closes the obvious X gap from above, but may reveal a flat leaf layer from steep oblique angles. The four atlases remain repeated assets. Species placement, tree height and tree position are synthetic; dark-green roofs and other colour-classification mistakes remain possible. Trees do not have individual collision volumes or animated branches.

## Atmosphere implementation

`Tools/TerrainProcessing/build_atmosphere.py` generates four original 2048 Ã— 384 packed little-endian RGB panoramas (`day.rgb`, `dusk.rgb`, `storm.rgb`, `night.rgb`). The software renderer uses the full height; the existing OpenGL panorama consumes the first 256 rows. File size remains 3,145,728 bytes each. Existing runtime readers remain compatible.

Cloud colour is computed offline by integrating density through a procedural volume, with several extinction samples along the light direction. Horizon colours match the current runtime fog to avoid a seam. Sunset adds directional afterglow and a cooler anti-solar sky rather than making every direction equally orange. Runtime clouds remain static textured scenery anchored to the camera's angular view. This is not runtime volumetric cloud rendering, weather advection, aircraft/cloud interaction or physical atmospheric scattering. The generator does not introduce moving cloud shadows.

## Reproduce and integrate

With Python, NumPy, SciPy and Pillow installed, from the simulator directory:

```powershell
python Tools/TerrainProcessing/build_landscape.py --output ../ExtremeCandidates/Landscape
python Tools/TerrainProcessing/build_atmosphere.py --output ../ExtremeCandidates/Graphics
```

The landscape tool reuses cached authentic USGS imagery and elevation. Provenance stays in `source.json`; no new external imagery licenses are introduced. Candidate-only preview PNGs visualize the assets, not the actual simulator. Do not ship these as evidence of native rendering.

Before integration, retain the v0.7 assets separately, change the tree atlas allocation/upload dimensions, copy the candidate binary files, then run the matched native scene suite. Inspect low-altitude woods, steep external views, sunset, KFCI departure and KRIC approach. Test alpha cutouts at distance and watch for overhead canopy clipping, silhouettes at night and tree placement on movement areas. Measure overdraw and pacing, not only geometry counts.

## Integrated follow-up

The runtime now accepts the larger atlas. Native review exposed near-horizontal cloud streaks; a smooth horizon fade was added to the offline density integration and the skies were rebaked. Mapped building volumes are documented in `Assets/Landscape/BUILDINGS-LICENSE.md`. Terrain imagery and elevation resolution remain unchanged.
