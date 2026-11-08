"""Validate the retained FAA footprint against the runtime runway constants."""
from pathlib import Path
import json
import math
import re

root = Path(__file__).resolve().parents[2]
data = json.loads((root / 'Assets/Airports/KFCI-runway.json').read_text(encoding='utf-8-sig'))
source = (root / 'Source/VBA/modWorld.bas').read_text()
feature, = data['features']
attributes = feature['attributes']
assert attributes['DESIGNATOR'] == '15/33'
assert attributes['DIM_UOM'] == 'FT'
assert attributes['LENGTH'] == 5500 and attributes['WIDTH'] == 100

def local(point):
    lon, lat = point
    correction = math.cos(math.radians(37.4065))
    east = math.radians(lon + 77.5248333333) * 6378137 * correction
    north = (math.log(math.tan(math.pi / 4 + math.radians(lat) / 2))
             - math.log(math.tan(math.pi / 4 + math.radians(37.4065) / 2))) * 6378137 * correction
    return east, north

points = [local(point) for point in feature['geometry']['rings'][0][:4]]
northwest = tuple((points[1][i] + points[2][i]) / 2 for i in range(2))
southeast = tuple((points[0][i] + points[3][i]) / 2 for i in range(2))
expected = {
    'RunwayCenterEast': (northwest[0] + southeast[0]) / 2,
    'RunwayCenterNorth': (northwest[1] + southeast[1]) / 2,
    'RunwayHeading': math.atan2(southeast[0] - northwest[0], southeast[1] - northwest[1]),
}
for name, value in expected.items():
    actual = float(re.search(rf'Const {name} As Double = ([\d.\-]+)', source)[1])
    assert abs(actual - value) < 1e-7, (name, actual, value)
report = {
    'status': 'PASS',
    'effective': '2026-10-29 to 2026-12-24',
    'runtime_center_and_heading_match_retained_FAA_polygon': True,
    'published_length_metres': attributes['LENGTH'] * .3048,
    'published_width_metres': attributes['WIDTH'] * .3048,
    'projected_centerline_metres': math.dist(northwest, southeast),
    'note': 'Runtime uses published dimensions, polygon center/heading, and the existing local terrain projection. Geometry is not survey-grade.',
}
(root / 'Tests/airport-source.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
