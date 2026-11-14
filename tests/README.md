# Test Infrastructure

**Engine**: Godot 4.7.2 (GDScript)
**Test Framework**: GdUnit4 6.2.2 (committed at `addons/gdUnit4/`)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-11-14 (TASK-002)

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

`project.yaml` `commands.test` holds the same command with the full editor path.

- Run the import first: without a `.godot/` class cache the runner exits 1
  (`Failed to load script`) and no test runs.
- Exit **0** = all pass · **100** = a test failed · **101** = passed but leaked
  nodes (warning) · **103/104** = gdUnit4 could not run · **105** = a test
  script does not parse.
- Two `ERROR:` lines about the remote port `127.0.0.1:0` are expected.
- `No test cases found` with exit 0 is **not** a pass.

## Installing / updating GdUnit4

GdUnit4 6.2.2 is committed in `addons/gdUnit4/` (from the v6.2.2 tag of
github.com/godot-gdunit-labs/gdUnit4) and enabled in `project.godot`
`[editor_plugins]`. CI uses `version: installed`, so it runs this copy.
To update: replace the folder with the new release's `addons/gdUnit4/`, then
check `addons/gdUnit4/plugin.cfg` shows the new version and `bin/GdUnitCmdTool.gd`
exists (capital U).

## Test Naming

GDScript (`.claude/rules/test-standards.md`): file `[system]_[feature]_test.gd`,
function `test_[scenario]_[expected]` — `combat_damage_test.gd` →
`test_base_attack_returns_expected_damage()`.

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging. Require the `Run GdUnit4 Tests` job check,
not `test-results` (that check run concludes success even when a test fails).
