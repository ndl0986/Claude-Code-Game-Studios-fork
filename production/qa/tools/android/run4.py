#!/usr/bin/env python3
"""Autoplay for TASK-007 r6 layout (7790ee9): title(started) -> quiz. run4.py <tag> <read|skipwarn|skipnowarn>
Screen = by probes; beat = number of filled HUD dots (5 dots at world x 627+90i, y 61). Saves one shot per new screen."""
import os, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__)); TAG, MODE = sys.argv[1], sys.argv[2]
EV = os.environ['EV']; ADB = os.path.expanduser('~/Android/sdk/platform-tools/adb')
K = min((2400 - 136) / 1280, (1080 - 74 - 84) / 720); OX = 136 + ((2400 - 136) - 1280 * K) / 2; OY = 74
log = open(os.path.join(HERE, TAG + '.log'), 'w', buffering=1); T0 = time.time(); n = [0]
def say(*a): s = f'{time.time() - T0:7.1f}s ' + ' '.join(map(str, a)); print(s, flush=True); log.write(s + '\n')
def wt(script): subprocess.run([sys.executable, '-I', os.path.join(HERE, 'wt.py'), script], check=False)
def tap(x, y, h=0.08): wt(f'down 0 {x} {y}; wait {h}; up 0')
def grab():
    raw = subprocess.run([ADB, 'exec-out', 'screencap'], capture_output=True).stdout
    if len(raw) < 100: return None
    w = int.from_bytes(raw[0:4], 'little'); h = int.from_bytes(raw[4:8], 'little'); hdr = 16 if len(raw) >= 16 + w * h * 4 else 12
    return lambda wx, wy: tuple(raw[hdr + (round(OY + wy * K) * w + round(OX + wx * K)) * 4:][:3])
gold = lambda c: c[0] > 225 and 160 < c[1] < 200 and c[2] < 90
red = lambda c: c[0] > 190 and c[1] < 80 and c[2] < 80
dark = lambda c: c[0] < 80 and c[1] < 80 and c[2] < 110
cream = lambda c: c[0] > 235 and c[1] > 220 and c[2] > 190
def shot(what):
    n[0] += 1; name = f'{TAG}-{n[0]:02d}-{what}.png'
    with open(os.path.join(EV, name), 'wb') as f: f.write(subprocess.run([ADB, 'exec-out', 'screencap', '-p'], capture_output=True).stdout)
    say('shot', name)
def state():
    px = grab()
    if px is None: return 'none', 0
    G = lambda c: c[0] > 200 and 150 < c[1] < 200 and c[2] < 90
    dots = sum(1 for i in range(5) if sum(1 for dx in range(-24, 26, 3) if G(px(627 + 90 * i + dx, 55))) >= 5)
    if gold(px(440, 495)) and not gold(px(1000, 600)) and dark(px(640, 30)) is False and cream(px(840, 470)): return 'skipwarn', dots
    if gold(px(440, 495)) and cream(px(840, 470)): return 'skipwarn', dots
    if dark(px(640, 30)) and cream(px(100, 320)) and cream(px(560, 320)): return 'quiz', dots
    if dark(px(640, 30)) and gold(px(640, 600)) and dark(px(1000, 600)): return 'results', dots
    c = px(1000, 600)
    if red(c): return 'ask', dots
    if gold(c): return 'next', dots
    return 'play', dots
last = None; warned = 0; SKIP = MODE in ('skipwarn', 'skipnowarn')
while time.time() - T0 < 1200:
    s, beat = state()
    if s == 'none': say('no screen'); time.sleep(2); continue
    if (s, beat) != last: say('screen', s, 'dots', beat)
    if s in ('quiz', 'results'): shot(s); say('stop on', s, 'warned', warned); break
    if s == 'skipwarn':
        if last is None or last[0] != 'skipwarn': shot(f'skip-warning-{warned + 1}')
        warned += 1
        if MODE == 'skipwarn' and warned == 1: tap(440, 495); say('-> Keep reading')
        else: tap(840, 495); say('-> Skip anyway')
        time.sleep(1.0); last = (s, beat); continue
    if s in ('next', 'ask'):
        if last != (s, beat): shot(f'{s}-d{beat}')
        if SKIP and s == 'next' or SKIP and s == 'ask': tap(168, 628); say('tap Skip')
        else: tap(1112, 628)
        time.sleep(1.1); last = (s, beat); continue
    last = (s, beat)
    if beat == 2: wt('down 0 330 610; wait 0.5; up 0; down 0 1150 590; wait 3.0; up 0'); continue                        # walk_to + hold
    if beat == 3: wt('down 0 1150 590; wait 0.05; up 0; wait 0.3; down 0 1150 590; wait 0.05; up 0; down 0 330 610; wait 0.25; up 0; '
                     'down 0 1150 590; wait 0.05; up 0; down 0 1150 590; wait 0.05; up 0; '
                     'down 0 1150 400; wait 0.05; up 0; down 0 950 625; wait 1.3; up 0'); continue                              # training
    if beat == 4: wt('down 0 330 610; wait 0.3; down 1 1150 590; wait 0.05; up 1; wait 0.3; down 1 1150 590; wait 0.05; up 1; wait 0.3; up 0'); continue
    wt('down 0 330 610; wait 1.5; up 0')
say('end')
