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
def write(stem,title,root,caps,outdir,skipfill=False):
    n,b,dd,ol=counts(root); stage=b+dd+ol; parade=b+ol
    parts_nonroot=n
    svg=['<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="640" height="440" viewBox="0 0 640 440">',f'  <title>{title}</title>']+emit(root)+['</svg>','']
    open(os.path.join(outdir,'src/art',f'cast_{stem}.svg'),'w').write('\n'.join(svg))
    sil=unary_union([g for p in allparts(root) for _,gs in p.body for g in gs]).buffer(3,RES,join_style=1)
    open(os.path.join(outdir,'src/sil',f'sil_{stem}.svg'),'w').write('\n'.join(['<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="640" height="440" viewBox="0 0 640 440">',f'  <title>{title} silhouette (rest pose)</title>',f'  <path fill="#000000" d="{pathd(sil)}"/>','</svg>','']))
    minx,miny,maxx,maxy=sil.bounds
    ok=stage<=caps[0] and parade<=caps[1] and (caps[2] is None or n<=caps[2])
    fill_ok=skipfill or (maxy-miny)>=264 or (maxx-minx)>=384
    inside=minx>=0 and miny>=0 and maxx<=640 and maxy<=440
    print(f'{stem}: parts {n}, body {b}, detail {dd}, outline {ol} -> stage {stage}, parade {parade} {"OK" if ok else "OVER"}; box {minx:.0f}-{maxx:.0f} x {miny:.0f}-{maxy:.0f} fill {"OK" if fill_ok else "LOW"} {"inside" if inside else "OUTSIDE"}')
    return ok and fill_ok and inside
