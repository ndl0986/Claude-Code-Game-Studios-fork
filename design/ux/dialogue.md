# UX Spec: Dialogue Beat (e.g. "Xin gặp vua" at Bình Than)

> **Status**: In Review · Task: TASK-021 · Author: game-art-content
> **Template**: UX Spec
> **Platform Target**: Android + iOS phones, landscape, touch only (`project.yaml` goal mobile; no gamepad or keyboard). Accessibility tier: Basic+ (`design/accessibility-requirements.md`).
> **Records what's built** (TASK-016a). Sources: Mission flow Rule 7d, states (`dialogue_line`),
> F6, AC23–25; schema 1.4 (R4c, R13d); Input Rules 8, 12, 13; Hints (the stuck hand on the ask
> button); assets ASSET-327–331; the hero doc §3 beat 1b (script approved by Luan).

## 1. Purpose & Player Need

A famous exchange is told as a short illustrated conversation. The child **acts** in it by
pressing the hero's own ask button ("Xin vào! / Let me in!").

## 2–4. Context, Navigation, Entry & Exit

Entry: `walk_to[i]` reaches a dialogue beat (no beat card, no caption). Exit: the last line's Tiếp
→ `beat_end` → the next beat (the orange).

## 5. Layout Specification

### 5.1 ASCII Wireframe (a speaker line; the hero on the left, others on the right)

```
┌──────────────────────────────────────────────────────────────────┐
│ [⏸][🔊]   (background: the meeting gate, ASSET-312, dimmed 30%)  │
│                                                                  │
│ ┌────────┐ ┌──── dialogue panel (bottom-anchored) ────┐           │
│ │portrait│ │ Xin gặp vua   (title row, line 1 only)    │           │
│ │  hero  │ │ "Xin cho tôi gặp nhà vua!" (≤ 3 lines)    │ ◀ tail    │
│ └────────┘ └───────────────────────────────────────────┘           │
│  [Bỏ qua]                                [ Xin vào! ] or [ Tiếp ▶ ]│
└──────────────────────────────────────────────────────────────────┘
```

Narrator lines: a centred box 880 wide, with no portrait and no tail (ASSET-330 narrator
variant).

### 5.2 Boxes (QC r5 follow-up)

The beat's `title` (Mission flow 7d) is **inside the top of the dialogue panel**, never floating
above it, so nothing on a dialogue screen sits above `corner_bottom` + 8 (the pause/sound block,
`story-screens.md` §5.2). World px, fitted to the safe rect (Input Rule 1, so `safe_bottom` = 720).
- **Panel:** the speaker box (720 text box) or the narrator box (880), plus 32 padding all round,
  plus a **title row (60 + 8)** at its top. The title row is **reserved on every line** of the
  beat, so the panel never changes height between lines; the title text shows on line 1 only, as
  Mission flow 7d says. Height: speaker lines 32 + 68 + 154 (3 × 38 px lines at 1.35) + 32 =
  **286**; narrator lines 32 + 68 + 103 + 32 = **235**.
- **Bottom-anchored like the beat card:** panel bottom = Tiếp's top − 8.
- **Portrait:** 256 world px tall (the 384 px asset at 1.5×), bottom-aligned with the panel, on
  the speaker's side (hero left, others right), 16 from the panel.
- **Worked numbers:** at the reference (k 0.527): Tiếp 565–702; panel 271–557; portrait
  301–557; `corner_bottom` + 8 = 163, clear. **At the floor (k 0.40):** pad 180, Tiếp 522–702;
  panel 228–514; portrait 258–514; `corner_bottom` + 8 = 206, clear by 22.
- **Fit condition:** `2 × pad_min / k + 52 + 286 ≤ safe_bottom`, i.e. 698 ≤ 720 at k 0.40. An
  app whose world isn't fitted to the safe rect (so `safe_bottom` < 720 in world px) breaks it:
  that's a fit bug, not a reason to move the title out of the panel.

### 5.3 Component Inventory

| Component | Spec | Source |
|---|---|---|
| Portrait | 384×384 at 1.5×, `pic.portrait_<hero_id>_<speaker>[_<mood>]`; hero left, others right. **The hero's portrait (left) and every box start at y ≥ `corner_bottom` + 8**, below the pause/sound block, as on story screens (`story-screens.md` §5.2; QC r5) | Rule 7d; ASSET-327–329 |
| Speaker box | `dialogue_line`: 720, 38 px, weight 600, ≤ 3 lines | 005i |
| Narrator box | `dialogue_narrator`: 880, 38 px, ≤ 2 lines | 005i |
| Ask button | big gold pill (ASSET-331), story Text (e.g. C14), `button` field; release-inside; debounced | Rule 7d |
| Tiếp / Bỏ qua | as on story screens | story-screens.md |
| Pads | **none** | R13d |

## 6. States & Variants

The button on the line showing (L, 1-based) is the **ask button** while `at_line ≤ L < at_line + taps`,
otherwise Tiếp. For Bình Than {at_line 2, taps 2}: line 1 Tiếp; lines 2–3 "Xin vào!"; lines 4–9 Tiếp.

## 7. Interaction Map

- Ask or Tiếp: release-inside, a 0.25 s debounce (B1); each ask tap shows line L + 1.
- Skip: as on story screens; it counts as a skipped story (no medal this run).
- Stuck: no ask tap for `hint_delay` → the hint hand on the ask button.

## 8–10. Data, Events, Transitions

Lines with speaker, mood and text (R4c: the marked opening narrator line covers the scene's
legend lines). Events: "line shown", "ask tapped", "dialogue done". A soft slide per line, and the
portrait swaps with a 0.15 s fade. *NOT YET BUILT: iOS, Android (both swap portraits instantly).*

## 11–13. Input, Accessibility, Localization

The portrait plus the box tail shows who speaks (not colour). Every line is on screen (captions).
D-17: lines between characters may use "cậu", "cháu" or "ta"; nothing addresses the player.

## 14. Acceptance Criteria

1. **GIVEN** the Bình Than dialogue, **WHEN** played, **THEN** the button reads Tiếp on line 1,
   "Xin vào!" on lines 2–3, and Tiếp on lines 4–9; no pads are shown.
2. **GIVEN** two taps on "Xin vào!" 0.17 s apart, **WHEN** on line 2, **THEN** only line 3 shows.
3. **GIVEN** each line in VI and EN, **WHEN** captured, **THEN** the portrait is on the correct side and
   the text fits its box (720 or 880).
4. **GIVEN** Skip then "Vẫn bỏ qua" in this scene, **WHEN** the quiz finishes, **THEN** no medal.
5. **GIVEN** no tap on the ask button for `hint_delay`, **WHEN** waiting, **THEN** the hint hand points at it.
6. **GIVEN** the reference phones and a k 0.40 phone or emulator, **WHEN** lines 1, 2 (ask button) and a narrator line of the Bình Than dialogue are captured in VI and EN, **THEN** the title "Xin gặp vua" is inside the top of the panel on line 1; the panel's height is the same on every speaker line; the panel's bottom is Tiếp's top − 8; and no pixel of the panel, the title or a portrait is above `corner_bottom` + 8 (y 163 at k 0.527, 206 at k 0.40).
6. **GIVEN** the lowest target Android phone, **WHEN** a line advances, **THEN** the next line and portrait show within 150 ms; checked on the narrowest phone and a 20:9 phone.
