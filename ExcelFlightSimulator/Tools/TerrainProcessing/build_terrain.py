"""Reproducible USGS/USDA terrain export. Build-time only; Python + numpy + Pillow."""
import urllib.request, urllib.parse, json, math, io, struct, hashlib
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'Assets/Terrain'
OUT.mkdir(parents=True, exist_ok=True)
LAT, LON = 37.4065, -77.5248333333
SCALE = math.cos(math.radians(LAT))
MX = 6378137 * math.radians(LON)
MY = 6378137 * math.log(math.tan(math.pi/4+math.radians(LAT)/2))
HALF = 10240
BBOX = [MX-HALF/SCALE, MY-HALF/SCALE, MX+HALF/SCALE, MY+HALF/SCALE]
DEM = 'https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer'
NAIP = 'https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer'

def fetch(url):
    print('Downloading', url[:130], flush=True)
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'ExcelFlightSimulator/1.0'}), timeout=180) as r:
        return r.read()

def export(service, n, name, extra, bbox=BBOX):
    path = OUT/name
    params = dict(f='json', bbox=','.join(map(str,bbox)), bboxSR=3857, imageSR=3857,
                  size=f'{n},{n}', interpolation='RSP_BilinearInterpolation', **extra)
    url = service+'/exportImage?'+urllib.parse.urlencode(params)
    if not path.exists():
        result=json.loads(fetch(url))
        (OUT/(name+'.json')).write_text(json.dumps(result,indent=2))
        if 'href' not in result: raise RuntimeError(result)
        path.write_bytes(fetch(result['href']))
    return np.array(Image.open(path)), url

if __name__ == '__main__':
    h, du = export(DEM,1024,'elevation.tif',dict(format='tiff',pixelType='F32',noData=-999999,renderingRule='{"rasterFunction":"None"}'))
    if h.ndim != 2 or h.min() < -100 or h.max()>1000: raise ValueError('Invalid DEM '+str((h.shape,h.min(),h.max())))
    tiles=[]; iu=[]
    for row in range(2):
        strip=[]
        for col in range(2):
            dx=(BBOX[2]-BBOX[0])/2; dy=(BBOX[3]-BBOX[1])/2
            bbox=[BBOX[0]+col*dx,BBOX[3]-(row+1)*dy,BBOX[0]+(col+1)*dx,BBOX[3]-row*dy]
            tile,url=export(NAIP,2048,f'imagery_{row}_{col}.jpg',dict(format='jpg',bandIds='0,1,2'),bbox)
            strip.append(tile); iu.append(url)
        tiles.append(np.concatenate(strip,axis=1))
    rgb=np.concatenate(tiles,axis=0)
    rgb=rgb[:,:,:3]
    h.astype('<f4').tofile(OUT/'height.bin')
    # DIB long is 0x00RRGGBB, represented on disk as B G R 0.
    packed=rgb[:,:,0].astype('uint32')*65536+rgb[:,:,1].astype('uint32')*256+rgb[:,:,2].astype('uint32')
    packed.astype('<u4').tofile(OUT/'color.bin')
    for size,name in [(1024,'color-lod1.bin'),(256,'color-lod2.bin')]:
        mip=np.array(Image.fromarray(rgb).resize((size,size),Image.Resampling.BOX)).astype('uint32')
        (mip[:,:,0]*65536+mip[:,:,1]*256+mip[:,:,2]).astype('<u4').tofile(OUT/name)
    Image.fromarray(rgb).resize((512,512)).save(OUT/'map.png')
    Image.fromarray(rgb).resize((512,512)).save(OUT/'menu.bmp')
    manifest=dict(latitude=LAT,longitude=LON,half_extent_m=HALF,projection='EPSG:3857 locally scaled by cos(reference latitude)',mercator_origin=[MX,MY],scale=SCALE,
                  dem_size=1024,dem_step_m=20,texture_size=4096,texture_step_m=5,rows='north to south',elevation_datum='3DEP NAVD88, metres; no geoid conversion',
                  dem_min=float(h.min()),dem_max=float(h.max()),dem_url=du,imagery_url=iu,
                  sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [OUT/'height.bin',OUT/'color.bin']})
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
    print(json.dumps(manifest,indent=2),flush=True)
