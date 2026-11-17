#!/usr/bin/env python3
"""boxes2.py <mp4> t0 t1 y0 y1 [x0 x1]: per-frame signature of thin strips (world coords); prints the 12 largest frame-to-frame diffs, sorted by time."""
import subprocess, sys, os
K,OX,OY=1.28055,448.5,74
t0,t1,y0,y1=map(float,sys.argv[2:6]); x0,x1=(float(sys.argv[6]),float(sys.argv[7])) if len(sys.argv)>7 else (150,1130)
rects=[]
for y in range(int(y0),int(y1),4):
    for x in range(int(x0),int(x1),70): rects.append(f"{round(OX+x*K)},{round(OY+y*K)},{round(70*K)},{round(3*K)}")
out=subprocess.run([os.path.join(os.path.dirname(os.path.abspath(__file__)),'frames'),'probe',sys.argv[1],';'.join(rects)],capture_output=True,text=True).stdout
prev=None; ds=[]
for line in out.splitlines():
    p=line.replace(',',' ').split(); t=int(p[0])/1000; v=[float(x) for x in p[1:]]
    if prev and t0<=t<=t1: ds.append((sum(abs(a-b) for a,b in zip(v,prev)),t))
    prev=v
n=int(os.environ.get('N','12'))
for d,t in sorted(sorted(ds)[-n:],key=lambda x:x[1]): print(f"{t:7.3f}s diff {d:7.0f}")
