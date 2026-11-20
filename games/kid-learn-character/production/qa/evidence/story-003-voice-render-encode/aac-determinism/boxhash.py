import sys,hashlib
def boxes(b,lo,hi):
    o=lo
    while o+8<=hi:
        size=int.from_bytes(b[o:o+4],'big'); t=b[o+4:o+8].decode('latin1'); h=8
        if size==1: size=int.from_bytes(b[o+8:o+16],'big'); h=16
        elif size==0: size=hi-o
        yield t,o+h,o+size; o+=size
def find(b,lo,hi,path):
    for t,s,e in boxes(b,lo,hi):
        if t==path[0]: return (s,e) if len(path)==1 else find(b,s,e,path[1:])
for p in sys.argv[1:]:
    b=open(p,'rb').read()
    m=find(b,0,len(b),['mdat']); z=find(b,0,len(b),['moov','trak','mdia','minf','stbl','stsz'])
    print(hashlib.sha256(b[m[0]:m[1]]).hexdigest()[:12], hashlib.sha256(b[z[0]:z[1]]).hexdigest()[:12] if z else '-', len(b))
