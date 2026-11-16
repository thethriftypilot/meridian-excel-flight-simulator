"""Bake OSM building ways to tiled C3F_V3F triangles (offline only).

Footprints are authentic OSM geometry; heights/materials/roofs are estimated
unless tagged. Relations/courtyards are not supported and are excluded by input.
Input is a saved Overpass `way[building](bbox);out geom;` JSON response.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import numpy as np
from scipy.ndimage import map_coordinates

ROOT = Path(__file__).resolve().parents[2]


def triangulate(points):
    """Ear clipping for a simple ring; reject invalid rings rather than fill gaps."""
    p = np.asarray(points)
    cross = lambda a, b: a[0]*b[1]-a[1]*b[0]
    area = sum(cross(p[i], p[(i+1) % len(p)]) for i in range(len(p)))
    ring = list(range(len(p))) if area > 0 else list(reversed(range(len(p))))
    result = []
    while len(ring) > 3:
        found = False
        for j in range(len(ring)):
            a, b, c = ring[j-1], ring[j], ring[(j+1) % len(ring)]
            if cross(p[b]-p[a], p[c]-p[b]) <= 1e-7:
                continue
            if any(cross(p[b]-p[a], p[k]-p[a]) >= -1e-7 and
                   cross(p[c]-p[b], p[k]-p[b]) >= -1e-7 and
                   cross(p[a]-p[c], p[k]-p[c]) >= -1e-7
                   for k in ring if k not in (a,b,c)):
                continue
            result.append((a,b,c)); ring.pop(j); found = True; break
        if not found:
            return []
    result.append(tuple(ring))
    return result


def build(source, dest):
    raw = source.read_bytes(); data = json.loads(raw)
    terrain = np.fromfile(ROOT/'Assets/Terrain/height.bin', '<f4').reshape(1024,1024)
    lat, lon = 37.4065, -77.5248333333
    scale = math.cos(math.radians(lat)); radius = 6378137
    mx = radius*math.radians(lon)
    my = radius*math.log(math.tan(math.pi/4+math.radians(lat)/2))
    tiles = [[] for _ in range(256)]
    accepted = skipped = tagged = 0
    for element in data['elements']:
        geo = element.get('geometry', [])
        tags = element.get('tags', {})
        if len(geo) < 4 or geo[0] != geo[-1] or tags.get('building') in ('no','roof'):
            skipped += 1; continue
        points = np.array([[(radius*math.radians(g['lon'])-mx)*scale,
                           -(radius*math.log(math.tan(math.pi/4+math.radians(g['lat'])/2))-my)*scale]
                          for g in geo[:-1]])
        center = points.mean(axis=0)
        if max(abs(points).max(axis=0)) >= 10200:
            skipped += 1; continue
        triangles = triangulate(points)
        if not triangles:
            skipped += 1; continue
        area = abs(sum(np.linalg.det(points[[i,(i+1)%len(points)]]) for i in range(len(points))))/2
        if area < 12:
            skipped += 1; continue
        rng = np.random.default_rng(element['id'])
        residential = tags.get('building') in ('house','residential','detached','semidetached_house') or area < 230
        try:
            height = float(tags['height'].replace(' m','')) if 'height' in tags else float(tags['building:levels'])*3.1
            tagged += 1
        except (KeyError, ValueError):
            height = rng.uniform(4.0,6.5) if residential else rng.uniform(5.5,9.0)
        height = np.clip(height, 2.5, 80)
        ground = map_coordinates(terrain, [(points[:,1]+10240)/20-.5,(points[:,0]+10240)/20-.5], order=1, mode='nearest')
        base, top = float(ground.min())-.3, float(ground.max())+height
        wall = np.array([[.62,.57,.49],[.61,.43,.32],[.72,.70,.62],[.51,.53,.53]])[rng.integers(4)]
        roof = np.array([[.25,.26,.27],[.35,.31,.28],[.40,.39,.36],[.48,.49,.47]])[rng.integers(4)]
        tile = tiles[int((center[1]+10240)//1280)*16+int((center[0]+10240)//1280)]
        def vertex(p, h): return [p[0],h,p[1]]
        def tri(a,b,c,color):
            tile.extend([list(color)+a,list(color)+b,list(color)+c])
        for i, a in enumerate(points):
            b = points[(i+1)%len(points)]; edge = b-a
            lighting = .65+.25*abs(float(edge @ np.array([.7,.3])))/max(np.linalg.norm(edge),.01)
            color = wall*lighting
            tri(vertex(a,base),vertex(b,base),vertex(b,top),color)
            tri(vertex(a,base),vertex(b,top),vertex(a,top),color)
        # A four-sided hipped roof adds volume without inventing a detailed house model.
        if residential and len(points) == 4:
            peak = vertex(center, top+min(2.3, math.sqrt(area)*.13))
            for i,a in enumerate(points):
                tri(vertex(a,top),vertex(points[(i+1)%4],top),peak,roof*(.82+.06*i))
        else:
            for a,b,c in triangles:
                tri(vertex(points[a],top),vertex(points[b],top),vertex(points[c],top),roof)
        accepted += 1
    dest.mkdir(parents=True,exist_ok=True)
    counts = np.array([len(t) for t in tiles],dtype='<i4')
    counts.tofile(dest/'buildings-counts.i32')
    with (dest/'buildings.f32').open('wb') as f:
        for tile in tiles: np.asarray(tile,dtype='<f4').tofile(f)
    report = dict(buildings=accepted, skipped=skipped, tagged_heights=tagged,
                  triangles=int(counts.sum()//3), source_sha256=hashlib.sha256(raw).hexdigest(),
                  source_timestamp=data.get('osm3s',{}).get('timestamp_osm_base'),
                  attribution='© OpenStreetMap contributors', license='ODbL 1.0',
                  source='https://www.openstreetmap.org/copyright',
                  limitations='Ways only; no relations/courtyards. Roofs and materials estimated; most heights estimated. No building collisions.')
    (dest/'buildings-provenance.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args()
    build(args.source,args.output)
