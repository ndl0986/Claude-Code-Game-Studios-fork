import subprocess,os,sys
ADB=os.path.expanduser('~/Android/sdk/platform-tools/adb')
raw=subprocess.run([ADB,'-s','emulator-5554','exec-out','screencap'],capture_output=True).stdout
w=int.from_bytes(raw[0:4],'little'); hdr=16; K=1.28055; OX=448.5; OY=74
def px(wx,wy):
    x=round(OX+wx*K); y=round(OY+wy*K); o=hdr+(y*w+x)*4; return tuple(raw[o:o+3])
s=sum(sum(px(500+6*i,470)) for i in range(50)); print('textsig', s)
