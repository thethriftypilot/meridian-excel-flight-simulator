# Runtime-generated audio

No downloaded recordings are required. `Source/VBA/modAudio.bas` synthesizes engine harmonics, airflow, rolling noise, and warnings directly into persistent 16-bit mono PCM buffers at 22,050 Hz. It makes all mixing and RPM decisions inside VBA and submits buffers through Windows winmm.

The synthesis is original project code. There are no external sample licenses or external audio programs.
