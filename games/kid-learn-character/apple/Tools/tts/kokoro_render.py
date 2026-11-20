#!/usr/bin/env python3
"""Kokoro-82M render helper for `kidtools bake-voice` (ADR-0003 D6, K-41). BUILD MACHINE ONLY, never shipped.

Own code. Two modes:

  --fetch  --revision R --dest DIR       one-off setup: download the pinned weights (network). Never at bake time.
  render   --text-file F --out W.wav --voice V --lang L --speed S --revision R --package P
           (offline; HF_HUB_OFFLINE=1) writes a mono 24 kHz PCM_16 WAV and prints ONE JSON object of strings on the
           last stdout line: installed versions for the bake's provenance.json. No trim, no loudness change (story 004).

Environment (see apple/Tools/README.md, the espeak-ng source build, K-36; from game-art-content TASK-073/108/110):
  ESPEAK_LIB       path of libespeak-ng.dylib
  ESPEAK_REL_DATA  espeak-ng data dir, RELATIVE to ESPEAK_CWD (the home-path buffer is 160 chars)
  ESPEAK_CWD       directory the helper chdir()s into before loading
  HF_HOME          where --fetch put the weights (snapshot_download cache)
  HF_HUB_OFFLINE   1 at bake time

NOT YET RUN: no venv exists in this run. Everything marked UNVERIFIED is written from the recipe, not observed.
"""
import argparse
import hashlib
import json
import os
import sys
import wave
from importlib import metadata

REPO = "hexgrad/Kokoro-82M"
# SHA-256 prefixes recorded in production/qa/evidence/TASK-073/README.md. That README holds only the first 16 hex
# digits, not the full hashes, so the check is by prefix. Replace with the full digests once they are recorded.
WEIGHT_SHA256_PREFIX = {
    "kokoro-v1_0.pth": "496dba118d1a58f5",
    "voices/af_heart.pt": "0ab5709b8ffab19b",
}
SAMPLE_RATE = 24000


def fail(code, msg):
    sys.stderr.write(msg + "\n")
    sys.exit(code)


def version(dist):
    try:
        return metadata.version(dist)
    except metadata.PackageNotFoundError:
        return None


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def snapshot(revision, offline):
    """The local snapshot folder of the pinned revision."""
    from huggingface_hub import snapshot_download
    return snapshot_download(
        REPO, revision=revision, local_files_only=offline,
        allow_patterns=["config.json", "kokoro-v1_0.pth", "voices/af_heart.pt"])


def check_weights(folder):
    for rel, prefix in WEIGHT_SHA256_PREFIX.items():
        p = os.path.join(folder, rel)
        if not os.path.isfile(p):
            fail(4, "missing weight file %s (run --fetch first)" % p)
        if not sha256(p).startswith(prefix):
            fail(4, "SHA-256 of %s does not start with %s" % (rel, prefix))


def patch_espeak():
    """The pip espeakng-loader wheel cannot load on macOS (data path compiled in): point it at the source build.
    Must run BEFORE kokoro/misaki are imported."""
    import espeakng_loader
    espeakng_loader.get_library_path = lambda: os.environ["ESPEAK_LIB"]
    espeakng_loader.get_data_path = lambda: os.environ["ESPEAK_REL_DATA"]
    os.chdir(os.environ["ESPEAK_CWD"])


def espeak_version():
    """espeak-ng's own version if it can be read; None otherwise (reported as "not reported")."""
    try:
        import ctypes
        lib = ctypes.CDLL(os.environ["ESPEAK_LIB"])
        lib.espeak_Info.restype = ctypes.c_char_p
        lib.espeak_Info.argtypes = [ctypes.c_void_p]
        v = lib.espeak_Info(None)
        return v.decode() if v else None
    except Exception:  # UNVERIFIED: espeak_Info may need espeak_Initialize first
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fetch", action="store_true")
    ap.add_argument("--text-file")
    ap.add_argument("--out")
    ap.add_argument("--voice")
    ap.add_argument("--lang")
    ap.add_argument("--speed", type=float)
    ap.add_argument("--revision", required=True)
    ap.add_argument("--package")
    a = ap.parse_args()

    if a.fetch:
        check_weights(snapshot(a.revision, offline=False))
        print(json.dumps({"fetched": a.revision}))
        return

    if os.environ.get("HF_HUB_OFFLINE") != "1":
        fail(2, "HF_HUB_OFFLINE=1 is required at bake time (no network)")
    for need in (a.text_file, a.out, a.voice, a.lang, a.speed, a.package):
        if need is None:
            fail(2, "render needs --text-file --out --voice --lang --speed --package")
    name, _, pin = a.package.partition("==")
    if version(name) != pin:
        fail(3, "installed %s is %s, the voice script pins %s" % (name, version(name), pin))
    if a.voice != "af_heart":
        fail(3, "only the verified voice af_heart is fetched/checked, got %s" % a.voice)

    folder = snapshot(a.revision, offline=True)
    check_weights(folder)
    patch_espeak()

    import numpy as np
    import soundfile
    # UNVERIFIED against kokoro 0.9.4 source: local-path loading of KModel / KPipeline / the voice .pt.
    from kokoro import KModel, KPipeline
    model = KModel(config=os.path.join(folder, "config.json"), model=os.path.join(folder, "kokoro-v1_0.pth"))
    pipe = KPipeline(lang_code=a.lang, model=model)
    with open(a.text_file, encoding="utf-8") as f:
        text = f.read()
    chunks = [audio.numpy() for _, _, audio in pipe(text, voice=os.path.join(folder, "voices", a.voice + ".pt"), speed=a.speed)]
    if not chunks:
        fail(5, "kokoro returned no audio")
    soundfile.write(a.out, np.concatenate(chunks), SAMPLE_RATE, subtype="PCM_16")  # 24 kHz mono PCM_16
    with wave.open(a.out) as w:
        if w.getnchannels() != 1 or w.getframerate() != SAMPLE_RATE:
            fail(5, "output is not 24 kHz mono")

    facts = {"kokoro": version("kokoro"), "misaki": version("misaki"), "torch": version("torch"),
             "spacy": version("spacy"), "en_core_web_sm": version("en_core_web_sm"),
             "espeakng-loader": version("espeakng-loader"), "espeak-ng": espeak_version()}
    print(json.dumps({k: v for k, v in facts.items() if v is not None}, sort_keys=True))


if __name__ == "__main__":
    main()
