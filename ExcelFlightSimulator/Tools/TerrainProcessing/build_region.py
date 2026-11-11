"""Extend Meridian's original KFCI terrain with a seamless Richmond/Hanover region."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json, math, urllib.request, urllib.parse
import numpy as np
from PIL import Image
from scipy.ndimage import map_coordinates
from build_terrain import ROOT, MX, MY, SCALE, DEM, NAIP
DEST=ROOT/'Assets'/'Region'
DEST.mkdir(exist_ok=True)
sources=[]
def export(service,n,name,bbox,dem=False):
    path=DEST/name
    params=dict(f='json',bbox=','.join(map(str,bbox)),bboxSR=3857,imageSR=3857,size=f'{n},{n}',interpolation='RSP_BilinearInterpolation')
    params.update(dict(format='tiff',pixelType='F32',renderingRule='{"rasterFunction":"None"}') if dem else dict(format='jpg',bandIds='0,1,2'))
    url=service+'/exportImage?'+urllib.parse.urlencode(params)
    if not path.exists():
        data=json.load(urllib.request.urlopen(url,timeout=180))
        if 'href' not in data:raise RuntimeError(data)
        path.write_bytes(urllib.request.urlopen(data['href'],timeout=180).read())
    sources.append(url)
    return np.asarray(Image.open(path))
def bbox(e,n,half):
    return [MX+(e-half)/SCALE,MY+(n-half)/SCALE,MX+(e+half)/SCALE,MY+(n+half)/SCALE]
def local(lon,lat):
    return [math.radians(lon+77.5248333333)*6378137*SCALE,(math.log(math.tan(math.pi/4+math.radians(lat)/2))*6378137-MY)*SCALE]
features=json.loads((ROOT/'Assets/Airports/region-runways.json').read_text())['features']
runways=[]
for feature in features:
    a=feature['attributes']
    ident={'69E61D8F-915F-4B1D-9666-6338F1F19CD9':1,'07817D3E-53AE-4E0E-BD54-25AFE59CDA6E':2}.get(a['AIRPORT_ID'])
    if not ident:continue
    points=np.array([local(*p) for p in feature['geometry']['rings'][0][:4]])
    lengths=np.linalg.norm(np.roll(points,-1,axis=0)-points,axis=1)
    k=int(np.argmin(lengths))
    end1=(points[k]+points[(k+1)%4])/2;end2=(points[(k+2)%4]+points[(k+3)%4])/2
    heading=math.atan2(*(end2-end1))
    number=int(a['DESIGNATOR'].split('/')[0])
    if abs(math.remainder(heading-math.radians(number*10-10),2*math.pi))>math.pi/2:end1,end2=end2,end1
    center=(end1+end2)/2;heading=math.atan2(*(end2-end1))%(2*math.pi)
    runways.append(dict(airport=ident,designator=a['DESIGNATOR'],east=center[0],north=center[1],heading=heading,length=a['LENGTH']*.3048,width=a['WIDTH']*.3048))
primary={r['airport']:r for r in runways if r['designator']=='16/34'}
# Regional 81.92 km square, with original KFCI scenery retained in its centre.
jobs=[(DEM,1024,'region-height.tif',bbox(0,0,40960),True)]
for row in range(2):
    for col in range(2):
        jobs.append((NAIP,2048,f'region-{row}-{col}.jpg',bbox(-20480+col*40960,20480-row*40960,20480),False))
for key,airport in primary.items():
    jobs.append((DEM,256,f'{key}-height.tif',bbox(airport['east'],airport['north'],2560),True))
    jobs.append((NAIP,2048,f'{key}-photo.jpg',bbox(airport['east'],airport['north'],2560),False))
with ThreadPoolExecutor(4) as pool:
    results=list(pool.map(lambda args:export(*args),jobs))
for job,arr in zip(jobs,results):print(job[2],arr.shape,flush=True)
height=results[0];height.astype('<f4').tofile(DEST/'height.f32')
photo=np.vstack([np.hstack(results[1:3]),np.hstack(results[3:5])])
def packed(rgb):
    rgb=rgb.astype('uint32')
    return (rgb[:,:,0]*65536+rgb[:,:,1]*256+rgb[:,:,2]).astype('<u4')
packed(photo).tofile(DEST/'photo.rgba')
packed(np.asarray(Image.fromarray(photo).resize((1024,1024),Image.Resampling.BOX))).tofile(DEST/'map.rgb')
def sample(arr,x,z,origin,step):
    return map_coordinates(arr,[[(z-origin[1])/step-.5],[(x-origin[0])/step-.5]],order=1,mode='nearest')[0]
# Coarse regional cells skip the original local square and the added airport patches.
triangles=[]
for row in range(256):
    for col in range(256):
        x=col*320-40960;z=row*320-40960
        if -10240<=x<10240 and -10240<=z<10240:continue
        if any(abs(x+160-a['east'])<2240 and abs(z+160+a['north'])<2240 for a in primary.values()):continue
        points=[(x,z),(x+320,z),(x+320,z+320),(x,z+320)]
        for j in [0,1,2,0,2,3]:
            e,t=points[j]
            triangles.append([(e+40960)/81920,(t+40960)/81920,e,float(sample(height,e,t,(-40960,-40960),80)),t])
np.array(triangles,dtype='<f4').tofile(DEST/'mesh.f32')
for idx,(key,airport) in enumerate(primary.items()):
    dem=results[5+idx*2];picture=results[6+idx*2]
    dem.astype('<f4').tofile(DEST/f'{key}-height.f32')
    packed(picture).tofile(DEST/f'{key}-photo.rgba')
    left=airport['east']-2560;top=-airport['north']-2560
    triangles=[]
    for row in range(128):
        for col in range(128):
            for j in [0,1,2,0,2,3]:
                x=col+(j in [1,2]);z=row+(j in [2,3])
                e=left+x*40;t=top+z*40
                h=float(sample(dem,e,t,(left,top),20))
                # Blend the patch boundary into the regional elevation.
                fade=min(1,min(x,z,128-x,128-z)/5)
                base=float(sample(height,e,t,(-40960,-40960),80))
                triangles.append([x/128,z/128,e,h*fade+base*(1-fade)+.10,t])
    np.array(triangles,dtype='<f4').tofile(DEST/f'{key}-mesh.f32')
    rng=np.random.default_rng(710+key)
    x=left+rng.random(45000)*5120; z=top+rng.random(45000)*5120
    uvx=np.clip(((x-left)/2.5).astype(int),0,2047);uvy=np.clip(((z-top)/2.5).astype(int),0,2047)
    r,g,b=picture[uvy,uvx,:3].astype(float).T
    valid=(g>r*.93)&(g>b*1.04)&(g<129)&(g>34)
    for rw in runways:
        if rw['airport']!=key:continue
        along=(x-rw['east'])*np.sin(rw['heading'])+(-z-rw['north'])*np.cos(rw['heading'])
        side=(x-rw['east'])*np.cos(rw['heading'])-(-z-rw['north'])*np.sin(rw['heading'])
        valid &= ~((abs(along)<rw['length']/2+220)&(abs(side)<140))
    x=x[valid];z=z[valid]
    y=map_coordinates(dem,[(z-top)/20-.5,(x-left)/20-.5],order=1,mode='nearest')-1
    h=rng.uniform(10,21,len(x));w=h*rng.uniform(.35,.55,len(x));u=rng.integers(0,4,len(x))/4
    angle=rng.uniform(0,np.pi,len(x));rows=[]
    for theta in [angle,angle+np.pi/2]:
        for sign,t in [(-1,0),(1,0),(1,1),(-1,1)]:
            rows.append(np.stack([u+(0.002 if sign<0 else .248),np.full_like(x,t),x+sign*w*np.cos(theta),y+h*t,z+sign*w*np.sin(theta)],axis=-1))
    np.stack(rows,axis=1).reshape(-1,5).astype('<f4').tofile(DEST/f'{key}-trees.f32')
# Runtime input data uses locale-independent binary doubles and simple quoted names.
with (DEST/'runways.csv').open('w') as f:
    for r in runways:
        f.write(','.join(map(str,[r['airport'],'"'+r['designator']+'"',r['east'],r['north'],r['heading'],r['length'],r['width']]))+'\n')
(DEST/'sources.json').write_text(json.dumps(dict(region_half_extent_m=40960,regional_dem_step_m=80,regional_imagery_step_m=20,airport_dem_step_m=20,airport_imagery_step_m=2.5,runways=runways,urls=sources),indent=2))
print('Region complete',flush=True)
