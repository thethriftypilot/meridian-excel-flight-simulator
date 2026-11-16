# OpenStreetMap building scenery

© OpenStreetMap contributors. Source data is available under the Open Data Commons Open Database License (ODbL) 1.0:

- https://www.openstreetmap.org/copyright
- https://opendatacommons.org/licenses/odbl/1-0/

The supplied `buildings-source.json.gz` is the complete input extract. The derived building geometry and tile index (`buildings.f32`, `buildings-counts.i32`) are made available under ODbL 1.0 as well. This data license does not replace the project's source-code license.

Extract query, executed on 16 November 2026 against https://overpass-api.de/api/interpreter:

```text
[out:json][timeout:90];way["building"](37.36,-77.59,37.46,-77.46);out geom;
```

Reproduce after decompressing the input:

```powershell
python Tools/TerrainProcessing/build_buildings.py buildings-source.json --output Assets/Landscape
```

Requires the existing terrain height asset, NumPy and SciPy at build time. No network or Python is used during flight. See `buildings-provenance.json` for input digest, database timestamp and counts.

35,263 accepted footprints are used. Only 14 have usable height or level tags; all other heights are estimates. Roof shapes and materials are synthetic. This extract includes building ways only; relation multipolygons and courtyard holes are not reconstructed. Invalid rings and tiny footprints are omitted. Existing generalized airport objects may overlap mapped footprints. Buildings are visual scenery with no collision model and are not navigation or obstacle-clearance data.
