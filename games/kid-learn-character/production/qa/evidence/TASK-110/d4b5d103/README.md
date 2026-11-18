# TASK-110: trimmed lengths of the seven K-35 picks (V15 early check)

Not a production bake: this re-measures the TASK-108 r2 renders (`../../TASK-108/8b30e7a5/`), the files Luan picked
(K-41), and the as-spelled triceratops, so a line that would break Key Table V15 (word lines ≤ 1.25 s) shows up early.

**Method** (`trim_len.py`): 20 ms windows; the leading and trailing windows whose RMS is below −40 dBFS relative to
the file's peak are dropped; the length is the span that remains. This is an estimate. The bake's own trim and
D5's measured `voiceDurations` decide V15.

| Line id | Respelled input | Raw (s) | Trimmed (s) | V15 (≤ 1.25 s) |
|---|---|---|---|---|
| `word_ankylosaurus` | ankie low saurus | 2.000 | 1.080 | OK |
| `word_juravenator` | joor uh vuh nay tor | 1.850 | 1.000 | OK |
| `word_quetzalcoatlus` | kets all ko at lus | 2.050 | **1.220** | OK, tight (0.03 s margin) |
| `word_tapejara` | tah pay jar ah | 1.975 | 0.920 | OK |
| `word_wuerhosaurus` | wur hoe saurus | 2.025 | 1.080 | OK |
| `word_xenoceratops` | zen oh sair uh tops | 2.000 | 1.180 | OK |
| `word_zuniceratops` | zoo nee serra tops | 1.950 | 1.100 | OK |
| `word_triceratops` | (as spelled) | 1.825 | 0.900 | OK |

**Watch:** quetzalcoatlus at 1.22 s is within 0.03 s of the limit. If the bake's trim measures it over 1.25 s, the
options are a slightly faster speed for that one line or a tighter respelling, which would need Luan's ear again
(K-35).
