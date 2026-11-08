"""Plot completed native soak measurements without third-party dependencies."""
from pathlib import Path
import csv
import html
import math

root = Path(__file__).resolve().parents[2]
result = (root / 'Tests/soak-result.txt').read_text().strip()
assert result.startswith('PASS |'), 'A completed passing soak is required'
with (root / 'Tests/soak.csv').open(newline='') as source:
    rows = list(csv.DictReader(source))
assert len(rows) > 2 and all(row['audio_state'] for row in rows), 'Incomplete log'
samples = []
for previous, row in zip(rows, rows[1:]):
    elapsed = float(row['wall_seconds'])
    dt = elapsed - float(previous['wall_seconds'])
    assert dt > 0
    samples.append((elapsed / 60, (int(row['frames']) - int(previous['frames'])) / dt,
                    float(row['working_set_mb']), int(row['gdi_objects'])))

width, height = 1000, 720
left, right = 80, 950
end = math.ceil(samples[-1][0])
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
       '<rect width="1000" height="720" fill="#101e26"/>',
       '<g font-family="Arial, sans-serif" fill="#e8eeed">',
       '<text x="80" y="40" font-size="24">MERIDIAN / Native Excel continuous flight</text>',
       '<text x="80" y="68" font-size="14">Real renderer, audio and physics; all seven weather presets and five cameras</text>']
for panel, (label, column, color) in enumerate([
        ('Interval frame rate (FPS)', 1, '#75dacb'),
        ('Excel working set (MB)', 2, '#dfb77c'),
        ('GDI object count', 3, '#9fb8f0')]):
    top = 110 + panel * 185
    bottom = top + 125
    values = [sample[column] for sample in samples]
    low, high = min(values), max(values)
    padding = max((high - low) * .2, 1)
    low, high = math.floor(low - padding), math.ceil(high + padding)
    if column == 1:
        low = 0
        high = max(30, high)
    svg.append(f'<text x="80" y="{top - 12}" font-size="16">{label}</text>')
    for fraction in (0, .5, 1):
        y = bottom - fraction * (bottom - top)
        value = low + fraction * (high - low)
        svg.append(f'<path d="M {left} {y} H {right}" stroke="#33444e"/>')
        svg.append(f'<text x="68" y="{y + 5}" text-anchor="end" font-size="12">{value:g}</text>')
    for minute in range(0, end + 1, max(1, end // 4)):
        x = left + minute / end * (right - left)
        svg.append(f'<text x="{x}" y="{bottom + 20}" text-anchor="middle" font-size="12">{minute}</text>')
    points = ' '.join(f'{left + sample[0] / end * (right-left):.1f},'
                      f'{bottom - (sample[column]-low)/(high-low)*(bottom-top):.1f}'
                      for sample in samples)
    svg.append(f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="2"/>')
svg.extend([
    '<text x="950" y="648" text-anchor="end" font-size="13">Elapsed wall-clock minutes</text>',
    '<text x="80" y="680" font-size="13">Frame rate uses each ~10-second interval; resource axes are truncated to show variation.</text>',
    '<text x="80" y="702" font-size="12">Source: Tests/soak.csv. Startup sample excluded. Bounded observation; not proof of indefinite leak freedom.</text>',
    '</g>', f'<desc>{html.escape(result)}</desc>', '</svg>'])
output = root / 'Tests/soak-performance.svg'
output.write_text('\n'.join(svg), encoding='utf-8')
print(f'{output}: {len(samples)} measured intervals plotted')
