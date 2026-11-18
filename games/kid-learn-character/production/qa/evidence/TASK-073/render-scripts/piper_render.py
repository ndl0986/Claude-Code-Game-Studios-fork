# Piper (rhasspy/piper, MIT) inference re-implemented with onnxruntime, as in piper's own python_run:
# espeak-ng IPA phonemes -> phoneme_id_map with BOS '^', pad '_' after every phoneme, EOS '$'.
import json, os, subprocess, sys, unicodedata, numpy as np, onnxruntime as ort, soundfile as sf
sys.path.insert(0, sys.argv[2]); from lines import LINES
out, model, espeak_bin, data = sys.argv[1], sys.argv[3], sys.argv[4], sys.argv[5]
length_scale = float(sys.argv[6]); tag = sys.argv[7]
cfg = json.load(open(model + '.json')); idmap = cfg['phoneme_id_map']; inf = cfg['inference']
sess = ort.InferenceSession(model, providers=['CPUExecutionProvider'])
env = dict(os.environ, ESPEAK_DATA_PATH=data)
for lid, text in LINES:
    ipa = subprocess.run([espeak_bin, '-q', '--ipa', '-v', os.environ.get('PIPER_VOICE', cfg['espeak']['voice']), text], capture_output=True, text=True, env=env).stdout
    ipa = unicodedata.normalize('NFD', ' '.join(ipa.split()))
    ids = list(idmap['^']) + list(idmap['_'])
    for ch in ipa:
        if ch in idmap: ids += idmap[ch] + idmap['_']
    ids += idmap['$']
    x = np.array([ids], dtype=np.int64)
    feeds = {'input': x, 'input_lengths': np.array([x.shape[1]], dtype=np.int64),
             'scales': np.array([inf['noise_scale'], length_scale, inf['noise_w']], dtype=np.float32)}
    audio = sess.run(None, feeds)[0].squeeze()
    sf.write(f"{out}/piper{tag}_{lid}.wav", audio.astype(np.float32), cfg['audio']['sample_rate'])
    print(lid, 'ipa:', ipa, round(len(audio) / cfg['audio']['sample_rate'], 3), 's')
