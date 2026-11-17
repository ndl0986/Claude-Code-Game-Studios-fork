#!/usr/bin/env python3
"""boxes.py <mp4> : probe panel text strips per frame, print times where the signature changes a lot."""
import subprocess, sys
K,OX,OY=1.28055,448.5,74
def r(wx,wy,ww,wh): return f"{round(OX+wx*K)},{round(OY+wy*K)},{round(ww*K)},{round(wh*K)}"
rects=[r(150,y,980,5) for y in range(int(sys.argv[3]) if len(sys.argv)>3 else 300, int(sys.argv[4]) if len(sys.argv)>4 else 640, 6)]+[r(0,100,1280,200)]
out=subprocess.run([sys.argv[1+0] if False else sys.argv[0].replace('boxes.py','frames'),'probe',sys.argv[1],';'.join(rects)],capture_output=True,text=True).stdout
prev=None; last_t=None; thr=float(sys.argv[2]) if len(sys.argv)>2 else 6
for line in out.splitlines():
    p=line.replace(',',' ').split()
    try: t=int(p[0])/1000; v=[float(x) for x in p[1:]]
    except: continue
    if prev is not None:
        d=max(abs(a-b) for a,b in zip(v,prev))
        if d>thr: print(f"{t:7.3f}s change {d:5.1f}" + (f"  (+{t-last_t:.3f} since last)" if last_t else '')); last_t=t
    prev=v
