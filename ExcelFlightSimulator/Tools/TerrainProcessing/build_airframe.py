"""Original Warrior-inspired exterior; output is little-endian C3F_V3F triangles.

This is an offline asset tool, never a flight-time dependency. Dimensions follow
Piper's general Warrior II three-view; contours, materials and detail are estimates.
Use --output to generate a candidate without replacing the runtime asset.
"""
from pathlib import Path
import argparse
import json
import hashlib
import numpy as np
from scipy.interpolate import PchipInterpolator

ROOT = Path(__file__).resolve().parents[2]
mesh = []
IVORY = np.array((.91, .925, .91))
NAVY = np.array((.075, .14, .205))
RED = np.array((.57, .065, .045))
RUBBER = np.array((.038, .044, .048))
METAL = np.array((.42, .47, .49))
SUN = np.array((-.35, .82, -.45)); SUN /= np.linalg.norm(SUN)


def shade(color, normal, gloss=0):
    n = np.asarray(normal); n = n / max(1e-10, np.linalg.norm(n))
    # Baked directional diffuse + hemispherical fill, not runtime PBR lighting.
    diffuse = max(0, float(n @ SUN))
    light = .56 + .32 * diffuse + .10 * max(0, n[1])
    return np.clip(np.asarray(color) * light + gloss * diffuse ** 18, 0, 1)


def face(points, color, normals=None, gloss=0):
    p = np.asarray(points, dtype=float)
    n = np.cross(p[1]-p[0], p[2]-p[0]); n /= max(1e-10, np.linalg.norm(n))
    for j in ([0, 1, 2] if len(p)==3 else [0, 1, 2, 0, 2, 3]):
        c = shade(color, n if normals is None else normals[j], gloss)
        mesh.append([*c, *p[j]])


def tube(a, b, radius, color, sides=10):
    a, b = np.array(a), np.array(b)
    axis = b-a; axis /= np.linalg.norm(axis)
    ref = np.array([0, 1, 0]) if abs(axis[1]) < .9 else np.array([1, 0, 0])
    u = np.cross(axis, ref); u /= np.linalg.norm(u); v = np.cross(axis, u)
    for i in range(sides):
        n0 = u*np.cos(i*2*np.pi/sides)+v*np.sin(i*2*np.pi/sides)
        n1 = u*np.cos((i+1)*2*np.pi/sides)+v*np.sin((i+1)*2*np.pi/sides)
        face([a+radius*n0, a+radius*n1, b+radius*n1, b+radius*n0], color, [n0,n1,n1,n0], .04)


# z aft, half-width, lower skin, upper skin. Propeller is animated by VBA at -3.02.
STATIONS = np.array([
    [-3.06,.15,-.03,.27],[-2.94,.36,-.23,.40],[-2.62,.48,-.31,.48],
    [-2.13,.56,-.38,.49],[-1.46,.57,-.39,.51],[-1.15,.57,-.40,.57],
    [-.58,.60,-.42,.97],[-.20,.61,-.42,1.00],[.43,.59,-.40,.96],
    [.87,.55,-.36,.86],[1.24,.47,-.30,.67],[2.03,.34,-.20,.45],
    [2.90,.20,-.10,.30],[3.71,.09,-.01,.22],[4.19,.012,.09,.15]])
SHAPE = PchipInterpolator(STATIONS[:,0], STATIONS[:,1:], axis=0)


def skin(z, a, offset=0):
    w, lo, hi = SHAPE(z)
    return np.array([(w+offset)*np.cos(a), (lo+hi)/2+((hi-lo)/2+offset)*np.sin(a), z])


def skin_normal(z, a):
    dz=.0001
    p0=skin(max(STATIONS[0,0],z-dz),a);p1=skin(min(STATIONS[-1,0],z+dz),a)
    tangent = skin(z,a+.0001)-skin(z,a-.0001)
    n=np.cross(tangent,p1-p0);return n/max(1e-10,np.linalg.norm(n))


def fuselage():
    zs = np.unique(np.r_[np.linspace(-3.06,4.19,83),STATIONS[:,0]])
    angles=np.linspace(0,2*np.pi,73)
    for z0,z1 in zip(zs,zs[1:]):
        for a0,a1 in zip(angles,angles[1:]):
            z=(z0+z1)/2;a=(a0+a1)/2;p=skin(z,a)
            c=IVORY
            points=[skin(z0,a0),skin(z0,a1),skin(z1,a1),skin(z1,a0)]
            normals=[skin_normal(z0,a0),skin_normal(z0,a1),skin_normal(z1,a1),skin_normal(z1,a0)]
            face(points,c,normals,.035)
    # Continuous paint ribbons follow the curved skin with no polygon-sized steps.
    for low,high,color in [(-.32,-.18,NAVY),(-.11,.025,RED)]:
        for side in (-1,1):
            angles=[np.arcsin(low),np.arcsin(high)]
            if side<0:angles=[np.pi-a for a in angles]
            zz=np.linspace(-2.94,3.91,110)
            for z0,z1 in zip(zz,zz[1:]):
                a0,a1=angles
                face([skin(z0,a0,.003),skin(z0,a1,.003),skin(z1,a1,.003),skin(z1,a0,.003)],color,
                     [skin_normal(z0,a0),skin_normal(z0,a1),skin_normal(z1,a1),skin_normal(z1,a0)])
    # Polished spinner beyond the existing prop plane.
    for i in range(48):
        a=i*2*np.pi/48;b=(i+1)*2*np.pi/48
        face([[0,.12,-3.28],[.15*np.cos(a),.12+.15*np.sin(a),-3.055],[.15*np.cos(b),.12+.15*np.sin(b),-3.055]],IVORY)


def window(z0,z1,a0,a1):
    # A curved patch of reflective blue-grey glazing, with rounded inset corners.
    nz,na=12,12
    for i in range(nz):
        for j in range(na):
            u0,u1=i/nz,(i+1)/nz;v0,v1=j/na,(j+1)/na
            def point(u,v):
                z=z0+(z1-z0)*u
                inset=.025*(abs(2*u-1)**8)
                a=a0+(a1-a0)*(inset+(1-2*inset)*v)
                return skin(z,a,.009)
            pts=[point(u0,v0),point(u0,v1),point(u1,v1),point(u1,v0)]
            middle=(j+.5)/na
            # Reflected horizon is intentionally subtle and baked.
            c=np.array((.095,.19,.25))*(.75+.65*middle)
            if .65<middle<.76:c+=np.array((.06,.07,.065))
            ns=[skin_normal(p[2],np.arctan2(p[1]-.25,p[0])) for p in pts]
            face(pts,c,ns,.13)
    for z in (z0,z1):
        arr=[skin(z,a,.012) for a in np.linspace(a0,a1,20)]
        for a,b in zip(arr,arr[1:]):tube(a,b,.009,RUBBER,6)
    for a in (a0,a1):
        arr=[skin(z,a,.012) for z in np.linspace(z0,z1,20)]
        for p,q in zip(arr,arr[1:]):tube(p,q,.009,RUBBER,6)


def glazing():
    # Split windscreen plus two side windows, preserving the opaque roof/cabin pillars.
    window(-1.04,-.57,np.deg2rad(40),np.deg2rad(87))
    window(-1.04,-.57,np.deg2rad(93),np.deg2rad(140))
    for side in (1,-1):
        a0,a1=(.06,.79) if side==1 else (np.pi-.79,np.pi-.06)
        window(-.49,.18,a0,a1)
        window(.28,.88,a0+.04,a1-.05)
        # Door outline and handle on cabin's right; understated seam on both sides.
        if side==1:
            for z in (-.52,.23):
                arr=[skin(z,a,.012) for a in np.linspace(-.55,.81,20)]
                for p,q in zip(arr,arr[1:]):tube(p,q,.0028,NAVY,5)
            arr=[skin(z,-.55,.012) for z in np.linspace(-.52,.23,20)]
            for p,q in zip(arr,arr[1:]):tube(p,q,.0028,NAVY,5)
            tube(skin(.08,-.07,.025),skin(.19,-.07,.025),.015,METAL)


def wing(side):
    # Semi-tapered planform, 35 ft total span. Estimated 15%-thick airfoil.
    xs=np.r_[np.linspace(.48,2.25,7),np.linspace(2.25,5.18,12)[1:],5.28,5.334]
    ts=(1-np.cos(np.linspace(0,np.pi,25)))/2
    def profile(x,t,upper):
        fraction=np.clip((x-2.25)/(5.334-2.25),0,1)
        chord=1.60-.55*fraction
        le=-.81+.43*fraction
        cap=np.clip((5.334-x)/.16,.07,1)
        thick=5*.15*chord*(.2969*np.sqrt(t)-.126*t-.3516*t*t+.2843*t**3-.1036*t**4)*cap
        y=-.23+.055*(x-.48)
        camber=.018*chord*np.sin(np.pi*t)
        return np.array([side*x,y+camber+(1 if upper else -1)*thick,le+chord*t])
    for upper in (True,False):
        for x0,x1 in zip(xs,xs[1:]):
            for t0,t1 in zip(ts,ts[1:]):
                pts=[profile(x0,t0,upper),profile(x1,t0,upper),profile(x1,t1,upper),profile(x0,t1,upper)]
                c=IVORY if upper else IVORY*.77
                if x0>5.17:c=RED
                if t0>.78:c=IVORY*.91
                if side==1 and .55<x0<1.25 and .3<t0<.96 and upper:c=RUBBER
                # Per-vertex smooth section shading, no extra runtime normals.
                ns=[]
                for x,t in [(x0,t0),(x1,t0),(x1,t1),(x0,t1)]:
                    tangent=profile(x,min(1,t+.0001),upper)-profile(x,max(0,t-.0001),upper)
                    n=np.cross(np.array([side,0,0]),tangent)
                    if (n[1]>0)!=upper:n=-n
                    ns.append(n)
                face(pts,c,ns,.035)
    for x in (2.25,5.10):
        arr=[profile(x,t,True)+[0,.002,0] for t in np.linspace(.74,.99,8)]
        for p,q in zip(arr,arr[1:]):tube(p,q,.0025,NAVY,5)
    arr=[profile(x,.77,True)+[0,.002,0] for x in np.linspace(.72,5.10,40)]
    for p,q in zip(arr,arr[1:]):tube(p,q,.0025,NAVY,5)
    # Fuel cap and a separate navigation-light lens.
    sphere(profile(1.68,.40,True)+[0,.012,0],(.055,.014,.055),METAL,12,6)
    sphere(profile(5.29,.17,True)+[0,.026,0],(.055,.035,.09),(.72,.025,.015) if side<0 else (.025,.48,.16),12,6)


def sphere(center,radii,color,sides=20,rings=10):
    center=np.array(center);radii=np.array(radii)
    for i in range(rings):
        a0=-np.pi/2+i*np.pi/rings;a1=-np.pi/2+(i+1)*np.pi/rings
        for j in range(sides):
            b0=j*2*np.pi/sides;b1=(j+1)*2*np.pi/sides
            ns=[np.array([np.cos(a)*np.cos(b),np.sin(a),np.cos(a)*np.sin(b)]) for a,b in [(a0,b0),(a0,b1),(a1,b1),(a1,b0)]]
            face([center+radii*n for n in ns],color,ns,.035)


def tail():
    # A tapered, closed stabilator with modeled thickness and inset trim-tab seam.
    for side in (-1,1):
        for surface in (-1,1):
            pts=[[side*.08,.17+surface*.035,2.98],[side*1.98,.17+surface*.022,3.18],[side*1.93,.17+surface*.012,3.93],[side*.08,.17+surface*.018,3.92]]
            face(pts,IVORY if surface>0 else IVORY*.70,[[0,surface,0]]*4)
        for z in (3.18,3.93):
            tube([side*1.93,.17,z],[side*1.98,.17,z],.018,RED)
        tube([side*.18,.192,3.73],[side*1.82,.192,3.77],.003,NAVY,5)
    # Fin scaled to approximately 2.23 m aircraft height at static ground line.
    contour=np.array([[0,.18,2.52],[0,.70,3.05],[0,1.11,3.41],[0,1.12,3.77],[0,.20,4.13]])
    for side in (-1,1):
        pts=contour.copy();pts[:,0]=side*.035
        for j in range(1,len(pts)-1):face([pts[0],pts[j],pts[j+1]],IVORY,[[side,0,0]]*3)
        face([[side*.038,.45,3.40],[side*.038,1.05,3.46],[side*.038,1.06,3.74],[side*.038,.45,3.98]],RED,[[side,0,0]]*4)
        tube([side*.04,.22,3.91],[side*.04,1.08,3.73],.003,NAVY,5)
    for p,q in zip(contour,np.roll(contour,-1,axis=0)):
        face([p+[-.035,0,0],q+[-.035,0,0],q+[.035,0,0],p+[.035,0,0]],IVORY)
    sphere([0,1.13,3.63],[.035,.035,.05],(.65,.035,.02),12,6)


def wheel(x,z,front=False):
    radius=.205 if front else .24
    cy=-1.12+radius
    width=.075 if front else .105
    # Rounded tire cross-section rather than a flat cylinder.
    for i in range(40):
        a0=i*2*np.pi/40;a1=(i+1)*2*np.pi/40
        for j in range(12):
            b0=j*2*np.pi/12;b1=(j+1)*2*np.pi/12
            pts=[];ns=[]
            for a,b in [(a0,b0),(a1,b0),(a1,b1),(a0,b1)]:
                radial=radius-.055+.055*np.cos(b)
                pts.append([x+width*np.sin(b),cy+radial*np.sin(a),z+radial*np.cos(a)])
                ns.append([np.sin(b),np.cos(b)*np.sin(a),np.cos(b)*np.cos(a)])
            face(pts,RUBBER,ns)
    for side in (-1,1):
        for k in range(32):
            a,b=np.array([k,k+1])*2*np.pi/32
            face([[x+side*width,cy,z],[x+side*width,cy+.12*np.sin(a),z+.12*np.cos(a)],[x+side*width,cy+.12*np.sin(b),z+.12*np.cos(b)]],METAL,[[side,0,0]]*3,.08)
        sphere([x+side*(width+.008),cy,z],[.018,.048,.048],IVORY,12,6)
    tube([x,-.26,z-.03],[x,cy+.03,z],.032,METAL,12)
    tube([x,-.32,z-.03],[x,cy+.15,z],.046,IVORY,12)
    if not front:
        # Main-gear streamlined upper fairing, lower tire remains visible.
        sphere([x,cy+.14,z+.03],[.14,.105,.34],IVORY,24,10)
    else:
        for side in (-1,1):tube([x+side*.095,cy,z],[x+side*.08,cy+.24,z-.07],.023,METAL)


def details():
    # Cooling inlets on the cowling and subtle cowl break line.
    for side in (-1,1):
        sphere([side*.27,.18,-2.955],[.13,.085,.016],RUBBER,16,8)
        tube([side*.36,-.25,-2.40],[side*.40,-.44,-2.27],.041,(.23,.23,.21),12)
    for a,b in zip(np.linspace(0,2*np.pi,65),np.linspace(0,2*np.pi,65)[1:]):
        tube(skin(-1.45,a,.003),skin(-1.45,b,.003),.0025,NAVY,5)
    # Original generalized roof antennas and right-side boarding step.
    tube([0,.96,.42],[0,1.16,.59],.009,IVORY,8)
    tube([0,.60,1.40],[0,.85,1.56],.008,IVORY,8)
    tube([.49,-.29,.84],[.76,-.65,1.04],.014,METAL,8)
    tube([.76,-.65,1.04],[.95,-.65,1.04],.022,METAL,8)


def build(output):
    mesh.clear()
    fuselage();glazing();wing(-1);wing(1);tail()
    for x,z in [(-1.524,.10),(1.524,.10),(0,-1.93)]:wheel(x,z,x==0)
    details()
    arr=np.asarray(mesh,dtype='<f4')
    # Keep the fixed propeller plane; match overall 23 ft 9.5 in length.
    arr[arr[:,5]>0,5] *= (7.2517-3.28)/4.19
    assert arr.ndim==2 and arr.shape[1]==6 and len(arr)%3==0
    assert np.isfinite(arr).all() and np.all((arr[:,:3]>=0)&(arr[:,:3]<=1))
    output.parent.mkdir(parents=True,exist_ok=True);arr.tofile(output)
    meta={'format':'C3F_V3F, little-endian float32, triangles, metres; x right/y up/z aft',
          'vertices':len(arr),'triangles':len(arr)//3,'bytes':output.stat().st_size,
          'bounds_m':{'min':arr[:,3:].min(axis=0).tolist(),'max':arr[:,3:].max(axis=0).tolist()},
          'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
          'source':'Original parametric geometry; general dimensions from Piper Warrior II POH VB-1180 Figure 1-1. Contours/materials are estimates.'}
    output.with_suffix('.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(meta,indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,default=ROOT/'Assets'/'Landscape'/'airframe.f32')
    build(parser.parse_args().output)
