#!/usr/bin/env python3
"""fhp2.py mp4 : banner top (x=300), sky state day/dim/night at (640,190), pause overlay; prints changes."""
import sys,subprocess,os
K,OX,OY=1.28055,448.5,74; H=os.path.dirname(os.path.abspath(__file__))
r=[f'{round(OX+300*K)},{round(OY+y*K)},4,2' for y in range(268,400,2)]+[f'{round(OX+640*K)},{round(OY+190*K)},6,6']
out=subprocess.run([H+'/frames','probe',sys.argv[1],';'.join(r)],capture_output=True,text=True).stdout
prev=None
for l in out.splitlines():
    p=l.split(); t=int(p[0])/1000; c=[tuple(map(int,x.split(','))) for x in p[1:]]
    ys=[268+2*i for i,v in enumerate(c[:-1]) if v[0]>120 and v[1]<90 and v[2]<90 and v[0]>v[1]+60]
    top=ys[0] if ys else None; s=c[-1]
    sky='night' if s[2]>s[0]+20 and s[0]<120 and s[2]>80 else ('day' if s[0]>150 else 'dim')
    st=(top if top is None else top//4*4,sky)
    if st!=prev: print(f'{t:.3f} top={top} {sky} {s}')
    prev=st
