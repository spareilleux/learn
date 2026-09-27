# AutoHarness course — code

Fixtures that exercise [tigerless-labs/autoharness](https://github.com/tigerless-labs/autoharness) at the pinned commit `ca39a72e4353ebef11b7de13c1fc7fa5f4df421b`, **without installing it**:
- no Claude Code plugin, hook, skill folder or MCP setting is changed;
- no model is called;
- nothing is written to your home directory.

| File | What it does |
|---|---|
| `fixtures.py` | Runs fixtures F0–F5 from `results/preregistration.md`, each in its own subprocess with an environment built from nothing, a disposable `HOME` and explicit skill roots. Prints one JSON line per fixture |
| `redact_probe.py` | Runs the pinned redactor on strings you pass. Use made-up values only |
| `results/preregistration.md` | Hypotheses, controls, falsifiers and input hashes, written before the first run |
| `results/fixtures-run.jsonl` | The measured run (Windows 11, Python 3.14.2) |
| `results/fixtures-run-1-cp1252-stdout.jsonl` | The first run, whose parent stdout was cp1252 (see the post-measurement edits) |
| `results/redact-probe.jsonl` | The probe used in lesson 1's exercise |
| `results/evaluation.md` | Evidence, claims and the verdict |

## Run it

It needs Python 3.11 or later, which AutoHarness requires, and git. Nothing to install.

```bash
git clone https://github.com/tigerless-labs/autoharness.git autoharness-ca39a72
git -C autoharness-ca39a72 checkout --detach ca39a72e4353ebef11b7de13c1fc7fa5f4df421b
python fixtures.py --hashes                          # input hashes; imports nothing from AutoHarness
python fixtures.py --clone autoharness-ca39a72       # F0..F5, then F4 again with PYTHONUTF8=1
```

On Linux and macOS, use `python3`. `fixtures.py` refuses a clone at any other commit.

The last line says whether `~/.claude/autoharness` existed before and after the run. It must say the same thing both times.
