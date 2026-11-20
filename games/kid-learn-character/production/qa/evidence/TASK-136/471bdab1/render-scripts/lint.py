"""Local lint of ADR-0003 D4 (subset + structure) and the silhouette path rules, until the bake tool exists."""
import sys, re, xml.etree.ElementTree as ET
NS='{http://www.w3.org/2000/svg}'
EL={'svg','g','path','circle','ellipse','rect','line','polyline','polygon','title','desc','metadata'}
AT={'d','cx','cy','r','rx','ry','x','y','width','height','x1','y1','x2','y2','points','fill','fill-opacity','stroke','stroke-width','stroke-linejoin','stroke-linecap','opacity','transform','id','data-pivot','xmlns','version','viewBox'}
COL=re.compile(r'^(#[0-9a-fA-F]{3}|#[0-9a-fA-F]{6}|none)$'); PART=re.compile(r'^[a-z]+(_[a-z]+)*$')
bad=0
def err(f,m):
    global bad; bad+=1; print(f'FAIL {f}: {m}')
for f in sys.argv[1:]:
    t=ET.parse(f); root=t.getroot(); ids=set()
    for e in root.iter():
        tag=e.tag.replace(NS,'')
        if tag not in EL: err(f,f'element {tag}')
        for a,v in e.attrib.items():
            if a not in AT: err(f,f'attribute {a} on {tag}')
            if a in('fill','stroke') and not COL.match(v): err(f,f'colour {v}')
            if a in('stroke-linejoin','stroke-linecap') and v!='round': err(f,f'{a}={v}')
            if a=='transform' and re.search(r'skew|matrix',v): err(f,f'transform {v}')
        if 'id' in e.attrib:
            i=e.attrib['id']
            if i in ids: err(f,f'duplicate id {i}')
            ids.add(i)
    name=f.split('/')[-1]
    if name.startswith('cast_'):
        top=[c for c in root if c.tag==NS+'g']
        if len(top)!=1 or top[0].get('id')!='root': err(f,'one top-level part "root" expected')
        def part(g):
            pid=g.get('id')
            if not PART.match(pid) or any(s in('body','outline','detail') for s in pid.split('_')): err(f,f'part name {pid}')
            if not g.get('data-pivot'): err(f,f'part {pid} without data-pivot')
            kids=[c for c in g if c.tag==NS+'g']; layers=[c.get('id') for c in kids if c.get('id','').rsplit('_',1)[-1] in('body','outline','detail') and c.get('id').rsplit('_',1)[0]==pid]
            if layers!=[pid+'_body',pid+'_outline',pid+'_detail']: err(f,f'part {pid} layers {layers}')
            for c in kids:
                cid=c.get('id')
                if cid in layers: continue
                part(c)
            ol=[c for c in kids if c.get('id')==pid+'_outline'][0]
            if ol.get('opacity')!='0.8': err(f,f'{pid}_outline opacity')
            for p in ol:
                if p.get('stroke')!='#2a2340' or p.get('stroke-width')!='6' or p.get('fill')!='none': err(f,f'{pid} outline stroke')
            return 1
        part(top[0])
    else:
        paths=[e for e in root.iter() if e.tag==NS+'path']
        if len(paths)!=1: err(f,f'{len(paths)} paths (one compound path expected)')
        for p in paths:
            d=p.get('d'); 
            if p.get('stroke'): err(f,'silhouette has a stroke')
            cmds=set(re.findall(r'[A-Za-z]',d))
            if not cmds<= {'M','L','Z'}: err(f,f'commands {cmds}')
            if re.search(r'Z(?!M|$)',d): err(f,'no M after a Z')
            if re.search(r'[eE][-+]?\d',d): err(f,'exponent in a number')
print('lint:',len(sys.argv)-1,'files,',bad,'problem(s):','PASS' if bad==0 else 'FAIL')
