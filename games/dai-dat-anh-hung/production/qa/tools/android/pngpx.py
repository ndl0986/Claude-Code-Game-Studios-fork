import zlib,struct,sys
def load(p):
    d=open(p,'rb').read(); i=8; idat=b''
    while i<len(d):
        n=struct.unpack('>I',d[i:i+4])[0]; t=d[i+4:i+8]; c=d[i+8:i+8+n]
        if t==b'IHDR': w,h,bd,ct=struct.unpack('>IIBB',c[:10])
        if t==b'IDAT': idat+=c
        i+=12+n
    bpp={2:3,6:4}[ct]; raw=zlib.decompress(idat); rows=[]; prev=bytearray(w*bpp); o=0
    for y in range(h):
        f=raw[o]; o+=1; line=bytearray(raw[o:o+w*bpp]); o+=w*bpp
        for x in range(len(line)):
            a=line[x-bpp] if x>=bpp else 0; b=prev[x]; c=prev[x-bpp] if x>=bpp else 0
            if f==1: line[x]=(line[x]+a)&255
            elif f==2: line[x]=(line[x]+b)&255
            elif f==3: line[x]=(line[x]+(a+b)//2)&255
            elif f==4:
                p_=a+b-c; pa,pb,pc=abs(p_-a),abs(p_-b),abs(p_-c); pr=a if pa<=pb and pa<=pc else (b if pb<=pc else c); line[x]=(line[x]+pr)&255
        rows.append(bytes(line)); prev=line
    return w,h,bpp,rows
