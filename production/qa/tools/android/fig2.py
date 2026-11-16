"""fig2.py frame.png : hero/partner height (hair top to shoe bottom, device px) and the hero-partner gap, in fixed device windows."""
import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pngpx import load
K,OX,OY=1.28055,448.5,74
w,h,b,rows=load(sys.argv[1]); HX=tuple(map(int,sys.argv[2].split('-'))) if len(sys.argv)>2 else (1752,1900); PX=tuple(map(int,sys.argv[3].split('-'))) if len(sys.argv)>3 else (1880,2060)
def P(x,y): r=rows[y]; return r[x*b],r[x*b+1],r[x*b+2]
dark=lambda c: c[0]<85 and c[1]<70 and c[2]<60
skin=lambda c: abs(c[0]-241)<22 and abs(c[1]-201)<22 and abs(c[2]-160)<24
red=lambda c: 195<c[0]<245 and 35<c[1]<95 and 25<c[2]<75
blue=lambda c: c[2]>120 and c[0]<90 and c[1]<130
beige=lambda c: abs(c[0]-216)<12 and abs(c[1]-201)<12 and abs(c[2]-163)<12
sash=lambda c: abs(c[0]-185)<14 and abs(c[1]-112)<14 and abs(c[2]-92)<14
def ext(xr,test):
    pts=[(x,y) for y in range(420,700) for x in range(*xr) if test(P(x,y))]
    return (min(p[0] for p in pts),max(p[0] for p in pts),min(p[1] for p in pts),max(p[1] for p in pts),len(pts)) if pts else None
wx=lambda v: round((v-OX)/K,1)
hh=ext(HX,dark); ph=ext(PX,dark)
hb=ext(HX,lambda c: red(c) or skin(c) or blue(c) or dark(c)); pb=ext(PX,lambda c: beige(c) or skin(c) or blue(c) or dark(c) or sash(c))
print('hero dark (hair..shoes) x %d-%d y %d-%d'%hh[:4], 'height', hh[3]-hh[2]+1)
print('partner dark x %d-%d y %d-%d'%ph[:4], 'height', ph[3]-ph[2]+1, 'ratio %.3f'%((ph[3]-ph[2]+1)/(hh[3]-hh[2]+1)))
print('hero body x %d-%d (world %s-%s)'%(hb[0],hb[1],wx(hb[0]),wx(hb[1])), '| partner body x %d-%d (world %s-%s)'%(pb[0],pb[1],wx(pb[0]),wx(pb[1])), '| gap world', round((pb[0]-hb[1])/K,1))
print('partner beige', ext(PX,beige)[:4], 'sash', ext(PX,sash)[:4] if ext(PX,sash) else None, 'red in partner window', ext(PX,red))
