import os, sys, numpy as np, soundfile as sf
import espeakng_loader
LIB = os.environ['ESPEAK_LIB']; DATA = os.environ['ESPEAK_REL_DATA']
espeakng_loader.get_library_path = lambda: LIB
espeakng_loader.get_data_path = lambda: DATA
sys.path.insert(0, sys.argv[2])
from lines import LINES
out = sys.argv[1]; speed = float(sys.argv[3]); tag = sys.argv[4] if len(sys.argv) > 4 else ''
os.chdir(os.environ['ESPEAK_CWD'])
from kokoro import KPipeline
pipe = KPipeline(lang_code='a', repo_id='hexgrad/Kokoro-82M')
for lid, text in LINES:
    chunks = []
    for _, ps, a in pipe(text, voice='af_heart', speed=speed):
        chunks.append(a.numpy() if hasattr(a, 'numpy') else a)
        print(lid, 'phonemes:', ps)
    audio = np.concatenate(chunks)
    sf.write(f"{out}/kokoro{tag}_{lid}.wav", audio, 24000)
    print(lid, round(len(audio)/24000, 3), 's')
