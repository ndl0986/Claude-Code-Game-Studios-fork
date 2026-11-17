#!/usr/bin/env python3
"""tl.py DUR : timeline -> fastmt script. Slot 0: tap TX,TY every IV (0.06 down) from T0. Slot 1: pad PX,PY held PH of every PP s.
env: TX TY IV T0 PX PY PH PP START(1=tap Start first)"""
import os, sys
E=os.environ.get; dur=float(sys.argv[1]); ev=[]
TX,TY,IV,T0=E('TX','1112'),E('TY','628'),float(E('IV','0.35')),float(E('T0','0.35'))
if E('START','0')=='1': ev+=[(0,'down 0 640 449'),(0.06,'up 0')]
t=T0
while t<dur: ev+=[(t,f'down 0 {TX} {TY}'),(t+0.06,'up 0')]; t+=IV
if E('PX'):
    PH,PP=float(E('PH','2.8')),float(E('PP','3.0')); t=float(E('PT0','0.5'))
    while t<dur: ev+=[(t+0.02,f'down 1 {E("PX")} {E("PY")}'),(t+0.02+PH,'up 1')]; t+=PP
ev.sort(key=lambda e:e[0]); out=[]; now=0
for t,c in ev:
    if t>now: out.append(f'wait {t-now:.4f}'); now=t
    out.append(c)
print('; '.join(out))
