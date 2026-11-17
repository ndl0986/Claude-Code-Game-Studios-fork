#!/usr/bin/env python3
"""Generate a device-side sendevent script for multi-touch on /dev/input/event1.
Usage: mt.py 'down 0 X Y; wait 0.5; down 1 X Y; up 1; wait 0.3; move 0 X Y; up 0'
X,Y are LANDSCAPE screen px (2400x1080). Mapping to the panel's 0..32767 natural-portrait axes is set by MAP."""
import sys, subprocess
DEV = '/dev/input/event1'
EV_SYN, EV_KEY, EV_ABS = 0, 1, 3
SLOT, TID, PX, PY, BTN, TOUCH = 0x2f, 0x39, 0x35, 0x36, 0x14a, 0x14a
PRESS, TOUCHMAJ = 0x3a, 0x30   # the app ignores zero-pressure touches; same values as fastmt.py
def to_panel(x, y):
    # ROTATION_90: landscape (x,y) -> natural portrait (nx, ny) = (1080-1-y?, x?) ; set empirically
    import os
    m = os.environ.get('MAP', 'a')
    if m == 'a': nx, ny = 1079 - y, x
    elif m == 'b': nx, ny = y, 2399 - x
    elif m == 'c': nx, ny = x, y
    return round(nx * 32767 / 1079), round(ny * 32767 / 2399)
lines, active, tid = [], set(), [100]
def ev(t, c, v): lines.append(f'sendevent {DEV} {t} {c} {v}')
def syn(): ev(EV_SYN, 0, 0)
for cmd in sys.argv[1].split(';'):
    p = cmd.split()
    if not p: continue
    if p[0] == 'wait': lines.append(f'sleep {p[1]}'); continue
    s = int(p[1])
    if p[0] in ('down', 'move'):
        x, y = to_panel(int(p[2]), int(p[3]))
        ev(EV_ABS, SLOT, s)
        if p[0] == 'down': tid[0] += 1; ev(EV_ABS, TID, tid[0])
        ev(EV_ABS, PX, x); ev(EV_ABS, PY, y); ev(EV_ABS, PRESS, 80); ev(EV_ABS, TOUCHMAJ, 6)
        if p[0] == 'down' and not active: ev(EV_KEY, BTN, 1)
        if p[0] == 'down': active.add(s)
        syn()
    elif p[0] == 'up':
        ev(EV_ABS, SLOT, s); ev(EV_ABS, PRESS, 0); ev(EV_ABS, TID, -1); active.discard(s)
        if not active: ev(EV_KEY, BTN, 0)
        syn()
script = '\n'.join(lines)
subprocess.run([__import__('os').path.expanduser('~/Android/sdk/platform-tools/adb'), 'shell', script], check=True)
