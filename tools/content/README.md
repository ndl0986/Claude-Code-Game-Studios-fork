# Content checker

`check_content.py` checks `content/data` against `content/schema` and the cross-file rules in
`content/README.md` (R4, R8/R8b/R8c, R10, R12, R13d …). It reports observations; the apps' unit
tests stay the real gate.

```sh
python3 -m venv ~/.venvs/ddah-content && ~/.venvs/ddah-content/bin/pip install -r tools/content/requirements.txt
~/.venvs/ddah-content/bin/python -I tools/content/check_content.py "$PWD"
```

Baseline on `docs/vn-history-game-plan` (2026-11-16): **0 errors, 10 warnings** (all R4 on label
fields, D-12 R4b). Moved here from game-art-content's scratchpad (TASK-021) so a restart can't
lose it.
