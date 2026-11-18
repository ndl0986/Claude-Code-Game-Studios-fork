import os, sys, espeakng_loader
espeakng_loader.get_library_path = lambda: os.environ['ESPEAK_LIB']
espeakng_loader.get_data_path = lambda: os.environ['ESPEAK_REL_DATA']
from misaki import en, espeak
fb = espeak.EspeakFallback(british=False)
g2p = en.G2P(trf=False, british=False, fallback=fb)
for w in open(sys.argv[1]).read().split('\n'):
    if not w.strip(): continue
    ps, toks = g2p(w)
    src = ','.join('lex' if (t.rating or 0) >= 3 else 'fallback' for t in toks if t.phonemes)
    print(f"{w:16s} {ps:28s} {src}")
