# Regional exploration — v0.7

Version 0.7 expands the world to an 81.92 km square, adding Richmond International (KRIC) and Hanover County (KOFP) to Richmond Executive (KFCI). It includes three connecting missions, a three-leg tour, destination navigation, a regional map, actual-airframe ground shadows and propeller animation.

Choose Detailed 3D for the new scenery or Detailed 3D / 2x for smoother edges. New menu scenarios include KRIC/KOFP departures and runway 16 approaches, KFCI → KRIC, KRIC → KOFP, KOFP → KFCI and the regional tour.

| Airport | Runways |
|---|---|
| KFCI — Richmond Executive | 15/33 |
| KRIC — Richmond International | 16/34, 02/20 |
| KOFP — Hanover County | 16/34 |

Depart and climb above 45 m AGL, navigate to the target, land on one of its runways and stop below 1.5 m/s for three seconds. The tour continues through KRIC, KOFP and back to KFCI. Landing at another airport does not complete a leg; a crash fails the mission.

Press M for the map and N to cycle destinations during free flight. Missions lock the target. The banner shows stage, distance, approximate magnetic bearing and groundspeed-based ETA. Pause and replay freeze progress. Demonstration-assisted flights are marked assisted. Ending a flight writes its outcome to the Mission log sheet; save the workbook to retain it. Regional missions do not introduce a new landing score; existing scored challenges and debrief/replay remain available.

A warning appears near the regional edge. At 40 km east/north from the origin, flight pauses: R restarts and Esc returns to the menu.

## Scenery detail

The original KFCI terrain remains intact. Beyond it, regional imagery is 20 m per pixel, elevation samples are 80 m apart and the display mesh uses 320 m spacing. KRIC and KOFP each have a 5.12 km patch with 2.5 m imagery, 20 m elevations and 40 m mesh spacing. Runway geometry comes from the retained FAA dataset. Trees are synthetic and have no individual collision volumes. New airport terminals appear in imagery but are not individually modeled buildings. Aircraft shadows project the model onto a local ground plane, not a terrain-wide shadow map.
