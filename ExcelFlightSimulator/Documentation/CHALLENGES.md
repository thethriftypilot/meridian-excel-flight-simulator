# Landing challenges, debriefs and replay — v0.4

Choose **Landing challenge / Runway 15** or **Landing challenge / Crosswind** and select **START FLIGHT**. Fly the approach, aim approximately 300 metres beyond the runway 15 threshold, land on the centerline and brake to a stop. Stay below 1 m/s for two simulated seconds to finish. Completion or a crash pauses the challenge. Press Esc, then **VIEW DEBRIEF** or **REPLAY LAST FLIGHT**.

This is an entertainment score for the simplified simulator, not a training assessment or a recommended real-aircraft technique.

## Score

Each component is clamped between zero and its maximum, then the total is rounded to an integer:

| Component | Maximum | Rule |
|---|---:|---|
| Smoothness | 30 | Linear reduction from zero sink to 3.2 m/s descent |
| Touchdown location | 25 | Full points at 300 m beyond the runway 15 threshold; zero at 450 m or more from that target |
| Centerline | 20 | Linear reduction from zero lateral offset to 15.24 m |
| Heading | 15 | Linear reduction from alignment with runway 15 to 30 degrees of error |
| Stop | 10 | Linear reduction from zero to 1200 m travelled after first contact |

The first contact captures sink rate **before** the physics engine sets vertical speed to zero. Further contacts count as bounces. A crash, bounce, runway excursion or heading error of 45 degrees or more makes the attempt unsuccessful and prevents a personal best. Leaving and returning to the runway does not remove the excursion. Quitting before a complete stop is unscored.

The crosswind scenario forces the existing crosswind preset. The ordinary runway 15 challenge uses the selected weather. Personal bests are separate for each scenario/weather combination. Enabling demonstration assistance at any point disqualifies that attempt from personal bests, even if assistance is later turned off. Free flights remain unscored.

## Debrief

Returning to the menu writes the latest flight to **Debrief** and **Flight data**, with touchdown measurements, a flight-path chart and an altitude profile. **Personal bests** keeps the best eligible score for each scenario/weather pair. Save the workbook normally to retain these sheets after closing Excel. The simulator does not silently save the workbook.

The recorded sample data are snapshots, not a recalculation of aircraft physics. The chart axes use local metres and feet MSL. The path chart is not a navigational map and its axes can have different scales. A flight with no contact displays `n.a.` for touchdown measurements.

The latest debrief/data replace the preceding flight report. **R** starts a new attempt and replaces the in-memory recording; the preceding completed debrief is written first. Personal bests remain. These are local, editable records, not a tamper-resistant online leaderboard.

## Replay

Replay uses recorded aircraft states rather than rerunning the flight model. It is silent, supports all five cameras and the map, and does not update scores or consume fuel. It restores the live aircraft state when closed.

| Key | Replay action |
|---|---|
| P | Pause / play |
| J / L | Seek backward / forward five seconds |
| K | Cycle 1×, 2×, 0.5× playback |
| R | Restart playback |
| C | Change camera |
| M | Toggle map |
| Esc | Return to menu |

Playback pauses at its end. Seek backward or press R to watch again. Flight-control keys are ignored during replay. Heading interpolation crosses north by the shortest arc.

Recording is bounded to 18,001 samples at approximately 10 Hz (about 30 minutes). At capacity, the first recorded portion is retained and the debrief flags the limit. Scoring continues independently. Pause and focus loss do not advance simulation time. Replay is kept in memory only: starting another flight or closing the workbook removes it. Saving the workbook preserves the debrief and charts, **not** replay availability.
