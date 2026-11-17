#!/usr/bin/env python3
"""bbox.py x0 y0 x1 y1 RRGGBB[,RRGGBB] [tol] -> world bbox of pixels near any colour within the world rect (live screen)."""
import subprocess, sys, os
ADB=os.path.expanduser('~/Android/sdk/platform-tools/adb')
raw=subprocess.run([ADB,'exec-out','screencap'],capture_output=True).stdout
w,h=int.from_bytes(raw[0:4],'little'),int.from_bytes(raw[4:8],'little'); hdr=16 if len(raw)>=16+w*h*4 else 12
K=1.28055; OX=448.5; OY=74
x0,y0,x1,y1=map(float,sys.argv[1:5]); cols=[tuple(int(c[i:i+2],16) for i in (0,2,4)) for c in sys.argv[5].split(',')]; tol=int(sys.argv[6]) if len(sys.argv)>6 else 20
for col in cols:
    xs=[];ys=[]
    for y in range(round(OY+y0*K),round(OY+y1*K)+1):
        for x in range(round(OX+x0*K),round(OX+x1*K)+1):
            o=hdr+(y*w+x)*4; p=raw[o:o+3]
            if max(abs(p[i]-col[i]) for i in range(3))<=tol: xs.append(x); ys.append(y)
    if xs: print('#%02X%02X%02X'%col, f"x {(min(xs)-OX)/K:.1f}-{(max(xs)-OX)/K:.1f}  y {(min(ys)-OY)/K:.1f}-{(max(ys)-OY)/K:.1f}  n={len(xs)}")
    else: print('#%02X%02X%02X'%col,'none')
