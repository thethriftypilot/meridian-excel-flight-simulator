# Sources and asset rights

Downloaded 2026-11-08. Original service responses, export URLs, coordinate metadata, and checksums are retained in `Assets/Terrain`.

## Geographic assets

- **Elevation:** [USGS 3DEP ImageServer](https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer). Float32 bare-earth export, 1024² samples over 20.48 km, 20 m prepared spacing. USGS describes the service as containing data published through October 26, 2026. USGS federal data are public-domain materials. The prepared array preserves source elevations, including deep quarry/low-area values; no synthetic hills were substituted.
- **Aerial texture:** [USGS NAIP Plus ImageServer](https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer). Four 2048² RGB JPEG exports assembled into a 4096² texture at 5 m prepared spacing, plus box-filtered 20 m and 80 m mipmaps. The service combines NAIP and high-resolution orthophotos and identifies public-domain download imagery. This is a service mosaic, not a claim that all imagery was captured in 2026. Individual acquisition vintages have not been resolved.
- **Airport:** [FAA Chart Supplement, January 22, 2026, page 375](https://aeronav.faa.gov/afd/22JAN2026/NE_375_22JAN2026.pdf): KFCI reference N37°24.39′ W77°31.49′, field elevation 236 ft, runway 15/33, 5500×100 ft, slope up toward northwest. The currently effective chart was not retrieved; this is a dated source, not current aeronautical information.

The runway true heading is approximated at 141° from imagery and chart/magnetic relationships. Threshold positions are approximated symmetrically about the airport reference point. They have not been validated against current FAA surveyed endpoint records. Geometry is therefore visually aligned but not survey-grade. DEM samples near the northwest threshold are about 72 m (236 ft), consistent with the dated field elevation. Ground contact and rendered runway use the same DEM-based centerline height.

The real terrain is not exaggerated. Richmond's landscape is comparatively low-relief. Buildings, roads, fields, forests, and water patterns are chiefly supplied by aerial imagery; they are not individually extruded or collision-modelled objects.

## Aircraft reference and synthetic content

The PA-28-161 concept uses a 160 hp engine, 15.8 m² wing area, fixed landing gear, and flap settings inspired by the Warrior II. The [FAA-hosted aircraft performance table](https://downloads.regulations.gov/FAA-2023-1377-0002/attachment_2.pdf) identifies 160 hp and representative Warrior performance. Detailed lift/drag coefficients, control response, propeller efficiency, oil-system behavior, mass distribution, and sound are engineering approximations. No proprietary Piper artwork or recordings are included.

Clouds, sky, runway markings/lights, chase-view aircraft silhouette, cockpit graphics, and all audio synthesis were created for this project. These are generalized simulation details, not measured airport scenery. Source code and generated design assets are supplied for the user's use and modification. Third-party geographic sources retain their attribution above.
