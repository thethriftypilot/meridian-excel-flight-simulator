# Sources and asset rights

## v0.7 update

Assets/Region/sources.json retains USGS elevation/NAIP URLs and patch metadata. Assets/Airports/region-runways.json retains the FAA response, projected into Assets/Region/runways.csv. Imagery dates vary by mosaic; runway effective dates do not imply imagery recency. Existing source attribution below applies.

Downloaded 2026-11-08. Original service responses, export URLs, coordinate metadata, and checksums are retained in `Assets/Terrain`.

## Geographic assets

- **Elevation:** [USGS 3DEP ImageServer](https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer). Float32 bare-earth export, 1024² samples over 20.48 km, 20 m prepared spacing. USGS describes the service as containing data published through October 26, 2026. USGS federal data are public-domain materials. The prepared array preserves source elevations, including deep quarry/low-area values; no synthetic hills were substituted.

- **Aerial texture:** [USGS NAIP Plus ImageServer](https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer). Four 2048² RGB JPEG exports assembled into a 4096² texture at 5 m prepared spacing, plus box-filtered 20 m and 80 m mipmaps. The service combines NAIP and high-resolution orthophotos and identifies public-domain download imagery. This is a service mosaic, not a claim that all imagery was captured in 2026. Individual acquisition vintages have not been resolved.

- **Airport chart:** [FAA Chart Supplement, 29 October 2026, page 372](https://aeronav.faa.gov/afd/29OCT2026/NE_372_29OCT2026.pdf), effective through 24 December 2026. The retained PDF identifies KFCI, elevation 236 ft, runway 15/33, 5500 x 100 ft, and northwest upslope.

- **Runway geometry:** [FAA AIS Runways feature service](https://services6.arcgis.com/ssFJjBXIUyZDrSYZ/arcgis/rest/services/Runways/FeatureServer/0), owned by AeronauticalInformationServices_FAA. Retained item metadata and the spatially queried KFCI polygon are in Assets/Airports. Its designator, dimensions and location match the chart. Metadata states the same October-December 2026 effective interval.

The runtime uses the FAA polygon center and true orientation (141.221189 degrees), with published length/width. In the existing terrain projection the center is E -0.168 m / N -6.369 m relative to the package origin. The polygon projected centerline is 1678.72 m versus published 1676.4 m; this small projection/geometry discrepancy is documented rather than treating the local projection as surveying. validate_airport.py independently checks retained source geometry against VBA constants. Ground contact and runway graphics share DEM centerline elevations.

The real terrain is not exaggerated. Richmond's landscape is comparatively low-relief. Buildings, roads, fields, forests, and water patterns are chiefly supplied by aerial imagery; most are not individually extruded or collision-modelled. Seven hangars are explicitly generalized synthetic scenery.

## Aircraft reference and synthetic content

The PA-28-161 concept uses a 160 hp engine, 15.8 m² wing area, fixed landing gear, and flap settings inspired by the Warrior II. The [FAA-hosted aircraft performance table](https://downloads.regulations.gov/FAA-2023-1377-0002/attachment_2.pdf) identifies 160 hp and representative Warrior performance. Detailed lift/drag coefficients, control response, propeller efficiency, oil-system behavior, mass distribution, and sound are engineering approximations. No proprietary Piper artwork or recordings are included.

Clouds, sky, runway markings/lights, low-poly chase aircraft, cockpit graphics, and all audio synthesis/menu tones were created for this project. These are generalized simulation details, not measured airport scenery. Source code and generated design assets are supplied for the user's use and modification. Third-party geographic sources retain their attribution above.

[AIRCRAFT_MODEL.md](AIRCRAFT_MODEL.md) separates reference aircraft characteristics from engineering approximations.
