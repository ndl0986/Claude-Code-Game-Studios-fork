#!/usr/bin/env python3
"""px.py wx,wy [wx,wy...] -> RGB at world points from a raw screencap (rotation 1 mapping)."""
import subprocess, sys, os
ADB = os.path.expanduser('~/Android/sdk/platform-tools/adb')
raw = subprocess.run([ADB, 'exec-out', 'screencap'], capture_output=True).stdout
w, h = int.from_bytes(raw[0:4], 'little'), int.from_bytes(raw[4:8], 'little')
hdr = 16 if len(raw) >= 16 + w * h * 4 else 12
K = min((2400 - 136) / 1280, (1080 - 74 - 84) / 720); OX = 136 + ((2400 - 136) - 1280 * K) / 2; OY = 74
out = []
for a in sys.argv[1:]:
    wx, wy = map(float, a.split(',')); x, y = round(OX + wx * K), round(OY + wy * K)
    o = hdr + (y * w + x) * 4; out.append('%d,%d,%d' % tuple(raw[o:o + 3]))
print(w, h, *out)
