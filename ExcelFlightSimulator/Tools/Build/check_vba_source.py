"""Catch accidental VBA labels that silently skip intended procedure calls.

This is a source lint check, not a replacement for the Excel compiler.
"""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2] / 'Source' / 'VBA'
files = list(root.glob('*.bas')) + list(root.glob('*.code'))
procedures = set()
for path in files:
    procedures.update(name.lower() for name in re.findall(
        r'^\s*(?:(?:Public|Private|Friend|Static)\s+)?(?:Sub|Function)\s+(\w+)',
        path.read_text(), re.M | re.I))
errors = []
for path in files:
    for number, line in enumerate(path.read_text().splitlines(), 1):
        match = re.match(r'^\s*(\w+)\s*:', line)
        if match and match.group(1).lower() in procedures:
            errors.append(f'{path.name}:{number}: {match.group(1)} is a label, not a call; use Call explicitly')
if errors:
    raise SystemExit('\n'.join(errors))
print(f'PASS: {len(files)} VBA sources checked for procedure-name labels')
