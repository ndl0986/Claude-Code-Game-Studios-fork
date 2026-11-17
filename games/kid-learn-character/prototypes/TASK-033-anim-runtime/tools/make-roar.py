# PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
# Synthesises a 0.9 s placeholder "roar" (a low growl: a falling sawtooth with noise and an envelope), so the spike
# has a sound with no licence question. Deterministic (seeded).  python3 tools/make-roar.py Spike/roar.wav
import math, random, struct, sys, wave
sr, dur = 44100, 0.9
random.seed(2026)
out, phase = [], 0.0
for i in range(int(sr * dur)):
    t = i / sr
    f = 140 - 70 * t / dur                       # falling pitch
    phase = (phase + f / sr) % 1.0
    saw = 2 * phase - 1
    noise = random.uniform(-1, 1)
    env = min(1, t / 0.04) * max(0, 1 - max(0, t - 0.55) / 0.35)  # 40 ms attack, release from 0.55 s
    trem = 0.75 + 0.25 * math.sin(2 * math.pi * 23 * t)            # growl flutter
    out.append(max(-1, min(1, (0.6 * saw + 0.35 * noise) * env * trem * 0.8)))
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in out))
print("wrote", sys.argv[1])
