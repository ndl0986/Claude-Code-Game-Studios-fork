#!/usr/bin/env python3
"""quiz3.py <tag> '<plan>' : r6 quiz layout. plan = per question, comma-separated slot order, ';' between questions,
e.g. '0,2;0,1;2;0;0'. Taps slots in order until the right card (green), then Tiếp. Logs wrong/right per tap."""
import os, subprocess, sys, time
HERE = os.path.dirname(os.path.abspath(__file__)); TAG, PLAN = sys.argv[1], sys.argv[2]
exec(open(os.path.join(HERE, 'run4.py')).read().split('last = None')[0].replace("TAG, MODE = sys.argv[1], sys.argv[2]", "TAG, MODE = sys.argv[1], 'q'").replace("TAG + '.log'), 'w'", "TAG + '.log'), 'a'"))
SX = [231, 642, 1050]
green = lambda c: c[1] > c[0] + 10 and c[1] > c[2] + 10
lav = lambda c: c[2] > c[0] + 5 and c[2] > c[1] + 8 and not dark(c)
R = 0
for qi, q in enumerate(PLAN.split(';')):
    for s in map(int, q.split(',')):
        tap(SX[s], 420); time.sleep(1.0); px = grab(); c = px(SX[s] - 150, 345)
        if green(c): say(f'Q{qi+1} slot{s} RIGHT'); break
        if lav(c): R += 1; say(f'Q{qi+1} slot{s} WRONG'); time.sleep(0.4); continue
        say(f'Q{qi+1} slot{s} ?? {c}')
    time.sleep(1.2); tap(1097, 640); time.sleep(1.4)
say('total retries', R)
