"""OQ-1 idle check: turn each proposed idle part to its full amplitude (both ways, and with the other part at its
extremes) around its pivot. For each pose, report whether the body stays one shape: no gap opens at a joint.
A gap the 6-unit outline would close at rest still shows as stardust islands and, under rotation, as a visible split.

Usage: python idle_check.py <keys>   e.g. python idle_check.py e,h,i,l,m,c,x,z,s,k,w,g,o
The amplitudes are the OQ-1 proposal (degrees). Cast Rendering R7 owns the real values, as data."""
import itertools, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shapely import affinity
from shapely.ops import unary_union
from lib import allparts
from figures import FIG

# family -> {part: amplitude in degrees}, the OQ-1 proposal
PROPOSAL = {
    'duckbill': {'head': 4, 'tail': 3},
    'horned':   {'head': 3, 'tail': 3},
    'plated':   {'head': 2, 'tail': 4},
    'ornitho':  {'head': 5, 'tail': 3},
}
FAMILY = {**{k: 'duckbill' for k in 'ehilm'}, **{k: 'horned' for k in 'cxz'}, **{k: 'plated' for k in 'skw'},
          **{k: 'ornitho' for k in 'go'}}
EXPECTED = {'m': 2}   # M's baby stands apart by design

def islands(root, angles):
    shapes = []
    for p in allparts(root):
        a = angles.get(p.name, 0)
        for _, gs in p.body:
            for g in gs:
                shapes.append(affinity.rotate(g, a, origin=p.pivot) if a else g)
    u = unary_union(shapes).buffer(3, 24, join_style=1)   # the silhouette rule: body union + 3
    return len(getattr(u, 'geoms', [u]))

def main(keys):
    ok = True
    for k in keys:
        amp = PROPOSAL[FAMILY[k]]
        root = FIG[k][2]()
        names = {p.name for p in allparts(root)}
        missing = [n for n in amp if n not in names]
        worst = 0
        for signs in itertools.product((-1, 0, 1), repeat=len(amp)):
            angles = {n: s * amp[n] for n, s in zip(amp, signs)}
            worst = max(worst, islands(root, angles))
        want = EXPECTED.get(k, 1)
        good = worst == want and not missing
        ok &= good
        print(f'{k} {FAMILY[k]}: {amp} -> most islands {worst} (expected {want}){" MISSING " + str(missing) if missing else ""} {"OK" if good else "GAP"}')
    print('ALL OK' if ok else 'PROBLEM')

if __name__ == '__main__':
    main(sys.argv[1].split(','))
