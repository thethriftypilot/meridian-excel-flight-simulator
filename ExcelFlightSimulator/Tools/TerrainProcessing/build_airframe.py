"""Build a small painted low-wing touring aircraft, in metres in body coordinates."""
import numpy as np
from pathlib import Path
out=Path(__file__).resolve().parents[2]/'Assets'/'Landscape'/'airframe.f32'
mesh=[]
ivory=(.93,.91,.83); red=(.58,.105,.09); blue=(.10,.17,.22); glass=(.16,.33,.40)
def face(points,color):
    # Body axes are right, up, aft. Two triangles per four-sided patch.
    pts=np.asarray(points,dtype=float)
    normal=np.cross(pts[1]-pts[0],pts[2]-pts[0]); normal/=max(1e-10,np.linalg.norm(normal))
    light=.80+.18*abs(normal[1])+.10*normal[0]
    for j in ([0,1,2] if len(points)==3 else [0,1,2,0,2,3]):
        mesh.append([*np.clip(np.array(color)*light,0,1),*pts[j]])
def loft(stations):
    rings=[]
    for z,w,low,high in stations:
        rings.append([[w*np.cos(a),(low+high)/2+np.sin(a)*(high-low)/2,z] for a in np.arange(32)*np.pi/16])
    for i,(front,back) in enumerate(zip(rings,rings[1:])):
        for j in range(32):
            k=(j+1)%32; a=(j+.5)*np.pi/16
            col=ivory
            if 0<np.sin(a)<.20:col=red
            if -.20<np.sin(a)<-.07:col=blue
            if i in (3,4,5) and np.sin(a)>.27 and (i==3 or abs(np.cos(a))>.40):col=glass
            face([front[j],front[k],back[k],back[j]],col)
loft([(-3.0,.02,-.03,.1),(-2.72,.38,-.32,.39),(-2.05,.60,-.46,.59),(-1.30,.64,-.47,.60),(-.68,.68,-.47,1.31),(-.53,.69,-.47,1.33),(.46,.65,-.42,1.23),(.69,.60,-.40,1.12),(1.18,.52,-.33,.91),(3.18,.19,-.10,.44),(3.72,.035,.06,.36)])
for side in (-1,1):
    stations=[(.48,-1.0,1.07,-.18),(2.45,-.84,1.07,-.11),(4.90,-.57,.98,.12),(5.35,-.43,.85,.17),(5.48,-.28,.68,.18)]
    for i,(a,b) in enumerate(zip(stations,stations[1:])):
        def profile(st):
            x,l,t,y=st
            return [(side*x,y,l),(side*x,y+.115,l+.24),(side*x,y+.075,t-.27),(side*x,y,t),(side*x,y-.07,l+.22)]
        for k in range(5):
            pa,pb=profile(a),profile(b);j=(k+1)%5
            face([pa[k],pa[j],pb[j],pb[k]],red if i>=3 else (ivory if k!=2 else (.77,.78,.75)))
    face([(side*.1,.23,2.65),(side*1.9,.27,2.92),(side*1.84,.29,3.56),(side*.10,.24,3.59)],ivory)
    face([(side*.05,.33,2.48),(side*.05,1.72,3.02),(side*.05,1.91,3.42),(side*.05,.35,3.64)],red)
    face([(side*.055,1.33,2.92),(side*.055,1.47,2.96),(side*.055,1.51,3.46),(side*.055,1.38,3.49)],ivory)
def wheel(x,z):
    face([(x-.04,-.21,z),(x+.04,-.21,z),(x+.04,-.90,z+.02),(x-.04,-.90,z+.02)],(.53,.54,.52))
    for k in range(16):
        a,b=np.array([k,k+1])*np.pi/8
        y1,z1=-.90+.22*np.sin(a),z+.22*np.cos(a);y2,z2=-.90+.22*np.sin(b),z+.22*np.cos(b)
        face([(x-.085,y1,z1),(x+.085,y1,z1),(x+.085,y2,z2),(x-.085,y2,z2)],(.12,.13,.13))
        for side in [-1,1]:face([(x+side*.085,-.90,z),(x+side*.085,y1,z1),(x+side*.085,y2,z2)],(.21,.22,.22))
for x,z in [(-1.18,.13),(1.18,.13),(0,-1.93)]:wheel(x,z)
np.array(mesh,dtype='<f4').tofile(out)
