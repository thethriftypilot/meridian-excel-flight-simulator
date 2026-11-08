# Known limitations — release 0.3

This is a playable native Excel simulator with a documented delivery audit in REQUIREMENTS.md. Optional hardware integrations and commercial-simulator fidelity are not implied.

- The flight model uses lift/drag/thrust and gravity with simplified attitude dynamics. It does not implement full six-degree-of-freedom inertia, detailed propeller aerodynamics, spin recovery, ground effect, tire side forces, or certified Piper handling. Oil behavior and fixed magnetic variation are approximations.

- Authentic terrain uses 20 m elevation and 5 m imagery. Most trees and buildings remain photographic surface detail. Seven airport hangars are generalized synthetic geometry with collision volumes; their footprints and heights are not surveyed obstacles. The apron and taxiway are approximate and have no route-guidance system.

- Runway center and heading derive from FAA geometry effective 29 October–24 December 2026; length and width use the published 5500 × 100 ft dimensions. The local projected polygon centerline differs by about 2.3 m from published length. DEM resolution, local projection, and a modest runway depth bias prevent survey-grade precision.

- The renderer has per-pixel inverse-depth tests for scenery and the chase aircraft. Terrain depth is sampled by the heightfield rays; the runway uses a 2.5% depth tolerance to suppress z-fighting against coarse elevation. Grazing views can still show edge artifacts. Terrain perspective retains a small-angle pitch approximation.

- The cockpit is an original six-pack-inspired panel, not a photorealistic reproduction. Altitude uses a single needle; the turn indication is an approximate banked bar rather than a gyro model. All 13 display bindings are exercised through framebuffer changes, but independent calibration against aircraft test data has not been performed.

- The chase model is original low-poly geometry with fixed gear. The scenic camera looks off-axis from the airplane; it is not an independent free camera. All five views preserve output aspect ratio.

- Weather is deterministic and offline. Rain uses bounded screen-space streaks, visibility, turbulence, wind and audio changes; it does not include icing, wet-runway friction or fluid simulation. Clouds are projected opacity masks, and overcast is a gray sky layer. Sun direction is preset-based, not an astronomical ephemeris. There is no live METAR import or volumetric cloud penetration.

- Original audio is mono PCM with about 0.4 seconds of queued buffering. Startup, touchdown and switch cues are synthesized approximations. Menu tones are original generated WAVs. Subjective speaker quality and every device configuration have not been verified.

- Keyboard controls and sensitivity settings are implemented; joystick support and editable binding UI are not. Short continuous-control taps receive a 100 ms pulse, and toggle keys use form events.

- Performance mode uses two-pixel spans. Balanced is sharper but slower; no higher-resolution preset is exposed because measured performance does not justify one.

- The complete compact world remains resident rather than streaming tiles. The terrain boundary pauses a normal flight; there is no larger world or automatic route home.

- The flight form covers the Excel application window but retains a normal title bar. It does not change global ribbon, calculation, event, or security settings. Other applications and multi-monitor arrangements remain under the user's control.

- 64-bit Windows desktop Excel 2021 was tested. Mac, web Excel, 32-bit Office, simultaneous simulator workbooks, and all DPI configurations are not validated.

- Guided approach/flare and braking are tested. Sustained manual piloting, manual crosswind landings, and aircraft-specific performance validation require broader testing. Exact continuous-test duration and results are recorded separately; a successful bounded soak is not proof of indefinite leak freedom.

Actual runtime captures and measurements are included. Concept art, generated mockups, and estimated FPS are not used as verification evidence.
