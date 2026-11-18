# Accessibility Requirements

> **Status**: In Design (tier proposed; Luan to confirm)
> **Author**: game-dev-android (TASK-112), from the Accessibility GDD and K-26 / K-29 / K-30
> **Last Updated**: 2026-11-18
> **Accessibility Tier Target**: **Proposed tier: Standard (Luan to confirm)**
> **Platform(s)**: iPadOS 26+, macOS 26+ (ADR-0001); Android later (its own ADR, NOT ASSESSED)
> **External Standards Targeted**:
> - WCAG 2.2: SC 2.3.1 Three Flashes or Below Threshold (Level A) is the photosensitivity gate (Accessibility F2); contrast floors per Accessibility A5
> - Apple Accessibility (VoiceOver, Dynamic Type, Reduce Motion, Smart Invert): grown-up panel and OS flags
> - AbleGamers CVAA, Xbox XAG, PlayStation guidelines: N/A (no console, no communication features)
> **Accessibility Consultant**: None engaged
> **Linked Documents**: `design/gdd/accessibility.md`, `design/gdd/systems-index.md`, `design/ux/interaction-patterns.md`, `design/ux/title-screen.md`
> **Template**: Accessibility Requirements

> **Source rule.** Every requirement below is an existing rule, cited to its owner (the Accessibility GDD collects
> them, its Summary: "cited, not restated as new rules"). This document adds no rule; where a template row has no
> rule behind it, it is marked N/A with the reason or listed in Open Questions.

---

## Accessibility Tier Definition

### Tier Definitions

| Tier | Core Commitment | Typical Effort |
|------|----------------|----------------|
| **Basic** | Critical player-facing text is readable at standard resolution. No feature requires color discrimination alone. Volume controls exist for music, SFX, and voice independently. The game is completable without photosensitivity risk. | Low — primarily design constraints |
| **Standard** | All of Basic, plus: full input remapping on all platforms, subtitle support with speaker identification, adjustable text size, at least one colorblind mode, and no timed input that cannot be extended or toggled. | Medium — requires dedicated implementation work |
| **Comprehensive** | All of Standard, plus: screen reader support for menus, mono audio option, difficulty assist modes, HUD element repositioning, reduced motion mode, and visual indicators for all gameplay-critical audio. | High — requires platform API integration and significant UI architecture |
| **Exemplary** | All of Comprehensive, plus: full subtitle customization (font, size, color, background, position), high contrast mode, cognitive load assist tools, tactile/haptic alternatives for all audio-only cues, and external third-party accessibility audit. | Very High — requires dedicated accessibility budget and specialist consultation |

### This Project's Commitment

**Target Tier**: **Proposed tier: Standard (Luan to confirm)**

**Rationale**: The player is 2.5–3 and cannot read, and a grown-up sets the device up (Accessibility Overview), so
the template's tiers fit only partly: the child's side has no text at all (art bible §7, K-22), so subtitles, text
size and remapping have nothing to act on there, and the design already meets several *Comprehensive* items (a
Reduce Motion mode that follows the OS, A1–A3; VoiceOver on the grown-up panel, A8; a visual answer for every sound,
A9; no meaning by colour alone, A6; the WCAG 2.3.1 flash gate, A4 / F2). **Standard** is proposed because its intent
holds once each item is read for this game: every key and tap answers, so there is no binding to remap (Input R2–R3);
no colour carries meaning alone, so no colourblind mode is needed (A6); text is only on the grown-up side, where
Dynamic Type applies (A8); the one timed input (the 1.5 s moon hold) has the Mac chord and Switch Control pause as
documented alternatives (A8, K-29). Two template baselines are **not** met by the GDDs and are recorded as
limitations for Luan rather than changed here: independent volume per bus (Basic) and captions (K-30).

**Features explicitly in scope (beyond tier baseline)**:
- Reduce Motion, read live from the OS, never an in-app switch (A1; art bible §7); per-system rules (A3).
- Photosensitivity gate on captured frames, F2 (A4; WCAG 2.3.1), plus the F1 rate lint on every build.
- VoiceOver and Dynamic Type on the grown-up panel (A8; Parent Gate G3, G7).
- Child touch floor 18 mm (A7; Hint Letters F5; On-screen Keyboard Row F2).
- Smart Invert: the stage opts out, the panel follows (A10; K-30).

**Features explicitly out of scope**:
- Captions (K-30; A9): the child cannot read; the glyph and creature are the visual equivalent.
- Increase Contrast (K-30; A10): not in the MVP; the A5 floors are the contrast design.
- Independent volume per bus: one volume and mute only (Settings Store R1) — see Known Intentional Limitations.
- An in-app Reduce Motion switch (A1: follow the OS; Settings Store R1 is closed).

---

## Visual Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Text on the child's side | — | Title, Play | N/A by design | No text at all (art bible §7; App Shell R2, K-22). |
| Text size — grown-up panel | Standard | Parent Gate challenge and panel | Designed | Dynamic Type; the panel scrolls, the keypad keeps its size (A8; Parent Gate AC-32). Bold Text through Dynamic Type; bold weight of the bundled font NOT ASSESSED (A10, Q5). |
| Contrast — glyph | Basic | Reveal | Designed | ≥ 3:1 at crossfade ends; ≥ 2.5:1 inside crossfades (K-25 exception); build check (A5; Cast Rendering R5). |
| Contrast — hints, tokens, panel | Basic | Play, panel | Designed | Letter Gold on cream ≈ 4:1; panel controls 6.5:1 (A5; art bible §4). |
| Contrast — moon ring | Basic | Title, Play | Designed (trade-off) | ≈ 2.5:1 on the day sky; length and hold time carry it (A5; Luan 2026-11-17). |
| Colourblind backup cues | Basic | Every colour meaning | Designed | A6 table; outline traits for R / U / V under deuteranopia (art bible §3, §4). |
| Reduce Motion | Comprehensive | Every moving system | Designed | A1–A3 (owners' rules, collected). |
| Photosensitivity | Basic | Whole stage | Designed; device gate NOT ASSESSED | F1 lint every build; F2 on frames, K-26 busy case (A4; AC-08 device run pending). |
| Smart Invert | — | Stage / panel | Designed | Stage opts out, panel inverts (A10; K-30; Reveal Stage R1). |
| Increase Contrast / Reduce Transparency | — | — | Out of scope / no effect | K-30; A10. |

### Color-as-Only-Indicator Audit

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| Reveal glyph | Letter Gold | a letter or number | largest, centred, outlined, spoken | Resolved (A6) |
| Press point | Starlight | "I heard you" | four-point star + chime | Resolved (A6) |
| Hint vs queued token | the same gold on cream | hint vs waiting | drifting rounded square vs small circle in a still row | Resolved (A6) |
| Cast member | hue slot | which creature | silhouette trait + spoken name | Resolved (A6) |
| Moon | progress ring | gate progress | ring length + hold time | Resolved (A6) |
| Panel switches | control tint | on / off | On / Off text | Resolved (A6; Parent Gate) |

---

## Motor Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Input remapping | Standard | Child input | N/A by design | Every letter and digit key is a press, by character with a position fallback; any tap (except the moon) answers (Input R2–R3, R7; App Shell R3). There is no binding to remap. |
| Child touch targets | Standard | Hints, keyboard-row keys | Designed | 18 mm physical floor; hint 27–31 mm on iPads; row key 144 × 134 units (A7; Hint Letters F5; Keyboard Row F2). |
| Non-targets | — | Play button, cast tap, empty stage | Designed | Any touch answers, so no floor is needed (A7; App Shell R3). |
| Grown-up targets | Standard | Panel, keypad, moon | Designed | ≥ 44 pt; keypad 60 pt keys, 12 pt gaps; moon ≥ 44 pt + 20 pt slop (A7; Parent Gate G1, G3, G7). |
| Hold-to-press alternatives | Standard | The moon hold (1.5 s) | Partial (documented) | Mac: the ⌃⌥⌘Q chord replaces the hold; iPad: pause Switch Control to open the gate (A8; K-29). VoiceOver's double-tap-and-hold is the hold (A8). |
| Rapid input | — | Mashing | N/A | Mashing is allowed, never required (Press Queue; K-26). |
| Switch Control / AssistiveTouch | Standard | Grown-up side | Accepted limitation | K-29; A8; see Known Intentional Limitations. |

---

## Cognitive Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Nothing to read or learn | — | Child side | Designed | No text, one icon (the play button), any press answers (art bible §7; App Shell R2–R3). |
| Pause anywhere | Basic | Play | Designed | The gate challenge freezes play (K-20; Reveal Stage R8); the background settles it (App Shell R6). |
| Reading time / auto-dismiss | Standard | Grown-up notices | Designed | The "Child lock is OFF" notice shows a few seconds and carries no action (Settings Store R8; Parent Gate). The panel auto-closes after 60 s (K-19). |
| Calm load | — | Stage | Designed | Busy moments are bounded: hints dim and hold during a parade (K-26); weather unchanged. |

---

## Auditory Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Captions / subtitles | Basic | Voice lines | Out of scope (K-30) | The child cannot read; the glyph and creature show what the voice says (A9). |
| Visual answer for every sound | Comprehensive | Every Audio R1 event | Designed | Audio R5; art bible §7; AC-14 (sound-off screenshots). |
| Silent mode | — | iPad | Designed | Respected (K-13; Audio R6); a static hint in the panel (App Shell R5). |
| Independent volume per bus | Basic | Music / SFX / voice | **Not met** | One volume (0–10) and mute (Settings Store R1). Recorded below for Luan. |
| Mono audio | Comprehensive | Output | Met by design | Every buffer is decoded mono (Audio R4; A9). |
| Loudness | — | All sounds | Designed | voice −16 LUFS, cast −20, chime −26, ping −30, parade −22, ≤ −1 dBTP (K-13; A9). |

### Gameplay-Critical SFX Audit

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| E1 chime (accepted press) | "I heard you" | Starlight star at the press point; the reveal | No | Resolved (A6, A9) |
| E2 ping (ignored press, queue full) | press not taken | sparkle; a touched hint stays and restarts its life | No | Resolved (Hint Letters R8; Reveal Stage) |
| Letter / number voice | which letter, which word | the glyph and the creature | No (K-30) | Resolved (A9) |
| E5 title chime | play is starting | the play button lights fully | No | Resolved (App Shell R3) |

---

## Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| iPadOS | UIAccessibility | Reduce Motion flag; VoiceOver + Dynamic Type on the panel; Smart Invert opt-out on the stage; Guided Access status | Designed | A1, A8, A10; Child Lock-in R8 |
| macOS | NSWorkspace accessibility options; AppKit accessibility | Reduce Motion flag; VoiceOver on the panel | Designed | A1, A8 |
| Android | Settings.Global / TalkBack | "Remove animations" flag; TalkBack on the panel | NOT ASSESSED | A1, A10; its ADR |
| Xbox / PlayStation / Steam / PC screen readers | — | — | N/A | Not target platforms (ADR-0001) |

---

## Per-Feature Accessibility Matrix

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| Key Table & Theme Data | content colours in F2b palette scope | — | toddler-safe content (T-rules) | voice line lengths | Yes | Key Table §7; A4 F2b |
| Input & Key Filter | — | any key / tap answers | nothing to learn | — | Yes | Input R2–R7 |
| MorphCore | reduced timing set | — | — | — | Yes | A3 (MorphCore Rule 8) |
| Settings Store | — | — | — | one volume only | Partial | Settings Store R1; see Limitations |
| Privacy & Kids Compliance | — | — | — | — | Yes | A11 (nothing stored, sent or logged) |
| Audio & Voice | visual answer per sound | — | — | silent mode, mono, loudness | Yes | A9 |
| Press Queue | — | mashing never required | hold stays 3 s | — | Yes | A3; K-15 |
| Cast Rendering | halo, idles, twinkle under RM | — | — | — | Yes | A3; K-16, K-29 |
| Reveal Stage | RM motion; Smart Invert opt-out | — | freeze for the gate | — | Yes | A3, A10; K-20 |
| Hint Letters | RM: no drift / pulse | 18 mm floor | dim during parade | — | Yes | A3, A7; K-26 |
| Parade | RM: bob × 0.5 | — | — | — | Yes | A3; K-17 |
| Parent Gate & Grown-up Panel | contrast, Dynamic Type | 44 pt; moon hold alternatives | — | silent-mode hint | Yes | A7, A8; K-29 |
| Child Lock-in | — | Mac chord way out | — | — | Yes | Child Lock-in R5 |
| App Shell & Title | breathe × 0.5 under RM; no text | play button needs no floor | nothing to read | — | Yes | App Shell R2–R3 |
| Scene: Time of Day & Weather | contrast check; RM weather | — | — | — | Yes | A3, A5; K-24, K-25 |
| On-screen Keyboard Row | — | 18 mm floor | short common word | — | Yes | A7; K-29 |
| Accessibility | owns the flag and F2 | — | — | — | Yes | this GDD |
| Theme Packs, Localization, Mash World | — | — | — | — | Not yet designed | Post-MVP systems (systems index); add rows when their GDDs exist |

---

## Accessibility Test Plan

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| One flag | Unit + code review | inject the flag against a mocked OS value | every A3 system follows the flag | QC | Accessibility AC-01 |
| Toggle timing | Unit | flag on mid-reveal | reveal keeps its set; ambient changes next frame | QC | AC-03 |
| Rate lint (F1) | Build check | shipped data; 1.2 Hz and 3.0 Hz fixtures | passes; fixtures fail | build | AC-05 |
| Flash gate (F2) | Frame capture + detector | K-26 busy case, Night/Day, rain/snow, RM off/on | no FAIL; Simulator every build, device release gate | QC | AC-07, AC-08 (device NOT ASSESSED) |
| Red flash (F2b) | Palette check | art bible, theme data, SVG fills | max R/(R+G+B) < 0.8 | build | AC-09 |
| Contrast | Build check | Scene 160 cases; palette | A5 floors | build | AC-10 |
| No colour-only meaning | Manual, greyscale screenshots | A6 rows | backup cue visible | QC | AC-11 |
| Child touch floor | Unit | every MVP device class | ≥ 18 mm | QC | AC-12 |
| Grown-up targets | UI test | panel, keypad | ≥ 44 pt; 60 pt / 12 pt | QC | AC-13 |
| Sound off | Manual, screenshots | 2-min seeded session muted | a visual answer per Audio R1 event | QC | AC-14 |
| Smart Invert | Manual, screenshot pair | stage + panel | stage unchanged, panel inverted | QC | AC-15; device row P-13 |
| Privacy | Release scan | stored values, network, logs | no accessibility setting carried | QC | AC-16 |

---

## Known Intentional Limitations

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| Captions | Basic | The child cannot read (K-30) | none for the child; a hearing grown-up loses nothing actionable | glyph + creature are the visual equivalent (A9) |
| Independent volume per bus | Basic | Settings Store R1 has one volume and mute | a grown-up cannot lower music without lowering the voice | **Open for Luan** (OQ-1); one slider + mute today |
| Increase Contrast | — | K-30: not in the MVP | low; A5 floors are designed | revisit after the MVP |
| Switch Control / AssistiveTouch on the moon hold | Standard | K-29: accepted for the MVP | an iPad grown-up must pause Switch Control to open the gate | documented; the Mac chord replaces the hold |
| VoiceOver on the child's stage | — | the child side has no text (A8) | unknown behaviour of VoiceOver gestures during play | NOT ASSESSED (Accessibility Q4) |

---

## Audit History

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| — | — | — | — | No audit yet; the device gates (AC-08, AC-15) wait for device time | Pending |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.2 | https://www.w3.org/TR/WCAG22/ | SC 2.3.1 and its flash definitions (Accessibility F2, read 2026-11-18) |
| Apple Accessibility for developers | https://developer.apple.com/accessibility/ | VoiceOver, Dynamic Type, Reduce Motion, Smart Invert |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | general checklist |
| Colour Blindness Simulator (Coblis) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | screenshot checks for A6 |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| OQ-0 Confirm the accessibility tier (proposed: Standard) | Luan | before the Pre-Production gate | — |
| OQ-1 Independent volume per bus (Basic baseline) vs today's single volume + mute (Settings Store R1) | Luan (Settings Store owner) | before the Pre-Production gate | — |
| Device time for the flash gate on a real iPad and Mac (Accessibility Q3, AC-08) | Luan | before release | — |
| VoiceOver left on during play (Accessibility Q4) | QC, on a device | before release | — |
| Bold weight in the bundled font (Accessibility Q5) | art / lead programmer | before the panel story | — |
