"""Offline ray-integrated cloud panoramas with directional dusk illumination.

Runtime remains the existing VBA sky panorama, not moving volumetric clouds.
The 2048x384 packed RGB format is shared with the software renderer; OpenGL
uses the first 256 rows, corresponding to slopes 0..1.10 above the horizon.
"""
from pathlib import Path
import argparse
import numpy as np
from scipy.ndimage import gaussian_filter,map_coordinates
from PIL import Image


def bake(out):
    out.mkdir(parents=True,exist_ok=True)
    rng=np.random.default_rng(20261111)
    n=128;shape=(n,n,n)
    volume=np.zeros(shape,np.float32)
    for smooth,weight in [(10,.65),(5,.60),(2.5,.38),(1.0,.20),(.45,.095)]:
        f=gaussian_filter(rng.standard_normal(shape).astype('f'),smooth,mode='wrap')
        volume+=weight*(f-f.mean())/f.std()
    yaw=np.arange(2048,dtype='f')*np.pi*2/2048
    slope=np.arange(384,dtype='f')[:,None]/232
    el=np.arctan(slope);sn=np.maximum(np.sin(el),.08)
    de=np.sin(yaw)/np.maximum(slope,.035)
    dn=np.cos(yaw)/np.maximum(slope,.035)
    for name,horizon,zenith,shadow,lit,threshold,sun,alt in [
        ('day',(174,196,205),(35,91,151),(80,96,111),(254,251,239),1.05,5.50,.78),
        ('dusk',(234,169,126),(40,62,108),(70,66,87),(255,198,125),1.05,4.71,.14),
        ('storm',(166,178,181),(67,83,97),(55,66,75),(174,182,183),-.55,5.5,.5),
        ('night',(18,28,46),(3,7,19),(8,14,24),(34,44,58),1.1,1.8,.41)]:
        print('Baking',name,flush=True)
        # Horizon remains identical to runtime fog to avoid a visible seam.
        blend=(1-np.exp(-4.5*el))[...,None]
        sky=np.broadcast_to(horizon+(np.array(zenith)-horizon)*blend,(384,2048,3)).copy()
        cosine=np.sin(el)*np.sin(alt)+np.cos(el)*np.cos(alt)*np.cos(yaw-sun)
        angle=np.arccos(np.clip(cosine,-1,1))
        solar=np.maximum(0,np.cos(yaw-sun))[None,:]
        if name=='dusk':
            # Directional afterglow and cool anti-solar sky, strongest low down.
            low=np.exp(-el*3.0)
            sky+=(solar[...,None]**7)*low[...,None]*np.array([42,18,-8])
            sky+=(1-solar[...,None])*low[...,None]*np.array([-18,-8,17])
        if name!='storm':
            glow=np.exp(-angle*5.5)*.27+np.exp(-(angle/.009)**2)
            sky+=(np.array([208,216,234] if name=='night' else [255,238,194])-sky)*np.minimum(1,glow[...,None])
        if name=='night':
            stars=(rng.random(angle.shape)>.9983)*(1-np.exp(-4*slope))
            sky+=stars[...,None]*145
        trans=np.ones(angle.shape,dtype='f');clouds=np.zeros_like(sky)
        for h in np.linspace(0,1,32):
            coords=np.array(np.broadcast_arrays(48+h*22,(1+h*.34)*de*15,(1+h*.34)*dn*15),dtype='f')
            def sample(offset):
                return map_coordinates(volume,coords+np.array(offset,dtype='f')[:,None,None],order=1,mode='grid-wrap',prefilter=False)
            # Narrow base and softly eroded upper cap create detached cumulus banks.
            profile=((h-.40)/.53)**2
            raw=sample([0,0,0]);density=np.maximum(0,raw-threshold-profile)
            opacity=1-np.exp(-density*.25/sn)
            # Multiple light-path taps approximate extinction toward the sun.
            extinction=np.zeros_like(density)
            for distance in (2.5,7,14):
                offset=[distance*np.sin(alt),distance*np.cos(alt)*np.sin(sun),distance*np.cos(alt)*np.cos(sun)]
                extinction+=np.maximum(0,sample(offset)-threshold-profile)*1.1
            direct=np.exp(-extinction)
            rim=np.exp(-density*2)*np.exp(-angle*2.5)
            illumination=np.clip(.12+.69*direct+.17*h+.22*rim,0,1)
            color=np.array(shadow)+(np.array(lit)-shadow)*illumination[...,None]
            if name=='dusk':
                color=color*(.78+.22*solar[...,None])+np.array([7,0,5])*(1-solar[...,None])
            clouds+=(trans*opacity)[...,None]*color
            trans*=1-opacity
        result=clouds+trans[...,None]*sky
        # Suppress undersampled near-horizontal rays before they form radial streaks.
        distant=np.clip((el-.08)/.14,0,1)
        distant=distant*distant*(3-2*distant)
        result=sky+(result-sky)*distant[...,None]
        # Smooth atmospheric extinction hides near-horizon texture periodicity.
        haze=np.exp(-np.maximum(0,el-.015)*16)[...,None]
        result=result*(1-haze)+np.array(horizon)*haze
        rgb=np.uint32(np.clip(result,0,255));r,g,b=np.moveaxis(rgb,-1,0)
        ((r<<16)|(g<<8)|b).astype('<u4').tofile(out/(name+'.rgb'))
        Image.fromarray(rgb.astype('uint8')).transpose(Image.Transpose.FLIP_TOP_BOTTOM).save(out/(name+'-panorama.png'))
        # 90-degree linear-yaw preview only, not a simulated camera screenshot.
        if name=='dusk':
            center=int(4.71/(2*np.pi)*2048)
            indices=np.arange(center-256,center+256)%2048
            Image.fromarray(rgb[:256,indices].astype('uint8')).transpose(Image.Transpose.FLIP_TOP_BOTTOM).resize((1024,512)).save(out/'dusk-texture-preview.png')

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[2]/'Assets'/'Graphics')
    bake(p.parse_args().output)
