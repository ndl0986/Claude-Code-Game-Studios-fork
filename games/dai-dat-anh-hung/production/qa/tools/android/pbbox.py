#!/usr/bin/env python3
"""pbbox.py file.png x0 y0 x1 y1 RRGGBB tol : world bbox of a colour in a saved screenshot."""
import sys,os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__))); from pngpx import load
w,h,bpp,rows=load(sys.argv[1]); K=1.28055;OX=448.5;OY=74
x0,y0,x1,y1=map(float,sys.argv[2:6]); col=tuple(int(sys.argv[6][i:i+2],16) for i in (0,2,4)); tol=int(sys.argv[7])
xs=[];ys=[]
for y in range(round(OY+y0*K),round(OY+y1*K)+1):
    r=rows[y]
    for x in range(round(OX+x0*K),round(OX+x1*K)+1):
        p=r[x*bpp:x*bpp+3]
        if max(abs(p[i]-col[i]) for i in range(3))<=tol: xs.append(x);ys.append(y)
print(f"x {(min(xs)-OX)/K:.1f}-{(max(xs)-OX)/K:.1f}  y {(min(ys)-OY)/K:.1f}-{(max(ys)-OY)/K:.1f} n={len(xs)}" if xs else 'none')
