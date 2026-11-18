# Cross-GDD Review Report

Date: 2026-11-18
Task: TASK-055 (`/review-all-gdds`, full). Reviewer: game-qc-android (author of none of these GDDs).
Settings: review mode lean, workflow standard (`games/kid-learn-character/project.yaml`: `modes.rigor: standard`).
Inputs at: `origin/docs/kid-learn-character-plan` @ 801a2fd.
GDDs Reviewed: 15 of 15 present
Not read: none. The reviewers read section ranges, with no whole-file reads (the 40 KB rule). The coverage gaps are listed under "Not checked" below.
Focus: full (consistency and design theory, plus the scenario walkthrough)
Systems Covered: Key Table & Theme Data, Input & Key Filter, MorphCore, Settings Store, Privacy & Kids Compliance,
Audio & Voice, Press Queue, Cast Rendering, Reveal Stage, Hint Letters, Parade, Parent Gate & Grown-up Panel,
Child Lock-in, App Shell & Title, Scene: Time of Day & Weather.
Also read: `game-concept.md` (pillars, anti-pillars), `systems-index.md`, `production/team/decisions.md` (K-01…K-25),
`design/art/art-bible.md` §1, §2 and §7.

Entity registry: absent (`design/registry/entities.yaml` does not exist), so the consistency checks rest on GDD reads
alone. Run `/consistency-check` later to build a registry.

**How it was run.** Three `game-designer` reviewers worked in parallel:
- (1) clocks and the freeze / panel / background matrix;
- (2) the child-lock chain, dependency bidirectionality, stale references, and restated numbers and knobs;
- (3) design holism, checks 3a–3g.

The skill asks for GDD content to be pasted into each reviewer. Here they were given file paths and read the sections
themselves instead, because the set is about 525 KB. game-qc-android checked every Blocking finding, and each Warning
marked "verified", against the text at 801a2fd, and ran the scenario walkthrough (Phase 4).

**Known nits.** These are already queued and are not reported again. All four were confirmed as still present:
- Scene's Cast Rendering row says "(follow-up)" and has no `skyMidL`;
- the hysteresis floor is 2.53 vs 2.57 (Cast Rendering F8, art bible K-25 block);
- the K-25 time windows;
- the Privacy PKC-09 continuous-clock note.

---

### Consistency Issues

#### Blocking (must resolve before architecture begins)

🔴 **B-1 · The Mac parent chord: does Fn count?** (Input & Key Filter ↔ Parent Gate & Panel)
- `parent-gate-panel.md` §G2: "Shift, Caps Lock and Fn are not "other keys" (Input R6 ignores Shift)."
- `input-key-filter.md` §R6: "**⌃⌥⌘Q**, exactly those three modifiers plus Q (Shift ignored)". §R3: "**Disqualifying:**
  any of Ctrl, Alt/Option, Cmd/Meta, Fn".
- With Fn held, the Parent Gate says the chord opens the gate and Input (the rule's owner) says it doesn't. Neither
  set of ACs settles it: Parent Gate AC-03 tests only Shift and Caps Lock, and Input AC-1j tests neither.
- The risk is low (the moon always works), but this is the kiosk way out, and the two rules can't both be built.
- **Options:** (a) Input R6 also ignores Fn, and AC-1j adds a Fn case; (b) G2 drops Fn from its list. One line either
  way. This is the team's call, not Luan's.

#### Warnings (should resolve, but won't block)

⚠️ **W-1 · The Mac lock after an engage failure: ⌘ swallowing and Quit are undefined** (Child Lock-in ↔ Input ↔ Parent Gate), verified
- Child Lock-in §R7: on timeout, "the state goes to **Off** with the **failure flag** set"; `childLockActive` is
  "unchanged" (R4 table). It doesn't say what happens to Input's kiosk-on mode.
- Input §R5: "While `childLockActive` is true … ⌘-combinations are swallowed **in every state**".
- Parent Gate §G7: Quit is shown "Quit only while the lock is on", which doesn't say whether "on" means
  `childLockActive` or the Locked state.
- Result: a Mac that looks unlocked (Dock and menu bar visible), where ⌘Q does nothing, and possibly no Quit button.
  It is not a trap: no presentation options were applied, the mouse can still use the menu bar, and the panel can
  turn the lock off.
- **Options:** (a) Child Lock-in R7 states the kiosk-on mode and the ⌘ behaviour on timeout, and G7 defines "lock on";
  (b) Input keys its ⌘ swallowing on one signal only, and AC-1k / AC-1k2 merge.

⚠️ **W-2 · Cancel and Esc return to the gate's origin in the Parent Gate only**
- `parent-gate-panel.md` §G9 ("the same for a challenge closed without the panel") and AC-31 (chord on Title, then
  Cancel → Title).
- `input-key-filter.md` States (Gate challenge) and AC-1k4, and `app-shell-title.md` States, cover only "wrong answer
  or timeout".
- **Option:** add Cancel and Esc to Input's Gate challenge row and AC-1k4, and to App Shell's Gate row.

⚠️ **W-3 · Cast Rendering names the wrong clock for `s` and `idleTime`**, verified
- `cast-rendering.md` §R3: "**Time:** seconds on the platform's monotonic uptime clock (Input R8, Press Queue R5)."
- `reveal-stage.md` §R8, the owner: "`play = uptime − frozenTotal`. Every time the Reveal Stage uses (frame times,
  `r0`, `s`, cooldowns) … is on this clock."
- The two clocks part during the gate-challenge freeze. Cast Rendering only receives `s` from its caller, so nothing
  diverges at run time, but the text points a programmer at the wrong clock.
- **Option:** R3 says "`s` and `idleTime` are play-clock values supplied by the caller (Reveal Stage R8)". The
  wall-clock edge dissolve stays as it is.

⚠️ **W-4 · The challenge timeout has no named clock**, verified
- `parent-gate-panel.md` §G3 ("`challenge_timeout_s` (20 s) …") runs while §G5 freezes the play clock, so it can't be
  on the play clock. Its sibling timers each name theirs (moon sleep: continuous; `t_held`: event timestamp).
- **Option:** name it: uptime (background cancels the challenge anyway), or continuous to match moon sleep.

⚠️ **W-5 · The Parent Gate doesn't name the panel's hint freeze that Hint Letters relies on**, verified
- `hint-letters.md` §R9: "**Panel open** | frozen under the dim (K-18) | stopped"; Dependencies: "the challenge
  **and panel** freezes".
- `parent-gate-panel.md` Interactions, Hint Letters row: "challenge open → **freeze `hintTime`**, close → resume" (no
  panel). §G6 doesn't list it either.
- **Options:** add "panel open → freeze, close → resume" to that row; or Hint Letters says it observes
  `panelWillOpen` / `panelDidClose`.

⚠️ **W-6 · "Key Table R3" points at the wrong section, in 7 GDDs**, verified
- `key-table-theme-data.md` has no R-numbered rules. Its core rules are "#### 1." to "#### 7.", and "#### 3." is
  "Numbers". The item pick and `lastShown` are in "#### 4. Picking the item for a key".
- Cited as R3 for the pick rule or `lastShown` in:
  - `parent-gate-panel.md` §G7;
  - `press-queue.md` (the ownership table, R3, line 302);
  - `reveal-stage.md` (§R2 step 1, line 320);
  - `hint-letters.md` (R9 theme row);
  - `cast-rendering.md` (line 204);
  - `settings-store.md` (lines 66 and 235).
- `hint-letters.md` §R4 cites "Key Table R4" correctly.
- Downgraded from the reviewer's Blocking: the rule exists and each citing GDD restates the behaviour (resolve at
  reveal start, with the theme active now). Only the pointer is wrong.
- **Options:** change the citations to "Key Table §4", or number Key Table's sections R1–R7 so that the pick is R4,
  and fix them all.

⚠️ **W-7 · The parade count is "every 8" in two documents; K-17 says 6**, verified
- `game-concept.md` lines 89, 146 and 318, and `systems-index.md` line 40, say "every 8 new cast members met".
- K-17 ("A parade every 6 creatures met") and `parade.md` §R2 (`parade_count` 6) agree with each other.
- **Option:** sync both documents to 6. A text-only edit.

⚠️ **W-8 · One knob name with two owners and two meanings**
- `mash_window_s`: Audio (F3 loudness window) and Scene (weather thinning) each claim it. The values agree (1 s).
- `moon_slop_pt`: Input gives the safe range 10–40 (owner "Input / Parent Gate"), the Parent Gate 10–30, verified.
- **Options:** rename one `mash_window_s` (e.g. `weather_mash_window_s`) or make it one shared knob; give
  `moon_slop_pt` one owner and one range.

⚠️ **W-9 · The systems index and several Dependencies sections are one-sided or stale** (2a, 2c)
- **Index (Draft):**
  - Child Lock-in lists Input and Parent Gate, but the GDD has upstream Settings Store, Input and App Shell, and
    Parent Gate as a peer.
  - App Shell is called a "leaf", but Child Lock-in waits for its "ready".
  - Scene sits in the Core layer but reads the Reveal Stage and the Parade.
  - Press Queue and Parade list fewer upstreams than their GDDs.
- **One-sided links:**
  - Cast Rendering's Dependencies list neither Scene (its F8 uses Scene F1/F2) nor App Shell;
  - Scene doesn't name Privacy & Kids Compliance (which names Scene);
  - Input's Downstream table doesn't list App Shell;
  - Parade labels Scene as upstream, but Scene is what reads `paradeWalking`.
- **"No GDD yet" for GDDs now approved:**
  - Reveal Stage, about Hint Letters;
  - Parade, about the Reveal Stage;
  - Press Queue's peer list;
  - Settings Store;
  - Input's leader note;
  - Parent Gate's Dependencies line "the exact chord (from the held set)" (TASK-054 I1 changed this).
- **Stale "(follow-up)" and "today" markers:**
  - `reveal-stage.md` §R8: "Audio is asked to pause its players (follow-up)", though Audio's freeze rule and AC-21
    define it;
  - `parent-gate-panel.md` §G1: "Input R7 emits only began/ended today";
  - §G11: "#13 is the next GDD";
  - `child-lock-in.md` AC-6: "after the Input follow-up".
- **Option:** one text-only sweep. Add it to the next follow-up batch.

⚠️ **W-10 · Smaller lock-chain wording gaps**
- `child-lock-in.md` §R2's list of "every Input state" leaves out the Title (Input R5 includes it).
- Settings Store AC-15 checks fewer launch preconditions than Child Lock-in AC-1 (the rules agree, since R8 defers
  to Child Lock-in R3).
- `app-shell-title.md` Interactions says "`childLock` for Child Lock-in", though Child Lock-in reads
  `childLockActive`.
- `panelWillOpen` is listed as an input to Child Lock-in, but no rule uses it.

ℹ️ **Info**
- The play clock's behaviour under the panel ("the panel is not a freeze") is stated by Scene §R9, not by its owner,
  Reveal Stage §R8. Add one line to R8.
- Scene's Cross-References cite "cast-rendering R11 (device measurement)", but R11 is the SVG-rendering choice.

---

### Game Design Issues

#### Blocking
None. Checks 3a (one clear point: press → creature), 3c (no degenerate input), 3d (bounded queue; batch in memory
only), 3f (no anti-pillar violation in a child-facing system) and 3g (both the child's and the grown-up's fantasies
are coherent) found nothing blocking.

#### Warnings
⚠️ **W-11 · No overall cap at the busiest moment (Pillar 1 vs Pillar 3)**, decision for Luan
- When a press lands during a parade on a windy-snow day, all of this moves at once:
  - the parade (6 walkers with a step bob, and its tune);
  - the reveal (a glyph halo at ~2.2 Hz, 240 specks twinkling at ~1.4 Hz, the creature forming, cast and voice
    sounds);
  - 3 hint bubbles still drifting (`hint-letters.md` §R9 freezes hints for the panel, the gate and the background,
    not for a parade);
  - up to 3 queue tokens;
  - up to 60 snowflakes;
  - up to 7 sounds (`audio-voice.md` §R2).
- Each channel has its own ceiling (the weather thins while mashing, sky and frame brightness caps, the audio cap, and
  the hint pulse stops after the first press), but nothing caps the total. The art bible calls the parade "the only
  energy-4 moment", and it is designed to stack on a reveal.
- **Options:** (a) hints fade or freeze while a parade walks; (b) the weather thins during a parade too; (c) keep as
  played (Luan's favourite moment) and add it as a named playtest check.

ℹ️ **Info**
- A child who presses only a favourite key never reaches 6 distinct keys, so never sees a parade (K-17: "A key pressed
  again within the same batch counts once"). This is consistent with the parade being a surprise, but should be
  accepted on purpose.
- Parades are uncapped (K-17). That fits the "NOT endless reward loops" anti-pillar because the parade is a surprise,
  not a reward (`parade.md` Player Fantasy).
- The third queued key waits up to ~11.5 s (`press-queue.md` F4). Each press is still acknowledged at once, so
  Pillar 1 holds. Watch it in playtest.
- Tapping the creature replays its sound without limit. One cast sound at a time (Audio §R2), so nothing stacks.

---

### Cross-System Scenario Issues

Scenarios walked: 6
1. A palm on the moon mid-reveal, with the queue [B, C] and a parade walking → challenge → timeout.
2. The correct code mid-parade and mid-reveal → panel → weather and theme changed → close.
3. A locked Mac: launch → Title → chord → Cancel (and with Fn held).
4. A locked Mac whose lock can't engage (a precondition still missing after 5 s).
5. The app sent to the background mid-parade for 5 min, and again for 31 min with the device asleep.
6. A mash burst during a parade on a windy-snow day.

#### Blockers
🔴 **Scenario 3: Parent Gate, Input, Child Lock-in.** With Fn held, the chord's result differs by GDD. This is B-1.

#### Warnings
⚠️ **Scenario 1: Parent Gate, Reveal Stage, Press Queue, Hint Letters, Parade, Audio, Scene.**
- The freeze fans out cleanly. Queue, reveal frame, `hintTime`, parade `pt` and E12 all hold, Audio pauses every
  player, Scene motion holds, and nothing replays on resume. Moon sleep then runs 10 s on the continuous clock.
- The only gap is the clock the 20 s timeout runs on (W-4).

⚠️ **Scenario 2: Parent Gate, Press Queue, Reveal Stage, Parade, Audio, Hint Letters, Scene.**
- K-15 applies: the queue clears and the reveal settles. The parade fades and counts as played, Audio cuts. Weather
  fades over 2 s under the dim (K-24), and Scene keeps moving (the panel is not a freeze).
- Hints are frozen per Hint Letters, but the Parent Gate never says it drives that (W-5). The order of the clear,
  fade and cut on panel open is unstated, but they act on separate state, so it doesn't matter.

⚠️ **Scenario 3: the same systems.** Cancel returning to the Title is defined only in the Parent Gate (W-2).

⚠️ **Scenario 4: Child Lock-in, Input, Parent Gate.** After the timeout: the lock shows Off, ⌘ is swallowed, and
Quit's visibility is undefined (W-1). The grown-up has a way out (the menu bar by mouse, the panel switch), but the
state is incoherent.

⚠️ **Scenario 6: Parade, Reveal Stage, Hint Letters, Scene, Audio, Press Queue.** The attention load is W-11. The
mash rule itself holds: 1 started, 3 queued, the rest ignored with sparkles and a softer ping.

#### Info
ℹ️ **Scenario 5: App Shell, Reveal Stage, Audio, Hint Letters, Parade, Input.**
- The background cascade is ordered (App Shell §R6): settle → Audio cut → hints cleared → parade dropped (counts as
  played) → Input cleared.
- After 5 min, Play returns with the settled creature and three fresh hints (the pulse does not reset).
- After 31 min, on the continuous clock (K-22), the app goes to the Title, and the next entry to Play resets the pulse.
- Consistent across all the GDDs.

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| input-key-filter.md | B-1 (Fn in R6); W-1 (one ⌘ signal); W-2 (Cancel/Esc origin); W-8 (`moon_slop_pt` range); W-9 (App Shell downstream, leader note) | Consistency | Blocking |
| parent-gate-panel.md | B-1 (Fn in G2); W-1 (G7 "lock on"); W-4 (timeout clock); W-5 (panel hint freeze); W-6 (Key Table R3); W-9 (stale markers) | Consistency | Blocking |
| child-lock-in.md | W-1 (R7 kiosk mode on timeout); W-9 (AC-6 marker); W-10 (R2 Title, `panelWillOpen`) | Consistency | Warning |
| cast-rendering.md | W-3 (clock); W-6; W-9 (Scene and App Shell dependencies) | Consistency | Warning |
| reveal-stage.md | W-6; W-9 ("no GDD yet", Audio "(follow-up)"); play clock under the panel (Info) | Consistency | Warning |
| press-queue.md | W-6; W-9 (peers stale) | Consistency | Warning |
| hint-letters.md | W-6 (R9 theme row); W-11 (parade freeze, if Luan picks (a)) | Consistency / Design | Warning |
| settings-store.md | W-6; W-9; W-10 (AC-15) | Consistency | Warning |
| app-shell-title.md | W-2; W-10 (`childLock` wording) | Consistency | Warning |
| scene-time-weather.md | W-8 (`mash_window_s`); W-9 (Privacy dependency, R11 cite) | Consistency | Warning |
| audio-voice.md | W-8 (`mash_window_s`) | Consistency | Warning |
| parade.md | W-9 (Scene direction, "no GDD yet") | Consistency | Warning |
| game-concept.md, systems-index.md | W-7 ("every 8"); W-9 (index edges and layers) | Consistency | Warning |

The systems index was **not** changed. The leader's instruction for TASK-055 was to write only this report.

---

### Verdict: FAIL

One Blocking issue (B-1) must be resolved before architecture begins. It is a one-line rule edit. Eleven Warnings
remain, nearly all text-only sweeps, plus one design decision for Luan (W-11).

### If FAIL — required actions before re-running
1. B-1: make Input §R6 and Parent Gate §G2 agree on Fn in ⌃⌥⌘Q, and add the Fn case to Input AC-1j and Parent Gate
   AC-03.
2. After that, a `since-last-review` run (or a leader check of the diff) is enough. W-1…W-10 can go in one follow-up
   batch, and W-11 waits for Luan.

### Not checked (coverage gaps, not clean results)
- Audio's Cross-References to Key Table V7, V12 and T5–T7, and to MorphCore F1, F3 and F6.
- Parade's references to Audio E12, F2 and F6, and to Key Table's numbers and "0" item.
- Scene's references to Reveal Stage R8, R10 and F1.
- Documents outside the GDDs named in Cross-References tables.
- Stage coordinates (glyph 640,320; play button 640,520; lane y 558) against Scene and Hint Letters.
- Cast Rendering's step-bob values.
- Full rule-contradiction scans (2b) of Key Table, MorphCore and Privacy beyond the clock, freeze and lock themes.

### Decisions for Luan
- **W-11:** at the parade + reveal + hints + weather peak, keep as played or calm it, with options (a)–(c) above.
- Confirm on purpose: a favourite-key-only child never sees a parade (K-17, Info).

---

## Re-run — 2026-11-18 (after TASK-056)

Task: TASK-055 re-run. Reviewer: game-qc-android. Base: `origin/docs/kid-learn-character-plan` @ c64d6c6. TASK-056
landed in four parts: 056a 7663676, 056b efe9997, 056c 7352682, 056d f4ccb4a. The leader's index fix is 27a12d4, and
K-26 is in d91fc9e.

**Scope** (the `since-last-review` mode):
- every finding above (B-1, W-1…W-11), checked against the merged text;
- every change since 801a2fd in the 13 GDDs that changed, plus the concept doc, the systems index and the art bible;
- anything the fixes introduced, looked at hardest in the `kioskModeOn` chain (Input, Child Lock-in, Parent Gate,
  App Shell, Settings Store) and the Hint Letters Dimmed/Frozen states.

Key Table & Theme Data and MorphCore have not changed since the first run. Their "Not checked" items above are carried
over: still unchecked, not clean.

GDDs Reviewed: 15 of 15 present (13 changed, re-read in their changed sections; 2 unchanged). Not read: none.

### Status of the first-run findings

| ID | Status | Evidence at c64d6c6 |
|---|---|---|
| B-1 Fn in the chord | **Resolved** | Input §R6: "Shift and Caps Lock are ignored; Fn disqualifies" (K-26); AC-1j has an Fn case. Parent Gate §G2: "Fn disqualifies it … (Input R6 and AC-1j)"; AC-03 adds "with Fn held THEN nothing opens" |
| W-1 Engage failure | **Resolved** | One signal, `kioskModeOn` (Child Lock-in §R7: on in Waiting, Locked and Suspended, off in Off, including after the timeout). Input §R5 keys all ⌘ swallowing on it, and AC-k covers "`childLockActive` true but the mode off → pass to system". Parent Gate §G7 shows Quit "exactly while `kioskModeOn` is on", and AC-28 matches. Either ⌘Q works or Quit is shown, so the grown-up always has a way out |
| W-2 Cancel/Esc origin | **Resolved** | Input States (Gate challenge) and AC-1k4; App Shell §R5, the States Gate row and Edge Cases |
| W-3 Cast Rendering clock | **Resolved** | Cast Rendering §R3: "`s` and `idleTime` are **play-clock** values supplied by the caller (Reveal Stage R8)" |
| W-4 Timeout clock | **Resolved** | Parent Gate §G3: on the continuous monotonic clock, with the reason given |
| W-5 Panel hint freeze | **Resolved** | Parent Gate §G6 and the Interactions Hint Letters row |
| W-6 "Key Table R3" | **Resolved** | No "Key Table R3" left in any GDD; the citations read §4 |
| W-7 "every 8" | **Resolved** | game-concept.md says 6 (K-17) in all three places; the systems index too |
| W-8 Knob owners | **Resolved** | Audio F3 uses `chime_window_s`; `mash_window_s` is the Scene's (Reveal Stage R10 cites it). Input owns `moon_slop_pt` 10–40, and the Parent Gate cites it |
| W-9 Index and stale markers | **Resolved** | The index rows and layers are fixed (Child Lock-in upstreams, App Shell not a leaf, Scene's reads); the one-sided dependencies are added; no "no GDD yet", "(follow-up)" or "is the next GDD" is left |
| W-10 Lock wording | **Resolved** | Child Lock-in §R2 includes the Title; `panelWillOpen` is dropped from Child Lock-in (still published for others); Settings AC-15 checks all six preconditions; App Shell names `childLockActive` |
| W-11 Busy moment | **Resolved by K-26** | Hint Letters §R6/§R9 and the Dimmed state: hints dim to 0.5 and hold still while the parade walks; still tappable, no replay. Frozen leaves to Dimmed if `paradeWalking` is still on. Parade Downstream names Hint Letters |
| Info: play clock under the panel | **Resolved** | Reveal Stage §R8: "Under the panel the play clock runs" |
| Known nits (skyMidL, 2.53, K-25 windows, PKC-09) | **Resolved** | Scene and Cast Rendering rows, Cast Rendering F8 and the art bible (2.53:1 shown-edge floor; 16:06–16:10 and 06:06–06:09 in clear weather), PKC-09's continuous-clock note |

### New findings from the fixes

No Blocking findings and no Warnings.

ℹ️ **R-1 · App Shell's "ready" lists `kioskModeOn`, which is now Child Lock-in's own output** (`app-shell-title.md`
§R1 step 5 and F1 `t_ready`; `child-lock-in.md` §R3 and §R7)
- Child Lock-in now sets the mode when it enters Waiting, so with the lock off it never turns on, and App Shell's
  "ready" never fires.
- Nothing breaks: Child Lock-in is the only consumer of "ready", and its own R3 lists the same preconditions.
- **Option:** App Shell R1 step 5 reads "Input's kiosk-on mode is on (set by Child Lock-in on Waiting; only when
  `childLockActive`)", or drops it from "ready" and leaves it to Child Lock-in R3.

ℹ️ **R-2 · ⌘ is swallowed from the start of Waiting, before the chord handler is installed** (Child Lock-in §R7;
Input §R5)
- At launch with the lock stored on, Waiting begins at the settings read. For that short window, at most
  `engage_timeout_s`, ⌘Q is swallowed and the chord may not be live yet.
- K-12's concern still holds: the presentation options that block Force Quit apply only after all six preconditions,
  and ⌥⌘Esc is the system's hotkey, not an app key. So nothing traps the grown-up.
- **Option:** keep as is, or state this window in Child Lock-in's Edge Cases so the real-Mac AC-1k6 run checks it.

ℹ️ **R-3 · Hint Letters §R4 cites "Key Table R4"** for the variety seed. Key Table has no R-numbers; its seed and pick
are in §4. A pointer nit, the same kind as W-6.

### Re-run verdict: PASS (`since-last-review` scope)

B-1 and all eleven Warnings are resolved in the merged text. The fixes introduced no contradiction; three Info notes
(R-1…R-3) are optional text edits. The scope is the TASK-056 diffs and the first run's findings. The first run's
"Not checked" list still stands, and the unchanged Key Table and MorphCore weren't re-read.

Recommended next: `/gate-check` (Systems Design → Technical Setup).
