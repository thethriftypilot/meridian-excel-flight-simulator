"""Bake tiled terrain strips and cutout tree geometry for the Windows OpenGL view."""
from build_terrain import OUT, ROOT, export, NAIP, MX, MY, SCALE
from concurrent.futures import ThreadPoolExecutor
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import map_coordinates, distance_transform_edt, gaussian_filter
import json, argparse
from pathlib import Path
from build_canopy import canopy_atlas
from math import sin, cos

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output',type=Path,default=ROOT/'Assets'/'Landscape')
args=parser.parse_args()
dest=args.output
dest.mkdir(parents=True,exist_ok=True)
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
# Four original species silhouettes, shaded as overlapping crown volumes.
atlas=canopy_atlas(512)
atlas.save(dest/'trees-preview.png')
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
            # Stratified positions avoid overlapping tree centres while keeping a natural jitter.
            gx,gz=np.meshgrid(np.arange(46),np.arange(46))
            x=left+(gx.ravel()+rng.uniform(.04,.96,gx.size))*1280/46
            z=top+(gz.ravel()+rng.uniform(.04,.96,gz.size))*1280/46
            c=imagery[((z+10240)/20).astype(int),((x+10240)/20).astype(int)]
            r=c>>16;g=(c>>8)&255;b=c&255
            wooded=(g>r*.93)&(g>b*1.04)&(g<129)&(g>34)
            s=x*sin(2.46477)-z*cos(2.46477); side=x*cos(2.46477)+z*sin(2.46477)
            wooded &= ~((abs(s)<1100)&(side<150)&(side>-330))
            x=x[wooded];z=z[wooded];y=elevation(x,z)-1.0
            # Mature stands share a gently varying canopy height; gaps still follow imagery.
            stand=(np.sin(x/340)+np.cos(z/270)+np.sin((x+z)/510))/3
            h=np.clip(22+4*stand+rng.normal(0,2.0,len(x)),12,30)
            species=rng.choice(4,len(x),p=[.39,.17,.28,.16])
            w=h*rng.uniform(.46,.61,len(x));w[species==1]*=.74
            u=species/4
            rot=rng.uniform(0,np.pi,len(x));rows=[]
            for theta in [rot,rot+np.pi/2]:
                for sign,t in [(-1,0),(1,0),(1,1),(-1,1)]:
                    rows.append(np.stack([u+(0.002 if sign<0 else .248)+np.zeros_like(x),np.full_like(x,t),x+sign*w*np.cos(theta),y+h*t,z+sign*w*np.sin(theta)],axis=-1))
            # A horizontal crown closes the obvious X-shaped gap in aerial views.
            # It samples only the leafy part of the same four-cell atlas.
            for sx,sz in [(-1,-1),(1,-1),(1,1),(-1,1)]:
                rows.append(np.stack([u+(0.002 if sx<0 else .248),np.full_like(x,.27 if sz<0 else .96),x+sx*w*.83,y+h*.69+np.zeros_like(x),z+sz*w*.83],axis=-1))
            batch=np.stack(rows,axis=1).reshape(-1,5).astype('<f4')
            sizes.append(len(batch));total+=len(x);batch.tofile(forest)
np.array(sizes,dtype='<i4').tofile(dest/'counts.i32')
(dest/'source.json').write_text(json.dumps(dict(airport_imagery=[t[1] for t in tiles],metres_per_pixel=1.25,trees=total,placement="synthetic scenery inferred from imagery colour",tree_atlas=[2048,512],tree_vertices=12,canopy="four original generalized species; crossed side impostors and overhead crown; no surveyed individual trees"),indent=2))
print("Tree instances",total)
