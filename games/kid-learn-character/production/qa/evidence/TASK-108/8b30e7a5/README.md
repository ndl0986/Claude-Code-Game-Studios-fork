# TASK-108: Kokoro respelling candidates (K-35, K-41)

**Purpose:** Luan listens and approves one respelled script per hard name before anything is baked (K-35). Nothing here
ships, the voice script is not changed yet, and no app code was written. The directory name is the plan-branch
commit the work was cut from (`8b30e7a5`).
**Engine (K-41):** Kokoro-82M, voice `af_heart`, `lang_code='a'`, speed 0.88. Package `kokoro` 0.9.4 (`misaki`
0.9.4), weights revision `f3ff3571791e39611d31c381e3a41a3af07b4987`, the same files as TASK-073 (pins and hashes in
`../../TASK-073/README.md`). Rendered headless at `nice -n 10`, with a throwaway venv in the session scratchpad, on
2026-11-18.

## How the names were picked

game-art-content **did not listen**. The check is the phoneme string Kokoro's own G2P (`misaki`, with the espeak-ng
fallback, K-36) produces for every Dinosaurs word line, compared with the usual US pronunciation. 7 of the 26 word
lines differ (`render-scripts/g2p_check.py` prints them):

| Name | Kokoro reads (G2P) | Usual US form | Why flagged |
|---|---|---|---|
| ankylosaurus | `ˌæŋkəlOsˈɔɹəs` (ANK-uh-loh-SOR-us) | an-KYE-luh-SOR-us | the "kye" is missing |
| quetzalcoatlus | `kˌɛtsəlkəwˈɑTələs` (ket-sul-kuh-WAH-tuh-lus) | ket-sul-koh-AT-lus | wrong vowels and stress |
| juravenator | `ʤjˈʊɹɹAvənˌATəɹ` | joo-RAV-uh-nay-tor | the fallback garbles it |
| tapejara | `tApʤˈɑɹɹə` (TAYP-jar-uh) | tap-uh-JAR-uh | a syllable is lost |
| wuerhosaurus | `wjˌuɹhəsˈɔɹəs` (wyoor-huh-SOR-us) | WER-hoh-SOR-us | "wyoor" |
| xenoceratops | `zˈɛnOsəɹɹˌætɑps` (ZEN-oh-ser-RAT-ops) | zee-noh-SER-uh-tops | stress on "RAT" |
| zuniceratops | `zjˈunɪsəɹɹˌætɑps` (ZYOO-ni-ser-RAT-ops) | zoo-nee-SER-uh-tops | "zyoo", stress on "RAT" |

**Checked and fine:** triceratops (`tɹIsˈɛɹətˌɑps`, try-SER-uh-tops), so it needs no respelling. The as-spelled file is
included for comparison. The other 18 word lines read the usual way, e.g. brachiosaurus, diplodocus, iguanodon,
stegosaurus, velociraptor and "tee rex".

## Candidates

Respelled inputs were chosen so the G2P gives the intended phonemes. The G2P reads "ay" as /aɪ/ ("eye"), so
those were avoided. File names are `kokoro_<line id>__<variant>.wav`; `__as_spelled` is Kokoro's current reading.

| Line id | Variant | Input to Kokoro | Phonemes | File |
|---|---|---|---|---|
| `word_ankylosaurus` | as spelled | ankylosaurus | `ˌæŋkəlOsˈɔɹəs` | `kokoro_word_ankylosaurus__as_spelled.wav` |
| | r1 | an kye low sore us | `ɐn kˈI lˈO sˈɔɹ ˌʌs` | `kokoro_word_ankylosaurus__r1.wav` |
| | r2 | ankie low saurus | `ˈæŋki lˈO sˈɔɹəs` | `kokoro_word_ankylosaurus__r2.wav` |
| `word_quetzalcoatlus` | as spelled | quetzalcoatlus | `kˌɛtsəlkəwˈɑTələs` | `kokoro_word_quetzalcoatlus__as_spelled.wav` |
| | r1 | ket sul co at luss | `kˈɛt sˈʌl kˈO æt lˈʌs` | `kokoro_word_quetzalcoatlus__r1.wav` |
| | r2 | kets all ko at lus | `kˈɛts ˈɔl kˈO æt lˈʌs` | `kokoro_word_quetzalcoatlus__r2.wav` |
| `word_juravenator` | as spelled | juravenator | `ʤjˈʊɹɹAvənˌATəɹ` | `kokoro_word_juravenator__as_spelled.wav` |
| | r1 | joo rav uh nay tor | `ʤˈu ɹˈɑv ˈʌ nˈA tˈɔɹ` | `kokoro_word_juravenator__r1.wav` |
| | r2 | joor uh vuh nay tor | `ʤˈɔɹ ˈʌ vˈʌ nˈA tˈɔɹ` | `kokoro_word_juravenator__r2.wav` |
| `word_tapejara` | as spelled | tapejara | `tApʤˈɑɹɹə` | `kokoro_word_tapejara__as_spelled.wav` |
| | r1 | tap uh jar uh | `tˈæp ˈʌ ʤˈɑɹ ˈʌ` | `kokoro_word_tapejara__r1.wav` |
| | r2 | tah pay jar ah | `tˈɑ pˈA ʤˈɑɹ ˈɑ` | `kokoro_word_tapejara__r2.wav` |
| `word_wuerhosaurus` | as spelled | wuerhosaurus | `wjˌuɹhəsˈɔɹəs` | `kokoro_word_wuerhosaurus__as_spelled.wav` |
| | r1 | wer ho sore us | `wˈɜɹ hˈO sˈɔɹ ˌʌs` | `kokoro_word_wuerhosaurus__r1.wav` |
| | r2 | wur hoe saurus | `wˈɜɹ hˈO sˈɔɹəs` | `kokoro_word_wuerhosaurus__r2.wav` |
| `word_xenoceratops` | as spelled | xenoceratops | `zˈɛnOsəɹɹˌætɑps` | `kokoro_word_xenoceratops__as_spelled.wav` |
| | r1 | zee no sair uh tops | `zˈi nˈO sˈɛɹ ˈʌ tˈɑps` | `kokoro_word_xenoceratops__r1.wav` |
| | r2 | zen oh sair uh tops | `zˈɛn ˈO sˈɛɹ ˈʌ tˈɑps` | `kokoro_word_xenoceratops__r2.wav` |
| `word_zuniceratops` | as spelled | zuniceratops | `zjˈunɪsəɹɹˌætɑps` | `kokoro_word_zuniceratops__as_spelled.wav` |
| | r1 | zoo nee sair uh tops | `zˈu nˈi sˈɛɹ ˈʌ tˈɑps` | `kokoro_word_zuniceratops__r1.wav` |
| | r2 | zoo nee serra tops | `zˈu nˈi sˈɛɹə tˈɑps` | `kokoro_word_zuniceratops__r2.wav` |
| `word_triceratops` | as spelled (no change needed) | triceratops | `tɹIsˈɛɹətˌɑps` | `kokoro_word_triceratops__as_spelled.wav` |

**What to listen for:**
- **Rhythm.** Spaced respellings are separate words to the G2P, and each gets its own stress mark, so a candidate may
  sound syllable-by-syllable. If every candidate for a name sounds choppy, say so, and game-art-content will try
  joined or hyphenated forms.
- **Pick per line:** the as-spelled reading (keep), r1, r2, or "none of these, try again".
- **Length:** the files are raw (24 kHz mono, about 0.3–0.5 s of lead and trail silence each). After trimming, a word
  line must still be ≤ 1.25 s (Key Table V15); the bake checks this.

**Unchanged by K-35:** the displayed name and the Key Table `name` / `word` keep the correct spelling. Only the
voice script's input for that line changes, after Luan's pick, as a separate commit.

## Reproduce

`render-scripts/lines.py` (the 22 inputs) and `g2p_check.py` (the phoneme check) run with the TASK-073 setup and
`render-scripts/kokoro_render.py` from `../../TASK-073/render-scripts/` at speed 0.88.
