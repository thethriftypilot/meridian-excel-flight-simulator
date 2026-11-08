"""Create the distributable ZIP without transient Office lock files."""
from pathlib import Path
import zipfile, hashlib, json
root=Path(__file__).resolve().parents[2]
dest=root.parent/'ExcelFlightSimulator.zip'
files=[p for p in root.rglob('*') if p.is_file() and '__pycache__' not in p.parts and not p.name.startswith('~$') and p.name not in ['environment-probe.xlsx','imagery.jpg.json','PACKAGE_SHA256.json']]
manifest={str(p.relative_to(root)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(root/'PACKAGE_SHA256.json').write_text(json.dumps(manifest,indent=2))
files.append(root/'PACKAGE_SHA256.json')
with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in files:z.write(p,str(Path(root.name)/p.relative_to(root)))
with zipfile.ZipFile(dest) as z:
    assert z.testzip() is None
print(f'{dest}: {dest.stat().st_size:,} bytes / {len(files)} files; archive CRC verified')
