import sys, json, subprocess, os
# logical 1280x720 -> device px. Page viewport origin on screen: (136, 219) device px (uiautomator), dpr 2.625. Canvas rect read live.
here = os.path.dirname(os.path.abspath(__file__))
r = json.loads(json.loads(subprocess.check_output([sys.executable, '-I', os.path.join(here, 'cdp.py'), 'eval',
    'JSON.stringify((b=>[b.left,b.top,b.width])(canvas.getBoundingClientRect()))']))['result']['value'])
L, T, Wd = r; k = Wd / 1280; DPR = 2.625
for i in range(1, len(sys.argv), 2):
    lx, ly = float(sys.argv[i]), float(sys.argv[i+1])
    print(round(136 + (L + lx * k) * DPR), round(219 + (T + ly * k) * DPR), end=' ')
print()
