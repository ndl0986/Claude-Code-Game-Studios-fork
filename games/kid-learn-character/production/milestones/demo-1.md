# Milestone: Demo 1

> **Stage**: Pre-Production (gate `production/gate-checks/2026-11-20-technical-setup-to-pre-production.md`, CONCERNS accepted by Luan)
> **Decision**: K-48 (Luan, 2026-11-20), with the leader defaults Luan may change
> **Audience**: leadership and partners (outside viewers)
> **Epics**: `production/epics/index.md` (TASK-132). Stories come per epic after TASK-131's control manifest.
> **Last Updated**: 2026-11-20

## Scope

The core loop, native on **macOS and iPadOS**, with the **full Dinosaurs set: A–Z and 0–9** (36 keys):

- Title → Play (App Shell & Title), with a **simple grown-up exit** (Q2 below).
- Hardware keys on both platforms (Input & Key Filter) and the **On-screen Keyboard Row** (Q1 below).
- The **morph reveal** (MorphCore, Press Queue, Reveal Stage, Cast Rendering).
- **Voice** (Kokoro, K-41) and **creature sound** (Audio & Voice).
- The **Scene** (time of day and weather).
- **Hint Letters**.
- The **parade meter and parade** (K-44, K-45, K-46).
- The **content pipeline** the 36 items need: the bake tool, the voice bake and the validator (Content Pipeline epic).
- Cross-cutting, because outside viewers see the build: Settings Store (read on defaults), Privacy & Kids Compliance
  gates, and Accessibility's Reduce Motion, Smart Invert, touch floor and ADR-0013 flash gates.

## Out of scope (next milestone)

- **Parent Gate & Grown-up Panel** (`parent-gate-panel.md`, TR-gate-001..007).
- **Child Lock-in** (`child-lock-in.md`, TR-lock-001..005, ADR-0008).
- Their parts of in-scope systems: TR-input-003 (kiosk chord), TR-settings-004 (childLock), TR-queue-003's gate and panel
  freeze; the device rows that only they need (M-2, M-3's lock-on half, M-4 to M-7, M-9, M-16, P-4's Guided Access
  half, P-12, P-14).
- Android (TR-android-001, K-03); Theme Packs, Localization, Mash World.

## Exit criteria

1. **Playable on the child's iPad** (iPad13,4, iPadOS 27.2, K-47) **and on the Mac**: all 36 keys reveal their
   creature with its voice and sound, through hardware keys and the keyboard row, and a parade follows every 6th new
   creature.
2. **A recorded demo video** of the demo path on the iPad and the Mac, retained in `production/qa/evidence/`.
3. **No visible glitch on the demo path**: no missing art, frame hitch, audio click or pop, stuck state or debug UI,
   judged on the recorded run and on the device rows below.
4. Every Demo 1 epic's stories are closed with `/story-done` (each epic's Definition of Done), `verify.sh` is green,
   and the signed Release builds for iPadOS and macOS pass the PKC scans and ADR-0013's gates.

## Critical path

1. **Device sessions.** The weekend iPad session and a Mac session block (K-48) carry the rows that decide the three
   Proposed ADRs the Demo 1 epics depend on:
   - ADR-0010 audio: P-1, P-7 (open: the pop heard in TASK-127, TASK-128), P-8, P-9, M-14;
   - ADR-0009 render path: P-2 decisive and M-13 (the decisive iPad is chosen at release prep, K-47; Demo 1 runs
     on the child's iPad);
   - ADR-0007 input adapters, its keyboard part decided in Demo 1: M-1; **M-3's Keys half with the lock off** (Mac
     normalization, key-ups under ⌘, system keys left alone; runs in TASK-134's Mac session 1 on DeviceSpike);
     P-15 and **P-4's media-keys half** (both need an iPad hardware keyboard, which Luan doesn't have yet: NOT ASSESSED
     until one is available). M-2 and M-3's lock-on half stay with the next milestone.
   Until each is Accepted, the stories that depend on it are Blocked (or proceed on the measured candidate with
   Luan's OK).
2. **The 36 assets** (TASK-133 asset specs, then the layered SVG creatures per art bible §8), baked by the content
   pipeline; `content/themes/dinosaurs/` holds only `src/` today.
3. **The voice bake** (Kokoro, K-41): 36 item lines pre-rendered, AAC mono, loudness target, voiceDurations into the
   theme data.
4. **TASK-131's control manifest**, then the stories per epic.

## Open questions (for the leader / Luan; not decided here)

- **Q1. The keyboard row's default.** The row is off by default and turned on only in the grown-up panel (Keyboard
  Row R8, AC-1), and the panel is out of Demo 1. Options: a Demo 1 build setting that seeds `keyboardRow` on; keep it
  off on the Mac and on the iPad only when no hardware keyboard is attached (a design change); or move the panel's row
  toggle into Demo 1.
- **Q2. The "simple grown-up exit".** No GDD defines it. Without Child Lock-in the OS ways out already work (⌘Q on the
  Mac; the home gesture on the iPad without Guided Access). Options: those alone; or a minimal in-app exit to the
  Title. A new rule needs a GDD change.
- **Q3. Partial requirements** that no Accepted ADR decides yet: TR-shell-004 (status bar, home indicator, edge
  deferral), TR-hints-003 (hint knob validator rule), TR-scene-002 (weather device cost), TR-a11y-004 (A5 contrast
  for hints). Each epic lists its own.
