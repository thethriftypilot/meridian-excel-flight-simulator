"""Bake tiled terrain strips and cutout tree geometry for the Windows OpenGL view."""
from build_terrain import OUT, ROOT, export, NAIP, MX, MY, SCALE
from concurrent.futures import ThreadPoolExecutor
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import map_coordinates, distance_transform_edt, gaussian_filter
import json
from math import sin, cos

dest=ROOT/'Assets'/'Landscape'
dest.mkdir(exist_ok=True)
rng=np.random.default_rng(202611)
def tile(pair):
    y,x=pair
    box=[MX+(-2560+x*2560)/SCALE, MY-(-2560+(y+1)*2560)/SCALE,
         MX+(-2560+(x+1)*2560)/SCALE, MY-(-2560+y*2560)/SCALE]
    return export(NAIP,2048,f'airport-detail-{y}-{x}.jpg',dict(format="jpg",bandIds="0,1,2"),box)
with ThreadPoolExecutor(4) as pool:
    tiles=list(pool.map(tile,[(0,0),(0,1),(1,0),(1,1)]))
photo=np.vstack([np.hstack([t[0] for t in tiles[:2]]),np.hstack([t[0] for t in tiles[2:]])])
assert photo.shape==(4096,4096,3)
# Windows DIB / GL_BGRA input.
def bgra(img):
    a=np.asarray(img.convert('RGBA'))
    return a[:,:,[2,1,0,3]].copy()
bgra(Image.fromarray(photo)).tofile(dest/'airport.rgba')
terrain=np.fromfile(OUT/'height.bin','<f4').reshape(1024,1024)
imagery=np.fromfile(OUT/'color-lod1.bin','<u4').reshape(1024,1024)
def elevation(x,z):
    return map_coordinates(terrain,[(z+10240)/20-.5,(x+10240)/20-.5],order=1,mode='nearest')
# A tree silhouette built from sunlit clumps over branch structure.
atlas=Image.new('RGBA',(512,128))
for species in range(4):
    img=Image.new('RGBA',(128,128)); d=ImageDraw.Draw(img)
    d.polygon([(61,124),(69,124),(65,49),(63,48)],fill=(83,74,57,255))
    for k in range(95):
        angle=rng.uniform(0,2*np.pi); radius=np.sqrt(rng.random())
        cx=64+42*radius*np.cos(angle); cy=54+40*radius*np.sin(angle)
        d.line([(64,102),(cx,cy)],fill=(64,60,43,255),width=2)
    for k in range(1600):
        angle=rng.uniform(0,2*np.pi); radius=np.sqrt(rng.random())
        cx=64+(40+5*np.sin(5*angle+species))*radius*np.cos(angle)
        cy=53+(37+6*np.cos(3*angle))*radius*np.sin(angle)
        light=60+23*(1-radius)+18*(64-cx)/45+rng.normal(0,8)
        col=tuple(int(np.clip(c,0,255)) for c in (light*.91+species*4,light*1.14+9,light*.72))
        r=rng.uniform(1.8,5)
        d.ellipse([cx-r,cy-r,cx+r,cy+r],fill=(*col,255))
    atlas.paste(img,(128*species,0))
foliage=bgra(atlas.transpose(Image.Transpose.FLIP_TOP_BOTTOM))
empty=foliage[:,:,3]==0
nearest=distance_transform_edt(empty,return_distances=False,return_indices=True)
foliage[:,:,:3]=foliage[tuple(nearest)][:,:,:3]
foliage.tofile(dest/'trees.rgba')
# One tile covers the runway width and 40 metres of length.
y,x=np.indices((512,512)); side=(x+.5)/512*30.48-15.24
grit=rng.normal(0,6,x.shape)
coarse=gaussian_filter(rng.normal(0,1,x.shape),6,mode='wrap')
rubber=np.exp(-((abs(side)-2.15)/.98)**2)*(12+4*np.cos(side*21)+3*np.sin(side*39))
asphalt=70+grit+coarse*42-rubber
bgra(Image.fromarray(np.uint8(np.clip(asphalt[:,:,None]+[1,3,4],0,255)))).tofile(dest/'asphalt.rgba')
sizes=[]; total=0
with (dest/'mesh.f32').open('wb') as mesh,(dest/'groves.f32').open('wb') as forest:
    for tz in range(16):
        for tx in range(16):
            left=tx*1280-10240; top=tz*1280-10240
            coord=np.arange(33)*40
            X,Z=np.meshgrid(left+coord,top+coord)
            H=elevation(X,Z)
            near=6<=tx<10 and 6<=tz<10
            origin,extent=(-2560,5120) if near else (-10240,20480)
            vertices=np.stack([(X-origin)/extent,(Z-origin)/extent,X,H,Z],axis=-1)
            strips=[]
            for k in range(32):
                pair=vertices[[k,k+1]].transpose(1,0,2).reshape(-1,5)
                strips.extend([pair[:1],pair,pair[-1:]])
            np.concatenate(strips).astype('<f4').tofile(mesh)
            # Jittered candidates only on dark wooded imagery; exclude airport movement area.
            x=left+rng.random(3200)*1280; z=top+rng.random(3200)*1280
            c=imagery[((z+10240)/20).astype(int),((x+10240)/20).astype(int)]
            r=c>>16;g=(c>>8)&255;b=c&255
            wooded=(g>r*.93)&(g>b*1.04)&(g<129)&(g>34)
            s=x*sin(2.46477)-z*cos(2.46477); side=x*cos(2.46477)+z*sin(2.46477)
            wooded &= ~((abs(s)<1100)&(side<150)&(side>-330))
            x=x[wooded];z=z[wooded];y=elevation(x,z)-1.0
            h=rng.uniform(9,22,len(x));w=h*rng.uniform(.35,.55,len(x));u=rng.integers(0,4,len(x))/4
            rot=rng.uniform(0,np.pi,len(x));rows=[]
            for theta in [rot,rot+np.pi/2]:
                for sign,t in [(-1,0),(1,0),(1,1),(-1,1)]:
                    rows.append(np.stack([u+(0.002 if sign<0 else .248)+np.zeros_like(x),np.full_like(x,t),x+sign*w*np.cos(theta),y+h*t,z+sign*w*np.sin(theta)],axis=-1))
            batch=np.stack(rows,axis=1).reshape(-1,5).astype('<f4')
            sizes.append(len(batch));total+=len(x);batch.tofile(forest)
np.array(sizes,dtype='<i4').tofile(dest/'counts.i32')
(dest/'source.json').write_text(json.dumps(dict(airport_imagery=[t[1] for t in tiles],metres_per_pixel=1.25,trees=total,placement="synthetic scenery inferred from imagery colour"),indent=2))
print("Tree instances",total)
