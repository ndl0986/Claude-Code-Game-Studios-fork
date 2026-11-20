# Gate Check: Technical Setup → Pre-Production

**Date**: 2026-11-20
**Checked by**: gate-check skill (run by game-leader with Luan)
**Settings**: workflow standard · review_mode lean · qa.level standard · team.size individual · performance.enforce warn
**Base**: docs/kid-learn-character-plan @ bd48c3c0

### Required Artifacts: 8/8 present (standard tier; + recommended set present)
- [x] Engine chosen: native Apple stack (Swift 6.4, SpriteKit in SwiftUI, AVAudioEngine; Xcode 27.1), ADR-0001
  Accepted. `engine.name` unset on purpose (K-28); the game's CLAUDE.md is a symlink to the shared template, so its
  Technology Stack line still reads `[CHOOSE]` (recorded deviation, not a gap).
- [x] Project config: `project.yaml` (stage, modes; the stack as a comment block per K-28).
- [x] Foundation ADRs ≥ 3: 8 Accepted (0001, 0002, 0003, 0004, 0005, 0006, 0011, 0013); 0007–0010 Proposed.
- [x] Engine reference docs: `docs/engine-reference-local/native-apple/` (game-local by K-28 Q3, in place of
  `docs/engine-reference/<engine>/`).
- [x] Test framework + example tests: XCTest in the MorphCore, KidCore, Tools and ContractKit packages and the app's
  test targets.
- [x] CI test workflow (or equivalent): `tools/ci/verify.sh`, local only by Luan's decision (K-42). Plan
  `verify --dev --no-xcode` PASS at c8bd1422 (2026-11-20, leader-run); `--dev` with Xcode (macOS + iPad simulator
  tests) PASS at 6a7a0429 (TASK-130).
- [x] Master architecture: `docs/architecture/architecture.md` (v2).
- [x] `/architecture-review` run: `architecture-review-2026-11-18.md`, `Mode: full`, verdict CONCERNS.
- [x] Recommended at standard: art bible (Approved), `design/ux/title-screen.md` (UX spec started),
  `design/accessibility-requirements.md` (tier Standard, K-42), `design/ux/interaction-patterns.md`,
  `docs/architecture/requirements-traceability.md` + `tr-registry.yaml` (83 TRs).

`artifact-check.sh --phase technical-setup`: 7 steps, 0 NO_CHECK; PRESENT: create-architecture, architecture-decision
(12), architecture-review, accessibility-doc, interaction-patterns; ABSENT: control-manifest, test-setup
(`.github/workflows/tests.yml`; equivalent accepted by K-42).

### Quality Checks: 7/9 passing, 2 concerns
- [x] Architecture decisions cover core systems: rendering (0006, 0009), input (0002 D5–D7, 0007), state
  (0002, 0005), audio (0010), content (0003), build/PKC (0011), flash safety (0013).
- [ ] Naming conventions set: **none** documented (project.yaml has no naming block; technical-preferences.md is the
  template). → CONCERN.
- [~] Performance budgets: 60 fps cap and 16.7 ms p99 frame budget (ADR-0006, ADR-0009); **no memory ceiling, no
  draw-call limit**. → CONCERN (`performance.enforce: warn`). P-2 memory (138 / 119 / 94 MiB) is recorded against
  no budget (ADR-0009, TASK-129).
- [x] Accessibility tier defined: Standard (K-42).
- [x] At least one screen's UX spec started: Title screen.
- [x] Every ADR has an Engine Compatibility section with the version stamped (Xcode 27.1 / Swift 6.4, one version
  throughout) and a GDD Requirements Addressed section (12/12).
- [x] No ADR uses an API on the deprecated/avoided list (`docs/engine-reference-local/native-apple/deprecated-apis.md`):
  ADR-0001 requires `loadCdn: false`; ADR-0008 rules out `requestGuidedAccessSession`; ADR-0010 calls `stop()` only
  after a gate-to-0 and `cut_settle_s`, not the per-press main-thread pattern. Checked by the leader (grep) and
  independently by the technical-director. The list itself is "NOT SOURCEABLE beyond this table".
- [x] HIGH RISK engine domains addressed: architecture.md Engine Knowledge Gap Summary names each HIGH domain
  (SpriteKit layered render, AVAudioEngine latency/session) with its owning ADR and a measurement-first rule.
- [x] Zero Foundation-layer traceability gaps: Foundation 19 Covered, 3 Covered (Proposed), 0 Partial, 0 Gap.

ADR dependency graph (`adr-dep-graph.sh`): 12 ADRs, no `CYCLE:`, no `NO_DEPS_SECTION`, no `UNFILLED_DEPS`.
Order: 0001, 0002, 0004, 0006, 0003, 0005, 0007, 0008, 0009, 0010, 0011, 0013. → PASS.

Engine validation: Knowledge Risk lines present in every ADR; one engine version across all ADRs.

### Device evidence carried in (TASK-127, `production/qa/evidence/TASK-127/7db7511a/results.md`)
- H-2 PASS on the device; P-2 PASS on iPad13,4 (frame pacing at 120 Hz, no dropped frame; render headroom not
  measured; crispness and the oldest-iPad decisive run NOT ASSESSED).
- **P-7 FAIL (open)**: Luan heard a pop on every audio button except Tone freeze; the on-screen detector's cuts
  PASS and the offline whole-sound check (TASK-128) found no digital click.
- P-1, P-8, P-9, P-4: NOT ASSESSED (weekend session). P-15 and P-4's key parts: NOT ASSESSED (no hardware keyboard).
  Mac session M-1…M-16: not run.
- Oldest supported iPad: decided at release prep (K-47).

### Director Panel Assessment
Panel: 2 of 4 (`workflow: standard`, from `modes.rigor: standard`). Creative and Art perspectives not consulted;
raise `modes.rigor` to `full` for the complete panel.

Technical Director: **CONCERNS**
- Required artifacts at standard all present and sound; dependency graph and deprecated-API audit verified
  independently.
- Carry: 3 Foundation requirements on Proposed ADRs 0007/0009/0010 (the slice is the vehicle that promotes them; tie
  slice exit to their acceptance rows); P-7 FAIL as the top technical risk (ADR-0010 cannot be Accepted until it
  resolves); no memory ceiling or draw-call limit (set from slice numbers before Production); Mac rows M-1…M-16 open
  (Mac parity in scope, not deferred); control manifest absent (noted).

Producer: **CONCERNS**
- Design locked (14 MVP GDDs + Scene Approved, cross-review PASS, art bible Approved, prototype replayed with the
  child); 0 open decisions, no scope creep.
- Carry: no epics/stories yet (the first act of Pre-Production; keep the slice thin); control manifest before stories;
  4 Proposed ADRs gate slice features (map ADR → device rows in each story); device sessions on Luan's time are the
  critical path (book the weekend iPad session and a Mac block before the slice's first sprint).

### Blockers
None. No required check is NOT ASSESSED.

### Recommendations (ordered)
1. Book the weekend iPad session (P-1, P-7 re-run, P-8, P-9, P-4) and a Mac session block (M-1…M-16).
2. `/create-control-manifest` from the Accepted ADRs; document Swift naming conventions.
3. `/create-epics` and `/create-stories` for a thin vertical slice (a few letters, dinosaurs, sound, one parade) on
   macOS and iPadOS; each story names the ADRs and device rows it depends on.
4. Set a memory ceiling (and draw-call limit if useful) from the slice's measurements before the Production gate.
5. Refresh project.yaml's stale "ADR-0001, Proposed" comment.

### Verdict: CONCERNS
Every required artifact is present and the quality checks pass except two configuration gaps (naming conventions,
memory budget). The Foundation adapter ADRs are deliberately unfinished pending device data, and one device check
(P-7) is open; both directors judged these carryable into the vertical slice.

Chain-of-Verification: 5 questions checked, 2 by tool (re-read TASK-127 results.md for the P-2/P-7 rows; grep of
the traceability matrix for Foundation Gap/Partial rows, none). Verdict unchanged (CONCERNS). No FAIL condition was
softened: no Foundation requirement is uncovered, no cycle exists, and the test suites pass.

### Accepted Risks
Accepted by Luan, 2026-11-20 ("chuyển pre-production for first checking and demo với board trước": advance to
Pre-Production for a first check and a demo build first):
- ADR-0007, 0008, 0009, 0010 remain Proposed pending device rows; 3 Foundation requirements rest on them.
- P-7 FAIL (audible pop on iPad13,4) is open.
- The Mac device session (M-1…M-16) is not scheduled; the remaining iPad rows wait for the weekend session.
- No memory ceiling or draw-call limit is set.
- No naming conventions are documented.
- No control manifest exists yet.

Stage advanced to **Pre-Production** on Luan's explicit acceptance (2026-11-20).
