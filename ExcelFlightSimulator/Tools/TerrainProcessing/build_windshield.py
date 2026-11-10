"""Original pilot-eye windshield surround. Pixel coordinates match the 1000 x 700 cockpit."""
from pathlib import Path
import numpy as np
out=Path(__file__).resolve().parents[2]/'Assets'/'Landscape'
x,y=np.meshgrid(np.arange(1024)*1000/1024,np.arange(512)*400/512)
rgb=np.zeros((*x.shape,4),np.uint8)
rng=np.random.default_rng(28)
grain=rng.normal(0,1.5,x.shape)
def layer(mask,base,light):
    rgb[mask,:3]=np.clip(np.asarray(base)+light[mask,None],0,255)
    rgb[mask,3]=255
# Painted nose and raised cowling seam, visible over the glare shield.
nose=351+40*((x-511)/167)**2
layer((y>nose)&(abs(x-511)<210),[161,159,145],18*np.cos((x-480)/102)-.42*(y-nose)+grain*.4)
seam=abs(x-(505+.10*(y-351)))<.75
layer((y>nose)&(y<392)&seam,[107,107,99],grain)
# Windshield posts narrow toward their mounting points.
edge=np.minimum(x,1000-x)
post=6+32*((387-y)/360)**2
layer(edge<post+2,[24,29,30],grain)
layer(edge<post-3,[100,103,100],-22*(edge/np.maximum(post,1))+grain)
layer(edge<post-9,[50,54,52],-12*edge/np.maximum(post,1)+grain)
top=370+11*((x-505)/500)**2+3*np.cos(x/230)
layer(y>top,[26,30,31],grain+.6*(y-top))
layer((y>top+2)&(y<top+5),[65,68,67],grain)
layer(y>top+11,[39,43,43],grain+3*np.cos(x/200))
rgb[::-1][:,:,[2,1,0,3]].copy().tofile(out/'windshield.rgba')
