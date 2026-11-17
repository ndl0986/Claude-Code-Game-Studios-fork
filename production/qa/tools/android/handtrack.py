"""handtrack.py dir : per frame, pause dim, hint hand x (white at world y 400) and the Cờ pad's width on that row."""
import sys,glob,os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from pngpx import load
K,OX,OY=1.28055,448.5,74
y=round(OY+400*K)
for f in sorted(glob.glob(os.path.join(sys.argv[1],'*.png'))):
    t=int(f[-10:-4])/1000
    w,h,b,rows=load(f); r=rows[y]; P=lambda x: (r[x*b],r[x*b+1],r[x*b+2])
    white=[x for x in range(round(OX+900*K),round(OX+1080*K)) if all(c>235 for c in P(x))]
    pad=[x for x in range(round(OX+1040*K),round(OX+1280*K)) if abs(P(x)[0]-0xF2)<10 and abs(P(x)[1]-0xE6)<10 and abs(P(x)[2]-0xD0)<12]
    dim=P(round(OX+640*K))[0]<120
    print(f'{t:.3f}', 'DIM' if dim else 'lit', 'hand x %.1f-%.1f'%((min(white)-OX)/K,(max(white)-OX)/K) if white else 'hand -', 'pad w %.1f'%((max(pad)-min(pad))/K) if pad else 'pad -')
