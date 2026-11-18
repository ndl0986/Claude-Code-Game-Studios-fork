# Trimmed length: drop leading/trailing samples below -40 dBFS relative to the file's peak (20 ms hold windows).
import sys, numpy as np, soundfile as sf
for f in sys.argv[1:]:
    a, sr = sf.read(f); a = a if a.ndim == 1 else a.mean(1)
    win = int(0.02 * sr); n = len(a) // win
    rms = np.array([np.sqrt(np.mean(a[i*win:(i+1)*win]**2)) for i in range(n)])
    thr = np.max(np.abs(a)) * 10**(-40/20)
    idx = np.where(rms > thr)[0]
    t = (idx[-1] - idx[0] + 1) * win / sr if len(idx) else 0.0
    print(f"{f.split('/')[-1]}\traw {len(a)/sr:.3f}\ttrimmed {t:.3f}\t{'OK' if t <= 1.25 else 'OVER 1.25'}")
