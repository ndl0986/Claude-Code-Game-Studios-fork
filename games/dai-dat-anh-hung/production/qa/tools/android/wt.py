#!/usr/bin/env python3
"""wt.py '<mt script in WORLD coords 1280x720>' : converts to landscape display px for TASK-007 native app and runs mt.py.
Safe rect from dumpsys (rotation 1: cutout left 136, status 74, gesture bottom 84). ROT=1|3. Also: wt.py --xy wx wy -> prints device px."""
import os, sys, subprocess
ROT = os.environ.get('ROT', '1')
K = min((2400 - 136) / 1280, (1080 - 74 - 84) / 720)
OX = (136 if ROT == '1' else 0) + ((2400 - 136) - 1280 * K) / 2
OY = 74 + ((1080 - 74 - 84) - 720 * K) / 2
def d(wx, wy): return round(OX + float(wx) * K), round(OY + float(wy) * K)
if sys.argv[1] == '--xy':
    print(*d(sys.argv[2], sys.argv[3])); sys.exit()
out = []
for c in sys.argv[1].split(';'):
    p = c.split()
    if p and p[0] in ('down', 'move'): x, y = d(p[2], p[3]); p = [p[0], p[1], str(x), str(y)]
    out.append(' '.join(p))
here = os.path.dirname(os.path.abspath(__file__))
subprocess.run([sys.executable, '-I', os.path.join(here, 'mt.py'), ';'.join(out)], check=True, env={**os.environ, 'MAP': 'a' if ROT == '1' else 'b'})
