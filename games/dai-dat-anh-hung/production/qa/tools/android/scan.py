#!/usr/bin/env python3
"""scan.py col|row WX|WY A B  -> runs of similar colour along a world column/row on the live screen (device-px resolution, reported in world px)."""
import subprocess, sys, os
ADB=os.path.expanduser('~/Android/sdk/platform-tools/adb')
raw=subprocess.run([ADB,'exec-out','screencap'],capture_output=True).stdout
w,h=int.from_bytes(raw[0:4],'little'),int.from_bytes(raw[4:8],'little'); hdr=16 if len(raw)>=16+w*h*4 else 12
K=1.28055; OX=448.5; OY=74
mode,c,a,b=sys.argv[1],float(sys.argv[2]),float(sys.argv[3]),float(sys.argv[4])
def px(x,y): o=hdr+(y*w+x)*4; return tuple(raw[o:o+3])
if mode=='col': X=round(OX+c*K); pts=[(X,y) for y in range(round(OY+a*K),round(OY+b*K)+1)]
else: Y=round(OY+c*K); pts=[(x,Y) for x in range(round(OX+a*K),round(OX+b*K)+1)]
runs=[]; 
for (x,y) in pts:
    p=px(x,y); v=(y-OY)/K if mode=='col' else (x-OX)/K
    if runs and max(abs(p[i]-runs[-1][2][i]) for i in range(3))<=int(os.environ.get('TOL','24')): runs[-1][1]=v
    else: runs.append([v,v,p])
for s,e,p in runs:
    if e-s>=float(os.environ.get('MIN','2')): print(f"{s:7.1f}-{e:7.1f}  #{p[0]:02X}{p[1]:02X}{p[2]:02X}")
