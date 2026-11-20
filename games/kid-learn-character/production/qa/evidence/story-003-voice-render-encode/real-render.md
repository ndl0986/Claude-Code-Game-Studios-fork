# content-pipeline/003: real Kokoro render (2026-11-20)

The 72 Dinosaurs voice lines (36 letter or number, 36 word) baked from key-table/001's draft
(`content/themes/dinosaurs/src/theme.draft.json`, the nest-family revision) in a scratch copy of `content/`.
Not committed: per the leader's option A they ship together with theme.json, the bakes and the sfx.

**Venv** (scratchpad, never in git; recipe in `apple/Tools/README.md`): Python 3.11, kokoro 0.9.4, misaki 0.9.4,
torch 2.15.0, spacy 3.8.18, en_core_web_sm 3.8.0, espeakng-loader 0.2.4, espeak-ng 1.52.0 built from source
(commit 4870adfa…, `N_PATH_HOME_DEF` raised to 1024), `HF_HUB_OFFLINE=1` at bake time.

**Weights** (Kokoro-82M, revision f3ff3571791e39611d31c381e3a41a3af07b4987), full SHA-256 measured after `--fetch`;
the first 16 hex digits match production/qa/evidence/TASK-073/README.md:
- `kokoro-v1_0.pth` 496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4
- `voices/af_heart.pt` 0ab5709b8ffab19bfd849cd11d98f75b60af7733253ad0d67b12382a102cb4ff

**Bake:** `kidtools bake-voice` → 73 files (72 `.m4a` + provenance.json), 0 rejected, ~4.5 min, load ≤ 4.

**Reproducibility** (an ADR-0003 Engine Compatibility observation, recorded here, ADR unchanged — leader):
1. Unseeded, Kokoro renders the same line to the same length but a different waveform every run (RMS difference
   about −23 dBFS): its vocoder draws noise from torch's RNG.
2. Seeded (torch, random, numpy; `RENDER_SEED` 0), 65 of 72 lines decoded identically across two bakes; 7 still
   differed by multi-threaded float noise (RMS −66 to −116 dBFS).
3. Seeded **and** `torch.set_num_threads(1)` + `torch.use_deterministic_algorithms(True)`: renders are byte-identical.
4. `AVAudioFile` stamps the MP4 `mvhd`/`tkhd`/`mdhd` boxes with the encode time (12 bytes); `VoiceBake.encode` now
   zeroes them (inside `moov` only). Test `test_encoding_the_same_audio_twice_gives_identical_bytes` (watched fail
   without the zeroing).
5. **Result: two full bakes of all 72 lines + provenance are byte-identical (0 differing files).**

**Open, for the leader / Luan (V15):** a rough trim estimate (−40 dB, 20 ms windows; not the D5 measurement) puts
7 of 10 number phrases over the 1.25 s word limit (seven / nine baby dinosaurs ~1.42 s … three ~1.28 s). To be
measured with the D5 meter (content-pipeline/007, reused by 004) before options are put to Luan.

**Listening:** these are seeded takes, not the exact takes Luan heard in TASK-108/110; key-table/001's T1–T8 review
listens to them.
