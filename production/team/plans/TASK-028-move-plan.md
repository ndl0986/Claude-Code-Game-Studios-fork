# TASK-028: move Dải Đất Anh Hùng into `games/dai-dat-anh-hung/` (plan only)

Status: **PLAN**. Nothing has moved. Author: game-dev-ios. The Android parts were surveyed by game-dev-android (folded
in below), who reviews them. Luan put the game on hold (2026-11-17), and a new game starts next. The framework stays at
the root so that game starts clean.

## 0. Sources of truth today (all unmerged to `main`)

| Branch | Tip (fetched 2026-11-17) | Holds | Not in docs |
|---|---|---|---|
| `docs/vn-history-game-plan` | 3a32cf4 | design/, production/, content/, assets/, docs/architecture ADRs, tools/art, tools/team, project.yaml (≈ 446 commits ahead of main) | — |
| `feat/TASK-006-ios-native` | 81d3fa4 local (origin 9af55da) | + ios/, tools/ios, tools/qa/ios-*, production/qa/tools/ios, iOS evidence, TASK-026 (Preview, icon, privacy, guides) | 117 commits |
| `setup/TASK-007-android-kotlin` | beea731 | + android/, tools/dev/android, production/qa/tools/android, Android evidence | 115 commits |

Both code branches already contain docs up to 3f464b4. Docs has about 23 newer commits (board, decisions, QC records).
**The leader pushes 81d3fa4 first** (55cbbe6 install-script fix, 81d3fa4 device-run evidence); the move starts from the
pushed tips.

## 1. Merge order and expected conflicts

On one branch, **`chore/TASK-028-move-game`** (cut from `docs/vn-history-game-plan`):

1. `git merge --no-ff feat/TASK-006-ios-native`: **clean** (dry run with `git merge-tree`, no conflicts).
2. `git merge --no-ff setup/TASK-007-android-kotlin`: **one conflict, `.gitignore`**. Both sides add
   `production/qa/builds/`, and Android also adds `*.jks`, `*.keystore`, `keystore.properties`, `preview.properties`
   (D-37). Resolve by keeping both blocks (one `production/qa/builds/` line, and the four key rules).
3. **Commit the merged state before moving anything** (a pure merge commit). This gives the build/test baseline in §5 a
   reference point: every check runs once here, then again after the move.
4. The move itself is one commit of `git mv` only (§2), so `git log --follow` and blame survive. Path fixes follow it
   as separate commits, one per platform or tool (§3).
5. Merging to `main` is the leader's call afterwards. Nothing in the plan pushes.

Risk: a QC round still open on either code branch. The move starts only when both platforms are idle. iOS: r11 passed,
and iOS-R11-01 (9af55da) is committed but not frozen. Android: r14 is the latest.

## 2. File inventory

**Moves** to `games/dai-dat-anh-hung/` (with `git mv`, paths kept underneath):

| From (root) | To | Notes |
|---|---|---|
| `ios/` | `games/dai-dat-anh-hung/ios/` | Xcode project, GameCore package, tests, Scripts/ContentGate.swift |
| `android/` | `…/android/` | Gradle project |
| `content/` | `…/content/` | data, schema, samples, fixtures, drafts, metrics; **must stay a sibling of ios/ and android/** (§3) |
| `assets/` | `…/assets/` | art (incl. app_icon) |
| `design/` (game parts) | `…/design/` | gdd/, narrative/, art/, assets/ (specs), ux/, accessibility-requirements.md, **registry/entities.yaml as edited by the game** (see "copied") |
| `production/` (game parts) | `…/production/` | progress.md, project-plan.md, stage.txt, gate-checks/, qa/ (evidence ≈ 1060 files, tools/), releases/, team/ (board, decisions, handover, plans) |
| `docs/architecture/adr-000{1,2,3}-*.md`, `docs/architecture/architecture.md` | `…/docs/architecture/` | the game's ADRs (the 4 files the game added) |
| `tools/ios/`, `tools/qa/` (ios-touch-tests, ios-release-check), `tools/dev/android/`, `tools/art/` | `…/tools/…` | game build, QC and art tools |
| `project.yaml` (game version) | `…/project.yaml` | the game's config (stage Systems Design, goal mobile, native engine notes) |

**Stays at the root** (studio framework, reused by the next game): `.claude/` (agents, skills, hooks, rules, docs),
`studio-tests/`, `src/` (template `.gitkeep` + `CLAUDE.md`), `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `CONTRIBUTING.md`,
`LICENSE`, `SECURITY.md`, `UPGRADING.md`, `.github/`, `.gitattributes`, `.worktreeinclude`, `docs/` apart from the 4
game files (engine-reference, registry, WORKFLOW-GUIDE …), and **`tools/team/`** (game-dev-android's call: studio infra
for the team sessions; its prompts get a game-root parameter, §3).

**Copied** (a game copy moves, and the root gets main's template back):
- `project.yaml`: root reset to `main`'s template (no stage, no game modes). The game keeps its copy.
- `design/CLAUDE.md`, `design/registry/entities.yaml`, `docs/architecture/tr-registry.yaml`,
  `docs/registry/architecture.yaml`, `production/.gdignore`, `production/session-state/.gitkeep`: these exist on main
  as template files. The root keeps main's version, and the game folder gets its own copy where the game edited it
  (entities.yaml is unchanged vs main today, so the game only gets a copy if it diverges).
- `.claude/skills/game-team-lead/SKILL.md`: the only `.claude/` file the game changed. It stays at the root (a team
  skill), but its paths (`production/team/board.md`, `production/qa/evidence/`, `ios/`, `android/`, `tools/team/…`)
  become relative to a **game root** it reads from the leader's brief. The leader's call.

**Not moved** (untracked or ignored): `production/qa/builds/` (frozen QC builds),
`production/session-state/active.md` and `team-sessions.tsv`, `android/local.properties`, `.gradle/`, `build/`,
`ios/…/xcuserdata`. Run `./gradlew --stop` first. After the move, `local.properties` (sdk.dir) is re-created or
`ANDROID_HOME` is set. Frozen build folders stay usable from their old place, or move by hand.

## 3. Hard-coded paths that must change (and those that don't)

**Unchanged because the layout is kept** (ios/, android/, content/, tools/, production/ stay siblings inside the game
folder):
- iOS project: `ios/DaiDatAnhHung.xcodeproj/project.pbxproj` uses `path = ../content/data` (SOURCE_ROOT), the debug
  sample phase `$SRCROOT/../content/samples/…`, and the R12 gate `$SRCROOT/Scripts/ContentGate.swift
  "$SRCROOT/../content/data"`. GameCore is a local package (`relativePath = GameCore`). The scheme is shared under the
  xcodeproj.
- GameCore tests: `Repo.content` goes up 5 levels from `#filePath` (…/ios/GameCore/Tests/GameCoreTests/Support.swift),
  then `content/`. That is the game folder's content/, with `CONTENT_ROOT` as the override.
- Android Gradle: `app/build.gradle.kts` L73/L74 assets `../../content/{data,samples,drafts}` and L129 contentGate
  `../content/data`. TestContent.root tries `$CONTENT_ROOT`, `../../content`, `../content`, then `content`.
- `tools/dev/android/phone-install.sh`, `frametime.sh`: `ROOT=${0:A:h:h:h:h}` (4 levels up from the script = the game
  folder) then `$ROOT/android`, `$ROOT/production/qa/evidence`.
- Keystore: absolute `~/.config/daidatanhhung`; the `.gitignore` rules match at any depth.

**Must change:**

| File | Today | After |
|---|---|---|
| `tools/ios/install-device.sh` L22, `tools/ios/archive-upload.sh` L16 | `cd "$(git rev-parse --show-toplevel)"` then `ios/…` | `cd "${0:A:h:h:h}"` (the game folder, 2 levels up from tools/ios/), so `ios/…` still resolves; `ExportOptions` copy unchanged |
| `tools/qa/ios-release-check.sh` L19, L50, L54, L70 | `ROOT=$(git rev-parse --show-toplevel)`; `git archive "$REF" ios content`; `cd "$W/src"` | `GAME=games/dai-dat-anh-hung`; `git archive "$REF" "$GAME/ios" "$GAME/content"`, then build in `"$W/src/$GAME"` (so `../content` still resolves); strip list under `$W/src/$GAME/ios/…` |
| `tools/qa/ios-touch-tests.sh` | usage text `production/qa/builds/…` | text only (`games/dai-dat-anh-hung/production/qa/builds/…`) |
| `production/qa/tools/ios/q8.sh` L8 | `$ROOT/production/qa/evidence/…` | `$ROOT/games/dai-dat-anh-hung/production/…`, or ROOT = the game folder: **game-qc-ios** |
| `production/qa/tools/android/h.sh` L2 (and siblings using `QCREPO`/`EV`) | `…/game-qc-android/production/qa/evidence/…` | add `games/dai-dat-anh-hung/`: **game-qc-android** |
| `tools/team/start-member.sh` L23–L34, L47–L50 | prompts name `ios/`, `android/`, `production/project-plan.md`, `production/progress.md`; `$ROOT/production/session-state/team-sessions.tsv` | a `GAME_ROOT` parameter (default `games/dai-dat-anh-hung`) put in front of the game paths in the prompts. The session list stays at the root `production/session-state/` (team infra) |
| `.claude/skills/game-team-lead/SKILL.md` | `production/team/board.md`, `production/qa/evidence/`, `production/progress.md`, `ios/`, `android/` | relative to the game root (leader) |
| Guides and READMEs | `tools/qa/ios-touch-tests.md`, `production/releases/ios-device-and-testflight.md`, `tools/dev/android/README.md`, `android/README.md`, `production/qa/tools/*/README.md`, evidence READMEs | path text only. Old evidence READMEs stay as they are (historical record); only the guides people run from get updated |
| `project.yaml` (game copy) | `code_root: ios` / `android`, `shared_content: content/data` | relative to the game folder (unchanged text; a comment says so) |

**Framework hooks** (`.claude/hooks/*.sh`: session-start, detect-gaps, validate-write, validate-commit, pre-compact …)
read root `production/`, `design/gdd`, `production/stage.txt` and `project.yaml`. **No change**: after the move they see
the new game's (empty) root, which is the point. To work on Dải Đất Anh Hùng again later, open a session with the game
folder's paths in the brief. Framework support for a per-game root (e.g. `project.yaml` `paths.game_root`) is a separate
framework change, not part of this move.

**Asset manifests:** `content/data/assets.json` paths are relative to `content/data` (`pictures/…`, `fonts/…`), so
there's no change. `tools/art/make_app_icon.py` writes `assets/art/app_icon/` relative to argv[1] (default `.`): run it
from the game folder.

## 4. Checks after the move: no silent path failures

Each check runs on the merge commit (baseline) and again after the move and path fixes. The results must match.

**iOS** (game-dev-ios, dev Simulator FB836E51 only):
1. `cd games/dai-dat-anh-hung/ios/GameCore && swift test`: **164/164**. Proof that the tests read the moved content
   (not a stale copy or the old root): run once with the root `content/` absent (it is, after the move), and check the
   ContentTests counts of heroes and pictures equal the baseline.
2. `xcodebuild build-for-testing` Debug, then the app tests (5) plus the UI suite (29, the opt-in Preview case skipped).
   `AppBundleTests` asserts `data/` and `samples/` are inside the .app.
3. **Bundle proof**: list the built `DaiDatAnhHung.app` (`data/index.json`, `data/pictures/…`, `data/fonts/nunito.ttf`,
   `PrivacyInfo.xcprivacy`, AppIcon in `Assets.car` via `assetutil`) and diff the file list against the baseline .app.
   It must be identical.
4. `tools/qa/ios-release-check.sh`: Release and Preview each A1 = A2 = B; Release still stops **only** at R12 (the gate
   finds `content/data`: its "claims not signed off" message, not "file not found").
5. Scripts: `install-device.sh --dry-run` and `archive-upload.sh --dry-run` print paths under the game folder. One real
   `install-device.sh` to Luan's iPhone if it is connected (it renews the 7-day profile anyway).

**Android** (game-dev-android's list, verbatim scope):
1. `./gradlew --stop`, then `clean testDebugUnitTest assembleDebug assemblePreview`: JVM **182/182**, TraceTest
   (trace 1.3 **byte-identical**). RngTest must actually run: it skips silently if its fixture is missing, so check its
   count in the report.
2. `unzip -l` the Debug and Preview APKs: `assets/data/…`, samples (Debug only), drafts where expected. Diff against the
   baseline APK listing.
3. `assembleRelease` still stops **only** at R12.
4. `tools/dev/android/phone-install.sh --no-install`; a smoke run on emulator 5556.

**Repo-wide:**
- `git grep -nE '(^|[^.])\b(ios|android|content|assets)/'` over tools/, .claude/skills/game-team-lead, and the guides:
  every hit is either inside the game folder or reviewed.
- `git log --follow` on three moved files (one per platform, plus a GDD) shows history before the move.
- The root framework check: run the session-start hook in a fresh session at the root and confirm it reports an
  empty/new project, not the game's stage.

## 5. The root afterwards, and the reset for the new game

```
/
├── .claude/  .github/  studio-tests/  src/ (template)  tools/team/   ← framework and team infra
├── CLAUDE.md  README.md  … (framework docs)
├── docs/            ← framework docs (engine-reference, registry, WORKFLOW-GUIDE …); no game ADRs
├── design/          ← main's template (CLAUDE.md, registry/entities.yaml)
├── production/      ← main's template (.gdignore, session-state/.gitkeep); new stage.txt from /start
├── project.yaml     ← main's template: no stage, no modes; the new game's /start fills it
└── games/
    └── dai-dat-anh-hung/
        ├── project.yaml  ios/  android/  content/  assets/  tools/  design/  docs/architecture/  production/
        └── README.md     ← new: what the game is, status ON HOLD (2026-11-17), how to build each platform, where the board is
```

- **Stage reset**: root `project.yaml` returns to main's version and `production/stage.txt` is removed from the root, so
  `/start` for the new game sees a fresh project. The game's own `project.yaml` and `stage.txt` keep "Systems Design"
  inside the game folder.
- **Team infra**: `tools/team/start-*.sh` keep working for the next game through `GAME_ROOT`. The session list stays at
  the root.
- **On-hold marker**: `games/dai-dat-anh-hung/README.md` records the hold, the last frozen builds (iOS r11 86ddce0 +
  9af55da unfrozen, Android r14 beea731), the open items (ADR-0002 frame time on a real phone, history sign-off
  C01–C16, TASK-025 map) and how to resume.

## 6. Order of work once approved

1. The leader pushes the code tips. Both platforms are idle.
2. game-dev-ios: the merge branch (§1), baseline checks (§4), `git mv` commit, the iOS path fixes and iOS checks.
3. game-dev-android: the Android path fixes (if any beyond the guides) and the Android checks on the same branch.
   game-qc-ios and game-qc-android fix their QC tool paths (§3).
4. The leader: `game-team-lead` skill paths, `tools/team` `GAME_ROOT`, the root reset (§5), and the merge to main.

Estimated: about half a day of iOS-side work including the baseline and after-move checks; the Android checks run in
parallel.
