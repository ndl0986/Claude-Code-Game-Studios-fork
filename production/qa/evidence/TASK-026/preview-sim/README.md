# TASK-026: the Preview build on the Simulator (developer check, not QC evidence)

game-dev-ios, own Simulator "iPhone 18 Pro – dev-ios" (FB836E51-…), `Preview` config (D-37) installed beside the
Debug app as `com.galaxyandsun.daidatanhhung.preview`.

| Shot | What it shows |
|---|---|
| 01 before the fix (5ad4f23) | The title has no hero card and no Start. The runtime R12 guard hid the unsigned hero because the build isn't Debug. A Preview build like this would be useless on Luan's phone |
| 02 after the fix (1f1a6e1) | Trần Quốc Toản's card (0★, medal outline) and Start. The debug line is gone (TitleLayout debug false). `-startScreen play` on the launch was ignored, so the debug jumps are off |

Not yet seen on screen: the `UNSIGNED Cxx` strip on a story screen in Preview. `simctl` can't tap Start. The strip is
compiled in for Preview (`#if DEBUG || PREVIEW`, `-DPREVIEW` on the app's compile line), and the first device run
checks it.

## Release check (`tools/qa/ios-release-check.sh`, ref 1f1a6e1)

| Config | A1 = A2 = B (182 `#if DEBUG` lines stripped) | strings / nm | Gate |
|---|---|---|---|
| Release | `54e61be5…8e86` | 0 / 0 | stops at R12 (C01–C16 unsigned), as designed |
| Preview | `f252dbc5…9658` | 0 / 0 | skipped (D-37) |

GameCore (local package) builds `-O -whole-module-optimization` with no `DEBUG` flag in Preview. The one
debug-named symbol, `Game.debugStart`, is public API also present in Release, and it returns at once unless the
build is Debug.
