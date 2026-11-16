"""Offline mesh inspection only; this is NOT a simulator screenshot or runtime renderer."""
from pathlib import Path
import argparse
import numpy as np
from PIL import Image, ImageDraw


def render(path, size=(1200,800), yaw=-35, pitch=23):
    width,height=size
    m=np.fromfile(path,dtype='<f4').reshape(-1,3,6)
    p=m[:,:,3:].astype(float)
    yaw,pitch=np.deg2rad([yaw,pitch])
    right=np.array([np.cos(yaw),0,np.sin(yaw)])
    forward=np.array([-np.sin(yaw)*np.cos(pitch),-np.sin(pitch),np.cos(yaw)*np.cos(pitch)])
    up=np.cross(forward,right)
    depth=p@forward
    screen=np.stack([p@right,-p@up],axis=-1)*(width/12)+[width/2,height*.52]
    pixels=np.zeros((height,width,3),dtype=np.uint8);pixels[:]=[169,192,203]
    zbuf=np.full((height,width),np.inf)
    for k,tri in enumerate(screen):
        x0=max(0,int(np.floor(tri[:,0].min())));x1=min(width,int(np.ceil(tri[:,0].max()))+1)
        y0=max(0,int(np.floor(tri[:,1].min())));y1=min(height,int(np.ceil(tri[:,1].max()))+1)
        if x0>=x1 or y0>=y1:continue
        (ax,ay),(bx,by),(cx,cy)=tri
        denom=(by-cy)*(ax-cx)+(cx-bx)*(ay-cy)
        if abs(denom)<1e-8:continue
        yy,xx=np.mgrid[y0:y1,x0:x1];xx=xx+.5;yy=yy+.5
        a=((by-cy)*(xx-cx)+(cx-bx)*(yy-cy))/denom
        b=((cy-ay)*(xx-cx)+(ax-cx)*(yy-cy))/denom
        c=1-a-b
        z=a*depth[k,0]+b*depth[k,1]+c*depth[k,2]
        mask=(a>=0)&(b>=0)&(c>=0)&(z<zbuf[y0:y1,x0:x1])
        colors=a[:,:,None]*m[k,0,:3]+b[:,:,None]*m[k,1,:3]+c[:,:,None]*m[k,2,:3]
        pixels[y0:y1,x0:x1][mask]=(colors[mask]*255).clip(0,255).astype(np.uint8)
        zbuf[y0:y1,x0:x1][mask]=z[mask]
    image=Image.fromarray(pixels)
    ImageDraw.Draw(image).text((20,20),'OFFLINE GEOMETRY INSPECTION - NOT EXCEL EXECUTION',fill='#183448')
    return image


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('output',type=Path);p.add_argument('--yaw',type=float,default=-35);p.add_argument('--pitch',type=float,default=23)
    args=p.parse_args();render(args.source,yaw=args.yaw,pitch=args.pitch).save(args.output)
