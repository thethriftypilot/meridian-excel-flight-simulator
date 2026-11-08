"""Build-time geographic/binary integrity checks, independent of Excel runtime."""
from pathlib import Path
import json, hashlib, math
import numpy as np

root=Path(__file__).resolve().parents[2]
p=root/'Assets/Terrain'
m=json.loads((p/'manifest.json').read_text())
results=[]
def check(name,ok,detail):
    results.append({'test':name,'status':'PASS' if ok else 'FAIL','detail':detail})
for name,size in [('height.bin',1024*1024*4),('color.bin',4096*4096*4),('color-lod1.bin',1024*1024*4),('color-lod2.bin',256*256*4)]:
    check(name,(p/name).stat().st_size==size,f'Expected {size} bytes')
for name,digest in m['sha256'].items():
    check(name+' SHA256',hashlib.sha256((p/name).read_bytes()).hexdigest()==digest,digest)
h=np.fromfile(p/'height.bin',dtype='<f4').reshape(1024,1024)
check('finite DEM',bool(np.isfinite(h).all()),f'Min {h.min():.3f}, max {h.max():.3f} m; negative quarry/low-area samples retained')
check('missing data',bool((h!=-999999).all()),'No requested no-data sentinel present')
head=math.radians(141)
e=-838.2*math.sin(head); n=-838.2*math.cos(head)
elev=float(h[int((10240-n)/20),int((10240+e)/20)])
check('FAA northwest field elevation',abs(elev-236*.3048)<3,f'Nearest DEM threshold sample {elev:.3f} m; dated FAA field elevation 71.933 m')
for name in ['elevation.tif.json','imagery_0_0.jpg.json','imagery_0_1.jpg.json','imagery_1_0.jpg.json','imagery_1_1.jpg.json']:
    r=json.loads((p/name).read_text())
    check(name+' export', 'extent' in r and 'error' not in r, 'Export extent and success metadata retained')
report={'checks':results,'scope':'Binary and source-package checks only. These do not establish VBA compilation or rendering.'}
(root/'Tests/assets.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
raise SystemExit(0 if all(x['status']=='PASS' for x in results) else 1)
