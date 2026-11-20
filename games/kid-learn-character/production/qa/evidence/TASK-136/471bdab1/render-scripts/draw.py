"""TASK-136 batch 1: layered cast SVGs + silhouettes for T D R P A 9 (art spec: design/assets/specs/dinosaurs-assets.md).
Shapes are primitives; same-colour body shapes in a part are unioned into one path; each part's outline is the
boundary of the union of its body shapes; the silhouette is the union of all body shapes buffered by 3 (the outer
half of the 6-unit round-joined outline), so the bake's raster check holds by construction."""
import sys, os, math
from shapely.geometry import Point, Polygon, MultiPolygon
from shapely.geometry.polygon import orient
from shapely.ops import unary_union
from shapely import affinity
INK='#2a2340'; CREAM='#f8efdc'; BONE='#f3e6c8'; ROSE='#e8a6b8'
RES=24
def ell(cx,cy,rx,ry,rot=0): return affinity.rotate(affinity.scale(Point(0,0).buffer(1,RES),rx,ry),rot,origin=(0,0)).__class__ and affinity.translate(affinity.rotate(affinity.scale(Point(0,0).buffer(1,RES),rx,ry),rot,origin=(0,0)),cx,cy)
def circ(cx,cy,r): return Point(cx,cy).buffer(r,RES)
def rrect(x,y,w,h,r):
    r=min(r,w/2,h/2); return Polygon([(x+r,y+r),(x+w-r,y+r),(x+w-r,y+h-r),(x+r,y+h-r)]).buffer(r,RES)
def rpoly(pts,r): return Polygon(pts).buffer(-r,RES).buffer(r,RES)
def tf(g,s,dx,dy): return affinity.translate(affinity.scale(g,s,s,origin=(0,0)),dx,dy)
def fmt(v): return ('%.1f'%v).rstrip('0').rstrip('.') if abs(v-round(v))>1e-9 else str(int(round(v)))
def ring(coords):
    pts=[]; 
    for x,y in coords[:-1]:
        p=(round(x,1),round(y,1))
        if not pts or p!=pts[-1]: pts.append(p)
    if len(pts)>1 and pts[0]==pts[-1]: pts.pop()
    return 'M'+fmt(pts[0][0])+' '+fmt(pts[0][1])+''.join('L'+fmt(x)+' '+fmt(y) for x,y in pts[1:])+'Z'
def pathd(g):
    polys=[g] if isinstance(g,Polygon) else list(g.geoms)
    d=''
    for p in polys:
        p=orient(p,1.0); d+=ring(list(p.exterior.coords))
        for it in p.interiors: d+=ring(list(it.coords))
    return d
class Part:
    def __init__(s,name,pivot,body=(),detail=(),back=(),front=()):
        s.name=name; s.pivot=pivot; s.body=list(body); s.detail=list(detail); s.back=list(back); s.front=list(front)
def bodyunion(p): return unary_union([g for _,gs in p.body for g in gs]) if p.body else None
def allparts(p):
    yield p
    for c in p.back+p.front: yield from allparts(c)
def emit(p,ind='  '):
    o=[]; a=f'{ind}<g id="{p.name}" data-pivot="{fmt(p.pivot[0])} {fmt(p.pivot[1])}">'; o.append(a)
    for c in p.back: o+=emit(c,ind+'  ')
    o.append(f'{ind}  <g id="{p.name}_body">')
    for col,gs in p.body: o.append(f'{ind}    <path fill="{col}" d="{pathd(unary_union(gs))}"/>')
    o.append(f'{ind}  </g>')
    o.append(f'{ind}  <g id="{p.name}_outline" opacity="0.8">')
    u=bodyunion(p)
    if u is not None: o.append(f'{ind}    <path fill="none" stroke="{INK}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round" d="{pathd(u)}"/>')
    o.append(f'{ind}  </g>')
    o.append(f'{ind}  <g id="{p.name}_detail">')
    for it in p.detail:
        if it[0]=='fill':
            _,col,gs,*op=it; extra=f' fill-opacity="{op[0]}"' if op else ''
            o.append(f'{ind}    <path fill="{col}"{extra} d="{pathd(unary_union(gs))}"/>')
        else:
            _,d,w=it; o.append(f'{ind}    <path fill="none" stroke="{INK}" stroke-width="{fmt(w)}" stroke-linecap="round" stroke-linejoin="round" d="{d}"/>')
    o.append(f'{ind}  </g>')
    for c in p.front: o+=emit(c,ind+'  ')
    o.append(f'{ind}</g>'); return o
def counts(root):
    parts=[p for p in allparts(root)]
    body=sum(len(p.body) for p in parts); det=sum(len(p.detail) for p in parts)
    outl=sum(1 for p in parts if p.body)
    return len(parts),body,det,outl
def smile(x0,y0,cx,cy,x1,y1): return f'M{fmt(x0)} {fmt(y0)}Q{fmt(cx)} {fmt(cy)} {fmt(x1)} {fmt(y1)}'
def write(stem,title,root,caps,outdir):
    n,b,dd,ol=counts(root); stage=b+dd+ol; parade=b+ol
    parts_nonroot=n
    svg=['<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="640" height="440" viewBox="0 0 640 440">',f'  <title>{title}</title>']+emit(root)+['</svg>','']
    open(os.path.join(outdir,'src/art',f'cast_{stem}.svg'),'w').write('\n'.join(svg))
    sil=unary_union([g for p in allparts(root) for _,gs in p.body for g in gs]).buffer(3,RES,join_style=1)
    open(os.path.join(outdir,'src/sil',f'sil_{stem}.svg'),'w').write('\n'.join(['<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="640" height="440" viewBox="0 0 640 440">',f'  <title>{title} silhouette (rest pose)</title>',f'  <path fill="#000000" d="{pathd(sil)}"/>','</svg>','']))
    minx,miny,maxx,maxy=sil.bounds
    ok=stage<=caps[0] and parade<=caps[1] and (caps[2] is None or n<=caps[2])
    fill_ok=(maxy-miny)>=264 or (maxx-minx)>=384
    inside=minx>=0 and miny>=0 and maxx<=640 and maxy<=440
    print(f'{stem}: parts {n}, body {b}, detail {dd}, outline {ol} -> stage {stage}, parade {parade} {"OK" if ok else "OVER"}; box {minx:.0f}-{maxx:.0f} x {miny:.0f}-{maxy:.0f} fill {"OK" if fill_ok else "LOW"} {"inside" if inside else "OUTSIDE"}')
    return ok and fill_ok and inside
# ---------------- figures ----------------
def trex():
    B,F,BL,RD='#9a6fd1','#7f48c5','#c9afd6','#c39af0'
    # jaw: an ellipse with a circle carved out of its top, so the visible jaw line is a U-shaped smile
    jawshape=ell(470,200,56,18).difference(circ(472,150,42))
    jaw=Part('jaw',(398,182),body=[(B,[jawshape])],detail=[('fill',BONE,[circ(461,195.5,3),circ(472,196.5,3),circ(483,195.5,3)])])
    head=Part('head',(380,176),body=[(B,[ell(448,165,74,50,-6)]),(CREAM,[circ(468,146,15)]),(INK,[circ(474,148,8)])],
              detail=[('fill',CREAM,[circ(477,144,3.5)]),('fill',ROSE,[ell(496,172,11,7)],0.7)],front=[jaw])
    neck=Part('neck',(360,250),body=[(B,[ell(386,214,44,62,25)])],front=[head])
    tail=Part('tail',(196,270),body=[(B,[ell(158,292,125,30,8)])])
    root=Part('root',(320,410),back=[tail,neck],
      body=[(F,[rrect(262,320,46,90,22)]),(B,[ell(305,282,108,82,-8),rrect(318,318,56,92,26),ell(398,304,18,9,35)]),(BL,[ell(335,305,58,46,-10)]),(BONE,[ell(366,403,16,7)])],
      detail=[('fill',RD,[circ(270,222,9),circ(300,214,9),circ(330,218,9)])])
    return root
def diplo():
    B,F,BL,SP='#5fb3a8','#48978d','#acd1c2','#3f8a82'
    head=Part('head',(540,205),body=[(B,[ell(560,198,38,26,-5)]),(CREAM,[circ(568,188,10)]),(INK,[circ(572,189,5.5)])],
              detail=[('fill',CREAM,[circ(574,186,2.5)]),('fill',ROSE,[ell(583,207,8,5)],0.7),('stroke',smile(571,210,584,215,595,206),4)])
    neck=Part('neck',(400,262),body=[(B,[ell(458,240,95,24,-20)])],front=[head])
    tail=Part('tail',(182,316),body=[(B,[ell(140,326,125,22,10)])])
    root=Part('root',(320,410),back=[tail,neck],
      body=[(F,[rrect(230,330,40,80,18),rrect(350,330,40,80,18)]),(B,[ell(300,300,115,62),rrect(252,330,44,80,20),rrect(372,330,44,80,20)]),(BL,[ell(305,328,72,28)]),(BONE,[ell(292,404,12,6),ell(412,404,12,6)])],
      detail=[('fill',SP,[circ(258,278,10),circ(300,266,10),circ(342,276,10)])])
    return root
def raptor():
    B,F,BL,ST='#68b761','#519a4b','#b4d6a8','#5a9256'
    head=Part('head',(408,214),body=[(B,[ell(432,205,52,30,-8),ell(434,183,22,9,-10)]),(CREAM,[circ(442,196,11)]),(INK,[circ(446,197,6)])],
              detail=[('fill',CREAM,[circ(448,194,2.8)]),('fill',ROSE,[ell(463,215,9,6)],0.7),('stroke',smile(452,222,466,228,479,219),4)])
    tail=Part('tail',(210,300),body=[(B,[ell(150,282,108,22,-10)])])
    root=Part('root',(320,410),back=[tail],front=[head],
      body=[(F,[rrect(268,320,34,90,16)]),(B,[ell(300,280,80,52,-15),ell(378,240,28,42,30),rrect(300,318,40,92,18),ell(374,284,16,7,40)]),(BL,[ell(318,296,44,28,-15)]),(BONE,[ell(338,404,12,6)])],
      detail=[('fill',ST,[ell(266,252,6,15,-15),ell(291,244,6,15,-15),ell(316,240,6,15,-15)])])
    return root
def tapejara():
    B,WG,WF,CR='#5fb6b0','#9fd9cf','#7fbfb4','#e8704f'
    # far wing raised up and back (behind the body); near wing swept back, level; head, crest and beak clear in front
    wf=Part('wing_far',(300,250),body=[(WF,[ell(276,182,95,26,55)])])
    wn=Part('wing_near',(330,255),body=[(WG,[ell(208,278,118,25,-5)])],
            detail=[('fill','#7fbfb4',[ell(200,272,70,3.5,-5),ell(190,284,55,3.5,-3)])])
    root=Part('root',(320,410),back=[wf],front=[wn],
      body=[(CR,[ell(430,182,30,34,-20)]),(B,[ell(330,268,72,32,-8),ell(396,246,28,14,-30),ell(455,222,38,25,-10),ell(508,234,40,9,16),ell(288,293,18,8,20)]),(CREAM,[circ(462,214,9)]),(INK,[circ(465,215,5)])],
      detail=[('fill',CREAM,[circ(467,213,2.2)]),('fill',ROSE,[ell(476,230,7,4)],0.7),('stroke',smile(470,236,482,240,494,233),4)])
    return root
def ankylo():
    B,F,BL,CL,STD='#5f8fd6','#4475c5','#afbfd9','#3f68a8','#a9c6f2'
    head=Part('head',(470,300),body=[(B,[ell(455,322,40,30,5)]),(CREAM,[circ(466,312,10)]),(INK,[circ(470,313,5.5)])],
              detail=[('fill',CREAM,[circ(472,310,2.5)]),('fill',ROSE,[ell(483,333,8,5)],0.7),('stroke',smile(470,342,482,347,493,340),4)])
    tail=Part('tail',(170,330),body=[(B,[ell(135,336,85,18,8)]),(CL,[ell(56,346,28,20)])])
    root=Part('root',(320,410),back=[tail],front=[head],
      body=[(F,[rrect(215,345,40,65,18),rrect(355,345,40,65,18)]),(B,[ell(300,320,125,58),rrect(237,345,44,65,20),rrect(377,345,44,65,20),circ(220,274,14),circ(260,264,14),circ(300,260,14),circ(340,264,14),circ(380,274,14)]),(BL,[ell(300,350,85,20)]),(BONE,[ell(277,404,12,6),ell(417,404,12,6)])],
      detail=[('fill',STD,[circ(250,300,7),circ(300,294,7),circ(350,300,7)])])
    return root
def babies(n):
    cols=['#7fcf8f','#f2a37a','#8fb4ea','#d8b87a','#c39af0','#f29ab0','#6fc9c0','#e48a5a','#a5d46a']
    front=min(n,5); back=n-front; slots=[]
    for j in range(back): slots.append((320+104*(j-(back-1)/2),292,0.95,cols[(j+5)%9]))
    for i in range(front): slots.append((320+104*(i-(front-1)/2),410,1.05,cols[i%9]))
    kids=[]
    for k,(fx,fy,s,col) in enumerate(slots):
        T=lambda g: tf(g,s,fx,fy)
        body=[T(ell(0,-30,36,30)),T(circ(10,-62,28)),T(ell(-36,-22,12,7,-20)),T(ell(-14,-6,12,6)),T(ell(16,-6,12,6))]
        WORD=['one','two','three','four','five','six','seven','eight','nine']   # part names allow no digits (ADR-0003 D4)
        p=Part(f'baby_{WORD[k]}',(fx,fy),body=[(col,body),(CREAM,[T(circ(20,-66,9))]),(INK,[T(circ(23,-65,5))])],
               detail=[('fill',CREAM,[T(circ(25,-68,2))]),('stroke',smile(fx+22*s,fy-50*s,fx+30*s,fy-45*s,fx+37*s,fy-52*s),3.5*s)])
        kids.append(p)
    return Part('root',(320,410),front=kids)
out=sys.argv[1]
os.makedirs(os.path.join(out,'src/art'),exist_ok=True); os.makedirs(os.path.join(out,'src/sil'),exist_ok=True)
ok=True
ok&=write('dino_t_trex_01','Letterlings Dinosaurs: T-Rex (TASK-136)',trex(),(23,15,5),out)
ok&=write('dino_d_diplodocus_01','Letterlings Dinosaurs: Diplodocus (TASK-136)',diplo(),(23,15,5),out)
ok&=write('dino_r_raptor_01','Letterlings Dinosaurs: Raptor (TASK-136)',raptor(),(23,15,5),out)
ok&=write('dino_p_tapejara_01','Letterlings Dinosaurs: Tapejara (TASK-136)',tapejara(),(23,15,5),out)
ok&=write('dino_a_ankylosaurus_01','Letterlings Dinosaurs: Ankylosaurus (TASK-136)',ankylo(),(23,15,5),out)
ok&=write('dino_9_babies_01','Letterlings Dinosaurs: nine baby dinosaurs (TASK-136; render budget pending, spec R-3)',babies(9),(54,36,None),out)
print('ALL OK' if ok else 'PROBLEM')
