# Language & Text (VI/EN)

> **Status**: In Review
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Nhỏ chơi được (Small hands can do it), Đúng sự thật (True to history), Học mà vui (Learn by playing)
> **Task**: TASK-015 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

Every word the child sees exists in Vietnamese and English. Vietnamese is the default, and the
child can switch at the title screen or in the pause menu. Text is always a live layer (never
in art), set in one rounded font with full Vietnamese diacritics. Every line fits its box in
both languages without shrinking, and is written by one voice: warm, plain, no pronoun for the
child (or "em").

> **Quick reference** — Layer: `Foundation` · Priority: `Vertical Slice` · Key deps: `Content data & claims` · Used by: `Mission flow, Quiz & stars, Hints & onboarding, Hero progression, Audio & voice-over`

## Overview

The concept promises "Vietnamese (default) and English… switch language at any time". This
system owns:
- which language is active and how it changes;
- how text is drawn (font, size, wrapping);
- the length limits that keep layouts working in both languages;
- the voice rules every line follows.

It does not own what lines say (content, `design/narrative/heroes/<hero>.md`), where text sits
on a screen (each UX spec), or voice-over (Audio & voice-over).

## Detailed Design

### Core Rules

1. **Two languages, both complete.** Every player-facing string is a Text or UiText with
   non-empty `vi` and `en` (content contract). A missing language **fails validation**: there is
   no silent fallback to the other language.
2. **Default and switching (vertical-slice rule).** The game starts in **Vietnamese**. The
   child switches with the VI|EN chip on the **title screen** and in the **pause menu** (P-04).
   The choice is saved as `lang` (Save & progress) and restored on the next launch.
3. **First-launch choice (proposed, D-20).** The concept asks for a "first-launch choice". The
   proposal: on the very first launch only, a picture-only screen with two big buttons ("Tiếng
   Việt" with a lotus icon, "English" with a book icon) sets `lang`. VI is pre-selected, so one
   tap on "Tiếp" keeps it. Not in the slice until Luan decides.
4. **Switch effect.** On the title screen the switch applies at once. From the pause menu,
   all on-screen Text is in the new language when play resumes (Mission flow Rule 12). Play
   state, `story_skipped`, quiz retries and card order never change on a switch.
5. **One font.** Nunito (SIL OFL 1.1, `content/data/fonts/nunito.ttf`, licence beside it), two
   weights (regular, bold). It must render every Vietnamese character, including stacked marks
   (Ặ Ỗ Ữ ẫ ợ ệ ằ) and both tone-mark placements (khoá/khóa), with no clipped diacritics.
6. **Sizes** (art bible §7, three sizes: title, body, button), in **world px at the fitted
   scale** (k ≈ 1.28 on a 20:9 phone):
   - **Body text** is never below `text_min_body` = **37 world px** (about 18 dp). It covers story
     boxes, goal, dialog, quiz prompt, quiz why and **quiz choices**.
   - **Labels that sit under or beside an icon or picture** are never below
     `text_min_label` = **28 world px**. They cover pad labels, counters ("Câu 2/5") and the
     map-stub line. The icon carries the meaning, so the label is a secondary cue.
   - Today's sizes that must rise: quiz choices 32 → 37, pad labels 24 → 28, map-stub 26 → 28
     (the quiz counter at 28 is fine). `/ux-design` sets the exact size per screen, at or above
     these minimums.
   - Text **never shrinks to fit**: a line that doesn't fit is a content error caught by
     validation (R8c, F1).
   - **Run-time safety net (leader's call):** if a line still overflows at run time, the app
     may cut it with an ellipsis "…" rather than draw outside its box. Validation must catch it
     first, so an ellipsis in a shipped build is a **bug**.
7. **Line height.** At least 1.35 × the font size, so stacked Vietnamese marks never touch the
   line above.
8. **Length limits, both languages.**
   - EN: `rules.json` `text_limits.en_budget` per field type (R8).
   - **VI (proposed, D-21):** a matching `vi_budget` = `en_budget` × 1.6, rounded down. In
     today's data, VI runs 0.38–1.7× EN (median 0.9), and short UI words are often longer in VI
     ("Màn hình chính" vs "Home").
   - Each field also has a **maximum line count** (Formula F1): button 1, ui 1, goal 1, beat
     title 1, hero name 1, place 1, quiz choice 2, story box (intro/scene/ending) 2, quiz prompt
     2, quiz why 3, dialog 3, banner 2.
9. **Text is never in pictures.** Every word, including the banner's six words, is a text layer
   drawn over the art (art bible; Luan's rule 2).
10. **Writing rules** (`design/narrative/writing-guide.md`, enforced in review; R-rules where
    marked):
    - Vietnamese uses **no pronoun** for the child where possible, and **"em"** when one is
      needed (D-17). Never "bạn", "con" or "cháu". Story narration about a hero ("cậu", "ông")
      is not covered by this rule.
    - No designer words on screen ("special", "beat", "level", "meter").
    - One sentence per story box, at most 120 characters (R8).
    - NFC, full diacritics (R7).
    - Legend lines carry a marker (R4, R4b).
11. **Numbers and order.** Counters such as "Câu 2/5 / Question 2/5" are built from a UiText
    plus numbers in code, using the same digits in both languages. No date or number formats
    differ by language in the slice.
12. **Accessibility.** Every instruction a pre-reader needs also has an icon or voice
    (Hints and Audio). Text is never the only cue.

### States and Transitions

`lang` is `vi` or `en`.
- `vi` → `en` (or back): the chip is tapped on the title screen or in the pause menu.
- First launch, if D-20 is accepted: `unset` → `vi` or `en` from the picker. Otherwise
  `unset` → `vi`.
- The value is saved at once (Save & progress).

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Content data & claims | Text/UiText (`vi`, `en`), `rules.json` budgets, the font | (none) | Content contract |
| Save & progress | the saved `lang` | the new `lang` on a switch | Save GDD |
| Mission flow, Quiz & stars, Hero progression | (none) | the current language; a language-changed event | Each GDD renders through this system |
| Hints & onboarding | (none) | nothing: hints have no text | Hints GDD |
| Audio & voice-over | (none) | the current language, to pick the VO clip | Audio GDD |

## Formulas

The F1 (line fit) formula is defined as:

`lines = greedy_wrap(text, box_width / (1 + kern), font_px)`, where each word's width is the **sum of Nunito's real advance widths** (from the TTF's `cmap` and `hmtx`, scaled by `font_px / unitsPerEm`). Words go on the current line while they fit; otherwise they start a new line. A field **passes** if `lines ≤ max_lines(field)` in **both** VI and EN. An overflow **fails validation (R8c)**.

This is the check both apps' content tests run. It's deterministic: the same font file and the same numbers give the same result on both platforms.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| text | string | 1–120 chars | content (NFC) | The line, in each language |
| advance(g) | int (font units) | from the TTF | data file (`content/data/fonts/nunito.ttf`, `hmtx`) | Real width of each glyph |
| font_px | float (world px at 1×) | ≥ `text_min_*` | data file (`rules.json`, per field type; proposed) | Font size |
| box_width | float (world px at 1×) | per field type | data file (`rules.json`, per field type; proposed) | Text box width |
| kern | float | 0.03 | constant | Allowance for kerning and shaping differences |
| max_lines | int | 1–3 | data file (`rules.json`, per field type; proposed, Rule 8 table) | Allowed lines |

**Output Range:** an integer ≥ 1 per language. Words longer than a whole line (none exist in
VI or EN game text) would also fail.
**Example:** a story box with `box_width` 1000 world px and body 37 px. Nunito's average advance
is ≈ 0.55 em, so about 20 px per glyph and, after the 3% allowance, about 48 characters per
line. A 90-character VI line wraps to 2 lines, within story-box max 2. A 120-character line could
need 3 and would fail R8c, so the writer shortens it.

The F2 (VI budget) formula is defined as:

`vi_budget(field) = floor(1.6 × en_budget(field))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| en_budget | int | 12–120 | data (`rules.json`) | EN limit per field type |
| 1.6 | float | — | constant (measured max VI/EN ratio 1.7 over 80 lines, rounded down for short UI words) | VI headroom |

**Output Range:** 19–192, capped by `max_chars` 120.
**Example:** button 12 → VI 19 ("Màn hình chính" is 14, so it fits). ui 24 → VI 38. The one line
that would fail today is `ui.medal.missing` (VI 39). It is a sentence, so it should be typed
`dialog` (60 → VI 96): part of D-21.

## Edge Cases

- **If a line is missing one language**: validation fails (Rule 1), and the build stops.
- **If a VI line exceeds `vi_budget`** (once D-21 lands): validation fails with R8b. It's fixed in
  content, never by shrinking.
- **If the language switches while a voice line plays** (post-slice): Audio stops it and plays
  the same line id in the new language (Mission flow Rule 12, Audio GDD).
- **If the saved `lang` is missing or unreadable**: use `vi` (Save: start fresh).
- **If a device's system language is English**: still start in VI (concept: VI default). The
  first-launch picker (D-20), if accepted, is where a child picks English.
- **If a glyph is missing from the font**: a debug build shows a visible tofu box and a test
  fails. A shared fixture string covers every Vietnamese letter with every tone mark (Rule 5).
- **If text would overflow at run time** (an unforeseen font or screen): it is cut with "…" as a
  safety net (Rule 6). That is a bug to fix in content or layout, never a shipped behaviour.
- **If a screen is narrower than designed**: the world is fitted by scale k, so world-px boxes
  keep their line breaks. Layouts are tested on the narrowest supported phone (QC).

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Content data & claims | this depends on it | Hard | Text, budgets, font file |
| Save & progress | this depends on it (lang) | Hard | `lang` (`design/gdd/save-and-progress.md`) |
| Mission flow & beat types | depends on this | Hard | Rendering, switch on pause (Rule 12 there) |
| Quiz & stars | depends on this | Hard | Rendering; the switch keeps quiz state |
| Hero progression & unlock | depends on this | Hard | Hero names, unlock and results text |
| Audio & voice-over | depends on this | Soft | Current language for VO |
| Hints & onboarding | (none) | — | Hints use no text |

## Visual/Audio Requirements

- The VI|EN chip is spec'd as ASSET-031 (`design/assets/specs/mission-hud-assets.md`). The
  first-launch picker (D-20), if accepted, needs two icon buttons (lotus, book) and a
  `/asset-spec` addition.
- No audio of its own. VO language follows `lang` (Audio GDD).

## UI Requirements

- The chip shows "VI | EN" with the active one bold and in the accent colour, plus an underline
  shape. That is the colour-blind backup.
- Text boxes are sized by F1 for the longer language.
- 📌 **UX Flag — Language & Text**: the first-launch picker (if D-20) and the text-box sizes per
  screen go in `/ux-design`.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Concept | `design/gdd/game-concept.md` (Languages) | VI default, switch any time, first-launch choice |
| Content contract | `content/README.md` R4, R4b, R7, R8; `content/data/rules.json` `text_limits` | Rules and budgets |
| Writing guide | `design/narrative/writing-guide.md` | Voice (D-17), plain words, format |
| Art bible | `design/art/art-bible.md` §7 | Typography, sizes, no text in art |
| Mission flow | `design/gdd/mission-flow.md` Rules 4, 12 | Where the switch is; resume behaviour |
| Decisions | `production/team/decisions.md` P-04, D-17, D-20 (new), D-21 (new) | Switch placement, voice, picker, VI budgets |

## Acceptance Criteria

Criteria 1–5 and 9 are logic and need unit tests or validation; 6–8 need QC screenshots.

1. **GIVEN** a fresh install, **WHEN** the game starts, **THEN** all text is Vietnamese (the slice
   rule, until D-20).
2. **GIVEN** the title screen, **WHEN** the chip is tapped, **THEN** all title text is English at
   once, and after a relaunch the game starts in English.
3. **GIVEN** a quiz question with one greyed card, **WHEN** the language is switched in pause
   and play resumes, **THEN** the same card is greyed, retries are unchanged, and the text is in
   the new language.
4. **GIVEN** content with a Text whose `en` is empty, **WHEN** validated, **THEN** validation fails.
5. **GIVEN** an EN line over its field budget, **WHEN** validated, **THEN** validation fails (R8).
   **GIVEN** D-21, the same holds for VI over `vi_budget`. **GIVEN** a line that wraps to more
   than its field's `max_lines` with Nunito's real advances (F1), **THEN** validation fails (R8c),
   with the same result on both apps.
6. **GIVEN** the diacritic fixture string ("Ặ Ỗ Ữ ẫ ợ ệ ằ khoá khóa"), **WHEN** rendered at
   body size on both platforms, **THEN** no mark is clipped or overlaps the line above (screenshot).
7. **GIVEN** every slice screen, **WHEN** captured in VI and EN on the narrowest supported phone,
   **THEN** no text overflows its box and none is shrunk below its size.
8. **GIVEN** any picture asset, **WHEN** reviewed, **THEN** it contains no letters or numerals.
9. **GIVEN** the Vietnamese player text, **WHEN** scanned, **THEN** no line addresses the child as
   "bạn", "con" or "cháu" (D-17; a review check, optionally a lint).

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| D-20 | First-launch language picker (Rule 3): add it, or keep "VI by default, switch on the title and pause"? | Luan | Before first release |
| D-21 | VI budgets (`vi_budget` = 1.6 × EN, R8b) + `max_lines` per field in `rules.json`; retype `ui.medal.missing` as `dialog` | game-dev-ios + game-dev-android, game-art-content | Before the UX specs |
| — | `box_width`, `font_px` and `max_lines` per field type in `rules.json`, plus R8c in both apps' content tests (with D-21) | game-dev-android (data branch), game-dev-ios reviews | Before the UX specs |
| — | `/ux-design` sets per-screen sizes at or above `text_min_body` 37 and `text_min_label` 28 world px | game-art-content + ux | UX pass |
