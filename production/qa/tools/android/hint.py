"""hint.py png... : pads (cream #F2E6D0 / gold #F2B632 components, >1500 px) and the hint glove (#FFFFFF component + 6 px for its outline), world coords; checks overlap and y >= 276."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pngpx import load
K,OX,OY=1.28055,448.5,74; S=2
def comps(mask,W,H):
    seen=set(); out=[]
    for (x,y) in mask:
        if (x,y) in seen: continue
        st=[(x,y)]; seen.add((x,y)); pts=[]
        while st:
            p=st.pop(); pts.append(p)
            for d in ((S,0),(-S,0),(0,S),(0,-S)):
                q=(p[0]+d[0],p[1]+d[1])
                if q in mask and q not in seen: seen.add(q); st.append(q)
        out.append(pts)
    return out
wx=lambda v:(v-OX)/K; wy=lambda v:(v-OY)/K
for f in sys.argv[1:]:
    w,h,b,rows=load(f); P=lambda x,y: tuple(rows[y][x*b:x*b+3])
    near=lambda c,t,tol: all(abs(c[i]-t[i])<=tol for i in range(3))
    x0,x1,y0,y1=round(OX+700*K),round(OX+1280*K),round(OY+250*K),round(OY+720*K)
    pad=set(); wh=set()
    for y in range(y0,y1,S):
        for x in range(x0,x1,S):
            c=P(x,y)
            if near(c,(0xF2,0xE6,0xD0),6) or near(c,(0xF2,0xB6,0x32),8) or near(c,(0xEE,0xEA,0xD2),5) or near(c,(0xF0,0xEA,0xD8),5): pad.add((x,y))
            if c[0]>248 and c[1]>248 and c[2]>248: wh.add((x,y))
    pads=[p for p in comps(pad,w,h) if len(p)>1500//(S*S)]
    gl=[p for p in comps(wh,w,h) if len(p)>60//(S*S)]
    bb=lambda pts:(min(p[0] for p in pts),max(p[0] for p in pts),min(p[1] for p in pts),max(p[1] for p in pts))
    PB=[bb(p) for p in pads]; GB=[bb(g) for g in gl]
    print(os.path.basename(f), 'pads(world):', ['x%.0f-%.0f y%.0f-%.0f'%(wx(a),wx(z),wy(c),wy(d)) for a,z,c,d in PB])
    for a,z,c,d in GB:
        a,z,c,d=a-6,z+6,c-6,d+6   # outline
        hit=[i for i,(pa,pz,pc,pd) in enumerate(PB) if a<=pz and z>=pa and c<=pd and d>=pc]
        print('   white blob x%.1f-%.1f y%.1f-%.1f'%(wx(a),wx(z),wy(c),wy(d)), 'overlaps pad#', hit, 'top>=276:', wy(c)>=276)
