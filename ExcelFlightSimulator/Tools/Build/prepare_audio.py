"""Generate original, short menu feedback tones; no third-party recordings."""
from pathlib import Path
import math
import struct
import wave

root = Path(__file__).resolve().parents[2] / 'Assets' / 'Audio'
root.mkdir(parents=True, exist_ok=True)
for name, amplitude in [('menu-low.wav', .04), ('menu-normal.wav', .08)]:
    count = 1323
    samples = [int(32767 * amplitude * math.sin(2 * math.pi * 880 * i / 22050)
                   * math.sin(math.pi * i / count) ** 2) for i in range(count)]
    with wave.open(str(root / name), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(22050)
        out.writeframes(struct.pack('<' + 'h' * count, *samples))
