# Extreme baseline and acceptance record

Baseline is v0.7.0 (07a0f45), with the published website follow-up at 94ec7bd. Development branch: codex/meridian-extreme. The release ZIP and workbook are retained outside the distribution in .baseline-v07. Baseline runtime assets were unchanged for the eight native CaptureShowcase views.

## Most visible shortcomings

1. Repeated crossed tree silhouettes expose their construction, especially overhead.
2. Woodland appears evenly scattered rather than a coherent canopy.
3. Low-altitude imagery is blurred and cannot supply actual building volume.
4. Aircraft cabin/cowling proportions are crude; surfaces have conspicuous polygon boundaries.
5. Aircraft windows are flat color patches; gear and exterior detailing are sparse.
6. Clouds look like a low-resolution panorama, with repeated scale and soft shapes.
7. Sunset applies a broad peach tint with limited directional lighting.
8. The cockpit occupies 44 percent of the frame and includes a large development-style flight computer.
9. Persistent monospace debug text, control hints and FPS counter make flight look like a diagnostic console.
10. Airports lack enough coherent buildings, apron objects and surface detail at taxiing distance.

## Baseline evidence

Tests/baseline-v07 holds eight actual Excel captures at fixed aircraft states: departure, short final, low scenery, external, sunset, night, KRIC approach and apron. Tests/baseline-software repeats those states using the software fallback. The original baseline timing includes presentation but does not explicitly drain buffered GPU work. New architecture comparisons must use the same synchronized benchmark for all paths; do not compare submission-only timing with these results.

Initial hardware inventory: Intel Core i7-8700K (6 cores / 12 threads), NVIDIA GeForce GTX 1080 plus DisplayLink adapters. Driver and display inventory retained separately; active OpenGL vendor/renderer and Excel version must be recorded from the executed candidate before final reporting.

No quality score is awarded on the basis of passing tests. User's v0.7 assessment is 3/10. Candidate scores require native images and manual-control evidence and remain subject to the user's assessment.
