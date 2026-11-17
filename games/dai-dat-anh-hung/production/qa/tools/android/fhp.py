#!/usr/bin/env python3
"""fhp.py mp4 t0 t1 : per-frame: pads visible?, banner cloth top y (column x=300 world), sky day/night; prints changes."""
import sys,subprocess,os
K,OX,OY=1.28055,448.5,74; H=os.path.dirname(os.path.abspath(__file__))
r=[f'{round(OX+1150*K)},{round(OY+440*K)},6,6']+[f'{round(OX+300*K)},{round(OY+y*K)},4,2' for y in range(268,400,2)]+[f'{round(OX+640*K)},{round(OY+190*K)},6,6']
out=subprocess.run([H+'/frames','probe',sys.argv[1],';'.join(r)],capture_output=True,text=True).stdout
t0,t1=float(sys.argv[2]),float(sys.argv[3]); prev=None
for l in out.splitlines():
    p=l.split(); t=int(p[0])/1000; c=[tuple(map(int,x.split(','))) for x in p[1:]]
    pad='pad' if c[0][0]>200 and c[0][1]>200 else 'nopad'
    ys=[268+2*i for i,v in enumerate(c[1:-1]) if v[0]>170 and v[1]<100 and v[2]<100]
    top=ys[0] if ys else None
    sky='night' if c[-1][2]>c[-1][0]+20 and c[-1][0]<120 else 'day'
    s=(pad,top,sky)
    if s!=prev and t0<t<t1: print(f'{t:.3f} {pad} bannertop={top} {sky}')
    prev=s
