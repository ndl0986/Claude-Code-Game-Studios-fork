# TASK-073: TTS samples, Kokoro vs Piper (K-33)

**Purpose:** Luan listens and picks the voice engine for the build-time TTS (Audio & Voice R8, Privacy L-09,
ADR-0003 D6). This is a listening spike: no app code was written and nothing here ships.
**Rendered:** 2026-11-18, by game-art-content, headless on the Mac under `nice -n 10` (K-34), with a throwaway venv
in the session scratchpad (deleted afterwards). No system-level install was used.

## The files

`<engine>_<id>.wav`, mono, 16-bit PCM. The ids are the Key Table voice line ids (`letter_a`, `number_7`,
`word_triceratops`…). Each engine renders the same 12 lines, using the Key Table's `say` script for letters and
digits ("A." for A, "dee" for D, "double you" for W):

| id | text rendered |
|---|---|
| `letter_a` | A. |
| `letter_d` | dee |
| `letter_w` | double you |
| `number_0` | zero |
| `number_7` | seven |
| `word_triceratops` | triceratops |
| `word_ankylosaurus` | ankylosaurus |
| `word_quetzalcoatlus` | quetzalcoatlus |
| `word_egg` | egg |
| `word_nest` | nest |
| `word_moon` | moon |
| `word_three_little_dinosaurs` | three little dinosaurs |

| Set (file prefix) | Engine and setting | Rate |
|---|---|---|
| `kokoro_` | Kokoro-82M, voice `af_heart`, American English (`lang_code='a'`), **speed 0.88** | 24 kHz |
| `piper_` | Piper `en_US-ljspeech` (medium), its **default** (`length_scale` 1.0, noise 0.667 / 0.333), with the voice file's own espeak voice `en` | 22.05 kHz |
| `piper-slow_` | the same, **slower**: `length_scale` 1.25 | 22.05 kHz |
| `piper-enus_` | the same as `piper_` but phonemised with espeak **`en-us`** (see the note below) | 22.05 kHz |

**Lengths are raw.** Kokoro's files include about 0.3–0.5 s of leading and trailing silence (for example "dee" is
1.4 s), and Piper's include a little. The production pipeline trims and loudness-normalises before measuring
`voiceDurations` (ADR-0003 D5, D6), so these raw lengths say nothing about Key Table V15's 1.25 s and 1.0 s limits.
None of the files is loudness-matched yet.

## Engines, versions and licences (as read on 2026-11-18)

**Kokoro**
- Code: `kokoro` 0.9.4 from PyPI (with `misaki` 0.9.4, the G2P), from https://github.com/hexgrad/kokoro. The repo has
  no tags; its `main` was at `dfb907a02bba8152ca444717ca5d78747ccb4bec` (2025-08-06). Licence: **Apache-2.0**
  (GitHub's licence field; the PyPI metadata says "Apache License").
- Weights: https://huggingface.co/hexgrad/Kokoro-82M at revision `f3ff3571791e39611d31c381e3a41a3af07b4987`, file
  `kokoro-v1_0.pth` (SHA-256 starts `496dba118d1a58f5`), voice `voices/af_heart.pt` (SHA-256 starts
  `0ab5709b8ffab19b`). Model-card licence: **apache-2.0**.
- Runtime: PyTorch 2.15.0 (BSD-style plus Apache-2.0 parts, per its licence expression), CPU only.

**Piper**
- Code: the **archived MIT** project https://github.com/rhasspy/piper (archived: yes; licence: **MIT**), release
  `2023.11.14-2`, commit `38917ffd8c0e219c6581d73e07b30ef1d572fce1`. **Not** the GPL successor (OHF-Voice
  `piper1-gpl`, `piper-tts` ≥ 1.3).
  - That release's `piper_macos_aarch64.tar.gz` is not usable on this Mac: its `piper` binary is x86_64 and the
    archive has no `libonnxruntime` or `libespeak-ng` dylibs. So the samples were rendered by running the **same voice
    model** with `onnxruntime` 1.32.0 (MIT), using Piper's own inference recipe (espeak-ng IPA phonemes, the voice's
    `phoneme_id_map` with `^` BOS, `_` padding after every phoneme and `$` EOS, and the voice's `scales`). See
    `render-scripts/piper_render.py`. The output should match the Piper binary, but that is **not verified**
    against the binary.
- Voice: https://huggingface.co/rhasspy/piper-voices at revision `0ca208afc2a2ee102b1e961e72e0a7e4907be3d0`, files
  `en/en_US/ljspeech/medium/en_US-ljspeech-medium.onnx` (SHA-256 starts `6f52a751e2349abe`) and its `.onnx.json`.
  Repo licence: **MIT**. Model card: US English female, single speaker, trained on the **LJ Speech** dataset,
  licence **public domain** (https://keithito.com/LJ-Speech-Dataset/).

**Shared build-time tool: espeak-ng (GPL-3.0).** Both engines phonemise with espeak-ng: Kokoro's `misaki` uses it as
a fallback for words outside its lexicon (through `phonemizer-fork`, also GPL-3.0), and Piper uses it for every
word. Here, espeak-ng 1.52.0 (https://github.com/espeak-ng/espeak-ng, tag `1.52.0`, commit
`4870adfa25b1a32b4361592f1be8a40337c58d6c`) was **built from source in the scratchpad**: the pip `espeakng-loader`
wheel for macOS has its data path compiled in and cannot load, and espeak's 160-character path buffer had to be
raised to fit the scratchpad path. espeak-ng is a **build-time tool only**. It never ships in the app (ADR-0003 D8),
and the rendered audio is the tool's output, not a copy of GPL code. **For Luan / L-09:** please confirm that a
GPL-3.0 tool in the build pipeline is acceptable. It doesn't touch the app's licence, but it is worth stating once.

## Pronunciation notes (from the phonemes each engine produced; game-art-content did not listen)

| Line | Kokoro (misaki) | Piper `en` | Piper `en-us` | Note |
|---|---|---|---|---|
| A | `ˈA` (= /eɪ/) | `ˈeɪ` | `ˈeɪ` | "A." reads as the letter name in both; no "eye" (the one-shot's problem). |
| zero | `zˈɪɹO` | `zˈiəɹəʊ` (British vowel) | `zˈiəɹoʊ` | Piper's default `en` is British-flavoured. **K-05 is US English**, so if Piper wins, phonemise with `en-us` (the `piper-enus_` set). |
| triceratops | `tɹIsˈɛɹətˌɑps` (/aɪ/) | `…ˌɒps` (British /ɒ/) | `…ˌɑːps` | US vowel only with `en-us`. |
| ankylosaurus | `ˌæŋkəlOsˈɔɹəs` (ank-uh-loh-SOR-us) | `ˌaŋkɪləsˈɔːɹəs` | `ˌæŋkɪləsˈɔːɹəs` | All fine. |
| quetzalcoatlus | `kˌɛtsəlkəwˈɑTələs` (ket-sul-kuh-WAH-tuh-lus) | `kwˈɛtsɐlkˌəʊtləs` (KWET-sal-koht-lus) | `kwˈɛtsɐlkˌoʊtləs` | Neither is the usual US museum form, "ket-sul-koh-AT-lus". If Luan wants that, set the `say`-style script to **"ket sul koh AT lus"** (the Key Table `word` stays "quetzalcoatlus"); a respelled script is allowed by Audio R8. |
| three little dinosaurs | `… lˈɪTᵊl dˈInəsˌɔɹz` (flapped t) | `… lˈɪtəl dˈaɪnəsˌɔːz` (non-rhotic) | `… lˈɪɾəl dˈaɪnəsˌɔːɹz` | US forms in Kokoro and Piper `en-us`. |
| double you | `dˈʌbᵊl ju` | `dˈʌbəl juː` | same | Fine. A US child may hear "dubba-you" more often; the clear form is the better teaching form. |
| dee, seven, egg, nest, moon | as expected | as expected | as expected | — |

## Reproduce

The scripts are in `render-scripts/`: `lines.py` (the 12 lines), `kokoro_render.py` and `piper_render.py`. In a
Python 3.11 venv: `pip install kokoro==0.9.4 soundfile onnxruntime`, build espeak-ng 1.52.0 locally (as above), then run
each script with the paths it takes on its command line. The Hugging Face downloads come from the revisions above.

## Next

Luan listens and picks (K-33). game-art-content then writes the chosen engine into Audio & Voice (R8, Q8), Privacy
L-09, and an ADR-0003 D6 note, with the pinned versions above.
