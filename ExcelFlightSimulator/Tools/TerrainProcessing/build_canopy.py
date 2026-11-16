"""Original shaded tree impostor atlas; offline only, no photographic assets."""
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import gaussian_filter

def canopy_atlas(size=512):
    atlas=Image.new('RGBA',(size*4,size))
    for species in range(4):
        rng=np.random.default_rng(8750+species)
        yy,xx=np.indices((size,size),dtype=float)
        x=(xx+.5)/size; y=(yy+.5)/size
        depth=np.full(x.shape,-10.0); shade=np.zeros(x.shape)
        leaf=gaussian_filter(rng.normal(0,1,x.shape),1.3);leaf/=leaf.std()
        # Crown architectures: spreading oak, loblolly pine, asymmetric maple,
        # and taller tulip-poplar. Original generalized species, not survey data.
        count=[340,200,320,280][species]
        for k in range(count):
            a=rng.uniform(0,np.pi*2); r=np.sqrt(rng.random())
            if species==1:
                cy=rng.uniform(.12,.76); spread=.07+.27*(cy-.12)/.64
                cx=.5+np.cos(a)*r*spread
                rx=rng.uniform(.035,.085)*(0.65+cy); ry=rx*.63
            else:
                sx=[.29,.22,.30,.23][species]; sy=[.23,.29,.25,.30][species]
                cy=.40+np.sin(a)*r*sy; cx=.5+np.cos(a)*r*sx
                if species==2:cx+=.06*np.sin(cy*9)
                rx=rng.uniform(.03,.075);ry=rx*rng.uniform(.75,1.2)
            dx=(x-cx)/rx;dy=(y-cy)/ry;rr=dx*dx+dy*dy+.11*leaf
            nz=np.sqrt(np.maximum(0,1-rr))
            z=.12*np.sqrt(max(0,1-r*r))+rng.uniform(-.025,.025)+nz*rx+.003*leaf
            visible=(rr<1)&(z>depth)
            # Broad crown ambient occlusion and local spherical leaf-clump light.
            illum=np.clip(.50-.23*dx-.32*dy+.30*nz, .18,1.12)
            illum*=.67+.33*(1-y)
            depth[visible]=z[visible];shade[visible]=illum[visible]
        opaque=depth>-9
        noise=gaussian_filter(rng.normal(0,1,x.shape),size/160)
        noise/=noise.std()
        fine=rng.normal(0,1,x.shape)
        holes=(noise < -1.35)&(fine<.15)
        edge=gaussian_filter(opaque.astype(float),size/170)
        opaque &= (~holes)|(edge>.985)
        opaque &= ~((leaf < -2.0)&(noise < -.4))
        # Leaf variation stays subtle at full distance but gives crown texture.
        light=shade*(1+.09*noise)+fine*.025
        base=np.array([(92,116,59),(74,103,62),(103,127,62),(86,116,60)][species])
        rgb=np.uint8(np.clip(light[...,None]*base+np.array([7,10,5]),0,255))
        img=Image.new('RGBA',(size,size));draw=ImageDraw.Draw(img)
        def p(coords):return [(int(a*size),int(b*size)) for a,b in coords]
        draw.polygon(p([(.478,.98),(.523,.98),(.513,.56),(.491,.54)]),fill=(74,64,48,255))
        for k in range(13):
            cy=rng.uniform(.35,.72);cx=.5+rng.uniform(-.22,.22)
            draw.line(p([(.5,.9),(.5,.66),(cx,cy)]),fill=(66,59,42,255),width=max(2,int(size*.006)))
        crown=Image.fromarray(np.dstack([rgb,np.uint8(opaque)*255]),'RGBA')
        img.alpha_composite(crown)
        atlas.paste(img,(species*size,0))
    return atlas

if __name__=='__main__':
    canopy_atlas().save('canopy-atlas.png')
