# Aircraft model and provenance

The reference is a Piper PA-28-161 Warrior II. Piper's [manufacturer-authored POH, report VB-1180](https://www.basic6aviation.com/downloads/PA-28-161-POH.pdf), hosted by a flight school, documents a 160 hp / 2700 RPM engine, fixed-pitch propeller, 35-foot wingspan, and the basic Warrior configuration. This is an August 1982 handbook with later revisions, not a serial-specific 1978 document. It supports the general aircraft inspiration; the simulator does not claim year-specific certification or performance. The handbook itself is not redistributed.

| Model parameter | Simulator value / interpretation |
|---|---|
| Maximum shaft power | 119,312 W, approximately 160 hp |
| RPM target | 700 + throttle × 2000, with lag; zero-power exponential spin-down |
| Wing area | 15.8 m² engineering model |
| Non-fuel mass | 890 kg including assumed occupants/load; not empty aircraft weight |
| Scenario fuel | 136 L, approximately 36 US gallons; partial loading, not tank capacity |
| Fuel mass | 0.72 kg/L |
| Propulsive efficiency | Fixed 0.72 approximation |
| Lift | Dynamic pressure × wing area × angle-of-attack/flap coefficient |
| Drag | Parasitic + induced + flap + post-stall components |
| Attitude | Damped pitch and roll response; not six-axis rigid-body integration |
| Touchdown limit | 3.2 m/s vertical contact plus attitude/surface checks; gameplay threshold |
| Landing gear | Fixed; no retractable-gear system |

Aerodynamic coefficients, control response, fuel burn, oil dynamics, turbulence and sound are original engineering approximations. The 3D exterior is original simplified geometry. No Piper artwork, proprietary simulator assets, or recorded aircraft samples are included.

Engine-off and fuel-exhaustion checks ensure the model cannot recreate idle power without fuel. The engine may be restarted with E only while fuel remains. This is simplified interaction rather than a real checklist or engine-management simulation.
