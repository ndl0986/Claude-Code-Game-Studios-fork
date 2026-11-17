#!/usr/bin/env python3
"""fastmt.py '<script in WORLD coords>' — like wt.py, but streams raw input_event structs to /dev/input/event1
through ONE long-lived `cat` on the device, with timing done on the host (no per-event process spawn).
Script ops: down S X Y; move S X Y; up S; wait SECONDS. Rotation 1 mapping (MAP a). Needs adb root."""
import os, struct, subprocess, sys, time
ADB = os.path.expanduser('~/Android/sdk/platform-tools/adb'); SER = os.environ.get('ANDROID_SERIAL', 'emulator-5554')
K = min((2400 - 136) / 1280, (1080 - 74 - 84) / 720); OX = 136 + ((2400 - 136) - 1280 * K) / 2; OY = 74
EV_SYN, EV_KEY, EV_ABS = 0, 1, 3
SLOT, TID, PX, PY, PRESS, TOUCHMAJ, BTN = 0x2f, 0x39, 0x35, 0x36, 0x3a, 0x30, 0x14a
def ev(t, c, v): return struct.pack('<qqHHi', 0, 0, t, c, v)       # 64-bit input_event: timeval(16) type code value
def panel(wx, wy):
    x, y = OX + float(wx) * K, OY + float(wy) * K                     # landscape px
    nx, ny = 1079 - y, x                                              # MAP a (rotation 1)
    return round(nx * 32767 / 1079), round(ny * 32767 / 2399)
p = subprocess.Popen([ADB, '-s', SER, 'exec-in', 'cat > /dev/input/event1'], stdin=subprocess.PIPE)
time.sleep(0.3)  # let cat start
active, tid = set(), [200 + int(time.time()) % 1000]
log = []
for cmd in sys.argv[1].split(';'):
    a = cmd.split()
    if not a: continue
    if a[0] == 'wait':
        end = time.perf_counter() + float(a[1])
        while time.perf_counter() < end: pass
        continue
    s = int(a[1]); b = ev(EV_ABS, SLOT, s)
    if a[0] in ('down', 'move'):
        x, y = panel(a[2], a[3])
        if a[0] == 'down': tid[0] += 1; b += ev(EV_ABS, TID, tid[0])
        b += ev(EV_ABS, PX, x) + ev(EV_ABS, PY, y) + ev(EV_ABS, PRESS, 80) + ev(EV_ABS, TOUCHMAJ, 6)
        if a[0] == 'down' and not active: b += ev(EV_KEY, BTN, 1)
        if a[0] == 'down': active.add(s)
    elif a[0] == 'up':
        b += ev(EV_ABS, PRESS, 0) + ev(EV_ABS, TID, -1); active.discard(s)
        if not active: b += ev(EV_KEY, BTN, 0)
    b += ev(EV_SYN, 0, 0)
    p.stdin.write(b); p.stdin.flush(); log.append((a[0], round(time.perf_counter(), 3)))
time.sleep(0.2); p.stdin.close(); p.wait(timeout=5)
if os.environ.get('FASTMT_LOG'): print(log)
