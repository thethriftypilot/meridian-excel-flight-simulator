"""Bake original cockpit materials and wraparound weather skies for the VBA renderer."""
from pathlib import Path
import numpy as np
from scipy.ndimage import gaussian_filter, map_coordinates

out = Path(__file__).resolve().parents[2] / "Assets" / "Graphics"
out.mkdir(exist_ok=True)
rng = np.random.default_rng(161)

def save(name, rgb):
    r, g, b = np.moveaxis(np.uint32(np.clip(rgb, 0, 255)), -1, 0)
    ((r << 16) | (g << 8) | b).astype("<u4").tofile(out / (name + ".rgb"))

def panel():
    y, x = np.indices((310, 1000))
    grain = rng.normal(0, 1.7, x.shape)
    light = 32 + 17 * (1 - y / 310) + 7 * (1 - x / 1000) + grain
    rgb = light[..., None] + np.array([1, 3, 3])
    def paint(mask, value):
        rgb[mask] = np.broadcast_to(value, rgb.shape)[mask]
    # Raised glare shield, recessed display surround and avionics rack.
    for top, bottom, base in [(0, 9, 65), (9, 14, 20), (278, 283, 24), (283, 310, 37)]:
        paint((y >= top) & (y < bottom), (base - (y-top)*0.6 + grain)[..., None]+np.array([1,3,4]))
    for inset, tone in [(0,22),(2,86),(4,50),(7,23),(10,12)]:
        paint((x>=626+inset)&(x<=988-inset)&(y>=13+inset)&(y<=275-inset), (tone+grain)[...,None]+np.array([0,3,4]))
    for cx, cy in [(85,80),(240,80),(395,80),(550,80),(85,220),(240,220),(395,220)]:
        dx,dy=x-cx,y-cy
        radius=np.hypot(dx,dy)
        direction=(-dx-dy)/np.maximum(radius,1)/1.42
        for outer, level, shine in [(70,22,8),(68,74,50),(66,47,37),(63,18,12),(61,16,4)]:
            val=level+shine*direction+grain*.45
            if outer==61: val=13+7*(1-radius/61)+4*direction+grain*.2
            paint(radius<=outer,val[...,None]+np.array([0,3,5]))
        for a in [-1,1]:
            for b in [-1,1]:
                sx,sy=dx-a*55,dy-b*54
                screw=np.hypot(sx,sy)
                paint(screw<4.2,(70-6*sx-6*sy)[...,None]+np.array([0,2,4]))
                paint((screw<3)&(abs(sx+sy)<1.2),[25,28,30])
    save("panel",rgb)

def skies():
    size=96
    volume=np.zeros((size,size,size),np.float32)
    for width,weight in [(8,1),(4,.55),(2,.30),(.9,.17)]:
        band=gaussian_filter(rng.standard_normal(volume.shape).astype("f"),width,mode="wrap")
        volume+=weight*(band-band.mean())/band.std()
    yaw=np.arange(2048)*2*np.pi/2048
    slope=np.arange(384)[:,None]/232
    # Intersect camera rays with a horizontal cloud layer.
    de=np.sin(yaw)/np.maximum(slope,.035)
    dn=np.cos(yaw)/np.maximum(slope,.035)
    for name,horizon,zenith,shadow,lit,threshold,sun,alt in [
        ("day",(174,196,205),(42,107,169),(111,132,151),(255,252,237),.48,5.50,.78),
        ("dusk",(234,169,126),(62,81,134),(98,83,111),(255,196,140),.48,4.71,.14),
        ("storm",(166,178,181),(77,95,108),(67,79,88),(173,181,185),-.75,5.5,.5),
        ("night",(18,28,46),(5,9,23),(13,20,34),(39,49,62),.75,1.8,.41)]:
        elevation=np.arctan(slope)
        blend=(1-np.exp(-3.2*elevation))[...,None]
        sky=np.broadcast_to(horizon+(np.array(zenith)-horizon)*blend,(384,2048,3)).copy()
        cosine=np.sin(elevation)*np.sin(alt)+np.cos(elevation)*np.cos(alt)*np.cos(yaw-sun)
        angle=np.arccos(np.clip(cosine,-1,1))
        if name!='storm':
            glow=np.exp(-angle*9)*.32+np.exp(-(angle/.014)**2)*.98
            sky+=(np.array([208,216,234] if name=="night" else [255,239,192])-sky)*np.minimum(1,glow[...,None])
        if name=="night":
            stars=(rng.random(angle.shape)>.997)*(1-np.exp(-4*slope))
            sky+=stars[...,None]*110
        trans=np.ones(angle.shape); clouds=np.zeros_like(sky)
        for height in np.linspace(0,1,26):
            coords=np.array(np.broadcast_arrays(34+height*14, (1+height*.42)*de*17, (1+height*.42)*dn*17))
            def sample(offset):
                return map_coordinates(volume,coords+np.array(offset)[:,None,None],order=1,mode="grid-wrap",prefilter=False)
            density=np.maximum(0,sample([0,0,0])-threshold-(2*height-1)**2*1.5)
            opacity=1-np.exp(-density*.24/np.maximum(.35,np.sin(elevation)))
            shade=np.clip(.48+.34*(density-sample([3,3*np.sin(sun),3*np.cos(sun)]))+.38*height,0,1)
            clouds+=(trans*opacity)[...,None]*(shadow+(np.array(lit)-shadow)*shade[...,None])
            trans*=1-opacity
        composite=clouds+trans[...,None]*sky
        haze=np.exp(-np.maximum(0,elevation-.032)*11)[...,None]
        save(name,composite*(1-haze)+np.array(horizon)*haze)

if __name__=="__main__":
    panel()
    skies()
