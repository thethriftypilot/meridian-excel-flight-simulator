# KFCI source snapshot

Retrieved 8 November 2026; effective 29 October–24 December 2026.

- `KFCI-29OCT2026.pdf`: [FAA Northeast Chart Supplement page 372](https://aeronav.faa.gov/afd/29OCT2026/NE_372_29OCT2026.pdf). `KFCI-chart.txt` is its extracted text; the page also contains another airport entry.
- `FAA-runways-source.json`: [ArcGIS item metadata](https://www.arcgis.com/sharing/rest/content/items/4d8fa46181aa470d809776c57a8ab1f6?f=json), owned by AeronauticalInformationServices_FAA.
- `KFCI-runway.json`: spatial query of the [FAA Runways layer](https://services6.arcgis.com/ssFJjBXIUyZDrSYZ/arcgis/rest/services/Runways/FeatureServer/0), using the parameters below. It returns one runway, designator 15/33, 5500 × 100 feet.

```text
Endpoint: FeatureServer/0/query
where=1=1
geometry=-77.55,37.39,-77.50,37.43
geometryType=esriGeometryEnvelope
inSR=4326
spatialRel=esriSpatialRelIntersects
outFields=*
returnGeometry=true
outSR=4326
f=pjson
```

`Tools/TerrainProcessing/validate_airport.py` projects the retained four corners and independently compares the resulting center and heading with the VBA constants. Runtime length and width use the published dimensions. The local projection is approximate, and these dated development assets are not a source for real flight planning. No runtime network access is required.
